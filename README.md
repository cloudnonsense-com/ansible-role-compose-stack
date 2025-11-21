# Ansible Role: compose-stack

Deploy opinionated Docker Compose v2 stacks with pre-configured services, automated validation, and security-hardened defaults.

**[View Architecture Diagrams →](docs/architecture.md)**

## Requirements

- Ansible ≥ 2.12
- Docker Engine + Compose v2.40.1+
- `community.docker` collection
- Python `docker` library

## Installation

```bash
ansible-galaxy install cloudnonsense.compose_stack
```

## Usage

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "demo"
        compose_stack_name: "myapp"
        compose_stack_state: "present"
```

### Configuration

**Required:**
- `compose_stack_type` - Stack type (demo/grafana/traefik/actions/netbird/registry)
- `compose_stack_name` - Unique stack identifier
- `compose_stack_state` - `present` or `absent`

**Optional:**
| Variable | Default | Description |
|----------|---------|-------------|
| `compose_stack_domain` | `""` | Domain for Traefik routing labels |
| `compose_stack_additional_networks` | `[]` | External networks to attach |
| `compose_stack_base_dir` | `/opt/apps` | Stack deployment directory |
| `compose_stack_restart_policy` | `always` | Default container restart policy |
| `compose_stack_expose_ports` | `false` | Expose service ports to host (false = more secure) |
| `compose_stack_config` | `{}` | Stack-specific config + overrides |
| `compose_stack_file_owner/group` | `root` | File ownership |
| `compose_stack_file_mode` | `0644` | File permissions |
| `compose_stack_dir_mode` | `0755` | Directory permissions |
| `compose_stack_env_file_mode` | `0600` | .env file permissions (secure) |
| `compose_stack_destroy_remove_volumes` | `true` | Remove volumes on destroy |
| `compose_stack_destroy_remove_images` | `local` | Remove images (`all`/`local`) |

## Stacks

### demo

Nginx web server for testing. No configuration required.

### grafana

Monitoring stack: Grafana + InfluxDB + Telegraf + Prometheus with provisioned dashboards.

**Required config:**
```yaml
compose_stack_config:
  influxdb:
    database: "monitoring"
    admin_user: "admin"
    admin_password: "secure_password"
  grafana:
    admin_user: "admin"
    admin_password: "secure_password"
```

**Services:**
- Grafana (port 37011) - Visualization + provisioned datasources/dashboards
- InfluxDB 1.8 (port 37012) - Time-series database
- Telegraf - Metrics collection
- Prometheus (port 37013) - Additional metrics

**Includes:** ISP public IP geolocation dashboard

### traefik

Traefik v3 reverse proxy with TLS, Docker discovery, and automatic routing.

**Required files in `templates/traefik/`:**
- `traefik.yaml` - Main configuration
- `tls.yml` - TLS settings
- `cert.crt` and `cert.key` - TLS certificates

**Exposes:** 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)

### actions

Self-hosted GitHub Actions runner with Docker-in-Docker build support.

**Required config:**
```yaml
compose_stack_config:
  actions:
    runner_scope: "org"  # Optional: "org" (default) or "repo"
    github_organization: "your-org"
    github_repository: "your-repo"  # Required only when runner_scope is "repo"
    github_access_token: "ghp_xxxxx"
    runner_name: "runner-name"
    runner_labels: "self-hosted,linux,x64"  # Optional
```

**Features:** Custom Dockerfile, automatic registration, DinD capability, org-level and repo-level scopes

### netbird

Netbird VPN mesh network client for secure peer-to-peer connectivity.

**Required config:**
```yaml
compose_stack_config:
  netbird:
    hostname: "netbird-client"
    setup_key: "your-netbird-setup-key"
```

**Network mode:** Uses `network_mode: host` for direct network access, required for VPN tunnel creation and network interface manipulation.

### registry

Docker Registry v2 with web UI for container image storage and management.

**Required config:** None (works out of the box)

**Services:**
- Registry v2 (port 37022) - Docker Registry server with delete support
- Registry UI (port 37021) - Web interface for browsing and managing images

**Features:** Image deletion, content digest display, CORS support for web UI

## Advanced Features

### Per-Service Overrides

Customize images or restart policies per service:

```yaml
compose_stack_config:
  grafana:
    image: "grafana/grafana-enterprise:11.5.1"
    restart: "unless-stopped"
```

### Environment Variables

Credentials and environment variables are automatically extracted to `.env` files with `0600` permissions for enhanced security.

### Preflight Checks

Automated validation before deployment:
- Docker and Docker Compose v2 availability
- Required external networks existence
- Stack-specific configuration validation

### Build Context Support

Stacks with custom Docker builds (e.g., `actions`) automatically handle build context creation, file templating, and script permissions.

## License

MIT | [CloudNonsense.com](https://cloudnonsense.com)
