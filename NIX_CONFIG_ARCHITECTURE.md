# NixOS & Home Manager 配置架构说明

## 概述

这是一个用于管理多个设备的 NixOS 和 Home Manager 配置的 Flake 项目。项目采用模块化设计，支持多种设备类型，包括常规 PC、树莓派、WSL 等。

## 项目结构总览

从 `flake.nix` 出发，整个仓库大致分为四层：

1. 顶层：Flake 入口与文档（`flake.nix` / `flake.lock` / `README.md` / `NIX_CONFIG_ARCHITECTURE.md`）
2. 模块层：可复用的 NixOS / Home Manager 模块（`modules/`）
3. 主机层：每台机器的组合入口与主机专属模块（`hosts/`，遗留结构仍在 `hostSpecific/`）
4. 包与开发环境层：自定义包与开发 Shell（`pkgs/`）

### 顶层文件

```
├── flake.nix
├── flake.lock
├── README.md
└── NIX_CONFIG_ARCHITECTURE.md
```

- `flake.nix`  
  - 整个仓库的入口，定义 `inputs` 和 `outputs`。  
  - `inputs`：
    - `nixpkgs-unstable`：主要包源。
    - `home-manager`：Home Manager flake，`inputs.nixpkgs` 跟随 `nixpkgs-unstable`。
    - `nixos-raspberrypi`：提供 Raspberry Pi 5 的专用模块集合。
    - `nixos-wsl`：WSL 环境支持模块。
    - `my-codes`：个人代码仓库，提供 `overlays.exposedPackages`。
    - `zen-browser`：Zen 浏览器 flake，用于 Home 配置中的浏览器模块。
  - `outputs`（按功能分层）：
    - `lib.pkgs'`：封装 `nixpkgs` 导入逻辑，统一 overlay、配置和 `system`。
    - `nixosConfigurations`：为每台 NixOS 主机构建系统配置：
      - `"WSdlly02-PC"`：x86_64 PC，模块为 `self.nixosModules.default` + `./hosts/WSdlly02-PC`。
      - `"WSdlly02-RPi5"`：aarch64 树莓派 5，额外引入 `nixos-raspberrypi` 提供的树莓派模块。
      - `"WSdlly02-WSL"`：x86_64 WSL，额外引入 `nixos-wsl.nixosModules.default`。
      - `"Lily-PC"`：x86_64 PC，额外设置 `{ system.name = "Lily-PC"; }`。
    - `homeConfigurations`：为每个用户/主机组合构建 Home Manager 配置：
      - `"wsdlly02@WSdlly02-PC"`：`./profiles/home/base` + `zen-browser.homeModules.beta` + `./hosts/WSdlly02-PC/home.nix`。
      - `"wsdlly02@WSdlly02-WSL"`：`./profiles/home/base` + `./hostSpecific/WSdlly02-WSL/Home`。
      - `"wsdlly02@WSdlly02-RPi5"`：`./profiles/home/base` + `./hostSpecific/WSdlly02-RPi5/Home`。
    - `homeModules.default`：兼容性暴露入口，当前内部转发到 `./profiles/home/base`。
    - `nixosModules.default`：将 `./modules/nixosModules` 作为一个整体模块暴露，同时向模块传入 `inputs`。
    - `overlays`：
      - `default`：预留的全局 overlay（目前为空，占位）。
      - `exposedPackages`：从 `legacyPackages.${system}.exposedPackages` 中暴露包。
      - `libraryPackages`：从 `legacyPackages.${system}.libraryPackages` 中提供库用途的包。
    - `devShells.${system}`：
      - `aitools`：AI 工具开发 Shell（从 `./pkgs/devShells-aitools.nix`）。
      - `nixfmt`：Nixfmt 开发 Shell（从 `./pkgs/devShells-nixfmt.nix`）。
      - `default`：指向 `aitools`。
    - `formatter.${system}`：使用 `nixfmt-tree` 作为格式化工具。
    - `legacyPackages.${system}`：
      - `exposedPackages`：
        - `currentNixConfig`：打包当前 flake 源码。
        - `epson-inkjet-printer-201601w`：Epson 打印机驱动。
        - `fabric-survival`：Minecraft Fabric 生存服务器。
        - `rocmFHSEnv`：ROCm FHS 容器环境。
      - `libraryPackages`：目前为空。
      - `my-codes-exposedPackages`：引用 `my-codes` flake 暴露的包。
      - `nixpkgs-unstable`：将当前 `system` 下的 pkgs 实例以包形式暴露。

