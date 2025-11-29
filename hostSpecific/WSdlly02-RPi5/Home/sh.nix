{
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        set WSdlly02_PC_MAC_ADDR 10:ff:e0:35:6a:95
        set $WSdlly02_PC_hostname 100.64.16.64
        alias exportproxy='export https_proxy=http://$WSdlly02_PC_hostname:7890 http_proxy=http://$WSdlly02_PC_hostname:7890 all_proxy=http://$WSdlly02_PC_hostname:7890'
      '';
    };
  };
}
