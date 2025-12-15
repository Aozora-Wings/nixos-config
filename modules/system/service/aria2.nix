{ pkgs, lib,rpcSecretFile, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
    aria2 = {
      enable = true;
      rpcSecretFile = "${rpcSecretFile}";
      settings = {
        enable-rpc = true;
      };
    };
    
    };
}