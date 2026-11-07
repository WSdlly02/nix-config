{ pkgs, lib, ... }:
{
  systemd.user.services.atrust-rs = {
    Unit.Description = "aTrust client service";
    Service.ExecStart = "${pkgs.atrust-rs}/bin/atrust-client serve --credentials %h/Documents/atrust-rs/.env --node-cert-sha256 6c289777da91769114efa5acd35d1b1a3c078d20fb1a2da36bb5e1bb0679642b";
    Install.WantedBy = lib.mkForce [ ]; # start on demand
  };
}
