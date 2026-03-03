# LuCI 可用插件列表

本文档列出了当前编译环境中所有可用的 LuCI 插件，按 Feed 来源分类。

> **注意**：标记 `[已启用]` 的插件为当前固件已启用的插件

---

## luci Feed（官方 LuCI 仓库）

```
插件名                                  中文名              功能说明
─────────────────────────────────────────────────────────────────────────────────
luci-app-3cat                          3Cat                串口终端工具
luci-app-3ginfo-lite                   3G信息              3G/4G调制解调器信息显示
luci-app-acl                           访问控制列表        ACL规则管理
luci-app-acme                          ACME证书            Let's Encrypt自动证书管理
luci-app-adblock                       广告拦截            基于DNS的广告过滤
luci-app-adblock-fast                  快速广告拦截        轻量级广告过滤
luci-app-advanced-reboot               高级重启            双固件切换重启
luci-app-airplay2                      AirPlay2            苹果AirPlay音频接收
luci-app-amule                         aMule               eMule/eDonkey下载客户端
luci-app-antiblock                     反封锁              绕过网络封锁工具
luci-app-apinger                       网络探测            多目标网络延迟监控
luci-app-argon-config                  Argon主题设置       Argon主题配置工具
luci-app-aria2                         Aria2下载           多协议下载工具
luci-app-attendedsysupgrade            在线升级            固件在线升级助手
luci-app-autoreboot                    定时重启            计划任务自动重启 [已启用]
luci-app-babeld                        Babel路由           Babel网状网络路由协议
luci-app-banip                         IP封禁              IP黑名单管理
luci-app-bcp38                         BCP38               源地址验证/防IP欺骗
luci-app-bitsrunlogin-go               深澜认证            校园网深澜认证客户端
luci-app-bmx7                          BMX7路由            BMX7网状网络协议
luci-app-cd8021x                       802.1X              有线802.1X认证
luci-app-chrony                        Chrony时间          NTP时间同步服务
luci-app-cifs-mount                    CIFS挂载            Windows共享文件夹挂载
luci-app-clamav                        ClamAV              病毒扫描引擎
luci-app-cloudflared                   Cloudflare隧道      Cloudflare零信任隧道 [已启用]
luci-app-commands                      自定义命令          快捷Shell命令执行
luci-app-coovachilli                   CoovaChilli         WiFi热点认证网关
luci-app-cpufreq                       CPU频率             CPU调频管理
luci-app-cpulimit                      CPU限制             进程CPU使用率限制
luci-app-crowdsec-firewall-bouncer     CrowdSec            协作式入侵防御
luci-app-csshnpd                       SSH端口敲门         SSH端口隐藏服务
luci-app-dawn                          DAWN漫游            WiFi无缝漫游优化
luci-app-dcwapd                        DCWAP               分布式WiFi控制器
luci-app-ddns                          动态DNS             传统DDNS客户端 [已启用]
luci-app-diskman                       磁盘管理            硬盘分区/格式化/挂载 [已启用]
luci-app-docker                        Docker              Docker容器管理(旧版)
luci-app-dockerman                     Docker管理          Docker容器管理(新版) [已启用]
luci-app-dufs                          DUFS                简易HTTP文件服务器
luci-app-dump1090                      ADS-B接收           飞机ADS-B信号接收
luci-app-email                         邮件通知            系统邮件告警
luci-app-eoip                          EoIP                MikroTik EoIP隧道
luci-app-eqos                          设备限速            按设备限速/QoS
luci-app-example                       示例插件            LuCI插件开发示例
luci-app-filebrowser                   文件浏览器          Web文件管理器
luci-app-filebrowser-go                文件浏览器Go        Go版Web文件管理
luci-app-filemanager                   文件管理器          系统文件管理
luci-app-firewall                      防火墙              防火墙规则管理 [已启用]
luci-app-frpc                          Frp客户端           内网穿透客户端 [已启用]
luci-app-frps                          Frp服务端           内网穿透服务端
luci-app-fwknopd                       端口敲门            单包授权端口敲门
luci-app-gost                          Gost代理            多功能安全隧道
luci-app-hd-idle                       硬盘休眠            硬盘自动休眠管理
luci-app-https-dns-proxy               DoH代理             DNS-over-HTTPS代理
luci-app-ipsec-vpnd                    IPSec VPN           IPSec VPN服务
luci-app-irqbalance                    IRQ均衡             中断请求负载均衡
luci-app-k3screenctrl                  K3屏幕              斐讯K3屏幕控制
luci-app-keepalived                    Keepalived          高可用/VRRP服务
luci-app-ksmbd                         Ksmbd               内核SMB服务器
luci-app-ledtrig-rssi                  信号LED             WiFi信号强度LED指示
luci-app-ledtrig-switch                开关LED             端口状态LED指示
luci-app-ledtrig-usbport               USB LED             USB端口状态LED指示
luci-app-libreswan                     Libreswan           IPsec VPN实现
luci-app-lldpd                         LLDP                链路层发现协议
luci-app-lorawan-basicstation          LoRaWAN             LoRaWAN基站服务
luci-app-lxc                           LXC容器             Linux容器管理
luci-app-microsocks                    MicroSocks          轻量SOCKS5代理
luci-app-minidlna                      MiniDLNA            DLNA媒体服务器
luci-app-modemband                     调制解调器频段      4G/5G频段锁定
luci-app-mosquitto                     Mosquitto           MQTT消息代理
luci-app-music-remote-center           音乐中心            网络音乐播放控制
luci-app-mwan3                         多WAN               多线负载均衡/故障切换
luci-app-n2n                           N2N组网             P2P VPN组网
luci-app-natmap                        NAT映射             NAT类型检测/穿透
luci-app-netdata                       Netdata             实时系统监控
luci-app-nextdns                       NextDNS             NextDNS客户端
luci-app-nfs                           NFS                 网络文件系统服务
luci-app-ngrokc                        Ngrok               Ngrok内网穿透
luci-app-njitclient                    南理工认证          校园网认证客户端
luci-app-nlbwmon                       流量监控            网络带宽使用统计
luci-app-nps                           NPS穿透             NPS内网穿透客户端
luci-app-nut                           UPS管理             不间断电源管理
luci-app-ocserv                        OpenConnect         OpenConnect VPN服务
luci-app-oled                          OLED显示            OLED屏幕信息显示
luci-app-olsr                          OLSR路由            优化链路状态路由
luci-app-olsr-services                 OLSR服务            OLSR服务发现
luci-app-olsr-viz                      OLSR可视化          OLSR网络拓扑图
luci-app-omcproxy                      组播代理            IGMP/MLD组播代理
luci-app-openlist                      开放列表            自定义列表管理
luci-app-openvpn-server                OpenVPN服务         OpenVPN服务端
luci-app-openwisp                      OpenWISP            网络管理平台客户端
luci-app-oscam                         OSCam               卫星电视解密
luci-app-p910nd                        打印服务器          无驱动打印服务
luci-app-package-manager               软件包管理          opkg包管理界面 [已启用]
luci-app-pagekitec                     PageKite            PageKite隧道客户端
luci-app-pbr                           策略路由            基于策略的路由 [已启用]
luci-app-pppoe-relay                   PPPoE中继           PPPoE协议中继
luci-app-pppoe-server                  PPPoE服务           PPPoE拨号服务端
luci-app-privoxy                       Privoxy             HTTP过滤代理
luci-app-ps3netsrv                     PS3网络服务         PS3游戏网络加载
luci-app-qbittorrent                   qBittorrent         BT下载客户端
luci-app-qos                           QoS                 传统服务质量控制
luci-app-radicale3                     Radicale            CalDAV/CardDAV服务
luci-app-ramfree                       内存释放            手动释放内存缓存
luci-app-rp-pppoe-server               RP-PPPoE            Roaring Penguin PPPoE
luci-app-rustdesk-server               RustDesk服务        远程桌面服务端
luci-app-samba4                        Samba共享           Windows文件共享 [已启用]
luci-app-scutclient                    华工认证            校园网认证客户端
luci-app-ser2net                       串口转网络          串口设备网络访问
luci-app-smartdns                      SmartDNS            智能DNS解析加速 [已启用]
luci-app-sms-tool-js                   短信工具            4G模块短信收发
luci-app-snmpd                         SNMP                简单网络管理协议
luci-app-softether                     SoftEther           SoftEther VPN
luci-app-softethervpn                  SoftEther VPN       SoftEther VPN管理
luci-app-spotifyd                      Spotifyd            Spotify Connect播放
luci-app-sqm                           SQM智能队列         智能队列管理/降延迟 [已启用]
luci-app-squid                         Squid代理           HTTP缓存代理服务
luci-app-sshtunnel                     SSH隧道             SSH端口转发隧道
luci-app-statistics                    系统统计            系统性能图表统计
luci-app-strongswan-swanctl            StrongSwan          IPsec VPN(swanctl)
luci-app-syncdial                      多拨                PPPoE多线并发拨号
luci-app-syncthing                     Syncthing           文件同步工具
luci-app-sysuh3c                       中大认证            校园网H3C认证
luci-app-tailscale-community           Tailscale           WireGuard组网(社区版)
luci-app-timewol                       定时唤醒            定时网络唤醒
luci-app-tinyproxy                     TinyProxy           轻量HTTP代理
luci-app-tor                           Tor                 洋葱路由匿名网络
luci-app-transmission                  Transmission        BT下载客户端
luci-app-travelmate                    旅行伴侣            WiFi自动连接/漫游
luci-app-ttyd                          网页终端            Web SSH终端 [已启用]
luci-app-ua2f                          UA2F                HTTP User-Agent修改
luci-app-udpxy                         UDPXY               UDP转HTTP组播代理
luci-app-uhttpd                        uHTTPd              Web服务器管理
luci-app-unbound                       Unbound             DNS递归解析器
luci-app-upnp                          UPnP                自动端口映射 [已启用]
luci-app-usb-printer                   USB打印             USB打印机共享
luci-app-usteer                        uSteer              WiFi漫游协调器
luci-app-ustreamer                     uStreamer           MJPEG视频流服务
luci-app-v2raya                        V2rayA              V2ray图形管理界面
luci-app-vlmcsd                        KMS服务             微软KMS激活服务 [已启用]
luci-app-vnstat2                       VnStat              网络流量统计
luci-app-vsftpd                        FTP服务             VSFTPD FTP服务器 [已启用]
luci-app-watchcat                      看门狗              网络连通性监控重启
luci-app-wechatpush                    微信推送            微信消息通知
luci-app-wifihistory                   WiFi历史            WiFi设备连接历史
luci-app-wifischedule                  WiFi定时            WiFi定时开关
luci-app-wol                           网络唤醒            Wake-on-LAN [已启用]
luci-app-xfrpc                         xFrp客户端          xFrp内网穿透
luci-app-xinetd                        Xinetd              超级服务器守护进程
luci-app-xlnetacc                      迅雷快鸟            迅雷网络加速
luci-app-zerotier                      ZeroTier            P2P虚拟局域网
```

