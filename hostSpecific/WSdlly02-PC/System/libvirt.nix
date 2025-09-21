{
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu.swtpm.enable = true;
  };
  programs.virt-manager.enable = true;
}
