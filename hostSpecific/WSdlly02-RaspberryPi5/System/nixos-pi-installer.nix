# Only for generating sd images!
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  nixpkgs.overlays = [
    (final: prev: {
      makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "btrfs"
    "tmpfs"
  ];
  sdImage.compressImage = false;

  networking = {
    hostName = config.system.name;
    timeServers = [
      "ntp.ntsc.ac.cn"
      "cn.ntp.org.cn"
    ];
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      ethernet.macAddress = "stable";
      wifi.macAddress = "stable-ssid";
      plugins = lib.mkForce [ ];
      # rc-manager has been set as unmanaged
    };
  };
  services = {
    timesyncd.servers = config.networking.timeServers;
    resolved = {
      enable = true; # which will disable resolvconf
      domains = [ "~." ];
      fallbackDns = [
        "223.5.5.5"
        "119.29.29.29"
        "1.1.1.1"
        "9.9.9.9"
      ];
      extraConfig = ''
        Cache=yes
        CacheFromLocalhost=no
        ReadEtcHosts=yes
        MulticastDNS=false
      '';
    };
  };

  services.openssh.enable = true;
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
    nssmdns6 = true;
    nssmdns4 = true;
    ipv6 = true;
    ipv4 = true;
    extraConfig = ''
      [server]
      disallow-other-stacks=yes
    '';
  };
  programs = {
    tmux = {
      enable = true;
      historyLimit = 4000;
      clock24 = true;
      extraConfig = "set -g mouse on";
    };
    fish.enable = true;
    git = {
      enable = true;
    };
    htop.enable = true;
  };
  security.sudo = {
    wheelNeedsPassword = false;
    extraConfig = ''Defaults env_keep += "http_proxy https_proxy all_proxy"'';
  };
  users.users.wsdlly02 = {
    isNormalUser = true;
    extraGroups = [
      "audio"
      "networkmanager"
      "input"
      "render"
      "video"
      "users"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCkH7l0JnwQeP+cmD+ty29i0kdxHdvnvedkiXKcp8dCYRYAoGBIS6FIzD6p058cNwp1DDHN+TTrlNZz9DEizKqbS1SOPJyiWrln6lx3jh9p/AD1pbPRjsgVLzvdBS6bJ6NgtXe2q0bV4UgGktVi6VxDAt4jBQPsUKfyGYx9hh95xeWjvt9AEYcD2hOak9bBRHkE4IQcus5xV1kXNSiVec0DMhB2IObADbx+6H4C+oIIAxVccr+SOivwrSgwmn9XhQ0VgopJomVKg9zmlr7idorwmDZdIsMmpeU346Gu2Piq+Amvn1FM7H37ThBNx81dUO18UZ/gw35zT7G6Hh4CisYFDJWocKfYKMdT4IdzxcyOWkUr3PSfcpOUc+60h+BlpI0ogxYRoXM6R9bWRGYM3x26hRrfcBR8fwTepTa9H+Vz70KNJh4qNrHuMICnyerX+h9igkVXoysPjbzfqidGPzLIbbi+iUU56/8C4JGL2haEppoZgq/bx1Lo5rv1BT7Q732BkhcnS96vaDqsAffAKupHWQ1eRFZ9uId8uRTNbKZmstgKJthcoSdizrbXvlx7b3Kzob9Y4mix9tlUU2Z5i5sm2FFa/AYfTNrLVg6jA4fSrB0vKRyeCaBBzHOhwPOIWZAa0MG/2LZ40M2jT3270HCToHH3kBCMQthByCos20h/IQ== wsdlly02@WSdlly02-PC"
    ];
  };
  nix = {
    settings = {
      max-jobs = 64;
      substituters = lib.mkForce [
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirror.sjtu.edu.cn/nix-channels/store"
      ];
      trusted-users = [
        "root"
        "wsdlly02"
      ];
      auto-optimise-store = true;
      experimental-features = lib.mkForce [
        "nix-command"
        "flakes"
      ];
    };
  };
  system = {
    name = "WSdlly02-RaspberryPi5";
    # nixos.tag = [];
    stateVersion = "25.05";
  };
  nixpkgs = {
    hostPlatform = "aarch64-linux";
    config.allowUnfree = true;
    config.enableParallelBuilding = true;
  };
}
