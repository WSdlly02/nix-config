{
  inputs,
  pkgs',
}:
let
  hostModule = { config, pkgs, ... }: {
    imports = [
      ../../profiles/nixos/base.nix
      ../../profiles/nixos/development.nix
    ];

    time.timeZone = "Asia/Singapore";
    i18n.extraLocales = [ "zh_CN.UTF-8/UTF-8" ];

    nix.settings.max-jobs = 64;
    environment.systemPackages = with pkgs; [
      wsl-open
    ];

    wsl = {
      enable = true;
      defaultUser = "wsdlly02";
      startMenuLaunchers = true;
      interop.register = true;
      useWindowsDriver = true;
    };

    boot.binfmt.emulatedSystems = [
      # use QEMU to emulate systems for compiling pkgs of different archs.
      "aarch64-linux"
    ];
    system = {
      name = "WSdlly02-WSL";
      stateVersion = "26.11";
    };
    networking = {
      hostName = config.system.name;
      firewall.enable = false;
      tempAddresses = "disabled";
    };
  };

in
inputs.nixpkgs-unstable.lib.nixosSystem rec {
  specialArgs = { inherit inputs; };
  system = "x86_64-linux";
  pkgs = pkgs' { inherit system; };
  modules = [
    inputs.nixos-wsl.nixosModules.default
    hostModule
  ];
}
