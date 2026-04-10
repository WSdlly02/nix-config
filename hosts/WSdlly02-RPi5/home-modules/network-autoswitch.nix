{ pkgs, ... }:
{
  xdg.configFile = {
    "net-failover.sh" = pkgs.writeShellScript "net-failover.sh" ''
      ETH="end0"
      WLAN="wlan0"
      HOST_IP="10.42.0.1"

      if [[ $(cat /sys/class/net/$ETH/carrier) -eq 1 ]]; then
          if ping -c1 -W1 $HOST_IP &>/dev/null; then
              echo "Ethernet up, host reachable -> use wired"
              ip route replace default dev $ETH metric 100
          else
              echo "Ethernet link up but host unreachable -> switch WiFi"
              ip route replace default dev $WLAN metric 200
          fi
      else
          echo "Ethernet link down -> switch WiFi"
          ip route replace default dev $WLAN metric 200
      fi
    '';
    "99-net-failover.rules".text = ''
      ACTION=="change", SUBSYSTEM=="net", KERNEL=="eth0", RUN+="/usr/local/bin/net-failover.sh"
    '';
  };
}
