{ pkgs
, config
, ...
}: {
  # i3 配置，基于 https://github.com/endeavouros-team/endeavouros-i3wm-setup
  # 直接从当前文件夹中读取配置文件作为配置内容

  # wallpaper, binary file
  home.file.".config/i3".source = ./.;
  home.file.".config/i3".recursive = true;
  home.file.".config/i3/scripts" = {
    source = ./scripts;
    # copy the scripts directory recursively
    recursive = true;
    executable = true; # make all scripts executable
  };


  # set cursor size and dpi for 4k monitor
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 192;
  };

  # 直接以 text 的方式，在 nix 配置文件中硬编码文件内容
  # home.file.".xxx".text = ''
  #     xxx
  # '';
}
