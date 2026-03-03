# Nikki (Mihomo) 混入配置优化指南

本文档记录了 Nikki 代理工具的推荐优化配置。

## 已写入编译脚本（自动生效）

以下配置已通过编译脚本自动设置，无需手动修改：

### 1. GeoIP 下载地址
- **原地址**：`https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country-lite.mmdb`
- **代理地址**：`https://gh-proxy.com/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country-lite.mmdb`
- **说明**：解决国内无法直连 GitHub 的问题

### 2. UI (zashboard) 下载地址
- **原地址**：`https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip`
- **代理地址**：`https://gh-proxy.com/https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip`
- **说明**：解决国内无法直连 GitHub 导致面板 404 问题

---

## 需要手动配置的优化项

导入订阅配置后，在 **LuCI → 服务 → Nikki → Mixin 设置** 中进行以下配置：

### 混入选项 - 全局配置

| 配置项 | 默认值 | 推荐值 | 说明 |
|--------|--------|--------|------|
| **TCP 模式** | Redirect | **TProxy** | 支持 IPv6 透明代理 |
| **DNS 模式** | Fake-IP | **Redir-Host** | 可 ping 真实 IP，域名分流更准确 |
| **嗅探器** | 关闭 | **启用** | 启用域名嗅探 |
| **嗅探 Redir-Host 流量** | 关闭 | **启用** | 配合 Redir-Host 模式使用 |
| **绕过中国大陆 IP** | 关闭 | **启用** | 国内 IP 直连，减少代理负载 |
| **绕过中国大陆 IP6** | 关闭 | **启用** | IPv6 国内直连 |
| **统一延迟** | 关闭 | **启用** | 负载均衡更公平 |
| **TCP 并发** | 关闭 | **启用** | Clash Meta 特性，提升多节点性能 |

### 保持默认的配置项（无需修改）

- **日志等级**：warning
- **模式**：规则模式
- **匹配进程**：off（避免性能损耗）
- **出站接口**：不修改（单 WAN 口无需指定）
- **IPv6**：启用
- **TCP Keep Alive**：不修改

---

## 配置步骤

1. 打开 LuCI 管理界面
2. 进入 **服务 → Nikki**
3. 在 **配置文件** 标签页导入订阅
4. 切换到 **Mixin 设置** 标签页
5. 按上表进行配置
6. 点击 **保存并应用**
7. 启动 Nikki 服务

---

*文档更新时间：2026-03-03*
