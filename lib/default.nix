{ inputs }:

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
        utils-self
      ]
      ++ overlays;
    };
  utils-self =
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
