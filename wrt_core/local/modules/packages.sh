#!/usr/bin/env bash

source "$SCRIPT_DIR/modules/_helpers.sh"
source "$SCRIPT_DIR/../modules/packages.sh"

maintim_wrap_function update_dockerman upstream_update_dockerman

remove_unwanted_packages() {
    local luci_packages=(
        "luci-app-passwall" "luci-app-ddns-go" "luci-app-rclone" "luci-app-ssr-plus"
        "luci-app-vssr" "luci-app-daed" "luci-app-dae" "luci-app-alist" "luci-app-homeproxy"
        "luci-app-haproxy-tcp" "luci-app-openclash" "luci-app-mihomo" "luci-app-appfilter"
        "luci-app-msd_lite" "luci-app-unblockneteasemusic"
    )
    local packages_net=(
        "haproxy" "xray-core" "xray-plugin" "dns2socks" "alist" "hysteria"
        "mosdns" "adguardhome" "ddns-go" "naiveproxy" "shadowsocks-rust"
        "sing-box" "v2ray-core" "v2ray-geodata" "v2ray-plugin" "tuic-client"
        "chinadns-ng" "ipt2socks" "tcping" "trojan-plus" "simple-obfs" "shadowsocksr-libev"
        "dae" "daed" "mihomo" "geoview" "tailscale" "open-app-filter" "msd_lite"
    )
    local packages_utils=("cups")
    local small8_packages=(
        "ppp" "firewall" "dae" "daed" "daed-next" "libnftnl" "nftables" "dnsmasq" "luci-app-alist"
        "alist" "opkg"
    )

    for pkg in "${luci_packages[@]}"; do
        [ -d "./feeds/luci/applications/$pkg" ] && \rm -rf "./feeds/luci/applications/$pkg"
        [ -d "./feeds/luci/themes/$pkg" ] && \rm -rf "./feeds/luci/themes/$pkg"
    done

    for pkg in "${packages_net[@]}"; do
        [ -d "./feeds/packages/net/$pkg" ] && \rm -rf "./feeds/packages/net/$pkg"
    done

    for pkg in "${packages_utils[@]}"; do
        [ -d "./feeds/packages/utils/$pkg" ] && \rm -rf "./feeds/packages/utils/$pkg"
    done

    for pkg in "${small8_packages[@]}"; do
        [ -d "./feeds/small8/$pkg" ] && \rm -rf "./feeds/small8/$pkg"
    done

    if [[ -d ./package/istore ]]; then
        \rm -rf ./package/istore
    fi

    if [ -d "$BUILD_DIR/target/linux/qualcommax/base-files/etc/uci-defaults" ]; then
        find "$BUILD_DIR/target/linux/qualcommax/base-files/etc/uci-defaults/" -type f -name "99*.sh" -exec rm -f {} +
    fi
}

clone_sparse_repo_packages() {
    local repo_url="$1"
    local target_dir="$2"
    shift 2

    local tmp_dir
    tmp_dir=$(mktemp -d)

    if ! git clone --depth 1 --filter=blob:none --no-checkout "$repo_url" "$tmp_dir"; then
        echo "Error: failed to clone $repo_url" >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    pushd "$tmp_dir" >/dev/null
    git sparse-checkout init --cone
    git sparse-checkout set "$@" || {
        popd >/dev/null
        rm -rf "$tmp_dir"
        echo "Error: failed to sparse-checkout packages from $repo_url" >&2
        exit 1
    }
    git checkout --quiet
    popd >/dev/null

    mkdir -p "$target_dir"
    for pkg in "$@"; do
        rm -rf "$target_dir/$pkg"
        cp -rf "$tmp_dir/$pkg" "$target_dir/"
    done

    rm -rf "$tmp_dir"
}

