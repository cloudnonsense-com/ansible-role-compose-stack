# Ansible Role: compose-stack

Manage Docker Compose v2 stacks with opinionated, pre-configured definitions. Deploy production-ready stacks with minimal configuration.

## Requirements

- Ansible ≥ 2.12
- Docker Engine with Compose v2 plugin
- Ansible collection: `community.docker`
- Python `docker` library on target hosts

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

**Required:**
- `compose_stack_type` - Stack type (`"demo"`, `"grafana"`)
- `compose_stack_name` - Instance identifier (e.g., `"grafana-dev"`, `"grafana-prd"`)
- `compose_stack_state` - `"present"` or `"absent"`

**Optional:**
- `compose_stack_domain` - Domain name (default: `""`)
- `compose_stack_additional_networks` - Additional networks beyond primary (default: `[]`)
- `compose_stack_base_dir` - Base directory (default: `"/opt/apps"`)
- `compose_stack_restart_policy` - Restart policy (default: `"always"`)
- `compose_stack_file_owner` - File owner (default: `"root"`)
- `compose_stack_file_mode` - File permissions (default: `"0644"`)
- `compose_stack_dir_mode` - Directory permissions (default: `"0755"`)
- `compose_stack_destroy_remove_volumes` - Remove volumes on destroy (default: `true`)
- `compose_stack_destroy_remove_images` - Remove images: `"all"` or `"local"` (default: `"local"`)

## Available Stacks

- `demo` - Basic nginx demo
- `grafana` - Grafana + InfluxDB monitoring

Stacks are opinionated and consumed "as-is" with minimal user input.

## Usage Examples

### Deploy Stack

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "grafana"
        compose_stack_name: "grafana-dev"
        compose_stack_state: "present"
        compose_stack_additional_networks:
          - traefik-prod
```

### Destroy Stack

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "grafana"
        compose_stack_name: "grafana-dev"
        compose_stack_state: "absent"
```

### Multiple Instances

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "grafana"
        compose_stack_name: "grafana-dev"

    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "grafana"
        compose_stack_name: "grafana-prd"
```

## Architecture

- **Opinionated Stacks** - Pre-configured in `vars/{{ compose_stack_type }}.yml`
- **Auto-Generated Networks** - Primary network = stack name, additional via `compose_stack_additional_networks`
- **External Networks** - All networks must exist before deployment
- **Universal Template** - `templates/compose.yml.j2` renders all stacks

## Testing

```bash
# Test all stacks
./test-all-scenarios.sh

# Run specific command on all stacks
./test-all-scenarios.sh converge
./test-all-scenarios.sh verify

# Test individual stack
molecule test -s demo
```

## License

MIT

## Author

[CloudNonsense.com](https://cloudnonsense.com)
