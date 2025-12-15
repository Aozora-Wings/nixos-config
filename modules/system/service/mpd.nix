{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
        
    mpd =
      if install-config.mpd.enable then
        install-config.mpd
      else {
        enable = false;
      };
        };
}