#!/usr/bin/env bash

set -e
set -o errexit
set -o errtrace

error_handler() {
    echo "Error occurred in script at line: ${BASH_LINENO[0]}, command: '${BASH_COMMAND}'"
}

trap 'error_handler' ERR

REPO_URL=$1
REPO_BRANCH=$2
BUILD_DIR=$3
COMMIT_HASH=$4

# Convert BUILD_DIR to absolute path
if [[ "$BUILD_DIR" != /* ]]; then
    BUILD_DIR="$(pwd)/$BUILD_DIR"
fi

FEEDS_CONF="feeds.conf.default"
GOLANG_REPO="https://github.com/sbwml/packages_lang_golang"
GOLANG_BRANCH="25.x"
THEME_SET="bootstrap"
LAN_ADDR="192.168.10.1"

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
BASE_PATH=${BASE_PATH:-$SCRIPT_DIR}

source "$SCRIPT_DIR/modules/general.sh"
source "$SCRIPT_DIR/modules/feeds.sh"
source "$SCRIPT_DIR/modules/packages.sh"
source "$SCRIPT_DIR/modules/system.sh"
source "$SCRIPT_DIR/modules/cups.sh"


main() {
    clone_repo
    clean_up
    reset_feeds_conf
    update_feeds
    restore_missing_small8_packages
    remove_unwanted_packages
    remove_tweaked_packages
    update_homeproxy
    fix_default_set
    fix_miniupnpd
    update_golang
    change_dnsmasq2full
    fix_mk_def_depends

    install_libubox_cmake_patch
    update_default_lan_addr
    remove_something_nss_kmod
    update_affinity_script
    # update_ath11k_fw  # 太乙ER1无WiFi，不需要ath11k固件
    # fix_mkpkg_format_invalid
    change_cpuusage
    update_tcping
    # add_ax6600_led  # 太乙ER1不是雅典娜AX6600，不需要LED控制
    set_custom_task
    apply_passwall_tweaks
    update_nss_pbuf_performance
    set_build_signature
    update_nss_diag
    update_menu_location
    fix_compile_coremark
    update_dnsmasq_conf
    add_backup_info_to_sysupgrade
    update_mosdns_deconfig
    fix_quickstart
    update_oaf_deconfig
    fix_oaf_kernel_compat
    fix_oaf_init
    add_service_default_policies
    add_timecontrol
    add_ddnsgo_uci_defaults
    add_nikki_proxy_defaults
    add_quickfile
    update_lucky
    fix_rust_compile_error
    # update_smartdns  # 使用small8 feed自带的smartdns
    update_diskman
    set_nginx_default_config
    update_uwsgi_limit_as
    update_nginx_ubus_module
    check_default_settings
    install_opkg_distfeeds
    fix_easytier_mk
    remove_attendedsysupgrade
    fix_kconfig_recursive_dependency
    install_feeds
    fix_smartdns_default_state
    fix_service_resource_limits
    fix_cups_libcups_avahi_depends
    fix_easytier_lua
    update_adguardhome
    patch_dockerman_ui
    update_script_priority
    update_geoip
    fix_openssl_ktls
    fix_opkg_check
    fix_quectel_cm
    install_pbr_cmcc
    update_package "runc" "releases" "v1.3.3"
    update_package "containerd" "releases" "v1.7.28"
    update_package "docker" "tags" "v28.5.2"
    update_package "dockerd" "releases" "v28.5.2"
    # apply_hash_fixes
}

main "$@"
