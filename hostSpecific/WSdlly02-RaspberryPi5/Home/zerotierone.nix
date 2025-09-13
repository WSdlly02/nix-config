{ pkgs, ... }:
let
  zerotier = pkgs.zerotierone;
  networkId = "632ea290852ba225";
  stateDir = "/var/lib/zerotier-one/networks.d";
in
{
  xdg.configFile."zerotierone.service".text = ''
    [Unit]
    Description=ZeroTier One Service
    After=network.target
    Wants=network-online.target

    [Service]
    ExecStartPre=/bin/mkdir -p ${stateDir}
    ExecStartPre=/bin/chmod 700 ${stateDir}
    ExecStartPre=/bin/chown -R root:root ${stateDir}
    ExecStart=${zerotier}/bin/zerotier-one -d
    ExecStartPost=${zerotier}/bin/zerotier-cli join ${networkId}
    Restart=always
    KillMode=process
    TimeoutStopSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
