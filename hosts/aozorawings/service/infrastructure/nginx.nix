# services/my-websites/nginx.nix
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf types;

  extractHostPort = ports:
    let
      firstPort = lib.lists.head ports;
      parts = lib.splitString ":" firstPort;
    in
    if lib.length parts == 2 then
      lib.lists.head parts
    else
      "8080";

  # 检查是否有任何网站需要nginx配置
  anyNginxEnabled = lib.any
    (cfg: cfg.enable && cfg.enableNginx)
    (lib.attrValues config.myWebsites);

  # 客户端证书配置
  clientCertConfig = {
    sslTrustedCertificate = "/etc/nginx/client_ca.crt";
    extraConfig = ''
      # 客户端证书验证
      ssl_client_certificate /etc/nginx/client_ca.crt;
      ssl_verify_client on;
      ssl_verify_depth 2;
      
      # 客户端证书验证失败时的错误页面
      error_page 495 496 = @client_cert_error;
    '';
  };

  # 代理配置函数
  createProxyConfig = proxyTarget: needsClientCert: {
    proxyPass = proxyTarget;
    proxyWebsockets = true;
    recommendedProxySettings = false;
    extraConfig = ''
      # 基础代理头
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header X-Forwarded-Server $host;
      
      # 安全超时设置
      proxy_read_timeout 300;
      proxy_connect_timeout 300;
      proxy_send_timeout 300;
      proxy_buffer_size 4k;
      proxy_buffers 8 4k;
      
      # 安全头
      add_header X-Frame-Options DENY always;
      add_header X-Content-Type-Options nosniff always;
      add_header X-XSS-Protection "1; mode=block" always;
      add_header Referrer-Policy "strict-origin-when-cross-origin" always;
      
      # 客户端证书信息（只在 location 级别设置，避免重复）
      ${lib.optionalString needsClientCert ''
        proxy_set_header X-Client-Certificate $ssl_client_cert;
        proxy_set_header X-Client-Verify $ssl_client_verify;
        proxy_set_header X-Client-DN $ssl_client_s_dn;
        proxy_set_header X-Client-I-DN $ssl_client_i_dn;
      ''}
    '';
  };

  # 统一的虚拟主机创建函数
  createVirtualHost = websiteName: websiteCfg:
    let
      container = websiteCfg.ociContainer;

      proxyTarget =
        if websiteCfg.proxyPass != null then
          websiteCfg.proxyPass
        else if container != null && container.enable then
          if container.proxyPass != null then
            container.proxyPass
          else if container.ports != [ ] then
            "http://127.0.0.1:${extractHostPort container.ports}"
          else
            null
        else
          null;

      enableProxy = proxyTarget != null;
      isDefault = websiteCfg.isDefault == true;
      isDefaultWildcard = isDefault && websiteCfg.enableWildcardSSL;
      needsClientCert = websiteCfg.requireClientCertificate or false;

      # 基础 location 配置
      baseLocation =
        if enableProxy then
          createProxyConfig proxyTarget needsClientCert
        else {
          index = websiteCfg.Index;
          tryFiles = "$uri $uri/ =404";
        };

      # 基础虚拟主机配置
      baseVirtualHost = {
        serverName = websiteCfg.domain;
        root = websiteCfg.rootDir;
        forceSSL = websiteCfg.enableSSL;
        enableACME = websiteCfg.enableSSL;
        default = isDefault;

        extraConfig = ''
          add_header X-Config-Source "virtual-host" always;
          add_header X-Website-Name "${websiteName}" always;
          ${lib.optionalString isDefault "add_header X-Default-Site \"true\" always;"}
          ${lib.optionalString isDefaultWildcard "add_header X-Uses-Wildcard-Cert \"true\" always;"}
          add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload" always;
        '';

        locations."/" = baseLocation;
      };

      # 客户端证书特定的配置
      clientCertVirtualHost = lib.optionalAttrs needsClientCert {
        sslTrustedCertificate = clientCertConfig.sslTrustedCertificate;
        extraConfig = baseVirtualHost.extraConfig + clientCertConfig.extraConfig;

        locations = baseVirtualHost.locations // {
          "@client_cert_error" = {
            extraConfig = ''
              return 403 "Client certificate required or invalid certificate provided.";
            '';
          };
        };
      };

    in
    if websiteCfg.enable && websiteCfg.enableNginx then
      {
        "${websiteName}" =
          if needsClientCert then
            baseVirtualHost // clientCertVirtualHost
          else
            baseVirtualHost;
      }
    else
      { };
  # 生成客户端证书的工具脚本
  generateClientCertScript = pkgs.writeShellScriptBin "generate-client-cert" ''
    set -e
  
    if [ ! -f /etc/nginx/client_ca.crt ]; then
      echo "错误: 系统 CA 证书不存在。请先启用客户端证书认证的网站并重建系统。"
      exit 1
    fi
  
    CLIENT_NAME="''${1:-client}"
    OUTPUT_DIR="''${2:-./client-certs}"
  
    # 创建输出目录
    mkdir -p "$OUTPUT_DIR"
  
    CLIENT_KEY="$OUTPUT_DIR/$CLIENT_NAME.key"
    CLIENT_CSR="$OUTPUT_DIR/$CLIENT_NAME.csr" 
    CLIENT_CRT="$OUTPUT_DIR/$CLIENT_NAME.crt"
    CLIENT_P12="$OUTPUT_DIR/$CLIENT_NAME.p12"
  
    echo "为客户端 '$CLIENT_NAME' 生成证书..."
    echo "证书文件将保存在: $OUTPUT_DIR/"
  
    # 生成客户端密钥和证书请求
    ${pkgs.openssl}/bin/openssl genrsa -out "$CLIENT_KEY" 2048
    ${pkgs.openssl}/bin/openssl req -new -key "$CLIENT_KEY" -out "$CLIENT_CSR" \
      -subj "/CN=$CLIENT_NAME/O=Client/C=CN"
  
    # 在临时目录处理序列号，避免权限问题
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
  
    # 复制序列号文件到临时目录
    if [ -f /etc/nginx/client_ca.srl ]; then
      cp /etc/nginx/client_ca.srl ./
    else
      # 创建初始序列号
      echo "01" > client_ca.srl
    fi
  
    # 使用临时目录的序列号文件签发证书
    ${pkgs.openssl}/bin/openssl x509 -req -days 365 -in "$CLIENT_CSR" \
      -CA /etc/nginx/client_ca.crt \
      -CAkey /etc/nginx/client_ca.key \
      -CAserial client_ca.srl -CAcreateserial \
      -out "$CLIENT_CRT"
  
    # 更新系统序列号文件（需要sudo）
    sudo cp client_ca.srl /etc/nginx/client_ca.srl
    sudo chmod 644 /etc/nginx/client_ca.srl
    sudo chown nginx:wheel /etc/nginx/client_ca.srl
  
    # 复制生成的证书文件到输出目录
    cp "$CLIENT_CRT" "$OUTPUT_DIR/"
  
    # 清理临时目录
    cd -
    rm -rf "$TEMP_DIR"
  
    # 生成 PKCS12 格式
    ${pkgs.openssl}/bin/openssl pkcs12 -export -out "$CLIENT_P12" \
      -inkey "$CLIENT_KEY" -in "$CLIENT_CRT" \
      -certfile /etc/nginx/client_ca.crt -passout pass:
  
    # 清理临时文件
    rm -f "$CLIENT_CSR"
  
    echo "✅ 完成！生成的客户端证书文件:"
    echo "   客户端证书: $CLIENT_CRT"
    echo "   客户端私钥: $CLIENT_KEY" 
    echo "   浏览器格式: $CLIENT_P12"
    echo ""
    echo "使用示例:"
    echo "  curl --cert $CLIENT_CRT --key $CLIENT_KEY https://cd2.qkzy.net"
    echo "  或将 $CLIENT_P12 导入浏览器"
  '';
