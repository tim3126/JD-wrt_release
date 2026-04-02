# JD-wrt_release 项目知识与约定

本文档用于沉淀 [JD-wrt_release](/G:/wowcode/ctm/JD-wrt_release) 的项目级知识、长期约定与已确认问题，减少每次处理固件问题时重复排查。

说明：
- 本文档是项目知识文档，不替代上级 [AGENTS.md](/G:/wowcode/ctm/AGENTS.md)
- 规则判定仍以上级 [AGENTS.md](/G:/wowcode/ctm/AGENTS.md) 为准

## 当前主要目标

- 当前主要维护分支：`taiyi1`
- 当前主要设备：`jdcloud_er1_immwrt`
- 当前主要诉求：
  - 稳定可靠
  - 尽量缩短编译时间
  - 尽量减少后续从 `main` 合并时的冲突

## ER1 当前插件策略

以下是 `ER1` 当前明确保留或排除的方向，优先体现在设备配置文件中：

- 保留：
  - `AdGuardHome`
  - `ddns-go`
  - `nikki`
  - `homeproxy`
  - `uhttpd`
  - `bootstrap`
- 不重新带回：
  - `openclash`
  - `istorex`
  - `passwall`
  - `quickstart`
  - `argon`

当前设备配置落点：
- [wrt_core/deconfig/jdcloud_er1_immwrt.config](/G:/wowcode/ctm/JD-wrt_release/wrt_core/deconfig/jdcloud_er1_immwrt.config)

## 合并 main 的低冲突原则

后续处理 `taiyi1 <- main` 合并时，遵循以下原则：

1. 通用构建文件尽量贴近 `main`
- 重点文件：
  - [wrt_core/modules/feeds.sh](/G:/wowcode/ctm/JD-wrt_release/wrt_core/modules/feeds.sh)
  - [wrt_core/modules/packages.sh](/G:/wowcode/ctm/JD-wrt_release/wrt_core/modules/packages.sh)
  - [wrt_core/update.sh](/G:/wowcode/ctm/JD-wrt_release/wrt_core/update.sh)

2. 设备差异尽量收口到设备配置
- 主要放到：
  - [wrt_core/deconfig/jdcloud_er1_immwrt.config](/G:/wowcode/ctm/JD-wrt_release/wrt_core/deconfig/jdcloud_er1_immwrt.config)

3. 项目专属兜底逻辑尽量放在后置补丁层
- 例如：
  - [wrt_core/patches/991_custom_settings](/G:/wowcode/ctm/JD-wrt_release/wrt_core/patches/991_custom_settings)
  - [wrt_core/patches/993_ddns-go_config](/G:/wowcode/ctm/JD-wrt_release/wrt_core/patches/993_ddns-go_config)

4. 非必要不直接修改上游 feed 源码
- 特别是：
  - `OpenWrt-nikki`
  - `small8`
  - `luci`

## 已确认问题与结论

### 1. ddns-go 包已安装但菜单不显示

已确认根因：
- `luci-app-ddns-go` 菜单依赖 `uci` 配置存在
- 仅把包编进固件，不足以保证菜单显示

当前项目处理方式：
- 在固件中直接打入默认配置：
  - [wrt_core/patches/993_ddns-go_config](/G:/wowcode/ctm/JD-wrt_release/wrt_core/patches/993_ddns-go_config)
- 由：
  - [wrt_core/modules/system.sh](/G:/wowcode/ctm/JD-wrt_release/wrt_core/modules/system.sh)
  负责安装到 `/etc/config/ddns-go`

### 2. Nikki 控制面板默认值问题

已确认现象：
- 订阅下载文件中通常没有：
  - `external-ui`
  - `external-ui-name`
- 若运行中的最终配置缺少这两个字段，控制面板可能打不开

上游历史线索：
- `OpenWrt-nikki` 早期移除了默认 `ui_path`
- 后续又删掉了迁移脚本里的 `ui_path` 自动兜底

重要说明：
- 这里要区分“历史排查结论”和“当前分支现状”
- 我们曾经验证过一种有效的历史兜底方案：
  - `ui_path=./ui`
  - `ui_name=zashboard`
- 但**当前 `taiyi1` 分支并没有在 [wrt_core/patches/991_custom_settings](/G:/wowcode/ctm/JD-wrt_release/wrt_core/patches/991_custom_settings) 中保留这段 Nikki 兜底逻辑**
- 因此以后再排查时，不应默认认为当前固件仍然带有该兜底

当前建议：
- 若再次复现控制面板默认打不开，先检查运行配置是否存在：
  - `external-ui`
  - `external-ui-name`
- 再决定是否需要重新引入本地空值兜底

### 3. Nikki access control 行为问题

已确认：
- `OpenWrt-nikki` 上游 `6517464` 修复了 access control 的 DNS / PROXY 行为
- 该修复位于：
  - `nikki/files/ucode/hijack.ut`
- 当前 `JD-wrt_release` 构建链会跟随 Nikki feed 的 `main`
- 只要 `feeds update` 正常执行，重新编译通常就会自然吃到该修复

当前分支结论：
- 访问控制问题优先信上游修复
- 当前项目中**没有**额外保留本地 access control 兜底逻辑

### 4. 通过 Cloudflare 零信任隧道远程打开 LuCI 正常，但 zashboard 打不开

已确认结论：
- 这通常不是 `nikki` 固件没带上
- 主因是 `zashboard` 依赖 `Mihomo API` 监听端口，默认是 `9090`
- 远程访问 LuCI 成功，只说明 Cloudflare 隧道代理了 LuCI
- 不代表同一条隧道已经代理了 `9090`

上游前端生成链接的位置：
- [OpenWrt-nikki/luci-app-nikki/htdocs/luci-static/resources/tools/nikki.js](/G:/wowcode/ctm/OpenWrt-nikki/luci-app-nikki/htdocs/luci-static/resources/tools/nikki.js)

关键行为：
- 前端会拼出：
  - `http(s)://<当前访问主机>:9090/ui/...`
- 因此远程场景下，若 Cloudflare 只代理了 LuCI 的 `80/443`，而没有代理 `9090`，则 `zashboard` 无法打开

这类问题优先排查：
1. `nikki` 的 `external-controller` 是否已启用
2. `9090` 是否可从远程访问
3. Cloudflare Tunnel 是否单独暴露了 `9090` 服务，或是否已由反向代理转发

## 远程 VPS 编译约定

当前主要脚本：
- [taiyi1_er1.sh](/G:/wowcode/ctm/JD-wrt_release/taiyi1_er1.sh)

默认会话名：
- `wrt_er1`

更完整的 VPS 说明：
- [doc/vps_compile_guide.md](/G:/wowcode/ctm/JD-wrt_release/doc/vps_compile_guide.md)

## 后续新增规则时的维护建议

后续如果再遇到：
- 固件插件默认行为问题
- 远程编译 / 增量编译问题
- `nikki` / `ddns-go` / `cloudflared` 类长期问题

优先把最终结论补到本文档，不要只留在聊天记录里。
