# ~/.config/nushell/config.nu

# 检查是否是交互式TTY会话
let is_interactive = (try { (tty | str length) > 0 } catch { false })

if $is_interactive {
    # ========== 只在交互式TTY模式下加载 ==========
    
    # 欢迎信息（只在交互式模式下显示）
    $env.config.show_banner = true

    # Starship 提示符（只在交互式模式下加载）
    mkdir ~/.cache/starship
    starship init nu | save -f ~/.cache/starship/init.nu
    source ~/.cache/starship/init.nu
    
    # Carapace 补全（只在交互式模式下加载）
    carapace _carapace nushell | save -f ~/.cache/carapace.nu
    source ~/.cache/carapace.nu
    
    # 自定义命令（交互式模式下可用）
    def urldecode [] {
        python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'
    }

    def urlencode [] {
        python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'
    }
}

# ========== 所有模式下都加载 ==========

# 简单别名（基础功能，所有模式都可用）
alias k = kubectl
alias nixdr = ^nix-store --add
alias ll = ls -l

# 带环境变量的别名（所有模式都可用）
alias nixup = ^https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897 nix flake update
alias nhsw = ^nh os switch --impure --accept-flake-config