- `flake.lock`  
  - 锁定所有 `inputs` 的具体版本，保证构建可复现。

- `README.md`  
  - 仓库使用简介、基本命令等（高层说明）。

- `NIX_CONFIG_ARCHITECTURE.md`  
  - 本文件，详细解释架构与各文件职责。

## 核心组件

### 1. Flake 配置 (flake.nix)

#### 输入 (Inputs)
- `nixpkgs-unstable`: NixOS 不稳定频道，作为主要包源
- `home-manager`: 用户环境管理工具
- `nixos-raspberrypi`: 树莓派硬件模块集合
- `nixos-wsl`: WSL 支持模块
- `my-codes`: 用户自定义代码仓库
- `zen-browser`: Zen 浏览器 Flake

#### 输出 (Outputs)
- `nixosConfigurations`: NixOS 系统配置
- `homeConfigurations`: Home Manager 用户配置
- `nixosModules`: NixOS 自定义模块
- `homeModules`: Home Manager 自定义模块
- `overlays`: 包覆盖层
- `devShells`: 开发环境
- `packages`: 自定义包

## 模块层：modules/

### 1. NixOS 模块 (modules/nixosModules/)

目录结构：

```
modules/nixosModules/
├── default.nix
├── Daily/
│   └── default.nix
├── Development/
│   └── default.nix
└── Infrastructure/
    ├── avahi.nix
    ├── bluetooth.nix
    ├── ccache.nix
    ├── default.nix
    ├── getty.nix
    ├── gitDaemon.nix
    ├── gnupg.nix
    ├── i18n.nix
    ├── mihomo.nix
    ├── neovim.nix
    ├── networking.nix
    ├── networkmanager.nix
    ├── nix.nix
    ├── openssh.nix
    ├── pipewire.nix
    ├── samba.nix
    ├── smartdns.nix
    ├── static-web-server.nix
    ├── sudo.nix
    ├── sysctl.nix
    └── tmux.nix
```

- `modules/nixosModules/default.nix`  
  - 类型：NixOS 顶层模块。  
  - `imports`：
    - `./Daily`
    - `./Development`
    - `./Infrastructure`
  - 定义通用选项 `options.hostSystemSpecific`，由各主机在 `hostSpecific/*/default.nix` 中填充：
    - `boot.kernel.sysctl."vm.swappiness"`：内核参数默认值（整数）。
    - `enableBtrfsScrub`：是否启用 Btrfs scrub。
    - `enableDevEnv`：是否启用开发环境相关模块（暴露给 `_module.args.enableDevEnv`）。
    - `enableInfrastructure`：是否启用基础设施相关模块（暴露给 `_module.args.enableInfrastructure`）。
    - `enableBluetooth`：控制蓝牙模块。
    - `enableSmartd`：控制 smartd 守护进程。
    - `enablePythonRocmSupport`：控制 Python 包是否启用 ROCm 支持（通过 overlay 修改 `python3`）。  
    - `environment.extraSystemPackages`：额外安装到系统环境的包列表。
    - `defaultUser`：
      - `name`：默认操作用户（例如 `wsdlly02` / `lily`）。
      - `linger`：是否启用 linger。
      - `extraGroups`：额外用户组。
    - `networking.firewall`：
      - `extraAllowedPorts`：额外允许的端口。
      - `extraAllowedPortRanges`：额外允许的端口范围。
      - `lanOnlyPorts`：仅局域网允许的端口（用于自定义规则）。
      - `lanOnlyPortRanges`：仅局域网允许的端口范围。
    - `nix.settings.max-jobs`：Nix 并行构建的最大任务数。
    - `services.pipewire.socketActivation`：是否启用 PipeWire socket 激活。
  - 在 `config` 中：
    - 将 `enableDevEnv` / `enableInfrastructure` 注入 `_module.args`，便于子模块条件化启用。
    - 当 `enablePythonRocmSupport` 为真时，对 `python3` 和 `python3Packages` 做 overlay，将所有 `rocmSupport = true` 的 Python 包改为带 ROCm 支持的版本。

