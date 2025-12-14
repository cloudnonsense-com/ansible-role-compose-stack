# Architecture Diagram

This diagram illustrates the complete workflow of the Ansible Docker Compose Stack Role.

```mermaid
flowchart TD
    Start([Role Invoked]) --> Main[tasks/main.yml]

    Main --> Validate[tasks/validate.yml]

    Validate --> CheckVars{Check Required Vars}
    CheckVars -->|Missing| Fail1[Fail: Missing Variables]
    CheckVars -->|OK| CheckType{Stack Type Valid?}

    CheckType -->|Invalid| Fail2[Fail: Unknown Stack Type]
    CheckType -->|Valid| LoadVars[Load vars/type.yml]

    LoadVars --> ValidateStack[tasks/validate-type.yml]
    ValidateStack -->|Fail| Fail3[Fail: Stack Config Invalid]
    ValidateStack -->|Pass| CheckState{State?}

    CheckState -->|present| Preflight[tasks/preflight.yml]
    CheckState -->|absent| Destroy[tasks/destroy.yml]

    Preflight --> CheckDocker{Docker Available?}
    CheckDocker -->|No| Fail4[Fail: Docker Not Found]
    CheckDocker -->|Yes| CheckCompose{Compose v2?}

    CheckCompose -->|No| Fail5[Fail: Wrong Version]
    CheckCompose -->|Yes| CheckNetworks{Networks Exist?}

    CheckNetworks -->|No| Fail6[Fail: Networks Missing]
    CheckNetworks -->|Yes| CheckBuild{Build Context Needed?}

    CheckBuild -->|Yes| BuildContext[tasks/build-context.yml]
    CheckBuild -->|No| Create[tasks/create.yml]
    BuildContext --> Create

    Create --> CreateDir[Create Stack Directory]
    CreateDir --> GenCompose[Generate compose.yml]
    GenCompose --> GenEnv[Generate .env File]
    GenEnv --> Deploy[docker compose up -d]
    Deploy --> CheckLog{Log Deployments?}

    CheckLog -->|Yes| LogChanges[tasks/log-changes.yml]
    CheckLog -->|No| Done1([Success])
    LogChanges --> Done1

    Destroy --> RemoveStack[docker compose down]
    RemoveStack --> CheckVolumes{Remove Volumes?}
    CheckVolumes -->|Yes| RemoveVol[Remove Volumes]
    CheckVolumes -->|No| CheckImages
    RemoveVol --> CheckImages{Remove Images?}

    CheckImages -->|all/local| RemoveImg[Remove Images]
    CheckImages -->|No| Done2([Success])
    RemoveImg --> Done2

    style Start fill:#e1f5e1
    style Done1 fill:#e1f5e1
    style Done2 fill:#e1f5e1
    style Fail1 fill:#ffe1e1
    style Fail2 fill:#ffe1e1
    style Fail3 fill:#ffe1e1
    style Fail4 fill:#ffe1e1
    style Fail5 fill:#ffe1e1
    style Fail6 fill:#ffe1e1
```

## Configuration Flow

```mermaid
flowchart LR
    DefaultVars[defaults/main.yml<br/>compose_stack_*] --> Override{User Variables}
    Override -->|Override| StackDict[vars/main.yml<br/>stack dict]

    TypeVars[vars/type.yml<br/>Stack Definition] --> StackDict

    StackDict --> Services[services list]
    StackDict --> Networks[networks config]
    StackDict --> Volumes[volumes config]

    Services --> Template[templates/compose.yml.j2]

    Template --> IncCommon[_includes/service_common.j2]
    Template --> IncBuild[_includes/service_build.j2]
    Template --> IncCaps[_includes/service_capabilities.j2]
    Template --> IncConfigs[_includes/configs.j2]

    IncCommon --> Final[Final compose.yml]
    IncBuild --> Final
    IncCaps --> Final
    IncConfigs --> Final

    Env[Environment Variables] --> EnvTemplate[templates/env.j2]
    EnvTemplate --> EnvFile[.env file<br/>mode 0600]

    style DefaultVars fill:#e1e8f5
    style TypeVars fill:#e1e8f5
    style Final fill:#e1f5e1
    style EnvFile fill:#fff4e1
```

## Template Processing

