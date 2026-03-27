#!/usr/bin/env bash

source "$SCRIPT_DIR/modules/_helpers.sh"
source "$SCRIPT_DIR/../modules/feeds.sh"

FEED_LOCKS_FILE="$BASE_PATH/feed_locks.ini"

has_feed_locks() {
    [ -f "$FEED_LOCKS_FILE" ] && grep -qE '^[a-z_]+=[0-9a-f]{7,}' "$FEED_LOCKS_FILE" 2>/dev/null
}

apply_feed_locks() {
    local feeds_path="$1"

    [ -f "$FEED_LOCKS_FILE" ] || return 0
    has_feed_locks || return 0

    if [ "${UPDATE_FEEDS:-0}" = "1" ]; then
        echo "[Feed Lock] UPDATE_FEEDS=1, skip lock and pull latest feeds"
        return 0
    fi

    while IFS='=' read -r name hash; do
        [[ "$name" =~ ^[[:space:]]*# ]] && continue
        name=$(echo "$name" | tr -d '\r' | xargs)
        hash=$(echo "$hash" | tr -d '\r' | xargs)
        [ -z "$name" ] || [ -z "$hash" ] && continue
        [ "$name" = "small8" ] && continue

        if grep -qE "^src-git(-full)?[[:space:]]+${name}[[:space:]]" "$feeds_path"; then
            sed -i "s|^\(src-git\(-full\)\?[[:space:]]\+${name}[[:space:]]\+[^[:space:]]*\)\^[0-9a-f]*|\1|" "$feeds_path"
            sed -i "s|^\(src-git\(-full\)\?[[:space:]]\+${name}[[:space:]]\+[^;[:space:]]*\);[^[:space:]]*|\1|" "$feeds_path"
            sed -i "s|^\(src-git\(-full\)\?[[:space:]]\+${name}[[:space:]]\+[^[:space:]]*\)|\1^${hash}|" "$feeds_path"
        fi
    done < "$FEED_LOCKS_FILE"
}

save_feed_locks() {
    local tmp_lock="${FEED_LOCKS_FILE}.tmp"

    {
        echo "# Feed lock snapshot generated on $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Format: feed_name=commit_hash"
    } > "$tmp_lock"

    for dir in "$BUILD_DIR"/feeds/*/; do
        [ -d "$dir" ] || continue

        local name
        local git_dir
        local hash

        name=$(basename "$dir")
        [[ "$name" == *.tmp ]] && continue
        [[ "$name" == *.index ]] && continue
        [[ "$name" == *.targetindex ]] && continue

        git_dir="$dir"
        [ -L "$dir" ] && git_dir=$(readlink -f "$dir")

        if [ -d "$git_dir/.git" ]; then
            hash=$(git -C "$git_dir" rev-parse HEAD 2>/dev/null)
            [ -n "$hash" ] && echo "${name}=${hash}" >> "$tmp_lock"
        fi
    done

    mv "$tmp_lock" "$FEED_LOCKS_FILE"
}

prepare_small8_feed() {
    local local_feeds_root="$BUILD_DIR/.customfeeds"
    local local_small8_dir="$local_feeds_root/small8"
    local small8_repos=(
        "https://github.com/kenzok8/jell.git"
        "https://github.com/kenzok8/small-package.git"
        "https://gitee.com/aiyboy/small-package.git"
    )
    local locked_hash=""

    if [ "${UPDATE_FEEDS:-0}" != "1" ] && [ -f "$FEED_LOCKS_FILE" ]; then
        locked_hash=$(awk -F'=' '/^small8=/ {print $2}' "$FEED_LOCKS_FILE" | xargs)
    fi

    mkdir -p "$local_feeds_root"
    rm -rf "$local_small8_dir"

    for repo in "${small8_repos[@]}"; do
        echo "Preparing small8 feed from $repo"

        if [ -n "$locked_hash" ]; then
            if git clone --single-branch "$repo" "$local_small8_dir"; then
                if git -C "$local_small8_dir" checkout "$locked_hash" 2>/dev/null; then
                    return 0
                fi
                rm -rf "$local_small8_dir"
                if git clone --depth 1 --single-branch "$repo" "$local_small8_dir"; then
                    return 0
                fi
            fi
        else
            if git clone --depth 1 --single-branch "$repo" "$local_small8_dir"; then
                return 0
            fi
        fi

        rm -rf "$local_small8_dir"
    done

    echo "Error: failed to prepare small8 feed" >&2
    exit 1
}

update_feeds() {
    local feeds_path="$BUILD_DIR/$FEEDS_CONF"
    local local_small8_dir="$BUILD_DIR/.customfeeds/small8"
    local optional_feeds=("passwall" "nikki")
    local max_retries=3
    local retry_delay=5
    local failed_feeds=()

    if [[ -f "$BUILD_DIR/feeds.conf" ]]; then
        feeds_path="$BUILD_DIR/feeds.conf"
    fi

    prepare_small8_feed

    sed -i '/^#/d' "$feeds_path"
    sed -i '/packages_ext/d' "$feeds_path"
    sed -i '/^src-git small8 /d' "$feeds_path"
    sed -i '/^src-link small8 /d' "$feeds_path"
    sed -i '/^src-git openwrt_bandix /d' "$feeds_path"
    sed -i '/^src-git luci_app_bandix /d' "$feeds_path"

    [ -z "$(tail -c 1 "$feeds_path")" ] || echo "" >>"$feeds_path"
    echo "src-link small8 $local_small8_dir" >>"$feeds_path"

    if ! grep -q "openwrt-passwall" "$feeds_path"; then
        [ -z "$(tail -c 1 "$feeds_path")" ] || echo "" >>"$feeds_path"
        echo "src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall;main" >>"$feeds_path"
    fi

    if ! grep -q "nikkinikki-org" "$feeds_path"; then
        [ -z "$(tail -c 1 "$feeds_path")" ] || echo "" >>"$feeds_path"
        echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >>"$feeds_path"
    fi

    if [ ! -f "$BUILD_DIR/include/bpf.mk" ]; then
        touch "$BUILD_DIR/include/bpf.mk"
    fi

    apply_feed_locks "$feeds_path"

    while IFS= read -r line; do
        local feed_name
        local success=false
        local is_optional=false

        feed_name=$(echo "$line" | awk '{print $2}')
        [ -n "$feed_name" ] || continue

        for attempt in $(seq 1 $max_retries); do
            if ./scripts/feeds update "$feed_name"; then
                success=true
                break
            fi

            if [ "$attempt" -lt "$max_retries" ]; then
                rm -rf "$BUILD_DIR/feeds/$feed_name"
                sleep "$retry_delay"
            fi
        done

        if $success; then
            continue
        fi

        for optional_feed in "${optional_feeds[@]}"; do
            [ "$feed_name" = "$optional_feed" ] && is_optional=true && break
        done

        if $is_optional; then
            failed_feeds+=("$feed_name")
            rm -rf "$BUILD_DIR/feeds/$feed_name"
            sed -i "/^src-git\(-full\)\?[[:space:]]\+${feed_name}[[:space:]]/d" "$feeds_path"
        else
            echo "Error: required feed '$feed_name' failed to update" >&2
            exit 1
        fi
    done < <(grep -E '^src-(git|git-full|link)' "$feeds_path")

    if [ ${#failed_feeds[@]} -gt 0 ]; then
        ./scripts/feeds update -i
    fi

    if [ ! -d "$BUILD_DIR/feeds/small8" ]; then
        echo "Error: feeds/small8 was not created after feeds update" >&2
        exit 1
    fi

    if declare -f restore_missing_small8_packages >/dev/null 2>&1; then
        restore_missing_small8_packages
    fi
}

install_nikki() {
    ./scripts/feeds install -p nikki -f nikki luci-app-nikki
}

install_feeds() {
    ./scripts/feeds update -i

    for dir in "$BUILD_DIR"/feeds/*; do
        [ -d "$dir" ] || continue
        [[ "$dir" == *.tmp ]] && continue
        [[ "$dir" == *.index ]] && continue
        [[ "$dir" == *.targetindex ]] && continue

        case "$(basename "$dir")" in
            small8)
                install_small8
                install_fullconenat
                ;;
            passwall)
                install_passwall
                ;;
            nikki)
                install_nikki
                ;;
            *)
                ./scripts/feeds install -f -ap "$(basename "$dir")"
                ;;
        esac
    done

    if declare -f fix_smartdns_default_state >/dev/null 2>&1; then
        fix_smartdns_default_state
    fi

    if declare -f fix_service_resource_limits >/dev/null 2>&1; then
        fix_service_resource_limits
    fi
}
