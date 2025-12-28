#!/usr/bin/env bash
set -e

CONFIG_DIR="$1"
MEDIA_DIR="$2"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# 函数定义
info() { echo -e "${GREEN}[INFO]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
debug() { echo -e "${CYAN}[DEBUG]${RESET} $1"; }

# 元数据文件列表
ALL_METADATA_FILES=("all.mp4" "config.mp4" "115.mp4")
EXTRA_METADATA_FILES=("pikpak.mp4" "蓝光原盘.mp4" "json.mp4" "music.mp4" "短剧.mp4")

# 全局变量
DATA_DOWNLOADER="wget"  # 默认下载器
CURRENT_PAGE=1

# 检查目录是否存在
check_directories() {
  if [ ! -d "$CONFIG_DIR" ]; then
    error "配置目录不存在: $CONFIG_DIR"
    return 1
  fi
  
  if [ ! -d "$MEDIA_DIR" ]; then
    warn "媒体目录不存在，正在创建: $MEDIA_DIR"
    mkdir -p "$MEDIA_DIR"
  fi
  
  # 创建临时目录
  mkdir -p "$MEDIA_DIR/temp"
  mkdir -p "$MEDIA_DIR/xiaoya"
  mkdir -p "$MEDIA_DIR/config"
  
  return 0
}

# 检查文件大小
check_metadata_size() {
  local file="$1"
  if [ ! -f "$MEDIA_DIR/temp/$file" ]; then
    error "文件不存在: $MEDIA_DIR/temp/$file"
    return 1
  fi
  
  local file_size=$(du -k "$MEDIA_DIR/temp/$file" | cut -f1)
  if [ "$file_size" -lt 100 ]; then  # 小于100KB认为文件异常
    error "文件大小异常: $file (大小: ${file_size}KB)"
    return 1
  fi
  
  info "$file 文件大小验证正常，文件大小(in KB): $file_size"
  return 0
}

# 获取小雅内部地址
get_xiaoya_addr() {
  local docker0
  
  # 获取容器网络接口 IP
  if command -v ip > /dev/null 2>&1; then
    docker0=$(ip addr show podman0 2>/dev/null | awk '/inet / {print $2}' | cut -d '/' -f 1)
    if [ -z "$docker0" ]; then
      docker0=$(ip addr show docker0 2>/dev/null | awk '/inet / {print $2}' | cut -d '/' -f 1)
    fi
  elif command -v ifconfig > /dev/null 2>&1; then
    docker0=$(ifconfig docker0 2>/dev/null | awk '/inet / {print $2}' | sed 's/addr://')
  fi
  
  if [ -n "$docker0" ]; then
    info "容器网络接口的 IP 地址是：$docker0"
  else
    warn "无法获取容器网络接口的 IP 地址！"
    # 获取本地 IP
    docker0=$(get_local_ip)
    info "尝试使用本地IP：${docker0}"
  fi
  
  # 测试小雅连通性
  info "测试小雅的联通性..."
  
  # 获取签名（如果有）
  local sign=""
  if [ ! -f "$CONFIG_DIR/nosign.txt" ] && [ -f "$CONFIG_DIR/guestpass.txt" ] && [ -f "$CONFIG_DIR/guestlogin.txt" ]; then
    # 简化签名获取，实际使用中可能需要容器执行
    if [ -f "$CONFIG_DIR/guestpass.txt" ]; then
      sign_md5=$(cat "$CONFIG_DIR/guestpass.txt" | tr -d '\r\n' | md5sum | awk '{print $1}')
      sign="?sign=$sign_md5"
    fi
  fi
  
  # 内部函数：尝试启动小雅 Alist 容器
  start_xiaoya_alist_if_needed() {
    info "尝试启动小雅 Alist 容器..."
    
    # 检查 podman 是否可用
    if ! command -v podman > /dev/null 2>&1; then
      error "podman 命令未找到，无法启动容器"
      return 1
    fi
    
    # 检查容器是否已在运行
    if podman ps --filter name=xiaoya-alist --format "{{.Status}}" 2>/dev/null | grep -q "Up"; then
      info "小雅 Alist 容器已在运行"
      return 0
    fi
    
    # 检查容器是否存在但已停止
    if podman ps -a --filter name=xiaoya-alist --format "{{.Status}}" 2>/dev/null | grep -q "Exited"; then
      info "启动已停止的小雅 Alist 容器..."
      if podman start xiaoya-alist > /dev/null 2>&1; then
        info "容器启动成功"
        return 0
      else
        error "容器启动失败"
        return 1
      fi
    fi
    
    # 如果容器不存在，尝试使用 xiaoya-alist-start 命令启动
    if command -v xiaoya-alist-start > /dev/null 2>&1; then
      info "使用 xiaoya-alist-start 命令启动容器..."
      if xiaoya-alist-start > /dev/null 2>&1; then
        info "容器启动成功"
        return 0
      else
        error "xiaoya-alist-start 启动失败"
        return 1
      fi
    else
      # 直接使用 podman run 启动容器（简化版本，可能需要根据实际情况调整参数）
      warn "xiaoya-alist-start 命令未找到，尝试直接启动容器"
      if podman run -d \
        --name xiaoya-alist \
        --restart=no \
        -v "$CONFIG_DIR:/data" \
        -v "$MEDIA_DIR:/media" \
        -p 5678:80 \
        -p 5244:5244 \
        -p 2345:2345 \
        -e TZ=Asia/Shanghai \
        ddsderek/xiaoya-alist:latest > /dev/null 2>&1; then
        info "容器启动成功"
        return 0
      else
        error "容器启动失败"
        return 1
      fi
    fi
  }
  
  # 内部函数：测试连接
  test_connection() {
    local url="$1"
    if curl -siL -m 10 "$url" | grep -q -e "x-oss-" -e "x-115-request-id"; then
      return 0
    else
      return 1
    fi
  }
  
  # 第一次尝试连接
  local xiaoya_addr=""
  if test_connection "http://127.0.0.1:5678/d/README.md$sign"; then
    xiaoya_addr="http://127.0.0.1:5678"
  elif [ -n "$docker0" ] && test_connection "http://${docker0}:5678/d/README.md$sign"; then
    xiaoya_addr="http://${docker0}:5678"
  elif [ -f "$CONFIG_DIR/docker_address.txt" ]; then
    docker_address=$(head -n1 "$CONFIG_DIR/docker_address.txt")
    if test_connection "${docker_address}/d/README.md$sign"; then
      xiaoya_addr="$docker_address"
    else
      warn "使用配置的 docker_address.txt 地址，但无法验证连通性"
      xiaoya_addr="$docker_address"
    fi
  fi
  
  # 如果连接成功，返回地址
  if [ -n "$xiaoya_addr" ]; then
    echo "$xiaoya_addr"
    return 0
  fi
  
  # 连接失败，尝试启动容器
  warn "无法连接到小雅，尝试启动小雅 Alist 容器..."
  if start_xiaoya_alist_if_needed; then
    info "等待容器启动（10秒）..."
    sleep 10
    
    # 第二次尝试连接
    if test_connection "http://127.0.0.1:5678/d/README.md$sign"; then
      xiaoya_addr="http://127.0.0.1:5678"
    elif [ -n "$docker0" ] && test_connection "http://${docker0}:5678/d/README.md$sign"; then
      xiaoya_addr="http://${docker0}:5678"
    elif [ -f "$CONFIG_DIR/docker_address.txt" ]; then
      docker_address=$(head -n1 "$CONFIG_DIR/docker_address.txt")
      if test_connection "${docker_address}/d/README.md$sign"; then
        xiaoya_addr="$docker_address"
      else
        warn "使用配置的 docker_address.txt 地址，但无法验证连通性"
        xiaoya_addr="$docker_address"
      fi
    fi
    
    if [ -n "$xiaoya_addr" ]; then
      info "小雅 Alist 容器已启动并成功连接"
      echo "$xiaoya_addr"
      return 0
    fi
  fi
  
  # 如果仍然失败，报错退出
  error "无法连接到小雅，请检查小雅是否正常运行"
  error "可以尝试手动运行 'xiaoya-alist-start' 启动容器"
  exit 1
}

# 获取本地 IP
get_local_ip() {
  # Linux (包括 NixOS)
  ip address | grep inet | grep -v 172.17 | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | sed 's/addr://' | head -n1 | cut -f1 -d"/"
}

# 下载元数据文件
download_metadata_file() {
  local file="$1"
  
  # 获取小雅地址
  local xiaoya_addr=$(get_xiaoya_addr)
  info "连接小雅地址为: $xiaoya_addr"
  
  # 获取签名
  local sign=""
  if [ ! -f "$CONFIG_DIR/nosign.txt" ] && [ -f "$CONFIG_DIR/guestpass.txt" ] && [ -f "$CONFIG_DIR/guestlogin.txt" ]; then
    if [ -f "$CONFIG_DIR/guestpass.txt" ]; then
      sign_md5=$(cat "$CONFIG_DIR/guestpass.txt" | tr -d '\r\n' | md5sum | awk '{print $1}')
      sign="?sign=$sign_md5"
    fi
  fi
  
  info "开始下载 $file ..."
  info "下载路径: $MEDIA_DIR/temp/$file"
  
  # 清理旧文件
  if [ -f "$MEDIA_DIR/temp/$file" ]; then
    info "清理旧 $file 中..."
    rm -f "$MEDIA_DIR/temp/$file"
    if [ -f "$MEDIA_DIR/temp/$file.aria2" ]; then
      rm -f "$MEDIA_DIR/temp/$file.aria2"
    fi
  fi
  
  # 下载文件
  local url="$xiaoya_addr/d/元数据/$file$sign"
  
  if [ "$DATA_DOWNLOADER" = "wget" ]; then
    info "使用 wget 下载"
    if wget -c --show-progress "$url" -U "Mozilla/5.0" -O "$MEDIA_DIR/temp/$file"; then
      info "$file 下载成功！"
      return 0
    else
      error "$file 下载失败！"
      return 1
    fi
  else
    info "使用 aria2 下载"
    if aria2c -o "$file" --header="User-Agent: Mozilla/5.0" --allow-overwrite=true \
              --auto-file-renaming=false -c -x4 "$url" -d "$MEDIA_DIR/temp"; then
      if [ -f "$MEDIA_DIR/temp/$file.aria2" ]; then
        error "存在 $MEDIA_DIR/temp/$file.aria2 文件，下载不完整！"
        return 1
      else
        info "$file 下载成功！"
        return 0
      fi
    else
      error "$file 下载失败！"
      return 1
    fi
  fi
}

# 解压元数据文件
extract_metadata_file() {
  local file="$1"
  
  if ! check_metadata_size "$file"; then
    return 1
  fi
  
  info "开始解压 $file ..."
  
  # 检查是否安装 7z
  if ! command -v 7z &> /dev/null; then
    error "请先安装 7z (p7zip) 工具"
    return 1
  fi
  
  # 根据文件类型选择解压目录
  if [ "$file" = "config.mp4" ]; then
    local extract_dir="$MEDIA_DIR/config"
    if [ -d "$extract_dir" ]; then
      info "清理旧配置文件中..."
      rm -rf "$extract_dir"
    fi
    mkdir -p "$extract_dir"
  else
    local extract_dir="$MEDIA_DIR/xiaoya"
    mkdir -p "$extract_dir"
  fi
  
  # 解压文件
  cd "$extract_dir" || return 1
  info "当前解压工作目录: $(pwd)"
  
  if 7z x -aoa -mmt=4 "$MEDIA_DIR/temp/$file"; then
    info "$file 解压成功！"
    
    # 设置权限
    chmod -R 755 "$extract_dir"
    
    # 可选：清理原文件
    # rm -f "$MEDIA_DIR/temp/$file"
    
    return 0
  else
    error "$file 解压失败！"
    return 1
  fi
}

# 解压指定目录
extract_specific_directory() {
  local file="$1"
  
  if ! check_metadata_size "$file"; then
    return 1
  fi
  
  info "请选择要解压的目录:"
  
  if [ "$file" = "all.mp4" ]; then
    echo "1、动漫"
    echo "2、每日更新"
    echo "3、电影"
    echo "4、电视剧"
    echo "5、纪录片"
    echo "6、纪录片（已刮削）"
    echo "7、综艺"
    echo "8、短剧"
    
    read -p "请输入数字 [1-8]: " choice
    
    case $choice in
      1) target_dir="动漫" ;;
      2) target_dir="每日更新" ;;
      3) target_dir="电影" ;;
      4) target_dir="电视剧" ;;
      5) target_dir="纪录片" ;;
      6) target_dir="纪录片（已刮削）" ;;
      7) target_dir="综艺" ;;
      8) target_dir="短剧" ;;
      *)
        error "无效选择"
        return 1
        ;;
    esac
  elif [ "$file" = "115.mp4" ]; then
    echo "1、电影"
    echo "2、电视剧"
    echo "3、动漫"
    echo "4、纪录片"
    
    read -p "请输入数字 [1-4]: " choice
    
    case $choice in
      1) target_dir="电影" ;;
      2) target_dir="电视剧" ;;
      3) target_dir="动漫" ;;
      4) target_dir="纪录片" ;;
      *)
        error "无效选择"
        return 1
        ;;
    esac
  else
    error "此文件暂时不支持解压指定目录！"
    return 1
  fi
  
  info "开始解压 $file 中的 $target_dir 目录..."
  
  mkdir -p "$MEDIA_DIR/xiaoya"
  cd "$MEDIA_DIR/xiaoya" || return 1
  
  if 7z x -aoa -mmt=4 "$MEDIA_DIR/temp/$file" "$target_dir/*"; then
    info "$target_dir 目录解压成功！"
    return 0
  else
    error "$target_dir 目录解压失败！"
    return 1
  fi
}