- `modules/nixosModules/Daily/default.nix`  
  - 类型：日常使用相关的 NixOS 配置。  
  - 常见职责：  
    - 创建默认用户 `users.users."${config.hostSystemSpecific.defaultUser.name}"`。  
    - 使用 `hostSystemSpecific.defaultUser.linger` 和 `extraGroups` 设置用户行为和用户组。  
    - 安装一定的常用系统工具等。  
  - 与主机的关系：通过 `hostSystemSpecific.defaultUser` 从主机层获取具体用户名与组。

- `modules/nixosModules/Development/default.nix`  
  - 类型：开发环境相关配置。  
  - 常见职责：  
    - 根据 `_module.args.enableDevEnv` 决定是否启用开发工具（如 compiler、debugger、language server 等）。  
  - 被所有 `nixosConfigurations.*` 的系统通过 `nixosModules.default` 间接导入。

- `modules/nixosModules/Infrastructure/default.nix`  
  - 类型：基础设施模块的总入口。  
  - `imports` 所有 `Infrastructure/*.nix` 文件：网络、SSH、音频、编辑器等。  
  - 根据 `hostSystemSpecific.enableInfrastructure`、`enableSmartd`、`enableBtrfsScrub` 等开关选择性启用具体服务。

- `modules/nixosModules/Infrastructure/*.nix` 细分模块（每个文件一个功能域）：
  - `avahi.nix`：Avahi / mDNS 相关配置。
  - `bluetooth.nix`：蓝牙服务配置，读取 `config.hostSystemSpecific.enableBluetooth`。
  - `ccache.nix`：启用和配置 ccache。
  - `getty.nix`：TTY 登录服务相关。
  - `gitDaemon.nix`：Git 守护进程服务。
  - `gnupg.nix`：GnuPG / gpg agent 配置。
  - `i18n.nix`：语言与本地化设置。
  - `mihomo.nix`：mihomo 代理/服务配置，使用默认用户 home 目录等路径。
  - `neovim.nix`：Neovim 编辑器配置（plugins、默认设置等）。
  - `networking.nix`：网络相关配置；包括防火墙设置，利用 `hostSystemSpecific.networking.firewall` 扩展/限制端口。  
  - `networkmanager.nix`：NetworkManager 相关配置。
  - `nix.nix`：Nix 包管理器的系统级配置：
    - 使用 `config.hostSystemSpecific.defaultUser.name` 作为可信用户/守护进程用户。  
    - 使用 `config.hostSystemSpecific.nix.settings.max-jobs` 控制构建并行度。
  - `openssh.nix`：OpenSSH 服务配置。
  - `pipewire.nix`：PipeWire 音频服务配置：
    - 使用 `config.hostSystemSpecific.services.pipewire.socketActivation` 调整 Socket 激活。  
  - `samba.nix`：Samba / SMB 文件共享配置。
  - `smartdns.nix`：SmartDNS 服务配置。
  - `static-web-server.nix`：静态 Web 服务器配置。
  - `sudo.nix`：sudo 行为配置。
  - `sysctl.nix`：内核 sysctl 参数设置：
    - 使用 `config.hostSystemSpecific.boot.kernel.sysctl."vm.swappiness"` 写入系统参数。
  - `tmux.nix`：tmux 终端复用器配置。

### 2. Home Base Profile (profiles/home/base/)

目录结构：

```
profiles/home/base/
├── default.nix
├── direnv.nix
└── sh.nix
```

- `profiles/home/base/default.nix`  
  - 类型：Home Manager 基础 profile。  
  - `imports`：
    - `./direnv.nix`
    - `./sh.nix`
  - 在 `config` 中：
    - `programs.command-not-found`：启用并指定数据库路径 `${pkgs.path}/programs.sqlite`。
    - `programs.home-manager.enable = true`：让 Home Manager 管理自身。
    - `programs.lazygit.enable = true`：默认启用 `lazygit`。
    - `programs.nh`：启用 `nh` 并将 `flake` 指向 `~/Documents/nix-config`。
    - `home.packages`：安装常用工具，例如 `currentNixConfig`, `nixd`, `nixfmt`, `nix-diff`, `nix-output-monitor`, `nix-tree`, `yazi`。
    - `home.sessionVariables`：
      - `MY_CODES_PATH`：指向 `~/Documents/my-codes`。
      - `NIX_CONFIG_PATH`：指向 `~/Documents/nix-config`。

