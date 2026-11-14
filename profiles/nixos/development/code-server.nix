{ pkgs, ... }:
{
  services.code-server = {
    enable = true;
    host = "0.0.0.0";
    port = 8500;
    auth = "password";
    hashedPassword = "a5ecd93dd284ee022487f50c9dcbb6cb99c8debfa487fa68aec454ed17c025da";
    user = "wsdlly02";
    group = "users";
    userDataDir = "/home/wsdlly02/.config/code-server";
    extensionsDir = "/home/wsdlly02/.local/share/code-server/extensions";
    extraPackages = with pkgs; [
      gcc
      pkg-config
    ];
    disableTelemetry = true;
    disableUpdateCheck = true;
    disableGettingStartedOverride = true;
  };
}
