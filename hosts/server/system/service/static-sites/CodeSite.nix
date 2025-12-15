{ config, lib, pkgs, install-config, unstable, ... }: {
  myWebsites = {
     CodeSite = {
       enable = true;  # 这个必须有！
       domain = "dejected4764.code.qkzy.net";
       enableSSL = true;
       proxyPass = "http://[::1]:9003";
     };
  };
}