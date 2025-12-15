{ pkgs, lib,  username,install-config, unstable, stable,flakeSoftware,hyprlandConfigPath, ... }:
{
    services = {
    
    code-server = {
      enable = true;
      auth = "password";
      hashedPassword = install-config.code-server.password;
      port = install-config.def_ports.code_server;
      host = "[::]";
      user = install-config.username;
    };
    };
}