{ config, lib, pkgs, install-config, unstable,parseConfigFile, ... }: let 
  web = parseConfigFile "/run/agenix/web";
  hasDecryptedSecret = builtins.pathExists "/run/agenix/web";
  in
  {
  myWebsites = lib.mkIf hasDecryptedSecret {
    DatabaseSite = {
      domain = "db.qkzy.net";
      enable = true;
      enableSSL = false;
      ociContainer = {
        enable = true;
        image = "mariadb";
        imageTag = "10.11";
        ports = [];  # 不暴露外部端口，只在内部网络访问
        environment = {
          MYSQL_ROOT_PASSWORD = web.mysql_root_password;
        };
        volumes = ["mariadb_new_data:/var/lib/mysql"];
        joinCustomNetwork = true;
        hostname = "db-qkzy-net";  # 设置固定主机名
        dbConfig = {
          rootPassword = web.mysql_root_password;
          host = "db-qkzy-net";  # 使用容器主机名
        };
        initScript = ''
          CREATE DATABASE IF NOT EXISTS wordpress;
          CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY '${web.wpuser}';
          GRANT ALL ON wordpress.* TO 'wpuser'@'%';
          CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY '${web.appuser}';
          CREATE DATABASE IF NOT EXISTS appdb;
          GRANT ALL ON appdb.* TO 'appuser'@'%';
          CREATE DATABASE IF NOT EXISTS bitwarden;
          CREATE USER IF NOT EXISTS 'bitwarden'@'%' IDENTIFIED BY '${web.bitwarden}';
          GRANT ALL ON bitwarden.* TO 'bitwarden'@'%';
          CREATE DATABASE IF NOT EXISTS JxbStore;
          CREATE USER IF NOT EXISTS 'JxbStore'@'%' IDENTIFIED BY '${web.JxbStore}';
          GRANT ALL ON JxbStore.* TO 'JxbStore'@'%';
          FLUSH PRIVILEGES;
        '';
        # updateScript = ''

        # FLUSH PRIVILEGES;
        # '';
        
      };
    };
  };
}