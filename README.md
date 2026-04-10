# nix-config

个人多机器 NixOS / Home Manager Flake 配置仓库。

当前结构已经完成从旧的 `hostSpecific/` / `modules/` 方案迁移到 `hosts/` + `profiles/`：

- `hosts/`：每台机器的入口与主机专属模块
- `profiles/nixos/`：系统级可复用 profile
- `profiles/home/`：Home Manager 可复用 profile
- `lib/`：共享辅助函数与 overlay 组装
- `pkgs/`：自定义包与开发 shell

当前由 `flake.nix` 暴露的主机：

- `WSdlly02-PC`
- `WSdlly02-RPi5`
- `WSdlly02-WSL`
- `WSdlly02-SRV`
- `Lily-PC`

当前由 `flake.nix` 暴露的 Home 配置：

- `wsdlly02@WSdlly02-PC`
- `wsdlly02@WSdlly02-RPi5`
- `wsdlly02@WSdlly02-WSL`

常用命令：

```bash
nixos-rebuild build --flake .#WSdlly02-PC
home-manager build --flake .#wsdlly02@WSdlly02-PC
nix flake check
```

更详细的结构说明见 [NIX_CONFIG_ARCHITECTURE.md](/home/wsdlly02/Documents/nix-config/NIX_CONFIG_ARCHITECTURE.md)。
