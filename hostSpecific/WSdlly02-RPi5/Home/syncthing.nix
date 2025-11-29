{ lib, ... }:
{
  services.syncthing = {
    enable = true;
    guiAddress = "0.0.0.0:8384";
    overrideDevices = false;
    overrideFolders = false;
  };
  systemd.user.services.syncthing.Install.WantedBy = lib.mkForce [ ];
}