- `profiles/home/base/direnv.nix`  
  - Direnv 和相关集成配置（如 `nix-direnv`、shell hook 等）。

- `profiles/home/base/sh.nix`  
  - 终端 Shell 配置（例如 `fish` / `bash` / `zsh` 等的别名、prompt、通用环境变量等）。

> 注：`direnv.nix` 和 `sh.nix` 的具体内容可以根据需要进一步细看，这里主要说明在整体层级中的位置和作用。

## 主机层：hostSpecific/

每台主机一个目录，统一由 `flake.nix` 的 `nixosConfigurations.*` 和 `homeConfigurations.*` 引用。  
典型结构（不同主机略有差异）：

```
hostSpecific/
├── Lily-PC/
│   ├── Hardware/
│   ├── Packages/
│   ├── Programs/
│   ├── configuration.nix
│   └── default.nix
├── WSdlly02-PC/
│   ├── Daily/
│   ├── Gaming/
│   ├── Home/
│   ├── System/
│   └── default.nix
├── WSdlly02-RPi5/
│   ├── Daily/
│   ├── Gaming/
│   ├── Home/
│   ├── System/
│   └── default.nix
└── WSdlly02-WSL/
    ├── Daily/
    ├── Home/
    ├── System/
    └── default.nix
```

### 1. Lily-PC（hostSpecific/Lily-PC）

- `hostSpecific/Lily-PC/default.nix`  
  - 类型：Lily-PC 的 NixOS 主机入口模块。  
  - `imports`：  
    - `./Daily`：Lily-PC 日常使用模块（目录内容在未来可扩展）。  
    - `./Gaming`：游戏相关模块。  
    - `./System`：系统相关模块（例如磁盘、服务、基础设施）。  
  - `hostSystemSpecific`：填充全局选项：
    - `enableBluetooth = false`：禁用蓝牙。
    - `enableDevEnv = false`：不启用开发环境模块。
    - `enableInfrastructure = true`：启用基础设施模块。
    - `enableSmartd = true`：启用磁盘监控。  
    - `environment.extraSystemPackages`：安装 `ntfs3g` 等额外包。
    - `defaultUser`：
      - `name = "lily"`，`linger = true`，`extraGroups = [ ]`。
    - `nix.settings.max-jobs = 32`。
    - `services.pipewire.socketActivation = false`：关闭 PipeWire socket 激活。

- `hostSpecific/Lily-PC/Hardware/hardware-configuration.nix`  
  - 由 `nixos-generate-config` 生成的硬件配置：文件系统、分区、驱动等。

- `hostSpecific/Lily-PC/Hardware/printer.nix`  
  - 打印机相关配置（与 `pkgs/epson-inkjet-printer-201601w.nix` 搭配使用）。

- `hostSpecific/Lily-PC/Packages/*.nix`  
  - `epson-inkjet-printer-201601w.nix`：给 Lily-PC 用的打印机包定义，可能引用 `pkgs/` 中的同名包或做主机特定封装。
  - `forge-survival.nix` / `fabric-survival.nix`：不同 MC 服务器环境的封装。

- `hostSpecific/Lily-PC/configuration.nix`  
  - 传统风格单文件配置（可能是早期配置/兼容用途）。  
  - 与 flake 中的模块化结构并行存在，可用于对比或迁移。

### 2. WSdlly02-PC（当前结构）

- `hosts/WSdlly02-PC/default.nix`
  - 类型：WSdlly02-PC 的 NixOS 主机入口模块。
  - `imports`：
    - `../../profiles/nixos/desktop`：桌面与日常工作负载。
    - `../../profiles/nixos/gaming`：游戏相关配置。
    - `./hardware.nix`：主机硬件、文件系统、boot、firmware。
    - `./system.nix`：主机系统服务与网络策略。
  - `hostSystemSpecific`：
    - 保留主机元数据与少量 feature flag，例如 `defaultUser`、`networking.firewall`、`nix.settings.max-jobs`、`environment.extraSystemPackages`。

