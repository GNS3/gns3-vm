#!/usr/bin/env bash
set -e

source /etc/gns3/gns3-bridge.conf

# Generate Netplan YAML dynamically
cat <<EOF | sudo tee /etc/netplan/60_gns3vm_bridge_netcfg.yaml > /dev/null
network:
  version: 2
  renderer: networkd
  bridges:
    ${BRIDGE_NAME}:
      dhcp4: false
      addresses:
        - ${BRIDGE_IP}
      parameters:
        stp: false
        forward-delay: 0
EOF

# Prevent the dnsmasq system-wide daemon from colliding with gns3-dnsmasq service
if [ -d /etc/dnsmasq.d ]; then
cat <<EOF | sudo tee /etc/dnsmasq.d/gns3 > /dev/null
bind-interfaces
except-interface=${BRIDGE_NAME}
EOF
fi

# Replace the gns3-dnsmasq configuration with the new bridge name and DHCP range
cat <<EOF |  sudo tee /etc/gns3/gns3-dnsmasq.conf > /dev/null
strict-order
user=gns3
except-interface=lo
bind-dynamic
interface=${BRIDGE_NAME}
dhcp-range=${BRIDGE_DHCP_RANGE}
dhcp-no-override
dhcp-authoritative
dhcp-lease-max=253
dhcp-leasefile=/var/lib/misc/gns3-dnsmasq.leases
EOF

# Update the gns3server.conf with the new bridge name
sudo sed -i "s/^default_nat_interface = .*/default_nat_interface = ${BRIDGE_NAME}/" /opt/gns3/server/gns3_server.conf

# Apply netplan
sudo netplan apply

# Reload systemd and restart services
sudo systemctl daemon-reload
sudo systemctl restart gns3-dnsmasq.service
sudo systemctl restart gns3-bridge.service
sudo systemctl restart gns3.service

echo "Bridge configuration updated successfully to: ${BRIDGE_NAME}"