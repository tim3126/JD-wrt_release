#!/usr/bin/env bash

set -e

if [ "$(id -u)" = "0" ]; then
    export FORCE_UNSAFE_CONFIGURE=1
fi

if printf '%s\n' "$PATH" | tr ':' '\n' | grep -qv '^/'; then
    export PATH
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
fi

if [ -d "wrt_core" ]; then
    WRT_CORE_PATH="wrt_core"
elif [ -d "../wrt_core" ]; then
    WRT_CORE_PATH="../wrt_core"
else
    echo "Error: wrt_core directory not found!"
    exit 1
fi

BASE_PATH=$(cd "$WRT_CORE_PATH" && pwd)

Dev=$1
Build_Mod=$2

CONFIG_FILE="$BASE_PATH/deconfig/$Dev.config"
INI_FILE="$BASE_PATH/compilecfg/$Dev.ini"
UPDATE_SCRIPT="$BASE_PATH/local/maintim_update.sh"

if [[ ! -f $CONFIG_FILE ]]; then
    echo "Config not found: $CONFIG_FILE"
    exit 1
fi

if [[ ! -f $INI_FILE ]]; then
    echo "INI file not found: $INI_FILE"
    exit 1
fi

if [[ ! -f $UPDATE_SCRIPT ]]; then
    echo "Update script not found: $UPDATE_SCRIPT"
    exit 1
fi

read_ini_by_key() {
    local key=$1
    awk -F"=" -v key="$key" '$1 == key {print $2}' "$INI_FILE"
}

append_config_if_exists() {
    local source_file="$1"
    local target_file="$2"

    if [[ -f $source_file ]]; then
        cat "$source_file" >>"$target_file"
    fi
}

remove_uhttpd_dependency() {
    local config_path="$BASE_PATH/../$BUILD_DIR/.config"
    local luci_makefile_path="$BASE_PATH/../$BUILD_DIR/feeds/luci/collections/luci/Makefile"

    if grep -q "CONFIG_PACKAGE_luci-app-quickfile=y" "$config_path"; then
        if [ -f "$luci_makefile_path" ]; then
            sed -i '/luci-light/d' "$luci_makefile_path"
            echo "Removed uhttpd (luci-light) dependency as luci-app-quickfile (nginx) is enabled."
        fi
    fi
}

apply_config() {
    local target_config="$BASE_PATH/../$BUILD_DIR/.config"

    \cp -f "$CONFIG_FILE" "$target_config"

    if grep -qE "(ipq60xx|ipq807x)" "$target_config" &&
        ! grep -q "CONFIG_GIT_MIRROR" "$target_config"; then
        append_config_if_exists "$BASE_PATH/deconfig/nss.config" "$target_config"
    fi

    append_config_if_exists "$BASE_PATH/deconfig/compile_base.config" "$target_config"
    append_config_if_exists "$BASE_PATH/deconfig/docker_deps.config" "$target_config"
    append_config_if_exists "$BASE_PATH/deconfig/proxy.config" "$target_config"
    append_config_if_exists "$BASE_PATH/deconfig/disable_packages.config" "$target_config"

    if [ -d "$BASE_PATH/local/config" ]; then
        for extra_config in "$BASE_PATH"/local/config/*.config; do
            [ -f "$extra_config" ] || continue
            append_config_if_exists "$extra_config" "$target_config"
        done
    fi
}

REPO_URL=$(read_ini_by_key "REPO_URL")
REPO_BRANCH=$(read_ini_by_key "REPO_BRANCH")
REPO_BRANCH=${REPO_BRANCH:-main}
BUILD_DIR=$(read_ini_by_key "BUILD_DIR")
COMMIT_HASH=$(read_ini_by_key "COMMIT_HASH")
COMMIT_HASH=${COMMIT_HASH:-none}

if [[ -d action_build ]]; then
    BUILD_DIR="action_build"
fi

"$UPDATE_SCRIPT" "$REPO_URL" "$REPO_BRANCH" "$BUILD_DIR" "$COMMIT_HASH"

apply_config
remove_uhttpd_dependency

cd "$BASE_PATH/../$BUILD_DIR"
make defconfig

if grep -qE "^CONFIG_TARGET_x86_64=y" "$CONFIG_FILE"; then
    DISTFEEDS_PATH="$BASE_PATH/../$BUILD_DIR/package/emortal/default-settings/files/99-distfeeds.conf"
    if [ -d "${DISTFEEDS_PATH%/*}" ] && [ -f "$DISTFEEDS_PATH" ]; then
        sed -i 's/aarch64_cortex-a53/x86_64/g' "$DISTFEEDS_PATH"
    fi
fi

if [[ $Build_Mod == "debug" ]]; then
    exit 0
fi

TARGET_DIR="$BASE_PATH/../$BUILD_DIR/bin/targets"
if [[ -d $TARGET_DIR ]]; then
    find "$TARGET_DIR" -type f \( -name "*.bin" -o -name "*.manifest" -o -name "*efi.img.gz" -o -name "*.itb" -o -name "*.fip" -o -name "*.ubi" -o -name "*rootfs.tar.gz" \) -exec rm -f {} +
fi

make download -j$(($(nproc) * 2))
make -j$(($(nproc) + 1)) || make -j1 V=s

FIRMWARE_DIR="$BASE_PATH/../firmware"
\rm -rf "$FIRMWARE_DIR"
mkdir -p "$FIRMWARE_DIR"
find "$TARGET_DIR" -type f \( -name "*.bin" -o -name "*.manifest" -o -name "*efi.img.gz" -o -name "*.itb" -o -name "*.fip" -o -name "*.ubi" -o -name "*rootfs.tar.gz" \) -exec cp -f {} "$FIRMWARE_DIR/" \;
\rm -f "$BASE_PATH/../firmware/Packages.manifest" 2>/dev/null

if [[ -d action_build ]]; then
    make clean
fi
