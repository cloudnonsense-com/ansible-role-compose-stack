# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible role (`cloudnonsense.compose_stack`) for managing Docker Compose v2 stacks with a declarative, template-based approach. The role provides lifecycle management (deploy/update/destroy) for Docker Compose applications.

## Architecture

### Core Workflow

The role follows a strict execution flow in tasks/main.yml:
1. **Validate** - Check all required variables (tasks/validate.yml)
2. **Load Per-Stack Variables** - Auto-include `defaults/{{ stack.name }}.yml`
3. **Execute State** - Run create.yml or destroy.yml based on `stack.state`

### Template System

The role uses a two-layer configuration pattern:

1. **Core Stack Config** (`defaults/main.yml`) - Defines the `stack` dictionary with paths, permissions, network, and destroy settings
2. **Per-Stack Services** (`defaults/{{ stack.name }}.yml`) - Defines the `services` dictionary with container-specific config

Templates in `templates/{{ stack.name }}/compose.yml.j2` reference both dictionaries and use modular includes from `templates/includes/` for reusable blocks (service_common, service_ports, service_labels, service_networks, service_configs, networks, configs, etc.).

**Important Pattern**: Templates set a local variable referencing the service config, e.g.:
```jinja2
{% set svc = services.nginxdemo %}
```
Then include modular templates that reference `svc` for that service's configuration.

### Task Organization

- **tasks/validate.yml** - Multi-stage validation using `assert` modules:
  - Core variable existence and types
  - State-specific variable validation (present vs absent)
  - Template file existence check

- **tasks/create.yml** - Deployment tasks:
  - Create Docker networks (if defined)
  - Create stack directory
  - Render compose.yml from Jinja2 template
  - Start/update stack via `community.docker.docker_compose_v2`

- **tasks/destroy.yml** - Cleanup tasks:
  - Check directory existence first
  - Stop compose stack with configurable cleanup (images/volumes)
  - Remove stack directory
  - Remove networks (if `destroy.remove_networks: true`)

## Testing

Uses Molecule for integration testing in `molecule/default/`:

### Test Commands
```bash
# Full test suite
molecule test

# Individual phases
molecule create       # Build test container
molecule converge     # Deploy stacks
molecule idempotence  # Verify no changes on re-run
molecule verify       # Run verification tests
molecule destroy      # Cleanup

# Development workflow
molecule converge && molecule verify  # Quick test cycle
```

### Test Environment

- **Driver**: Docker
- **Image**: geerlingguy/docker-ubuntu2204-ansible:latest
- **Privileged**: Required for Docker-in-Docker
- **Volumes**: Mounts Docker socket and cgroup

### What's Tested

The verify.yml playbook tests:
- HTTP responses from deployed services (nginx on :37080, grafana on :37005, influxdb on :8086)
- Docker network creation (nginx-demo, grafana)
- Compose stack status via `docker compose ps`
- Service availability and expected content

## Development Patterns

### Adding a New Stack

1. Create `defaults/{{ stack_name }}.yml` with the `services` dictionary
2. Create `templates/{{ stack_name }}/compose.yml.j2` using standard includes
3. Use the existing pattern: `{% set svc = services.servicename %}` then include modular templates
4. Add convergence test to `molecule/default/converge.yml`
5. Add verification tests to `molecule/default/verify.yml`

### Variable Validation

When adding new stack variables:
- Add validation to tasks/validate.yml
- Use state-specific validation blocks for present/absent states
- Provide clear fail_msg describing what's required

### Modifying Templates

- Reusable logic belongs in `templates/includes/*.j2`
- Stack-specific templates in `templates/{{ stack_name }}/`
- Always reference `svc` variable for service config (set via `{% set svc = services.servicename %}`)

## Key Variables

The `stack` dictionary drives all behavior:

**Required Core Variables**:
- `stack.name` - Stack identifier
- `stack.state` - "present" or "absent"
- `stack.dst_dir` - Destination directory for compose.yml

**State-Specific**:
- When `state: present` - requires `src_file`, `file.mode`, `dir.mode`
- When `state: absent` - requires `destroy.{remove_images,remove_volumes,remove_networks}`

**Auto-Loaded**:
- `services` dictionary from `defaults/{{ stack.name }}.yml`

## Requirements

- Ansible ≥ 2.12
- Docker Engine with Compose v2 plugin
- Ansible collection: `community.docker`
- Python docker library on target hosts
