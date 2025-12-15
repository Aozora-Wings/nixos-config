# ./docker-compose.nix (更新版)
{ config, lib, pkgs, MySecrets, ... }:

{

  options.modules-install.docker-compose = {
    enable = lib.mkEnableOption "Enable Docker Compose like services using OCI containers";

    containers = lib.mkOption {
      type = with lib.types; attrsOf (submodule {
        options = {
          image = lib.mkOption {
            type = str;
            description = "Docker image to use";
          };
          ports = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = "Port mappings";
          };
          environment = lib.mkOption {
            type = with lib.types; attrsOf str;
            default = { };
            description = "Environment variables";
          };
          volumes = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = "Volume mappings";
          };
          dependsOn = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = "Container dependencies";
          };
          # 新增：支持网络模式
          networkMode = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            description = "Network mode (e.g., host, bridge)";
          };
          # 新增：支持特权模式
          privileged = lib.mkOption {
            type = with lib.types; bool;
            default = false;
            description = "Run container in privileged mode";
          };
          # 添加 log-driver 选项
          log-driver = lib.mkOption {
            type = with lib.types; str;
            default = "journald";
            description = "Logging driver for the container";
          };
          # 新增：支持额外选项
          extraOptions = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = "Extra docker options";
          };
        };
      });
      default = { };
      description = "Container definitions";
    };
  };

  config = {
    environment.etc."docker/registry-mapping.json".text =
      builtins.toJSON (MySecrets.docker-mirror.registryMapping or { });

  } // lib.mkIf config.modules-install.docker-compose.enable {
    # 启用 Docker
    #virtualisation.docker.enable = true;
    # 配置 OCI 容器，处理特殊选项

    virtualisation.oci-containers.containers =
      lib.mapAttrs
        (name: container: {
          inherit (container) image ports environment volumes;
          # 添加 log-driver 映射
          log-driver = container.log-driver or "journald";
          autoStart = container.autoStart or true;

          extraOptions =
            (if container.networkMode != null then [ "--network=${container.networkMode}" ] else [ ])
              ++ (if container.privileged then [ "--privileged" ] else [ ])
              ++ container.extraOptions;
        })
        config.modules-install.docker-compose.containers;
  };
}
