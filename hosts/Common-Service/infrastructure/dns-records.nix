# dns-records.nix
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;
  hasDecryptedSecret = builtins.pathExists "/run/agenix/azure-token";
  # 检查是否有启用的 DNS 记录配置
  anyDnsEnabled = 
    hasDecryptedSecret &&  # 先检查密钥存在
    lib.any 
      (cfg: cfg.enable && cfg.setDnsRecord.enable) 
      (lib.attrValues config.myWebsites);

  # 为每个需要 DNS 记录的网站创建 systemd 服务
  dnsServices = lib.mapAttrs' 
    (name: cfg: 
      lib.nameValuePair 
        "create-dns-${name}" 
        (mkIf (cfg.enable && cfg.setDnsRecord.enable) {
          description = "Create DNS record for ${cfg.domain}";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          path = with pkgs; [ azure-cli gnused gnugrep ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "create-dns-${name}" ''
              set -e
              echo "Creating DNS record for ${cfg.domain} -> ${cfg.setDnsRecord.target}"
              
              # 从环境变量文件读取凭据
              AZURE_SUBSCRIPTION_ID=$(grep AZURE_SUBSCRIPTION_ID /etc/acme/azure.env | cut -d '=' -f2)
              AZURE_TENANT_ID=$(grep AZURE_TENANT_ID /etc/acme/azure.env | cut -d '=' -f2)
              AZURE_CLIENT_ID=$(grep AZURE_CLIENT_ID /etc/acme/azure.env | cut -d '=' -f2)
              AZURE_CLIENT_SECRET=$(grep AZURE_CLIENT_SECRET /etc/acme/azure.env | cut -d '=' -f2)
              
              # 验证凭据是否存在
              if [ -z "$AZURE_SUBSCRIPTION_ID" ] || [ -z "$AZURE_TENANT_ID" ] || [ -z "$AZURE_CLIENT_ID" ] || [ -z "$AZURE_CLIENT_SECRET" ]; then
                echo "ERROR: Missing Azure credentials in /etc/acme/azure.env"
                exit 1
              fi
              
              # 使用服务主体登录
              echo "Logging into Azure..."
              az login --service-principal \
                --username "$AZURE_CLIENT_ID" \
                --password "$AZURE_CLIENT_SECRET" \
                --tenant "$AZURE_TENANT_ID" \
                --output none
              
              az account set --subscription "$AZURE_SUBSCRIPTION_ID"
              
              # 检查记录是否已存在
              echo "Checking if DNS record already exists..."
              if az network dns record-set ${cfg.setDnsRecord.recordType} show \
                --resource-group dns \
                --zone-name qkzy.net \
                --name "${lib.removeSuffix ".qkzy.net" cfg.domain}" > /dev/null 2>&1; then
                echo "DNS record already exists, updating..."
                az network dns record-set ${cfg.setDnsRecord.recordType} set-record \
                  --resource-group dns \
                  --zone-name qkzy.net \
                  --record-set-name "${lib.removeSuffix ".qkzy.net" cfg.domain}" \
                  --cname "${cfg.setDnsRecord.target}" \
                  --ttl ${toString cfg.setDnsRecord.ttl}
              else
                echo "Creating new DNS record..."
                az network dns record-set ${cfg.setDnsRecord.recordType} create \
                  --resource-group dns \
                  --zone-name qkzy.net \
                  --name "${lib.removeSuffix ".qkzy.net" cfg.domain}" \
                  --ttl ${toString cfg.setDnsRecord.ttl}
                
                az network dns record-set ${cfg.setDnsRecord.recordType} set-record \
                  --resource-group dns \
                  --zone-name qkzy.net \
                  --record-set-name "${lib.removeSuffix ".qkzy.net" cfg.domain}" \
                  --cname "${cfg.setDnsRecord.target}"
              fi
              
              echo "DNS record created/updated successfully"
              
              # 登出
              az logout
            '';
          };
          wantedBy = [ "multi-user.target" ];
        })
    )
    config.myWebsites;

in
{
  config = mkIf anyDnsEnabled {
    environment.systemPackages = with pkgs; [ azure-cli ];
    
    # 创建 systemd 服务
    systemd.services = dnsServices;
    
    # 可选：添加网络依赖
    systemd.targets.network-online.wantedBy = [ "multi-user.target" ];
  };
}