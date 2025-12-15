#!/usr/bin/env bash

# 从环境变量或默认值获取配置目录
CONFIG_DIR="${CONFIG_DIR:-/etc/xiaoya}"

# 小雅账号管理脚本
echo "小雅账号管理工具"
echo "=================="
echo "1) 配置115 Cookie (扫码/手动)"
echo "2) 配置夸克 Cookie (扫码/手动)"
echo "3) 配置阿里云盘 Refresh Token (扫码/手动)"
echo "4) 配置阿里云盘 Open Token (扫码/手动)"
echo "5) 配置UC Cookie (扫码/手动)"
echo "6) 配置PikPak账号 (手动)"
echo "7) 配置阿里转存115播放(ali2115.txt)"
echo "8) 配置阿里云盘转存目录ID (扫码/手动)"
echo "9) 扫码获取阿里云盘 Folder ID"
echo "0) 退出"
echo

read -p "请选择操作 (0-9): " choice

case $choice in
  1)
    echo "是否使用扫码获取115 Cookie? (y/n, 默认y):"
    read -r use_qrcode
    [ -z "$use_qrcode" ] && use_qrcode="y"
    if [ "$use_qrcode" = "y" ]; then
      echo "开始扫码获取115 Cookie..."
      podman run -i --rm \
        -v "$CONFIG_DIR:/data" \
        -e LANG=C.UTF-8 \
        -e QRCODE_SAVE_PATH="/data" \
        --userns=keep-id \
        --security-opt label=disable \
        ddsderek/xiaoya-glue:python \
        /115cookie/115cookie.py --qrcode_mode=shell
      if [ -f "$CONFIG_DIR/115_cookie.txt" ]; then
        echo "115 Cookie已通过扫码保存到 $CONFIG_DIR/115_cookie.txt"
      else
        echo "扫码获取失败，切换到手动输入模式"
        read -r cookie
        echo "$cookie" > $CONFIG_DIR/115_cookie.txt
        echo "115 Cookie已手动保存到 $CONFIG_DIR/115_cookie.txt"
      fi
    else
      echo "请输入115 Cookie:"
      read -r cookie
      echo "$cookie" > $CONFIG_DIR/115_cookie.txt
      echo "115 Cookie已保存到 $CONFIG_DIR/115_cookie.txt"
    fi
    ;;
  2)
    echo "是否使用扫码获取夸克 Cookie? (y/n, 默认y):"
    read -r use_qrcode
    [ -z "$use_qrcode" ] && use_qrcode="y"
    if [ "$use_qrcode" = "y" ]; then
      echo "开始扫码获取夸克 Cookie..."
      # 设备类型选择不适用于夸克 Cookie，直接运行扫码
      podman run -i --rm \
        -v "$CONFIG_DIR:/data" \
        -e LANG=C.UTF-8 \
        -e QRCODE_SAVE_PATH="/data" \
        --userns=keep-id \
        --security-opt label=disable \
        ddsderek/xiaoya-glue:python \
        /quark_cookie/quark_cookie.py --qrcode_mode=shell
      if [ -f "$CONFIG_DIR/quark_cookie.txt" ]; then
        echo "夸克 Cookie已通过扫码保存到 $CONFIG_DIR/quark_cookie.txt"
      else
        echo "扫码获取失败，切换到手动输入模式"
        read -r cookie
        echo "$cookie" > $CONFIG_DIR/quark_cookie.txt
        echo "夸克 Cookie已手动保存到 $CONFIG_DIR/quark_cookie.txt"
      fi
    else
      echo "请输入夸克 Cookie:"
      read -r cookie
      echo "$cookie" > $CONFIG_DIR/quark_cookie.txt
      echo "夸克 Cookie已保存到 $CONFIG_DIR/quark_cookie.txt"
    fi
    ;;
  3)
    echo "是否使用扫码获取阿里云盘 Refresh Token? (y/n, 默认y):"
    read -r use_qrcode
    [ -z "$use_qrcode" ] && use_qrcode="y"
    if [ "$use_qrcode" = "y" ]; then
      echo "开始扫码获取阿里云盘 Refresh Token..."
      podman run -i --rm \
        -v "$CONFIG_DIR:/data" \
        -e LANG=C.UTF-8 \
        -e QRCODE_SAVE_PATH="/data" \
        --userns=keep-id \
        --security-opt label=disable \
        ddsderek/xiaoya-glue:python \
        /aliyuntoken/aliyuntoken.py --qrcode_mode=shell --api_url=auth.xiaoya.pro
      if [ -f "$CONFIG_DIR/mytoken.txt" ]; then
        echo "阿里云盘 Refresh Token已通过扫码保存到 $CONFIG_DIR/mytoken.txt"
        # 验证token
        token_content=$(cat "$CONFIG_DIR/mytoken.txt" 2>/dev/null || echo "")
        if [ ${#token_content} -eq 32 ]; then
          echo "阿里云盘 Refresh Token验证成功"
        else
          echo "获取的Token不正确，请重新获取或手动输入"
        fi
      else
        echo "扫码获取失败，切换到手动输入模式"
        read -r token
        if [ ${#token} -eq 32 ]; then
          echo "$token" > $CONFIG_DIR/mytoken.txt
          echo "阿里云盘 Refresh Token已手动保存到 $CONFIG_DIR/mytoken.txt"
        else
          echo "错误：阿里云盘 Refresh Token应为32位"
        fi
      fi
    else
      echo "请输入阿里云盘 Refresh Token (32位):"
      read -r token
      if [ ${#token} -eq 32 ]; then
        echo "$token" > $CONFIG_DIR/mytoken.txt
        echo "阿里云盘 Refresh Token已保存到 $CONFIG_DIR/mytoken.txt"
      else
        echo "错误：阿里云盘 Refresh Token应为32位"
      fi
    fi
    ;;
  4)
    echo "是否使用扫码获取阿里云盘 Open Token? (y/n, 默认y):"
    read -r use_qrcode
    [ -z "$use_qrcode" ] && use_qrcode="y"
    if [ "$use_qrcode" = "y" ]; then
      echo "开始扫码获取阿里云盘 Open Token..."
      podman run -i --rm \
        -v "$CONFIG_DIR:/data" \
        -e LANG=C.UTF-8 \
        -e QRCODE_SAVE_PATH="/data" \
        --userns=keep-id \
        --security-opt label=disable \
        ddsderek/xiaoya-glue:python \
        /aliyunopentoken/aliyunopentoken.py --qrcode_mode=shell --api_url=auth.xiaoya.pro
      if [ -f "$CONFIG_DIR/myopentoken.txt" ]; then
        echo "阿里云盘 Open Token已通过扫码保存到 $CONFIG_DIR/myopentoken.txt"
        # 验证token
        token_content=$(cat "$CONFIG_DIR/myopentoken.txt" 2>/dev/null || echo "")
        token_len=${#token_content}
        if [ $token_len -eq 280 ] || [ $token_len -eq 335 ]; then
          echo "阿里云盘 Open Token验证成功"
        else
          echo "获取的Token长度不正确($token_len)，请重新获取或手动输入"
        fi
      else
        echo "扫码获取失败，切换到手动输入模式"
        read -r token
        if [ ${#token} -eq 280 ] || [ ${#token} -eq 335 ]; then
          echo "$token" > $CONFIG_DIR/myopentoken.txt
          echo "阿里云盘 Open Token已手动保存到 $CONFIG_DIR/myopentoken.txt"
        else
          echo "错误：阿里云盘 Open Token应为280位或335位"
        fi
      fi
    else
      echo "请输入阿里云盘 Open Token (280或335位):"
      read -r token
      if [ ${#token} -eq 280 ] || [ ${#token} -eq 335 ]; then
        echo "$token" > $CONFIG_DIR/myopentoken.txt
        echo "阿里云盘 Open Token已保存到 $CONFIG_DIR/myopentoken.txt"
      else
        echo "错误：阿里云盘 Open Token应为280位或335位"
      fi
    fi
    ;;
  5)
    echo "是否使用扫码获取UC Cookie? (y/n, 默认y):"
    read -r use_qrcode
    [ -z "$use_qrcode" ] && use_qrcode="y"
    if [ "$use_qrcode" = "y" ]; then
      echo "开始扫码获取UC Cookie..."
      podman run -i --rm \
        -v "$CONFIG_DIR:/data" \
        -e LANG=C.UTF-8 \
        -e QRCODE_SAVE_PATH="/data" \
        --userns=keep-id \
        --security-opt label=disable \
        ddsderek/xiaoya-glue:python \
        /uc_cookie/uc_cookie.py --qrcode_mode=shell
      if [ -f "$CONFIG_DIR/uc_cookie.txt" ]; then
        echo "UC Cookie已通过扫码保存到 $CONFIG_DIR/uc_cookie.txt"
      else
        echo "扫码获取失败，切换到手动输入模式"
        read -r cookie
        echo "$cookie" > $CONFIG_DIR/uc_cookie.txt
        echo "UC Cookie已手动保存到 $CONFIG_DIR/uc_cookie.txt"
      fi
    else
      echo "请输入UC Cookie:"
      read -r cookie
      echo "$cookie" > $CONFIG_DIR/uc_cookie.txt
      echo "UC Cookie已保存到 $CONFIG_DIR/uc_cookie.txt"
    fi
    ;;
  6)
    echo "请输入PikPak账号:"
    read -r username
    echo "请输入PikPak密码:"
    read -r password
    echo "请输入PikPak设备ID:"
    read -r device_id
    echo "$username" "$password" "web" "$device_id" > $CONFIG_DIR/pikpak.txt
    echo "PikPak账号已保存到 $CONFIG_DIR/pikpak.txt"
    ;;
  7)
    echo "是否启用自动删除115转存文件? (y/n, 默认y):"
    read -r purge_115
    [ -z "$purge_115" ] && purge_115="y"
    echo "是否启用自动删除阿里云盘转存文件? (y/n, 默认y):"
    read -r purge_ali
    [ -z "$purge_ali" ] && purge_ali="y"
    echo "请输入115转存文件夹ID (默认0):"
    read -r dir_id
    [ -z "$dir_id" ] && dir_id="0"
    
    if [ "$purge_115" = "y" ]; then
      purge_115_val="true"
    else
      purge_115_val="false"
    fi
    if [ "$purge_ali" = "y" ]; then
      purge_ali_val="true"
    else
      purge_ali_val="false"
    fi
    
    echo "purge_ali_temp=$purge_ali_val" > $CONFIG_DIR/ali2115.txt
    echo 'cookie=""' >> $CONFIG_DIR/ali2115.txt
    echo "purge_pan115_temp=$purge_115_val" >> $CONFIG_DIR/ali2115.txt
    echo "dir_id=$dir_id" >> $CONFIG_DIR/ali2115.txt
    echo "阿里转存115播放配置已保存到 $CONFIG_DIR/ali2115.txt"
    ;;
  8)
    echo "是否使用扫码获取阿里云盘转存目录ID? (y/n, 默认y):"
    read -r use_qrcode
    [ -z "$use_qrcode" ] && use_qrcode="y"
    if [ "$use_qrcode" = "y" ]; then
      echo "开始扫码获取阿里云盘转存目录ID..."
      podman run -i --rm \
        -v "$CONFIG_DIR:/data" \
        -e LANG=C.UTF-8 \
        --userns=keep-id \
        --security-opt label=disable \
        ddsderek/xiaoya-glue:python \
        /get_folder_id/get_folder_id.py --data_path='/data' --drive_mode=r
      if [ -f "$CONFIG_DIR/temp_transfer_folder_id.txt" ]; then
        folder_id=$(cat "$CONFIG_DIR/temp_transfer_folder_id.txt")
        if [ ${#folder_id} -eq 40 ]; then
          echo "阿里云盘转存目录ID已通过扫码保存到 $CONFIG_DIR/temp_transfer_folder_id.txt"
        else
          echo "获取的ID长度不正确，请重新获取或手动输入"
        fi
      else
        echo "扫码获取失败，切换到手动输入模式"
        read -r folder_id
        if [ ${#folder_id} -eq 40 ]; then
          echo "$folder_id" > $CONFIG_DIR/temp_transfer_folder_id.txt
          echo "阿里云盘转存目录ID已手动保存到 $CONFIG_DIR/temp_transfer_folder_id.txt"
        else
          echo "错误：阿里云盘转存目录ID应为40位"
        fi
      fi
    else
      echo "请输入阿里云盘转存目录ID (40位):"
      read -r folder_id
      if [ ${#folder_id} -eq 40 ]; then
        echo "$folder_id" > $CONFIG_DIR/temp_transfer_folder_id.txt
        echo "阿里云盘转存目录ID已保存到 $CONFIG_DIR/temp_transfer_folder_id.txt"
      else
        echo "错误：阿里云盘转存目录ID应为40位"
      fi
    fi
    ;;
  9)
    echo "开始扫码获取阿里云盘 Folder ID..."
    podman run -i --rm \
      -v "$CONFIG_DIR:/data" \
      -e LANG=C.UTF-8 \
      --userns=keep-id \
      --security-opt label=disable \
      ddsderek/xiaoya-glue:python \
      /get_folder_id/get_folder_id.py --data_path='/data' --drive_mode=r
    if [ -f "$CONFIG_DIR/temp_transfer_folder_id.txt" ]; then
      folder_id=$(cat "$CONFIG_DIR/temp_transfer_folder_id.txt")
      if [ ${#folder_id} -eq 40 ]; then
        echo "阿里云盘 Folder ID已保存到 $CONFIG_DIR/temp_transfer_folder_id.txt: $folder_id"
      else
        echo "获取的ID长度不正确，请重新获取"
      fi
    else
      echo "扫码获取失败"
    fi
    ;;
  0)
    echo "退出账号管理工具"
    exit 0
    ;;
  *)
    echo "无效选择，请输入0-9之间的数字"
    ;;
esac