- `hosts/WSdlly02-PC/hardware.nix`
  - 聚合 WSdlly02-PC 的纯硬件配置。
  - 包含 `boot`、`fileSystems`、`swapDevices`、`zramSwap`、`hardware` 等。
  - 子模块位于 `hosts/WSdlly02-PC/hardware-modules/`，如：
    - `bootloader.nix`
    - `gpu.nix`
    - `localdisksmount.nix`
    - `nixpkgs-x86_64.nix`
    - `plymouth.nix`
    - `tpm.nix`

- `hosts/WSdlly02-PC/system.nix`
  - 聚合 WSdlly02-PC 的系统服务层配置。
  - 子模块位于 `hosts/WSdlly02-PC/system-modules/`，如：
    - `cups.nix`
    - `networking.nix`
    - `samba.nix`
    - `virtualisation.nix`
    - `remotefsmount.nix`（当前保留为未启用备用模块）

- `profiles/nixos/desktop/*.nix`
  - WSdlly02-PC 的桌面 profile。
  - 已承接原先 Daily 目录中的配置：
    - `fcitx5.nix`
    - `plasma6.nix`
    - `lact.nix`
    - `paperless.nix`（备用）
    - `sunshine.nix`
    - `wine.nix`（备用）

- `profiles/nixos/gaming/*.nix`
  - WSdlly02-PC 的 gaming profile。
  - 当前包含 `default.nix` 和 `gamescope.nix`，承接 Steam、Java、PrismLauncher、Heroic 等配置。

- `hosts/WSdlly02-PC/home.nix`
  - WSdlly02-PC 的 Home Manager 主机入口。
  - 当前仅导入 `../../profiles/home/workstation`。

- `profiles/home/workstation/*.nix`
  - WSdlly02-PC 的 workstation Home profile。
  - 当前包含：
    - `epson-maintenance.nix`
    - `eye-care-reminder.nix`（备用）
    - `localllm.nix`
    - `mihomo-updater.nix`
    - `ollama-omni-ocr.nix`
    - `roc-sink.nix`（备用）
    - `sh.nix`
    - `syncthing.nix`
  - `default.nix` 中集中定义 `home.username`、`home.homeDirectory`、`home.packages`、`programs.zen-browser`、`home.stateVersion`、`services.mpris-proxy` 等 Home 级组合。

### 3. WSdlly02-RPi5（hostSpecific/WSdlly02-RPi5）

- `hostSpecific/WSdlly02-RPi5/default.nix`  
  - 类型：树莓派 5 主机入口模块。  
  - `imports`：
    - `./Daily`
    - `./Gaming`
    - `./System`
  - `hostSystemSpecific`：
    - `enableBluetooth = true`：启用蓝牙。
    - `enableDevEnv = true`：启用开发环境。
    - `enableInfrastructure = true`：启用基础设施模块。
    - `environment.extraSystemPackages`：安装 `libraspberrypi`、`i2c-tools`、`raspberrypi-eeprom` 等树莓派特定工具。
    - `defaultUser`：
      - `name = "wsdlly02"`，`linger = true`。
      - `extraGroups = [ "i2c" "video" ]`。
    - `networking.firewall.extraAllowedPorts = [ 8080 ]`：开放 8080 端口。  
      其他端口/范围保持默认。  
    - `nix.settings.max-jobs = 32`。  
    - `services.pipewire.socketActivation = false`。

- `hostSpecific/WSdlly02-RPi5/System/*.nix`  
  - `default.nix`：树莓派 System 子模块入口。  
  - `nixpkgs-aarch64.nix`：为 aarch64 平台指定/调整 nixpkgs 设置。  
  - `nixos-pi-installer.nix`：树莓派专用的安装/引导工具或初始系统配置。

- `hostSpecific/WSdlly02-RPi5/Daily/default.nix`  
  - 日常使用相关配置入口，针对树莓派环境做精简/特化。

- `hostSpecific/WSdlly02-RPi5/Gaming/*.nix`  
  - `default.nix`：Gaming 子模块入口。  
  - `minecraft-server.nix`：在树莓派上运行 Minecraft Server 的配置（通常与 `pkgs/fabric-survival.nix` 配合）。

