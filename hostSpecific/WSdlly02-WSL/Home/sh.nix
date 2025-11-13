{
  programs = {
    fish = {
      enable = true;
      shellAliases = {
        dl = "aria2c -x 16 -s 16 -k 1M -d /mnt/c/Users/WSdlly02/Downloads --allow-overwrite=true --file-allocation=none --continue=true";
      };
    };
  };
}
