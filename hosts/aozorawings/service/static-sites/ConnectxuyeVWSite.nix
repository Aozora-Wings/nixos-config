{ config, lib, pkgs, install-config, unstable, ... }: {
  myWebsites = {
    ConnectxuyeVWSite = {
      enable = true; # 这个必须有！
      domain = "qcxyun.app.qkzy.net";
      enableSSL = true;
      proxyPass = "http://127.0.0.1:9110";
    };
  };
}
