#!/usr/bin/env bash

source "$SCRIPT_DIR/modules/_helpers.sh"
source "$SCRIPT_DIR/../modules/system.sh"

maintim_wrap_function fix_mk_def_depends upstream_fix_mk_def_depends
maintim_wrap_function update_menu_location upstream_update_menu_location
maintim_wrap_function update_oaf_deconfig upstream_update_oaf_deconfig
maintim_wrap_function install_pbr_cmcc upstream_install_pbr_cmcc

fix_default_set() {
    if [ -d "$BUILD_DIR/feeds/luci/collections/" ]; then
        find "$BUILD_DIR/feeds/luci/collections/" -type f -name "Makefile" -exec sed -i "s/luci-theme-bootstrap/luci-theme-$THEME_SET/g" {} \;
    fi

    install -Dm544 "$BASE_PATH/patches/990_set_default_lang_theme" "$BUILD_DIR/package/base-files/files/etc/uci-defaults/990_set_default_lang_theme"
    install -Dm544 "$BASE_PATH/patches/991_custom_settings" "$BUILD_DIR/package/base-files/files/etc/uci-defaults/991_custom_settings"
    install -Dm544 "$BASE_PATH/patches/992_set-wifi-uci.sh" "$BUILD_DIR/package/base-files/files/etc/uci-defaults/992_set-wifi-uci.sh"

    if [ -f "$BUILD_DIR/package/emortal/autocore/files/tempinfo" ] && [ -f "$BASE_PATH/patches/tempinfo" ]; then
        \cp -f "$BASE_PATH/patches/tempinfo" "$BUILD_DIR/package/emortal/autocore/files/tempinfo"
    fi

    add_service_default_policies
}

fix_mk_def_depends() {
    upstream_fix_mk_def_depends
    install_libubox_cmake_patch
    fix_libxml2_host_install
}

fix_libxml2_host_install() {
    local makefile_path="$BUILD_DIR/package/libs/libxml2/Makefile"

    [ -f "$makefile_path" ] || return 0

    python3 - "$makefile_path" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

old = """define Host/Install
\t$(call Host/Install/Default)
\tmv $(1)/bin/xml2-config $(1)/bin/$(GNU_HOST_NAME)-xml2-config
\t$(LN) $(GNU_HOST_NAME)-xml2-config $(1)/bin/xml2-config
endef
"""

new = """define Host/Install
\t$(call Host/Install/Default)
\tif [ ! -L $(1)/bin/xml2-config ]; then \\
\t\t[ ! -e $(1)/bin/$(GNU_HOST_NAME)-xml2-config ] && mv $(1)/bin/xml2-config $(1)/bin/$(GNU_HOST_NAME)-xml2-config || true; \\
\t\trm -f $(1)/bin/xml2-config; \\
\t\t$(LN) $(GNU_HOST_NAME)-xml2-config $(1)/bin/xml2-config; \\
\tfi
endef
"""

if old in text:
    text = text.replace(old, new, 1)
else:
    pattern = re.compile(
        r"define Host/Install\n\t\$\((?:call )?Host/Install/Default\)\n\tmv \$\(1\)/bin/xml2-config \$\(1\)/bin/\$\(GNU_HOST_NAME\)-xml2-config\n\t\$\(LN\) \$\(GNU_HOST_NAME\)-xml2-config \$\(1\)/bin/xml2-config\nendef\n",
        re.MULTILINE,
    )
    text = pattern.sub(new, text, count=1)

path.write_text(text, encoding="utf-8", newline="\n")
PY
}

update_menu_location() {
    upstream_update_menu_location

    local ddnsgo_path="$BUILD_DIR/feeds/small8/luci-app-ddns-go/root/usr/share/luci/menu.d/luci-app-ddns-go.json"
    if [ -f "$ddnsgo_path" ]; then
        sed -i 's/adminrvices/admin\/services/g' "$ddnsgo_path"
    fi

    local pbr_path="$BUILD_DIR/feeds/luci/applications/luci-app-pbr/root/usr/share/luci/menu.d/luci-app-pbr.json"
    if [ -f "$pbr_path" ]; then
        sed -i 's/adminrvices/admin\/services/g' "$pbr_path"
    fi

    add_ddnsgo_uci_defaults
    add_nikki_proxy_defaults
}

