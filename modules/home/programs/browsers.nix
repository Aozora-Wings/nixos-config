{ pkgs
, config
, ...
}:
let

in {
  programs = {
    chromium = {
      enable = true;
      commandLineArgs = [ "--enable-features=TouchpadOverscrollHistoryNavigation" ];
      extensions = [
        # {id = "";}  // extension id, query from chrome web store
      ];
    };

    # firefox = {
    #   enable = true;
    #   package = pkgs.firefox.overrideAttrs (old: {
    #     buildInputs = old.buildInputs ++ [ pkgs.ffmpeg pkgs.libva ];
    #     NIX_CFLAGS_COMPILE = "-DENABLE_VAAPI=1";
    #   });
    # };
  };
}
