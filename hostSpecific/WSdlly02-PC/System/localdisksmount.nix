# NTFS Disks mounting
{
  fileSystems = {
    "/home/wsdlly02/Disks/Files" = {
      device = "/dev/disk/by-uuid/D85499D95499BAA8";
      fsType = "ntfs3";
      depends = [ "/home" ];
      noCheck = true;
      options = [
        "rw"
        "relatime"
        "nofail"
        "uid=1000"
        "gid=1000"
        "umask=000"
        "iocharset=utf8"
        "discard"
        "prealloc"
      ];
    };

    "/home/wsdlly02/Disks/Files-M" = {
      device = "/dev/disk/by-uuid/666A5B1D6A5AE8F7";
      fsType = "ntfs3";
      depends = [ "/home" ];
      noCheck = true;
      options = [
        "rw"
        "relatime"
        "nofail"
        "uid=1000"
        "gid=1000"
        "umask=000"
        "iocharset=utf8"
        "discard"
        "prealloc"
      ];
    };
  };
}