# 下载并解压全部元数据
download_extract_all_metadata() {
  info "开始下载并解压全部元数据..."
  
  # 清理旧目录
  rm -rf "$MEDIA_DIR/config"
  rm -rf "$MEDIA_DIR/xiaoya"
  
  # 创建目录
  mkdir -p "$MEDIA_DIR/config"
  mkdir -p "$MEDIA_DIR/xiaoya"
  mkdir -p "$MEDIA_DIR/temp"
  
  # 下载并解压所有文件
  for file in "${ALL_METADATA_FILES[@]}"; do
    if download_metadata_file "$file"; then
      if extract_metadata_file "$file"; then
        info "$file 处理完成"
      else
        error "$file 解压失败"
        return 1
      fi
    else
      error "$file 下载失败"
      return 1
    fi
  done
  
  info "全部元数据下载解压完成！"
  return 0
}

# 解压全部元数据
extract_all_metadata() {
  info "开始解压全部元数据..."
  
  # 检查文件是否存在
  for file in "${ALL_METADATA_FILES[@]}"; do
    if [ ! -f "$MEDIA_DIR/temp/$file" ]; then
      error "文件不存在: $MEDIA_DIR/temp/$file"
      error "请先下载元数据文件"
      return 1
    fi
  done
  
  # 清理旧目录
  rm -rf "$MEDIA_DIR/config"
  rm -rf "$MEDIA_DIR/xiaoya"
  
  # 创建目录
  mkdir -p "$MEDIA_DIR/config"
  mkdir -p "$MEDIA_DIR/xiaoya"
  
  # 解压所有文件
  for file in "${ALL_METADATA_FILES[@]}"; do
    if extract_metadata_file "$file"; then
      info "$file 解压完成"
    else
      error "$file 解压失败"
      return 1
    fi
  done
  
  info "全部元数据解压完成！"
  return 0
}

