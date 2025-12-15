{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
    pcscd.enable = true;
    
    };
}