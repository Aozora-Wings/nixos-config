{ config, lib, pkgs, install-config, unstable, ... }: {
  myWebsites = {
    backup_mysql = {
      domain = "backup_mysql";
      enable = true;
      enableNginx = false; # 设置为false表示只创建容器，不配置nginx
      enableSSL = false;
      ociContainer = {
        enable = true;
        image = "localhost/db-backup";
        imageTag = "latest";
        ports = [ ];
        joinCustomNetwork = true;
        environment = {
          TZ = "Asia/Shanghai";
        };
        volumes = [
          "/home/wt/create/python:/app"
          "/etc/localtime:/etc/localtime:ro"
          "/cloud/115open/个人文件/mysql_backup/:/mysql_backup/"
        ];
        #waitForServices = [ "clouddrive2" ];
      };
    };
  };
}
