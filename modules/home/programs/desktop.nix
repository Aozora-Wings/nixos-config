{ config, lib, pkgs, install-config, stable,unstable, ... }:

let
  mkDesktopIcon = name: exec: icon: categories: {
    "Desktop/${name}.desktop" = {
      text = ''
        [Desktop Entry]
        Version=1.0
        Name=${name}
        Exec=${exec}
        Icon=${icon}
        Type=Application
        Categories=${builtins.concatStringsSep ";" categories}
        Terminal=false
      '';
      executable = true;
    };
  };
  neteaseMusicElectron = pkgs.writeShellScriptBin "netease-music" ''
    # 创建一个简单的 Electron 应用来加载网页
    ${pkgs.electron}/bin/electron --app="${pkgs.writeText "netease-app.js" ''
      const { app, BrowserWindow } = require('electron');
      
      function createWindow() {
        const win = new BrowserWindow({
          width: 1200,
          height: 800,
          webPreferences: {
            nodeIntegration: false,
            contextIsolation: true
          }
        });
        
        win.loadURL('https://music.163.com/st/webplayer');
        win.setMenuBarVisibility(false);
      }
      
      app.whenReady().then(createWindow);
      app.on('window-all-closed', () => {
        if (process.platform !== 'darwin') app.quit();
      });
    ''}" "$@"
  '';

  # 桌面图标（总是启用）
  desktopIcons = lib.foldl (acc: elem: acc // elem) { } [
    (mkDesktopIcon "Obsidian" "obsidian %U" "${pkgs.obsidian}/share/icons/hicolor/256x256/apps/obsidian.png" [ "Office" ])
    (mkDesktopIcon "HMCL" "hmcl" "${pkgs.hmcl}/share/icons/hicolor/256x256/apps/hmcl.png" [ "Game" ])
    (mkDesktopIcon "QQ" "qq" "qq" [ "Network" "InstantMessaging" ])
    (mkDesktopIcon "Steam" "steam" "steam" [ "Game" ])
    (mkDesktopIcon "osu!" "env http_proxy=http://127.0.0.1:7897 https_proxy=http://127.0.0.1:7897 osu! %u" "osu!" [ "Game" ])
    (mkDesktopIcon "Firefox" "firefox" "firefox" [ "Network" "WebBrowser" ])
    (mkDesktopIcon "115浏览器" "steam-run 115.sh" "${pkgs.pc115-my}/local/115Browser/res/115Browser.png" [ "Network" "WebBrowser" ])
    (mkDesktopIcon "RetroArch" "retroarch -f --verbose" "${unstable.retroarch-full}/share/pixmaps/com.libretro.RetroArch.svg" [ "Game" ])
    (mkDesktopIcon "Watt-Tools" "steam-run ${pkgs.SteamTools-my}/bin/watt-toolkit" "${pkgs.SteamTools-my}/bin/Icons/Watt-Toolkit.png" [ "Game" ])
   # 网易云音乐 - 使用 Electron 版本
    (mkDesktopIcon "网易云音乐" 
      "${neteaseMusicElectron}/bin/netease-music" 
      "music" 
      [ "Music" "AudioVideo" ])
  ];

  # Hyprland 配置（条件启用）

in
{
  home.file = desktopIcons;
  #home.file = desktopIcons // hyprlandFiles;
}
