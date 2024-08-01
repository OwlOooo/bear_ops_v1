#!/bin/bash

# 定义函数：检查命令是否存在
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# 步骤 0: 检查是否安装了 Git，如果没有则安装
if ! command_exists git; then
  echo "未安装 Git，开始安装..."
  # 使用包管理器安装 Git（以 CentOS 为例）
  sudo yum install -y git
fi

# 步骤 1: 检查是否安装了 Node.js 和 npm，如果没有则安装
if ! command_exists node || ! command_exists npm; then
  echo "未安装 Node.js 或 npm，开始安装..."
  # 使用包管理器安装 Node.js 和 npm（以 CentOS 为例）
  sudo yum install -y nodejs npm
fi

# 步骤 2: 如果项目尚未克隆，则创建 /bear 目录，再克隆 bear_ops_v1 项目
if [ ! -d "/bear/bear_ops_v1" ]; then
  echo "正在创建 /bear 目录并克隆 bear_ops_v1 项目..."
  sudo mkdir -p /bear
  sudo chown -R $USER:$USER /bear  # 如果需要设置用户权限，请根据实际情况修改
  cd /bear
  git clone https://github.com/OwlOooo/bear_ops_v1.git
fi

# 步骤 3: 进入项目目录，安装依赖库
echo "正在安装 bear_ops_v1 项目依赖库..."
cd /bear/bear_ops_v1
npm install

# 步骤 4: 启动 index.js 并在后台运行
echo "正在启动 bear_ops_v1 项目..."
node index.js &

echo "bear_ops_v1 项目已在后台启动."
