{
  lib,
  enableInfrastructure,
  ...
}:
lib.mkIf enableInfrastructure {
  programs.ccache = {
    enable = true;
    packageNames = [ ];
    # Which adds ccacheStdenv to overlays
  };
}
