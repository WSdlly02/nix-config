{
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/9c058d11-63b8-4a19-8884-28519aaa8b16";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "ssd"
        "discard=async"
        "space_cache=v2"
        "compress=zstd"
        "subvol=@"
      ];
    };
    "/nix" = {
      device = "/dev/disk/by-uuid/a7715c2f-c6e1-48a9-b891-4fe319c6c727";
      fsType = "ext4";
      options = [
        "rw"
        "noatime"
      ];
    };
    "/home" = {
      device = "/dev/disk/by-uuid/9c058d11-63b8-4a19-8884-28519aaa8b16";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "ssd"
        "discard=async"
        "space_cache=v2"
        "compress=zstd"
        "subvol=@home"
      ];
    };
    "/var/cache" = {
      device = "/dev/disk/by-uuid/9c058d11-63b8-4a19-8884-28519aaa8b16";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "ssd"
        "discard=async"
        "space_cache=v2"
        "compress=zstd"
        "subvol=@var-cache"
      ];
    };
    "/var/log" = {
      device = "/dev/disk/by-uuid/9c058d11-63b8-4a19-8884-28519aaa8b16";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "ssd"
        "discard=async"
        "space_cache=v2"
        "compress=zstd"
        "subvol=@var-log"
      ];
    };
    "/var/tmp" = {
      device = "/dev/disk/by-uuid/9c058d11-63b8-4a19-8884-28519aaa8b16";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "ssd"
        "discard=async"
        "space_cache=v2"
        "compress=zstd"
        "subvol=@var-tmp"
      ];
    };
    "/efi" = {
      device = "/dev/disk/by-uuid/18B2-C53C";
      fsType = "vfat";
      options = [
        "rw"
        "relatime"
        "fmask=0022"
        "dmask=0022"
        "codepage=437"
        "iocharset=ascii"
        "shortname=mixed"
        "errors=remount-ro"
      ];
    };

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
