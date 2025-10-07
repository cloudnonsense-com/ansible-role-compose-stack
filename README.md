# Ansible Role: compose-stack

Manage Docker Compose v2 stacks with opinionated, pre-configured definitions.

## Requirements

Ansible ≥ 2.12, Docker Engine + Compose v2, `community.docker` collection, Python `docker` library

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

**Required vars:** `compose_stack_type`, `compose_stack_name`, `compose_stack_state` (`present`/`absent`)

**Optional:** `compose_stack_domain`, `compose_stack_additional_networks`, `compose_stack_base_dir`, `compose_stack_restart_policy`, `compose_stack_config`

## Stacks

**`demo`** - Nginx (no required config)

**`grafana`** - Grafana + InfluxDB + Telegraf + Prometheus
```yaml
compose_stack_config:
  influxdb: {database: "monitoring", admin_user: "admin", admin_password: "pass"}
  grafana: {admin_user: "admin", admin_password: "pass"}
```

## Per-Service Overrides

```yaml
compose_stack_config:
  <service>:
    image: "custom/image:tag"    # Override default image
    restart: "on-failure"        # Override restart policy
```

## License

MIT | [CloudNonsense.com](https://cloudnonsense.com)
