Nix-Config 2.0 重构路线图：面向功能的架构演进

1. 核心理念 (Core Philosophy)

我们正在从 “以主机为中心 (Host-Centric)” 转向 “以功能为中心 (Feature-Oriented)”。

    旧思维：“这台电脑叫 PC，它需要这些这配置文件。” -> 导致重复、混乱、难以复用。

    新思维：“我有‘游戏’、‘服务器’、‘办公’这些能力。PC 是‘游戏+办公’的组合，树莓派是‘服务器’的实例。” -> 模块化、清晰、即插即用。

三大原则：

    功能即模块 (Features as Profiles)：将一组相关的配置（如“Steam + Gamescope + 手柄驱动”）封装为一个独立的 profile。

    主机即菜单 (Hosts as Menus)：主机配置文件不再包含大量逻辑，它只是一份“点菜单”，负责导入硬件配置和所需的 profile。

    单一事实来源 (Single Source of Truth)：flake.nix 依然是入口，但它指向结构化良好的 hosts/ 目录，而非深埋的子文件夹。

2. 目标架构 (Target Architecture)

重构后的目录结构将清晰地反映我们的思维模型：
Plaintext

nix-config/
├── flake.nix             # 唯一的入口点
├── flake.lock
├── lib/                  # [新增] 辅助函数 (Helpers)
│   └── default.nix       # 例如 mkPkgs, mkSystem 等函数
├── pkgs/                 # [保留] 自定义包 (Overlay)
├── hosts/                # [重构] 具体的物理/虚拟机器定义
│   ├── wsdlly02-pc/      # 台式机
│   │   ├── default.nix   # 系统入口 (Imports profiles)
│   │   └── hardware.nix  # 纯硬件配置 (File systems, kernel modules)
│   ├── WSdlly02-RPi5/        # 树莓派 (NixOS)
│   │   ├── default.nix
│   │   └── hardware.nix
│   └── wsl/              # 笔记本 WSL
│       └── default.nix
└── profiles/             # [核心] 可复用的功能模块
    ├── nixos/            # 系统级功能 (System Level)
    │   ├── base/         # 基础底座 (所有机器都有)
    │   │   ├── core.nix  # Nix settings, bootloader defaults
    │   │   ├── user.nix  # 默认用户, SSH keys
    │   │   └── net.nix   # 基础网络工具 (NetworkManager/Tailscale)
    │   ├── desktop/      # 桌面环境
    │   │   ├── plasma6.nix
    │   │   └── fonts.nix
    │   ├── gaming/       # 游戏栈
    │   │   └── steam.nix # Steam, Gamemode, Gamescope
    │   ├── virt/         # 虚拟化与容器
    │   │   ├── podman.nix # Podman, Distrobox
    │   │   └── libvirt.nix
    │   └── services/     # 服务
    │       ├── syncthing.nix
    │       └── ssh-server.nix
    └── home/             # 用户级功能 (Home-Manager)
        ├── shell/        # 终端体验 (Fish, Starship, Tmux)
        ├── dev/          # 开发环境 (Git, Direnv)
        └── apps/         # GUI 应用 (Browser, Obsidian)

3. 实施步骤 (Execution Steps)

这是一场“开着飞机换引擎”的操作。我们将分阶段进行，确保每一步都是可验证的。

第一阶段：地基建设 (Foundation)

目标：建立新目录结构，迁移辅助代码，不破坏现有系统。

    创建目录骨架：
    mkdir -p hosts profiles/{nixos,home} lib

    提取库函数 (lib/)：

        将 flake.nix 中定义的 pkgs' (或 mkPkgs) 函数移动到 lib/default.nix。

        在 flake.nix 中导入它：let myLib = import ./lib { inherit inputs; }; in ...。

    提取基础系统层 (profiles/nixos/base)：

        分析 modules/nixosModules/Infrastructure/。

        将 nix.nix (Nix 设置), sudo.nix, openssh.nix, i18n.nix 等所有机器都通用的配置，合并/整理到 profiles/nixos/base/default.nix 或分拆为几个文件。

        关键点：移除所有 config.hostSystemSpecific 的条件判断。base profile 的含义就是“启用这些功能”。

