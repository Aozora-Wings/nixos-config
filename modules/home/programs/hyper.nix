{ config, lib, pkgs, install-config, stable, ... }:
let
  cfg = install-config.hyprland;
  username = install-config.username;
  hyprlandConfigPath = ../../config/hyprland.conf;
  
  # 在这里定义要使用的包，确保它们在作用域内可用
  dolphin = pkgs.kdePackages.dolphin;
  xdg-hyprland = pkgs.xdg-desktop-portal-hyprland;
  xdg-gtk = pkgs.xdg-desktop-portal-gtk;
  zenity-pkg = pkgs.zenity;
in
{
  home.file.".config/xdg-desktop-portal/hyprland-portals.conf" = lib.mkIf cfg.enable {
    text = ''
      [preferred]
      # 使用 hyprland 的截图和屏幕录制
      org.freedesktop.impl.portal.Screenshot=hyprland
      org.freedesktop.impl.portal.ScreenCast=hyprland
      
      # 使用 GTK 的文件选择器和设置
      org.freedesktop.impl.portal.FileChooser=gtk
      org.freedesktop.impl.portal.Settings=gtk
      org.freedesktop.impl.portal.AppChooser=gtk
    '';
  };
  
  home.file."Pictures/Wallpapers" = lib.mkIf cfg.enable {
    source = install-config.wallpapers;
    recursive = true;
    force = true;
  };
  
  home.packages = lib.mkIf cfg.enable (with pkgs; [
    # 文件管理器
    kdePackages.dolphin
    
    # XDG/MIME 工具
    shared-mime-info
    xdg-utils
    xdg-user-dirs
    desktop-file-utils
    
    # 桌面门户
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    
    # GTK 对话框
    zenity
  
    # 桌面环境集成
    adwaita-icon-theme
    gnome-themes-extra
    
    # Rofi 主题和配置（可选）
    rofi
  ]);
  
  home.sessionVariables = lib.mkIf cfg.enable {
    # 必须设置这些让桌面门户知道我们用的是 Hyprland
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    
    # 更新 MIME 数据库的路径 - 确保包含系统路径
   # XDG_DATA_DIRS = "$HOME/.local/share:$HOME/.nix-profile/share:/run/current-system/sw/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
    
    # 添加 Rofi 环境变量
    #XDG_DATA_HOME = "$HOME/.local/share";
    #XDG_CONFIG_HOME = "$HOME/.config";
  };

  # 添加 XDG 配置
  xdg = lib.mkIf cfg.enable {
    enable = true;
    
    # 确保创建必要的用户目录
    userDirs = {
      enable = true;
      createDirectories = true;
    };
    
    # 配置 MIME 类型应用关联
    mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/bitwarden" = [ "bitwarden.desktop" ];
        "text/plain" = [ "code.desktop" ];
        "text/x-c" = [ "code.desktop" ];
        "text/x-c++" = [ "code.desktop" ];
        "text/x-python" = [ "code.desktop" ];
        "application/json" = [ "code.desktop" ];
      };
    };
  };

  # 创建 Rofi 配置文件
  home.file.".config/rofi/config.rasi" = lib.mkIf cfg.enable {
    text = ''
      configuration {
        modi: "drun,run,window";
        show-icons: true;
        icon-theme: "Adwaita";
        display-drun: "Applications";
        display-run: "Run";
        display-window: "Windows";
        drun-display-format: "{name}";
        window-format: "{w} · {c} · {t}";
      }
      
      @theme "default"
    '';
  };

  wayland.windowManager.hyprland = lib.mkIf cfg.enable {
    enable = true;
    settings = {
      # 显示器配置
      monitor = [
        "HDMI-A-1, 3440x1440@100, 0x80, 1,bitdepth,10"
        "eDP-1, 2560x1600@240, 3440x0, 1,bitdepth,10"
      ];

      # 环境变量
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "XIM,fcitx"
        "XIM_PROGRAM,fcitx"
        "INPUT_METHOD,fcitx"
        "GTK_IM_MODULE,fcitx"
        "QT_IM_MODULE,fcitx"
        "XMODIFIERS,@im=fcitx"
        # 添加 Rofi 环境变量
        "ROFI_THEME,~/.config/rofi/config.rasi"
      ];

      # 自动启动 - 修正版
      exec-once = [
  # 1. 首先设置环境变量
  "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_DATA_DIRS"
  
  # 2. 启动桌面门户
  "${xdg-hyprland}/libexec/xdg-desktop-portal-hyprland &"
  
  # 3. 等待片刻后启动 GTK 门户
  "sleep 1 && ${xdg-gtk}/libexec/xdg-desktop-portal-gtk &"
  
  # 4. 通知 DBus
  "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_DATA_DIRS"
  
  # 5. 只更新用户目录的数据库（Nix 系统目录是只读的）
  "sleep 2 && mkdir -p ~/.local/share/applications"
  "sleep 2 && update-desktop-database ~/.local/share/applications"
  "sleep 2 && update-mime-database ~/.local/share/mime"
  
  # 6. 创建桌面文件到用户目录的链接（正确的方法）
  "sleep 3 && find /run/current-system/sw/share/applications -name '*.desktop' -exec ln -sf {} ~/.local/share/applications/ \\; 2>/dev/null || true"
  "sleep 3 && find ~/.nix-profile/share/applications -name '*.desktop' -exec ln -sf {} ~/.local/share/applications/ \\; 2>/dev/null || true"
  
  # 7. 使用桌面文件索引工具扫描所有路径
  "sleep 4 && ${pkgs.gnome-menus}/libexec/gmenu-dbus-menu-proxy &"
  
  # 8. 其他应用
  "kwalletd6"
  "waybar"
  "fcitx5"
  "hyprpaper"
  "swww-daemon --format xrgb"
  "sleep 5 && swww img ~/Pictures/Wallpapers/$(ls ~/Pictures/Wallpapers | shuf -n 1) --transition-type random"
  "bash -c 'sleep 7 && numlockx on'"
  "hyprland-mpris"
  "clash-verge"
      ];

      # 外观设置
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # 输入设置
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad.natural_scroll = false;
        force_no_accel = 1;
      };

      # 快捷键绑定 - 使用完整路径调用 rofi
      bind = [
        "CTRL ALT, T, exec, $terminal"
        "$mainMod, C, killactive,"
        "$mainMod, B, exec, rofi-rbw"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating,"
        "$mainMod, R, exec, $menu"
        "$mainMod, P, pseudo," # dwindle
        "$mainMod, J, togglesplit," # dwindle
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
        "CTRL ALT, a, exec, ''grim -g \"$(slurp)\" - | xclip -selection clipboard -t image/png''"
        "SUPER SHIFT, L, exit, "
        # 修改这里：使用完整路径并添加主题
        "SUPER, D, exec, ${pkgs.rofi}/bin/rofi -show drun -theme ~/.config/rofi/config.rasi"
        "SUPER, Tab, exec, ${pkgs.rofi}/bin/rofi -show window -theme ~/.config/rofi/config.rasi"
        "SUPER SHIFT, L, exit,"
      ];
      
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # 变量定义
      "$terminal" = "konsole";
      "$fileManager" = "dolphin";
      "$menu" = "${pkgs.rofi}/bin/rofi -show drun";
      "$mainMod" = "SUPER";

      # 窗口规则
      windowrulev2 = [
        "suppressevent maximize, class:.*"
        "stayfocused, title:^rofi$"
        "nofocus, title:^rofi$" # 防止焦点丢失
      ];
    };
  };
}