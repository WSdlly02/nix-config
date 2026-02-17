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
          # 定义变量
          VM_NAME="Windows 11"
          HUGEPAGES=6200 # 2M * 6200 = 12GB 大页数量

          command=$2

          if [ "$1" = "$VM_NAME" ]; then
            case "$command" in
              "prepare")
                # 分配大页前尝试清理缓存，增加分配成功率
                echo 3 > /proc/sys/vm/drop_caches
                echo 1 > /proc/sys/vm/compact_memory
                
                # VM 启动前：分配大页
                ${pkgs.procps}/bin/sysctl vm.nr_hugepages=$HUGEPAGES
                ;;
                
              "release")
                # VM 关闭后：释放大页
                ${pkgs.procps}/bin/sysctl vm.nr_hugepages=0
                
                # 释放后再次整理内存
                echo 1 > /proc/sys/vm/compact_memory
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
