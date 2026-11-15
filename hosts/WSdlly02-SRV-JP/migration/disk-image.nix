{ host, home }:
let
  inherit (host) config pkgs;
in
import (pkgs.path + "/nixos/lib/make-disk-image.nix") {
  inherit pkgs config;
  inherit (pkgs) lib;
  name = "srv-jp-bios-image";
  partitionTableType = "legacy";
  diskSize = 30720;
  format = "qcow2";
  rootFSUID = baseNameOf config.fileSystems."/".device;
  copyChannel = false;
  additionalPaths = [ home.activationPackage ];
  contents = [
    {
      source = pkgs.writeText "home-activation-path" (toString home.activationPackage);
      target = "/etc/nixos/home-activation-path";
    }
  ];
}
