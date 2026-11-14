# NixOS & Home Manager 配置架构说明

## 概述

这个仓库使用 Flake 管理多台机器的 NixOS 与 Home Manager 配置。当前架构已经完成迁移，入口统一收敛到 `hosts/`，可复用逻辑统一收敛到 `profiles/`，不再依赖旧的 `hostSpecific/`、`hostSystemSpecific`、`hostUserSpecific` 设计。

## 当前目录结构

```text
nix-config/
├── flake.nix
├── flake.lock
├── README.md
├── NIX_CONFIG_ARCHITECTURE.md
├── REFORM_ROADMAP.md
├── lib/
├── hosts/
├── profiles/
└── pkgs/
```

各目录职责：

- `flake.nix`：唯一入口，定义 `inputs`、`nixosConfigurations`、`homeConfigurations`、overlay、devShell 和 formatter。
- `lib/`：仓库级辅助函数与通用 overlay，目前核心是 `pkgs'` 和对 `buildEnv` 的稳定化包装。
- `hosts/`：每台机器的主入口，以及无法抽象为共享 profile 的主机专属模块。
- `profiles/nixos/`：系统级可复用能力集合。
- `profiles/home/`：Home Manager 侧的共享 profile。
- `pkgs/`：仓库自定义包、dev shell 和格式化相关定义。

## Flake 组装方式

`flake.nix` 只负责两件事：

1. 为每个配置注入 `inputs`
2. 将每个配置指向各自的 `hosts/<name>` 入口

当前约定：

- 每个 `nixosConfigurations.<name>` 都显式设置 `specialArgs = { inherit inputs; };`
- 每个 `homeConfigurations."wsdlly02@<host>"` 都显式设置 `extraSpecialArgs = { inherit inputs; };`
- 不再通过 `inputs.self.nixosModules.default` 或 `inputs.self.homeModules.default` 注入旧式聚合模块

## NixOS 层

### 1. 主机入口：`hosts/`

当前活跃主机入口：

- `hosts/WSdlly02-PC/`
- `hosts/WSdlly02-RPi5/`
- `hosts/WSdlly02-WSL/`
- `hosts/WSdlly02-SRV/`

典型主机入口负责：

- 导入共享 profile
- 导入本机 `hardware.nix` / `system.nix`
- 放置极少量本机特有覆写，例如磁盘、驱动、网卡、打印机、特定服务参数

以 [hosts/WSdlly02-PC/default.nix](/home/wsdlly02/Documents/nix-config/hosts/WSdlly02-PC/default.nix) 为例，它导入：

- `profiles/nixos/base.nix`
- `profiles/nixos/development.nix`
- `profiles/nixos/desktop.nix`
- `profiles/nixos/gaming.nix`
- `profiles/nixos/infrastructure.nix`
- 若干本机模块

### 2. 系统级共享 profile：`profiles/nixos/`

当前主要 profile：

- `profiles/nixos/base.nix`
- `profiles/nixos/development.nix`
- `profiles/nixos/desktop.nix`
- `profiles/nixos/gaming.nix`
- `profiles/nixos/infrastructure.nix`

它们的职责划分如下。

#### `profiles/nixos/base.nix`

PC、RPi5 和 WSL 共用本文件中的账户、sudo、Nix、本地化、Neovim、基础服务和工具配置。PC 的 SMART 监测和 Btrfs 定期 scrub 在其主机入口中设置。

#### `profiles/nixos/development.nix`

PC 和 WSL 共用编译器、语言工具链、uv 配置和 nix-ld 运行库。Codex Desktop 由 PC 入口单独导入并配置。

#### `profiles/nixos/desktop.nix`

桌面体验 profile，负责：

- Plasma 6
- fcitx5
- Sunshine
- 字体
- 桌面常用 GUI 应用

PC 的 LACT 显卡风扇和功耗配置位于 `hosts/WSdlly02-PC/hardware-modules/gpu.nix`。

#### `profiles/nixos/gaming.nix`

游戏相关 profile，负责：

- Steam、局域网游戏传输和 Protontricks
- Gamemode
- Minecraft / Heroic / MangoHud 等游戏相关程序

#### `profiles/nixos/infrastructure.nix`

PC 和 RPi5 共用同一组网络、防火墙、DNS、代理、组网、SSH、蓝牙与音频配置，以及 GnuPG、getty 和内核参数。防火墙扩展选项与使用它们的配置都在本文件中。两台主机各自的 PipeWire 用户服务设置位于各自的主机入口。

## Home Manager 层

### 1. 共享 Home 配置

PC、WSL 和 RPi5 都导入 [base.nix](profiles/home/base.nix)，共用账户、Bash、Fish、direnv、常用工具以及 Cargo、npm 和 Go 的用户环境路径。

### 2. 主机 Home 入口

每个 Home 配置只指向自己的 host 入口：

- [hosts/WSdlly02-PC/home.nix](/home/wsdlly02/Documents/nix-config/hosts/WSdlly02-PC/home.nix)
- [hosts/WSdlly02-WSL/home.nix](/home/wsdlly02/Documents/nix-config/hosts/WSdlly02-WSL/home.nix)
- [hosts/WSdlly02-RPi5/home.nix](/home/wsdlly02/Documents/nix-config/hosts/WSdlly02-RPi5/home.nix)

Syncthing 用户服务只在 PC 的 Home 入口启用，管理界面监听 `127.0.0.1:8384`。

## 当前设计原则

这次迁移之后，仓库遵循下面三条规则：

1. 功能开关优先通过显式 `imports` 表达，而不是额外造布尔选项。
2. 能直接落回上游原生 option 的配置，就不保留自定义中间层。
3. 确实需要跨模块共享的主机事实，只保留窄接口，不再使用大杂烩 attrset。

对应到当前代码上，就是：

- `hostSystemSpecific` 已删除
- `hostUserSpecific` 已删除
- 主机配置统一从 `hosts/` 进入
- 共享逻辑统一从 `profiles/` 进入

## 与旧架构的差异

已经完成的变化：

- 旧的 `hostSpecific/` 主入口已经全部迁出
- 旧的 `modules/homeModules` 已迁入 `profiles/home/base.nix`
- 旧的 NixOS 聚合逻辑已迁入 `profiles/nixos/*`
- `flake.nix` 不再依赖旧式默认模块导出
- 迁移期使用过的结果基准与一致性脚本已经移除

因此，当前文档只描述现行结构，不再保留迁移过程中的兼容说明。
