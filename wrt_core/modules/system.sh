#!/usr/bin/env bash

fix_default_set() {
    if [ -d "$BUILD_DIR/feeds/luci/collections/" ]; then
        find "$BUILD_DIR/feeds/luci/collections/" -type f -name "Makefile" -exec sed -i "s/luci-theme-bootstrap/luci-theme-$THEME_SET/g" {} \;
    fi

    install -Dm544 "$BASE_PATH/patches/990_set_default_lang_theme" "$BUILD_DIR/package/base-files/files/etc/uci-defaults/990_set_default_lang_theme"
    install -Dm544 "$BASE_PATH/patches/991_custom_settings" "$BUILD_DIR/package/base-files/files/etc/uci-defaults/991_custom_settings"
    install -Dm544 "$BASE_PATH/patches/992_set-wifi-uci.sh" "$BUILD_DIR/package/base-files/files/etc/uci-defaults/992_set-wifi-uci.sh"

    if [ -f "$BUILD_DIR/package/emortal/autocore/files/tempinfo" ]; then
        if [ -f "$BASE_PATH/patches/tempinfo" ]; then
            \cp -f "$BASE_PATH/patches/tempinfo" "$BUILD_DIR/package/emortal/autocore/files/tempinfo"
        fi
    fi
}

fix_miniupnpd() {
    local miniupnpd_dir="$BUILD_DIR/feeds/packages/net/miniupnpd"
    local patch_file="999-chanage-default-leaseduration.patch"

    if [ -d "$miniupnpd_dir" ] && [ -f "$BASE_PATH/patches/$patch_file" ]; then
        install -Dm644 "$BASE_PATH/patches/$patch_file" "$miniupnpd_dir/patches/$patch_file"
    fi
}

change_dnsmasq2full() {
    if ! grep -q "dnsmasq-full" $BUILD_DIR/include/target.mk; then
        sed -i 's/dnsmasq/dnsmasq-full/g' ./include/target.mk
    fi
}

fix_mk_def_depends() {
    sed -i 's/libustream-mbedtls/libustream-openssl/g' $BUILD_DIR/include/target.mk 2>/dev/null
    if [ -f $BUILD_DIR/target/linux/qualcommax/Makefile ]; then
        sed -i 's/wpad-openssl/wpad-mesh-openssl/g' $BUILD_DIR/target/linux/qualcommax/Makefile
    fi
}

fix_kconfig_recursive_dependency() {
    local file="$BUILD_DIR/scripts/package-metadata.pl"
    if [ -f "$file" ]; then
        sed -i 's/<PACKAGE_\$pkgname/!=y/g' "$file"
        echo "已修复 package-metadata.pl 的 Kconfig 递归依赖生成逻辑。"
    fi
}

update_default_lan_addr() {
    local CFG_PATH="$BUILD_DIR/package/base-files/files/bin/config_generate"
    if [ -f $CFG_PATH ]; then
        sed -i 's/192\.168\.[0-9]*\.[0-9]*/'$LAN_ADDR'/g' $CFG_PATH
    fi
}

remove_something_nss_kmod() {
    local ipq_mk_path="$BUILD_DIR/target/linux/qualcommax/Makefile"
    local target_mks=("$BUILD_DIR/target/linux/qualcommax/ipq60xx/target.mk" "$BUILD_DIR/target/linux/qualcommax/ipq807x/target.mk")

    for target_mk in "${target_mks[@]}"; do
        if [ -f "$target_mk" ]; then
            sed -i 's/kmod-qca-nss-crypto//g' "$target_mk"
        fi
    done

    if [ -f "$ipq_mk_path" ]; then
        sed -i '/kmod-qca-nss-drv-eogremgr/d' "$ipq_mk_path"
        sed -i '/kmod-qca-nss-drv-gre/d' "$ipq_mk_path"
        sed -i '/kmod-qca-nss-drv-map-t/d' "$ipq_mk_path"
        sed -i '/kmod-qca-nss-drv-match/d' "$ipq_mk_path"
        sed -i '/kmod-qca-nss-drv-mirror/d' "$ipq_mk_path"
        sed -i '/kmod-qca-nss-drv-tun6rd/d' "$ipq_mk_path"
        sed -i '/kmod-qca-nss-drv-tunipip6/d' "$ipq_mk_path"
        sed -i '/kmod-qca-nss-drv-vxlanmgr/d' "$ipq_mk_path"
        sed -i '/kmod-qca-nss-drv-wifi-meshmgr/d' "$ipq_mk_path"
        sed -i '/kmod-qca-nss-macsec/d' "$ipq_mk_path"

        sed -i 's/automount //g' "$ipq_mk_path"
        sed -i 's/cpufreq //g' "$ipq_mk_path"
    fi
}

update_affinity_script() {
    local affinity_script_dir="$BUILD_DIR/target/linux/qualcommax"

    if [ -d "$affinity_script_dir" ]; then
        find "$affinity_script_dir" -name "set-irq-affinity" -exec rm -f {} \;
        find "$affinity_script_dir" -name "smp_affinity" -exec rm -f {} \;
        install -Dm755 "$BASE_PATH/patches/smp_affinity" "$affinity_script_dir/base-files/etc/init.d/smp_affinity"
    fi
}

fix_hash_value() {
    local makefile_path="$1"
    local old_hash="$2"
    local new_hash="$3"
    local package_name="$4"

    if [ -f "$makefile_path" ]; then
        sed -i "s/$old_hash/$new_hash/g" "$makefile_path"
        echo "已修正 $package_name 的哈希值。"
    fi
}

apply_hash_fixes() {
    fix_hash_value \
        "$BUILD_DIR/package/feeds/packages/smartdns/Makefile" \
        "860a816bf1e69d5a8a2049483197dbebe8a3da2c9b05b2da68c85ef7dee7bdde" \
        "582021891808442b01f551bc41d7d95c38fb00c1ec78a58ac3aaaf898fbd2b5b" \
        "smartdns"

    fix_hash_value \
        "$BUILD_DIR/package/feeds/packages/smartdns/Makefile" \
        "320c99a65ca67a98d11a45292aa99b8904b5ebae5b0e17b302932076bf62b1ec" \
        "43e58467690476a77ce644f9dc246e8a481353160644203a1bd01eb09c881275" \
        "smartdns"
}

