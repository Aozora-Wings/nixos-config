{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
    displayManager = {
        sddm = {
      enable = true;
      wayland.enable = true;
      settings.General = {
        Numlock = "on";
      };
        };
    };
    };
}