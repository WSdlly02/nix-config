{ pkgs, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf = {
        enable = true;
        packages = with pkgs; [
          (OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
      vhostUserPackages = with pkgs; [ virtiofsd ];
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;
  specialisation = {
    Gaming.configuration = {
      boot = {
      };
    };
    Working.configuration = {
      boot = {
        extraModprobeConfig = ''
          options vfio-pci ids=1002:13c0,1002:1640
          softdep amdgpu pre: vfio-pci
          softdep snd_hda_intel pre: vfio-pci
        '';
        initrd.kernelModules = [
          "vfio_pci"
          "vfio"
          "vfio_iommu_type1"
        ];
      };
    };
  };
}
