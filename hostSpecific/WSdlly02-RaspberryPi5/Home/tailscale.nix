{ pkgs, ... }:
{
  xdg.configFile = {
    "tailscaled-override.conf".text = ''
      [Service]
      ExecStartPost=${pkgs.writeShellScript "tailscale-up.sh" ''
        while [[ "$(/usr/bin/tailscale status --json --peers=false | /usr/bin/jq -r '.BackendState')" == "NoState" ]]; do
          sleep 0.5
        done
        status=$(/usr/bin/tailscale status --json --peers=false | /usr/bin/jq -r '.BackendState')
        if [[ "$status" == "NeedsLogin" || "$status" == "NeedsMachineAuth" ]]; then
          /usr/bin/tailscale up --auth-key "$(cat /var/lib/tailscale/authkey)" --ssh --advertise-exit-node --accept-routes --accept-dns
        fi
      ''}
    '';
  };
}
