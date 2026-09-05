{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    programs = {
      command-not-found = {
        enable = true;
        dbPath = lib.mkForce "${config.nixpkgs.flake.source}/programs.sqlite";
      };
      fish.enable = true;
      git = {
        enable = true;
        lfs.enable = true;
      };
      htop.enable = true;
      lazygit.enable = true;
    };
    # security.apparmor.enable = true; # disable for now, as it causes some issues with docker and flatpak
    services = {
      atd.enable = true;
      fstrim.enable = true;
      dbus.implementation = "broker";
      journald = {
        settings.Journal = {
          Compress = true;
          Storage = "auto";
          SystemMaxUse = if ("${pkgs.stdenv.hostPlatform.system}" == "x86_64-linux") then "512M" else "256M";
        };
      };
    };
    environment.systemPackages = with pkgs; [
      # Drivers and detection tools
      android-tools
      aria2
      btop
      compsize
      cryptsetup
      # currentNixConfig !!!
      dnsutils
      fastfetch
      fzf
      iperf
      iptables
      jq
      lm_sensors
      lsof
      # nixd
      # nixfmt
      # nix-diff
      # nix-output-monitor
      # nix-tree
      ncdu
      net-tools
      nmap
      pciutils
      psmisc
      rclone
      ripgrep
      rsync
      sshfs
      tree
      usbutils
      wget
      zellij
    ];
    # system.etc.overlay = {
    #   enable = true;
    #   mutable = true;
    # };
  };
}
