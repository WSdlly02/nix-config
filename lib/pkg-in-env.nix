# Run the package from the environment
{ inputs }:
let
  pname = "codex-desktop-appshots-codex-micro-computer-use-linux-global-dictation-pet-overlay-remote-control-ui-remote-mobile-control";
  packages = inputs.self.nixosConfigurations.WSdlly02-PC.config.environment.systemPackages;
  matches = builtins.filter (p: (p.pname or "") == pname) packages;
in
if matches == [ ] then throw "Package not found" else builtins.head matches
