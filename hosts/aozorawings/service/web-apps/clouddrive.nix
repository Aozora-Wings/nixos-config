{ config, lib, pkgs, install-config, unstable, ... }: {
  myWebsites = {
    "clouddrive" = {
      enable = true;
      domain = "cd2.app.qkzy.net";
      enableNginx = true;
      enableSSL = true;
      proxyPass = "http://[::1]:19798";
    };
  };
}
