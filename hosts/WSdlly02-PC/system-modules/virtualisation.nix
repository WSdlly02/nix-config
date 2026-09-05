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
        hugepages = pkgs.writers.writePython3 "hugepages-hook.py" { } ./hugepages-hook.py;
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
        "transparent_hugepage=madvise"
      ];
      kernelModules = [
        "kvm-amd"
        "kvmfr"
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
  environment.systemPackages = with pkgs; [
    looking-glass-client-dev
  ];
  system.nixos.tags = [ "with-iGPUPassthr" ];
}
