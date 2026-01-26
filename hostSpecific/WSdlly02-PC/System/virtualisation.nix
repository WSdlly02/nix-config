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
        systemd.tmpfiles.rules = [
          "z /dev/kvmfr0 0660 root kvm -"
        ];
        environment.systemPackages = with pkgs; [ looking-glass-client ];
      };
  };
}
