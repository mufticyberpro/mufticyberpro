# Section 8: Manage Basic Networking (4 Objectives = 4 Labs)

> **Official RHEL 10 Objectives in Section 8 (4 Objectives):**
> 1. Configure IPv4 and IPv6 addresses
> 2. Configure hostname resolution
> 3. Configure network services to start automatically at boot
> 4. Restrict network access using `firewalld` and `firewall-cmd`

---

## Lab 8.1 — Objective 1: Configure IPv4 and IPv6 addresses
**Task:**
1. Create a virtual dummy interface `s8eth0` (`ip link add s8eth0 type dummy && ip link set s8eth0 up`) so you can safely practice static IP configuration without disconnecting your main SSH session.
2. Create a NetworkManager connection profile named **`s8-static`** on interface `s8eth0` with:
   - Static **IPv4** address: **`172.25.250.50/24`** (`ipv4.method manual`)
   - Static **IPv6** address: **`fd00:250::50/64`** (`ipv6.method manual`)
3. Activate the `s8-static` connection (`nmcli con up s8-static`).

---

## Lab 8.2 — Objective 2: Configure hostname resolution
**Task:**
1. Set the system's static hostname to **`node1.lab.example.com`** (`hostnamectl set-hostname`).
2. Add entries in `/etc/hosts` so that `172.25.250.50` and `fd00:250::50` resolve to **`app.lab.example.com`** and short name **`app`**.
3. Configure the `s8-static` NetworkManager profile with DNS server **`172.25.250.254`** and DNS search domain **`lab.example.com`**.

---

## Lab 8.3 — Objective 3: Configure network services to start automatically at boot
**Task:**
1. Configure the NetworkManager connection **`s8-static`** (and your primary active connection) to start automatically at boot (`connection.autoconnect yes`).
2. Configure the network daemons **`NetworkManager`**, **`sshd`**, and **`httpd`** to start automatically at boot (`systemctl enable --now`).

---

## Lab 8.4 — Objective 4: Restrict network access using `firewalld` and `firewall-cmd`
**Task:**
1. Ensure `firewalld` is enabled and running.
2. Persistently allow the **`http`** and **`https`** services and TCP port **`8443/tcp`** in the default zone.
3. Persistently restrict (block/drop) all incoming traffic from source subnet **`198.51.100.0/24`** by adding that source subnet to the **`drop`** zone.
4. Reload `firewalld` (`firewall-cmd --reload`).
