# NixOS & Home Manager 配置架构说明

## 概述

这是一个用于管理多个设备的 NixOS 和 Home Manager 配置的 Flake 项目。项目采用模块化设计，支持多种设备类型，包括常规 PC、树莓派、WSL 等。

## 项目结构

```
├── flake.nix                 # Flake 入口文件，定义所有输入和输出
├── flake.lock                # 锁定的依赖版本
├── modules/                  # 自定义模块
│   ├── homeModules/          # Home Manager 模块
│   └── nixosModules/         # NixOS 模块
├── hostSpecific/             # 各主机特定配置
│   ├── WSdlly02-PC/          # PC 主机配置
│   ├── WSdlly02-RaspberryPi5/# 树莓派配置
│   ├── WSdlly02-WSL/         # WSL 配置
│   └── Lily-PC/              # 另一台 PC 配置
├── pkgs/                     # 自定义包定义
└── README.md
```

## 核心组件

### 1. Flake 配置 (flake.nix)

#### 输入 (Inputs)
- `nixpkgs-unstable`: NixOS 不稳定频道，作为主要包源
- `home-manager`: 用户环境管理工具
- `nixos-hardware`: 硬件特定配置模块
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

### 2. 模块化设计

#### NixOS 模块 (modules/nixosModules/)
采用分层模块化设计：
- `Infrastructure/`: 基础设施相关模块（网络、安全、服务等）
- `Development/`: 开发环境相关模块
- `Daily/`: 日常使用相关模块

每个模块通过 `default.nix` 导入其子模块，实现功能分类管理。

#### Home Manager 模块 (modules/homeModules/)
- `direnv.nix`: Direnv 配置
- `sh.nix`: Shell 相关配置
- `default.nix`: 默认配置和基础选项

### 3. 主机特定配置 (hostSpecific/)

每台主机都有独立的配置目录，包含：
- `default.nix`: 主机基本配置
- `System/`: 系统级配置
- `Home/`: 用户级配置
- 功能分类目录（如 Daily, Gaming 等）

### 4. 自定义包 (pkgs/)

包含一些在标准仓库中不可用或需要特殊配置的软件包：
- `currentNixConfig.nix`: 当前配置的打包
- `rocmFHSEnv.nix`: ROCm FHS 环境
- `fabric-survival.nix`: Minecraft Fabric 生存模组包
- 等等...

## 配置流程

### 系统配置流程
1. Flake 定义系统配置 (`nixosConfigurations`)
2. 引入默认 NixOS 模块 (`nixosModules.default`)
3. 加载主机特定配置 (`hostSpecific/{HOSTNAME}`)
4. 应用硬件特定模块（如 Raspberry Pi 5）

### 用户配置流程
1. Flake 定义用户配置 (`homeConfigurations`)
2. 引入默认 Home Manager 模块 (`homeModules.default`)
3. 加载主机特定用户配置 (`hostSpecific/{HOSTNAME}/Home`)
4. 应用浏览器等额外模块

## 特色功能

### 1. 多平台支持
- x86_64 Linux (PC)
- aarch64 Linux (树莓派)
- WSL 环境

### 2. 条件化配置
通过 `enableDevEnv` 和 `enableInfrastructure` 等选项控制功能模块的启用。

### 3. 自定义包管理
通过 overlays 机制集成自定义包和第三方包。

### 4. 开发环境
提供专门的开发工具链和 AI 工具环境。

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