add_ddnsgo_uci_defaults() {
    local uci_defaults_dir="$BUILD_DIR/feeds/small8/luci-app-ddns-go/root/etc/uci-defaults"
    local config_dir="$BUILD_DIR/feeds/small8/luci-app-ddns-go/root/etc/config"
    local initd_script="$BUILD_DIR/feeds/small8/ddns-go/files/ddns-go.init"

    if [ -d "$BUILD_DIR/feeds/small8/luci-app-ddns-go" ]; then
        mkdir -p "$uci_defaults_dir" "$config_dir"

        cat > "$config_dir/ddns-go" <<'EOF'
config ddns-go 'config'
    option enabled '0'
    option port '9876'
EOF

        cat > "$uci_defaults_dir/99-ddns-go-init" <<'EOF'
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

    if [ -f "$initd_script" ]; then
        sed -i 's/config_foreach get_config basic/config_foreach get_config ddns-go/' "$initd_script"
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

    for config_path in "${config_source_paths[@]}"; do
        [ -f "$config_path" ] || continue
        if grep -q 'class_create(THIS_MODULE' "$config_path"; then
            sed -i 's/class_create(THIS_MODULE, *\(.*\))/class_create(\1)/' "$config_path"
        fi
    done

    for source_path in "${source_paths[@]}"; do
        [ -f "$source_path" ] || continue

        python3 - "$source_path" <<'PY'
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
            indent = substr($0, 1, match($0, /[^ \t]/) - 1)
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
    local script_path="$uci_defaults_dir/zzz_service_defaults"

    mkdir -p "$uci_defaults_dir"

    cat >"$script_path" <<'EOF'
#!/bin/sh

[ -f /etc/config/smartdns ] || touch /etc/config/smartdns
uci -q get smartdns.@smartdns[0] >/dev/null 2>&1 || uci add smartdns smartdns >/dev/null 2>&1
uci -q set smartdns.@smartdns[0].enabled='0'
uci -q commit smartdns
/etc/init.d/smartdns disable 2>/dev/null

if [ -f /etc/init.d/smartdns ]; then
    sed -i 's/^START=[0-9]*/START=94/' /etc/init.d/smartdns
fi

if uci -q get cupsd.config >/dev/null 2>&1; then
    uci -q set cupsd.config.enabled='0'
    uci -q commit cupsd
    /etc/init.d/cupsd disable 2>/dev/null
fi

TC_ACL="/usr/share/rpcd/acl.d/luci-app-timecontrol.json"
if [ -f "$TC_ACL" ] && ! grep -q '"/bin/ps"' "$TC_ACL"; then
    cat > "$TC_ACL" <<'TCEOF'
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
TCEOF
fi

PBR_INIT="/etc/init.d/pbr"
PBR_RPCD="/usr/libexec/rpcd/luci.pbr"
PBR_STATUS_JS="/www/luci-static/resources/pbr/status.js"
if [ -f "$PBR_INIT" ]; then
    pbr_pkg_compat="$(grep -o "packageCompat='[0-9][0-9]*'" "$PBR_INIT" 2>/dev/null | head -n1 | grep -o "[0-9][0-9]*")"
    if [ -n "$pbr_pkg_compat" ]; then
        if [ -f "$PBR_RPCD" ]; then
            pbr_rpcd_compat="$(grep -o "rpcdCompat='[0-9][0-9]*'" "$PBR_RPCD" 2>/dev/null | head -n1 | grep -o "[0-9][0-9]*")"
            if [ -n "$pbr_rpcd_compat" ] && [ "$pbr_rpcd_compat" != "$pbr_pkg_compat" ]; then
                sed -i "s/rpcdCompat='${pbr_rpcd_compat}'/rpcdCompat='${pbr_pkg_compat}'/" "$PBR_RPCD"
            fi
        fi
        if [ -f "$PBR_STATUS_JS" ]; then
            pbr_luci_compat="$(sed -n '/LuciCompat/,/return/{s/.*return \+\([0-9]\+\).*/\1/p}' "$PBR_STATUS_JS" 2>/dev/null | head -n1)"
            if [ -n "$pbr_luci_compat" ] && [ "$pbr_luci_compat" != "$pbr_pkg_compat" ]; then
                sed -i "/LuciCompat/,/return/{s/return ${pbr_luci_compat}/return ${pbr_pkg_compat}/}" "$PBR_STATUS_JS"
            fi
        fi
    fi
fi

EVENTS_JS="/www/luci-static/resources/view/dockerman/events.js"
if [ -f "$EVENTS_JS" ]; then
    sed -i 's|dm2\.docker_events([^)]*)|Promise.resolve({code:200,body:[]})|' "$EVENTS_JS"
    sed -i 's|this\.renderEventsTable(event_list)|void 0|' "$EVENTS_JS"
    sed -i "s|'value':[ ]*'1970-01-01T00:00'|'value':new Date(Date.now()-3600000).toISOString().slice(0,16)|" "$EVENTS_JS"
    sed -i "s|let since[ ]*=[ ]*'0'|let since=Math.floor((Date.now()-3600000)/1000).toString()|" "$EVENTS_JS"
    sed -i 's|view\.executeDockerAction(dm2\.docker_events|flushBatch();void(0)\&\&view.executeDockerAction(dm2.docker_events|' "$EVENTS_JS"
fi

SMARTDNS_JS="/www/luci-static/resources/view/smartdns/smartdns.js"
if [ -f "$SMARTDNS_JS" ]; then
    sed -i 's/smartdnsRenderStatus(res)/smartdnsRenderStatus(res[0])/' "$SMARTDNS_JS"
fi

exit 0
EOF

    chmod +x "$script_path"
}

