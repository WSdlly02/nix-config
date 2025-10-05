{
  config,
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
{
  imports = [
    ./avahi.nix
    ./bluetooth.nix
    ./ccache.nix
    ./getty.nix
    ##./gitDaemon.nix
    ./gnupg.nix
    ./i18n.nix
    ./mihomo.nix
    ./neovim.nix
    ./networking.nix
    ./networkmanager.nix
    ./nix.nix
    ./openssh.nix
    ./pipewire.nix
    ##./samba.nix
    ##./smartdns.nix
    ##./static-web-server.nix
    ./sudo.nix
    ./sysctl.nix
    ./tmux.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf enableInfrastructure {
      programs = {
        fuse.userAllowOther = true;
        bandwhich.enable = true;
        usbtop.enable = true;
        adb.enable = true;
      };
    })
    {
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
        smartd.enable = config.hostSystemSpecific.enableSmartd;
        fstrim.enable = true;
        btrfs.autoScrub = lib.mkIf config.hostSystemSpecific.enableBtrfsScrub {
          enable = true;
          interval = "monthly";
          fileSystems = [
            "/"
          ];
        };
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
      environment.systemPackages =
        with pkgs;
        [
          # Drivers and detection tools
          aria2
          btop
          compsize
          cryptsetup
          currentNixConfig
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
          ripgrep
          rsync
          sshfs
          tree
          usbutils
          wget
        ]
        ++ config.hostSystemSpecific.environment.extraSystemPackages;
      # system.etc.overlay = {
      #   enable = true;
      #   mutable = true;
      # };
    }
  ];
}
