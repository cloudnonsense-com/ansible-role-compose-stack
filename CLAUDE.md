# CLAUDE.md

Guidance for Claude Code on this Ansible role for Docker Compose v2 stacks.

## Architecture

**Workflow**: Validate → Load `vars/{{ stack.type }}.yml` → Execute create/destroy

**Config**: `compose_stack_*` vars (defaults/main.yml) → `stack` dict (vars/main.yml). Stack definitions in `vars/{{ type }}.yml` (opinionated, not user-modifiable).

**Template**: Universal `templates/compose.yml.j2` + modular includes (templates/includes/*.j2). Loops `services` list via `svc_data`.

**Networks**: Auto-generated `[stack.name] + stack.additional_networks`. Must exist externally.

**Environment Variables**: Extracted to `.env` files with mode `0600` for security. Created in stack directory alongside compose.yml.

**Overrides**: Per-service `image` and `restart` policy overrides via `compose_stack_config.<service>.image` and `compose_stack_config.<service>.restart`.

## Testing

Separate scenarios per stack. No `molecule/default/`.

```bash
./test-all-scenarios.sh [test|converge|verify]
molecule test -s demo
molecule converge -s demo && molecule verify -s demo
```

**Per scenario**: molecule.yml, prepare.yml (networks), converge.yml, verify.yml, cleanup.yml

## Available Stacks

- **demo**: Nginx web server (testing)
- **grafana**: Grafana + InfluxDB + Telegraf + Prometheus (monitoring)
- **traefik**: Traefik v3 reverse proxy (routing/TLS)
- **actions-runner**: GitHub Actions self-hosted runner (CI/CD)

## Adding a Stack

1. `vars/{{ type }}.yml`: `services` list with `{{ stack.name }}-<service>` naming, hardcoded config, no networks
2. (Optional) `templates/{{ type }}/` for custom assets (configs, Dockerfiles, etc.)
3. `molecule/{{ type }}/` with test files:
   - `molecule.yml` - Scenario configuration
   - `prepare.yml` - Network setup
   - `converge.yml` - Stack deployment
   - `verify.yml` - Validation tests
   - `cleanup.yml` - Teardown

## Dev Notes

- **Validation**: tasks/validate.yml checks required vars and stack type
- **Stacks are opinionated**: Pre-configured "as-is" with hardcoded settings
- **Modified versions**: Create new stack variants instead of modifying existing ones
- **File permissions**: Separate modes for regular files (0644), directories (0755), and .env files (0600)
- **Destroy behavior**: Controlled by `compose_stack_destroy_remove_volumes` and `compose_stack_destroy_remove_images`
- **Docker Compose compatibility**: Tested with v2.40.1+ (uses `docker compose` not `docker-compose`)
