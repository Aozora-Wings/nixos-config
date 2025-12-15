{ config, lib, pkgs, install-config, unstable,mapPort, ... }: let
  #port = import ../lib/ports.nix { inherit lib install-config; };
  web = parseConfigFile "/run/agenix/web";
  hasDecryptedSecret = builtins.pathExists "/run/agenix/web";
in {
  myWebsites = lib.mkIf hasDecryptedSecret {
    WordPressSite = {
      domain = "wp.qkzy.net";
      enableSSL = true;
      ociContainer = {
        enable = true;
        image = "wordpress";
        imageTag = "latest";
        ports = [ (mapPort "WordPressSite" 80) ];
        environment = {
          WORDPRESS_DB_HOST = "db-qkzy-net";  # 使用数据库容器主机名
          WORDPRESS_DB_USER = "wpuser";
          WORDPRESS_DB_PASSWORD = web.wpuser;
          WORDPRESS_DB_NAME = "wordpress";
        };
        volumes = ["wordpress_data:/var/www/html"];
        joinCustomNetwork = true;  # 加入同一网络
      };
    };
  };
}