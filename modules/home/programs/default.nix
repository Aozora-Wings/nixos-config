{ config, lib, pkgs, install-config, unstable, ... }: {
  imports = [
    ./browsers.nix
    ./common.nix
    ./git.nix
    ./media.nix
    ./xdg.nix
    ./game
    ./my_use_update
    #./template_new_app 
    ./fonts
    ./desktop.nix
    ./hyper.nix
    ./niri.nix
  ];
}
