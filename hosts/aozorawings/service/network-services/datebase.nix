{ config, lib, pkgs, install-config, unstable, ... }: {
  myWebsites = {
    DatabaseSite = {
      domain = "db.app.qkzy.net";
      enable = true;
      enableSSL = false;
      ociContainer = {
        enable = true;
        image = "mariadb";
        imageTag = "10.11";
        ports = [ ]; # 不暴露外部端口，只在内部网络访问
        environment = {
          MYSQL_ROOT_PASSWORD = "rootpassword123";
        };
        volumes = [ "mariadb_new_data:/var/lib/mysql" ];
        joinCustomNetwork = true;
        hostname = "db-qkzy-net"; # 设置固定主机名
        dbConfig = {
          rootPassword = "rootpassword123";
          host = "db-qkzy-net"; # 使用容器主机名
        };
        initScript = ''
          CREATE DATABASE IF NOT EXISTS wordpress;
          CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY 'wppassword123';
          GRANT ALL ON wordpress.* TO 'wpuser'@'%';
          CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'apppassword123';
          CREATE DATABASE IF NOT EXISTS appdb;
          GRANT ALL ON appdb.* TO 'appuser'@'%';
          CREATE DATABASE IF NOT EXISTS bitwarden;
          CREATE USER IF NOT EXISTS 'bitwarden'@'%' IDENTIFIED BY 'JptR8jEaHy2dH2my';
          GRANT ALL ON bitwarden.* TO 'bitwarden'@'%';
          CREATE DATABASE IF NOT EXISTS JxbStore;
          CREATE USER IF NOT EXISTS 'JxbStore'@'%' IDENTIFIED BY 'e73XhQwCNfjSYYt2';
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
