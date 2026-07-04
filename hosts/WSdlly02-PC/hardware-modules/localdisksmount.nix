{ lib, ... }:
# NTFS Disks mounting
{
  boot.supportedFilesystems = {
    ntfs = lib.mkForce false; # remove ntfs-3g from initrd, since we are using ntfs kernel module
  };
  fileSystems = {
    "/home/wsdlly02/Disks/Files" = {
      device = "/dev/disk/by-uuid/D85499D95499BAA8";
      fsType = "ntfs";
      depends = [ "/home" ];
      noCheck = true;
      options = [
        "rw"
        "relatime"
        "nofail"
        "uid=1000"
        "gid=100"
        "umask=022"
        "iocharset=utf8"
        "case_sensitive"
        "errors=continue"
        "mft_zone_multiplier=1"
      ];
    };

    "/home/wsdlly02/Disks/Files-M" = {
      device = "/dev/disk/by-uuid/666A5B1D6A5AE8F7";
      fsType = "ntfs";
      depends = [ "/home" ];
      noCheck = true;
      options = [
        "rw"
        "relatime"
        "nofail"
        "uid=1000"
        "gid=100"
        "umask=022"
        "iocharset=utf8"
        "case_sensitive"
        "errors=continue"
        "mft_zone_multiplier=1"
      ];
    };
  };
}
