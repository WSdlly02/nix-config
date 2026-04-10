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
- 每个 `homeConfigurations.<user@host>` 都显式设置 `extraSpecialArgs = { inherit inputs; };`
- 不再通过 `inputs.self.nixosModules.default` 或 `inputs.self.homeModules.default` 注入旧式聚合模块

## NixOS 层

### 1. 主机入口：`hosts/`

当前活跃主机入口：

- `hosts/WSdlly02-PC/`
- `hosts/WSdlly02-RPi5/`
- `hosts/WSdlly02-WSL/`
- `hosts/WSdlly02-SRV/`
- `hosts/Lily-PC/`

典型主机入口负责：

- 导入共享 profile
- 导入用户 profile
- 导入本机 `hardware.nix` / `system.nix`
- 放置极少量本机特有覆写，例如磁盘、驱动、网卡、打印机、特定服务参数

以 [hosts/WSdlly02-PC/default.nix](/home/wsdlly02/Documents/nix-config/hosts/WSdlly02-PC/default.nix) 为例，它只组合：

- `profiles/nixos/base`
- `profiles/nixos/development`
- `profiles/nixos/desktop`
- `profiles/nixos/gaming`
- `profiles/nixos/infrastructure`
- `profiles/nixos/base/user-wsdlly02.nix`
- 若干本机模块

### 2. 系统级共享 profile：`profiles/nixos/`

当前主要 profile：

- `profiles/nixos/base/`
- `profiles/nixos/development/`
- `profiles/nixos/desktop/`
- `profiles/nixos/gaming/`
- `profiles/nixos/infrastructure/`

它们的职责划分如下。

#### `profiles/nixos/base/`

提供所有主机都可复用的基础能力，包括：

- [options.nix](/home/wsdlly02/Documents/nix-config/profiles/nixos/base/options.nix)：定义少量保留下来的窄接口
- [common.nix](/home/wsdlly02/Documents/nix-config/profiles/nixos/base/common.nix)：基础工具与通用系统配置
- [i18n.nix](/home/wsdlly02/Documents/nix-config/profiles/nixos/base/i18n.nix)：时区、本地化、输入法基础
- [neovim.nix](/home/wsdlly02/Documents/nix-config/profiles/nixos/base/neovim.nix)：Neovim
- [nix.nix](/home/wsdlly02/Documents/nix-config/profiles/nixos/base/nix.nix)：Nix 本身的系统级配置
- [sudo.nix](/home/wsdlly02/Documents/nix-config/profiles/nixos/base/sudo.nix)：sudo 行为
- [smartd.nix](/home/wsdlly02/Documents/nix-config/profiles/nixos/base/smartd.nix)：smartd
- [btrfs-scrub.nix](/home/wsdlly02/Documents/nix-config/profiles/nixos/base/btrfs-scrub.nix)：Btrfs scrub
- [user-wsdlly02.nix](/home/wsdlly02/Documents/nix-config/profiles/nixos/base/user-wsdlly02.nix)、[user-lily.nix](/home/wsdlly02/Documents/nix-config/profiles/nixos/base/user-lily.nix)：用户 profile

当前仅保留两个自定义接口：

- `config.my.mainUser.name`
- `config.my.networking.firewall.*`

它们用于表达“主交互用户是谁”以及“仓库自定义的防火墙扩展语义”。其余原先塞进大桶里的配置已经回归原生 NixOS option 或显式 `imports`。

#### `profiles/nixos/development/`

开发环境 profile，提供编译器、语言工具链与相关环境变量。

#### `profiles/nixos/desktop/`

桌面体验 profile，负责：

- Plasma 6
- fcitx5
- Sunshine
- 字体
- 桌面常用 GUI 应用

#### `profiles/nixos/gaming/`

游戏相关 profile，负责：

- Gamescope
- Gamemode
- Minecraft / Heroic / MangoHud 等游戏相关程序

#### `profiles/nixos/infrastructure/`

基础设施 profile，负责网络、远程访问、代理、音频和共享服务等能力，包含：

- Avahi
- dnsmasq
- EasyTier
- GnuPG
- Mihomo
- 基础 networking / NetworkManager
- OpenSSH
- PipeWire
- sysctl
- Tailscale

该 profile 的语义是“导入即启用”，不再依赖布尔开关驱动。

## Home Manager 层

### 1. 共享 Home profile：`profiles/home/`

当前 Home 侧主要分为：

- `profiles/home/base/`
- `profiles/home/workstation/`

#### `profiles/home/base/`

提供所有 Home 配置共享的基础能力，包括：

- `direnv`
- shell 基础配置
- `home-manager` 自管理
- `nh`
- `nixd`、`nixfmt`、`nix-diff`、`nix-tree`、`yazi` 等常用工具

#### `profiles/home/workstation/`

提供偏工作站环境的 Home 配置，供桌面主机复用。

### 2. 主机 Home 入口

每个 Home 配置只指向自己的 host 入口：

- [hosts/WSdlly02-PC/home.nix](/home/wsdlly02/Documents/nix-config/hosts/WSdlly02-PC/home.nix)
- [hosts/WSdlly02-WSL/home.nix](/home/wsdlly02/Documents/nix-config/hosts/WSdlly02-WSL/home.nix)
- [hosts/WSdlly02-RPi5/home.nix](/home/wsdlly02/Documents/nix-config/hosts/WSdlly02-RPi5/home.nix)

用户信息直接通过 `home.username`、`home.homeDirectory` 等原生 Home Manager option 表达，不再使用 `hostUserSpecific`。

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
- 旧的 `modules/homeModules` 已迁入 `profiles/home/base/`
- 旧的 NixOS 聚合逻辑已迁入 `profiles/nixos/*`
- `flake.nix` 不再依赖旧式默认模块导出
- 迁移期使用过的结果基准与一致性脚本已经移除

因此，当前文档只描述现行结构，不再保留迁移过程中的兼容说明。
