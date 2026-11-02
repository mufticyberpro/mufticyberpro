# Section 2: Manage Software (4 Objectives = 4 Labs)

> **Official RHEL 10 Objectives in Section 2 (4 Objectives):**
> 1. Configure access to RPM repositories
> 2. Install and remove RPM software packages
> 3. Configure access to Flatpak repositories
> 4. Install and remove Flatpak software packages

---

## Lab 2.1 — Objective 1: Configure access to RPM repositories
**Task:**
1. Ensure `/mnt/disc` exists and mount the RHEL 10 DVD ISO (`/dev/sr0`) persistently at `/mnt/disc` via `/etc/fstab` (`iso9660`, `ro,defaults,nofail`).
2. Create `/etc/yum.repos.d/local-dvd.repo` with two enabled repositories:
   - `[BaseOS]` pointing to `file:///mnt/disc/BaseOS` (`gpgcheck=0`)
   - `[AppStream]` pointing to `file:///mnt/disc/AppStream` (`gpgcheck=0`)
3. Refresh the DNF cache (`dnf makecache`).

---

## Lab 2.2 — Objective 2: Install and remove RPM software packages
**Task:**
1. Install the **`zsh`** and **`tmux`** RPM packages non-interactively using `dnf`.
2. Remove the **`nano`** RPM package non-interactively using `dnf`.
3. Save the output of `rpm -qa | grep -E '^(zsh|tmux)'` to `~/labs/s2/installed_pkgs.txt`.

---

## Lab 2.3 — Objective 3: Configure access to Flatpak repositories
**Task:**
1. Ensure the `flatpak` and `ostree` RPM packages are installed.
2. Create a local Flatpak repository at `/srv/flatpak/exam-repo` (simulating the exam's offline Flatpak repository server) AND register it as a system-wide Flatpak remote named **`exam-flatpak`** (`--no-gpg-verify`).
3. Also register the **`flathub`** remote (`https://dl.flathub.org/repo/flathub.flatpakrepo`) if your VM has internet access.

---

## Lab 2.4 — Objective 4: Install and remove Flatpak software packages
**Task:**
1. List all configured Flatpak remotes and save the output to `~/labs/s2/flatpak_remotes.txt`.
2. Build and publish a minimal local Flatpak app named **`org.example.Hello`** into your `/srv/flatpak/exam-repo` repository (using the provided setup block below), then **install** `org.example.Hello` from `exam-flatpak`, verify it appears in `flatpak list`, and then **uninstall** it cleanly.

### Setup for Lab 2.4 (Run before starting Lab 2.4 to populate `/srv/flatpak/exam-repo` with `org.example.Hello`)
```bash
mkdir -p /srv/flatpak/exam-repo /tmp/fp-build/files/bin
cat << 'EOF' > /tmp/fp-build/metadata
[Application]
name=org.example.Hello
runtime=org.example.Hello/x86_64/stable
command=hello.sh
EOF
cat << 'EOF' > /tmp/fp-build/files/bin/hello.sh
#!/bin/sh
echo "Hello from RHCSA RHEL 10 Flatpak!"
EOF
chmod +x /tmp/fp-build/files/bin/hello.sh
ostree --repo=/srv/flatpak/exam-repo init --mode=archive-z2 2>/dev/null || true
flatpak build-export /srv/flatpak/exam-repo /tmp/fp-build stable
flatpak build-update-repo /srv/flatpak/exam-repo
```
