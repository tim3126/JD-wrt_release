#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANCH="taiyi1"
DEVICE="jdcloud_er1_immwrt"
SESSION="wrt_er1"
STATE_DIR="$REPO_DIR/.remote-build"
LAST_LOG="$STATE_DIR/${SESSION}.lastlog"
LAST_EXIT="$STATE_DIR/${SESSION}.exitcode"
CMD="${1:-start}"

mkdir -p "$STATE_DIR"

sync_line_endings() {
    cd "$REPO_DIR"
    dos2unix \
      build.sh \
      wrt_core/update.sh \
      wrt_core/modules/*.sh \
      wrt_core/deconfig/jdcloud_er1_immwrt.config \
      wrt_core/patches/cpuusage \
      wrt_core/patches/tempinfo \
      wrt_core/patches/hnatusage \
      wrt_core/patches/smp_affinity \
      wrt_core/patches/990_set_argon_primary \
      wrt_core/patches/991_custom_settings \
      wrt_core/patches/992_set-wifi-uci.sh \
      wrt_core/patches/pbr.user.cmcc \
      wrt_core/patches/pbr.user.cmcc6 >/dev/null 2>&1 || true
    find "$REPO_DIR" -type f -name '*.sh' -exec chmod +x {} +
}

start_build() {
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "编译会话已存在: $SESSION"
        echo "可执行: ./taiyi1_er1.sh attach"
        exit 1
    fi

    cd "$REPO_DIR"
    git fetch origin "$BRANCH"
    git checkout "$BRANCH"
    git reset --hard "origin/$BRANCH"

    sync_line_endings

    local log_path="$REPO_DIR/build_${DEVICE}_$(date +%F_%H-%M-%S).log"
    printf '%s\n' "$log_path" > "$LAST_LOG"
    rm -f "$LAST_EXIT"

    cat > "$STATE_DIR/${SESSION}.run.sh" <<EOF
#!/usr/bin/env bash
set -o pipefail
cd "$REPO_DIR"
./build.sh "$DEVICE" 2>&1 | tee "$log_path"
rc=\${PIPESTATUS[0]}
printf '%s\n' "\$rc" > "$LAST_EXIT"
exit "\$rc"
EOF
    chmod +x "$STATE_DIR/${SESSION}.run.sh"

    tmux new-session -d -s "$SESSION" "$STATE_DIR/${SESSION}.run.sh"

    echo "已启动编译会话: $SESSION"
    echo "日志文件: $log_path"
    echo "查看界面: ./taiyi1_er1.sh attach"
    echo "查看状态: ./taiyi1_er1.sh status"
    echo "查看日志: ./taiyi1_er1.sh log"
}

show_status() {
    cd "$REPO_DIR"
    echo "仓库: $REPO_DIR"
    echo "分支: $(git branch --show-current)"
    echo "提交: $(git rev-parse --short HEAD)"
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "会话状态: 运行中 [$SESSION]"
    else
        echo "会话状态: 未运行"
    fi

    if [ -f "$LAST_LOG" ]; then
        local log_path
        log_path="$(cat "$LAST_LOG")"
        echo "最近日志: $log_path"
        if [ -f "$log_path" ]; then
            stat -c '日志时间: %y  大小: %s bytes' "$log_path"
            tail -n 30 "$log_path"
        fi
    fi

    if [ -f "$LAST_EXIT" ]; then
        echo "最近退出码: $(cat "$LAST_EXIT")"
    fi
}

attach_session() {
    exec tmux attach -t "$SESSION"
}

follow_log() {
    if [ ! -f "$LAST_LOG" ]; then
        echo "没有找到最近日志记录"
        exit 1
    fi

    local log_path
    log_path="$(cat "$LAST_LOG")"
    if [ ! -f "$log_path" ]; then
        echo "日志文件不存在: $log_path"
        exit 1
    fi

    exec tail -f "$log_path"
}

stop_build() {
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux kill-session -t "$SESSION"
        echo "已停止会话: $SESSION"
    else
        echo "会话不存在: $SESSION"
    fi
}

case "$CMD" in
    start)
        start_build
        ;;
    attach)
        attach_session
        ;;
    status)
        show_status
        ;;
    log)
        follow_log
        ;;
    stop)
        stop_build
        ;;
    *)
        echo "用法: ./taiyi1_er1.sh {start|attach|status|log|stop}"
        exit 1
        ;;
esac
