# Section 8: Manage Basic Networking — Solutions & Verification (4 Labs)

---

## Lab 8.1 — Configure IPv4 and IPv6 addresses

### Solution
```bash
nmcli con delete s8-static 2>/dev/null || true
ip link add s8eth0 type dummy 2>/dev/null || true
ip link set s8eth0 up

nmcli con add con-name s8-static ifname s8eth0 type dummy \
  ipv4.method manual ipv4.addresses 172.25.250.50/24 \
  ipv6.method manual ipv6.addresses fd00:250::50/64

nmcli con up s8-static
```

### Verify
```bash
ip -4 addr show dev s8eth0 | grep -c '172.25.250.50/24'  # expect 1
ip -6 addr show dev s8eth0 | grep -c 'fd00:250::50/64'   # expect 1
```

**Explanation:** `nmcli con add` (or `nmcli con mod` on an existing profile) sets both `ipv4.addresses` and `ipv6.addresses` persistently under `/etc/NetworkManager/system-connections/`.

---

## Lab 8.2 — Configure hostname resolution

### Solution
```bash
hostnamectl set-hostname node1.lab.example.com

sed -i '/app\.lab\.example\.com/d' /etc/hosts
cat << 'EOF' >> /etc/hosts
172.25.250.50  app.lab.example.com app
fd00:250::50   app.lab.example.com app
EOF

nmcli con mod s8-static ipv4.dns 172.25.250.254 ipv4.dns-search lab.example.com
nmcli con up s8-static
```

### Verify
```bash
hostnamectl --static                                     # expect node1.lab.example.com
getent hosts app.lab.example.com | grep -c '172.25.250.50' # expect 1
nmcli -g ipv4.dns con show s8-static                     # expect 172.25.250.254
```

**Explanation:** `/etc/hosts` provides local static hostname resolution for IPv4 and IPv6, while `ipv4.dns` and `ipv4.dns-search` configure DNS resolver settings in NetworkManager.

---

## Lab 8.3 — Configure network services to start automatically at boot

### Solution
```bash
PRIMARY_CON=$(nmcli -t -f NAME con show --active | head -n1)
nmcli con mod "$PRIMARY_CON" connection.autoconnect yes
nmcli con mod s8-static connection.autoconnect yes

dnf install -y httpd &>/dev/null || true
systemctl enable --now NetworkManager sshd httpd
```

### Verify
```bash
nmcli -g connection.autoconnect con show s8-static       # expect yes
systemctl is-enabled NetworkManager sshd httpd           # expect enabled (all 3)
```

**Explanation:** `connection.autoconnect yes` ensures the network interface activates automatically at boot, and `systemctl enable --now` ensures network daemons start at boot.

---

## Lab 8.4 — Restrict network access using `firewalld` and `firewall-cmd`

### Solution
```bash
systemctl enable --now firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=8443/tcp
firewall-cmd --permanent --zone=drop --add-source=198.51.100.0/24

firewall-cmd --reload
```

### Verify
```bash
firewall-cmd --list-services | grep -cE 'http.*https'    # expect 1
firewall-cmd --list-ports | grep -c '8443/tcp'           # expect 1
firewall-cmd --zone=drop --list-sources | grep -c '198.51.100.0/24' # expect 1
```

**Explanation:** Always combine `--permanent` with `firewall-cmd --reload` so firewall rules apply immediately AND survive a system reboot.