update_ath11k_fw() {
    local makefile="$BUILD_DIR/package/firmware/ath11k-firmware/Makefile"
    local new_mk="$BASE_PATH/patches/ath11k_fw.mk"
    local url="https://raw.githubusercontent.com/VIKINGYFY/immortalwrt/refs/heads/main/package/firmware/ath11k-firmware/Makefile"

    if [ -d "$(dirname "$makefile")" ]; then
        echo "正在更新 ath11k-firmware Makefile..."
        if ! curl -fsSL -o "$new_mk" "$url"; then
            echo "错误：从 $url 下载 ath11k-firmware Makefile 失败" >&2
            exit 1
        fi
        if [ ! -s "$new_mk" ]; then
            echo "错误：下载的 ath11k-firmware Makefile 为空文件" >&2
            exit 1
        fi
        mv -f "$new_mk" "$makefile"
    fi
}

fix_mkpkg_format_invalid() {
    if [[ $BUILD_DIR =~ "imm-nss" ]]; then
        if [ -f $BUILD_DIR/feeds/small8/v2ray-geodata/Makefile ]; then
            sed -i 's/VER)-\$(PKG_RELEASE)/VER)-r\$(PKG_RELEASE)/g' $BUILD_DIR/feeds/small8/v2ray-geodata/Makefile
        fi
        if [ -f $BUILD_DIR/feeds/small8/luci-lib-taskd/Makefile ]; then
            sed -i 's/>=1\.0\.3-1/>=1\.0\.3-r1/g' $BUILD_DIR/feeds/small8/luci-lib-taskd/Makefile
        fi
        if [ -f $BUILD_DIR/feeds/small8/luci-app-openclash/Makefile ]; then
            sed -i 's/PKG_RELEASE:=beta/PKG_RELEASE:=1/g' $BUILD_DIR/feeds/small8/luci-app-openclash/Makefile
        fi
        if [ -f $BUILD_DIR/feeds/small8/luci-app-quickstart/Makefile ]; then
            sed -i 's/PKG_VERSION:=0\.8\.16-1/PKG_VERSION:=0\.8\.16/g' $BUILD_DIR/feeds/small8/luci-app-quickstart/Makefile
            sed -i 's/PKG_RELEASE:=$/PKG_RELEASE:=1/g' $BUILD_DIR/feeds/small8/luci-app-quickstart/Makefile
        fi
        if [ -f $BUILD_DIR/feeds/small8/luci-app-store/Makefile ]; then
            sed -i 's/PKG_VERSION:=0\.1\.27-1/PKG_VERSION:=0\.1\.27/g' $BUILD_DIR/feeds/small8/luci-app-store/Makefile
            sed -i 's/PKG_RELEASE:=$/PKG_RELEASE:=1/g' $BUILD_DIR/feeds/small8/luci-app-store/Makefile
        fi
    fi
}

change_cpuusage() {
    local luci_rpc_path="$BUILD_DIR/feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci"
    local qualcommax_sbin_dir="$BUILD_DIR/target/linux/qualcommax/base-files/sbin"
    local filogic_sbin_dir="$BUILD_DIR/target/linux/mediatek/filogic/base-files/sbin"

    if [ -f "$luci_rpc_path" ]; then
        sed -i "s#const fd = popen('top -n1 | awk \\\'/^CPU/ {printf(\"%d%\", 100 - \$8)}\\\'')#const cpuUsageCommand = access('/sbin/cpuusage') ? '/sbin/cpuusage' : 'top -n1 | awk \\\'/^CPU/ {printf(\"%d%\", 100 - \$8)}\\\''#g" "$luci_rpc_path"
        sed -i '/cpuUsageCommand/a \\t\t\tconst fd = popen(cpuUsageCommand);' "$luci_rpc_path"
    fi

    local old_script_path="$BUILD_DIR/package/base-files/files/sbin/cpuusage"
    if [ -f "$old_script_path" ]; then
        rm -f "$old_script_path"
    fi

    if [ -d "$BUILD_DIR/target/linux/qualcommax" ]; then
        install -Dm755 "$BASE_PATH/patches/cpuusage" "$qualcommax_sbin_dir/cpuusage"
    fi
    if [ -d "$BUILD_DIR/target/linux/mediatek" ]; then
        install -Dm755 "$BASE_PATH/patches/hnatusage" "$filogic_sbin_dir/cpuusage"
    fi
}

update_tcping() {
    local tcping_path="$BUILD_DIR/feeds/small8/tcping/Makefile"
    local url="https://raw.githubusercontent.com/Openwrt-Passwall/openwrt-passwall-packages/refs/heads/main/tcping/Makefile"

    if [ -d "$(dirname "$tcping_path")" ]; then
        echo "正在更新 tcping Makefile..."
        if ! curl -fsSL -o "$tcping_path" "$url"; then
            echo "错误：从 $url 下载 tcping Makefile 失败" >&2
            exit 1
        fi
    fi
}

set_custom_task() {
    local sh_dir="$BUILD_DIR/package/base-files/files/etc/init.d"
    cat <<'EOF' >"$sh_dir/custom_task"
#!/bin/sh /etc/rc.common
START=99

boot() {
    sed -i '/drop_caches/d' /etc/crontabs/root
    echo "15 3 * * * sync && echo 3 > /proc/sys/vm/drop_caches" >>/etc/crontabs/root

    sed -i '/wireguard_watchdog/d' /etc/crontabs/root

    local wg_ifname=$(wg show | awk '/interface/ {print $2}')

    if [ -n "$wg_ifname" ]; then
        echo "*/15 * * * * /usr/bin/wireguard_watchdog" >>/etc/crontabs/root
        uci set system.@system[0].cronloglevel='9'
        uci commit system
        /etc/init.d/cron restart
    fi

    crontab /etc/crontabs/root
}
EOF
    chmod +x "$sh_dir/custom_task"
}

