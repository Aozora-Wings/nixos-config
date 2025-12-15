# services/my-websites/acme.nix
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf types;

  anySSLEnabled = lib.any (cfg: cfg.enable && cfg.enableSSL) (lib.attrValues config.myWebsites);
  sslDomains = lib.filterAttrs (name: cfg: cfg.enable && cfg.enableSSL) config.myWebsites;

  # 获取证书名称 - 必须与nginx虚拟主机名一致
  getCertName = websiteCfg: websiteCfg.domain;

  # 获取实际提交给ACME的域名
  getCertDomain = websiteCfg:
    # 如果是默认网站且启用了泛域名SSL，申请泛域名证书
    if websiteCfg.isDefault && websiteCfg.enableWildcardSSL then
      "*.${lib.removePrefix "*." websiteCfg.domain}"
    else
      websiteCfg.domain;

  # 判断是否需要DNS验证
  needsDNSValidation = websiteCfg:
    # 泛域名必须使用DNS验证，或者显式指定了DNS提供商
    websiteCfg.isDefault && websiteCfg.enableWildcardSSL || websiteCfg.dnsProvider != null;

in
{
  config = mkIf anySSLEnabled {
    security.acme = {
      acceptTerms = config.myWebsitesAcme.acceptTerms;
      defaults = {
        email = config.myWebsitesAcme.defaultsEmail;
        server = config.myWebsitesAcme.server;
        webroot = "/var/lib/acme/acme-challenge";
      };

      certs = lib.mapAttrs'
        (websiteName: websiteCfg:
          let
            # 关键：证书名称必须与nginx虚拟主机名一致
            certName = getCertName websiteCfg;
            certDomain = getCertDomain websiteCfg;
            isDefaultWildcard = websiteCfg.isDefault && websiteCfg.enableWildcardSSL;

            validationMethod =
              if needsDNSValidation websiteCfg then
                "dns"
              else
                "webroot";

            azureEnvFile =
              if websiteCfg.dnsProvider == "azuredns" && websiteCfg.credentialsFile != null then
                websiteCfg.credentialsFile
              else
                null;

          in
          lib.nameValuePair certName (mkIf (websiteCfg.enable && websiteCfg.enableSSL) {
            # 申请时使用泛域名，但证书存储路径与nginx期望的一致
            domain = certDomain;

            email = if websiteCfg.acmeEmail != null then websiteCfg.acmeEmail else config.myWebsitesAcme.defaultsEmail;

            # 验证方法配置
            dnsProvider = if validationMethod == "dns" then websiteCfg.dnsProvider else null;
            credentialsFile = if validationMethod == "dns" then websiteCfg.credentialsFile else null;
            webroot = if validationMethod == "webroot" then "/var/lib/acme/acme-challenge" else null;

            environmentFile = azureEnvFile;

            # 如果是默认网站的泛域名证书，添加基础域名作为额外域名
            extraDomainNames = lib.optionals isDefaultWildcard [
              websiteCfg.domain # 包含基础域名，如 app.app.qkzy.net
            ];

            postRun = ''
              echo "Certificate for ${certDomain} has been renewed"
              ${pkgs.systemd}/bin/systemctl reload nginx
            '';
          })
        )
        sslDomains;
    };

    # 确保 ACME 目录存在并有正确权限
    system.activationScripts.acme-directories = ''
      mkdir -p /var/lib/acme/acme-challenge
      chmod 755 /var/lib/acme/acme-challenge
    '';
  };
}
