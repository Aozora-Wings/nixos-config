{ config, lib, pkgs, install-config, unstable,mapPort, ... }: {
  myWebsites = {
    phpmyadmin = {
      domain = "apcx.qkzy.net";
      enableSSL = true;
      setDnsRecord = {
        enable = true;
        target = "alist.qkzy.net";
        recordType = "CNAME";
        ttl = 3600;
      };
      ociContainer = {
        enable = true;
        image = "phpmyadmin";
        imageTag = "latest";
        ports = [(mapPort "phpmyadmin" 80)];
        environment = {
          PMA_ARBITRARY="1";
          # PMA_HOST = "db-qkzy-net";
          # PMA_PORT = "3306";
          # PMA_USER = "root";
          # PMA_PASSWORD = "e73XhQwCNfjSYYt2";
        };
        #volumes = ["phpmyadmin_data:/var/www/html"];
        joinCustomNetwork = true;
      };
    };
  };
}