{ lib, enableInfrastructure, ... }:
lib.mkIf enableInfrastructure {
  services.gitDaemon = {
    enable = true;
    port = 19418;
    basePath = "/srv/gitDaemon";
    exportAll = true;
  };
}