- `hostSpecific/WSdlly02-RPi5/Home/*.nix`  
  - `default.nix`：
    - `imports`：  
      - `./network-autoswitch.nix`  
      - `./sh.nix`  
      - `./syncthing.nix`  
      - `./tailscale.nix`  
      - （可选）`./roc-source.nix`（目前注释）。  
    - `home.username = "wsdlly02"`，`home.homeDirectory = "/home/wsdlly02"`。  
    - `home.packages = [ ]`（树莓派 Home 尽量精简）。  
    - `programs.java`：启用 Java，指定 `pkgs.zulu21` 作为包。  
    - `services.mpris-proxy.enable = true`。  
    - `home.stateVersion = "25.05"`。  
    - `targets.genericLinux.enable = true`：启用 generic Linux 目标（适配非标准 NixOS 环境）。
  - `network-autoswitch.nix`：网络自动切换逻辑。  
  - `sh.nix`：树莓派环境 Shell 配置。  
  - `syncthing.nix`：树莓派的 Syncthing 配置。  
  - `tailscale.nix`：Home 级 Tailscale 配置。  
  - `roc-source.nix`：音频源相关配置（目前在 `imports` 中注释）。

### 4. WSdlly02-WSL（hostSpecific/WSdlly02-WSL）

- `hostSpecific/WSdlly02-WSL/default.nix`  
  - 类型：WSL 主机入口模块。  
  - `imports`：
    - `./Daily`
    - `./System`
  - `hostSystemSpecific`：
    - `enableDevEnv = true`：在 WSL 中启用开发环境。
    - `enableInfrastructure = false`：不启用完整基础设施（WSL 环境下简化服务）。  
    - `environment.extraSystemPackages = [ wsl-open ]`：安装 `wsl-open` 以在 Windows 中打开链接/文件。  
    - `defaultUser`：
      - `name = "wsdlly02"`，`linger = false`，`extraGroups = [ ]`。  
    - `nix.settings.max-jobs = 64`。

- `hostSpecific/WSdlly02-WSL/System/*.nix`  
  - `default.nix`：System 子模块入口。  
  - `networking.nix`：WSL 环境下的网络配置。  
  - `nixpkgs-x86_64.nix`：为 WSL 指定 x86_64 nixpkgs 设置。

- `hostSpecific/WSdlly02-WSL/Daily/default.nix`  
  - WSL 环境的日常配置入口（通常包含较少的图形/服务配置）。

- `hostSpecific/WSdlly02-WSL/Home/*.nix`  
  - `default.nix`：
    - `imports`：  
      - `./sh.nix`。  
    - `home.username = "wsdlly02"`，`home.homeDirectory = "/home/wsdlly02"`。  
    - `home.packages` 包含 `codex`、`gemini-cli`、`ncmdump` 等 CLI 工具。  
    - `home.stateVersion = "25.05"`。
  - `sh.nix`：WSL 环境下的 Shell 定制。

## 包与开发环境层：pkgs/

目录结构：

```
pkgs/
├── currentNixConfig.nix
├── devShells-aitools.nix
├── devShells-nixfmt.nix
├── epson-inkjet-printer-201601w.nix
├── fabric-survival.nix
└── rocmFHSEnv.nix
```

- `pkgs/currentNixConfig.nix`  
  - 将当前 flake 源打包成 `currentNixConfig` 包：  
    - `src = inputs.self`，版本为 `inputs.self.lastModifiedDate`。  
    - 安装到 `$out/share/currentNixConfig`，用于在系统里访问当前配置源码。

- `pkgs/devShells-aitools.nix`  
  - 定义 `devShells.${system}.aitools`：  
    - 使用 `mkShell`，构建一个包含 `python3Env` 的环境，并在其中添加 `markitdown`、`openai-whisper` 等 AI 工具。  
    - `shellHook`：进入 Shell 时自动运行 `fish`。

- `pkgs/devShells-nixfmt.nix`  
  - 定义 `devShells.${system}.nixfmt`：  
    - 安装 `nixfmt` 作为唯一依赖。  
    - `shellHook`：进入 Shell 时自动运行 `fish`。

- `pkgs/epson-inkjet-printer-201601w.nix`  
  - Epson L380 打印机驱动的打包脚本：  
    - 从官方 RPM 源下载并展开。  
    - 使用 `rpmextract`、`autoreconfHook` 等构建工具。  
    - 调整 PPD 文件中的路径，将 `/opt/epson-inkjet-printer-201601w`/`/cups/lib` 替换为 Nix store 中的路径。  
    - 安装到 `$out/share/cups/model/epson-inkjet-printer-201601w` 等目录。  
    - 设置 meta：homepage、描述、支持平台等。

