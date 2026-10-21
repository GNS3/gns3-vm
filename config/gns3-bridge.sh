#!/usr/bin/env bash
set -e

# Source central config if not already exported by systemd
[ -f /etc/gns3/gns3-bridge.conf ] && source /etc/gns3/gns3-bridge.conf

BRIDGE="${BRIDGE_NAME:-gns3br0}"
SUBNET="${BRIDGE_SUBNET:-192.168.122.0/24}"

case "$1" in
  start)
    iptables -N GNS3_IN
    iptables -N GNS3_OUT
    iptables -N GNS3_FWX
    iptables -N GNS3_FWI
    iptables -N GNS3_FWO
    iptables -t nat -N GNS3_PRT

    iptables -A INPUT -j GNS3_IN
    iptables -A OUTPUT -j GNS3_OUT
    iptables -A FORWARD -j GNS3_FWX
    iptables -A FORWARD -j GNS3_FWI
    iptables -A FORWARD -j GNS3_FWO
    iptables -t nat -A POSTROUTING -j GNS3_PRT

    # GNS3_IN: Allow inbound DNS (53) and DHCP server (67) requests on the bridge
    iptables -A GNS3_IN -i "$BRIDGE" -p udp --dport 53 -j ACCEPT
    iptables -A GNS3_IN -i "$BRIDGE" -p tcp --dport 53 -j ACCEPT
    iptables -A GNS3_IN -i "$BRIDGE" -p udp --dport 67 -j ACCEPT
    iptables -A GNS3_IN -i "$BRIDGE" -p tcp --dport 67 -j ACCEPT

    # GNS3_OUT: Allow outbound DNS (53) and DHCP client (68) responses from the host
    iptables -A GNS3_OUT -o "$BRIDGE" -p udp --dport 53 -j ACCEPT
    iptables -A GNS3_OUT -o "$BRIDGE" -p tcp --dport 53 -j ACCEPT
    iptables -A GNS3_OUT -o "$BRIDGE" -p udp --dport 68 -j ACCEPT
    iptables -A GNS3_OUT -o "$BRIDGE" -p tcp --dport 68 -j ACCEPT

    # GNS3_FWX: Allow intra-bridge communication (VM to VM on the same bridge)
    iptables -A GNS3_FWX -i "$BRIDGE" -o "$BRIDGE" -j ACCEPT

    # GNS3_FWI: Allow incoming traffic back to the subnet ONLY if established/related
    iptables -A GNS3_FWI -d "$SUBNET" -o "$BRIDGE" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -A GNS3_FWI -o "$BRIDGE" -j REJECT --reject-with icmp-port-unreachable

    # GNS3_FWO: Allow outbound traffic originating from the bridge subnet
    iptables -A GNS3_FWO -s "$SUBNET" -i "$BRIDGE" -j ACCEPT
    iptables -A GNS3_FWO -i "$BRIDGE" -j REJECT --reject-with icmp-port-unreachable

    # GNS3_PRT: Outbound masquerading
    iptables -t nat -A GNS3_PRT -s "$SUBNET" -d 224.0.0.0/24 -j RETURN
    iptables -t nat -A GNS3_PRT -s "$SUBNET" -d 255.255.255.255/32 -j RETURN
    iptables -t nat -A GNS3_PRT -s "$SUBNET" -p tcp ! -d "$SUBNET" -j MASQUERADE --to-ports 1024-65535
    iptables -t nat -A GNS3_PRT -s "$SUBNET" -p udp ! -d "$SUBNET" -j MASQUERADE --to-ports 1024-65535
    iptables -t nat -A GNS3_PRT -s "$SUBNET" ! -d "$SUBNET" -j MASQUERADE
    ;;

  stop)
    iptables -D INPUT -j GNS3_IN || true
    iptables -D OUTPUT -j GNS3_OUT || true
    iptables -D FORWARD -j GNS3_FWX || true
    iptables -D FORWARD -j GNS3_FWI || true
    iptables -D FORWARD -j GNS3_FWO || true
    iptables -t nat -D POSTROUTING -j GNS3_PRT || true

    iptables -F GNS3_IN || true
    iptables -F GNS3_OUT || true
    iptables -F GNS3_FWX || true
    iptables -F GNS3_FWI || true
    iptables -F GNS3_FWO || true
    iptables -t nat -F GNS3_PRT || true

    iptables -X GNS3_IN || true
    iptables -X GNS3_OUT || true
    iptables -X GNS3_FWX || true
    iptables -X GNS3_FWI || true
    iptables -X GNS3_FWO || true
    iptables -t nat -X GNS3_PRT || true
    ;;

  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
