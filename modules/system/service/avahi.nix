{ pkgs, lib,rpcSecretFile, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
      };
    };
    
    };
}