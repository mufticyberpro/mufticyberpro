#!/usr/bin/env bash
# ==============================================================================
# RHCSA (EX200) RHEL 10 Performance-Based Lab Provisioning Script
# Usage:
#   ./setup-lab.sh node1
#   ./setup-lab.sh node2
# ==============================================================================

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Please run this script as root (sudo -i).${NC}"
    exit 1
fi

ROLE="${1:-}"
if [[ "$ROLE" != "node1" && "$ROLE" != "node2" ]]; then
    echo -e "${YELLOW}Usage: $0 [node1|node2]${NC}"
    exit 1
fi

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}  Preparing RHCSA (EX200) RHEL 10 Practice Environment: ${ROLE^^}  ${NC}"
echo -e "${CYAN}================================================================${NC}"

mount_iso_temp() {
    mkdir -p /mnt/cdrom_temp /var/repo
    if blkid /dev/sr0 &>/dev/null; then
        echo -e "${GREEN}[+] Found RHEL DVD ISO on /dev/sr0. Mounting temporarily for setup...${NC}"
        mount -o ro /dev/sr0 /var/repo 2>/dev/null || true
    else
        echo -e "${YELLOW}[!] Warning: /dev/sr0 (RHEL 10 ISO) not detected.${NC}"
        echo -e "${YELLOW}    Make sure the RHEL 10 DVD ISO is connected in VMware CD/DVD settings.${NC}"
    fi
}

