# nix-config

三台主机的 NixOS 和 Home Manager 配置，用户为 `wsdlly02`。

## 配置入口

| 主机 | NixOS | Home Manager |
| --- | --- | --- |
| WSdlly02-PC | [nixos.nix](hosts/WSdlly02-PC/nixos.nix) | [home.nix](hosts/WSdlly02-PC/home.nix) |
| WSdlly02-RPi5 | [nixos.nix](hosts/WSdlly02-RPi5/nixos.nix) | [home.nix](hosts/WSdlly02-RPi5/home.nix) |
| WSdlly02-WSL | [nixos.nix](hosts/WSdlly02-WSL/nixos.nix) | [home.nix](hosts/WSdlly02-WSL/home.nix) |

主机专属配置放在各自主机目录。要看某台机器启用了哪些共享配置，直接看入口中的 `imports`。系统级配置在 [profiles/nixos/](profiles/nixos/)，三台机器共用的用户配置在 [profiles/home/base.nix](profiles/home/base.nix)。

自定义包在 [pkgs/default.nix](pkgs/default.nix) 登记一次，[flake.nix](flake.nix) 从这里生成默认 overlay 和各平台的 `legacyPackages`。

## 构建

在仓库根目录运行。构建其他主机时，将命令中的 `WSdlly02-PC` 换成表中的主机名。

```bash
nixos-rebuild build --flake .#WSdlly02-PC
home-manager build --flake .#wsdlly02@WSdlly02-PC
nix flake check
```
