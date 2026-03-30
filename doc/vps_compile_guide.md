# VPS 编译与查看说明

本文档记录 `JD-wrt_release` 在远程 VPS 上的常用编译命令、`tmux` 查看方式，以及以后手动拉取 `taiyi1` 最新代码后自动编译的方法。

## 一、连接 VPS

```bash
ssh -p 22103 user@149.56.29.191
```

登录后进入仓库：

```bash
cd ~/JD-wrt_release
```

## 二、当前编译会话查看

当前默认使用的 `tmux` 会话名是：

```bash
wrt_er1
```

直接进入编译界面：

```bash
tmux attach -t wrt_er1
```

或者使用仓库脚本进入：

```bash
cd ~/JD-wrt_release
./taiyi1_er1.sh attach
```

## 三、退出编译界面但不停止编译

进入 `tmux` 后，如果只想退出查看界面、让编译继续在后台跑：

```bash
Ctrl+b d
```

这不会中断编译。

## 四、查看当前有哪些 tmux 会话

```bash
tmux ls
```

如果看到类似：

```bash
wrt_er1: 1 windows
```

说明编译会话还在。

## 五、只看编译日志，不进入 tmux

```bash
cd ~/JD-wrt_release
./taiyi1_er1.sh log
```

查看当前状态：

```bash
cd ~/JD-wrt_release
./taiyi1_er1.sh status
```

## 六、以后手动拉取最新 taiyi1 并自动编译

如果以后本地已经把修改提交并推送到远程 `taiyi1`，在 VPS 上只需要执行：

```bash
cd ~/JD-wrt_release
git pull
chmod +x ./taiyi1_er1.sh
./taiyi1_er1.sh start
```

更推荐直接只使用脚本：

```bash
cd ~/JD-wrt_release
./taiyi1_er1.sh start
```

`start` 会自动完成这些事情：

1. `fetch origin taiyi1`
2. `checkout taiyi1`
3. `reset --hard origin/taiyi1`
4. 修正常用脚本换行和执行权限
5. 启动 `tmux` 会话 `wrt_er1`
6. 执行：

```bash
./build.sh jdcloud_er1_immwrt
```

## 七、手动重启一轮编译

如果上一轮已经结束，或者你想明确重开一轮：

```bash
cd ~/JD-wrt_release
./taiyi1_er1.sh stop
./taiyi1_er1.sh start
```

如果当前没有会话，`stop` 提示不存在也没关系。

## 八、关闭 SSH 会不会影响编译

不会。

因为编译是运行在远程 `tmux` 会话里的，不依赖当前 SSH 窗口持续保持连接。

建议做法：

1. 如果你当前在 `tmux` 里，先按：

```bash
Ctrl+b d
```

2. 再关闭 SSH

之后重新登录 VPS，仍然可以继续查看：

```bash
cd ~/JD-wrt_release
./taiyi1_er1.sh attach
```

## 九、最常用命令汇总

进入编译界面：

```bash
tmux attach -t wrt_er1
```

退出界面但不停编译：

```bash
Ctrl+b d
```

查看会话：

```bash
tmux ls
```

查看日志：

```bash
cd ~/JD-wrt_release
./taiyi1_er1.sh log
```

查看状态：

```bash
cd ~/JD-wrt_release
./taiyi1_er1.sh status
```

启动最新 `taiyi1` 编译：

```bash
cd ~/JD-wrt_release
./taiyi1_er1.sh start
```

停止当前编译：

```bash
cd ~/JD-wrt_release
./taiyi1_er1.sh stop
```
