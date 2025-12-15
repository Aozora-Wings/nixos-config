{ config, lib, pkgs, install-config, stable, ... }:
let
  cfg = install-config.niri;
  username = install-config.username;
in
{


  # services.displayManager.dms-greeter.compositor = lib.mkIf cfg.enable {
  #   name = "niri";
  # };
}