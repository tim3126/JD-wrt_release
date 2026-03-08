#!/usr/bin/env bash

prepare_small8_feed() {
    local local_feeds_root="$BUILD_DIR/.customfeeds"
    local local_small8_dir="$local_feeds_root/small8"
    local small8_repos=(
        "https://github.com/kenzok8/jell.git"
        "https://github.com/kenzok8/small-package.git"
        "https://gitee.com/aiyboy/small-package.git"
    )

    mkdir -p "$local_feeds_root"
    rm -rf "$local_small8_dir"

    for repo in "${small8_repos[@]}"; do
        echo "正在准备 small8 feed: $repo"
        if git clone --depth 1 --single-branch "$repo" "$local_small8_dir"; then
            echo "small8 feed 准备完成: $repo"
            return 0
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
