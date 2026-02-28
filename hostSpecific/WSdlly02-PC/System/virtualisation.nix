{
  config,
  lib,
  pkgs,
  ...
}:
{
  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        package = pkgs.qemu_kvm;
        vhostUserPackages = with pkgs; [ virtiofsd ];
        swtpm.enable = true;
        verbatimConfig = ''
          cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
            "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
            "/dev/kvmfr0"
          ]
        '';
      };
      hooks.qemu = {
        hugepages = pkgs.writeShellScript "hugepages-hook.sh" ''
          set -euo pipefail

          VM_NAME="Windows 11"
          CONFIG_FILE="/var/lib/libvirt/qemu/$VM_NAME.xml"

          guest_name="$1"
          hook_action="$2"

          get_current_memory_kib() {
              local xml value unit

              if [ ! -f "$CONFIG_FILE" ]; then
                echo "Error: File not found $CONFIG_FILE!" >&2
                exit 1
              fi

              xml=$(cat "$CONFIG_FILE")

              value="$(
                  printf '%s' "$xml" \
                  | ${pkgs.libxml2}/bin/xmllint --xpath "string(/domain/currentMemory)" -
              )"

              unit="$(
                  printf '%s' "$xml" \
                  | ${pkgs.libxml2}/bin/xmllint --xpath "string(/domain/currentMemory/@unit)" -
              )"

              [ -n "$value" ] || {
                  echo "Failed to read /domain/currentMemory from libvirt XML" >&2
                  return 1
              }

              [ -n "$unit" ] || unit="KiB"

              case "$unit" in
                  KiB|k|KB)
                      echo "$value"
                      ;;
                  MiB|M|MB)
                      echo $(( value * 1024 ))
                      ;;
                  GiB|G|GB)
                      echo $(( value * 1024 * 1024 ))
                      ;;
                  *)
                      echo "Unsupported memory unit: $unit" >&2
                      return 1
                      ;;
              esac
          }

          calc_hugepages_2m() {
              local mem_kib="$1"
              echo $(( (mem_kib + 2047) / 2048 ))
          }

          if [ "$guest_name" = "$VM_NAME" ]; then
              case "$hook_action" in
                  prepare)
                      MEM_KIB="$(get_current_memory_kib)"
                      HUGEPAGES="$(calc_hugepages_2m "$MEM_KIB")"

                      echo "Preparing hugepages for $VM_NAME: $MEM_KIB KiB -> $HUGEPAGES x 2MiB" >&2

                      echo 3 > /proc/sys/vm/drop_caches
                      echo 1 > /proc/sys/vm/compact_memory

                      ${pkgs.procps}/bin/sysctl -q "vm.nr_hugepages=$HUGEPAGES"

                      ACTUAL_HUGEPAGES="$(${pkgs.coreutils}/bin/cat /proc/sys/vm/nr_hugepages)"
                      if [ "$ACTUAL_HUGEPAGES" -lt "$HUGEPAGES" ]; then
                          echo "Hugepage allocation failed: need $HUGEPAGES, got $ACTUAL_HUGEPAGES" >&2
                          exit 1
                      fi
                      ;;

                  release)
                      echo "Releasing hugepages for $VM_NAME" >&2

                      ${pkgs.procps}/bin/sysctl -q vm.nr_hugepages=0
                      echo 1 > /proc/sys/vm/compact_memory
                      ;;

                  *)
                      ;;
              esac
          fi
        '';
      };
    };
    podman = {
      enable = true;
      dockerCompat = true;
    };
    quadlet = {
      enable = true;
      autoUpdate.enable = true;
      autoEscape = true;
    };
  };
  programs.virt-manager.enable = true;

  boot =
    let
      pciIDs = [
        "1002:13c0" # radeon graphics
        "1002:1640" # audio
      ];
    in
    {
      kernelParams = [
        "video=efifb:off"
        ("vfio-pci.ids=" + lib.concatStringsSep "," pciIDs)
        "transparent_hugepage=always" # 透明大页
      ];
      kernelModules = [
        "kvm-amd"
        "kvmfr"
        "vfio_virqfd"
        "vfio_pci"
        "vfio_iommu_type1"
        "vfio"
        # "vendor-reset" useless for igpu
      ];
      extraModulePackages = with config.boot.kernelPackages; [
        kvmfr
        # vendor-reset # useless for igpu
      ];
      extraModprobeConfig = ''
        options vfio-pci ids=${lib.concatStringsSep "," pciIDs}
        options kvmfr static_size_mb=128
        softdep amdgpu pre: vfio-pci
        softdep snd_hda_intel pre: vfio-pci
      '';
      initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
      ];
    };
  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", GROUP="kvm", MODE="0660"
    KERNEL=="kvmfr0", OWNER="wsdlly02", GROUP="kvm", MODE="0660"
  '';
  systemd.user.services.scream-receiver = {
    description = "Scream Audio Receiver";
    after = [ "pipewire.service" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      # -i 指定接口，-u 指定单播模式(可选)，-v 详细日志
      # 通常直接运行 scream 即可自动监听多播
      ExecStart = "${pkgs.scream}/bin/scream -i virbr0";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
  environment.systemPackages = with pkgs; [
    looking-glass-client
    scream
  ];
  system.nixos.tags = [ "with-iGPUPassthr" ];
}