# 显示当前状态
show_status() {
  info "当前状态:"
  echo -e "配置目录: $CONFIG_DIR"
  echo -e "媒体目录: $MEDIA_DIR"
  echo -e "当前下载器: ${GREEN}$DATA_DOWNLOADER${RESET}"
  echo ""
  
  info "元数据文件状态:"
  for file in "${ALL_METADATA_FILES[@]}" "${EXTRA_METADATA_FILES[@]}"; do
    if [ -f "$MEDIA_DIR/temp/$file" ]; then
      local size=$(du -h "$MEDIA_DIR/temp/$file" | cut -f1)
      echo -e "  $file: ${GREEN}已下载${RESET} ($size)"
    else
      echo -e "  $file: ${RED}未下载${RESET}"
    fi
  done
  
  echo ""
  info "解压状态:"
  if [ -d "$MEDIA_DIR/config" ] && [ "$(ls -A $MEDIA_DIR/config 2>/dev/null)" ]; then
    echo -e "  config: ${GREEN}已解压${RESET}"
  else
    echo -e "  config: ${RED}未解压${RESET}"
  fi
  
  if [ -d "$MEDIA_DIR/xiaoya" ] && [ "$(ls -A $MEDIA_DIR/xiaoya 2>/dev/null)" ]; then
    local file_count=$(find "$MEDIA_DIR/xiaoya" -type f | wc -l)
    echo -e "  xiaoya: ${GREEN}已解压${RESET} ($file_count 个文件)"
  else
    echo -e "  xiaoya: ${RED}未解压${RESET}"
  fi
}

