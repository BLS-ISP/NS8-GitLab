# ns8-gitlab

[GitLab Community Edition](https://about.gitlab.com/) module for **NethServer 8 (NS8)**.

- **GitHub Repository:** [`https://github.com/BLS-ISP/NS8-GitLab`](https://github.com/BLS-ISP/NS8-GitLab)
- **Container Image:** `ghcr.io/bls-isp/gitlab`
- **NS8 Software Center Repository URL:** `https://raw.githubusercontent.com/BLS-ISP/ns8-nethforge/repomd/ns8/updates/`
- **License:** [GPL-3.0-or-later](LICENSE)

---

## Features

- **GitLab CE (`19.5.1-ce.0`)** running in a rootless Podman pod behind the NS8 Traefik reverse proxy
- **Let's Encrypt & HTTP-to-HTTPS redirect** configurable via the NS8 Web UI
- **NS8 LDAP / Active Directory integration** (automatic user authentication via NS8 user domains and `Ldapproxy`, including `user-domain-changed` event handler)
- **NS8 Smarthost / SMTP integration** (automatic discovery and reload on `smarthost-changed` events)
- **Git over SSH** (automatically allocates a dedicated TCP port, opens it in the NS8 node firewall via `node:fwadm`, and configures `gitlab_shell_ssh_port`)
- **Integrated GitLab Container Registry** (optional, exposed on a separate FQDN via Traefik)
- **Integrated GitLab Runner (`v19.5.1`)** (optional toggle in UI; enables `podman.socket` and automatically registers the instance runner in the background using the `glrt-` runner authentication token workflow once GitLab is ready)
- **Custom Disk / Volume Selection** (`org.nethserver.volumes` label unlocks NS8 disk selection for `gitlab-data`, `gitlab-config`, `gitlab-logs`, and `gitlab-runner-config`)
- **Backup, Restore & Clone/Move** (`module-dump-state`, `module-cleanup-state`, `restore-module`, `clone-module`, and `update-module` support)

---

## Install via NethServer 8 Software Center UI (Recommended)

1. Open the **NethServer 8 Cluster Admin UI**.
2. Go to **Software center → Settings → Software repositories → Add repository**.
3. Enter the following details:
   - **Name:** `bls-isp`
   - **URL:** `https://raw.githubusercontent.com/BLS-ISP/ns8-nethforge/repomd/ns8/updates/`
   - **Status:** Enabled
4. Open **Software center**, find **GitLab**, and click **Install** (you can optionally expand **Configure additional volumes** during installation to place `gitlab-data` on a dedicated disk).
5. Future module updates published with a newer Semantic Version tag (e.g. `1.0.4`, `1.1.0`) will automatically appear in the **Software center → Updates** view.

> **Tip:** To clear the 1-hour repository metadata cache on NS8 and immediately see a newly published release:
> ```bash
> redis-cli del cluster/repository_cache/bls-isp
> ```

---

## Install via CLI

Instantiate the module using a **Semantic Version tag** (do not use `:latest` in production, as NS8 skips UI updates for `:latest` development instances):

```bash
add-module ghcr.io/bls-isp/gitlab:1.0.4 1
```

The output of the command will return the instance name:

```json
{"module_id": "gitlab1", "image_name": "gitlab", "image_url": "ghcr.io/bls-isp/gitlab:1.0.4"}
```

---

## Configure

Assuming the instance is named `gitlab1`, you can configure it directly in the **NethServer 8 Web UI** (**Settings → gitlab1**) or via CLI using `configure-module`:

- `host`: Fully qualified domain name for the GitLab web interface (e.g. `git.example.org`)
- `http2https`: Redirect HTTP requests to HTTPS (`true` / `false`)
- `lets_encrypt`: Request a valid Let's Encrypt certificate (`true` / `false`)
- `password`: Initial password for the `root` user (optional, minimum 8 characters)
- `ldap_domain`: NS8 LDAP / Active Directory domain for user authentication (optional)
- `registry_host`: Fully qualified domain name for the GitLab Container Registry (optional, e.g. `registry.example.org`)
- `runner_enabled`: Enable and auto-register the integrated GitLab Runner container (`true` / `false`)

Example CLI invocation:

```bash
api-cli run module/gitlab1/configure-module --data '{
  "host": "git.example.org",
  "http2https": true,
  "lets_encrypt": true,
  "password": "MyStrongRootPassword123!",
  "ldap_domain": "",
  "registry_host": "registry.example.org",
  "runner_enabled": true
}'
```

> **Note on first startup:** On initial boot, GitLab Omnibus initializes PostgreSQL, Gitaly, Redis, and runs all database migrations. This takes approximately **3 to 5 minutes** depending on hardware. The assigned **Git SSH port** is opened automatically in the node firewall and displayed at the top of the module settings page.

---

## Architecture, Volumes & Environment Variables (Developer / Support Reference)

### Systemd User Units (`imageroot/systemd/user/`)

- `gitlab.service`: Manages the rootless Podman pod (`gitlab`) with 512 MB `/dev/shm` and port mappings (`GITLAB_NGINX_PORT:80`, `GITLAB_REGISTRY_PORT:5050`, `GITLAB_SSH_PORT:22`).
- `gitlab-app.service`: Runs the `docker.io/gitlab/gitlab-ce:19.5.1-ce.0` container inside the pod. Executes `../bin/write-config` prior to startup to render `state/gitlab.rb` from the current module environment, NethServer 8 `Ldapproxy`, and Redis smarthost settings.
- `gitlab-runner.service`: Optional container (`docker.io/gitlab/gitlab-runner:v19.5.1`) attached to the rootless `podman.socket` (`%t/podman/podman.sock`).
- `gitlab-runner-register.service`: Oneshot background service (`RemainAfterExit=yes`) that waits for `http://127.0.0.1:80/-/readiness` inside `gitlab-app`, generates a `glrt-` runner authentication token via `Ci::Runners::CreateRunnerService`, and registers the runner automatically.

### Persistent Volumes (`imageroot/etc/state-include.conf` & `org.nethserver.volumes`)

| Volume / Path | Container Mountpoint | Description | Included in Backup |
|---|---|---|---|
| `volumes/gitlab-data` | `/var/opt/gitlab` | Git repositories (Gitaly), PostgreSQL database, Redis state, registry storage | Yes |
| `volumes/gitlab-config` | `/etc/gitlab` | Omnibus configuration (`gitlab.rb`), `gitlab-secrets.json`, SSH host keys | Yes |
| `volumes/gitlab-runner-config` | `/etc/gitlab-runner` | Registered runner configuration (`config.toml`) | Yes |
| `volumes/gitlab-logs` | `/var/log/gitlab` | Service and application logs | No |
| `state/gitlab.rb` | `/assets/ns8-gitlab.rb` | Generated Omnibus configuration template | Yes (implicit `state/`) |
| `state/environment` | — | Module instance environment variables | Yes (implicit `state/`) |

### Environment Variables (`state/environment`)

| Variable | Description |
|---|---|
| `HOST` | Configured FQDN for the GitLab web interface |
| `HTTP2HTTPS` | Whether Traefik redirects HTTP to HTTPS (`True` / `False`) |
| `LETS_ENCRYPT` | Whether Traefik requests a Let's Encrypt certificate (`True` / `False`) |
| `GITLAB_NGINX_PORT` | Allocated local TCP port for GitLab HTTP behind Traefik |
| `GITLAB_REGISTRY_PORT` | Allocated local TCP port for GitLab Container Registry behind Traefik |
| `GITLAB_SSH_PORT` | Allocated public TCP port for Git over SSH (opened in node firewall) |
| `GITLAB_REGISTRY_HOST` | Optional FQDN for the integrated Container Registry |
| `LDAP_DOMAIN` | Optional NethServer 8 user domain name bound via `Ldapproxy` |
| `RUNNER_ENABLED` | Enables or disables the integrated GitLab Runner (`True` / `False`) |
| `GITLAB_INITIAL_PASSWORD` | Initial password for the `root` administrator account |

### Maintenance, Backup & Restore

- **Pre-Backup Hook (`imageroot/bin/module-dump-state`):** Automatically invoked by NS8 `run-backup` before Restic snapshots the module volumes. When `gitlab-app` is active, it runs `gitlab-backup create SKIP=repositories,uploads,builds,artifacts,lfs,terraform_state,ci_secure_files,pages,registry,packages CRON=1` to write a consistent hot PostgreSQL database dump into `/var/opt/gitlab/backups/` without duplicating large repository or registry blobs already covered by `volumes/gitlab-data`.
- **Post-Backup Hook (`imageroot/bin/module-cleanup-state`):** Removes temporary `/var/opt/gitlab/backups/*_gitlab_backup.tar` archives after the Restic snapshot finishes.
- **Restore & Clone (`restore-module` / `clone-module`):** Re-applies the Traefik HTTP routes, firewall rules for the allocated `GITLAB_SSH_PORT`, LDAP/Smarthost bindings, and systemd unit states on the target node.

---

## Update Module via CLI

Updates are normally applied through the **NethServer 8 Software Center UI**. To manually update via CLI:

```bash
api-cli run update-module --data '{"module_url":"ghcr.io/bls-isp/gitlab:1.0.4","instances":["gitlab1"]}'
```

---

## Publishing a New Release (Semantic Versioning)

In accordance with NethServer 8 standards, releases must use pure **Semantic Versioning (`X.Y.Z`) without a `v` prefix** (e.g. `1.0.4`, `1.1.0`, or `1.1.0-testing.1` for pre-releases):

```bash
git tag -a 1.0.4 -m "Release 1.0.4"
git push origin main --tags
```

The GitHub Actions workflow (`.github/workflows/publish-images.yml`) automatically builds and publishes `ghcr.io/bls-isp/gitlab:1.0.4` and updates `repodata.json` on the `repomd` branch.

---

## Uninstall

To uninstall the instance and remove its data:

```bash
remove-module --no-preserve gitlab1
```

---

## Testing

Test the module using the `test-module.sh` script:

```bash
./test-module.sh <NODE_ADDR> ghcr.io/bls-isp/gitlab:1.0.4
```

---

## Data Privacy & Terms

This module runs **100% self-hosted** on your NethServer 8 cluster:

- **No External Telemetry:** All Git repositories, CI/CD artifacts, container images, issues, and user credentials remain exclusively on your NethServer 8 node inside the rootless module volumes (`gitlab-data`, `gitlab-config`, `gitlab-runner-config`). Usage ping and Puma/Sidekiq Prometheus exporters are disabled by default to minimize footprint and prevent unwanted telemetry.
- **Terms & License:** Distributed under the **GNU General Public License v3.0 or later (`GPL-3.0-or-later`)** without warranty of any kind. See [`LICENSE`](LICENSE) for full details.

---

## Limitations, Roadmap & Contact

- **Hardware Requirements:** GitLab CE Omnibus bundles PostgreSQL, Gitaly, Redis, Puma, Sidekiq, and Workhorse. While tuned for lower memory consumption (~2.5–3 GB RAM idle), at least **4 GB of free RAM** and **2–4 CPU cores** are recommended on the target NS8 node.
- **Bug Reports & Feature Requests:** Please open an issue on [GitHub Issues](https://github.com/BLS-ISP/NS8-GitLab/issues).
- **Maintainer Contact:** BLS-ISP (`info@bls-isp.de`) or via the [NethServer Community Forum](https://community.nethserver.org/).
