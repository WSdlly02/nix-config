{ pkgs, ... }:
{
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
