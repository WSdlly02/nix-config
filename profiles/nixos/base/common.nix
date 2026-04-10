{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs = {
      command-not-found = {
        enable = true;
        dbPath = "${config.nixpkgs.flake.source}/programs.sqlite";
      };
      fish.enable = true;
      git = {
        enable = true;
        lfs.enable = true;
      };
      htop.enable = true;
      lazygit.enable = true;
      nix-ld.enable = true;
    };
    security.apparmor.enable = true;
    services = {
      atd.enable = true;
      fstrim.enable = true;
      dbus.implementation = "broker";
      journald = {
        storage = "auto";
        extraConfig =
          let
            systemLogsMaxUse =
              if ("${pkgs.stdenv.hostPlatform.system}" == "x86_64-linux") then "512M" else "256M";
          in
          ''
            Compress=true
            SystemMaxUse=${systemLogsMaxUse}
          '';
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
      fzf
      iperf
      iptables
      lm_sensors
      lsof
      # nixd
      # nixfmt
      # nix-diff
      # nix-output-monitor
      # nix-tree
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
