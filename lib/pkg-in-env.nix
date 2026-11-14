# 临时用 nix run .#pkg-in-env 启动 PC 系统配置中的程序，所有平台的导出都指向这台 PC 的包。
{ inputs }:
let
  pname = "codex-desktop-appshots-codex-micro-computer-use-linux-global-dictation-pet-overlay-remote-control-ui-remote-mobile-control";
  packages = inputs.self.nixosConfigurations.WSdlly02-PC.config.environment.systemPackages;
  matches = builtins.filter (p: (p.pname or "") == pname) packages;
in
if matches == [ ] then throw "Package not found" else builtins.head matches
