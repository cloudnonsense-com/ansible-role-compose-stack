# CLAUDE.md

Developer guidance for this Ansible role managing Docker Compose v2 stacks.

## Architecture

**Workflow**: `tasks/main.yml` → Validate → Stack validation → Preflight → Load `vars/{{ type }}.yml` → Create/Destroy

**Task Flow**:
- `validate.yml` - Required vars + stack type validation
- `validate-{{ type }}.yml` - Stack-specific config validation
- `preflight.yml` - Docker/Compose/network checks (create only)
- `build-context.yml` - Build directory setup (if `build` attribute present)
- `create.yml` or `destroy.yml` - Stack operations
- `log-changes.yml` - Optional deployment history (if `compose_stack_log_deployments: true`)

**Config Flow**: `compose_stack_*` vars (defaults/main.yml) → `stack` dict (vars/main.yml). Stack defs in `vars/{{ type }}.yml` (opinionated, hardcoded).

**Templates**: `templates/compose.yml.j2` + modular includes:
- `includes/service_common.j2` - Base service config
- `includes/service_build.j2` - Build context handling
- `includes/service_capabilities.j2` - Linux capabilities (cap_add)
- `includes/configs.j2` - Docker configs
- Loops `services` list, each item becomes `svc_data`

**Networks**: Auto-generated `{{ stack.name }}` + `stack.additional_networks`. Must exist externally.

**Environment**: Extracted to `.env` files (mode `0600`) in stack directory. Template: `templates/env.j2`

**Overrides**: Per-service via `compose_stack_config.<service>.image` / `.restart`

## Testing

Per-stack scenarios (no `molecule/default/`). Shared verification in `molecule/shared/verify-common.yml`.

```bash
./test-all-scenarios.sh [test|converge|verify]  # All scenarios
molecule test -s demo                            # Single scenario
molecule converge -s demo && molecule verify -s demo
```

**Scenario structure**: `molecule/{{ type }}/` with molecule.yml, prepare.yml, converge.yml, verify.yml (includes shared), cleanup.yml

## Stacks

| Type | Description | Custom Assets |
|------|-------------|---------------|
| `demo` | Nginx test server | - |
| `grafana` | Monitoring (Grafana/InfluxDB/Telegraf/Prometheus) | `templates/grafana/` dashboards |
| `traefik` | Reverse proxy v3 | `templates/traefik/` configs + certs |
| `actions-runner` | GitHub Actions runner | `templates/actions-runner/build/` Dockerfile + entrypoint |
| `netbird` | VPN mesh network client | - |

## Adding a Stack

1. **Define stack**: `vars/{{ type }}.yml` - `services` list, `{{ stack.name }}-<name>` naming, no `networks` key
2. **Add validation**: `tasks/validate-{{ type }}.yml` - Check required `compose_stack_config` vars
3. **Custom assets** (optional): `templates/{{ type }}/` - Configs, Dockerfiles, dashboards
4. **Build support** (optional): Add `build: context: ./build` to service + Dockerfile in `templates/{{ type }}/build/`
5. **Test scenario**: `molecule/{{ type }}/` - molecule.yml, prepare.yml, converge.yml, verify.yml (include shared), cleanup.yml

## Key Notes

- **Opinionated stacks**: Hardcoded, pre-configured. Create variants for modifications.
- **Validation chain**: Generic → Stack-specific → Preflight (Docker/networks)
- **Permissions**: Files `0644`, dirs `0755`, .env `0600`
- **Build context**: Auto-detected via `build` attribute, files templated from `templates/{{ type }}/build/`
- **Linux capabilities**: Optional `capabilities` list in service definition (e.g., `NET_ADMIN`, `SYS_ADMIN`)
- **Destroy options**: `compose_stack_destroy_remove_volumes` (bool), `compose_stack_destroy_remove_images` (all/local)
- **Compatibility**: Docker Compose v2.40.1+ (`docker compose` not `docker-compose`)
- **Shared verification**: Common container/network checks in `molecule/shared/verify-common.yml`
- **Netbird networking**: Uses experimental bridged networking (standard Docker network) instead of official `network_mode: host`. May require host networking if connectivity issues occur.
- it's mandatory for every stack to have a healthcheck.