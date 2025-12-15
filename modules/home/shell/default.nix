{ config, pkgs,install-config, ... }:
let
  d = config.xdg.dataHome;
  c = config.xdg.configHome;
  cache = config.xdg.cacheHome;
in
{
  imports = [
    ./nushell
    ./common.nix
    ./starship.nix
    ./terminals.nix
  ];

  # add environment variables
  home.sessionVariables = {
    # clean up ~
    LESSHISTFILE = cache + "/less/history";
    LESSKEY = c + "/less/lesskey";
    WINEPREFIX = d + "/wine";

    # set default applications
    EDITOR = "vim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";

    # enable scrolling in git diff
    DELTA_PAGER = "less -R";
    SHELL = "${pkgs.nushell}/bin/nu";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    NH_FLAKE = install-config.root;
    NH_DIR = install-config.root;
  };

  home.shellAliases = {
    k = "kubectl";
    nixup = "https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897 nix flake update";
  };
  
  programs.nushell.extraConfig = ''
    $env.NH_FLAKE = "${install-config.root}"
    $env.NH_DIR = "${install-config.root}"
  '';
  
  programs.bash.initExtra = ''
    export NH_FLAKE="${install-config.root}"
    export NH_DIR="${install-config.root}"
  '';
}
