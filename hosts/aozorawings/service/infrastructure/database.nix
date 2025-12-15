{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf types;
  
  domainToUnit = domain: lib.replaceStrings ["."] ["-"] domain;
  
  anyContainerNeedsUpdate = lib.any 
    (cfg: cfg.enable && cfg.ociContainer != null && cfg.ociContainer.enable && cfg.ociContainer.updateScript != null) 
    (lib.attrValues config.myWebsites);
in
{
  config = {
    # 创建数据库脚本
    system.activationScripts."create-container-scripts" = let
      containerScripts = lib.mapAttrsToList
        (websiteName: cfg:
          let container = cfg.ociContainer; in
          lib.optionalString (cfg.enable && container != null && container.enable) ''
            ${lib.optionalString (container.initScript != null) ''
              echo "Creating init script for ${websiteName}"
              mkdir -p /etc/podman-init-scripts
              cat > "/etc/podman-init-scripts/${domainToUnit cfg.domain}-init.sql" << 'EOF'
${container.initScript}
EOF
              chmod 644 "/etc/podman-init-scripts/${domainToUnit cfg.domain}-init.sql"
            ''}
            ${lib.optionalString (container.updateScript != null) ''
              echo "Creating update script for ${websiteName}"
              mkdir -p /etc/podman-update-scripts
              cat > "/etc/podman-update-scripts/${domainToUnit cfg.domain}-update.sql" << 'EOF'
${container.updateScript}
EOF
              chmod 644 "/etc/podman-update-scripts/${domainToUnit cfg.domain}-update.sql"
            ''}
          ''
        )
        config.myWebsites;
    in
      lib.strings.concatStringsSep "\n" containerScripts;

    # 数据库服务
    systemd.services = 
      let
        # 数据库初始化服务
        dbInitServices = lib.mapAttrs'
          (websiteName: websiteCfg:
            let 
              container = websiteCfg.ociContainer;
              containerName = domainToUnit websiteCfg.domain;
              serviceName = "db-init-${containerName}";
            in
            lib.nameValuePair serviceName (mkIf (websiteCfg.enable && container != null && container.enable && container.initScript != null) {
              description = "Initialize database for ${websiteName}";
              after = [ "podman.service" "podman-${containerName}.service" ];
              requires = [ "podman.service" "podman-${containerName}.service" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              script = let
                dbConfig = container.dbConfig;
                password = if dbConfig != null then dbConfig.rootPassword else "rootpassword123";
                host = if dbConfig != null then dbConfig.host else "localhost";
                user = if dbConfig != null && dbConfig.username != null then dbConfig.username else "root";
                db = if dbConfig != null && dbConfig.database != null then dbConfig.database else "";
              in ''
                echo "Running database initialization script for ${containerName}"
                
                # 等待数据库服务完全启动
                for i in {1..60}; do
                  if ${pkgs.podman}/bin/podman exec ${containerName} mysqladmin ping -h ${host} -u ${user} -p"${password}" --silent 2>/dev/null; then
                    echo "Database is ready, running initialization script..."
                    
                    # 如果有指定数据库，先创建
                    ${lib.optionalString (db != "") ''
                      echo "Creating database ${db} if not exists"
                      ${pkgs.podman}/bin/podman exec ${containerName} mysql -h ${host} -u ${user} -p"${password}" -e "CREATE DATABASE IF NOT EXISTS ${db};"
                    ''}
                    
                    # 执行初始化脚本
                    cat /etc/podman-init-scripts/${containerName}-init.sql | ${pkgs.podman}/bin/podman exec -i ${containerName} mysql -h ${host} -u ${user} -p"${password}" ${db}
                    
                    echo "Initialization script completed successfully"
                    exit 0
                  else
                    echo "Waiting for database to be ready... (attempt $i/60)"
                    sleep 2
                  fi
                done
                
                echo "ERROR: Database did not become ready in time"
                exit 1
              '';
              wantedBy = [ "multi-user.target" ];
              unitConfig = {
                ConditionPathExists = "/etc/podman-init-scripts/${containerName}-init.sql";
              };
            })
          )
          config.myWebsites;

        # 数据库更新服务
        dbUpdateServices = lib.mapAttrs'
          (websiteName: websiteCfg:
            let 
              container = websiteCfg.ociContainer;
              containerName = domainToUnit websiteCfg.domain;
              serviceName = "db-update-${containerName}";
            in
            lib.nameValuePair serviceName (mkIf (websiteCfg.enable && container != null && container.enable && container.updateScript != null) {
              description = "Update database schema for ${websiteName}";
              after = [ "podman.service" "podman-${containerName}.service" "db-init-${containerName}.service" ];
              requires = [ "podman.service" "podman-${containerName}.service" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              script = let
                dbConfig = container.dbConfig;
                password = if dbConfig != null then dbConfig.rootPassword else "rootpassword123";
                host = if dbConfig != null then dbConfig.host else "localhost";
                user = if dbConfig != null && dbConfig.username != null then dbConfig.username else "root";
                db = if dbConfig != null && dbConfig.database != null then dbConfig.database else "";
              in ''
                echo "Running database update script for ${containerName}"
                
                # 等待数据库服务完全启动
                for i in {1..30}; do
                  if ${pkgs.podman}/bin/podman exec ${containerName} mysqladmin ping -h ${host} -u ${user} -p"${password}" --silent 2>/dev/null; then
                    echo "Database is ready, running update script..."
                    
                    # 执行更新脚本
                    cat /etc/podman-update-scripts/${containerName}-update.sql | ${pkgs.podman}/bin/podman exec -i ${containerName} mysql -h ${host} -u ${user} -p"${password}" ${db}
                    
                    echo "Update script completed successfully"
                    exit 0
                  else
                    echo "Waiting for database to be ready... (attempt $i/30)"
                    sleep 2
                  fi
                done
                
                echo "ERROR: Database did not become ready in time"
                exit 1
              '';
              wantedBy = [ "multi-user.target" ];
              unitConfig = {
                ConditionPathExists = "/etc/podman-update-scripts/${containerName}-update.sql";
              };
            })
          )
          config.myWebsites;

        # 数据库服务协调器
        dbCoordinator = {
          "db-init-all" = mkIf (lib.any (cfg: cfg.enable && cfg.ociContainer != null && cfg.ociContainer.enable && cfg.ociContainer.initScript != null) (lib.attrValues config.myWebsites)) {
            description = "Run all database initialization scripts";
            after = [ "systemd-activate.service" ];
            before = [ "multi-user.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig.type = "oneshot";
            script = ":";
          };
          
          "db-update-all" = mkIf anyContainerNeedsUpdate {
            description = "Run all database update scripts";
            after = [ "systemd-activate.service" "db-init-all.service" ];
            before = [ "multi-user.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig.type = "oneshot";
            script = ":";
          };
        };

      in
        dbInitServices // dbUpdateServices // dbCoordinator;
  };
}