update_oaf_deconfig() {
    upstream_update_oaf_deconfig
    fix_oaf_kernel_compat
    fix_oaf_init
}

fix_smartdns_default_state() {
    local patch_src="$BASE_PATH/patches/100-smartdns-optimize.patch"
    local smartdns_dirs=(
        "$BUILD_DIR/feeds/packages/net/smartdns"
        "$BUILD_DIR/feeds/small8/smartdns"
    )
    local found=0

    for pkg_dir in "${smartdns_dirs[@]}"; do
        local init_script="$pkg_dir/files/etc/init.d/smartdns"
        [ -f "$init_script" ] || continue
        if grep -q '^START=19' "$init_script"; then
            sed -i 's/^START=19/START=94/' "$init_script"
            found=$((found + 1))
        fi
    done

    while IFS= read -r init_script; do
        [ -f "$init_script" ] || continue
        if grep -q '^START=19' "$init_script"; then
            sed -i 's/^START=19/START=94/' "$init_script"
            found=$((found + 1))
        fi
    done < <(find -L "$BUILD_DIR" -path "*/smartdns/files/etc/init.d/smartdns" -type f 2>/dev/null || true)

    if [ -f "$patch_src" ]; then
        for pkg_dir in "${smartdns_dirs[@]}"; do
            [ -d "$pkg_dir" ] || continue
            [ -f "$pkg_dir/Makefile" ] || continue
            mkdir -p "$pkg_dir/patches"
            cp -f "$patch_src" "$pkg_dir/patches/"
            found=$((found + 1))
        done
    fi

    while IFS= read -r cfg; do
        [ -f "$cfg" ] || continue
        if grep -q "option enabled '1'" "$cfg"; then
            sed -i "s/option enabled '1'/option enabled '0'/g" "$cfg"
            found=$((found + 1))
        fi
    done < <(
        find -L "$BUILD_DIR" \
            \( -path "*/smartdns/files/etc/config/smartdns" \
            -o -path "*/smartdns/files/smartdns.conf" \
            -o -path "*/smartdns/files/smartdns.config" \) \
            -type f 2>/dev/null || true
    )

    while IFS= read -r mk; do
        [ -f "$mk" ] || continue
        if grep -qE '/etc/init\.d/smartdns[[:space:]]+enable' "$mk"; then
            sed -i '/\/etc\/init\.d\/smartdns[[:space:]][[:space:]]*enable/d' "$mk"
            found=$((found + 1))
        fi
    done < <(find -L "$BUILD_DIR" -path "*/smartdns/Makefile" -type f 2>/dev/null || true)

    while IFS= read -r luci_js; do
        [ -f "$luci_js" ] || continue
        if grep -q 'smartdnsRenderStatus(res)' "$luci_js"; then
            sed -i 's/smartdnsRenderStatus(res)/smartdnsRenderStatus(res[0])/' "$luci_js"
            found=$((found + 1))
        fi
    done < <(find -L "$BUILD_DIR" -path "*/smartdns/htdocs/luci-static/resources/view/smartdns/smartdns.js" -type f 2>/dev/null || true)

    [ "$found" -gt 0 ] || echo "Warning: no SmartDNS files were patched" >&2
}

