{ config, lib, pkgs, install-config, unstable, ... }: {
  myWebsites = {
    vlmcsd = {
      domain = "vlmcsd";
      enable = true;
      enableNginx = false;  # 设置为false表示只创建容器，不配置nginx
      enableSSL = false;
      ociContainer = {
        enable = true;
        image = "mikolatero/vlmcsd";
        imageTag = "latest";
        ports = [ 
          "1688:1688"
         ]; 
      joinCustomNetwork = true;
        volumes = [];
      };
    };
  };
}