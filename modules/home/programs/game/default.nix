{ config, lib, pkgs, install-config, unstable, ... }: {
  home.packages = with pkgs; [
    #(import ./osu.nix { inherit (pkgs) lib stdenv fetchurl fetchzip appimageTools; })
    unstable.hmcl
    unstable.osu-lazer-bin
  ];
}
