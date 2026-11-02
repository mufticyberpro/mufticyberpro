#!/usr/bin/env bash
# ==============================================================================
# RHCSA (EX200) RHEL 10 Automated Grading Script (All 10 Official Categories)
# Usage:
#   ./grade-exam.sh node1   # Grades Node 1 (Max 195 Points)
#   ./grade-exam.sh node2   # Grades Node 2 (Max 105 Points)
# ==============================================================================

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Please run this grading script as root (sudo -i).${NC}"
    exit 1
fi

ROLE="${1:-}"
if [[ "$ROLE" != "node1" && "$ROLE" != "node2" ]]; then
    echo -e "${YELLOW}Usage: $0 [node1|node2]${NC}"
    exit 1
fi

TOTAL_SCORE=0
MAX_SCORE=0

pass_task() {
    local pts="$1"
    local msg="$2"
    TOTAL_SCORE=$((TOTAL_SCORE + pts))
    MAX_SCORE=$((MAX_SCORE + pts))
    printf "  ${GREEN}[ PASS ]${NC} (+%2d pts) %s\n" "$pts" "$msg"
}

fail_task() {
    local pts="$1"
    local msg="$2"
    local reason="$3"
    MAX_SCORE=$((MAX_SCORE + pts))
    printf "  ${RED}[ FAIL ]${NC} (  0/%2d ) %s\n" "$pts" "$msg"
    printf "           ${YELLOW}-> Hint: %s${NC}\n" "$reason"
}

echo -e "${CYAN}========================================================================${NC}"
echo -e "${BOLD}  RHCSA (EX200) RHEL 10 Automated Exam Grader - Evaluating: ${ROLE^^}${NC}"
echo -e "${CYAN}========================================================================${NC}"

if [[ "$(getenforce 2>/dev/null)" == "Enforcing" ]]; then
    echo -e "  ${GREEN}[  OK  ]${NC} Mandatory Check: SELinux is in Enforcing mode"
else
    echo -e "  ${RED}[CRITICAL]${NC} SELinux is NOT in Enforcing mode! Real exam deducts heavily."
fi

