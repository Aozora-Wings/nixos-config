#!/bin/sh
export run_type=install
#https_proxy="http://127.0.0.1:8443"
#https_proxy="http://192.168.1.243:7890"
#export ALL_PROXY=socks5://192.168.1.243:1080
sudo run_type="install" nixos-install --flake $1 --impure --show-trace #--option substituters "https://mirror.sjtu.edu.cn/nix-channels/store"