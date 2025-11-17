{ inputs }:

{
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
      ]
      ++ overlays;
    };
}
