{ pkgs
, config
, stable
, ...
}:
# media - control and enjoy audio/video

{
  # imports = [
  # ];

  home.packages = with pkgs; [
    # audio control
    pavucontrol
    playerctl
    pulsemixer
    # images
    imv
    stable.cantata
  ];

  programs = {
    mpv = {
      enable = true;
      package = (pkgs.mpv.override {
        extraMakeWrapperArgs = [
          # 添加 Anime4K 着色器
          "--add-flags"
          "--glsl-shaders=${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_VL.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"
          # 添加 HDR/Vulkan 参数
          "--add-flags"
          "--vo=gpu-next"
          "--add-flags"
          "--target-colorspace-hint"
          "--add-flags"
          "--gpu-api=vulkan"
        ];
      });
      config = {
        profile = "gpu-hq";
      };
    };

    obs-studio.enable = true;
  };

  services = {
    playerctld.enable = true;
  };
}