apply_passwall_tweaks() {
    local chnlist_path="$BUILD_DIR/feeds/passwall/luci-app-passwall/root/usr/share/passwall/rules/chnlist"
    if [ -f "$chnlist_path" ]; then
        >"$chnlist_path"
    fi

    local xray_util_path="$BUILD_DIR/feeds/passwall/luci-app-passwall/luasrc/passwall/util_xray.lua"
    if [ -f "$xray_util_path" ]; then
        sed -i 's/maxRTT = "1s"/maxRTT = "2s"/g' "$xray_util_path"
        sed -i 's/sampling = 3/sampling = 5/g' "$xray_util_path"
    fi
}

install_opkg_distfeeds() {
    local emortal_def_dir="$BUILD_DIR/package/emortal/default-settings"
    local distfeeds_conf="$emortal_def_dir/files/99-distfeeds.conf"

    if [ -d "$emortal_def_dir" ] && [ ! -f "$distfeeds_conf" ]; then
        cat <<'EOF' >"$distfeeds_conf"
src/gz openwrt_base https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/base/
src/gz openwrt_luci https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/luci/
src/gz openwrt_packages https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/packages/
src/gz openwrt_routing https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/routing/
src/gz openwrt_telephony https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/telephony/
EOF

        sed -i "/define Package\/default-settings\/install/a\\
\\t\$(INSTALL_DIR) \$(1)/etc\\n\
\t\$(INSTALL_DATA) ./files/99-distfeeds.conf \$(1)/etc/99-distfeeds.conf\n" $emortal_def_dir/Makefile

        sed -i "/exit 0/i\\
[ -f \'/etc/99-distfeeds.conf\' ] && mv \'/etc/99-distfeeds.conf\' \'/etc/opkg/distfeeds.conf\'\n\
sed -ri \'/check_signature/s@^[^#]@#&@\' /etc/opkg.conf\n" $emortal_def_dir/files/99-default-settings
    fi
}

update_nss_pbuf_performance() {
    local pbuf_path="$BUILD_DIR/package/kernel/mac80211/files/pbuf.uci"
    if [ -d "$(dirname "$pbuf_path")" ] && [ -f $pbuf_path ]; then
        sed -i "s/auto_scale '1'/auto_scale 'off'/g" $pbuf_path
        sed -i "s/scaling_governor 'performance'/scaling_governor 'schedutil'/g" $pbuf_path
    fi
}

set_build_signature() {
    local file="$BUILD_DIR/feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js"
    if [ -d "$(dirname "$file")" ] && [ -f $file ]; then
        sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ build by ZqinKing')/g" "$file"
    fi
}

update_nss_diag() {
    local file="$BUILD_DIR/package/kernel/mac80211/files/nss_diag.sh"
    if [ -d "$(dirname "$file")" ] && [ -f "$file" ]; then
        \rm -f "$file"
        install -Dm755 "$BASE_PATH/patches/nss_diag.sh" "$file"
    fi
}

update_menu_location() {
    local samba4_path="$BUILD_DIR/feeds/luci/applications/luci-app-samba4/root/usr/share/luci/menu.d/luci-app-samba4.json"
    if [ -d "$(dirname "$samba4_path")" ] && [ -f "$samba4_path" ]; then
        sed -i 's/nas/services/g' "$samba4_path"
    fi

    local tailscale_path="$BUILD_DIR/feeds/small8/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json"
    if [ -d "$(dirname "$tailscale_path")" ] && [ -f "$tailscale_path" ]; then
        sed -i 's/services/vpn/g' "$tailscale_path"
    fi

    # 修复 ddns-go 菜单路径错误 (adminrvices -> admin/services)
    local ddnsgo_path="$BUILD_DIR/feeds/small8/luci-app-ddns-go/root/usr/share/luci/menu.d/luci-app-ddns-go.json"
    if [ -d "$(dirname "$ddnsgo_path")" ] && [ -f "$ddnsgo_path" ]; then
        sed -i 's/adminrvices/admin\/services/g' "$ddnsgo_path"
    fi

    # 修复 pbr 菜单路径错误 (adminrvices -> admin/services)
    local pbr_path="$BUILD_DIR/feeds/luci/applications/luci-app-pbr/root/usr/share/luci/menu.d/luci-app-pbr.json"
    if [ -d "$(dirname "$pbr_path")" ] && [ -f "$pbr_path" ]; then
        sed -i 's/adminrvices/admin\/services/g' "$pbr_path"
    fi

}

# 添加 ddns-go UCI 默认配置并修复 init.d 脚本 bug
add_ddnsgo_uci_defaults() {
    local uci_defaults_dir="$BUILD_DIR/feeds/small8/luci-app-ddns-go/root/etc/uci-defaults"
    local config_dir="$BUILD_DIR/feeds/small8/luci-app-ddns-go/root/etc/config"
    local initd_script="$BUILD_DIR/feeds/small8/ddns-go/files/ddns-go.init"

    if [ -d "$BUILD_DIR/feeds/small8/luci-app-ddns-go" ]; then
        mkdir -p "$uci_defaults_dir"
        mkdir -p "$config_dir"

        # 创建默认配置文件
        cat > "$config_dir/ddns-go" << 'EOF'
config ddns-go 'config'
    option enabled '0'
    option port '9876'
EOF

        # 创建 uci-defaults 脚本确保配置存在
        cat > "$uci_defaults_dir/99-ddns-go-init" << 'EOF'
#!/bin/sh
[ -f /etc/config/ddns-go ] || {
    touch /etc/config/ddns-go
    uci set ddns-go.config=ddns-go
    uci set ddns-go.config.enabled='0'
    uci commit ddns-go
}
exit 0
EOF
        chmod +x "$uci_defaults_dir/99-ddns-go-init"
    fi

    # 修复 ddns-go init.d 脚本 bug: config_foreach 第二个参数应为配置类型 (ddns-go)，而不是配置节名 (basic)
    if [ -f "$initd_script" ]; then
        sed -i 's/config_foreach get_config basic/config_foreach get_config ddns-go/' "$initd_script"
        echo "ddns-go init.d 脚本已修复"
    fi
}

fix_compile_coremark() {
    local file="$BUILD_DIR/feeds/packages/utils/coremark/Makefile"
    if [ -d "$(dirname "$file")" ] && [ -f "$file" ]; then
        sed -i 's/mkdir \$/mkdir -p \$/g' "$file"
    fi
}

update_dnsmasq_conf() {
    local file="$BUILD_DIR/package/network/services/dnsmasq/files/dhcp.conf"
    if [ -d "$(dirname "$file")" ] && [ -f "$file" ]; then
        sed -i '/dns_redirect/d' "$file"
    fi
}

add_backup_info_to_sysupgrade() {
    local conf_path="$BUILD_DIR/package/base-files/files/etc/sysupgrade.conf"

    if [ -f "$conf_path" ]; then
        cat >"$conf_path" <<'EOF'
/etc/AdGuardHome.yaml
/etc/easytier
/etc/lucky/
EOF
    fi
}

update_script_priority() {
    local qca_drv_path="$BUILD_DIR/package/feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
    if [ -d "${qca_drv_path%/*}" ] && [ -f "$qca_drv_path" ]; then
        sed -i 's/START=.*/START=88/g' "$qca_drv_path"
    fi

    local pbuf_path="$BUILD_DIR/package/kernel/mac80211/files/qca-nss-pbuf.init"
    if [ -d "${pbuf_path%/*}" ] && [ -f "$pbuf_path" ]; then
        sed -i 's/START=.*/START=89/g' "$pbuf_path"
    fi

    local mosdns_path="$BUILD_DIR/package/feeds/small8/luci-app-mosdns/root/etc/init.d/mosdns"
    if [ -d "${mosdns_path%/*}" ] && [ -f "$mosdns_path" ]; then
        sed -i 's/START=.*/START=94/g' "$mosdns_path"
    fi
}

update_mosdns_deconfig() {
    local mosdns_conf="$BUILD_DIR/feeds/small8/luci-app-mosdns/root/etc/config/mosdns"
    if [ -d "${mosdns_conf%/*}" ] && [ -f "$mosdns_conf" ]; then
        sed -i 's/8000/300/g' "$mosdns_conf"
        sed -i 's/5335/5336/g' "$mosdns_conf"
    fi
}

fix_quickstart() {
    local file_path="$BUILD_DIR/feeds/small8/luci-app-quickstart/luasrc/controller/istore_backend.lua"
    local url="https://gist.githubusercontent.com/puteulanus/1c180fae6bccd25e57eb6d30b7aa28aa/raw/istore_backend.lua"
    if [ -f "$file_path" ]; then
        echo "正在修复 quickstart..."
        if ! curl -fsSL -o "$file_path" "$url"; then
            echo "错误：从 $url 下载 istore_backend.lua 失败" >&2
            exit 1
        fi
    fi
}

update_oaf_deconfig() {
    local conf_path="$BUILD_DIR/feeds/small8/open-app-filter/files/appfilter.config"
    local uci_def="$BUILD_DIR/feeds/small8/luci-app-oaf/root/etc/uci-defaults/94_feature_3.0"
    local disable_path="$BUILD_DIR/feeds/small8/luci-app-oaf/root/etc/uci-defaults/99_disable_oaf"

    if [ -d "${conf_path%/*}" ] && [ -f "$conf_path" ]; then
        sed -i \
            -e "s/record_enable '1'/record_enable '0'/g" \
            -e "s/disable_hnat '1'/disable_hnat '0'/g" \
            -e "s/auto_load_engine '1'/auto_load_engine '0'/g" \
            "$conf_path"
    fi

    if [ -d "${uci_def%/*}" ] && [ -f "$uci_def" ]; then
        sed -i '/\(disable_hnat\|auto_load_engine\)/d' "$uci_def"

        cat >"$disable_path" <<-EOF
#!/bin/sh
[ "\$(uci get appfilter.global.enable 2>/dev/null)" = "0" ] && {
    /etc/init.d/appfilter disable
    /etc/init.d/appfilter stop
}
EOF
        chmod +x "$disable_path"
    fi
}

fix_oaf_kernel_compat() {
    local source_paths=(
        "$BUILD_DIR/feeds/small8/oaf/src/app_filter.c"
        "$BUILD_DIR/package/feeds/small8/oaf/src/app_filter.c"
    )
    local config_source_paths=(
        "$BUILD_DIR/feeds/small8/oaf/src/app_filter_config.c"
        "$BUILD_DIR/package/feeds/small8/oaf/src/app_filter_config.c"
    )
    local makefile_paths=(
        "$BUILD_DIR/feeds/small8/oaf/Makefile"
        "$BUILD_DIR/package/feeds/small8/oaf/Makefile"
    )

    # Fix app_filter_config.c: class_create API changed in kernel 6.4+
    for config_path in "${config_source_paths[@]}"; do
        [ -f "$config_path" ] || continue
        if grep -q 'class_create(THIS_MODULE' "$config_path"; then
            sed -i 's/class_create(THIS_MODULE, *\(.*\))/class_create(\1)/' "$config_path"
            echo "已修复 $config_path 中的 class_create API (6.4+ 兼容)"
        fi
    done

    for source_path in "${source_paths[@]}"; do
        [ -f "$source_path" ] || continue

        python - "$source_path" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

for name in [
    "__add_app_feature",
    "add_app_feature",
    "af_init_feature",
    "load_feature_buf_from_file",
    "load_feature_config",
    "parse_flow_base",
    "parse_https_proto",
    "parse_http_proto",
    "af_match_by_pos",
    "af_match_by_url",
    "af_match_one",
    "app_filter_match",
    "__af_update_client_app_info",
    "af_update_client_app_info",
    "TEST_cJSON",
    "init_oaf_timer",
    "fini_oaf_timer",
    "netlink_oaf_init",
]:
    text = text.replace(f"\nint {name}(", f"\nstatic int {name}(")
    text = text.replace(f"\nvoid {name}(", f"\nstatic void {name}(")

text = text.replace(
    "\tmm_segment_t fs;\n",
    "#if LINUX_VERSION_CODE <= KERNEL_VERSION(5,7,19)\n\tmm_segment_t fs;\n#endif\n",
    1,
)
text = text.replace(
    "\tif (size == 0) {\n\t\treturn;\n\t}\n",
    "\tif (size == 0) {\n\t\tfilp_close(fp, NULL);\n\t\treturn;\n\t}\n",
    1,
)
text = text.replace("\tint i;\n\tint index = -1;\n", "\tint index = -1;\n", 1)
text = text.replace("\tint found = 0;\n", "", 1)
text = text.replace("\tint i;\n\tint index = 0;\n", "", 1)
text = text.replace("\tstatic int bytes1 = 0;\n", "", 1)
text = text.replace("time=%d action=%s, %d/%d\\n", "time=%lu action=%s, %d/%d\\n", 1)

path.write_text(text, encoding="utf-8", newline="\n")
PY
    done

    for makefile_path in "${makefile_paths[@]}"; do
        [ -f "$makefile_path" ] || continue
        if ! grep -q 'Wno-error' "$makefile_path"; then
            sed -i 's|EXTRA_CFLAGS="$(EXTRA_CFLAGS)"|EXTRA_CFLAGS="$(EXTRA_CFLAGS) -Wno-error"|' "$makefile_path"
        fi
    done
}


fix_oaf_init() {
    local init_paths=(
        "$BUILD_DIR/feeds/small8/open-app-filter/files/appfilter.init"
        "$BUILD_DIR/package/feeds/small8/open-app-filter/files/appfilter.init"
    )

    for init_path in "${init_paths[@]}"; do
        [ -f "$init_path" ] || continue

        if grep -q '/proc/sys/oaf' "$init_path"; then
            continue
        fi

        awk '
        /^[[:space:]]*insmod oaf[[:space:]]*$/ {
            indent = substr($0, 1, match($0, /[^ 	]/) - 1)
            print indent "modprobe oaf 2>/dev/null || insmod /lib/modules/$(uname -r)/oaf.ko"
            print indent "[ -d /proc/sys/oaf ] || return 1"
            next
        }
        { print }
        ' "$init_path" >"$init_path.tmp" && mv "$init_path.tmp" "$init_path"
    done
}

add_service_default_policies() {
    local uci_defaults_dir="$BUILD_DIR/package/base-files/files/etc/uci-defaults"
    local script_path="$uci_defaults_dir/993_service_defaults"

    mkdir -p "$uci_defaults_dir"

    cat >"$script_path" <<'EOF'
#!/bin/sh

# SmartDNS: 确保配置节存在，然后强制禁用
[ -f /etc/config/smartdns ] || touch /etc/config/smartdns
uci -q get smartdns.@smartdns[0] >/dev/null 2>&1 || uci add smartdns smartdns >/dev/null 2>&1
uci -q set smartdns.@smartdns[0].enabled='0'
uci -q commit smartdns
/etc/init.d/smartdns disable 2>/dev/null

# SmartDNS: 修补 init START 优先级 (19→94)，避免在 uci-defaults 之前运行
if [ -f /etc/init.d/smartdns ]; then
    sed -i 's/^START=19$/START=94/' /etc/init.d/smartdns
fi

# CUPS
if uci -q get cupsd.config >/dev/null 2>&1; then
    uci -q set cupsd.config.enabled='0'
    uci -q commit cupsd
    /etc/init.d/cupsd disable 2>/dev/null
fi

# Docker: 保持默认启用，用于部署项目

# Docker Events: 修复 uwsgi worker 耗尽导致 LuCI 卡死
# 根因: Docker events 是流式 API, 每次调用会长时间占用一个 uwsgi worker
#       events.js 页面加载时 load()+renderEventsTable() 同时发起调用,
#       占满全部 2 个 uwsgi worker → nginx upstream timeout → 整个 LuCI UI 冻结
# 修复: 页面加载时不发起任何 Docker events 调用, 用户通过过滤器手动触发
EVENTS_JS="/www/luci-static/resources/view/dockerman/events.js"
if [ -f "$EVENTS_JS" ]; then
    # 1) load(): 移除 dm2.docker_events() 阻塞调用, 返回空结果
    sed -i 's|dm2\.docker_events([^)]*)|Promise.resolve({code:200,body:[]})|' "$EVENTS_JS"
    # 2) render(): 移除自动调用 renderEventsTable, 避免页面加载时发起流式请求
    sed -i 's|this\.renderEventsTable(event_list)|void 0|' "$EVENTS_JS"
    # 3) From 日期选择器默认值: 1970-01-01 → 1小时前
    sed -i "s|'value':[ ]*'1970-01-01T00:00'|'value':new Date(Date.now()-3600000).toISOString().slice(0,16)|" "$EVENTS_JS"
    # 4) renderEventsTable() 中 since 默认回退: '0' → 1小时前 (用户触发时生效)
    sed -i "s|let since[ ]*=[ ]*'0'|let since=Math.floor((Date.now()-3600000)/1000).toString()|" "$EVENTS_JS"
    # 5) 手动过滤触发: 短路 executeDockerAction(dm2.docker_events), 渲染空表
    sed -i 's|view\.executeDockerAction(dm2\.docker_events|flushBatch();void(0)\&\&view.executeDockerAction(dm2.docker_events|' "$EVENTS_JS"
fi

exit 0
EOF

    chmod +x "$script_path"
}

# 构建时修补 SmartDNS 默认配置和 init 脚本，从根源禁用自启
fix_smartdns_default_state() {
    local found=0

    # 动态查找 SmartDNS 默认配置文件
    while IFS= read -r cfg; do
        if grep -q "option enabled '1'" "$cfg"; then
            sed -i "s/option enabled '1'/option enabled '0'/g" "$cfg"
            echo "已修补 SmartDNS 默认配置 enabled='0': $cfg"
            found=$((found + 1))
        fi
    done < <(find "$BUILD_DIR" -path "*/smartdns/files/etc/config/smartdns" -type f 2>/dev/null)

    # 动态查找 SmartDNS init 脚本，修补 START 优先级
    while IFS= read -r init; do
        if grep -q '^START=19$' "$init"; then
            sed -i 's/^START=19$/START=94/' "$init"
            echo "已修补 SmartDNS init START=19 -> 94: $init"
            found=$((found + 1))
        fi
    done < <(find "$BUILD_DIR" -path "*/smartdns/files/etc/init.d/smartdns" -type f 2>/dev/null)

    # 动态查找 SmartDNS Makefile，移除 postinst 中的 enable 调用
    while IFS= read -r mk; do
        if grep -q '/etc/init.d/smartdns enable' "$mk"; then
            sed -i '/\/etc\/init.d\/smartdns enable/d' "$mk"
            echo "已从 Makefile 移除 smartdns enable: $mk"
            found=$((found + 1))
        fi
    done < <(find "$BUILD_DIR" -path "*/smartdns/Makefile" -type f 2>/dev/null)

    if [ "$found" -eq 0 ]; then
        echo "Warning: 未找到任何 SmartDNS 文件可修补" >&2
    fi
}

# 限制 QuickFile 和 Docker 的内存/CPU 占用
fix_service_resource_limits() {
    # --- QuickFile: Go 二进制，优化 GC 策略和资源限制 ---
    # 注意: Go 程序的 VSZ (虚拟内存) 通常超过 1GB，这是 Go 运行时预留地址空间的正常行为，
    # 实际物理内存占用 (RSS) 远小于 VSZ。以下优化可进一步控制 GC 行为。
    local qf_init_paths=(
        "$BUILD_DIR/package/emortal/quickfile/quickfile/files/quickfile.init"
    )

    for init in "${qf_init_paths[@]}"; do
        [ -f "$init" ] || continue
        if grep -q 'GOMEMLIMIT' "$init"; then
            continue
        fi
        # GOMEMLIMIT=256MiB: Go GC 软上限，堆超过 256MB 后 GC 激进回收
        sed -i '/procd_set_param respawn/a\    procd_set_param env GOMEMLIMIT=256MiB' "$init"
        # 移除不必要的 core=unlimited
        sed -i '/procd_set_param limits core="unlimited"/d' "$init"
        # 将 nofile 降到合理值
        sed -i 's/procd_set_param limits nofile="200000 200000"/procd_set_param limits nofile="8192 8192"/' "$init"
        echo "已为 QuickFile 优化 Go GC 策略 (GOMEMLIMIT=256MiB)"
    done

    # --- Docker: 限制 dockerd OOM 优先级，保护路由核心服务 ---
    while IFS= read -r init; do
        if grep -q 'oom_score_adj' "$init"; then
            continue
        fi
        # OOM 得分 500: 内存不足时优先杀 docker，保护路由核心
        sed -i '/procd_close_instance/i\        procd_set_param oom_score_adj 500' "$init"
        sed -i '/procd_close_instance/i\        procd_set_param limits nofile="8192 8192"' "$init"
        echo "已为 dockerd 添加 OOM 保护 (oom_score_adj=500)"
    done < <(find "$BUILD_DIR" -path "*/dockerd/files/dockerd.init" -type f 2>/dev/null)
}

patch_dockerman_ui() {
    local source_root=""

    if [ -d "$BUILD_DIR/feeds/luci/applications/luci-app-dockerman" ]; then
        source_root="$BUILD_DIR/feeds/luci/applications/luci-app-dockerman"
    elif [ -d "$BUILD_DIR/package/feeds/luci/luci-app-dockerman" ]; then
        source_root="$BUILD_DIR/package/feeds/luci/luci-app-dockerman"
    else
        return
    fi

    install -Dm644 "$BASE_PATH/patches/dockerman/configuration.lua" \
        "$source_root/luasrc/model/cbi/dockerman/configuration.lua"
    install -Dm644 "$BASE_PATH/patches/dockerman/overview.lua" \
        "$source_root/luasrc/model/cbi/dockerman/overview.lua"

    # 修复事件页: Docker events 流式 API 占满 uwsgi worker 导致 LuCI 卡死
    local events_js="$source_root/htdocs/luci-static/resources/view/dockerman/events.js"
    if [ -f "$events_js" ]; then
        # 1) load(): 移除 dm2.docker_events() 阻塞调用, 返回空结果
        sed -i "s|dm2\.docker_events([^)]*)|Promise.resolve({code: 200, body: []})|" "$events_js"
        # 2) render(): 移除自动调用 renderEventsTable, 避免页面加载时发起流式请求
        sed -i 's|this\.renderEventsTable(event_list)|void 0|' "$events_js"
        # 3) From 日期选择器默认值: 1970-01-01 → 1小时前
        sed -i "s/'value': '1970-01-01T00:00'/'value': new Date(Date.now() - 3600000).toISOString().slice(0, 16)/" "$events_js"
        # 4) renderEventsTable() 中 since 默认回退: '0' → 1小时前 (用户触发时生效)
        sed -i "s/let since = '0'/let since = Math.floor((Date.now() - 3600000) \/ 1000).toString()/" "$events_js"
        # 5) 手动过滤触发: 短路 executeDockerAction(dm2.docker_events), 渲染空表
        sed -i 's|view\.executeDockerAction(dm2\.docker_events|flushBatch();void(0)\&\&view.executeDockerAction(dm2.docker_events|' "$events_js"
        echo "已修复 dockerman events.js: 禁止页面加载时自动查询Docker events"
    fi
}

update_geoip() {
    local geodata_path="$BUILD_DIR/package/feeds/small8/v2ray-geodata/Makefile"
    if [ -d "${geodata_path%/*}" ] && [ -f "$geodata_path" ]; then
        local GEOIP_VER=$(awk -F"=" '/GEOIP_VER:=/ {print $NF}' $geodata_path | grep -oE "[0-9]{1,}")
        if [ -n "$GEOIP_VER" ]; then
            local base_url="https://github.com/v2fly/geoip/releases/download/${GEOIP_VER}"
            local old_SHA256
            if ! old_SHA256=$(wget -qO- "$base_url/geoip.dat.sha256sum" | awk '{print $1}'); then
                echo "错误：从 $base_url/geoip.dat.sha256sum 获取旧的 geoip.dat 校验和失败" >&2
                return 1
            fi
            local new_SHA256
            if ! new_SHA256=$(wget -qO- "$base_url/geoip-only-cn-private.dat.sha256sum" | awk '{print $1}'); then
                echo "错误：从 $base_url/geoip-only-cn-private.dat.sha256sum 获取新的 geoip-only-cn-private.dat 校验和失败" >&2
                return 1
            fi
            if [ -n "$old_SHA256" ] && [ -n "$new_SHA256" ]; then
                if grep -q "$old_SHA256" "$geodata_path"; then
                    sed -i "s|=geoip.dat|=geoip-only-cn-private.dat|g" "$geodata_path"
                    sed -i "s/$old_SHA256/$new_SHA256/g" "$geodata_path"
                fi
            fi
        fi
    fi
}

fix_rust_compile_error() {
    if [ -f "$BUILD_DIR/feeds/packages/lang/rust/Makefile" ]; then
        sed -i 's/download-ci-llvm=true/download-ci-llvm=false/g' "$BUILD_DIR/feeds/packages/lang/rust/Makefile"
    fi
}

fix_easytier_lua() {
    local file_path="$BUILD_DIR/package/feeds/small8/luci-app-easytier/luasrc/model/cbi/easytier.lua"
    if [ -f "$file_path" ]; then
        sed -i 's/util.pcdata/xml.pcdata/g' "$file_path"
    fi
}

fix_easytier_mk() {
    local mk_path="$BUILD_DIR/feeds/small8/luci-app-easytier/easytier/Makefile"
    if [ -f "$mk_path" ]; then
        sed -i 's/!@(mips||mipsel)/!TARGET_mips \&\& !TARGET_mipsel/g' "$mk_path"
    fi
}

update_nginx_ubus_module() {
    local makefile_path="$BUILD_DIR/feeds/packages/net/nginx/Makefile"
    local source_date="2024-03-02"
    local source_version="564fa3e9c2b04ea298ea659b793480415da26415"
    local mirror_hash="92c9ab94d88a2fe8d7d1e8a15d15cfc4d529fdc357ed96d22b65d5da3dd24d7f"

    if [ -f "$makefile_path" ]; then
        sed -i "s/SOURCE_DATE:=2020-09-06/SOURCE_DATE:=$source_date/g" "$makefile_path"
        sed -i "s/SOURCE_VERSION:=b2d7260dcb428b2fb65540edb28d7538602b4a26/SOURCE_VERSION:=$source_version/g" "$makefile_path"
        sed -i "s/MIRROR_HASH:=515bb9d355ad80916f594046a45c190a68fb6554d6795a54ca15cab8bdd12fda/MIRROR_HASH:=$mirror_hash/g" "$makefile_path"
        echo "已更新 nginx-mod-ubus 模块的 SOURCE_DATE, SOURCE_VERSION 和 MIRROR_HASH。"
    else
        echo "错误：未找到 $makefile_path 文件，无法更新 nginx-mod-ubus 模块。" >&2
    fi
}

fix_openssl_ktls() {
    local config_in="$BUILD_DIR/package/libs/openssl/Config.in"
    if [ -f "$config_in" ]; then
        echo "正在更新 OpenSSL kTLS 配置..."
        sed -i 's/select PACKAGE_kmod-tls/depends on PACKAGE_kmod-tls/g' "$config_in"
        sed -i '/depends on PACKAGE_kmod-tls/a\\tdefault y if PACKAGE_kmod-tls' "$config_in"
    fi
}

fix_opkg_check() {
    local patch_file="$BASE_PATH/patches/001-fix-provides-version-parsing.patch"
    local opkg_dir="$BUILD_DIR/package/system/opkg"
    if [ -f "$patch_file" ]; then
        install -Dm644 "$patch_file" "$opkg_dir/patches/001-fix-provides-version-parsing.patch"
    fi
}

install_pbr_cmcc() {
    local pbr_pkg_dir="$BUILD_DIR/package/feeds/packages/pbr"
    local pbr_dir="$pbr_pkg_dir/files/usr/share/pbr"
    local pbr_conf="$pbr_pkg_dir/files/etc/config/pbr"
    local pbr_makefile="$pbr_pkg_dir/Makefile"

    if [ -d "$pbr_pkg_dir" ]; then
        echo "正在安装 PBR CMCC 配置文件..."
        install -Dm644 "$BASE_PATH/patches/pbr.user.cmcc" "$pbr_dir/pbr.user.cmcc"
        install -Dm644 "$BASE_PATH/patches/pbr.user.cmcc6" "$pbr_dir/pbr.user.cmcc6"

        if [ -f "$pbr_makefile" ]; then
            if ! grep -q "pbr.user.cmcc" "$pbr_makefile"; then
                echo "正在修改 PBR Makefile 添加安装规则..."
                sed -i '/pbr.user.netflix.*\$(1)/a\
	$(INSTALL_DATA) ./files/usr/share/pbr/pbr.user.cmcc $(1)/usr/share/pbr/pbr.user.cmcc\
	$(INSTALL_DATA) ./files/usr/share/pbr/pbr.user.cmcc6 $(1)/usr/share/pbr/pbr.user.cmcc6' "$pbr_makefile"
            fi
        fi
    fi

    if [ -f "$pbr_conf" ]; then
        if ! grep -q "pbr.user.cmcc" "$pbr_conf"; then
            echo "正在添加 PBR CMCC 配置条目..."
            sed -i "/option path '\/usr\/share\/pbr\/pbr.user.netflix'/,/option enabled '0'/{
                /option enabled '0'/a\\
\\
config include\\
	option path '/usr/share/pbr/pbr.user.cmcc'\\
	option enabled '0'\\
\\
config include\\
	option path '/usr/share/pbr/pbr.user.cmcc6'\\
	option enabled '0'
            }" "$pbr_conf"
        fi
    fi
}

