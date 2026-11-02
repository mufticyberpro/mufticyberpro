# Section 1: Understand and Use Essential Tools — Solutions & Verification (11 Labs)

---

## Lab 1.1 — Access a shell prompt and issue commands with correct syntax

### Solution
```bash
mkdir -p ~/labs/s1/projects/{app1,app2}/{src,bin}

cat << EOF > ~/labs/s1/sysinfo.txt
$(hostname)
$(uname -r)
$(date +%F)
EOF
```

### Verify
```bash
find ~/labs/s1/projects -type d | wc -l      # expect 7
wc -l < ~/labs/s1/sysinfo.txt                # expect 3
cat ~/labs/s1/sysinfo.txt
```

**Explanation:** Brace expansion `{app1,app2}/{src,bin}` expands into all 4 combinations before `mkdir -p` runs, creating parent and child directories in one command.

---

## Lab 1.2 — Use input-output redirection (`>`, `>>`, `|`, `2>`, etc.)

### Solution
```bash
ls -l /etc/passwd /etc/shadow /no_such_file > ~/labs/s1/stdout.txt 2> ~/labs/s1/stderr.txt

find /etc -name "*.conf" &> ~/labs/s1/all_output.txt
wc -l < ~/labs/s1/all_output.txt > ~/labs/s1/count.txt
```

### Verify
```bash
wc -l < ~/labs/s1/stdout.txt                 # expect 2
wc -l < ~/labs/s1/stderr.txt                 # expect 1
cat ~/labs/s1/count.txt                      # expect > 10
```

**Explanation:** `>` redirects file descriptor `1` (`stdout`), `2>` redirects file descriptor `2` (`stderr`), and `&>` (or `> file 2>&1`) redirects both `stdout` and `stderr` into the same file.

---

## Lab 1.3 — Use `grep` and regular expressions to analyze text

### Solution
```bash
grep '/bin/bash$' /etc/passwd > ~/labs/s1/bash_users.txt
grep -vE '^(#|[[:space:]]*$)' /etc/login.defs > ~/labs/s1/active_login_defs.txt
```

### Verify
```bash
grep -c '/bin/bash$' ~/labs/s1/bash_users.txt          # expect >= 1
grep -c '^#' ~/labs/s1/active_login_defs.txt           # expect 0
head -n 5 ~/labs/s1/active_login_defs.txt
```

**Explanation:** `$` anchors `/bin/bash` to the end of the line. In `grep -vE '^(#|[[:space:]]*$)'`, `-v` inverts the match to strip out lines starting with `#` and empty/whitespace lines.

---

## Lab 1.4 — Access remote systems using SSH

### Solution
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
[[ -f ~/.ssh/id_ed25519 ]] || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@localhost "hostname && touch ~/labs/s1/ssh-ok"
```


### Verify
```bash
ls ~/labs/s1/ssh-ok                          # expect /root/labs/s1/ssh-ok
```

**Explanation:** `ssh-keygen -N ""` generates a passwordless key pair non-interactively, and `BatchMode=yes` proves SSH key authentication succeeded without prompting for a password.

---

## Lab 1.5 — Log in and switch users in multiuser targets

### Solution
```bash
systemctl get-default > ~/labs/s1/current_target.txt
su - labuser1 -c 'echo -e "USER=$USER\nUID=$UID\nHOME=$HOME" > /tmp/labuser1_env.txt'
```

### Verify
```bash
grep '^USER=labuser1' /tmp/labuser1_env.txt  # expect USER=labuser1
grep '^HOME=/home/labuser1' /tmp/labuser1_env.txt
```

**Explanation:** `su - labuser1` (with the hyphen `-`) starts a full login shell as `labuser1`, initializing `$USER`, `$UID`, `$HOME`, and `$PATH` for that user instead of keeping `root`'s environment.

---

## Lab 1.6 — Archive, compress, unpack, and uncompress files using `tar`, `gzip`, and `bzip2`

### Solution
```bash
tar -czf ~/labs/s1/ssh_backup.tar.gz /etc/ssh
tar -cjf ~/labs/s1/ssh_backup.tar.bz2 /etc/ssh

