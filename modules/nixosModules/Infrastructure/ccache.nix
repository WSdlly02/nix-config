{
  ...
}:
{
  programs.ccache = {
    enable = true;
    packageNames = [ ];
    # Which adds ccacheStdenv to overlays
  };
}
