{
  config,
  lib,
  pkgs,
  enableInfrastructure,
  ...
}:
let
  config-toml = pkgs.writeText "config.toml" ''
    interval_seconds = 60
    filename_prefix = "gen-"
    allow_types = ["_http._tcp"]

    [port_map]
    "10.64.16.10:8000" = 8080

    [[txt_rewrite]]
    from = "10.64.16.10:8000"
    to   = "wsdlly02-pc.local:8080"
  '';
in
lib.mkIf enableInfrastructure {
  services.avahi = {
    enable = true;
    allowInterfaces = [
      "enp14s0"
      "wlp15s0"
    ];
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
    # nssmdns6 = true;
    nssmdns4 = true;
    ipv6 = true;
    ipv4 = true;
    extraConfig = ''
      [server]
      disallow-other-stacks=yes
    '';
  };
  /*
    systemd.services.mdns-collector-sync = {
      description = "Sync generated Avahi services from drop-in dir";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "mdns-dropin-sync.sh" ''
          set -euo pipefail

          SRC="/var/lib/mdns-collector/generated-services"
          DST="/etc/avahi/services"

          # 同步（只放我们生成的文件，避免污染手写文件）
          # 约定：生成文件都以 "gen-" 开头
          mkdir -p "$DST"

          # 删除旧的 gen- 文件
          find "$DST" -maxdepth 1 -type f -name 'gen-*.service' -delete

          # 拷贝新的
          shopt -s nullglob
          for f in "$SRC"/gen-*.service; do
            install -m 0644 "$f" "$DST/$(basename "$f")"
          done

          # 不必重启
          # systemctl restart avahi-daemon.service
        '';
      };
    };
    systemd.paths.mdns-collector-sync = {
      description = "Watch mdns drop-in dir for changes";
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        PathChanged = "/var/lib/mdns-collector/generated-services";
        PathModified = "/var/lib/mdns-collector/generated-services";
      };
    };
    virtualisation.quadlet.containers.mdns-collector = {
      containerConfig = {
        image = "ghcr.io/wsdlly02/my-codes/mdns-collector:latest";
        networks = [ config.virtualisation.quadlet.networks.vlan-with-mdns.ref ];
        ip = "10.64.16.2";
        volumes = [
          "/var/lib/mdns-collector/generated-services:/out"
          #"/etc/mdns-collector/config.toml:/config.toml:ro"
          "${config-toml}:/config.toml:ro"
        ];
        user = "0";
        autoUpdate = "registry";
      };

      serviceConfig = {
        Delegate = true;
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/lib/mdns-collector/generated-services";
        Restart = "always";
      };

      unitConfig.Description = "mdns collector (mdnsnet -> host avahi static)";
    };
    virtualisation.quadlet.networks.vlan-with-mdns.networkConfig = {
      driver = "bridge";
      ipamDriver = "host-local";
      ipv6 = false;
      name = "vlan-with-mdns";
      gateways = [ "10.64.16.1" ];
      subnets = [ "10.64.16.0/24" ];
    };
  */
}
