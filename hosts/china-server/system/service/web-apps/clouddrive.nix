{ config, lib, pkgs, install-config, unstable, ... }: {
  myWebsites = {
   "clouddrive" = {
      enable = true;
      domain = "cd2.qkzy.net";
      enableNginx = true;
      enableSSL = true;
      proxyPass = "http://127.0.0.1:19798";
    };
  };
}