fix_quectel_cm() {
    local makefile_path="$BUILD_DIR/package/feeds/packages/quectel-cm/Makefile"
    local cmake_patch_path="$BUILD_DIR/package/feeds/packages/quectel-cm/patches/020-cmake.patch"

    if [ -f "$makefile_path" ]; then
        echo "正在修复 quectel-cm Makefile..."

        sed -i '/^PKG_SOURCE:=/d' "$makefile_path"
        sed -i '/^PKG_SOURCE_URL:=@IMMORTALWRT/d' "$makefile_path"
        sed -i '/^PKG_HASH:=/d' "$makefile_path"

        sed -i '/^PKG_RELEASE:=/a\
\
PKG_SOURCE_PROTO:=git\
PKG_SOURCE_URL:=https://github.com/Carton32/quectel-CM.git\
PKG_SOURCE_VERSION:=$(PKG_VERSION)\
PKG_MIRROR_HASH:=skip' "$makefile_path"

        sed -i 's/^PKG_RELEASE:=2$/PKG_RELEASE:=3/' "$makefile_path"

        echo "quectel-cm Makefile 修复完成。"
    fi

    if [ -f "$cmake_patch_path" ]; then
        sed -i 's/-cmake_minimum_required(VERSION 2\.4)$/-cmake_minimum_required(VERSION 2.4) /' "$cmake_patch_path"
        sed -i 's/project(quectel-CM)$/project(quectel-CM) /' "$cmake_patch_path"
    fi
}

