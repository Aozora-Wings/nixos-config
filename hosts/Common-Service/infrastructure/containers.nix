# services/my-websites/containers.nix
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf types;
  
  domainToUnit = domain: lib.replaceStrings ["."] ["-"] domain;
  customNetworkName = "nixos-app-network";
  
  anyOCIContainerEnabled = lib.any 
    (cfg: cfg.enable && cfg.ociContainer != null && cfg.ociContainer.enable) 
    (lib.attrValues config.myWebsites);
    
  anyContainerNeedsNetwork = lib.any 
    (cfg: cfg.enable && cfg.ociContainer != null && cfg.ociContainer.enable && cfg.ociContainer.joinCustomNetwork) 
    (lib.attrValues config.myWebsites);

  # 检查是否有容器需要 FUSE3 支持
  anyContainerNeedsFUSE = lib.any 
    (cfg: cfg.enable && cfg.ociContainer != null && cfg.ociContainer.enable && cfg.ociContainer.enableFUSE) 
    (lib.attrValues config.myWebsites);
in
{
  config = mkIf anyOCIContainerEnabled {
    virtualisation.podman.enable = true;
    virtualisation.podman.dockerCompat = true;
    virtualisation.podman.dockerSocket.enable = true;

    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers = lib.mapAttrs'
      (websiteName: websiteCfg:
        let 
          container = websiteCfg.ociContainer;
          containerName = domainToUnit websiteCfg.domain;
          hostname = if container.hostname != null then container.hostname else containerName;
          
          # 如果启用 FUSE，添加必要的选项
          fuseOptions = lib.optionals (container.enableFUSE or false) [
            "--privileged"
            "--device=/dev/fuse:/dev/fuse"
            "--security-opt=apparmor:unconfined"
            "--cap-add=SYS_ADMIN"
          ];
        in
        lib.nameValuePair containerName (mkIf (websiteCfg.enable && container != null && container.enable) {
          image = "${container.image}:${container.imageTag}";
          ports = container.ports;
          environment = container.environment;
          volumes = container.volumes;
          cmd = container.cmd;
          extraOptions = container.extraOptions ++ fuseOptions ++ [
            "--hostname=${hostname}"
            "--name=${containerName}"
          ] ++ (lib.optionals container.joinCustomNetwork [
            "--network=${customNetworkName}"
          ]) ++ (lib.optionals (container.healthCheck != null) [
            "--health-cmd=${container.healthCheck.test}"
            "--health-interval=${container.healthCheck.interval}"
            "--health-timeout=${container.healthCheck.timeout}"
            "--health-retries=${toString container.healthCheck.retries}"
          ]);
          autoStart = true;
        })
      )
      config.myWebsites;

    # Podman 网络创建服务
    systemd.services."create-podman-network" = mkIf anyContainerNeedsNetwork {
      description = "Create custom Podman network for NixOS containers";
      after = [ "podman.service" ];
      requires = [ "podman.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if ! ${pkgs.podman}/bin/podman network inspect ${customNetworkName} > /dev/null 2>&1; then
          echo "Creating Podman network: ${customNetworkName}"
          ${pkgs.podman}/bin/podman network create \
            --driver bridge \
            --subnet=172.30.0.0/16 \
            --gateway=172.30.0.1 \
            ${customNetworkName}
        else
          echo "Podman network ${customNetworkName} already exists"
        fi
      '';
      wantedBy = [ "multi-user.target" ];
    };

    # 通用 FUSE3 共享挂载支持（任何需要 FUSE 的容器都会用到）
    systemd.services."setup-fuse-shared-mounts" = mkIf anyContainerNeedsFUSE {
      description = "Setup shared mounts for FUSE3 containers";
      after = [ "local-fs.target" ];
      before = [ "podman.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # 为根文件系统启用共享挂载（FUSE3 必需）
        echo "Setting up shared mount propagation for FUSE3 support"
        mount --make-shared / || echo "Note: Root filesystem already shared or unable to modify"
        
        # 确保 FUSE 设备可用
        if [ ! -e /dev/fuse ]; then
          echo "Creating FUSE device"
          mknod /dev/fuse c 10 229
          chmod 666 /dev/fuse
        fi
      '';
    };
  };
}