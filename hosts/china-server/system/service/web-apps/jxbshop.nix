{ config, lib, pkgs, install-config, unstable, mapPort, parseConfigFile, ... }:
let
  #port = import ../lib/ports.nix { inherit lib install-config; };
  web = parseConfigFile "/run/agenix/web";
  hasDecryptedSecret = builtins.pathExists "/run/agenix/web";
in
{
  myWebsites = {
    jxbShoopFrontend = {
      domain = "cj.app.qkzy.net";
      enableSSL = true;
      Index = "index.html";
      setDnsRecord = {
        enable = true;
        target = "alist.qkzy.net";
        recordType = "CNAME";
        ttl = 3600;
      };
    };
    jxbShoopFrontendzk = {
      domain = "zk.app.qkzy.net";
      enableSSL = true;
      Index = "index.html";
      setDnsRecord = {
        enable = true;
        target = "alist.qkzy.net";
        recordType = "CNAME";
        ttl = 3600;
      };
    };
    # 
    jxbShoopBackend = {
      domain = "api.cj.app.qkzy.net";
      enableSSL = true;
      setDnsRecord = {
        enable = true;
        target = "alist.qkzy.net";
        recordType = "CNAME";
        ttl = 3600;
      };
      ociContainer = lib.mkIf hasDecryptedSecret {
        enable = true;
        image = "node";
        imageTag = "latest";
        ports = [ (mapPort "jxbShoopBackend" 3000) ];
        environment = {
          DATABASE_URL = "mysql://JxbStore:${web.JxbStore}@db-qkzy-net:3306/JxbStore";
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