第二阶段：功能模块化 (Feature Extraction)

目标：将复杂的 modules 和 hostSpecific 拆解为独立的“乐高积木”。

    桌面环境 (profiles/nixos/desktop)：

        从 hostSpecific/WSdlly02-PC/Daily/plasma6.nix 提取 Plasma 6 配置。

        从 hostSpecific/WSdlly02-PC/Daily/fcitx5.nix 提取输入法配置。

        组合成 profiles/nixos/desktop/plasma.nix。

    游戏能力 (profiles/nixos/gaming)：

        整合 hostSpecific/WSdlly02-PC/Gaming/ 下的内容 (Steam, Gamescope, OpenRazer) 到 profiles/nixos/gaming/default.nix。

    虚拟化与容器 (profiles/nixos/virt)：

        这是新架构的核心。 创建 profiles/nixos/virt/podman.nix。

        在此处启用 virtualisation.podman, virtualisation.oci-containers 和 programs.distrobox。

        这就是我们在树莓派和 PC 上运行多实例服务的基础。

    用户环境 (profiles/home)：

        将 modules/homeModules 下的 Shell 配置 (Fish, TMUX, Git) 迁移到 profiles/home/shell/。

第三阶段：重构主机定义 (Host Definition)

目标：用新的“点菜”方式重新定义你的设备。

    PC 重构 (hosts/wsdlly02-pc)：

        创建 hosts/wsdlly02-pc/hardware.nix：放入 fileSystems, boot.loader, hardware.opengl 等纯硬件内容。

        创建 hosts/wsdlly02-pc/default.nix：
        Nix

    { pkgs, ... }: {
      imports = [
        ./hardware.nix
        ../../profiles/nixos/base       # 基础系统
        ../../profiles/nixos/desktop    # 桌面
        ../../profiles/nixos/gaming     # 游戏
        ../../profiles/nixos/virt       # 容器/虚拟机
        ../../profiles/nixos/services/syncthing.nix
      ];

      networking.hostName = "WSdlly02-PC";
      # 极少量的本机特有微调
    }

树莓派重构 (hosts/WSdlly02-RPi5)：

    战略调整：坚定使用 NixOS。

    创建 hosts/WSdlly02-RPi5/default.nix：
    Nix

        { inputs, ... }: {
          imports = [
            inputs.nixos-hardware.nixosModules.raspberry-pi-5
            ../../profiles/nixos/base
            ../../profiles/nixos/virt      # 启用 Podman/Distrobox
            ../../profiles/nixos/services/syncthing.nix # 作为 Hub
          ];

          networking.hostName = "WSdlly02-RPi5";
        }

第四阶段：清理与切换 (Cleanup & Switch)

    更新 flake.nix：

        修改 nixosConfigurations，让它们指向新的 hosts/*/default.nix。

    测试构建：

        使用 nixos-rebuild build --flake .#WSdlly02-PC 进行测试。

        利用 Git，如果不通过，随时回退。

    删除旧代码：

        一旦所有主机都迁移成功，删除旧的 modules/ 和 hostSpecific/ 目录。

4. 我们的“技术栈”总结

通过这次重构，你的技术栈将变得异常清晰：

    Nix Flakes: 整个生态的唯一真理 (Source of Truth)。

    NixOS Profiles: 可复用的能力积木 (Gaming, Virt, Desktop)。

    Podman (OCI Containers): 通过 NixOS 声明式管理的服务单元 (Minecraft, Web Servers)，解决多实例问题，拒绝黑洞。

    Distrobox: 声明式管理的异构应用沙盒 (Run Ubuntu/Arch apps)，解决专有软件兼容性，保持宿主纯净。

    Home-Manager: 跨平台 (NixOS/WSL) 的用户环境统一层。

    Syncthing: 以树莓派为 Hub 的数据同步层。

这就是你的宏伟蓝图的第一步。Let's build the profiles.