---

## small8 Feed（kenzok8/small-package）

```
插件名                                  中文名              功能说明
─────────────────────────────────────────────────────────────────────────────────
luci-app-adguardhome                   AdGuard Home        DNS广告过滤/家长控制 [已启用]
luci-app-amlogic                       晶晨助手            晶晨盒子固件管理
luci-app-cloudflarespeedtest           CF优选              Cloudflare IP测速优选
luci-app-cupsd                         CUPS打印            CUPS打印服务管理 [已启用]
luci-app-ddns-go                       DDNS-Go             新一代动态DNS客户端 [已启用]
luci-app-easytier                      EasyTier            去中心化组网工具 [已启用]
luci-app-homeproxy                     HomeProxy           sing-box图形界面 [已启用]
luci-app-istorex                       iStoreX             iStore应用商店扩展 [已禁用]
luci-app-lucky                         Lucky               动态域名/端口转发/反代 [已启用]
luci-app-mosdns                        MosDNS              DNS分流/防污染 [已禁用]
luci-app-msd_lite                      组播转单播          IPTV组播转HTTP单播
luci-app-oaf                           应用过滤            网络应用识别过滤 [已启用]
luci-app-openclash                     OpenClash           Clash图形管理界面 [已启用]
luci-app-quickstart                    快速开始            iStore快速配置向导 [已禁用]
luci-app-store                         iStore商店          软件应用商店 [已禁用]
luci-app-tailscale                     Tailscale           WireGuard组网工具
```