# ==============================================================================
# NODE 1 SETUP
# ==============================================================================
setup_node1() {
    mount_iso_temp

    echo -e "${GREEN}[1/8] Installing base packages for lab scenarios...${NC}"
    dnf install -y httpd nfs-utils policycoreutils-python-utils podman flatpak nano tar bzip2 gzip tuned chrony acl &>/dev/null || \
        echo -e "${YELLOW}[!] Could not auto-install all packages via current DNF repos. Ensure repos or DVD ISO are available.${NC}"
    dnf remove -y zsh &>/dev/null || true

    echo -e "${GREEN}[2/8] Setting up Task 2 (Local Repository directory /mnt/disc & mock Flatpak repo)...${NC}"
    mkdir -p /mnt/disc /srv/flatpak/repo
    if blkid /dev/sr0 &>/dev/null; then
        umount /var/repo 2>/dev/null || true
        mount -o ro /dev/sr0 /mnt/disc 2>/dev/null || true
    fi
    # Back up existing repos so the student configures Task 2A
    mkdir -p /root/.repo_backup
    mv /etc/yum.repos.d/*.repo /root/.repo_backup/ 2>/dev/null || true

    echo -e "${GREEN}[3/8] Setting up Task 3 (Broken SELinux Web Server on Port 82)...${NC}"
    mkdir -p /var/www/html
    cat << 'EOF' > /var/www/html/index.html
Welcome to RHCSA RHEL 10 Exam Server on Port 82
EOF
    chcon -t user_home_t /var/www/html/index.html 2>/dev/null || true
    setsebool -P httpd_enable_homedirs off 2>/dev/null || true
    if [[ -f /etc/httpd/conf/httpd.conf ]]; then
        sed -i 's/^Listen 80$/Listen 82/' /etc/httpd/conf/httpd.conf
    fi
    systemctl stop httpd 2>/dev/null || true
    systemctl disable httpd 2>/dev/null || true
    systemctl enable --now firewalld 2>/dev/null || true

    echo -e "${GREEN}[4/8] Setting up Task 7 (Pre-existing user 'harry' for find/copy task)...${NC}"
    id harry &>/dev/null || useradd harry
    mkdir -p /var/tmp/find_source /var/tmp/decoy_dir
    for i in {1..6}; do
        echo "Harry's important data file $i" > "/var/tmp/find_source/harry_doc_${i}.txt"
        chown harry:harry "/var/tmp/find_source/harry_doc_${i}.txt"
        chmod 640 "/var/tmp/find_source/harry_doc_${i}.txt"
    done
    echo "Root owned decoy file" > /var/tmp/find_source/root_decoy.txt

    echo -e "${GREEN}[5/8] Setting up Task 8 (Grep source file /usr/share/dict/exam_words)...${NC}"
    mkdir -p /usr/share/dict
    cat << 'EOF' > /usr/share/dict/exam_words
alpha
strato
substratum
beta
catastrophe
stratosphere
gamma
   stratify
delta
illustrate
epsilon
EOF

    echo -e "${GREEN}[6/8] Setting up Task 9 (NFS Server Export for Autofs /rhome/remoteuser1)...${NC}"
    id -u 2050 &>/dev/null || useradd -u 2050 -d /rhome/remoteuser1 -M -s /bin/bash remoteuser1
    echo "password" | passwd --stdin remoteuser1 &>/dev/null || echo "remoteuser1:password" | chpasswd
    mkdir -p /srv/nfs/rhome/remoteuser1
    cp -a /etc/skel/. /srv/nfs/rhome/remoteuser1/ 2>/dev/null || true
    echo "Autofs NFS Mount Verified!" > /srv/nfs/rhome/remoteuser1/README_EXAM.txt
    chown -R 2050:2050 /srv/nfs/rhome/remoteuser1
    chmod 700 /srv/nfs/rhome/remoteuser1

    cat << 'EOF' > /etc/exports
/srv/nfs/rhome *(rw,sync,no_root_squash)
EOF
    systemctl enable --now nfs-server 2>/dev/null || true
    exportfs -ra 2>/dev/null || true
    firewall-cmd --permanent --add-service=nfs --add-service=mountd --add-service=rpc-bind &>/dev/null || true
    firewall-cmd --reload &>/dev/null || true

    echo -e "${GREEN}[7/8] Setting up Task 13 & 14 (Container user 'aloha' & Containerfile in /home/aloha/build)...${NC}"
    id aloha &>/dev/null || useradd aloha
    echo "atenorth" | passwd --stdin aloha &>/dev/null || echo "aloha:atenorth" | chpasswd
    mkdir -p /home/aloha/build
    cat << 'EOF' > /home/aloha/build/Containerfile
FROM docker.io/library/httpd:latest
LABEL maintainer="RHCSA Candidate"
EXPOSE 80
EOF
    chown -R aloha:aloha /home/aloha/build

    echo -e "${GREEN}[8/8] Verifying Node 1 readiness...${NC}"
    echo ""
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${GREEN}[SUCCESS] NODE 1 Lab Environment is Ready!${NC}"
    echo -e "${CYAN}================================================================${NC}"
}

# ==============================================================================
# NODE 2 SETUP
# ==============================================================================
setup_node2() {
    mount_iso_temp

    echo -e "${GREEN}[1/5] Detecting secondary unpartitioned disk for LVM tasks...${NC}"
    PRIMARY_DISK=$(lsblk -no PKNAME "$(findmnt -n -o SOURCE /)" | head -n1)
    SECOND_DISK=""
    for dev in $(lsblk -dnpo NAME,TYPE | awk '$2=="disk"{print $1}'); do
        if [[ "$dev" != "/dev/${PRIMARY_DISK}" ]]; then
            if ! lsblk -no MOUNTPOINT "$dev" | grep -q '/'; then
                SECOND_DISK="$dev"
                break
            fi
        fi
    done

    if [[ -z "$SECOND_DISK" ]]; then
        echo -e "${YELLOW}[!] No secondary physical disk found! Creating a 10GB loopback disk (/var/lib/exam_disk.img)...${NC}"
        fallocate -l 10G /var/lib/exam_disk.img
        SECOND_DISK=$(losetup -f --show /var/lib/exam_disk.img)
        cat << EOF > /etc/systemd/system/exam-loopdisk.service
[Unit]
Description=Attach RHCSA Exam Loopback Disk
DefaultDependencies=no
Before=local-fs-pre.target lvm2-activation.service

[Service]
Type=oneshot
ExecStart=/usr/sbin/losetup /dev/loop5 /var/lib/exam_disk.img
RemainAfterExit=yes

[Install]
WantedBy=local-fs.target
EOF
        systemctl daemon-reload
        systemctl enable exam-loopdisk.service &>/dev/null || true
    fi

    echo -e "${GREEN}[+] Using disk ${SECOND_DISK} for Node 2 storage tasks.${NC}"

    echo -e "${GREEN}[2/5] Creating pre-existing Volume Group 'vg_exam' and LV 'lv_vo' (for Task 16 Resize)...${NC}"
    umount /vo 2>/dev/null || true
    lvremove -f /dev/vg_exam/lv_vo 2>/dev/null || true
    vgremove -f vg_exam 2>/dev/null || true
    wipefs -a "$SECOND_DISK" &>/dev/null || true

    parted -s "$SECOND_DISK" mklabel gpt
    parted -s "$SECOND_DISK" mkpart primary 1MiB 2049MiB
    parted -s "$SECOND_DISK" set 1 lvm on
    udevadm settle

    if [[ "$SECOND_DISK" =~ [0-9]$ ]]; then
        PART1="${SECOND_DISK}p1"
    else
        PART1="${SECOND_DISK}1"
    fi

    pvcreate -f "$PART1" &>/dev/null
    vgcreate vg_exam "$PART1" &>/dev/null
    lvcreate -L 180M -n lv_vo vg_exam &>/dev/null
    mkfs.ext4 -F /dev/vg_exam/lv_vo &>/dev/null

    mkdir -p /vo
    UUID_VO=$(blkid -s UUID -o value /dev/vg_exam/lv_vo)
    sed -i '\|/vo|d' /etc/fstab
    echo "UUID=${UUID_VO} /vo ext4 defaults 0 0" >> /etc/fstab
    mount -a
    echo "CRITICAL EXAM DATA - DO NOT DESTROY DURING LVM RESIZE" > /vo/important_data.txt

    echo -e "${GREEN}[3/5] Starting background 'dd' process for Task 19 process priority (renice) task...${NC}"
    cat << 'EOF' > /etc/systemd/system/exam-dd-worker.service
[Unit]
Description=RHCSA Exam Background CPU Worker for renice Task 19
After=multi-user.target

[Service]
ExecStart=/usr/bin/dd if=/dev/zero of=/dev/null
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now exam-dd-worker.service &>/dev/null || true

    echo -e "${GREEN}[4/5] Preparing repository directory on Node 2...${NC}"
    mkdir -p /mnt/disc
    if blkid /dev/sr0 &>/dev/null; then
        mount -o ro /dev/sr0 /mnt/disc 2>/dev/null || true
    fi

    echo -e "${GREEN}[5/5] Task 15 (Root Password Reset Option)...${NC}"
    read -r -p "Do you want to scramble Node 2's root password now so you must use 'rd.break' to log in? [y/N]: " SCRAMBLE
    if [[ "$SCRAMBLE" =~ ^[Yy]$ ]]; then
        RANDOM_PASS=$(tr -dc 'A-Za-z0-9!@#$%' < /dev/urandom | head -c 24)
        echo "root:${RANDOM_PASS}" | chpasswd
        echo -e "${RED}[!] Node 2 root password has been scrambled!${NC}"
        echo -e "${YELLOW}    Reboot Node 2 and interrupt GRUB to reset the root password to: atenorth${NC}"
    else
        echo -e "${YELLOW}[*] Keeping current root password. You can still practice rd.break and set it to 'atenorth'.${NC}"
    fi

    echo ""
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${GREEN}[SUCCESS] NODE 2 Lab Environment is Ready!${NC}"
    echo -e "${CYAN}================================================================${NC}"
}

if [[ "$ROLE" == "node1" ]]; then
    setup_node1
elif [[ "$ROLE" == "node2" ]]; then
    setup_node2
fi
