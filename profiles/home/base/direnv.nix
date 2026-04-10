{
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    # enableFishIntegration = true; Force enabled
    nix-direnv.enable = true;
  };
}
