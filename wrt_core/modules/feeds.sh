#!/usr/bin/env bash

# ── Feed 版本锁定 ──────────────────────────────────────────────
FEED_LOCKS_FILE="$BASE_PATH/feed_locks.ini"

# 检查锁文件是否有有效条目
has_feed_locks() {
    [ -f "$FEED_LOCKS_FILE" ] && grep -qE '^[a-z_]+=[0-9a-f]{7,}' "$FEED_LOCKS_FILE" 2>/dev/null
}

# 将锁定的 commit hash 注入 feeds.conf (src-git ^HASH 语法)
apply_feed_locks() {
    local feeds_path="$1"
    [ -f "$FEED_LOCKS_FILE" ] || return 0
    has_feed_locks || return 0

    if [ "${UPDATE_FEEDS:-0}" = "1" ]; then
        echo "[Feed Lock] UPDATE_FEEDS=1, 跳过锁定，拉取最新"
        return 0
    fi

    echo "[Feed Lock] 应用 feed 版本锁定..."
    while IFS='=' read -r name hash; do
        # 跳过注释和空行
        [[ "$name" =~ ^[[:space:]]*# ]] && continue
        name=$(echo "$name" | xargs)
        hash=$(echo "$hash" | xargs)
        [ -z "$name" ] || [ -z "$hash" ] && continue

        # small8 是 src-link，不在 feeds.conf 中锁定 (在 prepare_small8_feed 中处理)
        [ "$name" = "small8" ] && continue

        # 对 src-git/src-git-full 行追加 ^HASH
        if grep -qE "^src-git(-full)?[[:space:]]+${name}[[:space:]]" "$feeds_path"; then
            # 先移除已有的 ^hash，再追加新的
            sed -i "s|^\(src-git\(-full\)\?[[:space:]]\+${name}[[:space:]]\+[^[:space:]]*\)\^[0-9a-f]*|\1|" "$feeds_path"
            sed -i "s|^\(src-git\(-full\)\?[[:space:]]\+${name}[[:space:]]\+[^[:space:]]*\)|\1^${hash}|" "$feeds_path"
            echo "  锁定: ${name} -> ${hash:0:12}"
        fi
    done < "$FEED_LOCKS_FILE"
}

# 构建成功后保存各 feed 的当前 commit hash
save_feed_locks() {
    local tmp_lock="${FEED_LOCKS_FILE}.tmp"

    echo "[Feed Lock] 保存 feed 版本快照..."
    {
        echo "# Feed 版本锁定 — 自动生成于 $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# 格式: feed_name=commit_hash"
        echo "# 留空值或删除行 → 该 feed 使用最新版本"
        echo "# 首次构建自动生成，之后每次构建使用锁定版本"
        echo "# 手动触发 CI 并勾选 \"Update Feeds\" 可更新到最新并重新锁定"
    } > "$tmp_lock"

    # 遍历 feeds 目录获取 git commit
    for dir in "$BUILD_DIR"/feeds/*/; do
        [ -d "$dir" ] || continue
        local name
        name=$(basename "$dir")
        [[ "$name" == *.tmp ]] && continue
        [[ "$name" == *.index ]] && continue
        [[ "$name" == *.targetindex ]] && continue
        # src-link feeds 是符号链接目录，跟踪实际 .git
        local git_dir="$dir"
        [ -L "$dir" ] && git_dir=$(readlink -f "$dir")
        if [ -d "$git_dir/.git" ]; then
            local hash
            hash=$(git -C "$git_dir" rev-parse HEAD 2>/dev/null)
            if [ -n "$hash" ]; then
                echo "${name}=${hash}" >> "$tmp_lock"
                echo "  ${name} = ${hash:0:12}"
            fi
        fi
    done

    mv "$tmp_lock" "$FEED_LOCKS_FILE"
    echo "[Feed Lock] 已保存到 $FEED_LOCKS_FILE"
}

# ── Small8 Feed ────────────────────────────────────────────────
prepare_small8_feed() {
    local local_feeds_root="$BUILD_DIR/.customfeeds"
    local local_small8_dir="$local_feeds_root/small8"
    local small8_repos=(
        "https://github.com/kenzok8/jell.git"
        "https://github.com/kenzok8/small-package.git"
        "https://gitee.com/aiyboy/small-package.git"
    )

    # 读取 small8 锁定的 commit hash
    local locked_hash=""
    if [ "${UPDATE_FEEDS:-0}" != "1" ] && [ -f "$FEED_LOCKS_FILE" ]; then
        locked_hash=$(awk -F'=' '/^small8=/ {print $2}' "$FEED_LOCKS_FILE" | xargs)
    fi

    mkdir -p "$local_feeds_root"
    rm -rf "$local_small8_dir"

    for repo in "${small8_repos[@]}"; do
        echo "正在准备 small8 feed: $repo"
        if [ -n "$locked_hash" ]; then
            # 锁定模式: 完整 clone 后 checkout 到指定 commit
            if git clone --single-branch "$repo" "$local_small8_dir"; then
                if git -C "$local_small8_dir" checkout "$locked_hash" 2>/dev/null; then
                    echo "small8 feed 锁定到: ${locked_hash:0:12}"
                    return 0
                fi
                echo "small8 锁定 commit $locked_hash 不存在于 $repo，回退到最新" >&2
                rm -rf "$local_small8_dir"
                # 回退到浅克隆最新
                if git clone --depth 1 --single-branch "$repo" "$local_small8_dir"; then
                    echo "small8 feed 准备完成 (最新): $repo"
                    return 0
                fi
            fi
        else
            if git clone --depth 1 --single-branch "$repo" "$local_small8_dir"; then
                echo "small8 feed 准备完成: $repo"
                return 0
            fi
        fi
        echo "small8 feed 拉取失败，尝试下一个源: $repo" >&2
        rm -rf "$local_small8_dir"
    done

    echo "Error: failed to prepare small8 feed from all configured sources" >&2
    exit 1
}

update_feeds() {
    local FEEDS_PATH="$BUILD_DIR/$FEEDS_CONF"
    local LOCAL_SMALL8_DIR="$BUILD_DIR/.customfeeds/small8"
    if [[ -f "$BUILD_DIR/feeds.conf" ]]; then
        FEEDS_PATH="$BUILD_DIR/feeds.conf"
    fi

    prepare_small8_feed

    sed -i '/^#/d' "$FEEDS_PATH"
    sed -i '/packages_ext/d' "$FEEDS_PATH"
    sed -i '/^src-git small8 /d' "$FEEDS_PATH"
    sed -i '/^src-link small8 /d' "$FEEDS_PATH"

    [ -z "$(tail -c 1 "$FEEDS_PATH")" ] || echo "" >>"$FEEDS_PATH"
    echo "src-link small8 $LOCAL_SMALL8_DIR" >>"$FEEDS_PATH"

    if ! grep -q "openwrt-passwall" "$FEEDS_PATH"; then
        [ -z "$(tail -c 1 "$FEEDS_PATH")" ] || echo "" >>"$FEEDS_PATH"
        echo "src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall;main" >>"$FEEDS_PATH"
    fi

    # 添加 nikki (Mihomo) feed
    if ! grep -q "nikkinikki-org" "$FEEDS_PATH"; then
        [ -z "$(tail -c 1 "$FEEDS_PATH")" ] || echo "" >>"$FEEDS_PATH"
        echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >>"$FEEDS_PATH"
    fi

    if ! grep -q "openwrt_bandix" "$FEEDS_PATH"; then
        [ -z "$(tail -c 1 "$FEEDS_PATH")" ] || echo "" >>"$FEEDS_PATH"
        echo 'src-git openwrt_bandix https://github.com/timsaya/openwrt-bandix.git;main' >>"$FEEDS_PATH"
    fi

    if ! grep -q "luci_app_bandix" "$FEEDS_PATH"; then
        [ -z "$(tail -c 1 "$FEEDS_PATH")" ] || echo "" >>"$FEEDS_PATH"
        echo 'src-git luci_app_bandix https://github.com/timsaya/luci-app-bandix.git;main' >>"$FEEDS_PATH"
    fi

    if [ ! -f "$BUILD_DIR/include/bpf.mk" ]; then
        touch "$BUILD_DIR/include/bpf.mk"
    fi

    # 应用 feed 版本锁定
    apply_feed_locks "$FEEDS_PATH"

    echo "[Feeds] feeds.conf 最终内容:"
    cat "$FEEDS_PATH"
    echo "---"

    ./scripts/feeds update -a

    if [ ! -d "$BUILD_DIR/feeds/small8" ]; then
        echo "Error: feeds/small8 was not created after feeds update" >&2
        exit 1
    fi
}

install_nikki() {
    echo "正在从 nikki 仓库安装 nikki 和 luci-app-nikki..."
    ./scripts/feeds install -p nikki -f nikki luci-app-nikki
}

install_feeds() {
    ./scripts/feeds update -i
    for dir in $BUILD_DIR/feeds/*; do
        if [ -d "$dir" ] && [[ ! "$dir" == *.tmp ]] && [[ ! "$dir" == *.index ]] && [[ ! "$dir" == *.targetindex ]]; then
            if [[ $(basename "$dir") == "small8" ]]; then
                install_small8
                install_fullconenat
            elif [[ $(basename "$dir") == "passwall" ]]; then
                install_passwall
            elif [[ $(basename "$dir") == "nikki" ]]; then
                install_nikki
            else
                ./scripts/feeds install -f -ap $(basename "$dir")
            fi
        fi
    done
}
