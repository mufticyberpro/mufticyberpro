# Category 11: Manage Containers (Rootless Podman & Quadlets) — Solutions & Explanations

---

## Solution 11.1: Searching, Inspecting (`skopeo` & `podman`), Pulling, and Saving/Loading Images

### Commands (Run as `aloha` via `ssh aloha@localhost`):
```bash
# 1. Search registries for httpd
podman search httpd

# 2. Inspect remote image without pulling (using skopeo) or after pulling (using podman)
skopeo inspect docker://docker.io/library/httpd:latest | head -n 25
podman pull docker.io/library/httpd:latest
podman image inspect docker.io/library/httpd:latest

# 3. Save image to a tar archive and load it back
podman save -o ~/httpd_image.tar docker.io/library/httpd:latest
podman load -i ~/httpd_image.tar
```

### Why It Works (Explanation):
- **Note on Registries in the Exam:** On the real RHCSA exam, you will be given the URL of an internal classroom container registry (e.g., `registry.lab.example.com`). If it requires credentials, run **`podman login registry.lab.example.com`** first!
- `skopeo inspect docker://<registry>/<image>:<tag>` is explicitly mentioned in the RHCSA objectives—it lets you inspect environment variables, labels, and tags of a remote image before downloading it.

---

## Solution 11.2: Building a Custom Container Image from a `Containerfile` (`podman build`)

### Commands (As `aloha`):
```bash
mkdir -p ~/custom_build
cat << 'EOF' > ~/custom_build/Containerfile
FROM docker.io/library/httpd:latest
ENV APP_ENV=production
RUN echo "Built via RHEL 10 Containerfile" > /usr/local/apache2/htdocs/info.html
EXPOSE 80
EOF

# Build and tag (-t) the image from the current directory (.)
cd ~/custom_build
podman build -t localhost/webapp:v1.0 .

# Verify:
podman images
```

### Why It Works (Explanation):
- `podman build -t <name>:<tag> <directory>` automatically looks for a file named **`Containerfile`** (or `Dockerfile`) inside the specified directory.
- Don't forget the trailing dot **`.`** (the build context directory) at the end of `podman build -t localhost/webapp:v1.0 .`!

---

## Solution 11.3: Running Rootless Containers with Port Mapping (`-p`) and Environment Variables (`-e`)

### Commands (As `aloha`):
```bash
# 1. Run detached container with -p and -e flags
podman run -d --name test_env_web \
  -p 8081:80 \
  -e DB_HOST=node2.lab.example.com \
  -e LOG_LEVEL=debug \
  localhost/webapp:v1.0

# 2. Verify container is running, check env vars, and test web page
podman ps
podman exec test_env_web env | grep -E 'APP_ENV|DB_HOST|LOG_LEVEL'
curl http://localhost:8081/info.html

# 3. Stop and remove the test container
podman stop test_env_web
podman rm test_env_web
```

### Why It Works (Explanation):
- `-d`: Detached mode (runs in the background).
- `--name <name>`: Assigns the exact container name requested by the exam.
- `-p <HOST_PORT>:<CONTAINER_PORT>`: For rootless containers, `<HOST_PORT>` must be `>= 1024` (e.g., `8080`, `8081`).
- `-e KEY=VALUE`: Injects environment variables into the container runtime.

---

## Solution 11.4: Attaching Persistent Host Storage (`-v ...:Z`) and `podman unshare`

### Commands (As `aloha`):
```bash
# 1. Create the host directory and index.html
mkdir -p /home/aloha/persistent_html
echo "Persistent Storage Verified" > /home/aloha/persistent_html/index.html

# 2. (If the container runs as a non-root UID internally, e.g. UID 1001 in ubi9/httpd-24,
#     grant that container UID ownership of the host directory using podman unshare):
# podman unshare chown -R 1001:1001 /home/aloha/persistent_html

# 3. Run the container with -v /host/path:/container/path:Z
podman run -d --name logserver \
  -p 8080:80 \
  -v /home/aloha/persistent_html:/usr/local/apache2/htdocs:Z \
  localhost/webapp:v1.0

# Verify:
curl http://localhost:8080
```

### Why It Works (Explanation):
- **Why `:Z` on `-v` is Mandatory on RHEL 10:**
  - Without `:Z`, SELinux leaves `/home/aloha/persistent_html` labeled `user_home_t`, and SELinux blocks the confined container (`container_t`) from reading or writing to the directory (`Permission denied`)!
  - Appending **`:Z`** (`-v /host/dir:/container/dir:Z`) tells Podman to automatically relabel `/home/aloha/persistent_html` to `container_file_t` with the container's private MCS category.
- **When do you need `podman unshare chown`?**
  - Inside a rootless container, container `root` (UID `0`) maps directly to your host user `aloha` (UID `1001`).
  - However, if an image (like `mariadb`, `rsyslog`, or `ubi9/httpd-24`) runs its internal process as a non-root UID (like UID `27` or `1001` inside the container) and needs to **write** files into the mounted host directory, run:
    `podman unshare chown -R <CONTAINER_UID>:<CONTAINER_GID> /host/dir`
    so that the mapped sub-UID owns the directory!

---

## Solution 11.5: Configuring a Rootless Container as a Persistent Systemd Service on RHEL 10

### Step 1: Enable Lingering for `aloha`
```bash
# Can be run by aloha (for themselves) or by root:
loginctl enable-linger aloha

# Verify Linger=yes:
loginctl show-user aloha | grep Linger
```

### Step 2 (Method A — RHEL 10 Primary Method: Podman Quadlet `.container`)
*(Exam Pro-Tip: Forget the exact keys for a Quadlet file? Run **`man podman-systemd.unit`** and search for `[Container]`!)*
```bash
# Stop and remove any manually started 'logserver' container first so Quadlet manages it cleanly:
podman stop logserver 2>/dev/null || true
podman rm logserver 2>/dev/null || true

# Create the Quadlet directory for rootless user services:
mkdir -p ~/.config/containers/systemd

# Create ~/.config/containers/systemd/logserver.container
cat << 'EOF' > ~/.config/containers/systemd/logserver.container
[Unit]
Description=Rootless Logserver Container Service
After=network-online.target

[Container]
ContainerName=logserver
Image=localhost/webapp:v1.0
PublishPort=8080:80
Volume=/home/aloha/persistent_html:/usr/local/apache2/htdocs:Z

[Install]
WantedBy=default.target
EOF

# Tell systemd to run the Quadlet generator and start the service!
systemctl --user daemon-reload
systemctl --user start logserver.service
```

### Step 2 (Method B — Classic Fallback Method: `podman generate systemd`)
*(If you prefer generating a standard `.service` file from a running container)*
```bash
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd --name logserver --files --new

systemctl --user daemon-reload
systemctl --user enable --now container-logserver.service
```

### Why It Works (Explanation):
- **Important Difference Between Quadlets (Method A) and Classic Units (Method B):**
  - With **Quadlets** (`~/.config/containers/systemd/logserver.container`), the `[Install] WantedBy=default.target` section inside `.container` is automatically wired up by the Quadlet generator during `systemctl --user daemon-reload`! You only run **`systemctl --user daemon-reload`** and **`systemctl --user start logserver.service`** (note that `systemctl --user enable` is not needed/used on generated Quadlet units because the generator enables them automatically via `[Install]`).
  - With **`podman generate systemd`** (`~/.config/systemd/user/container-logserver.service`), you run **`systemctl --user enable --now container-logserver.service`**.

### Verification:
```bash
systemctl --user status logserver.service
podman ps
curl http://localhost:8080
```

