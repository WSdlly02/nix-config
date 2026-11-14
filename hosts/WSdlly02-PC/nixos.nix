{ inputs, pkgs' }:
let
  hostModule =
    { inputs, pkgs, ... }:
    {
      imports = [
        ../../profiles/nixos/base.nix
        ../../profiles/nixos/development.nix
        ../../profiles/nixos/desktop.nix
        ../../profiles/nixos/gaming.nix
        ../../profiles/nixos/infrastructure.nix
        ./hardware.nix
        ./system/networking.nix
        ./system/samba.nix
        ./system/virtualisation.nix
        inputs.codex-desktop-linux.nixosModules.default
      ];

      programs.codexDesktopLinux = {
        enable = true;
        linuxFeatures = [
          "appshots"
          "computer-use-linux"
          "global-dictation"
          "codex-micro"
          "pet-overlay"
          "remote-control-ui"
          "remote-mobile-control"
        ];
      };

      system.name = "WSdlly02-PC";
      system.stateVersion = "24.11";
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
      boot.kernel.sysctl."vm.swappiness" = 100;
      nix.settings.max-jobs = 64;
      environment.systemPackages = with pkgs; [
        amdgpu_top
        # distrobox
        libva-utils
        mesa-demos
        ntfsprogs
        rar # ark required
        vdpauinfo
        vulkan-tools
      ];

      my.networking.firewall = {
        extraAllowedPorts = [ ];
        extraAllowedPortRanges = [ ];
        lanOnlyPorts = [ 5353 ];
        lanOnlyPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
      };

      services.printing.enable = true;
      services.smartd.enable = true;
      services.btrfs.autoScrub = {
        enable = true;
        interval = "monthly";
        fileSystems = [
          "/"
        ];
      };

      systemd.user.services.gigabyte-usb-audio-profile = {
        description = "Enable Gigabyte USB audio profile";
        after = [ "wireplumber.service" ];
        wantedBy = [ "wireplumber.service" ];
        script = ''
          # WirePlumber's Type=simple starts before its profile policy settles.
          ${pkgs.coreutils}/bin/sleep 1
          for _ in {1..50}; do
            if ${pkgs.pulseaudio}/bin/pactl set-card-profile alsa_card.usb-Generic_USB_Audio-00 HiFi; then
              exit 0
            fi
            ${pkgs.coreutils}/bin/sleep 0.1
          done
          exit 1
        '';
      };
    };

in
inputs.nixpkgs-unstable.lib.nixosSystem rec {
  specialArgs = { inherit inputs; };
  system = "x86_64-linux";
  pkgs = pkgs' { inherit system; };
  modules = [
    inputs.quadlet-nix.nixosModules.quadlet
    hostModule
  ];
}