restore_missing_small8_packages() {
    local small8_dir="$BUILD_DIR/feeds/small8"
    local small8_real_dir=""

    if [ ! -d "$small8_dir" ]; then
        echo "Error: $small8_dir does not exist" >&2
        exit 1
    fi

    small8_real_dir=$(readlink -f "$small8_dir" 2>/dev/null || true)
    [ -n "$small8_real_dir" ] || small8_real_dir="$small8_dir"

    if [ ! -d "$small8_real_dir/ddns-go" ] || [ ! -d "$small8_real_dir/luci-app-ddns-go" ]; then
        clone_sparse_repo_packages "https://github.com/sirpdboy/luci-app-ddns-go.git" "$small8_real_dir" ddns-go luci-app-ddns-go
    fi

    if [ ! -d "$small8_real_dir/luci-app-homeproxy" ]; then
        rm -rf "$small8_real_dir/luci-app-homeproxy"
        if ! git clone --depth 1 "https://github.com/immortalwrt/homeproxy.git" "$small8_real_dir/luci-app-homeproxy"; then
            echo "Error: failed to clone homeproxy repository" >&2
            exit 1
        fi
    fi

    if [ ! -d "$small8_real_dir/lucky" ] || [ ! -d "$small8_real_dir/luci-app-lucky" ]; then
        clone_sparse_repo_packages "https://github.com/gdy666/luci-app-lucky.git" "$small8_real_dir" lucky luci-app-lucky
    fi
}

install_small8() {
    local small8_install_packages=(
        xray-core xray-plugin dns2tcp dns2socks haproxy hysteria
        naiveproxy shadowsocks-rust sing-box v2ray-core v2ray-geodata geoview v2ray-plugin
        tuic-client chinadns-ng ipt2socks tcping trojan-plus simple-obfs shadowsocksr-libev
        v2dat adguardhome luci-app-adguardhome luci-lib-xterm luci-app-cloudflarespeedtest
        netdata luci-app-netdata luci-app-openclash luci-app-amlogic tailscale luci-app-tailscale
        oaf open-app-filter luci-app-oaf easytier luci-app-easytier msd_lite luci-app-msd_lite
        cups luci-app-cupsd smartdns luci-app-smartdns
        luci-app-homeproxy luci-app-lucky lucky ddns-go luci-app-ddns-go
    )

    ./scripts/feeds install -p small8 -f "${small8_install_packages[@]}"
}

add_timecontrol() {
    local timecontrol_dir="$BUILD_DIR/package/luci-app-timecontrol"
    local repo_url="https://github.com/sirpdboy/luci-app-timecontrol.git"
    local menu_json
    local acl_json
    local init_script

    rm -rf "$timecontrol_dir" 2>/dev/null
    if ! git clone --depth 1 "$repo_url" "$timecontrol_dir"; then
        echo "Error: failed to clone luci-app-timecontrol from $repo_url" >&2
        exit 1
    fi

    menu_json="$timecontrol_dir/luci-app-timecontrol/root/usr/share/luci/menu.d/luci-app-timecontrol.json"
    if [ -f "$menu_json" ]; then
        sed -i 's/admin\/control/admin\/services/g' "$menu_json"
    fi

    acl_json="$timecontrol_dir/luci-app-timecontrol/root/usr/share/rpcd/acl.d/luci-app-timecontrol.json"
    if [ -f "$acl_json" ]; then
        cat > "$acl_json" <<'EOF'
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
    fi

    init_script="$timecontrol_dir/luci-app-timecontrol/root/etc/init.d/timecontrol"
    if [ -f "$init_script" ]; then
        python3 - "$init_script" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="latin-1")
lines = text.splitlines()

out = []
i = 0
replaced = False
while i < len(lines):
    if re.match(r'^\s*_timecontrol_start\(\)\s*\{', lines[i]):
        out.append("_timecontrol_start() {")
        out.append("\ttouch $LOCK")
        out.append("\ttimecontrol start")
        out.append("\tstart_instance")
        out.append("}")
        replaced = True
        i += 1
        while i < len(lines) and lines[i].strip() != "}":
            i += 1
        if i < len(lines):
            i += 1
        continue
    out.append(lines[i])
    i += 1

if replaced:
    path.write_text("\n".join(out) + "\n", encoding="latin-1", newline="\n")
PY
    fi
}

update_adguardhome() {
    local adguardhome_dir="$BUILD_DIR/package/feeds/small8/luci-app-adguardhome"
    local repo_url="https://github.com/ZqinKing/luci-app-adguardhome.git"

    rm -rf "$adguardhome_dir" 2>/dev/null
    if ! git clone --depth 1 "$repo_url" "$adguardhome_dir"; then
        echo "Error: failed to clone luci-app-adguardhome from $repo_url" >&2
        exit 1
    fi
}

