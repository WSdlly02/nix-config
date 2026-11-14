#!/usr/bin/env bash
set -euo pipefail

# 配置区：按需修改
ETH_IF="eth0"
WLAN_IF="wlan0"

# 用于测试的目标：
# - 如果你的 PC 开了 ICS/网卡共享，可以填 PC 的 IP
# - 或者直接用 8.8.8.8/1.1.1.1 等外网地址
TEST_HOST="10.42.0.1"

PING_COUNT=2
PING_TIMEOUT=1

log() {
    logger -t route-switch "$*"
    echo "$(date '+%F %T') route-switch: $*"
}

get_gw() {
    local iface="$1"
    ip route show dev "$iface" | awk '/default/ {print $3; exit}'
}

get_current_default_if() {
    ip route show default 2>/dev/null | awk '/default/ {print $5; exit}'
}

switch_default_route() {
    local iface="$1"
    local gw="$2"

    [ -z "$gw" ] && return 1

    # 替换默认路由
    ip route replace default via "$gw" dev "$iface"
    log "Switched default route to $iface via $gw"
}

# 1. 优先检查 eth0 是否“真正可用”

eth_gw="$(get_gw "$ETH_IF" || true)"
wlan_gw="$(get_gw "$WLAN_IF" || true)"
current_if="$(get_current_default_if || true)"

# eth0 必须：接口 UP + 有默认网关 + ping 成功
if ip link show "$ETH_IF" 2>/dev/null | grep -q "state UP" && [ -n "$eth_gw" ]; then
    if ping -I "$ETH_IF" -c "$PING_COUNT" -W "$PING_TIMEOUT" "$TEST_HOST" >/dev/null 2>&1; then
        # eth0 网络正常，必要时切过去
        if [ "$current_if" != "$ETH_IF" ]; then
            switch_default_route "$ETH_IF" "$eth_gw"
        else
            log "eth0 already default, nothing to do"
        fi
        exit 0
    else
        log "eth0 up but ping $TEST_HOST failed, will fall back to $WLAN_IF"
    fi
else
    log "eth0 not ready (no link or no default gw), will fall back to $WLAN_IF"
fi

# 2. eth0 不可用，则尝试切到 wlan0

if ip link show "$WLAN_IF" 2>/dev/null | grep -q "state UP" && [ -n "$wlan_gw" ]; then
    if [ "$current_if" != "$WLAN_IF" ]; then
        switch_default_route "$WLAN_IF" "$wlan_gw"
    else
        log "wlan0 already default, nothing to do"
    fi
else
    log "wlan0 is not ready (no link or no default gw) – leaving routes as-is"
fi
