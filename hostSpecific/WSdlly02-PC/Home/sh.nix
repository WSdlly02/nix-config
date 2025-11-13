{
  programs = {
    fish = {
      enable = true;
      shellAliases = {
        dl = "aria2c -x 16 -s 16 -k 1M -d ~/Downloads --allow-overwrite=true --file-allocation=none --continue=true";
      };
    };
  };
}
