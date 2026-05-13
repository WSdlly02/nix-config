{
  config,
  pkgs,
  ...
}:
{
  services.code-server = {
    enable = true;
    host = "0.0.0.0";
    port = 8500;
    auth = "password";
    hashedPassword = "a5ecd93dd284ee022487f50c9dcbb6cb99c8debfa487fa68aec454ed17c025da";
    user = config.my.mainUser.name;
    group = "users";
    userDataDir = "/home/${config.my.mainUser.name}/.config/code-server";
    extensionsDir = "/home/${config.my.mainUser.name}/.local/share/code-server/extensions";
    extraPackages = with pkgs; [
      rust-analyzer
      rustfmt
      clippy
      gcc
      pkg-config
    ];
    disableTelemetry = true;
    disableUpdateCheck = true;
    disableGettingStartedOverride = true;
  };
}
