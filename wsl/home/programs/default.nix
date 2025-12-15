{ config, lib, pkgs, install-config, unstable, ... }: {
  imports = [
    ./common.nix
    ./video.nix
    ./create.nix
  ];
}
