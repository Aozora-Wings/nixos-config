{ config, lib, pkgs, install-config, unstable, mapPort, npsPorts, ... }:
let
  #ports = import ../lib/ports.nix { inherit lib install-config; };
in
{
  myWebsites = {
    nps = {
      domain = "nps.app.qkzy.net";
      enable = true;
      #enableNginx = false;  # 设置为false表示只创建容器，不配置nginx
      enableSSL = true;
      ociContainer = {
        enable = true;
        image = "yisier1/nps";
        imageTag = "latest";
        ports =
          [
            (mapPort "nps" 8080)
            (mapPort "nps_connect" 8024)
          ]
          ++ map (port: "${toString port}:${toString port}") npsPorts;
        # ++ map (port: "${toString port}:${toString port}") (lib.range 9210 9299);

        joinCustomNetwork = true;
        volumes = [ "/var/www/nps:/conf" ];
      };
    };
  };
}
