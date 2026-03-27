# Maintim 编译说明

`maintim` 使用叠加式入口，尽量减少后续从 `main` 合并时反复修改上游热点文件。

## 本地编译

在 WSL 中进入仓库目录后执行：

```bash
./build_maintim.sh jdcloud_er1_libwrt
```

固件输出目录：

```text
/home/tim/src/JD-wrt_release/firmware
```

为了方便从 Windows 访问，已经额外提供了一个软链接：

```text
/home/tim/firmware
```

Windows 资源管理器可直接打开：

```text
\\wsl.localhost\Ubuntu\home\tim\firmware
```

## 自动同步到 WSL

单次同步：

```powershell
powershell -ExecutionPolicy Bypass -File .\sync_to_wsl.ps1
```

启动监听，同步但不自动编译：

```powershell
powershell -ExecutionPolicy Bypass -File .\start_watch_sync_to_wsl.ps1
```

启动监听，同步后自动触发 WSL 增量编译：

```powershell
powershell -ExecutionPolicy Bypass -File .\start_watch_sync_build_to_wsl.ps1
```

## GitHub Actions

Maintim 固件应使用以下 workflow：

- `.github/workflows/build_maintim.yml`
- `.github/workflows/release_maintim.yml`

不要使用旧的 `release_wrt.yml`，它走的是上游通用入口 `build.sh`，不是 maintim 专用构建链。

## 维护原则

以下文件尽量保持贴近上游：

- `build.sh`
- `wrt_core/update.sh`
- `wrt_core/modules/*.sh`

Maintim 自定义修复集中放在：

- `wrt_core/local/`
