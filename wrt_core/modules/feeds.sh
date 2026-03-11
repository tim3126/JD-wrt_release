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
        name=$(echo "$name" | tr -d '\r' | xargs)
        hash=$(echo "$hash" | tr -d '\r' | xargs)
        [ -z "$name" ] || [ -z "$hash" ] && continue

        # small8 是 src-link，不在 feeds.conf 中锁定 (在 prepare_small8_feed 中处理)
        [ "$name" = "small8" ] && continue

        # 对 src-git/src-git-full 行追加 ^HASH
        # 注意: OpenWrt feeds 格式为 url^hash，不能有 ;branch
        # 如果 URL 含 ;branch，必须先去掉 ;branch 再追加 ^hash
        if grep -qE "^src-git(-full)?[[:space:]]+${name}[[:space:]]" "$feeds_path"; then
            # 1) 移除已有的 ^hash
            sed -i "s|^\(src-git\(-full\)\?[[:space:]]\+${name}[[:space:]]\+[^[:space:]]*\)\^[0-9a-f]*|\1|" "$feeds_path"
            # 2) 移除 ;branch 后缀（如 ;main, ;master 等）
            sed -i "s|^\(src-git\(-full\)\?[[:space:]]\+${name}[[:space:]]\+[^;[:space:]]*\);[^[:space:]]*|\1|" "$feeds_path"
            # 3) 追加 ^hash
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


    if [ ! -f "$BUILD_DIR/include/bpf.mk" ]; then
        touch "$BUILD_DIR/include/bpf.mk"
    fi

    # 应用 feed 版本锁定
    apply_feed_locks "$FEEDS_PATH"

    echo "[Feeds] feeds.conf 最终内容:"
    cat "$FEEDS_PATH"
    echo "---"

    # ── 逐个更新 feed，可选 feed 失败时自动跳过 ──
    local OPTIONAL_FEEDS=("passwall" "nikki")
    local MAX_RETRIES=3
    local RETRY_DELAY=5
    local feed_names=()
    local failed_feeds=()

    # 从 feeds.conf 提取所有 feed 名称
    while IFS= read -r line; do
        local fname
        fname=$(echo "$line" | awk '{print $2}')
        [ -n "$fname" ] && feed_names+=("$fname")
    done < <(grep -E '^src-(git|git-full|link)' "$FEEDS_PATH")

    for fname in "${feed_names[@]}"; do
        echo "[Feeds] 更新 feed: $fname"
        local success=false
        for attempt in $(seq 1 $MAX_RETRIES); do
            if ./scripts/feeds update "$fname"; then
                echo "[Feeds] $fname 更新成功"
                success=true
                break
            fi
            if [ $attempt -lt $MAX_RETRIES ]; then
                echo "[Feeds] $fname 第 $attempt 次尝试失败，${RETRY_DELAY}s 后重试..." >&2
                # 清理可能残留的不完整目录
                rm -rf "$BUILD_DIR/feeds/$fname"
                sleep $RETRY_DELAY
            fi
        done

        if ! $success; then
            # 判断是否为可选 feed
            local is_optional=false
            for opt in "${OPTIONAL_FEEDS[@]}"; do
                [ "$fname" = "$opt" ] && is_optional=true && break
            done

            if $is_optional; then
                echo "[Feeds] WARNING: 可选 feed '$fname' 经 $MAX_RETRIES 次重试仍失败，从配置中移除并继续" >&2
                failed_feeds+=("$fname")
                rm -rf "$BUILD_DIR/feeds/$fname"
                sed -i "/^src-git\(-full\)\?[[:space:]]\+${fname}[[:space:]]/d" "$FEEDS_PATH"
            else
                echo "[Feeds] ERROR: 必需 feed '$fname' 更新失败" >&2
                exit 1
            fi
        fi
    done

    # 有 feed 被移除时重建索引
    if [ ${#failed_feeds[@]} -gt 0 ]; then
        echo "[Feeds] 以下可选 feed 未能获取: ${failed_feeds[*]}"
        echo "[Feeds] 重建索引..."
        ./scripts/feeds update -i
    fi

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
