#service/web/function/default.nix
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption mkIf types;
in
{
  imports = [
    ./types.nix
    ./acme.nix
    ./containers.nix
    ./database.nix
    ./firewall.nix
    ./nginx.nix
    ./dns-records.nix
    ./azure-dns-env.nix
  ];

  options = {
    myWebsites = mkOption {
      description = "A declarative way to manage simple static websites";
      default = {};
      type = types.attrsOf (types.submodule ({ name, ... }: {
        imports = [ ./types.nix ];
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to enable this website.";
          };
          domain = mkOption {
            type = types.str;
            description = "The domain name for this website (e.g., example.com).";
          };
          rootDir = mkOption {
            type = types.str;
            default = "/var/www/${name}";
            description = "The root directory for the website files.";
          };
          indexContent = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Optional HTML content for index.html. If set, it will be created automatically.";
          };
          
          # 注释掉或移除新增的功能选项
          /*
          basicAuth = mkOption {
            type = types.nullOr (types.attrsOf types.str);
            default = null;
            description = "Basic authentication credentials (username -> password).";
          };
          
          errorPages = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Custom error pages (code -> path, e.g. { \"404\" = \"/errors/404.html\"; }).";
          };
          
          securityHeaders = mkOption {
            type = types.attrsOf types.str;
            default = {
              "X-Frame-Options" = "SAMEORIGIN";
              "X-Content-Type-Options" = "nosniff";
              "X-XSS-Protection" = "1; mode=block";
            };
            description = "Security headers to add to responses.";
          };
          */
        };
      }));
    };

    myWebsitesAcme = {
      acceptTerms = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to accept the ACME CA terms of service.";
      };
      defaultsEmail = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default email for ACME certificates.";
      };
      server = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "ACME server URL (e.g., Let's Encrypt staging).";
      };
    };
  };

  config = {
    # 创建网站根目录和内容的激活脚本
    system.activationScripts."create-my-websites" = let
      websiteScripts = lib.mapAttrsToList
        (websiteName: cfg:
          lib.optionalString cfg.enable ''
            echo "Setting up website: ${websiteName} at ${cfg.rootDir}"
            mkdir -p "${cfg.rootDir}"
            chmod 755 "${cfg.rootDir}"
            ${
              if cfg.indexContent != null then ''
                cat > "${cfg.rootDir}/index.html" << 'EOF'
${cfg.indexContent}
EOF
                chmod 644 "${cfg.rootDir}/index.html"
              '' else ""
            }
            if getent passwd nginx > /dev/null; then
              chown -R nginx:users "${cfg.rootDir}" || echo "WARNING: Failed to change ownership"
              chmod -R 775 "${cfg.rootDir}" || echo "WARNING: Failed to change permissions"
            fi
          ''
        )
        config.myWebsites;
    in
      lib.strings.concatStringsSep "\n" websiteScripts;
  };
}