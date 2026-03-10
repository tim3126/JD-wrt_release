# TimeControl LuCI 状态显示"未运行"修复

## 问题现象
LuCI 时间控制页面始终显示"TimeControl Service ✗ NOT RUNNING"，
即使 `timecontrolctrl` 进程实际在运行。

## 根因
rpcd 的 `file.exec` 权限检查需要**同时满足两个条件**：
1. `ubus` 方法权限: `"ubus": {"file": ["exec"]}` ✅ 上游已有
2. 命令路径白名单: `"file": {"/bin/ps": ["exec"]}` ❌ 上游缺失

LuCI 前端 `basic.js` 通过 `fs.exec('/bin/ps', ['w'])` 检查进程，
因为缺少第2条，rpcd 返回 PermissionError，前端 catch 后显示未运行。

## SSH 手动修复

```sh
cat > /usr/share/rpcd/acl.d/luci-app-timecontrol.json << 'EOF'
{
   "luci-app-timecontrol": {
        "description": "Grant UCI Internet time control for luci-app-timecontrol",
        "read": {
            "file": {
                "/bin/ps": ["exec"],
                "/bin/ps w": ["exec"]
            },
            "ubus": {
                "file": ["exec", "list", "stat", "read"],
                "uci": [ "*" ],
                "timecontrol": ["*"]
            }
        },
        "write": {
            "ubus": {
                "timecontrol": ["*"],
                "file": ["write"],
                "uci": ["*"]
            }
        }
    }
}
EOF

# 重启 rpcd 使 ACL 生效
killall rpcd; sleep 1; /etc/init.d/rpcd start
```

修复后**注销 LuCI 重新登录**（需要创建新 session 加载新 ACL）。

## 首次启用 TimeControl

如果从未手动启用过该服务，还需要：
```sh
uci set timecontrol.@timecontrol[0].enabled='1'
uci commit timecontrol
/etc/init.d/timecontrol enable
/etc/init.d/timecontrol restart
```

## 验证

浏览器 F12 → Console 执行：
```js
L.require('fs').then(function(fs) {
  fs.exec('/bin/ps', ['w']).then(function(res) {
    console.log('code:', res.code, 'found:', res.stdout.includes('timecontrolctrl'));
  }).catch(function(e) { console.log('exec failed:', e); })
})
```
- 修复前: `exec failed: PermissionError`
- 修复后: `code: 0 found: true`
