{
  ...
}:
{
  imports = [
    ./avahi.nix
    ./bluetooth.nix
    ##./ccache.nix
    ./dnsmasq.nix
    ./easytier.nix
    ./getty.nix
    ##./gitDaemon.nix
    ./gnupg.nix
    ./mihomo.nix
    ./networking.nix
    ./networkmanager.nix
    ./openssh.nix
    ./pipewire.nix
    ##./samba.nix
    ##./smartdns.nix
    ##./static-web-server.nix
    ./sysctl.nix
    ./tailscale.nix
  ];

  config.programs = {
    fuse.userAllowOther = true;
    bandwhich.enable = true;
    usbtop.enable = true;
  };
}
