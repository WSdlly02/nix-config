{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    configure = {
      customRC = ''
        set nu
        set showmatch
        set encoding=utf-8
        set fenc=utf-8
        set mouse=a
        set tabstop=2
        filetype plugin indent on
        syntax on
      '';
      packages.vimPlugins = with pkgs.vimPlugins; {
        # loaded on launch
        start = [
          LazyVim
          lazy-nvim
          lazygit-nvim
          yazi-nvim
        ];
        # manually loadable by calling `:packadd $plugin-name`
        opt = [ ];
      };
    };
  };
}
