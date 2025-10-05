# Ansible Role: compose-stack

Manage Docker Compose v2 stacks with opinionated, pre-configured definitions.

## Requirements

Ansible ≥ 2.12, Docker Engine + Compose v2, `community.docker` collection, Python `docker` library

## Installation

```bash
ansible-galaxy install cloudnonsense.compose_stack
```

## Quick Start

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "demo"
        compose_stack_name: "myapp"
        compose_stack_state: "present"
```

## Variables

**Required:** `compose_stack_type`, `compose_stack_name`, `compose_stack_state` (`"present"`/`"absent"`)

**Optional:** `compose_stack_domain`, `compose_stack_additional_networks`, `compose_stack_base_dir`, `compose_stack_restart_policy`, file/dir ownership/permissions, destroy options

## Available Stacks

- `demo` - nginx
- `grafana` - Grafana + InfluxDB

## Architecture

- Opinionated service definitions in `vars/{{ type }}.yml`
- Auto-generated networks: primary = stack name, additional via `compose_stack_additional_networks` (must exist externally)
- Universal template `templates/compose.yml.j2` renders all stacks

## Testing

```bash
./test-all-scenarios.sh [converge|verify]  # All stacks
molecule test -s demo                       # Individual
```

## License

MIT

## Author

[CloudNonsense.com](https://cloudnonsense.com)
