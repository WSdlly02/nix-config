{
  programs = {
    # gamescope = {
    #   enable = true;
    #   capSysNice = true;
    # };
    # opengamepadui = {
    #   enable = true;
    #   extraPackages = with pkgs; [
    #     gamescope
    #   ];
    #   inputplumber.enable = true;
    #   gamescopeSession.enable = true;
    #   powerstation.enable = true;
    # };
    steam = {
      enable = true;
      # extraPackages = with pkgs; [
      #   gamescope
      #   (writeShellScriptBin "steamos-session-select" ''
      #     steam -shutdown
      #   '')
      # ];
      localNetworkGameTransfers.openFirewall = true;
      # gamescopeSession.enable = true;
      protontricks.enable = true;
    };
  };
}