---

## nikki Feed（nikkinikki-org/OpenWrt-nikki）

```
插件名                                  中文名              功能说明
─────────────────────────────────────────────────────────────────────────────────
luci-app-nikki                         Nikki/Mihomo        Mihomo代理核心管理 [已启用]
```

---

## passwall Feed（官方 Passwall）

```
插件名                                  中文名              功能说明
─────────────────────────────────────────────────────────────────────────────────
luci-app-passwall                      Passwall            科学上网工具 [已禁用]
```

---

## routing Feed（官方路由协议）

```
插件名                                  中文名              功能说明
─────────────────────────────────────────────────────────────────────────────────
luci-app-cjdns                         CJDNS               加密IPv6网状网络
```

---

## 其他独立 Feed

```
插件名                                  中文名              功能说明
─────────────────────────────────────────────────────────────────────────────────
luci-app-bandix                        Bandix              网络带宽监控(独立Feed)
```

---

## 自定义添加（package目录）

```
插件名                                  中文名              功能说明
─────────────────────────────────────────────────────────────────────────────────
luci-app-timecontrol                   上网时间控制        按设备/时间段控制上网 [已启用]
luci-app-quickfile                     快速文件            Nginx文件共享服务 [已启用]
```

---

## 当前固件已启用插件汇总（28个）

