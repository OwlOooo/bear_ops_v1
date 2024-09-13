# bear_ops_v1 项目一键安装和管理脚本

## 安装步骤

### CentOS 系统

```bash
curl -O https://raw.githubusercontent.com/OwlOooo/bear_ops_v1/main/install_bear_centos.sh
chmod +x install_bear_centos.sh
sudo mv install_bear_centos.sh /usr/local/bin/bear
sudo ln -s /usr/local/bin/bear /usr/bin/bear
```

### Ubuntu 系统

```bash
curl -O https://raw.githubusercontent.com/OwlOooo/bear_ops_v1/main/install_bear_ubuntu.sh
chmod +x install_bear_ubuntu.sh
sudo mv install_bear_ubuntu.sh /usr/local/bin/bear
sudo ln -s /usr/local/bin/bear /usr/bin/bear
```

## 使用方法

安装完成后，只需在终端中运行以下命令：

```bash
bear
```

## 项目信息

- **端口**：8976

---

注意：请确保您有足够的权限执行这些命令。如果遇到权限问题，可能需要使用 `sudo` 运行某些命令。
