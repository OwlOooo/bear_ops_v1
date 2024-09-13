#!/bin/bash

# 捕获 SIGINT 信号（Ctrl+C）
trap 'echo -e "\n退出脚本"; exit 0' SIGINT

# 函数：检查命令是否存在
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# 函数：安装 Git
install_git() {
  echo "未安装 Git，开始安装..."
  sudo apt-get update
  sudo apt-get install -y git
}

# 函数：安装 bear_ops_v1 项目
install_bear_ops() {
  # 步骤 1: 检查是否安装了 Git，如果没有则安装
  if ! command_exists git; then
    install_git || return 1
  fi
  
  # 步骤 2: 创建 /bear 目录（如果不存在）
  if [ ! -d "/bear" ]; then
    echo "正在创建 /bear 目录..."
    sudo mkdir -p /bear
    sudo chown -R $USER:$USER /bear  # 如果需要设置用户权限，请根据实际情况修改
  fi
  
  # 步骤 3: 克隆 bear_ops_v1 项目
  echo "正在克隆 bear_ops_v1 项目..."
  cd /bear
  git clone https://github.com/OwlOooo/bear_ops_v1.git
  
  # 步骤 4: 进入项目目录，安装依赖库
  echo "正在安装 bear_ops_v1 项目依赖库..."
  cd bear_ops_v1
  npm install
  
  echo "bear_ops_v1 项目安装完成."
}

# 函数：启动 bear_ops_v1 项目
start_bear_ops() {
  if [ -f /bear/bear_ops_v1/bear_ops.pid ]; then
    pid=$(cat /bear/bear_ops_v1/bear_ops.pid)
    if kill -0 $pid 2>/dev/null; then
      echo "bear_ops_v1 项目已经在运行中 (PID: $pid)."
      return
    fi
  fi
  
  echo "正在启动 bear_ops_v1 项目..."
  setsid nohup node /bear/bear_ops_v1/index.js > /bear/bear_ops_v1/output.log 2>&1 < /dev/null &
  echo $! > /bear/bear_ops_v1/bear_ops.pid
  echo "bear_ops_v1 项目已在后台启动，PID: $!"
}

# 函数：显示菜单
show_menu() {
  echo "bear 项目管理菜单:"
  echo "1. 安装 bear_ops"
  echo "2. 启动"
  echo "3. 重启"
  echo "4. 关闭"
  echo "5. 查看实时日志"
  echo "按 Ctrl+C 退出脚本"
}

# 函数：查看实时日志
view_logs() {
  echo "显示最后100行的实时日志，按 Ctrl+C 退出..."
  tail -n 100 -f /bear/bear_ops_v1/output.log
}

# 主程序
main() {
  # 检查是否安装了 Node.js 和 npm，如果没有则安装
  if ! command_exists node || ! command_exists npm; then
    echo "未安装 Node.js 或 npm，开始安装..."
    sudo apt-get update
    sudo apt-get install -y nodejs npm
  fi

  while true; do
    show_menu
    read -p "请选择操作（输入对应数字）: " choice
    case $choice in
      1)
        install_bear_ops
        ;;
      2)
        start_bear_ops
        disown -h $(cat /bear/bear_ops_v1/bear_ops.pid)
        ;;
      3)
        echo "正在重启 bear_ops_v1 项目..."
        if [ -f /bear/bear_ops_v1/bear_ops.pid ]; then
          pid=$(cat /bear/bear_ops_v1/bear_ops.pid)
          if kill -0 $pid 2>/dev/null; then
            kill $pid
            echo "已终止旧的 bear_ops_v1 进程 (PID: $pid)."
          else
            echo "bear_ops_v1 项目未在运行中."
          fi
          rm /bear/bear_ops_v1/bear_ops.pid
        fi
        start_bear_ops
        disown -h $(cat /bear/bear_ops_v1/bear_ops.pid)
        ;;
      4)
        echo "正在关闭 bear_ops_v1 项目..."
        if [ -f /bear/bear_ops_v1/bear_ops.pid ]; then
          pid=$(cat /bear/bear_ops_v1/bear_ops.pid)
          if kill -0 $pid 2>/dev/null; then
            kill $pid
            echo "已终止 bear_ops_v1 进程 (PID: $pid)."
          else
            echo "bear_ops_v1 项目未在运行中."
          fi
          rm /bear/bear_ops_v1/bear_ops.pid
        else
          echo "bear_ops_v1 项目未在运行中."
        fi
        ;;
      5)
        view_logs
        ;;
      *)
        echo "无效的选择，请输入菜单中的数字."
        ;;
    esac
    echo "按回车键返回主菜单..."
    read
  done
}

# 运行主程序
main
