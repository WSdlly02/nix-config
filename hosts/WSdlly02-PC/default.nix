{ pkgs, ... }:
{
  imports = [
    ../../profiles/nixos/base.nix
    ../../profiles/nixos/development
    ../../profiles/nixos/development/codex-desktop.nix
    ../../profiles/nixos/desktop
    ../../profiles/nixos/gaming
    ../../profiles/nixos/infrastructure.nix
    ./hardware.nix
    ./system.nix
  ];

  boot.kernel.sysctl."vm.swappiness" = 100;
  nix.settings.max-jobs = 64;
  environment.systemPackages = with pkgs; [
    amdgpu_top
    # distrobox
    lact # AMDGPU Fan Control
    libva-utils
    mesa-demos
    ntfsprogs
    rar # ark required
    vdpauinfo
    vulkan-tools
  ];

  users.users.wsdlly02.extraGroups = [
    "kvm"
    "libvirtd"
    "podman"
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
}
