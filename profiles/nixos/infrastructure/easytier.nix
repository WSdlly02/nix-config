{
  config,
  ...
}:
let
  user = config.my.mainUser.name;
in
{
  virtualisation.quadlet.containers.easytier = {
    containerConfig = {
      image = "docker.io/easytier/easytier:latest";
      networks = [ "host" ];
      volumes = [
        "/home/${user}/.config/easytier:/etc/easytier"
        "/etc/machine-id:/etc/machine-id:ro"
      ];
      addCapabilities = [
        "NET_ADMIN"
        "NET_RAW"
      ];
      devices = [ "/dev/net/tun" ];
      exec = [
        "--config-dir"
        "/etc/easytier"
      ];
      autoUpdate = "registry";
    };

    serviceConfig = {
      Delegate = true;
      Restart = "always";
    };

    unitConfig = {
      Description = "EasyTier in Podman container";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
  };
}
