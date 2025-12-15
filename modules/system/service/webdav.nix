{ pkgs, lib, install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
    webdav = {
      enable = true;
      settings = {
        address = "0.0.0.0";
        port = install-config.def_ports.webdav;
        scope = "/server/";
        modify = true;
        auth = true;
        users = [
          {
            username = "webdav";
            password = "FA9MiPajf*zWZuZA*fQq";
          }
        ];
      };
    };
    
    };
}