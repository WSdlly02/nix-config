# NTFS Disks mounting
{
  fileSystems = {
    "/home/wsdlly02/Disks/Files" = {
      device = "/dev/disk/by-uuid/D85499D95499BAA8";
      # Avoid the ntfs sparse-file extent validation regression affecting qcow2.
      # https://github.com/namjaejeon/linux-ntfs/issues/96
      fsType = "ntfs3";
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
        "gid=100"
        "umask=022"
        "iocharset=utf8"
      ];
    };
  };
}
