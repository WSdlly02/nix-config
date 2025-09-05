{
  config,
  lib,
  enableInfrastructure,
  ...
}:
lib.mkIf enableInfrastructure {
  programs.ccache = {
    enable = true;
    packageNames = [ ] ++ config.hostSystemSpecific.programs.ccache.extraPackageNames;
    # Which adds ccacheStdenv to overlays
  };
}
