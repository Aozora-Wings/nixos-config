#service/web/default.nix
{ config, lib, pkgs, install-config, unstable, ... }:
let
  # 如果install-config中没有定义所需的端口，可以在这里添加默认值
  defaultPorts = {
    jxbShoopSite = 11003; # 前端映射端口
    jxbShoopApi = 11004; # 后端API映射端口
    phpmyadmin = 11005; # PHPMyAdmin映射端口
    jxbShoopFrontend = 8082; # 可选：独立前端端口
    jxbShoopBackend = 8083; # 可选：独立后端端口
  };

  # 获取端口的辅助函数
  getPort = service:
    let
      port = if install-config.def_ports ? ${service} then install-config.def_ports.${service} else defaultPorts.${service};
    in
    port;

  # 安全的端口映射函数
  mapPort = (service: containerPort:
    "${toString (getPort service)}:${toString containerPort}"
  );
  npsPorts = lib.flatten (lib.mapAttrsToList
    (name: clientConfig:
      lib.range clientConfig.start clientConfig.end
    )
    install-config.def_ports.nps_client);
in
{
  # 只导入function目录，避免nginx配置重复
  imports = [ ./function ];
  # 移除了直接导入nginx.nix的引用，因为function目录中已经包含了nginx配置

  virtualisation.docker.enable = false;


  myWebsites = {
    TestSite = {
      enable = true; # 这个必须有！
      domain = "test.app.qkzy.net";
      enableSSL = true;
      dnsProvider = "azuredns";
      credentialsFile = "/etc/acme/azure.env";
      indexContent = ''
        <!DOCTYPE html>
        <html>
        <head><title>My Test Site</title></head>
        <body><h1>Hello from NixOS!</h1><p>This was deployed declaratively!</p></body>
        </html>
      '';
    };


    LocalConnectTestSite = {
      enable = true; # 这个必须有！
      domain = "wt.app.app.qkzy.net";
      enableSSL = true;
      proxyPass = "http://127.0.0.1:9210";
    };




    # MySQL 数据库
    # MySQL 数据库 - 使用自定义网络






    # 容器-only示例 - 只运行容器，不配置nginx代理




    # phpmyadmin = {
    #   domain = "apcx.app.qkzy.net";
    #   enableSSL = true;
    #   ociContainer = {
    #     enable = true;
    #     image = "phpmyadmin";
    #     imageTag = "latest";
    #     ports = [(mapPort "phpmyadmin" 80)];
    #     environment = {
    #       PMA_ARBITRARY="1";
    #       # PMA_HOST = "db-qkzy-net";
    #       # PMA_PORT = "3306";
    #       # PMA_USER = "root";
    #       # PMA_PASSWORD = "e73XhQwCNfjSYYt2";
    #     };
    #     #volumes = ["phpmyadmin_data:/var/www/html"];
    #     joinCustomNetwork = true;
    #   };
    # };
  };
}
