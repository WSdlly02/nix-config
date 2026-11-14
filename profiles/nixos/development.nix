{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      gh # GitHub CLI
      cloc # counts blank lines, comment lines, and physical lines of source code

      # C/C++
      gcc
      clang-tools
      cmake

      # Rust toolchain manager
      # rustup # installed maually

      # Haskell
      # haskellEnv

      # Python
      uv
      python3Env

      # Golang
      go

      # Node.js
      nodejs
      npm-check-updates
    ];
    etc."uv/uv.toml".text = ''
      # Only use managed Python versions
      python-preference = "only-managed"
    '';
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      gcc.cc.lib

      zlib
      zstd
      bzip2
      xz

      openssl
      libffi
      sqlite
      readline
      ncurses

      libxml2
      libxslt
      curl
      icu
    ];
  };
}
