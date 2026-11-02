# Section 2: Manage Software — Solutions & Verification (4 Labs)

---

## Lab 2.1 — Configure access to RPM repositories

### Solution
```bash
mkdir -p /mnt/disc ~/labs/s2
sed -i '\|/mnt/disc|d' /etc/fstab
echo "/dev/sr0  /mnt/disc  iso9660  ro,defaults,nofail  0 0" >> /etc/fstab
systemctl daemon-reload
mount -a

cat << 'EOF' > /etc/yum.repos.d/local-dvd.repo
[BaseOS]
name=RHEL 10 BaseOS
baseurl=file:///mnt/disc/BaseOS
enabled=1
gpgcheck=0

[AppStream]
name=RHEL 10 AppStream
baseurl=file:///mnt/disc/AppStream
enabled=1
gpgcheck=0
EOF

dnf clean all
dnf makecache
```

### Verify
```bash
findmnt /mnt/disc                                            # expect /mnt/disc /dev/sr0 iso9660
dnf repolist --enabled | grep -cE 'BaseOS|AppStream'         # expect 2
```

**Explanation:** Mounting `/dev/sr0` in `/etc/fstab` ensures the local DVD repository survives a system reboot, and `/etc/yum.repos.d/local-dvd.repo` configures both `BaseOS` and `AppStream`.

---

## Lab 2.2 — Install and remove RPM software packages

### Solution
```bash
mkdir -p ~/labs/s2
dnf install -y zsh tmux
dnf remove -y nano
rpm -qa | grep -E '^(zsh|tmux)-[0-9]' > ~/labs/s2/installed_pkgs.txt
```

### Verify
```bash
rpm -q zsh tmux                              # expect both installed
rpm -q nano                                  # expect package nano is not installed
wc -l < ~/labs/s2/installed_pkgs.txt         # expect 2
```

**Explanation:** `dnf install -y` and `dnf remove -y` manage RPM packages and resolve dependencies automatically.

---

## Lab 2.3 — Configure access to Flatpak repositories

### Solution
```bash
mkdir -p ~/labs/s2 /srv/flatpak/exam-repo
dnf install -y flatpak ostree

ostree --repo=/srv/flatpak/exam-repo init --mode=archive-z2 2>/dev/null || true
flatpak remote-add --no-gpg-verify --if-not-exists exam-flatpak file:///srv/flatpak/exam-repo
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
```

### Verify
```bash
flatpak remotes | grep -c '^exam-flatpak'    # expect 1
flatpak remotes -d
```

**Explanation:** `flatpak remote-add --if-not-exists <NAME> <URL>` adds a Flatpak repository. Add `--no-gpg-verify` if the exam repository does not use GPG signing.

---

## Lab 2.4 — Install and remove Flatpak software packages

### Solution
```bash
mkdir -p ~/labs/s2
flatpak remotes > ~/labs/s2/flatpak_remotes.txt

# List available packages in exam-flatpak and install org.example.Hello:
flatpak remote-ls exam-flatpak
flatpak install -y exam-flatpak org.example.Hello
flatpak list > ~/labs/s2/flatpak_installed_before_remove.txt

# Uninstall org.example.Hello:
flatpak uninstall -y org.example.Hello
```

### Verify
```bash
grep -c 'exam-flatpak' ~/labs/s2/flatpak_remotes.txt                  # expect 1
grep -c 'org.example.Hello' ~/labs/s2/flatpak_installed_before_remove.txt  # expect 1
flatpak list | grep -c 'org.example.Hello'                            # expect 0 (removed)
```

**Explanation:** `flatpak install -y <remote> <app-id>` installs a Flatpak package and `flatpak uninstall -y <app-id>` removes it.