in
{
  config = mkIf anyNginxEnabled {
    services.nginx.enable = true;
    services.nginx.group = "acme";
    services.nginx.package = pkgs.openresty;

    # 全局 Nginx 安全配置
    services.nginx.recommendedOptimisation = true;
    services.nginx.recommendedTlsSettings = true;
    services.nginx.recommendedGzipSettings = true;

    services.nginx.virtualHosts =
      let
        virtualHostsList = lib.mapAttrsToList createVirtualHost config.myWebsites;
        mergedVirtualHosts = lib.foldl (acc: hosts: acc // hosts) { } virtualHostsList;
      in
      mergedVirtualHosts;

    # 自动生成并安装 CA 证书
    system.activationScripts.nginx-client-ca = lib.mkIf
      (lib.any
        (cfg: cfg.enable && cfg.enableNginx && (cfg.requireClientCertificate or false))
        (lib.attrValues config.myWebsites))
      {
        text = ''
          if [ ! -f /etc/nginx/client_ca.crt ]; then
            echo "自动生成客户端 CA 证书..."
            mkdir -p /etc/nginx
            HOSTNAME=$(cat /proc/sys/kernel/hostname 2>/dev/null || echo "unknown-host")
          
            # 生成 CA 密钥和证书
            ${pkgs.openssl}/bin/openssl genrsa -out /etc/nginx/client_ca.key 2048
            ${pkgs.openssl}/bin/openssl req -new -x509 -days 3650 \
              -key /etc/nginx/client_ca.key \
              -out /etc/nginx/client_ca.crt \
              -subj "/CN=Nginx Client CA/O=Auto-generated on $HOSTNAME/C=CN"

            # 设置适当的权限
            chmod 600 /etc/nginx/client_ca.key
            chmod 644 /etc/nginx/client_ca.crt
            chown nginx:wheel /etc/nginx/client_ca.*
          
            echo "✅ CA 证书已自动生成:"
            echo "   CA 证书: /etc/nginx/client_ca.crt"
            echo "   CA 私钥: /etc/nginx/client_ca.key"
            echo ""
            echo "现在你可以使用 generate-client-cert 命令生成客户端证书"
          else
            echo "✅ 客户端 CA 证书已存在: /etc/nginx/client_ca.crt"
          fi
        '';
      };

    environment.systemPackages = [ generateClientCertScript ];
  };
}
