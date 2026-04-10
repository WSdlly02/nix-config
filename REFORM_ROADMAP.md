# Nix-Config 2.0 重构记录

本轮重构已经完成。

最终结果：

- 入口统一收敛到 `hosts/`
- 共享系统配置统一收敛到 `profiles/nixos/`
- 共享 Home 配置统一收敛到 `profiles/home/`
- `hostSystemSpecific` 与 `hostUserSpecific` 已删除
- `flake.nix` 不再注入旧式默认聚合模块
- 迁移期使用的结果基准与校验脚本已退场

当前后续工作不再是“继续迁移”，而是普通的日常维护：

- 新增机器时，在 `hosts/<name>/` 下建立入口
- 共享能力优先放入 `profiles/`
- 仅把确实无法抽象复用的内容保留在主机目录

如果未来继续演进，建议遵守当前已经形成的规则：

1. 功能通过显式 `imports` 表达。
2. 原生 NixOS / Home Manager option 直接落回原生接口。
3. 只有确实需要跨模块共享的主机事实，才保留为窄的 `config.my.*` 选项。
