{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
    desktopManager = {
        plasma6.enable = true;
    };
    };
}