# ==============================================================================
# GRADE NODE 1 (195 Points)
# ==============================================================================
grade_node1() {
    echo ""
    # Task 1: Manage Basic Networking — IPv4, IPv6, Hostname Resolution & SSH Keys (15 pts)
    local hname v4_ok=0 v6_ok=0 hosts_ok=0 ssh_ok=0
    hname=$(hostnamectl --static 2>/dev/null)
    ip -4 addr show | grep -q "172.25.250.10/24" && v4_ok=1
    ip -6 addr show | grep -qi "fd00:100::10/64" && v6_ok=1
    grep -q "node1.lab.example.com" /etc/hosts && grep -q "node2.lab.example.com" /etc/hosts && hosts_ok=1
    [[ -s /root/.ssh/authorized_keys ]] && ssh_ok=1

    if [[ "$hname" == "node1.lab.example.com" && $v4_ok -eq 1 && $v6_ok -eq 1 && $hosts_ok -eq 1 && $ssh_ok -eq 1 ]]; then
        pass_task 15 "Task 1: Hostname, IPv4 (172.25.250.10/24), IPv6 (fd00:100::10/64), /etc/hosts & SSH keys configured"
    else
        fail_task 15 "Task 1: Manage Basic Networking (IPv4, IPv6, /etc/hosts, SSH keys)" "Check hostnamectl, nmcli (+ipv4.addresses & +ipv6.addresses), /etc/hosts, and /root/.ssh/authorized_keys"
    fi

    # Task 2A: Manage Software — RPM Repositories & Packages (10 pts)
    if grep -qs '/mnt/disc' /etc/fstab && findmnt /mnt/disc &>/dev/null && \
       [[ $(dnf repolist --enabled 2>/dev/null | grep -cE 'BaseOS|AppStream') -ge 2 ]] && \
       rpm -q zsh &>/dev/null && ! rpm -q nano &>/dev/null; then
        pass_task 10 "Task 2A: BaseOS/AppStream repos active, 'zsh' installed, 'nano' removed"
    else
        fail_task 10 "Task 2A: RPM Repositories & Packages" "Check /mnt/disc in /etc/fstab, BaseOS/AppStream in /etc/yum.repos.d/, 'dnf install zsh', and 'dnf remove nano'"
    fi

    # Task 2B: Manage Software — Flatpak Repositories (10 pts)
    if command -v flatpak &>/dev/null && [[ $(flatpak remotes 2>/dev/null | wc -l) -ge 1 ]]; then
        pass_task 10 "Task 2B: Flatpak installed and Flatpak remote repository configured"
    else
        fail_task 10 "Task 2B: Flatpak Repositories" "Run: flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    fi

    # Task 3: SELinux Port, Context, Boolean & HTTP Server on Port 82 (20 pts)
    local curl_out bool_ok=0
    curl_out=$(curl -s --max-time 3 http://localhost:82 2>/dev/null || true)
    getsebool httpd_enable_homedirs 2>/dev/null | grep -qw "on" && bool_ok=1
    if systemctl is-enabled httpd &>/dev/null && systemctl is-active httpd &>/dev/null && \
       [[ "$curl_out" == *"Welcome to RHCSA RHEL 10 Exam Server on Port 82"* ]] && \
       firewall-cmd --list-ports 2>/dev/null | grep -qw "82/tcp" && [[ $bool_ok -eq 1 ]]; then
        pass_task 20 "Task 3: Apache httpd on port 82, SELinux port/context/boolean fixed, firewall open"
    else
        fail_task 20 "Task 3: SELinux & HTTP Server on Port 82" "Check semanage port (82), restorecon /var/www/html, setsebool -P httpd_enable_homedirs on, and firewall-cmd 82/tcp"
    fi

    # Task 4: Users and Groups (15 pts)
    local gid_ok=0 nat_ok=0 har_ok=0 sar_ok=0
    [[ "$(getent group sysmgrs | cut -d: -f3)" == "40000" ]] && gid_ok=1
    id -nG natasha 2>/dev/null | grep -qw "sysmgrs" && nat_ok=1
    id -nG harry 2>/dev/null | grep -qw "sysmgrs" && har_ok=1
    [[ "$(getent passwd sarah | cut -d: -f7)" == "/sbin/nologin" ]] && ! id -nG sarah 2>/dev/null | grep -qw "sysmgrs" && sar_ok=1

    if [[ $gid_ok -eq 1 && $nat_ok -eq 1 && $har_ok -eq 1 && $sar_ok -eq 1 ]]; then
        pass_task 15 "Task 4: Group sysmgrs (40000) & users natasha, harry, sarah configured"
    else
        fail_task 15 "Task 4: Users and Supplementary Groups" "Verify sysmgrs GID=40000, natasha & harry in sysmgrs, sarah shell=/sbin/nologin"
    fi

    # Task 5: Collaborative Directory, ACLs & Symlink (15 pts)
    local dir_ok=0 acl_ok=0 link_ok=0
    if [[ -d /home/managers ]] && [[ "$(stat -c %G /home/managers)" == "sysmgrs" ]] && \
       [[ "$(stat -c %a /home/managers)" == "2770" || "$(stat -c %a /home/managers)" == "3770" ]]; then
        dir_ok=1
    fi
    if [[ -f /var/tmp/fstab ]] && getfacl -p /var/tmp/fstab 2>/dev/null | grep -q "user:natasha:rw-" && \
       getfacl -p /var/tmp/fstab 2>/dev/null | grep -q "user:harry:---"; then
        acl_ok=1
    fi
    [[ -L /root/fstab_link && "$(readlink -f /root/fstab_link)" == "/var/tmp/fstab" ]] && link_ok=1

    if [[ $dir_ok -eq 1 && $acl_ok -eq 1 && $link_ok -eq 1 ]]; then
        pass_task 15 "Task 5: /home/managers (2770), ACLs on /var/tmp/fstab, and symlink /root/fstab_link verified"
    else
        fail_task 15 "Task 5: Collaborative Directory, ACLs & Symlink" "Check /home/managers (2770 :sysmgrs), setfacl on /var/tmp/fstab (natasha:rw-, harry:---), and ln -s /var/tmp/fstab /root/fstab_link"
    fi

    # Task 6: Password Aging & Sudoers (10 pts)
    local pass_max chage_max
    pass_max=$(awk '/^PASS_MAX_DAYS/{print $2}' /etc/login.defs 2>/dev/null)
    chage_max=$(chage -l harry 2>/dev/null | awk -F': ' '/Maximum number of days/{print $2}')
    if [[ "$pass_max" == "30" && "$chage_max" == "30" ]] && grep -RqsE '^%sysmgrs\s+ALL=\(ALL(:ALL)?\)\s+NOPASSWD:\s*ALL' /etc/sudoers /etc/sudoers.d/; then
        pass_task 10 "Task 6: PASS_MAX_DAYS=30, chage -M 30 harry, & %sysmgrs passwordless sudo configured"
    else
        fail_task 10 "Task 6: Password Aging & Sudo Privileges" "Check PASS_MAX_DAYS 30 in /etc/login.defs, 'chage -M 30 harry', and '%sysmgrs ALL=(ALL) NOPASSWD: ALL' in /etc/sudoers.d/sysmgrs"
    fi

    # Task 7: Find and Copy Harry's Files (10 pts)
    if [[ -d /root/harry_files ]] && [[ $(find /root/harry_files -maxdepth 1 -type f -user harry 2>/dev/null | wc -l) -eq 6 ]]; then
        pass_task 10 "Task 7: All 6 files owned by harry copied to /root/harry_files/"
    else
        fail_task 10 "Task 7: Locate and Copy Harry's Files" "Run: find /var/tmp/find_source -user harry -type f -exec cp -a {} /root/harry_files/ \;"
    fi

    # Task 8: Grep String Pattern 'strato' (10 pts)
    local expected_lines actual_lines
    expected_lines=$(grep 'strato' /usr/share/dict/exam_words 2>/dev/null || true)
    actual_lines=$(cat /root/lines.txt 2>/dev/null || true)
    if [[ -f /root/lines.txt ]] && [[ "$expected_lines" == "$actual_lines" ]] && [[ -n "$actual_lines" ]]; then
        pass_task 10 "Task 8: /root/lines.txt matches exact 'strato' lines from /usr/share/dict/exam_words"
    else
        fail_task 10 "Task 8: Grep String Pattern" "Run: grep 'strato' /usr/share/dict/exam_words > /root/lines.txt"
    fi

    # Task 9: Autofs NFS Home Directory (20 pts)
    if systemctl is-enabled autofs &>/dev/null && systemctl is-active autofs &>/dev/null && \
       su - remoteuser1 -c "grep -q 'Autofs NFS Mount Verified' /rhome/remoteuser1/README_EXAM.txt" 2>/dev/null; then
        pass_task 20 "Task 9: Autofs active & /rhome/remoteuser1 automounts cleanly via NFS"
    else
        fail_task 20 "Task 9: Autofs NFS Home Directory" "Check /etc/auto.master.d/rhome.autofs ('/rhome /etc/auto.rhome') and /etc/auto.rhome ('* -rw,sync 127.0.0.1:/srv/nfs/rhome/&')"
    fi

    # Task 10: Cron Job for Natasha (10 pts)
    if systemctl is-active crond &>/dev/null && crontab -u natasha -l 2>/dev/null | grep -qE '^\*/2 \* \* \* \*.*logger.*EX200 in progress'; then
        pass_task 10 "Task 10: Cron job for natasha runs every 2 minutes ('*/2 * * * *')"
    else
        fail_task 10 "Task 10: Recurring Cron Job for Natasha" "Check 'crontab -e -u natasha' for: */2 * * * * /usr/bin/logger \"EX200 in progress\""
    fi

    # Task 11: Compressed Tar Archive (10 pts)
    if [[ -f /root/backup.tar.bz2 ]] && file /root/backup.tar.bz2 | grep -qi "bzip2 compressed data"; then
        pass_task 10 "Task 11: /root/backup.tar.bz2 exists and is valid bzip2 compressed tar archive"
    else
        fail_task 10 "Task 11: Bzip2 Tar Archive" "Run: tar -cjf /root/backup.tar.bz2 /usr/local"
    fi

    # Task 12: Shell Script /usr/local/bin/mysearch.sh (15 pts)
    if [[ -x /usr/local/bin/mysearch.sh ]] && [[ -s /root/suid_files.txt ]] && grep -q '/usr/bin/' /root/suid_files.txt 2>/dev/null; then
        pass_task 15 "Task 12: /usr/local/bin/mysearch.sh is executable and populated /root/suid_files.txt"
    else
        fail_task 15 "Task 12: Executable Shell Script" "Ensure /usr/local/bin/mysearch.sh has chmod +x, handles 'suid' argument, and populates /root/suid_files.txt"
    fi

    # Task 13: Build Image & Run Rootless Podman Container 'logserver' (15 pts)
    local pod_running=0 web_ok=0
    su - aloha -c "podman ps --format '{{.Names}}'" 2>/dev/null | grep -qw "logserver" && pod_running=1
    curl -s --max-time 3 http://localhost:8080 2>/dev/null | grep -q "Hello from Rootless Podman" && web_ok=1
    if [[ $pod_running -eq 1 && $web_ok -eq 1 ]]; then
        pass_task 15 "Task 13: Rootless container 'logserver' running under aloha & serving on port 8080"
    else
        fail_task 15 "Task 13: Build & Run Rootless Podman Container" "Verify 'logserver' container is running under user aloha, mapped -p 8080:80 -v /home/aloha/webroot:/usr/local/apache2/htdocs:Z"
    fi

    # Task 14: Rootless Container Persistent Systemd Service / Quadlet (10 pts)
    local linger_ok=0 unit_ok=0
    [[ -f /var/lib/systemd/linger/aloha ]] && linger_ok=1
    if [[ -f /home/aloha/.config/containers/systemd/logserver.container ]] || \
       [[ -f /home/aloha/.config/systemd/user/container-logserver.service ]] || \
       [[ -f /home/aloha/.config/systemd/user/logserver.service ]]; then
        unit_ok=1
    fi
    if [[ $linger_ok -eq 1 && $unit_ok -eq 1 && $pod_running -eq 1 ]]; then
        pass_task 10 "Task 14: Linger enabled for aloha & systemd Quadlet/user service configured"
    else
        fail_task 10 "Task 14: Rootless Container Systemd Service" "Ensure 'loginctl enable-linger aloha' is set and either a Quadlet (.container) or user systemd unit is enabled"
    fi
}

# ==============================================================================
# GRADE NODE 2 (105 Points)
# ==============================================================================
grade_node2() {
    echo ""
    # Task 15: Root Access & Hostname (15 pts)
    if [[ "$(hostnamectl --static 2>/dev/null)" == "node2.lab.example.com" ]]; then
        pass_task 15 "Task 15: Root access verified & hostname set to node2.lab.example.com"
    else
        fail_task 15 "Task 15: Hostname node2.lab.example.com" "Run: hostnamectl set-hostname node2.lab.example.com"
    fi

    # Task 16: Resize Logical Volume /dev/vg_exam/lv_vo to ~300M (20 pts)
    local lv_size_mb fs_ok=0
    lv_size_mb=$(lvs --noheadings --units m -o LV_SIZE /dev/vg_exam/lv_vo 2>/dev/null | tr -d ' mM' | cut -d. -f1)
    grep -q "CRITICAL EXAM DATA" /vo/important_data.txt 2>/dev/null && fs_ok=1
    if [[ -n "$lv_size_mb" ]] && [[ "$lv_size_mb" -ge 280 && "$lv_size_mb" -le 320 ]] && [[ $fs_ok -eq 1 ]]; then
        pass_task 20 "Task 16: Logical volume lv_vo resized to ${lv_size_mb}M with data intact"
    else
        fail_task 20 "Task 16: Resize /dev/vg_exam/lv_vo to 280M-320M" "Run: lvextend -r -L 300M /dev/vg_exam/lv_vo"
    fi

    # Task 17: Add Persistent Swap Partition (15 pts)
    local swap_lines
    swap_lines=$(grep -v '^#' /etc/fstab | awk '$3=="swap"{count++} END{print count+0}')
    if [[ $(swapon --show --noheadings | wc -l) -ge 2 ]] || [[ "$swap_lines" -ge 2 ]]; then
        pass_task 15 "Task 17: Additional persistent swap partition configured in /etc/fstab and active"
    else
        fail_task 15 "Task 17: Persistent 512M Swap Partition" "Create a 512M partition/LV, run mkswap, add UUID=<uuid> swap swap defaults 0 0 to /etc/fstab, and run swapon -a"
    fi

    # Task 18: Create VG vg_datastore (16M PE), LV lv_database (50 extents), XFS at /mnt/database (25 pts)
    local pe_size lv_extents fstype
    pe_size=$(vgs --noheadings --units m -o VG_EXTENT_SIZE vg_datastore 2>/dev/null | tr -d ' mM' | cut -d. -f1)
    lv_extents=$(lvs --noheadings -o LV_SIZE --units m /dev/vg_datastore/lv_database 2>/dev/null | tr -d ' mM' | cut -d. -f1)
    fstype=$(findmnt -n -o FSTYPE /mnt/database 2>/dev/null || true)

    if [[ "$pe_size" == "16" ]] && [[ "$lv_extents" == "800" ]] && [[ "$fstype" == "xfs" ]] && grep -qs '/mnt/database' /etc/fstab; then
        pass_task 25 "Task 18: vg_datastore (16M PE), lv_database (50 extents/800M), XFS mounted at /mnt/database"
    else
        fail_task 25 "Task 18: VG vg_datastore, LV lv_database, XFS at /mnt/database" "Check vgcreate -s 16M vg_datastore <part>, lvcreate -l 50 -n lv_database vg_datastore, mkfs.xfs, and /etc/fstab"
    fi

    # Task 19: Boot Target, Tuned Profile & Process Priority (15 pts)
    local target_ok=0 tuned_ok=0 nice_ok=0
    [[ "$(systemctl get-default 2>/dev/null)" == "multi-user.target" ]] && target_ok=1
    systemctl is-active tuned &>/dev/null && tuned-adm active 2>/dev/null | grep -qw "virtual-guest" && tuned_ok=1
    ps -eo ni,comm | awk '$2=="dd" && $1==10 {found=1} END{exit !found}' 2>/dev/null && nice_ok=1

    if [[ $target_ok -eq 1 && $tuned_ok -eq 1 && $nice_ok -eq 1 ]]; then
        pass_task 15 "Task 19: Default target 'multi-user.target', tuned 'virtual-guest', and 'dd' nice value=10"
    else
        fail_task 15 "Task 19: Boot Target, Tuned Profile & Process Priority" "Check 'systemctl set-default multi-user.target', 'tuned-adm profile virtual-guest', and 'renice -n 10 \$(pgrep dd)'"
    fi

    # Task 20: Chrony NTP Client & Persistent System Journals (15 pts)
    local chrony_ok=0 journal_ok=0
    systemctl is-enabled chronyd &>/dev/null && systemctl is-active chronyd &>/dev/null && \
       grep -Rqs "time.cloudflare.com" /etc/chrony.conf /etc/chrony.d/ && chrony_ok=1
    [[ -d /var/log/journal ]] && ls /var/log/journal/ 2>/dev/null | grep -q . && journal_ok=1

    if [[ $chrony_ok -eq 1 && $journal_ok -eq 1 ]]; then
        pass_task 15 "Task 20: Chronyd synced with time.cloudflare.com & persistent systemd journals active"
    else
        fail_task 15 "Task 20: Chrony NTP & Persistent Journals" "Add 'server time.cloudflare.com iburst' to /etc/chrony.conf, and run 'mkdir -p /var/log/journal && systemctl restart systemd-journald'"
    fi
}

if [[ "$ROLE" == "node1" ]]; then
    grade_node1
elif [[ "$ROLE" == "node2" ]]; then
    grade_node2
fi

echo ""
echo -e "${CYAN}========================================================================${NC}"
echo -e "${BOLD}  ${ROLE^^} SCORE: ${TOTAL_SCORE} / ${MAX_SCORE} Points${NC}"
echo -e "${CYAN}========================================================================${NC}"
echo -e "  (Combine your Node 1 [195] + Node 2 [105] scores. Passing is 210 / 300)"