```mermaid
flowchart TD
    Start([Generate Compose File]) --> Loop{For Each Service}

    Loop -->|Next Service| SetData[svc_data = service item]
    SetData --> Common[Include service_common.j2]

    Common --> CheckBuild{Has build attribute?}
    CheckBuild -->|Yes| Build[Include service_build.j2]
    CheckBuild -->|No| CheckCaps
    Build --> CheckCaps

    CheckCaps{Has capabilities?}
    CheckCaps -->|Yes| Caps[Include service_capabilities.j2]
    CheckCaps -->|No| CheckConfigs
    Caps --> CheckConfigs

    CheckConfigs{Has configs?}
    CheckConfigs -->|Yes| Configs[Include configs.j2]
    CheckConfigs -->|No| CheckMore
    Configs --> CheckMore

    CheckMore{More Services?}
    CheckMore -->|Yes| Loop
    CheckMore -->|No| AddNetworks[Add Networks Section]

    AddNetworks --> AddVolumes[Add Volumes Section]
    AddVolumes --> Done([Complete])

    style Start fill:#e1f5e1
    style Done fill:#e1f5e1
```

## Stack Types

```mermaid
graph LR
    Role[Ansible Role] --> Demo[demo<br/>Nginx Test]
    Role --> Grafana[grafana<br/>Monitoring Stack]
    Role --> Traefik[traefik<br/>Reverse Proxy]
    Role --> Runner[actions<br/>GitHub Runner]
    Role --> Netbird[netbird<br/>VPN Client]
    Role --> Registry[registry<br/>Docker Registry v2]

    Demo --> DemoAssets[No Custom Assets]

    Grafana --> GrafanaAssets[templates/grafana/<br/>Dashboards]

    Traefik --> TraefikAssets[templates/traefik/<br/>Configs + Certs]

    Runner --> RunnerAssets[templates/actions/build/<br/>Dockerfile + Entrypoint]

    Netbird --> NetbirdAssets[Host Network Mode<br/>For VPN Tunnel]

    Registry --> RegistryAssets[templates/registry/<br/>Config File]

    style Role fill:#e1e8f5
    style Demo fill:#fff4e1
    style Grafana fill:#fff4e1
    style Traefik fill:#fff4e1
    style Runner fill:#fff4e1
    style Netbird fill:#fff4e1
    style Registry fill:#fff4e1
```

## Testing Structure

```mermaid
flowchart TD
    Test[Test Execution] --> Script[./test-all-scenarios.sh<br/>Excludes _shared]
    Script --> MolDemo[molecule/demo/]
    Script --> MolGrafana[molecule/grafana/]
    Script --> MolTraefik[molecule/traefik/]
    Script --> MolRunner[molecule/actions/]
    Script --> MolNetbird[molecule/netbird/]
    Script --> MolRegistry[molecule/registry/]

    Shared[molecule/_shared/<br/>Common Resources] -.->|Vars| MolDemo
    Shared -.->|Verify| MolDemo
    Shared -.->|Cleanup| MolDemo
    Shared -.->|Vars| MolGrafana
    Shared -.->|Verify| MolGrafana
    Shared -.->|Cleanup| MolGrafana

    MolDemo --> Prepare1[prepare.yml<br/>Create networks]
    Prepare1 --> Converge1[converge.yml<br/>Include _shared/common-vars.yml]
    Converge1 --> Verify1[verify.yml<br/>Include _shared/verify-common.yml]
    Verify1 --> Cleanup1[cleanup.yml<br/>Include _shared/cleanup-volumes.yml]
    Cleanup1 --> Side1[side_effect<br/>_shared/cleanup-misc.yml]

    MolGrafana --> PrepareN[prepare.yml]
    PrepareN --> ConvergeN[converge.yml]
    ConvergeN --> VerifyN[verify.yml]
    VerifyN --> CleanupN[cleanup.yml]
    CleanupN --> SideN[side_effect]

    style Test fill:#e1e8f5
    style Script fill:#e1f5e1
    style Shared fill:#fff4e1
```

## Key Components

### Validation Chain
1. Generic variable validation (validate.yml)
2. Stack-specific config validation (validate-type.yml)
3. Environment preflight checks (preflight.yml)

### File Permissions
- Regular files: 0644
- Directories: 0755
- Environment files (.env): 0600

### Network Architecture
- Auto-generated network: `{{ stack.name }}`
- Additional networks: `stack.additional_networks` (must exist externally)
- Netbird uses `network_mode: host` for direct network access (required for VPN tunneling)

### Build Context
- Auto-detected via `build` attribute in service definition
- Files templated from `templates/{{ type }}/build/`
- Dockerfile and assets copied to stack directory

### Destroy Options
- `compose_stack_destroy_remove_volumes`: Remove volumes (boolean)
- `compose_stack_destroy_remove_images`: Remove images (all/local/false)