- `pkgs/fabric-survival.nix`  
  - 打包 Minecraft Fabric Server：  
    - 使用指定的 `minecraftVersion` 和 `fabricVersion` 下载 server jar。  
    - 安装到 `$out/lib/minecraft/fabric-survival.jar`。  
    - 生成一个可执行脚本 `$out/bin/fabric-server`，使用 `zulu21` 运行该 jar。  
    - 设置 meta：描述、主页、license 等。

- `pkgs/rocmFHSEnv.nix`  
  - 构建一个基于 `buildFHSEnv` 的 FHS 环境以便在 ROCm 上运行软件：  
    - 使用 `symlinkJoin` 将各类 `rocmPackages.*` 合并到一个路径 `rocmtoolkit_joined` 中，删除 `nix-support`。  
    - 使用 `writeShellScriptBin` 定义入口脚本 `entrypoint`：  
      - 设置 `ROCM_PATH`、`LD_LIBRARY_PATH`。  
      - source `~/Documents/rocmFHSEnv/bin/activate`。  
      - 启动 `fish`。  
    - `targetPkgs`：在 FHS 环境中提供 `dbus`、`fish`、`libdrm`、`libglvnd`、`stdenv.cc` 等常见依赖。  
    - 通过 `vendorComposableKernel` 根据 `rocmPackages.composable_kernel.anyMfmaTarget` 决定是否包含 `composable_kernel`。

> 这些包与 flake 顶层的 `overlays`、`legacyPackages.${system}.exposedPackages` 配合使用，在系统和 Home 中作为可复用的专用软件/环境。

## 配置流程（从 flake.nix 到主机）

### 系统配置流程
1. Flake 定义系统配置 (`nixosConfigurations`)
2. 引入默认 NixOS 模块 (`nixosModules.default`)
3. 加载主机特定配置 (`hostSpecific/{HOSTNAME}`)
4. 应用硬件特定模块（如 Raspberry Pi 5）

### 用户配置流程
1. Flake 定义用户配置 (`homeConfigurations`)
2. 引入共享 Home base profile (`profiles/home/base`)
3. 加载主机特定用户配置 (`hostSpecific/{HOSTNAME}/Home`)
4. 应用浏览器等额外模块

## 特色功能与设计要点

- 多平台支持  
  - x86_64 Linux（桌面 PC、WSL）。  
  - aarch64 Linux（Raspberry Pi 5）。  
  - 针对 WSL 做了简化基础设施配置。

- 条件化模块启用  
  - `enableDevEnv`：控制开发环境相关模块是否启用。  
  - `enableInfrastructure`：控制 Infrastructure 模块整体启用。  
  - `enableBluetooth` / `enableSmartd` / `enableBtrfsScrub` / `enablePythonRocmSupport` 等进一步细化功能。

- 主机驱动的选项系统  
  - NixOS 通用模块仍通过 `config.hostSystemSpecific` 获取部分主机特定参数；Home Manager 侧已经改为由各 profile 或主机入口直接声明 `home.*` 选项。

- 自定义包与 overlays  
  - 利用 `overlays` 和 `legacyPackages` 机制将自定义包（打印机驱动、ROCm FHS、Minecraft 服务器等）自然注入到系统。  
  - 同时保持 `my-codes` flake 暴露的包可用。

- 开发环境支持  
  - `devShells.${system}.aitools` 提供 AI 工具环境。  
  - `devShells.${system}.nixfmt` 提供轻量级 Nix 格式化环境。  
  - `pkgs.currentNixConfig` 方便在任意环境中查看当前配置源码。

## 使用方法

### 构建系统配置
```bash
nixos-rebuild build --flake .#{HOSTNAME}
```

### 切换到新配置
```bash
sudo nixos-rebuild switch --flake .#{HOSTNAME}
```

### 更新配置
```bash
nix flake update
```

## 维护建议

1. 定期更新 flake.lock 以获取最新依赖
2. 根据设备用途调整模块启用状态
3. 将通用配置提取到模块中，避免重复
4. 使用条件化配置优化不同设备的性能
