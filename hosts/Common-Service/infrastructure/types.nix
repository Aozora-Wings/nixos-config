#types.nix
{ lib, ... }:

let
  inherit (lib) types mkOption;
in
{
  options = {
        setDnsRecord = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to create DNS record for this website";
          };
          target = lib.mkOption {
            type = lib.types.str;
            description = "The target domain for CNAME record";
          };
          recordType = lib.mkOption {
            type = lib.types.str;
            default = "CNAME";
            description = "Type of DNS record (CNAME, A, etc.)";
          };
          ttl = lib.mkOption {
            type = lib.types.int;
            default = 3600;
            description = "TTL for DNS record in seconds";
          };
        };
      };
      default = { };
      description = "DNS record configuration";
    };
    proxyPass = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Direct proxy pass target without container.";
    };

    enableSSL = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable ACME/Let's Encrypt SSL for this domain.";
    };

    enableNginx = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Nginx configuration for this website. Set to false for container-only setup.";
    };
    requireClientCertificate = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Client Certificate.";
    };
    acmeEmail = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Email for ACME certificate (optional, uses global default if not set).";
    };

    dnsProvider = mkOption {
      type = types.nullOr types.str;
      default = "azuredns";
      description = "DNS provider for DNS-01 challenge (e.g., azuredns).";
    };

    credentialsFile = mkOption {
      type = types.nullOr types.str;
      default = "/etc/acme/azure.env";
      description = "Path to credentials file for DNS provider.";
    };

    isDefault = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this is the default site for all unknown domains";
    };

    enableWildcardSSL = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable wildcard SSL certificate for this domain";
    };
    ociContainer = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to enable OCI container.";
          };
          enableFUSE = mkOption {
            type = types.bool;
            default = false;
            description = "Enable FUSE3 support for this container (required for CloudDrive, rclone, etc.)";
          };

          image = mkOption {
            type = types.str;
            description = "Container image to use.";
          };

          imageTag = mkOption {
            type = types.str;
            default = "latest";
            description = "Container image tag.";
          };

          ports = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Port mappings (e.g., [\"8080:80\"]).";
          };

          environment = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Environment variables.";
          };

          volumes = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Volume mappings.";
          };
          # 添加 cmd 选项
          cmd = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Command to run in container.";
          };
          extraOptions = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Extra podman run options.";
          };

          proxyPass = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Nginx proxy pass target (auto-generated from ports if null).";
          };

          joinCustomNetwork = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to join the custom internal network for container communication.";
          };

          hostname = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Custom hostname for container (defaults to container name).";
          };

          initScript = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Initialization script to run on first container start.";
          };

          updateScript = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Update script to run on every configuration change.";
          };

          dbConfig = mkOption {
            type = types.nullOr (types.submodule {
              options = {
                rootPassword = mkOption {
                  type = types.str;
                  description = "MySQL root password.";
                };

                host = mkOption {
                  type = types.str;
                  default = "localhost";
                  description = "Database host for update scripts.";
                };

                # 新增功能：数据库名称
                database = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Database name (optional).";
                };

                # 新增功能：数据库用户
                username = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Database username (optional, uses root if not set).";
                };
              };
            });
            default = null;
            description = "Database configuration for update scripts.";
          };

          # 新增功能：健康检查
          healthCheck = mkOption {
            type = types.nullOr (types.submodule {
              options = {
                test = mkOption {
                  type = types.str;
                  description = "Health check command.";
                };
                interval = mkOption {
                  type = types.str;
                  default = "30s";
                  description = "Check interval.";
                };
                timeout = mkOption {
                  type = types.str;
                  default = "10s";
                  description = "Check timeout.";
                };
                retries = mkOption {
                  type = types.int;
                  default = 3;
                  description = "Number of retries before marking unhealthy.";
                };
              };
            });
            default = null;
            description = "Container health check configuration.";
          };
        };
      });
      default = null;
      description = "OCI container configuration.";
    };
    Index = mkOption {
      type = types.nullOr types.str;
      default = "index.html index.htm";
      description = "index file.";
    };
  };
}
