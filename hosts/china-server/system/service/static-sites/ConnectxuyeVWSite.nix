{ config, lib, pkgs, install-config, unstable, ... }: {
  myWebsites = {
    ConnectxuyeVWSite = {
      enable = true;  # 这个必须有！
      domain = "qcxyun.qkzy.net";
      enableSSL = true;
      proxyPass = "https://127.0.0.1:9110";
    };
  };
}