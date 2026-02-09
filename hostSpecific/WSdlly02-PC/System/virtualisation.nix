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
          # 1. 将 kvmfr0 加入 Cgroup 设备白名单
          cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
            "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
            "/dev/kvmfr0"
          ]

          # 2. 指定运行用户 (可选，如果还是报错，可以尝试强制 root 运行)
          # user = "root"
          # group = "root"

          # 3. 命名空间设置 (通常不需要，但如果上面无效可尝试)
          # namespaces = []
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
  # environment.etc."distrobox/distrobox.conf".text = ''
  #   container_additional_volumes="/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro /etc/static/profiles/per-user:/etc/static/profiles/per-user:ro"
  # '';

  specialisation = {
    # Normal.configuration = { };
    # Has default option
    iGPUPassthr.configuration =
      let
        pciIDs = [
          "1002:13c0" # radeon graphics
          "1002:1640" # audio
        ];
      in
      {
        boot = {
          kernelParams = [
            "video=efifb:off"
            ("vfio-pci.ids=" + lib.concatStringsSep "," pciIDs)
            # 计算大页数量：
            # 假设给虚拟机 12GB，每个大页 2MB。
            # 12 * 1024 / 2 = 6144 个。
            # 为了保险（防止开销溢出），我们预留 6200 个。
            "hugepages=6200"
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
          extraModulePackages = with config.specialisation.iGPUPassthr.configuration.boot.kernelPackages; [
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
      };
  };
}