mkdir -p ~/labs/s1/unpacked_ssh
tar -xjf ~/labs/s1/ssh_backup.tar.bz2 -C ~/labs/s1/unpacked_ssh
```

### Verify
```bash
file ~/labs/s1/ssh_backup.tar.gz             # expect gzip compressed data
file ~/labs/s1/ssh_backup.tar.bz2            # expect bzip2 compressed data
ls ~/labs/s1/unpacked_ssh/etc/ssh/sshd_config
```

**Explanation:** `-z` uses `gzip`, `-j` uses `bzip2`, `-c` creates, `-x` extracts, `-f` specifies the archive filename, and `-C` extracts into a specific target directory.

---

## Lab 1.7 — Create and edit text files

### Solution
```bash
cat << 'EOF' > ~/labs/s1/servers.conf
web01.lab.example.com
db01.lab.example.com
cache01.lab.example.com
EOF

sed -i 's/lab\.example\.com/prod.example.com/g' ~/labs/s1/servers.conf
echo "backup01.prod.example.com" >> ~/labs/s1/servers.conf
```

### Verify
```bash
grep -c 'prod.example.com' ~/labs/s1/servers.conf   # expect 4
cat ~/labs/s1/servers.conf
```

**Explanation:** `sed -i 's/OLD/NEW/g'` edits the file in-place (`-i`), replacing every match globally (`g`), and `>>` appends a new line without overwriting the file.

---

## Lab 1.8 — Create, delete, copy, and move files and directories

### Solution
```bash
mkdir -p ~/labs/s1/source_files ~/labs/s1/backup_files
touch ~/labs/s1/source_files/file{1..5}.txt ~/labs/s1/source_files/temp.tmp
chown -R labuser1:labteam ~/labs/s1/source_files

cp -a ~/labs/s1/source_files/*.txt ~/labs/s1/backup_files/
mv ~/labs/s1/backup_files/file5.txt ~/labs/s1/archived_file5.txt
rm -f ~/labs/s1/source_files/temp.tmp
```

### Verify
```bash
find ~/labs/s1/backup_files -type f -user labuser1 | wc -l   # expect 4
ls ~/labs/s1/archived_file5.txt                              # expect archived_file5.txt
ls ~/labs/s1/source_files/temp.tmp 2>/dev/null               # expect nothing (deleted)
```

**Explanation:** `cp -a` (archive mode) preserves ownership (`labuser1:labteam`), permissions, SELinux labels, and timestamps during copy.

---

## Lab 1.9 — Create hard and soft links

### Solution
```bash
echo "Important Record" > ~/labs/s1/master_data.txt
ln ~/labs/s1/master_data.txt ~/labs/s1/hard_data.txt
ln -s /root/labs/s1/master_data.txt ~/labs/s1/soft_data.txt
```

### Verify
```bash
stat -c %i ~/labs/s1/master_data.txt ~/labs/s1/hard_data.txt | uniq | wc -l  # expect 1 (same inode)
readlink -f ~/labs/s1/soft_data.txt                                          # expect /root/labs/s1/master_data.txt
```

**Explanation:** `ln` without flags creates a hard link sharing the exact same inode number. `ln -s` creates a symbolic link pointing to the target path.

---

## Lab 1.10 — List, set, and change standard `ugo/rwx` permissions

### Solution
```bash
touch ~/labs/s1/deploy.sh
mkdir -p ~/labs/s1/shared_dir

chown labuser1:labteam ~/labs/s1/deploy.sh ~/labs/s1/shared_dir
chmod 0750 ~/labs/s1/deploy.sh
chmod u=rwx,g=rwx,o=rx ~/labs/s1/shared_dir
```

### Verify
```bash
stat -c "%U:%G %a" ~/labs/s1/deploy.sh       # expect labuser1:labteam 750
stat -c "%U:%G %a" ~/labs/s1/shared_dir      # expect labuser1:labteam 775
```

**Explanation:** Permissions can be set using octal (`0750`, `0775`) or symbolic syntax (`u=rwx,g=rx,o=`).

---

## Lab 1.11 — Locate, read, and use system documentation including `man`, `info`, and files in `/usr/share/doc`

### Solution
```bash
mandb -q
man -k crontab > ~/labs/s1/man_crontab.txt
find /usr/share/doc -name "README*" > ~/labs/s1/doc_readmes.txt
```

### Verify
```bash
grep -c 'crontab' ~/labs/s1/man_crontab.txt  # expect >= 1
wc -l < ~/labs/s1/doc_readmes.txt            # expect >= 5
```

**Explanation:** `mandb -q` builds the `man -k` (`apropos`) search index so you can search man pages by keyword during the offline exam.
