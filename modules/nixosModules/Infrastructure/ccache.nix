{
  config,
  lib,
  enableInfrastructure,
  ...
}:
{
  config = lib.mkIf enableInfrastructure {
    programs.ccache = {
      enable = true;
      packageNames = [ ] ++ config.hostSystemSpecific.programs.ccache.extraPackageNames;
      # Which adds ccacheStdenv to overlays
    };
  };
}
