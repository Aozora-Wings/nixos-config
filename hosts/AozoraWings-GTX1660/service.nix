
{ config, pkgs, install-config, unstable, stable, inputs, ... }:
let

  unstable = import <unstable> { config = { allowUnfree = true; }; };
  username = install-config.username;
  hyprlandConfigPath = "${toString ../config/hyprland.conf}";

in
{
  imports = [
  ];
 }