set_nginx_default_config() {
    local nginx_config_path="$BUILD_DIR/feeds/packages/net/nginx-util/files/nginx.config"
    if [ -f "$nginx_config_path" ]; then
        cat >"$nginx_config_path" <<EOF
config main 'global'
        option uci_enable 'true'

config server '_lan'
        list listen '443 ssl default_server'
        list listen '[::]:443 ssl default_server'
        option server_name '_lan'
        list include 'restrict_locally'
        list include 'conf.d/*.locations'
        option uci_manage_ssl 'self-signed'
        option ssl_certificate '/etc/nginx/conf.d/_lan.crt'
        option ssl_certificate_key '/etc/nginx/conf.d/_lan.key'
        option ssl_session_cache 'shared:SSL:32k'
        option ssl_session_timeout '64m'
        option access_log 'off; # logd openwrt'

config server 'http_only'
        list listen '80'
        list listen '[::]:80'
        option server_name 'http_only'
        list include 'conf.d/*.locations'
        option access_log 'off; # logd openwrt'
EOF
    fi

    local nginx_template="$BUILD_DIR/feeds/packages/net/nginx-util/files/uci.conf.template"
    if [ -f "$nginx_template" ]; then
        if ! grep -q "client_body_in_file_only clean;" "$nginx_template"; then
            sed -i "/client_max_body_size 128M;/a\\
\tclient_body_in_file_only clean;\\
\tclient_body_temp_path /mnt/tmp;" "$nginx_template"
        fi
    fi

    local luci_support_script="$BUILD_DIR/feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support"

    if [ -f "$luci_support_script" ]; then
        if ! grep -q "client_body_in_file_only off;" "$luci_support_script"; then
            echo "正在为 Nginx ubus location 配置应用修复..."
            sed -i "/ubus_parallel_req 2;/a\\        client_body_in_file_only off;\\n        client_max_body_size 1M;" "$luci_support_script"
        fi
    fi
}