fix_service_resource_limits() {
    local qf_init_paths=(
        "$BUILD_DIR/package/emortal/quickfile/quickfile/files/quickfile.init"
    )

    for init in "${qf_init_paths[@]}"; do
        [ -f "$init" ] || continue
        grep -q 'GOMEMLIMIT' "$init" && continue
        sed -i '/procd_set_param respawn/a\    procd_set_param env GOMEMLIMIT=256MiB' "$init"
        sed -i '/procd_set_param limits core="unlimited"/d' "$init"
        sed -i 's/procd_set_param limits nofile="200000 200000"/procd_set_param limits nofile="8192 8192"/' "$init"
    done

    while IFS= read -r init; do
        grep -q 'oom_score_adj' "$init" && continue
        sed -i '/procd_close_instance/i\        procd_set_param oom_score_adj 500' "$init"
        sed -i '/procd_close_instance/i\        procd_set_param limits nofile="8192 8192"' "$init"
    done < <(find "$BUILD_DIR" -path "*/dockerd/files/dockerd.init" -type f 2>/dev/null)
}

patch_dockerman_ui() {
    local source_root=""

    if [ -d "$BUILD_DIR/feeds/luci/applications/luci-app-dockerman" ]; then
        source_root="$BUILD_DIR/feeds/luci/applications/luci-app-dockerman"
    elif [ -d "$BUILD_DIR/package/feeds/luci/luci-app-dockerman" ]; then
        source_root="$BUILD_DIR/package/feeds/luci/luci-app-dockerman"
    else
        return 0
    fi

    install -Dm644 "$BASE_PATH/patches/dockerman/configuration.lua" \
        "$source_root/luasrc/model/cbi/dockerman/configuration.lua"
    install -Dm644 "$BASE_PATH/patches/dockerman/overview.lua" \
        "$source_root/luasrc/model/cbi/dockerman/overview.lua"

    local events_js="$source_root/htdocs/luci-static/resources/view/dockerman/events.js"
    if [ -f "$events_js" ]; then
        sed -i "s|dm2\.docker_events([^)]*)|Promise.resolve({code: 200, body: []})|" "$events_js"
        sed -i 's|this\.renderEventsTable(event_list)|void 0|' "$events_js"
        sed -i "s/'value': '1970-01-01T00:00'/'value': new Date(Date.now() - 3600000).toISOString().slice(0, 16)/" "$events_js"
        sed -i "s/let since = '0'/let since = Math.floor((Date.now() - 3600000) \/ 1000).toString()/" "$events_js"
        sed -i 's|view\.executeDockerAction(dm2\.docker_events|flushBatch();void(0)\&\&view.executeDockerAction(dm2.docker_events|' "$events_js"
    fi
}

install_pbr_cmcc() {
    upstream_install_pbr_cmcc
    fix_pbr_version_mismatch
}

fix_pbr_version_mismatch() {
    local pbr_init="$BUILD_DIR/feeds/packages/net/pbr/files/etc/init.d/pbr"
    local luci_rpcd="$BUILD_DIR/feeds/luci/applications/luci-app-pbr/root/usr/libexec/rpcd/luci.pbr"
    local luci_status_js="$BUILD_DIR/feeds/luci/applications/luci-app-pbr/htdocs/luci-static/resources/pbr/status.js"

    [ -f "$pbr_init" ] || return 0

    local pkg_compat
    pkg_compat=$(grep -oP "packageCompat='\K[0-9]+" "$pbr_init" 2>/dev/null)
    [ -n "$pkg_compat" ] || return 0

    if [ -f "$luci_rpcd" ]; then
        local rpcd_compat
        rpcd_compat=$(grep -oP "rpcdCompat='\K[0-9]+" "$luci_rpcd" 2>/dev/null)
        if [ -n "$rpcd_compat" ] && [ "$rpcd_compat" != "$pkg_compat" ]; then
            sed -i "s/rpcdCompat='${rpcd_compat}'/rpcdCompat='${pkg_compat}'/" "$luci_rpcd"
        fi
    fi

    if [ -f "$luci_status_js" ]; then
        local luci_compat
        luci_compat=$(sed -n '/LuciCompat/,/return/{s/.*return \+\([0-9]\+\).*/\1/p}' "$luci_status_js" 2>/dev/null)
        if [ -n "$luci_compat" ] && [ "$luci_compat" != "$pkg_compat" ]; then
            sed -i "/LuciCompat/,/return/{s/return ${luci_compat}/return ${pkg_compat}/}" "$luci_status_js"
        fi
    fi
}

add_nikki_proxy_defaults() {
    local nikki_config="$BUILD_DIR/feeds/nikki/luci-app-nikki/root/etc/config/nikki"

    if [ -f "$nikki_config" ]; then
        sed -i "s|option geoip_mmdb_url 'https://github.com/|option geoip_mmdb_url 'https://gh-proxy.com/https://github.com/|g" "$nikki_config"
        sed -i "s|option ui_url 'https://github.com/|option ui_url 'https://gh-proxy.com/https://github.com/|g" "$nikki_config"
    fi
}
