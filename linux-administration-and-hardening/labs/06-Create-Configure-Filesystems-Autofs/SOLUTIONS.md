# Section 6: Create and Configure File Systems — Solutions & Verification (5 Labs)

---

## Lab 6.1 — Create, mount, unmount, and use `vfat`, `ext4`, and `xfs` file systems

### Solution
```bash
lvcreate -y -L 160M -n lv_vfat vg_s5
lvcreate -y -L 160M -n lv_ext4 vg_s5
lvcreate -y -L 160M -n lv_xfs  vg_s5

mkfs.vfat /dev/vg_s5/lv_vfat
mkfs.ext4 -F /dev/vg_s5/lv_ext4
mkfs.xfs  -f /dev/vg_s5/lv_xfs

mkdir -p /mnt/s6_vfat /mnt/s6_ext4 /mnt/s6_xfs
mount /dev/vg_s5/lv_vfat /mnt/s6_vfat
mount /dev/vg_s5/lv_ext4 /mnt/s6_ext4
mount /dev/vg_s5/lv_xfs  /mnt/s6_xfs

echo "vfat ok" > /mnt/s6_vfat/test.txt
echo "ext4 ok" > /mnt/s6_ext4/test.txt
echo "xfs ok"  > /mnt/s6_xfs/test.txt

umount /mnt/s6_vfat
mount /dev/vg_s5/lv_vfat /mnt/s6_vfat
```

### Verify
```bash
findmnt -no FSTYPE /mnt/s6_vfat              # expect vfat
findmnt -no FSTYPE /mnt/s6_ext4              # expect ext4
findmnt -no FSTYPE /mnt/s6_xfs               # expect xfs
cat /mnt/s6_vfat/test.txt                    # expect vfat ok
```

**Explanation:** `mkfs.vfat`, `mkfs.ext4`, and `mkfs.xfs` format block devices with the three filesystem types required by the RHCSA exam.

---

## Lab 6.2 — Mount and unmount network file systems using NFS

### Solution
```bash
mkdir -p /srv/nfs/s6_share /mnt/s6_nfs
echo "NFS Share Active" > /srv/nfs/s6_share/nfs_ok.txt

sed -i '\|/srv/nfs/s6_share|d' /etc/exports
echo "/srv/nfs/s6_share *(rw,sync,no_root_squash)" >> /etc/exports
systemctl enable --now nfs-server
exportfs -ra

sed -i '\|/mnt/s6_nfs|d' /etc/fstab
echo "127.0.0.1:/srv/nfs/s6_share  /mnt/s6_nfs  nfs  rw,sync,_netdev,nofail  0 0" >> /etc/fstab
systemctl daemon-reload
mount -a
```

### Verify
```bash
findmnt -no FSTYPE /mnt/s6_nfs               # expect nfs4
cat /mnt/s6_nfs/nfs_ok.txt                   # expect NFS Share Active
```

**Explanation:** Adding `127.0.0.1:/srv/nfs/s6_share /mnt/s6_nfs nfs rw,sync,_netdev 0 0` in `/etc/fstab` mounts the NFS export persistently at boot.

---

## Lab 6.3 — Configure `autofs`

### Solution
```bash
mkdir -p /srv/nfs/s6_homes/ldapuser1
echo "Autofs Home Mounted" > /srv/nfs/s6_homes/ldapuser1/welcome.txt

sed -i '\|/srv/nfs/s6_homes|d' /etc/exports
echo "/srv/nfs/s6_homes *(rw,sync,no_root_squash)" >> /etc/exports
exportfs -ra

echo "/s6_homes  /etc/auto.s6_homes" > /etc/auto.master.d/s6_homes.autofs
echo "*  -rw,sync  127.0.0.1:/srv/nfs/s6_homes/&" > /etc/auto.s6_homes

systemctl enable --now autofs
systemctl restart autofs
```

### Verify
```bash
cat /s6_homes/ldapuser1/welcome.txt          # expect Autofs Home Mounted
findmnt -no FSTYPE /s6_homes/ldapuser1       # expect nfs4
```

**Explanation:** In `/etc/auto.s6_homes`, `*` matches any subdirectory requested under `/s6_homes` (such as `ldapuser1`), and `&` substitutes that subdirectory name into the remote NFS path.

---

## Lab 6.4 — Extend existing logical volumes

### Solution
```bash
lvextend -r -L 320M /dev/vg_s5/lv_ext4
lvextend -r -L 320M /dev/vg_s5/lv_xfs
```

### Verify
```bash
lvs --noheadings -o lv_size --units m /dev/vg_s5/lv_ext4  # expect 320.00m
lvs --noheadings -o lv_size --units m /dev/vg_s5/lv_xfs   # expect 320.00m
cat /mnt/s6_ext4/test.txt /mnt/s6_xfs/test.txt            # expect ext4 ok / xfs ok
```

**Explanation:** Passing `-r` (`--resizefs`) to `lvextend` automatically grows both the Logical Volume and its mounted `ext4` or `xfs` filesystem online without data loss.

---

## Lab 6.5 — Create and configure set-GID directories for collaboration

### Solution
```bash
groupadd -f s6_collab
id s6_alice &>/dev/null || useradd -G s6_collab s6_alice
id s6_bob   &>/dev/null || useradd -G s6_collab s6_bob

mkdir -p /srv/s6_team
chown :s6_collab /srv/s6_team
chmod 2770 /srv/s6_team

su - s6_alice -c "touch /srv/s6_team/alice_file.txt"
setfacl -m u:labuser1:r-x /srv/s6_team
```

### Verify
```bash
stat -c "%G %a" /srv/s6_team                 # expect s6_collab 2770
stat -c "%G" /srv/s6_team/alice_file.txt     # expect s6_collab (inherited via SGID!)
getfacl -p /srv/s6_team | grep -c 'user:labuser1:r-x'  # expect 1
```

**Explanation:** `chmod 2770` sets the Set-GID bit (`2000`), ensuring all files created inside `/srv/s6_team` inherit group `s6_collab`, while `setfacl -m` grants fine-grained ACL access.
