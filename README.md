# ns8-gitlab

[GitLab Community Edition](https://about.gitlab.com/) module for **NethServer 8 (NS8)**.

- **GitHub Repository:** [`https://github.com/BLS-ISP/NS8-GitLab`](https://github.com/BLS-ISP/NS8-GitLab)
- **Container Image:** `ghcr.io/bls-isp/gitlab`
- **NS8 Software Center Repository URL:** `https://raw.githubusercontent.com/BLS-ISP/ns8-nethforge/repomd/ns8/updates/`
- **License:** [GPL-3.0-or-later](LICENSE)

---

## Features

- **GitLab CE (`19.6.0-ce.0`)** running in a rootless Podman pod behind the NS8 Traefik reverse proxy
- **Let's Encrypt & HTTP-to-HTTPS redirect** configurable via the NS8 Web UI
- **NS8 LDAP / Active Directory integration** (automatic user authentication via NS8 user domains and `Ldapproxy`, including `user-domain-changed` event handler)
- **NS8 Cluster Single Sign-On (`ns8-idp`, `ns8-lemonldapng`, etc.)** (zero-touch OIDC client registration via `register-client` and automatic reload on `service-oidc-changed` events)
- **External Single Sign-On (OmniAuth)** (OpenID Connect, SAML 2.0, Microsoft Entra ID / Azure AD v2, GitHub / GitHub Enterprise, GitLab.com / External GitLab, Google Workspace, and Generic OAuth2, plus Custom Trusted CA Certificate support)
- **Persistent Custom Omnibus Configuration (`gitlab-custom.rb`)** (editable directly in the NS8 Web UI or at `state/gitlab-custom.rb`, preserved across restarts, updates, and Restic cluster backups)
- **NS8 Smarthost / SMTP integration** (automatic discovery and reload on `smarthost-changed` events)
- **Git over SSH** (automatically allocates a dedicated TCP port, opens it in the NS8 node firewall via `node:fwadm`, and configures `gitlab_shell_ssh_port`)
- **Integrated GitLab Container Registry** (optional, exposed on a separate FQDN via Traefik)
- **Integrated GitLab Runner (`v19.6.0`)** (optional toggle in UI; enables `podman.socket` and automatically registers the instance runner in the background using the `glrt-` runner authentication token workflow once GitLab is ready)
- **Custom Disk / Volume Selection** (`org.nethserver.volumes` label unlocks NS8 disk selection for `gitlab-data`, `gitlab-config`, `gitlab-logs`, and `gitlab-runner-config`)
- **Backup, Restore & Clone/Move** (`module-dump-state`, `module-cleanup-state`, `restore-module` with `40restoreDB`, `clone-module`, and `update-module` support)

---

## Install via NethServer 8 Software Center UI (Recommended)

1. Open the **NethServer 8 Cluster Admin UI**.
2. Go to **Software center → Settings → Software repositories → Add repository**.
3. Enter the following details:
   - **Name:** `bls-isp`
   - **URL:** `https://raw.githubusercontent.com/BLS-ISP/ns8-nethforge/repomd/ns8/updates/`
   - **Status:** Enabled
4. Open **Software center**, find **GitLab**, and click **Install** (you can optionally expand **Configure additional volumes** during installation to place `gitlab-data` on a dedicated disk).
5. Future module updates published with a newer Semantic Version tag (e.g. `1.1.0`, `1.2.0`) will automatically appear in the **Software center → Updates** view.

> **Tip:** To clear the 1-hour repository metadata cache on NS8 and immediately see a newly published release:
> ```bash
> redis-cli del cluster/repository_cache/bls-isp
> ```

---

## Install via CLI

Instantiate the module using a **Semantic Version tag** (do not use `:latest` in production, as NS8 skips UI updates for `:latest` development instances):

```bash
add-module ghcr.io/bls-isp/gitlab:1.1.0 1
```

The output of the command will return the instance name:

```json
{"module_id": "gitlab1", "image_name": "gitlab", "image_url": "ghcr.io/bls-isp/gitlab:1.1.0"}
```

---

## Configure

Assuming the instance is named `gitlab1`, you can configure it directly in the **NethServer 8 Web UI** (**Settings → gitlab1**) or via CLI using `configure-module`:

- `host`: Fully qualified domain name for the GitLab web interface (e.g. `git.example.org`)
- `http2https`: Redirect HTTP requests to HTTPS (`true` / `false`)
- `lets_encrypt`: Request a valid Let's Encrypt certificate (`true` / `false`)
- `password`: Root password for the `root` administrator account (optional, minimum 8 characters). If left empty during initial setup, the module generates a random password and stores it in `state/passwords.env` (mode `0600`). You can either set a new `root` password at any time in the module **Settings** page or retrieve the generated password on the NS8 node via:
  ```bash
  runagent -m gitlab1 grep '^GITLAB_INITIAL_PASSWORD=' passwords.env
  ```
- `ldap_domain`: NS8 LDAP / Active Directory domain for user authentication (optional; required when enabling NS8 Cluster SSO)
- `registry_host`: Fully qualified domain name for the GitLab Container Registry (optional, e.g. `registry.example.org`)
- `runner_enabled`: Enable and auto-register the integrated GitLab Runner container (`true` / `false`)
- `sso_enabled`: Enable Single Sign-On / OmniAuth authentication (`true` / `false`)
- `custom_gitlab_rb`: Optional persistent Ruby configuration appended via `/etc/gitlab/gitlab-custom.rb`

> [!WARNING]
> **Security Notice — Integrated GitLab Runner:**
> When `runner_enabled` is enabled, CI jobs run inside containers spawned through the module's rootless Podman socket (`%t/podman/podman.sock`). Because CI jobs have access to this Podman socket, a job can control `gitlab-app` and read its volumes or secrets. Only enable the integrated runner when all users with CI/CD pipeline permissions on the GitLab instance are trusted, or use an external runner on a dedicated host for untrusted projects.

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

## Single Sign-On (SSO / OmniAuth)

Expand **Single Sign-On (SSO / OmniAuth)** in **Settings → gitlab1** (or set `"sso_enabled": true` via `configure-module`) to enable NS8 Cluster Single Sign-On and/or external GitLab CE OmniAuth identity providers. Multiple providers can be active at the same time.

### NS8 Cluster Single Sign-On (`ns8-idp`, `ns8-lemonldapng`, etc.)

`ns8-gitlab` implements the official [NethServer 8 Single Sign-On consumer contract](https://nethserver.github.io/ns8-core/core/user_domains/#single-sign-on):

1. **Select an NS8 User Domain (`ldap_domain`):** Choose the NS8 LDAP or Active Directory user domain in **Settings → gitlab1**.
2. **Select an NS8 Cluster SSO Provider (`ns8_sso_provider`):** `get-configuration` automatically discovers all OIDC providers published in cluster Redis (`module/*/srv/http/oidc`, such as `ns8-idp`, `ns8-lemonldapng`, `ns8-authentik`, `ns8-keycloak`, or `ns8-zitadel`) and filters them to match the selected `ldap_domain`.
3. **Zero-Touch OIDC Registration (`32ns8_sso`):** During `configure-module`, step `32ns8_sso` automatically calls `register-client` on the selected provider module (authorized via `idp@any:clientadm lemonldapng@any:clientadm authentik@any:clientadm keycloak@any:clientadm zitadel@any:clientadm`) with:
   - **Redirect / Callback URI:** `https://<host>/users/auth/openid_connect_ns8/callback`
   - **Post-Logout Redirect URI:** `https://<host>/`
   - Stores `NS8_SSO_ISSUER` and `NS8_SSO_CLIENT_ID` in `state/environment` and `NS8_SSO_CLIENT_SECRET` in `state/passwords.env` (mode `0600`).
4. **Coexistence with External OIDC:** Because NS8 Cluster SSO registers under its own OmniAuth provider name (`openid_connect_ns8` using `strategy_class: "OmniAuth::Strategies::OpenIDConnect"`), both **NS8 Cluster SSO** and an **External OpenID Connect** provider (`openid_connect`) can be active simultaneously without colliding.
5. **Automatic `service-oidc-changed` Event Handling:** `imageroot/events/service-oidc-changed/10reload_services` listens for cluster OIDC changes on the selected provider. When the provider updates its hostname or issuer, GitLab automatically re-runs `register-client`, regenerates `gitlab.rb`, and restarts `gitlab-app.service`. If SSO is disabled on the provider (`host == ""`), runtime `NS8_SSO_*` credentials are cleanly cleared with a journal warning so GitLab continues running without errors. During disaster recovery (`restore-module`), if the IdP module has not yet been restored on the target cluster, `32ns8_sso` logs a warning and allows the restore to complete cleanly.

### External Single Sign-On Providers (OmniAuth)

All native GitLab CE (Free Tier) OmniAuth providers are supported in the NS8 Web UI and CLI:

| Provider | OmniAuth Key | Callback / Redirect URL | Additional Endpoints & Notes |
|---|---|---|---|
| **NS8 Cluster SSO** (`ns8-idp`, `ns8-lemonldapng`, etc.) | `openid_connect_ns8` | `https://<host>/users/auth/openid_connect_ns8/callback` | Auto-registered via NS8 `register-client` (requires `ldap_domain`) |
| **OpenID Connect** (Keycloak, Authentik, Authelia, Zitadel, Okta, etc.) | `openid_connect` | `https://<host>/users/auth/openid_connect/callback` | Supports OIDC discovery, PKCE (`oidc_pkce`), custom scopes, UID claim, and `basic` / `query` / `jwt_bearer` / `mtls` client auth |
| **SAML 2.0** | `saml` | `https://<host>/users/auth/saml/callback` | SP Metadata URL: `https://<host>/users/auth/saml/metadata`; supports IdP SHA-1/SHA-256 fingerprint or full X.509 PEM certificate |
| **Microsoft Entra ID (Azure AD v2)** | `azure_activedirectory_v2` | `https://<host>/users/auth/azure_activedirectory_v2/callback` | Requires Application (Client) ID, Client Secret, and Directory (Tenant) ID |
| **GitHub / GitHub Enterprise** | `github` | `https://<host>/users/auth/github/callback` | Supports GitHub.com or self-hosted GitHub Enterprise URL (`github_url`) |
| **GitLab.com / External GitLab** | `gitlab` | `https://<host>/users/auth/gitlab/callback` | Supports GitLab.com or another self-managed GitLab instance (`gitlab_oauth_url`) |
| **Google Workspace / Google OAuth2** | `google_oauth2` | `https://<host>/users/auth/google_oauth2/callback` | Requires Google Cloud OAuth 2.0 Client ID and Client Secret |
| **Generic OAuth2** | `oauth2_generic` | `https://<host>/users/auth/oauth2_generic/callback` | Configurable `site`, `authorize_url`, `token_url`, `user_info_url`, and `uid_field` |

#### Global OmniAuth Policy, Custom Trusted CA & Emergency Login Bypass

- **Global Account Linking & Provisioning Controls:** Configure automatic account creation (`sso_allow_single_sign_on`), blocking auto-created users pending administrator approval (`sso_block_auto_created_users`), 2FA bypass for SSO logins (`sso_allow_bypass_two_factor`), automatic email/LDAP/SAML user linking (`sso_auto_link_user`, `sso_auto_link_ldap_user`, `sso_auto_link_saml_user`), and profile synchronization (`sso_sync_profile`).
- **Custom Trusted CA Certificate (`custom_ca_cert`):** When an internal NS8 IdP (`ns8-lemonldapng`, `ns8-idp`) or enterprise IdP uses a private or self-signed CA certificate, paste the PEM bundle into **Custom Trusted CA Certificate**. It is stored Base64-encoded in `state/passwords.env` (`CUSTOM_CA_CERT_B64`), rendered to `state/ns8-custom-ca.crt`, and installed into `/etc/gitlab/trusted-certs/ns8-custom-ca.crt` before `gitlab-ctl reconfigure` so OIDC discovery and token requests trust the CA automatically.
- **Automatic Sign-In & Emergency Bypass URL:** If `sso_auto_sign_in_provider` is set to an active provider, GitLab automatically redirects unauthenticated users to that IdP. To sign in locally (e.g. as `root` or if the external IdP is temporarily unavailable), open the emergency bypass URL:
  ```text
  https://<host>/users/sign_in?auto_sign_in=false
  ```

---

## Persistent Custom Omnibus Configuration (`gitlab-custom.rb`)

Because `bin/write-config` regenerates `state/gitlab.rb` (and copies `/assets/ns8-gitlab.rb` to `/etc/gitlab/gitlab.rb`) whenever the module starts or is reconfigured, manual edits made directly to `/etc/gitlab/gitlab.rb` inside the container are overwritten.

To add persistent custom GitLab Omnibus settings (such as time zone, rack attack settings, object storage, OmniAuth customizations, or performance tuning):

1. **Via the NS8 Web UI:** Open **Settings → gitlab1**, expand **Advanced Configuration (`gitlab-custom.rb`)**, enter valid Ruby Omnibus directives, and click **Save**:
   ```ruby
   gitlab_rails['time_zone'] = 'Europe/Berlin'
   gitlab_rails['artifacts_max_size'] = 250
   ```
2. **Via CLI or Node State File:** Pass `"custom_gitlab_rb"` to `configure-module`, or edit `state/gitlab-custom.rb` (mode `0600`) inside the module's state directory (`/home/gitlab1/.config/state/gitlab-custom.rb`) and restart `gitlab-app.service`.

`state/gitlab-custom.rb` is bind-mounted read-only into `gitlab-app` at `/assets/ns8-gitlab-custom.rb`, copied to `/etc/gitlab/gitlab-custom.rb` (mode `0600`) before `gitlab-ctl reconfigure`, and evaluated at the very end of `/etc/gitlab/gitlab.rb` (`from_file "/etc/gitlab/gitlab-custom.rb" if File.exist?("/etc/gitlab/gitlab-custom.rb")`). Because `state/gitlab-custom.rb` is listed in `imageroot/etc/state-include.conf`, custom Omnibus rules persist across container restarts, `configure-module` runs, `update-module` upgrades, `clone-module` migrations, and Restic cluster backups/restores.

---

## Architecture, Volumes & Environment Variables (Developer / Support Reference)

### Systemd User Units (`imageroot/systemd/user/`)

- `gitlab.service`: Manages the rootless Podman pod (`gitlab`) with 512 MB `/dev/shm` and port mappings (`GITLAB_NGINX_PORT:80`, `GITLAB_REGISTRY_PORT:5050`, `GITLAB_SSH_PORT:22`).
- `gitlab-app.service`: Runs the `docker.io/gitlab/gitlab-ce:19.6.0-ce.0` container inside the pod. Executes `../bin/write-config` prior to startup to render `state/gitlab.rb` (mode `0600`), ensure `state/gitlab-custom.rb` (mode `0600`) exists, and render any optional `state/ns8-custom-ca.crt` from `state/environment`, `state/passwords.env`, NethServer 8 `Ldapproxy`, and Redis smarthost settings.
- `gitlab-runner.service`: Optional container (`docker.io/gitlab/gitlab-runner:v19.6.0`) attached to the rootless `podman.socket` (`%t/podman/podman.sock`).
- `gitlab-runner-register.service`: Oneshot background service (`RemainAfterExit=yes`) that waits for `http://127.0.0.1:80/-/readiness` inside `gitlab-app`, generates a `glrt-` runner authentication token via `Ci::Runners::CreateRunnerService`, and registers the runner automatically.

### Persistent Volumes & State Files (`imageroot/etc/state-include.conf` & `org.nethserver.volumes`)

| Volume / Path | Container Mountpoint | Description | Included in Backup |
|---|---|---|---|
| `volumes/gitlab-data` | `/var/opt/gitlab` | Git repositories (Gitaly), PostgreSQL database, Redis state, registry storage | Yes |
| `volumes/gitlab-config` | `/etc/gitlab` | Omnibus configuration (`gitlab.rb`, `gitlab-custom.rb`), `trusted-certs/`, `gitlab-secrets.json`, SSH host keys | Yes |
| `volumes/gitlab-runner-config` | `/etc/gitlab-runner` | Registered runner configuration (`config.toml`) | Yes |
| `volumes/gitlab-logs` | `/var/log/gitlab` | Service and application logs | No |
| `state/gitlab.rb` | `/assets/ns8-gitlab.rb` (`ro`) | Generated Omnibus configuration copied to `/etc/gitlab/gitlab.rb` (mode `0600`) on startup | Regenerated |
| `state/gitlab-custom.rb` | `/assets/ns8-gitlab-custom.rb` (`ro`) | Persistent custom Omnibus Ruby overrides copied to `/etc/gitlab/gitlab-custom.rb` (mode `0600`) | Yes |
| `state/ns8-custom-ca.crt` | `/assets/ns8-custom-ca.crt` (`ro`, optional) | Rendered custom CA certificate copied to `/etc/gitlab/trusted-certs/ns8-custom-ca.crt` | Regenerated (from `passwords.env`) |
| `state/passwords.env` | — | Module secrets (`GITLAB_INITIAL_PASSWORD`, SSO client/app secrets, Base64-encoded PEM certs; mode `0600`) | Yes |
| `state/environment` | — | Non-secret module instance environment variables | Yes (implicit) |

### Environment Variables (`state/environment` & `state/passwords.env`)

| Variable | File | Description |
|---|---|---|
| `HOST` | `state/environment` | Configured FQDN for the GitLab web interface |
| `HTTP2HTTPS` | `state/environment` | Whether Traefik redirects HTTP to HTTPS (`True` / `False`) |
| `LETS_ENCRYPT` | `state/environment` | Whether Traefik requests a Let's Encrypt certificate (`True` / `False`) |
| `GITLAB_NGINX_PORT` | `state/environment` | Allocated local TCP port for GitLab HTTP behind Traefik |
| `GITLAB_REGISTRY_PORT` | `state/environment` | Allocated local TCP port for GitLab Container Registry behind Traefik |
| `GITLAB_SSH_PORT` | `state/environment` | Allocated public TCP port for Git over SSH (opened in node firewall) |
| `GITLAB_REGISTRY_HOST` | `state/environment` | Optional FQDN for the integrated Container Registry |
| `LDAP_DOMAIN` | `state/environment` | Optional NethServer 8 user domain name bound via `Ldapproxy` |
| `RUNNER_ENABLED` | `state/environment` | Enables or disables the integrated GitLab Runner (`True` / `False`) |
| `SSO_ENABLED` | `state/environment` | Master toggle for GitLab OmniAuth Single Sign-On (`True` / `False`) |
| `SSO_ALLOW_SINGLE_SIGN_ON` | `state/environment` | Allow automatic GitLab user creation via SSO (`True` / `False`) |
| `SSO_BLOCK_AUTO_CREATED_USERS` | `state/environment` | Block auto-created SSO users until approved by an administrator (`True` / `False`) |
| `SSO_ALLOW_BYPASS_TWO_FACTOR` | `state/environment` | Allow SSO logins to bypass GitLab's built-in 2FA prompt (`True` / `False`) |
| `SSO_AUTO_LINK_USER` | `state/environment` | Automatically link SSO identities to existing GitLab users with matching email (`True` / `False`) |
| `SSO_AUTO_LINK_LDAP_USER` | `state/environment` | Automatically link SSO identities to matching LDAP users (`True` / `False`) |
| `SSO_AUTO_LINK_SAML_USER` | `state/environment` | Automatically link SAML identities to existing users (`True` / `False`) |
| `SSO_SYNC_PROFILE` | `state/environment` | Sync user name and email from the SSO provider on login (`True` / `False`) |
| `SSO_AUTO_SIGN_IN_PROVIDER` | `state/environment` | Optional active OmniAuth provider key for automatic sign-in redirect |
| `NS8_SSO_PROVIDER` | `state/environment` | Selected NS8 OIDC provider module ID (e.g. `idp1`, `lemonldapng1`) |
| `NS8_SSO_LABEL` | `state/environment` | Sign-in button label for NS8 Cluster SSO (`openid_connect_ns8`) |
| `NS8_SSO_ISSUER` | `state/environment` | OIDC issuer URL returned by the NS8 SSO provider's `register-client` action |
| `NS8_SSO_CLIENT_ID` | `state/environment` | OIDC client ID returned by the NS8 SSO provider's `register-client` action |
| `OIDC_ENABLED`, `OIDC_LABEL`, `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_PKCE`, `OIDC_UID_FIELD`, `OIDC_SCOPES`, `OIDC_CLIENT_AUTH_METHOD` | `state/environment` | External OpenID Connect (`openid_connect`) configuration |
| `SAML_ENABLED`, `SAML_LABEL`, `SAML_IDP_SSO_TARGET_URL`, `SAML_IDP_SLO_TARGET_URL`, `SAML_ISSUER`, `SAML_IDP_CERT_FINGERPRINT`, `SAML_NAME_IDENTIFIER_FORMAT` | `state/environment` | SAML 2.0 (`saml`) service and identity provider configuration |
| `AZURE_ENABLED`, `AZURE_LABEL`, `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` | `state/environment` | Microsoft Entra ID / Azure AD v2 (`azure_activedirectory_v2`) configuration |
| `GITHUB_ENABLED`, `GITHUB_LABEL`, `GITHUB_APP_ID`, `GITHUB_URL` | `state/environment` | GitHub / GitHub Enterprise (`github`) OAuth configuration |
| `GITLAB_OAUTH_ENABLED`, `GITLAB_OAUTH_LABEL`, `GITLAB_OAUTH_APP_ID`, `GITLAB_OAUTH_URL` | `state/environment` | GitLab.com / external GitLab (`gitlab`) OAuth configuration |
| `GOOGLE_ENABLED`, `GOOGLE_LABEL`, `GOOGLE_CLIENT_ID` | `state/environment` | Google Workspace / Google OAuth2 (`google_oauth2`) configuration |
| `OAUTH2_GENERIC_ENABLED`, `OAUTH2_GENERIC_LABEL`, `OAUTH2_GENERIC_APP_ID`, `OAUTH2_GENERIC_SITE`, `OAUTH2_GENERIC_AUTHORIZE_URL`, `OAUTH2_GENERIC_TOKEN_URL`, `OAUTH2_GENERIC_USER_INFO_URL`, `OAUTH2_GENERIC_UID_FIELD` | `state/environment` | Generic OAuth2 (`oauth2_generic`) provider configuration |
| `GITLAB_INITIAL_PASSWORD` | `state/passwords.env` | Initial/configured password for the `root` administrator account (mode `0600`) |
| `NS8_SSO_CLIENT_SECRET` | `state/passwords.env` | OIDC client secret issued by `register-client` on the NS8 SSO provider (mode `0600`) |
| `OIDC_CLIENT_SECRET` | `state/passwords.env` | Client secret for the external OpenID Connect provider (mode `0600`) |
| `SAML_IDP_CERT_B64` | `state/passwords.env` | Base64-encoded SAML 2.0 IdP X.509 PEM certificate (single-line, mode `0600`) |
| `AZURE_CLIENT_SECRET` | `state/passwords.env` | Client secret for Microsoft Entra ID / Azure AD v2 (mode `0600`) |
| `GITHUB_APP_SECRET` | `state/passwords.env` | OAuth app secret for GitHub / GitHub Enterprise (mode `0600`) |
| `GITLAB_OAUTH_APP_SECRET` | `state/passwords.env` | OAuth app secret for GitLab.com / external GitLab (mode `0600`) |
| `GOOGLE_CLIENT_SECRET` | `state/passwords.env` | OAuth client secret for Google Workspace (mode `0600`) |
| `OAUTH2_GENERIC_APP_SECRET` | `state/passwords.env` | Client secret for the Generic OAuth2 provider (mode `0600`) |
| `CUSTOM_CA_CERT_B64` | `state/passwords.env` | Base64-encoded custom trusted CA PEM certificate bundle (single-line, mode `0600`) |

### Maintenance, Backup & Restore

- **Pre-Backup Hook (`imageroot/bin/module-dump-state`):** Automatically invoked by NS8 `run-backup` before Restic snapshots the module volumes. When `gitlab-app` is active and bootstrapped, it runs `gitlab-backup create SKIP=repositories,uploads,builds,artifacts,lfs,terraform_state,ci_secure_files,pages,registry,packages CRON=1` to write a consistent hot PostgreSQL database dump into `/var/opt/gitlab/backups/` without duplicating large repository or registry blobs already covered by `volumes/gitlab-data`.
- **Post-Backup Hook (`imageroot/bin/module-cleanup-state`):** Removes temporary `/var/opt/gitlab/backups/*_gitlab_backup.tar` archives after the Restic snapshot finishes.
- **Database Restore (`imageroot/actions/restore-module/40restoreDB`):** After Restic restores the volumes and `state/gitlab-custom.rb` in `10restore`, `40restoreDB` launches an ephemeral `${GITLAB_CE_IMAGE}` container, starts the embedded PostgreSQL service, and runs `gitlab-backup restore` against the backup archive in `/var/opt/gitlab/backups/` before `50configure` re-applies routes, firewall rules, SSO client registration, and starts the services.

---

## Update Module via CLI

Updates are normally applied through the **NethServer 8 Software Center UI**. To manually update via CLI:

```bash
api-cli run update-module --data '{"module_url":"ghcr.io/bls-isp/gitlab:1.1.0","instances":["gitlab1"]}'
```

---

## Publishing a New Release (Semantic Versioning)

In accordance with NethServer 8 standards, releases must use pure **Semantic Versioning (`X.Y.Z`) without a `v` prefix** (e.g. `1.1.0`, `1.2.0`, or `1.2.0-testing.1` for pre-releases):

```bash
git tag -a 1.1.0 -m "Release 1.1.0"
git push origin main --tags
```

The GitHub Actions workflow (`.github/workflows/publish-images.yml`) automatically builds and publishes `ghcr.io/bls-isp/gitlab:1.1.0` and updates `:latest`.

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
./test-module.sh <NODE_ADDR> ghcr.io/bls-isp/gitlab:1.1.0
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
