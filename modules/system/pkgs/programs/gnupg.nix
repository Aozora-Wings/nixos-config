{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    programs = {
        
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      enableBrowserSocket = true;
      enableExtraSocket = true;
      pinentryPackage = pkgs.pinentry-gtk2;
      settings = {
        log-file = "/home/public/gpg/gpg-agent.log";
      };
    };
    };
}