# 切换下载器
toggle_downloader() {
  if [ "$DATA_DOWNLOADER" = "wget" ]; then
    if command -v aria2c &> /dev/null; then
      DATA_DOWNLOADER="aria2"
      info "下载器已切换为: aria2"
    else
      warn "aria2 未安装，保持使用 wget"
    fi
  else
    DATA_DOWNLOADER="wget"
    info "下载器已切换为: wget"
  fi
}

# 显示菜单 - 第一页
show_menu_page1() {
  echo -e "${BLUE}========================================${RESET}"
  echo -e "${BLUE}        小雅 Emby 元数据解压${RESET}"
  echo -e "${BLUE}========================================${RESET}"
  echo ""
  echo -e "${CYAN}下载/解压 元数据${RESET}"
  echo ""
  echo -e "1、下载并解压 全部元数据"
  echo -e "2、解压 全部元数据"
  echo -e "3、下载 all.mp4"
  echo -e "4、解压 all.mp4"
  echo -e "5、解压 all.mp4 的指定元数据目录【非全部解压】"
  echo -e "6、下载 config.mp4（4.9.0.42）"
  echo -e "7、解压 config.mp4（4.9.0.42）"
  echo -e "8、下载 pikpak.mp4"
  echo -e "9、解压 pikpak.mp4"
  echo -e "10、下载 115.mp4"
  echo -e "11、解压 115.mp4"
  echo -e "n、下一页"
  echo -e "21、当前下载器【aria2/wget】                  当前状态：${GREEN}${DATA_DOWNLOADER}${RESET}"
  echo -e "0、退出"
  echo ""
  echo -e "${BLUE}========================================${RESET}"
}

