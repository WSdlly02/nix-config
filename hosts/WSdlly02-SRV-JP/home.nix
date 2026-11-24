{ inputs, pkgs' }:
let
  homeModule = {
    imports = [ ../../profiles/home/base.nix ];

    home.stateVersion = "26.11";

    virtualisation.quadlet.containers = {
      easytier = {
        unitConfig = {
          After = "network-online.target";
          Wants = "network-online.target";
        };
        containerConfig = {
          image = "docker.io/easytier/easytier:latest";
          networks = [ "host" ];
          exec = "--relay-network-whitelist=wsdlly02-easytier";
          autoUpdate = "registry";
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = 3;
        };
      };
      mihomo-updater-resolver = {
        containerConfig = {
          image = "ghcr.io/wsdlly02/my-codes/mihomo-updater-resolver:latest";
          networks = [ "host" ];
          volumes = [
            "%h/Documents/my-codes/SOPs/mihomo-updater/config.yaml:/app/config.yaml:ro"
            "%h/Documents/my-codes/SOPs/mihomo-updater/ACL4SSR_Online_Full.ini:/app/ACL4SSR_Online_Full.ini:ro"
            "%h/Documents/my-codes/SOPs/mihomo-updater/cache:/app/cache"
            "%h/Documents/my-codes/SOPs/mihomo-updater/vps-configs:/app/vps-configs"
          ];
          environmentFiles = [ "%h/Documents/my-codes/SOPs/mihomo-updater/.env" ];
          autoUpdate = "registry";
        };
        serviceConfig = {
          Delegate = true;
          Restart = "on-failure";
          TimeoutStartSec = 900;
        };
      };
    };
    systemd.user.services.yunzhizuo-server = {
      Unit = {
        Description = "Yunzhizuo demo backend (trial)";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "exec";
        ExecStart = "%h/.local/bin/yunzhizuo-server";
        Environment = [
          "YUNZHIZUO_ADDR=127.0.0.1:3080"
          "YUNZHIZUO_STRATEGY=fair-v1"
          "YUNZHIZUO_DB=%S/yunzhizuo/demo.sqlite3"
        ];
        StateDirectory = "yunzhizuo";
        KillSignal = "SIGINT";
        TimeoutStopSec = 10;
        Restart = "on-failure";
        RestartSec = 2;
        NoNewPrivileges = true;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
in
inputs.home-manager.lib.homeManagerConfiguration {
  extraSpecialArgs = { inherit inputs; };
  pkgs = pkgs' { system = "x86_64-linux"; };
  modules = [
    inputs.quadlet-nix.homeManagerModules.quadlet
    homeModule
  ];
}
