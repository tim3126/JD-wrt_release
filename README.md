# 京东云太乙 ER1 (RE-CS-07) OpenWrt 云编译

专为京东云太乙 ER1 路由器定制的 OpenWrt 云编译项目。

## 设备信息

- **设备型号**: 京东云太乙 ER1 (RE-CS-07)
- **芯片**: Qualcomm IPQ6010
- **特性**: 无 WiFi，有线 NSS 硬件加速

## 源码

基于 [LiBwrt/openwrt-6.x](https://github.com/LiBwrt/openwrt-6.x) 的 `main-nss` 分支，支持高通 NSS 满血加速。

## 预装插件

### 代理工具
- luci-app-nikki (Mihomo) - 主用，轻便
- luci-app-openclash - 备用，功能全
- luci-app-homeproxy

### DNS/广告过滤
- luci-app-adguardhome
- luci-app-smartdns

### 网络工具
- luci-app-ddns-go
- luci-app-cloudflared (Cloudflare 零信任隧道)
- luci-app-easytier
- luci-app-lucky
- luci-app-sqm
- luci-app-upnp
- luci-app-wol
- luci-app-pbr
- luci-app-frpc (内网穿透)
- luci-app-oaf (应用过滤)

### 系统管理
- luci-app-dockerman
- luci-app-diskman
- luci-app-ttyd
- luci-app-autoreboot
- luci-app-package-manager

### 文件共享
- luci-app-samba4
- luci-app-quickfile
- luci-app-cupsd (打印服务)

### 其他
- luci-app-vsftpd (FTP服务)
- luci-app-vlmcsd
- luci-app-firewall
- luci-app-arpbind (IP/MAC绑定)
- luci-app-timecontrol (上网时间控制)

## 编译方法

### 云编译 (GitHub Actions)

Fork 本仓库后，在 Actions 中手动触发编译。

### 本地编译

**要求**: Ubuntu 22.04 LTS 或 Debian 11

```bash
# 安装依赖
sudo apt -y update
sudo apt -y full-upgrade
sudo apt install -y dos2unix libfuse-dev
sudo bash -c 'bash <(curl -sL https://build-scripts.immortalwrt.org/init_build_environment.sh)'

# 克隆仓库
git clone https://github.com/你的用户名/JD-wrt_release.git
cd JD-wrt_release

# 编译太乙 ER1
./build.sh jdcloud_er1_libwrt
```

## 默认设置

- 登录地址: `192.168.10.1`
- 默认密码: 无

## 插件来源

| Feed | 仓库 |
|------|------|
| small8 | https://github.com/kenzok8/small-package |
| nikki | https://github.com/nikkinikki-org/OpenWrt-nikki |

## OAF（应用过滤）功能使用说明

使用 OAF（应用过滤）功能前，需先完成以下操作：

1. 打开系统设置 → 启动项 → 定位到「appfilter」
2. 将「appfilter」当前状态**从已禁用更改为已启用**
3. 完成配置后，点击**启动**按钮激活服务

## 致谢

- [LiBwrt](https://github.com/LiBwrt/openwrt-6.x) - OpenWrt NSS 源码
- [kenzok8](https://github.com/kenzok8/small-package) - 插件合集
- [nikkinikki-org](https://github.com/nikkinikki-org/OpenWrt-nikki) - Nikki/Mihomo
- [ZqinKing](https://github.com/ZqinKing/wrt_release) - 原始编译框架
