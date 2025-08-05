/*
  pkgs.rust.packages.stable.rustc = pkgs.rustc
  pkgs.rustPlatform.buildRustPackage = pkgs.rust.packages.stable.rustPlatform.buildRustPackage
*/
{
  lib,
  pkgs,
  enableDevelopment,
  ...
}:
{
  config = lib.mkIf enableDevelopment {
    environment = {
      systemPackages = with pkgs; [
        cloc # counts blank lines, comment lines, and physical lines of source code
        # Rust toolchains
        cargo
        clippy
        rustc
        rustfmt
        haskellEnv # Haskell
        stdenv.cc # gcc
        python3Env # Python 3.12 !!!
        # python3FHSEnv
        # Other pkgs
      ];
      sessionVariables = {
        RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
      };
    };
  };
}
