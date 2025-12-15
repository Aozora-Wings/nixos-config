{ config, lib, pkgs, install-config, unstable, ... }: {
  myWebsites = {
    DefaultAppSite = {
      enable = true;  # 这个必须有！
      enableNginx = true;
      enableSSL = true;
      isDefault = true;
      enableWildcardSSL = true;
      domain = "qkzy.net";
      dnsProvider = "azuredns";
      credentialsFile = "/etc/acme/azure.env";
      indexContent = ''
        <!DOCTYPE html>
        <html>
        <head><title>My Test Site</title></head>
        <body><h1>Hello from NixOS!</h1><p>This Site Created By Flakes!</p></body>
        </html>
      '';
    };
  };
}