# 显示菜单 - 第二页
show_menu_page2() {
  echo -e "${BLUE}========================================${RESET}"
  echo -e "${BLUE}        小雅 Emby 元数据解压${RESET}"
  echo -e "${BLUE}========================================${RESET}"
  echo ""
  echo -e "${CYAN}下载/解压 元数据${RESET}"
  echo ""
  echo -e "12、解压 115.mp4 的指定元数据目录【非全部解压】"
  echo -e "13、下载 蓝光原盘.mp4"
  echo -e "14、解压 蓝光原盘.mp4"
  echo -e "15、下载 json.mp4"
  echo -e "16、解压 json.mp4"
  echo -e "17、下载 music.mp4"
  echo -e "18、解压 music.mp4"
  echo -e "19、下载 短剧.mp4"
  echo -e "20、解压 短剧.mp4"
  echo -e "p、上一页"
  echo -e "21、当前下载器【aria2/wget】                  当前状态：${GREEN}${DATA_DOWNLOADER}${RESET}"
  echo -e "0、退出"
  echo ""
  echo -e "${BLUE}========================================${RESET}"
}

# 处理用户选择
handle_choice() {
  local choice="$1"
  
  case "$choice" in
    # 第一页选项
    1)
      if download_extract_all_metadata; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    2)
      if extract_all_metadata; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    3)
      if download_metadata_file "all.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    4)
      if extract_metadata_file "all.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    5)
      if extract_specific_directory "all.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    6)
      if download_metadata_file "config.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    7)
      if extract_metadata_file "config.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    8)
      if download_metadata_file "pikpak.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    9)
      if extract_metadata_file "pikpak.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    10)
      if download_metadata_file "115.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    11)
      if extract_metadata_file "115.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    
    # 第二页选项
    12)
      if extract_specific_directory "115.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    13)
      if download_metadata_file "蓝光原盘.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    14)
      if extract_metadata_file "蓝光原盘.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    15)
      if download_metadata_file "json.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    16)
      if extract_metadata_file "json.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    17)
      if download_metadata_file "music.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    18)
      if extract_metadata_file "music.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    19)
      if download_metadata_file "短剧.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    20)
      if extract_metadata_file "短剧.mp4"; then
        info "操作完成"
      else
        error "操作失败"
      fi
      ;;
    
    # 特殊选项
    21)
      toggle_downloader
      ;;
    
    # 页面导航
    n|N)
      if [ "$CURRENT_PAGE" -eq 1 ]; then
        CURRENT_PAGE=2
      fi
      ;;
    p|P)
      if [ "$CURRENT_PAGE" -eq 2 ]; then
        CURRENT_PAGE=1
      fi
      ;;
    
    # 状态查看
    s|S)
      show_status
      ;;
    
    0)
      info "退出元数据解压工具"
      exit 0
      ;;
    
    *)
      error "无效选择"
      ;;
  esac
}

# 主函数
main() {
  info "小雅 Emby 元数据解压工具"
  info "配置目录: $CONFIG_DIR"
  info "媒体目录: $MEDIA_DIR"
  
  # 检查目录
  if ! check_directories; then
    error "目录检查失败"
    exit 1
  fi
  
  # 检查必要工具
  if ! command -v 7z &> /dev/null; then
    warn "请安装 7z (p7zip) 工具以获得完整功能"
    warn "安装命令: nix-shell -p p7zip"
  fi
  
  if ! command -v wget &> /dev/null; then
    warn "wget 未安装，将尝试使用 curl"
  fi
  
  # 主循环
  while true; do
    if [ "$CURRENT_PAGE" -eq 1 ]; then
      show_menu_page1
    else
      show_menu_page2
    fi
    
    read -p "请选择操作: " choice
    
    # 清空输入缓冲区
    while read -t 0; do read -r; done
    
    handle_choice "$choice"
    
    echo ""
    read -p "按任意键继续..." -n1 -s
    echo ""
  done
}

# 执行主函数
if [ $# -lt 2 ]; then
  echo "用法: $0 <配置目录> <媒体目录>"
  echo "示例: $0 /etc/xiaoya /opt/media"
  exit 1
fi

main "$@"