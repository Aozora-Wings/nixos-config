{ pkgs
, ...
}: {
  home.packages = with pkgs; [
    carapace
    nushell
    nushellPlugins.formats
    nushellPlugins.highlight
    # nushellPlugins.net
    nushellPlugins.query
    # nushellPlugins.units
    # 其他用户级包...
  ];
  programs.nushell = {
    enable = true;
    configFile.source = ./config.nu;
    envFile.source = ./env.nu;
  };
}
