{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.clouddrive2;
in
{
  options.services.clouddrive2 = {
    enable = mkEnableOption "CloudDrive2 service";

    user = mkOption {
      type = types.str;
      default = "clouddrive";
      description = "User to run CloudDrive2 as";
    };

    group = mkOption {
      type = types.str;
      default = "clouddrive";
      description = "Group to run CloudDrive2 as";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/clouddrive2";
      description = "Data directory for CloudDrive2";
    };

    mountPoints = mkOption {
      type = types.listOf types.str;
      default = "/cloud";
      description = "Mount point for CloudDrive2";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra command line arguments";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.clouddrive2 ];

    # FUSE 配置
    security.polkit.enable = true;

    # 用户和组配置
    users.users."${cfg.user}" = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      extraGroups = [ "fuse" ]; # 添加到 fuse 组
    };

    users.groups."${cfg.group}" = { };

    # 创建挂载点目录
    # system.activationScripts.clouddrive2-mountpoint = ''
    #   mkdir -p ${cfg.mountPoint}
    #   chown ${cfg.user}:${cfg.group} ${cfg.mountPoint}
    # '';

    systemd.services.clouddrive2 = {
      description = "CloudDrive2 Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.clouddrive2}/bin/clouddrive ${escapeShellArgs cfg.extraArgs}";
        ExecStop =
          let
            cleanupScript = pkgs.writeShellScript "clouddrive-cleanup" ''
              echo "Cleaning up CloudDrive2 mount points..."
    
              # 从配置的 mountPoints 获取挂载点列表
              mount_points=(${toString cfg.mountPoints})
    
              # 直接卸载挂载点，而不是挂载点下的内容
              for mount_point in "''${mount_points[@]}"; do
                if ${pkgs.util-linux}/bin/mountpoint -q "$mount_point"; then
                  echo "Unmounting: $mount_point"
                  ${pkgs.util-linux}/bin/umount -f "$mount_point" 2>/dev/null || true
                  ${pkgs.fuse}/bin/fusermount -uz "$mount_point" 2>/dev/null || true
                fi
              done
    
              # 额外检查：使用 mount 命令查找任何残留的 CloudFS 挂载
              ${pkgs.util-linux}/bin/mount | ${pkgs.gnugrep}/bin/grep "CloudFS on /cloud/" | ${pkgs.gawk}/bin/awk '{print $3}' | while read mount_point; do
                echo "Unmounting found mount: $mount_point"
                ${pkgs.util-linux}/bin/umount -f "$mount_point" 2>/dev/null || true
                ${pkgs.fuse}/bin/fusermount -uz "$mount_point" 2>/dev/null || true
              done
    
              ${pkgs.coreutils}/bin/sleep 2
              echo "Cleanup completed"
            '';
          in
          "${cleanupScript}";
        ExecStopPost = "${pkgs.coreutils}/bin/sleep 2";
        Restart = "always";
        RestartSec = 5;
        User = "root"; # 直接使用 root
        Group = "root";
        WorkingDirectory = cfg.dataDir;

        # 即使使用 root 也禁用安全限制
        NoNewPrivileges = false;
        PrivateTmp = false;
        PrivateDevices = false;
      };
    };
  };
}
