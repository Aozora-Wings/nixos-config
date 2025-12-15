{ config, lib, pkgs, install-config, unstable, ... }: {
  imports = [
    ./profile.nix
    ./service.nix
    ./programs.nix
    ./software
    ../../../modules/home/fcitx5 #输入法
  ];
}
