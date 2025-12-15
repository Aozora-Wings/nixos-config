#service/default.nix
{ config, lib, pkgs, install-config, unstable, ... }: {
  imports = [
    ./datebase.nix
    ./nps.nix
  ];
}