### 代理工具
- `luci-app-nikki` - Mihomo代理核心管理
- `luci-app-openclash` - Clash图形管理界面
- `luci-app-homeproxy` - sing-box图形界面

### DNS/广告过滤
- `luci-app-adguardhome` - DNS广告过滤/家长控制
- `luci-app-smartdns` - 智能DNS解析加速

### 网络工具
- `luci-app-ddns-go` - 新一代动态DNS客户端 (DDNS-Go)
- `luci-app-ddns` - 官方动态DNS客户端
- `luci-app-cloudflared` - Cloudflare零信任隧道
- `luci-app-easytier` - 去中心化组网工具
- `luci-app-frpc` - 内网穿透客户端
- `luci-app-lucky` - 动态域名/端口转发/反代
- `luci-app-sqm` - 智能队列管理/降延迟
- `luci-app-upnp` - 自动端口映射
- `luci-app-wol` - Wake-on-LAN网络唤醒
- `luci-app-pbr` - 基于策略的路由
- `luci-app-oaf` - 网络应用识别过滤

### 系统管理
- `luci-app-dockerman` - Docker容器管理
- `luci-app-diskman` - 硬盘分区/格式化/挂载
- `luci-app-ttyd` - Web SSH终端
- `luci-app-autoreboot` - 计划任务自动重启
- `luci-app-package-manager` - opkg包管理界面

### 文件共享
- `luci-app-samba4` - Windows文件共享
- `luci-app-quickfile` - Nginx文件共享服务
- `luci-app-cupsd` - CUPS打印服务管理
- `luci-app-vsftpd` - VSFTPD FTP服务器

### 其他
- `luci-app-vlmcsd` - 微软KMS激活服务
- `luci-app-firewall` - 防火墙规则管理
- `luci-app-timecontrol` - 按设备/时间段控制上网

---

## 如何启用其他插件

1. 编辑 `wrt_core/deconfig/jdcloud_er1_libwrt.config`
2. 添加配置行：`CONFIG_PACKAGE_luci-app-xxx=y`
3. 如需中文：`CONFIG_PACKAGE_luci-i18n-xxx-zh-cn=y`
4. 提交并触发编译

---

*文档生成时间：2026-03-03*
