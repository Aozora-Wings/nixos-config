{ pkgs, inputs, ... }: {
  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default 
    # ... 可能还有其他软件包
  ];
}
