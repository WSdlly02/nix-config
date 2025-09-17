{
  xdg.configFile."tailscaled-override.conf".text = ''
    [Service]
    ExecStartPost=/usr/sbin/tailscale up --auth-key=$(cat /var/lib/tailscale/authkey) --ssh --advertise-exit-node
  '';
}
