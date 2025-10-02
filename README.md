# Ansible Role: compose-stack

Ansible role for managing Docker Compose v2 stacks with declarative configuration and Jinja2 templates.

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
        compose_stack_name: "myapp"
        compose_stack_domain: "example.lan"
        compose_stack_state: "present"
```

## Variables

**Required:**
- `compose_stack_name` - Stack identifier
- `compose_stack_state` - `"present"` or `"absent"`

**Optional:**
- `compose_stack_domain` - Domain name (default: `""`)
- `compose_stack_base_dir` - Base directory (default: `"/opt/apps"`)
- `compose_stack_dst_dir` - Destination directory (default: `"{{ compose_stack_base_dir }}/{{ compose_stack_name }}"`)
- `compose_stack_src_file` - Template filename (default: `"compose.yml.j2"`)
- `compose_stack_file_owner` - File owner (default: `"root"`)
- `compose_stack_file_mode` - File permissions (default: `"0644"`)
- `compose_stack_dir_mode` - Directory permissions (default: `"0755"`)
- `compose_stack_destroy_remove_volumes` - Remove volumes on destroy (default: `true`)
- `compose_stack_destroy_remove_images` - Remove images on destroy: `"all"` or `"local"` (default: `"local"`)

## Usage Examples

### Deploy Stack

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "nginxdemo"
        compose_stack_domain: "example.lan"
```

### Destroy Stack

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "nginxdemo"
        compose_stack_state: "absent"
```

### Deploy Multiple Stacks

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "nginxdemo"
        compose_stack_domain: "example.lan"

    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "grafana"
        compose_stack_domain: "example.lan"
```

## Testing

Molecule tests are organized per-stack:

```bash
# Test all stacks
molecule test -s nginxdemo && molecule test -s grafana

# Test individual stack
molecule test -s nginxdemo

# Development workflow
molecule converge -s nginxdemo
molecule verify -s nginxdemo
```

## License

MIT

## Author

[CloudNonsense.com](https://cloudnonsense.com)
