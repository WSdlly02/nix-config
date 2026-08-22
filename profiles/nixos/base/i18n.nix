{
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [
      # "C.UTF-8/UTF-8" is already included
      # "en_US.UTF-8/UTF-8" is already included
      "zh_CN.UTF-8/UTF-8"
    ];
    # extraLocaleSettings = {};
  };
  time.timeZone = "Asia/Singapore";
  # Select internationalisation properties.
  /*
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
      useXkbConfig = true; # use xkb.options in tty.
    };
  */
}