update_argon() {
    return 0
}

update_ath11k_fw() {
    return 0
}

add_ax6600_led() {
    return 0
}

update_smartdns() {
    return 0
}

update_lucky() {
    local lucky_repo_url="https://github.com/gdy666/luci-app-lucky.git"
    local target_small8_dir="$BUILD_DIR/feeds/small8"
    local lucky_dir="$target_small8_dir/lucky"
    local luci_app_lucky_dir="$target_small8_dir/luci-app-lucky"

    if [ -d "$lucky_dir" ] && [ -d "$luci_app_lucky_dir" ]; then
        local tmp_dir
        tmp_dir=$(mktemp -d)

        if ! git clone --depth 1 --filter=blob:none --no-checkout "$lucky_repo_url" "$tmp_dir"; then
            rm -rf "$tmp_dir"
            return 0
        fi

        pushd "$tmp_dir" >/dev/null
        git sparse-checkout init --cone
        git sparse-checkout set luci-app-lucky lucky || {
            popd >/dev/null
            rm -rf "$tmp_dir"
            return 0
        }
        git checkout --quiet

        \cp -rf "$tmp_dir/luci-app-lucky/." "$luci_app_lucky_dir/"
        \cp -rf "$tmp_dir/lucky/." "$lucky_dir/"

        popd >/dev/null
        rm -rf "$tmp_dir"
    fi

    local lucky_conf="$BUILD_DIR/feeds/small8/lucky/files/luckyuci"
    if [ -f "$lucky_conf" ]; then
        sed -i "s/option enabled '1'/option enabled '0'/g" "$lucky_conf"
        sed -i "s/option logger '1'/option logger '0'/g" "$lucky_conf"
    fi

    local version
    version=$(find "$BASE_PATH/patches" -name "lucky_*.tar.gz" -printf "%f\n" | head -n 1 | sed -n 's/^lucky_\(.*\)_Linux.*$/\1/p')
    [ -n "$version" ] || return 0

    local makefile_path="$BUILD_DIR/feeds/small8/lucky/Makefile"
    [ -f "$makefile_path" ] || return 0

    local patch_line="\\t[ -f \$(TOPDIR)/../wrt_core/patches/lucky_${version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz ] && install -Dm644 \$(TOPDIR)/../wrt_core/patches/lucky_${version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz \$(PKG_BUILD_DIR)/\$(PKG_NAME)_\$(PKG_VERSION)_Linux_\$(LUCKY_ARCH).tar.gz"
    if grep -q "Build/Prepare" "$makefile_path"; then
        sed -i "/Build\\/Prepare/a\\$patch_line" "$makefile_path"
        sed -i '/wget/d' "$makefile_path"
    fi
}

update_dockerman() {
    upstream_update_dockerman

    if declare -f patch_dockerman_ui >/dev/null 2>&1; then
        patch_dockerman_ui
    fi
}

add_quickfile() {
    local repo_url="https://github.com/sbwml/luci-app-quickfile.git"
    local target_dir="$BUILD_DIR/package/emortal/quickfile"
    local quickfile_commit="5d863b9"

    [ -d "$target_dir" ] && rm -rf "$target_dir"
    if ! git clone "$repo_url" "$target_dir"; then
        echo "Error: failed to clone luci-app-quickfile from $repo_url" >&2
        exit 1
    fi

    git -C "$target_dir" checkout "$quickfile_commit"

    local makefile_path="$target_dir/quickfile/Makefile"
    if [ -f "$makefile_path" ]; then
        sed -i '/\t\$(INSTALL_BIN) \$(PKG_BUILD_DIR)\/quickfile-\$(ARCH_PACKAGES)/c\
\tif [ "\$(ARCH_PACKAGES)" = "x86_64" ]; then \\\
\t\t\$(INSTALL_BIN) \$(PKG_BUILD_DIR)\/quickfile-x86_64 \$(1)\/usr\/bin\/quickfile; \\\
\telse \\\
\t\t\$(INSTALL_BIN) \$(PKG_BUILD_DIR)\/quickfile-aarch64_generic \$(1)\/usr\/bin\/quickfile; \\\
\tfi' "$makefile_path"
    fi
}
