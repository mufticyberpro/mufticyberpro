# Section 3: Create Simple Shell Scripts — Solutions & Verification (4 Labs)

---

## Lab 3.1 — Conditionally execute code (use of: `if`, `test`, `[]`, etc.)

### Solution
```bash
mkdir -p ~/labs/s3

cat << 'EOF' > ~/labs/s3/check_path.sh
#!/usr/bin/env bash

if [[ -f /var/tmp/maintenance.flag ]]; then
    echo "MAINTENANCE_MODE" > ~/labs/s3/mode.txt
else
    echo "NORMAL_MODE" > ~/labs/s3/mode.txt
fi
EOF

chmod 755 ~/labs/s3/check_path.sh
touch /var/tmp/maintenance.flag
~/labs/s3/check_path.sh
```

### Verify
```bash
cat ~/labs/s3/mode.txt                       # expect MAINTENANCE_MODE
rm -f /var/tmp/maintenance.flag
~/labs/s3/check_path.sh
cat ~/labs/s3/mode.txt                       # expect NORMAL_MODE
```

**Explanation:** `[[ -f FILE ]]` (or `[ -f FILE ]`) tests whether `FILE` exists and is a regular file, branching between `then` and `else`.

---

## Lab 3.2 — Use Looping constructs (`for`, etc.) to process file, command line input

### Solution
```bash
mkdir -p ~/labs/s3

cat << 'EOF' > ~/labs/s3/folders.txt
alpha
bravo
charlie
delta
EOF

cat << 'EOF' > ~/labs/s3/make_dirs.sh
#!/usr/bin/env bash

for dir in $(cat ~/labs/s3/folders.txt); do
    mkdir -p ~/labs/s3/output_dirs/"$dir"
    echo "Directory: $dir" > ~/labs/s3/output_dirs/"$dir"/README.txt
done
EOF

chmod 755 ~/labs/s3/make_dirs.sh
~/labs/s3/make_dirs.sh
```

### Verify
```bash
find ~/labs/s3/output_dirs -name "README.txt" | wc -l    # expect 4
cat ~/labs/s3/output_dirs/bravo/README.txt               # expect Directory: bravo
```

**Explanation:** The `for dir in $(cat ...); do ... done` loop iterates through each word/line in the input file and executes the body once per item.

---

## Lab 3.3 — Process script inputs (`$1`, `$2`, etc.)

### Solution
```bash
cat << 'EOF' > /usr/local/bin/ex200_arg.sh
#!/usr/bin/env bash

if [[ "${1:-}" == "redhat" ]]; then
    echo "fedora"
elif [[ "${1:-}" == "fedora" ]]; then
    echo "redhat"
else
    echo "Usage: /usr/local/bin/ex200_arg.sh redhat|fedora" >&2
    exit 1
fi
EOF

chmod 755 /usr/local/bin/ex200_arg.sh
```

### Verify
```bash
/usr/local/bin/ex200_arg.sh redhat           # expect fedora
/usr/local/bin/ex200_arg.sh fedora           # expect redhat
/usr/local/bin/ex200_arg.sh invalid 2>&1     # expect Usage: /usr/local/bin/ex200_arg.sh redhat|fedora
```

**Explanation:** `$1` captures the first command-line argument passed to the script, `>&2` writes the error message to `stderr`, and `exit 1` sets a non-zero exit code.

---

## Lab 3.4 — Processing output of shell commands within a script

### Solution
```bash
mkdir -p ~/labs/s3

cat << 'EOF' > ~/labs/s3/suid_audit.sh
#!/usr/bin/env bash

find /usr/bin -type f -perm -4000 2>/dev/null > ~/labs/s3/suid_list.txt
COUNT=$(wc -l < ~/labs/s3/suid_list.txt)
HOST=$(hostname)

echo "Found ${COUNT} SUID files on ${HOST}" > ~/labs/s3/suid_summary.txt
EOF

chmod 755 ~/labs/s3/suid_audit.sh
~/labs/s3/suid_audit.sh
```

### Verify
```bash
cat ~/labs/s3/suid_summary.txt               # expect Found <N> SUID files on <hostname>
wc -l < ~/labs/s3/suid_list.txt              # expect >= 5
```

**Explanation:** `$(...)` executes a command inside a subshell and stores its standard output into a variable (`COUNT` and `HOST`).
