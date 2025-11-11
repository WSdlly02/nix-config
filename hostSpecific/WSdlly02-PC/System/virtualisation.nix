{ pkgs, ... }:
{
  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        package = pkgs.qemu_kvm;
        vhostUserPackages = with pkgs; [ virtiofsd ];
        swtpm.enable = true;
      };
    };
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };
  programs.virt-manager.enable = true;
  environment.etc."distrobox/distrobox.conf".text = ''
    container_additional_volumes="/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro /etc/static/profiles/per-user:/etc/static/profiles/per-user:ro"
  '';

  specialisation = {
    # Gaming.configuration = {
    #   boot = {
    #   };
    # };
    # Working.configuration = {
    #   boot = {
    #     extraModprobeConfig = ''
    #       options vfio-pci ids=1002:13c0,1002:1640
    #       softdep amdgpu pre: vfio-pci
    #       softdep snd_hda_intel pre: vfio-pci
    #     '';
    #     initrd.kernelModules = [
    #       "vfio_pci"
    #       "vfio"
    #       "vfio_iommu_type1"
    #     ];
    #   };
    # };
  };
}