update_uwsgi_limit_as() {
    local cgi_io_ini="$BUILD_DIR/feeds/packages/net/uwsgi/files-luci-support/luci-cgi_io.ini"
    local webui_ini="$BUILD_DIR/feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini"

    if [ -f "$cgi_io_ini" ]; then
        sed -i 's/^limit-as = .*/limit-as = 8192/g' "$cgi_io_ini"
    fi

    if [ -f "$webui_ini" ]; then
        sed -i 's/^limit-as = .*/limit-as = 8192/g' "$webui_ini"
    fi
}

remove_tweaked_packages() {
    local target_mk="$BUILD_DIR/include/target.mk"
    if [ -f "$target_mk" ]; then
        if grep -q "^DEFAULT_PACKAGES += \$(DEFAULT_PACKAGES.tweak)" "$target_mk"; then
            sed -i 's/DEFAULT_PACKAGES += $(DEFAULT_PACKAGES.tweak)/# DEFAULT_PACKAGES += $(DEFAULT_PACKAGES.tweak)/g' "$target_mk"
        fi
    fi
}

# 设置 nikki (Mihomo) 默认下载地址为代理地址，解决国内无法访问 GitHub 导致面板 404 问题
add_nikki_proxy_defaults() {
    local nikki_config="$BUILD_DIR/feeds/nikki/luci-app-nikki/root/etc/config/nikki"
    
    if [ -f "$nikki_config" ]; then
        echo "正在设置 nikki 默认代理下载地址..."
        
        # 替换 geoip_mmdb_url 为代理地址
        sed -i "s|option geoip_mmdb_url 'https://github.com/|option geoip_mmdb_url 'https://gh-proxy.com/https://github.com/|g" "$nikki_config"
        
        # 替换 ui_url 为代理地址
        sed -i "s|option ui_url 'https://github.com/|option ui_url 'https://gh-proxy.com/https://github.com/|g" "$nikki_config"
        
        echo "nikki 代理下载地址设置完成。"
    fi
}

install_libubox_cmake_patch() {
    local libubox_pkg_dir="$BUILD_DIR/package/libs/libubox"
    local patch_file="999-libubox-demote-format-nonliteral.patch"

    if [ ! -d "$libubox_pkg_dir" ]; then
        echo "错误：libubox 包目录不存在: $libubox_pkg_dir" >&2
        return 1
    fi

    mkdir -p "$libubox_pkg_dir/patches"

    if [ -f "$BASE_PATH/patches/$patch_file" ]; then
        install -Dm644 "$BASE_PATH/patches/$patch_file" "$libubox_pkg_dir/patches/$patch_file"
        echo "已安装 libubox CMakeLists 补丁: $patch_file"
    else
        echo "错误：补丁文件不存在: $BASE_PATH/patches/$patch_file" >&2
        return 1
    fi

    if [ ! -f "$libubox_pkg_dir/patches/$patch_file" ]; then
        echo "错误：补丁安装失败: $libubox_pkg_dir/patches/$patch_file" >&2
        return 1
    fi
}
