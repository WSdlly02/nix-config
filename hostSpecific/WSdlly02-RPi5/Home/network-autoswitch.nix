{ pkgs, ... }:
{
  xdg.configFile = {
    "net-failover.sh" = pkgs.writeShellScript "net-failover.sh" ''
      ETH="end0"        # 有线网卡名
      WLAN="wlan0"      # WiFi 网卡名
      HOST_IP="10.42.0.1"   # 主机IP

      # 检测 carrier
      if [[ $(cat /sys/class/net/$ETH/carrier) -eq 1 ]]; then
          # 物理链路存在，再试着 ping 主机
          if ping -c1 -W1 $HOST_IP &>/dev/null; then
              echo "Ethernet up, host reachable → 使用有线"
              ip route replace default dev $ETH metric 100
          else
              echo "Ethernet link up but host unreachable → 切换 WiFi"
              ip route replace default dev $WLAN metric 200
          fi
      else
          echo "Ethernet link down → 切换 WiFi"
          ip route replace default dev $WLAN metric 200
      fi
    '';
    "99-net-failover.rules".text = ''
      ACTION=="change", SUBSYSTEM=="net", KERNEL=="eth0", RUN+="/usr/local/bin/net-failover.sh"
    '';
  };
}
