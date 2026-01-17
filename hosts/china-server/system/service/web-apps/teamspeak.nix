{ config, lib, pkgs, install-config, unstable, ... }: {
  myWebsites = {
    TeamSpeak = {
      domain = "TeamSpeak";
      enable = true;
      enableNginx = false;  # 设置为false表示只创建容器，不配置nginx
      enableSSL = false;
      ociContainer = {
        enable = true;
        image = "teamspeak";
        imageTag = "latest";
        ports = [ 
          "9987:9987/udp"
          "10011:10011"
          "10022:10022"
          "10080:10080"
          "10443:10443"
          "30033:30033"
          "41144:41144"
         ]; 
         environment = {
          TS3SERVER_LICENSE="accept";
         };
      joinCustomNetwork = true;

        volumes = [];
      };
    };
  };
}