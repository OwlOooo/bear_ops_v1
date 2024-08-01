#!/bin/bash

# 函数：检查命令是否存在
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# 函数：检查系统是否为 CentOS
check_centos() {
  if [ -f /etc/redhat-release ]; then
    grep -q "CentOS" /etc/redhat-release
    return $?
  else
    return 1
  fi
}

# 函数：安装 Git
install_git() {
  echo "未安装 Git，开始安装..."
  if command_exists yum; then
    sudo yum install -y git
  elif command_exists apt-get; then
    sudo apt-get install -y git
  else
    echo "无法确定包管理器，请手动安装 Git."
    exit 1
  fi
}

# 函数：安装 bear_ops_v1 项目
install_bear_ops() {
  # 步骤 1: 检查是否安装了 Git，如果没有则安装
  if ! command_exists git; then
    install_git
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

# 步骤 0: 检查系统是否为 CentOS，如果不是则提示并退出
if ! check_centos; then
  echo "当前系统不是 CentOS，无法继续执行脚本。"
  exit 1
fi

# 步骤 1: 检查是否安装了 Node.js 和 npm，如果没有则安装
if ! command_exists node || ! command_exists npm; then
  echo "未安装 Node.js 或 npm，开始安装..."
  # 使用包管理器安装 Node.js 和 npm（以 CentOS 为例）
  sudo yum install -y nodejs npm
fi

# 显示菜单
echo "bear 项目管理菜单:"
echo "1. 安装 bear_ops"
echo "2. 启动"
echo "3. 重启"
echo "4. 关闭"

# 读取用户输入选择操作
read -p "请选择操作（输入对应数字）: " choice

# 根据用户选择执行相应操作
case $choice in
  1)
    install_bear_ops
    ;;
  2)
    echo "正在启动 bear_ops_v1 项目..."
    node /bear/bear_ops_v1/index.js &
    echo "bear_ops_v1 项目已在后台启动."
    ;;
  3)
    echo "正在重启 bear_ops_v1 项目..."
    # 查找并终止已运行的 Node.js 进程
    pid=$(pgrep -f "node /bear/bear_ops_v1/index.js")
    if [ -n "$pid" ]; then
      kill "$pid"
      echo "已终止旧的 bear_ops_v1 进程 (PID: $pid)."
      # 启动新的 Node.js 进程
      node /bear/bear_ops_v1/index.js &
      echo "bear_ops_v1 项目已重启."
    else
      echo "bear_ops_v1 项目未在运行中."
    fi
    ;;
  4)
    echo "正在关闭 bear_ops_v1 项目..."
    # 查找并终止已运行的 Node.js 进程
    pid=$(pgrep -f "node /bear/bear_ops_v1/index.js")
    if [ -n "$pid" ]; then
      kill "$pid"
      echo "已终止 bear_ops_v1 进程 (PID: $pid)."
    else
      echo "bear_ops_v1 项目未在运行中."
    fi
    ;;
  *)
    echo "无效的选择，请输入菜单中的数字."
    ;;
esac

exit 0