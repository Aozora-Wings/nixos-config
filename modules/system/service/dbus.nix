{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
        
    dbus.packages = [ pkgs.gcr ];
        };
}