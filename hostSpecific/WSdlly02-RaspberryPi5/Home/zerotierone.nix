{ pkgs, ... }:
let
  zerotier = pkgs.zerotierone;
  networkId = "632ea290852ba225";
  stateDir = "/var/lib/zerotier-one";
in
{
  xdg.configFile."zerotierone.service".text = ''
    [Unit]
    Description=ZeroTier One Service
    After=network.target
    Wants=network-online.target

    [Service]
    ExecStartPre=/bin/mkdir -p ${stateDir}/networks.d
    ExecStartPre=/bin/chmod 700 ${stateDir}
    ExecStartPre=/bin/chown -R root:root ${stateDir}
    ExecStartPre=/bin/touch ${stateDir}/networks.d/${networkId}.conf
    ExecStart=${zerotier}/bin/zerotier-one -p9993
    Restart=always
    KillMode=process
    TimeoutStopSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
