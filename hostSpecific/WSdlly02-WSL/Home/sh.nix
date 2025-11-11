{
  programs = {
    fish = {
      enable = true;
      shellAliases = {
        dl = "aria2c -d /mnt/c/Users/WSdlly02/Downloads --allow-overwrite=true --max-tries=5 --max-file-not-found=2 --max-concurrent-downloads=16 --connect-timeout=5 --timeout=5 --split=16 --min-split-size=2M --lowest-speed-limit=20K --max-connection-per-server=16 --uri-selector=feedback";
      };
    };
  };
}
