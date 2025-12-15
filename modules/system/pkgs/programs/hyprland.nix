{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    programs = {
    hyprland = install-config.hyprland;
        
    };
}