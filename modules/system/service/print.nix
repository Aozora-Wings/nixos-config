{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
    printing = {
      enable = true;
      drivers = [
        pkgs.epson-escpr
        pkgs.epson-escpr2
      ];
    };
    
    };
}