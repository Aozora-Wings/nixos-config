{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
    
    sunshine = {
      enable = true;
      capSysAdmin = true;
    };
    };
}