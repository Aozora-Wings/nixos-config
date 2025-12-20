# config.nix
let def_ports = import ./def_ports.nix; in {
  root = "/developer/nixos-config";
  def_ports = import ./def_ports.nix;
  username = "wt";
  hostname = "aozorawings";
  useremail = "wt@qkzy.net";
  # hardwarefiles = "/etc/nixos/hardware-configuration.nix";
  openssh.publicKey = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBet/ZjyZr+kd/s6n19qchrG8KRh/Cn5POw61ARtzjMQ cardno:30_648_554"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4CbVAFZzd88MZkmGV6n/AJNBYrlluiVGKq8zCtH9hUJBhpu5b5gotVU92saYGZQaOs+nMYneBdn67MZqW9oFsIboPNvpKSPEUyPIATi9z+zRVKZ0GwLTEJbU72WIXoY0Q7f7Jb5iOB2cW7G/DX8fo9YmVGr/5KgEICQoz+AYUdLfziZn2fZVDouaQUXuIClSY+lDWIOGJmkk/1PE4dhOtG9oWku6E8IZXkWgVlxxzy2JeS5YaVGl2cI4bD75S1G/cZ46QaWahii9Lf+6ieLoS74i+dCmg5d4EnvULUGheHMtJYpYcKujA3/FOSTkD0aTuUKNrhvU6tE325SIRDSdH cardno:30_648_554"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM2RIXbYQVSE11LdMIP1YAIAeG3gQP8KcW5SNZFmS7py vw_wt"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1Et/mGh7yyG600rQAdNAkxFfcdOfQiOQjmcM7WHbGmYvcXI6xVN41EBzYvmkHT7z3VH0xJR9iTHKPMp6Gt/MroL79JniG6YvxCqzoO4becE9FgPMCYjCooQBEaEkPrFABxNmU4Gb7jb5nu4T6jYe8uijY6Lx1BGRjnJ1OvEgeEb72VxP1zyp+aUSSKI9GB5BzF6kELIB1VQjqp6aerrevSj047KGgP7RkADJp7Y89jANaNcwX2rPpjyMiqehmA7Lf77imGmQljqMj1JOc+5xsy2mhfaZBq9UDpJ+bvElqkwTi9rZD2Wh2nfSgDhvcWQAn1kFwFNBnFEBCjia2XJMxFNCZ8HwKYguJyKynNPYN1aOJBQM5aYTnHzK/whCDAIKnaT4sTqDJ/n9k9gcNp5YnujgdsUiEPLh/lJeO+BQLRVa93H33eLmrCHZGOWXSQqFZRT5YPaedV1mdx7pngd1P/hMC9hOzmbwtBlTnJpVqzofOCPUIYK25Hp4ZrmU/01PeZUXkMx6UoxrQBXjFyudKum4UvaGgq7AjaE8DObXUzWEjhApU3hJ9zkT5ZrUZIS0m28bEHOgrBPDycc8Lr5aV4M5gtBFEozQZ0x4fmoH/9+ecSzwA0zTFPbf/4n2GRtOc8VRzqDVLPOKzYfbKZQXWpHIDSyytB5mviRu+TJwc2w== wt@qkzy.net"
  ];
  security = {
    pam = {
      enable = true;
      mode = "challenge-response";
      id = "30648554";
      debug = false;
      challengeResponsePath = "/home/.yubico";
      control = "sufficient";
    };
    pki = {
      certificates = [
        ''
          SteamCommunity302
          =================
          -----BEGIN CERTIFICATE-----
          MIIJZjCCCE6gAwIBAgIJAKtnL2IMMiZPMA0GCSqGSIb3DQEBCwUAMGwxCzAJBgNV
          BAYTAkNOMQswCQYDVQQIDAJYWDELMAkGA1UEBwwCWFgxGjAYBgNVBAoMEVN0ZWFt
          Y29tbXVuaXR5MzAyMQswCQYDVQQLDAJYWDEaMBgGA1UEAwwRU3RlYW1jb21tdW5p
          dHkzMDIwHhcNMjQwNjEwMDEwMTQ0WhcNMzQwNjA4MDEwMTQ0WjBsMQswCQYDVQQG
          EwJDTjELMAkGA1UECAwCWFgxCzAJBgNVBAcMAlhYMRowGAYDVQQKDBFTdGVhbWNv
          bW11bml0eTMwMjELMAkGA1UECwwCWFgxGjAYBgNVBAMMEVN0ZWFtY29tbXVuaXR5
          MzAyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7qTrOFyheGaqxEWI
          tjm0mVujWNJsBK3nFYQ0yMJEBZ3dhlq6kACE0gEdPNVWaaaPQiiE845O/HTAWdUT
          np1Wi/m1L9UkMetXvD0XbX1Q5HFm5ijFkj1sw2V19gxeJ7rZo2zuKICK7YGzdga8
          Bm4YB+NikHjMD+SPwePVGIeXSRjhNkp2WbOopHIinku8u7vP8ySR6pjP17olEWY7
          lnz93IvvIGSxshnzAYNTm8rIU/k80PuO2pdTl9/0lhPS7QvdEiBTeNpPn2xWYyNI
          /riS7Bix/XpGyuGVsFRAgD6LFQYfgO3aTuKHekZCxIk9+b9NzbSNYq/vcYNrG2Na
          TJwhjwIDAQABo4IGCTCCBgUwHQYDVR0OBBYEFLso13uSRp+6co+FS1olChyg2tUJ
          MB8GA1UdIwQYMBaAFH52/Tdc8IFF/jHOWNtFjLM4JWbKMAsGA1UdDwQEAwIEsDCC
          BZUGA1UdEQSCBYwwggWIghJzdGVhbWNvbW11bml0eS5jb22CFCouc3RlYW1jb21t
          dW5pdHkuY29tggl0d2l0Y2gudHaCDXd3dy50d2l0Y2gudHaCCyoudHdpdGNoLnR2
          ghAqLmNoYXQudHdpdGNoLnR2ghwqLnVwbG9hZHMtcmVnaW9uYWwudHdpdGNoLnR2
          ghAqLmhlbHAudHdpdGNoLnR2gg8qLmRldi50d2l0Y2gudHaCECouY2hhdC50d2l0
          Y2gudHaCD3VzaGVyLnR0dm53Lm5ldIIOZGlzY29yZGFwcC5jb22CECouZGlzY29y
          ZGFwcC5jb22CECouZGlzY29yZGFwcC5uZXSCDCouZGlzY29yZC5nZ4ISKi5zdGVh
          bXBvd2VyZWQuY29tghIqLnMzLmFtYXpvbmF3cy5jb22CDiouYWthbWFpaGQubmV0
          gg0qLmNkbi51YmkuY29tgg53d3cuZ29vZ2xlLmNvbYIOc3RlYW0tY2hhdC5jb22C
          GCouYWthbWFpLnN0ZWFtc3RhdGljLmNvbYILZGlzY29yZC5jb22CDSouZGlzY29y
          ZC5jb22CBm1vZC5pb4IIKi5tb2QuaW+CCyouaW1naXgubmV0ggpnaXRodWIuY29t
          ggwqLmdpdGh1Yi5jb22CFyouZ2l0aHVidXNlcmNvbnRlbnQuY29tghIqLmdpdGh1
          YmFzc2V0cy5jb22CCyouZ2l0aHViLmlvgglnaXRodWIuaW+CDyoubTdnLnR3aXRj
          aC50doIRKi5zLW1pY3Jvc29mdC5jb22CDioueGJveGxpdmUuY29tggwqLm9yaWdp
          bi5jb22CEW9uZWRyaXZlLmxpdmUuY29tghhza3lhcGkub25lZHJpdmUubGl2ZS5j
          b22CFCoud2lraWEubm9jb29raWUubmV0ghkqLnBkeDAxLmFicy5obHMudHR2bncu
          bmV0gg5ibG9ja2JlbmNoLm5ldIIQKi5ibG9ja2JlbmNoLm5ldIIVKi5jbS5zdGVh
          bXBvd2VyZWQuY29tgg4qLmpzZGVsaXZyLm5ldIIPKi5sZ2UubW9kY2RuLmlvghEq
          LnN0ZWFtc2VydmVyLm5ldIIMKi5vbGQubW9kLmlvgg93d3cueW91dHViZS5jb22C
          HSouZ3Nzdi1wbGF5LXByb2QueGJveGxpdmUuY29tgiIqLmNvcmUuZ3Nzdi1wbGF5
          LXByb2QueGJveGxpdmUuY29tghMqLmF1dGgueGJveGxpdmUuY29tghEqLnN0ZWFt
          c3RhdGljLmNvbYIcKi5jbG91ZGZsYXJlLnN0ZWFtc3RhdGljLmNvbYIPKi5ha2Ft
          YWl6ZWQubmV0ggpkaXNjb3JkLmdngg5hcnRzdGF0aW9uLmNvbYIQKi5hcnRzdGF0
          aW9uLmNvbYIPKi5waW50ZXJlc3QuY29tggwqLnBpbmltZy5jb22CECoucGludGVy
          ZXN0LmluZm+CDioucGludGVyZXN0Lmpwgg4qLnBpbnRlcmVzdC5rcoIGcGluLml0
          gg1waW50ZXJlc3QuY29tggpwaW5pbWcuY29tgg5waW50ZXJlc3QuaW5mb4IMcGlu
          dGVyZXN0LmpwggxwaW50ZXJlc3Qua3KCCWltZ3VyLmNvbYILKi5pbWd1ci5jb22C
          ESouc3RhY2suaW1ndXIuY29tghgqLnN0b3JhZ2UuZ29vZ2xlYXBpcy5jb22CECou
          Z29vZ2xlYXBpcy5jb22CDCoubW9qYW5nLmNvbYIPKi5taW5lY3JhZnQubmV0ghcq
          Lm1pbmVjcmFmdHNlcnZpY2VzLmNvbYINbWluZWNyYWZ0Lm5ldIIWKi5yZWFsbXMu
          bWluZWNyYWZ0Lm5ldIIYKi5kb3dubG9hZC5taW5lY3JhZnQubmV0MB0GA1UdJQQW
          MBQGCCsGAQUFBwMBBggrBgEFBQcDAjANBgkqhkiG9w0BAQsFAAOCAQEAFwY5bvnV
          eiBciS+hsE2wZX+WopYc77fTpUqCcNsDX1/9qHlg9dALHSIjA0aKeL46v4a0enph
          ap2t4MGrQ0SZvmvxUGp+e03XjRg5c6DhQxiouiwmRHilY36yFsCdeesN6w25IdoF
          5CeACMTG4lRtq+1H4g/LTl/oW4OhDz5ZWkuq+bXr+OKDMsAhg5PbTQnZRaM/0fr1
          u9X2a87sbo4xiQvenJfQi+TxyVc5/PIZRvya+DNTbWtDRNPzpuPPzXzSFztGIhEv
          znrhus5CcVwSnRzpKABcQTMHbahfoDvRBOdJ+CuB2TlkvvU60k2Ot1jlFZVXvxqS
          R2Lp4VsvF0PYiA==
          -----END CERTIFICATE-----
        ''
      ];
    };
  };
  hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  niri = {
    enable = true;
  };
  mpd = {
    enable = true;
    startWhenNeeded = true;
    user = "mpd";
    group = "audio";
    dataDir = "/home/public/mpd";
    
    # 启用防火墙端口
    openFirewall = true;
    
    # 所有配置现在都在 settings 中
    settings = {
      music_directory = "/create/115open/音乐/";
      playlist_directory = "/home/public/mpd/Playlists";
      db_file = "/home/public/mpd/mpd.db";
      filesystem_charset = "UTF-8";
      log_file = "/home/public/mpd/log";
      
      # 网络配置
      bind_to_address = "0.0.0.0";  # 原先是 "any"，建议使用具体的地址
      port = def_ports.mpd.api;
      
      # 音频输出配置
      audio_output = [
        {
          type = "alsa";
          name = "Shan Ling H5 Pro";
          device = "hw:CARD=H5,DEV=0";
          mixer_type = "hardware";
          auto_resample = "no";
          auto_channels = "no";
          auto_format = "no";
          dop = "yes";
        }
        {
          type = "httpd";
          name = "HTTP Streams";
          always_on = "yes";
          encoder = "flac";
          oggchaining = "yes";
          compression = "5";
          port = "${def_ports.mpd.http}";
          bind_to_address = "0.0.0.0";
          max_clients = "0";
        }
      ];
    };
  };
  starship = {
    enable = true;
    enableBashIntegration = true;
    # 自定义配置
    settings = {
      custom = {
        command_timeout = 2000;
      };
      format = "[](#4EAC69)" +
        "$os" +
        "$hostname" +
        "[](bg:#9A348E fg:#4EAC69)" +
        "$username" +
        "[](bg:#DA627D fg:#9A348E)" +
        "$directory" +
        "[](fg:#DA627D bg:#FCA17D)" +
        "$git_branch" +
        "$git_status" +
        "[](fg:#FCA17D bg:#86BBD8)" +
        "$nix_shell" +
        "$c" +
        "$elixir" +
        "$elm" +
        "$golang" +
        "$gradle" +
        "$haskell" +
        "$java" +
        "$julia" +
        "$nodejs" +
        "$nim" +
        "$rust" +
        "$scala" +
        "[](fg:#86BBD8 bg:#06969A)" +
        "$docker_context" +
        "[](fg:#06969A bg:#33658A)" +
        "$time" +
        "[ ](fg:#33658A)" +
        "$cmd_duration" +
        "$line_break" +
        "$character";
      # Disable the blank line at the start of the prompt
      # add_newline = false

      # You can also replace your username with a neat symbol like   or disable this
      # and use the os module below

      os = {
        #format = "[ $symbols ]($style)";
        style = "bg:#4EAC69";
        disabled = false;
      };
      os.symbols = {
        "NixOS" = " ";
      };
      hostname = {
        ssh_only = false;
        style = "bg:#4EAC69";
        format = "[ $hostname ]($style)";
        disabled = false;
      };
      username = {
        show_always = true;
        style_user = "bg:#9A348E";
        style_root = "bg:#9A348E";
        format = "[ $user ]($style)";
        disabled = false;
      };
      # An alternative to the username module which displays a symbol that
      # represents the current operating system
      # my_symbol = {
      # style = "bg:#9A348E";
      # symbol = " ";
      # format = "[ $symbol ]($style)";
      # disabled = false; # Disabled by default
      # };
      directory = {
        style = "bg:#DA627D";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
      };
      # Here is how you can shorten some long paths by text replacement
      # similar to mapped_locations in Oh My Posh:
      directory.substitutions = {
        "Documents" = "󰈙 ";
        "Downloads" = " ";
        "Music" = " ";
        "Pictures" = " ";
        # Keep in mind that the order matters. For example:
        # "Important Documents" = " 󰈙 "
        # will not be replaced, because "Documents" was already substituted before.
        # So either put "Important Documents" before "Documents" or use the substituted version:
        # "Important 󰈙 " = " 󰈙 "
      };

      nix_shell = {
        disabled = false;
        format = "[ $name - $state |]($style)";
        style = "bg:#86BBD8";
        impure_msg = "impure";
        pure_msg = "pure";
      };
      c = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      docker_context = {
        symbol = " ";
        style = "bg:#06969A";
        format = "[ $symbol $context ]($style)";
      };

      elixir = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      elm = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      git_branch = {
        symbol = "";
        style = "bg:#FCA17D";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:#FCA17D";
        format = "[ $all_status$ahead_behind ]($style)";
      };

      golang = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      gradle = {
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      haskell = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      julia = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      nim = {
        symbol = "󰆥 ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      scala = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) |]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R"; # Hour:Minute Format
        style = "bg:#33658A";
        format = "[ ♥ $time ]($style)";
      };
      cmd_duration = {
        show_milliseconds = true;
        format = " in $duration ";
        style = "bg:lavender";
        disabled = false;
        show_notifications = true;
        min_time_to_notify = 45000;
      };
      character = {
        disabled = false;
        success_symbol = "[❯](bold fg:green)";
        error_symbol = "[❯](bold fg:red)";
        vimcmd_symbol = "[❮](bold fg:green)";
        vimcmd_replace_one_symbol = "[❮](bold fg:lavender)";
        vimcmd_replace_symbol = "[❮](bold fg:lavender)";
        vimcmd_visual_symbol = "[❮](bold fg:yellow)";
      };


      add_newline = true;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };
  boot.extraEntries = ''
    menuentry "Windows Loader" {
      search --file --no-floppy --set=root /EFI/Microsoft/Boot/bootmgfw.efi
      chainloader (''${root})/EFI/Microsoft/Boot/bootmgfw.efi
      }
            menuentry "Arch Linux" {
            insmod part_gpt
            insmod btrfs
            insmod ext2
            insmod fat
        
            # 设置根设备为 SATA 硬盘的 Arch 子卷
            search --no-floppy --fs-uuid --set=archroot 8b2675c3-41a0-45cd-91f4-4c9f818a3458
        
            # 设置 boot 设备为 NVMe 分区
            search --no-floppy --fs-uuid --set=bootroot 0B0C-B4BE
        
            # 告诉内核根文件系统在哪里
            linux (bootroot)/vmlinuz-linux root=UUID=8b2675c3-41a0-45cd-91f4-4c9f818a3458 rw rootflags=subvol=ArchLinux quiet
            initrd (bootroot)/initramfs-linux.img
          }
  '';
  #设定显示大小
  display = {
    size = "16";
    dpi = "188";
  };
  hosts = {
    # "127.0.0.1" = [
    #   "localhost.ptlogin2.qq.com"
    #   "steamcommunity.com"
    #   "www.steamcommunity.com"
    #   "store.steampowered.com"
    #   "checkout.steampowered.com"
    #   "api.steampowered.com"
    #   "help.steampowered.com"
    #   "login.steampowered.com"
    #   "store.akamai.steamstatic.com"
    #   ];
  };
  docker.httpProxy = "http://127.0.0.1:7897";
  docker.httpsProxy = "http://127.0.0.1:7897";
  openvscode.connectionToken = "d2b3f8c0-4e1f-4b6a-7c8e9f0a1b2c-9c5d";
  code-server.password = "$argon2i$v=19$m=4096,t=3,p=1$K1prRnA5SEJLU2IyUUs1YmR1aEVLWHVmQmxrPQ$3Q8U7jVxPzp7C3RxQKRAdSl5svLU7+oqAqhb/sVSuys";
  wallpapers = ./Wallpapers;
  aria2Secret = "TNwAtiN5qBQ5SiuDZZQEvCQALA1Ss5FJ/dyiqYXDmqs=";
  XiaoYa.config = {
    path="/server/xiaoya";
    AliCloud = {
      Refresh_Token="";
      Open_Token="";
      temp_transfer_folder_id="";
    };
  pikpak = "";
  P115 = {
    cookie="";
    ali2115="";
    share_list_115="";
  };
  quark_cookie="";
  uc_cookie="";
  pikpakshare_list="";
  quarkshare_list="";
  };
}
