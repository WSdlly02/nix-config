{ lib, inputs }:

rec {
  # pkgs' is a helper to construct a nixpkgs instance with
  # the project's common config and overlays applied.
  pkgs' =
    {
      nixpkgsInstance ? inputs.nixpkgs-unstable,
      config ? { },
      overlays ? [ ],
      system,
    }:
    import nixpkgsInstance {
      inherit system;
      config = {
        allowAliases = false;
        allowUnfree = true;
        # rocmSupport = true;
      }
      // config;
      overlays = [
        inputs.my-codes.overlays.exposedPackages
        inputs.self.overlays.default
        inputs.self.overlays.exposedPackages
        inputs.self.overlays.libraryPackages

        # overlays defined in here
        buildEnvWithSortedPathsOverlay
        utilsSelfOverlay
      ]
      ++ overlays;
    };
  buildEnvWithSortedPathsOverlay = final: prev: {
    /*
      NixOS 通过 lib.mkMerge 将所有模块的 environment.systemPackages 合并为一个有序列表。
      这个列表的顺序取决于模块的 import 顺序。你修改 flake.nix 入口定义时，即使功能等价，也可能改变了模块被求值和合并的顺序，从而导致包列表排列不同 。
      buildEnv（NixOS system-path 的构建器）把这个列表直接作为 derivation 输入，因此：
      包列表顺序变了 → buildEnv 的 inputDrvs 顺序变了 → drv 哈希变了
      ↓
      但实际链接进 /run/current-system 的文件完全一样
      这就是为什么哈希变了但内容没变的情况。
    */
    buildEnv =
      args:
      let
        name = args.name or "";
        # 匹配需要排序的三类 derivation
        # 确保它们在最终的列表中按照字母序排列，避免不必要的哈希变动
        isSortTarget = lib.any (s: lib.hasSuffix s name) [
          "completions"
          "path"
          "paths"
        ];
      in
      prev.buildEnv (
        args
        // lib.optionalAttrs isSortTarget {
          paths = lib.sort (a: b: lib.getName a < lib.getName b) (args.paths or [ ]);
        }
      );
  };
  utilsSelfOverlay =
    final: prev: with prev; {
      utils-self = {
        systemd-user-serializedStarter =
          name:
          writeShellScript "${name}-systemd-serialized-starter" ''
            set -euo pipefail
            if [ -z "''${SERVICES_START_ORDER:-}" ]; then
              echo "Error: SERVICES_START_ORDER environment variable not set."
              exit 1
            fi
            echo "Starting services in order..."

            for srv in $SERVICES_START_ORDER; do
              echo "Starting $srv..."
              systemctl --user start "$srv"
            done
            echo "All services started."
          '';
        systemd-user-serializedStopper =
          name:
          writeShellScript "${name}-systemd-serialized-stopper" ''
            set -euo pipefail
            if [ -z "''${SERVICES_STOP_ORDER:-}" ]; then
              echo "Error: SERVICES_STOP_ORDER environment variable not set."
              exit 1
            fi
            echo "Stopping services in order..."

            for srv in $SERVICES_STOP_ORDER; do
              echo "Stopping $srv..."
              systemctl --user stop "$srv"
            done
            echo "All services stopped."
          '';
      };
    };
}
