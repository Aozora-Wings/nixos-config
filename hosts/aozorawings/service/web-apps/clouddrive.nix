{ config, lib, pkgs, install-config, unstable, ... }: {
  myWebsites = {
    "clouddrive" = {
      enable = true;
      domain = "cd2.app.qkzy.net";
      enableNginx = true;
      enableSSL = true;
      proxyPass = "http://[::1]:19798";
      setDnsRecord = {
        enable = true;
        target = "aozorawings.qkzy.net";
        recordType = "CNAME";
        ttl = 3600;
      };
    };
  };
}
