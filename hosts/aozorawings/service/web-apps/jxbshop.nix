{ config, lib, pkgs, install-config, unstable, ... }:
let
  port = import ../lib/ports.nix { inherit lib install-config; };
in
{
  myWebsites = {
    jxbShoopFrontend = {
      domain = "cj.app.app.qkzy.net";
      enableSSL = true;
      Index = "index.html";
    };
    jxbShoopFrontendzk = {
      domain = "zk.app.app.qkzy.net";
      enableSSL = true;
      Index = "index.html";
    };
    # 
    jxbShoopBackend = {
      domain = "api.cj.app.app.qkzy.net";
      enableSSL = true;
      ociContainer = {
        enable = true;
        image = "node";
        imageTag = "latest";
        ports = [ (port.mapPort "jxbShoopBackend" 3000) ];
        environment = {
          DATABASE_URL = "mysql://JxbStore:e73XhQwCNfjSYYt2@db-qkzy-net:3306/JxbStore";
          NODE_ENV = "production";
          PORT = "3000";
          NODE_DEBUG = "http,net";
        };
        volumes = [
          "/var/www/jxbShoopBackend:/app"
        ];
        joinCustomNetwork = true;

        # 正确的启动命令配置
        cmd = [ "sh" "-c" "cd /app && node server.js" ];
      };
    };
  };
}
