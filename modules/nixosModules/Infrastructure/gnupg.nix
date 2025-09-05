{
  lib,
  enableInfrastructure,
  ...
}:
lib.mkIf enableInfrastructure {
  programs.gnupg = {
    agent = {
      enable = true;
      enableSSHSupport = true;
      enableBrowserSocket = true;
      enableExtraSocket = true;
    };
  };
}
