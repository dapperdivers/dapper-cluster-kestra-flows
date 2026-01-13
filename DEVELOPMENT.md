# Development Guide

Quick reference for developing Kestra flows in this repository.

## Quick Start

```bash
# 1. Ensure tools are installed
which pre-commit yamllint

# 2. Pre-commit hooks are already installed
# They will run automatically on git commit

# 3. Validate your changes
yamllint _flows/

# Or use the helper script
./scripts/validate-flows.sh
```

## Project Structure Explained

### `_flows/`
Contains all flow definitions, organized by namespace. Each subdirectory represents a Kestra namespace.

**Example:**
- `_flows/homelab/` → flows in the `homelab` namespace
- `_flows/production/` → flows in the `production` namespace

### `subflows/`
Reusable workflow components that can be called from multiple flows. Think of these as functions that can be invoked from any flow.

### `modules/`
Optional directory for more complex workflow patterns or templates. Use this for sophisticated reusable patterns that involve multiple flows or complex logic.

### `scripts/`
Helper scripts for development tasks:
- `validate-flows.sh` - Run YAML validation
- `create-namespace.sh` - Create new namespace with template

### `.github/workflows/`
CI/CD automation:
- `validate.yaml` - Validates flows on every PR and optionally deploys on merge

## Common Development Tasks

### Create a New Flow

```bash
# 1. Determine the namespace
NAMESPACE="homelab"

# 2. Create the flow file
cat > _flows/${NAMESPACE}/my_new_flow.yaml <<EOF
id: my_new_flow
namespace: ${NAMESPACE}

description: |
  Description of what this flow does

tasks:
  - id: first_task
    type: io.kestra.plugin.core.log.Log
    message: "Hello from my new flow!"
EOF

# 3. Validate
yamllint _flows/${NAMESPACE}/my_new_flow.yaml

# 4. Commit
git add _flows/${NAMESPACE}/my_new_flow.yaml
git commit -m "Add my_new_flow to ${NAMESPACE} namespace"
```

### Create a New Namespace

```bash
./scripts/create-namespace.sh production
```

This creates:
- `_flows/production/` directory
- An example flow to get started

### Test Locally with Docker

```bash
# Start local Kestra instance
docker-compose up -d

# Access UI
open http://localhost:8080

# View logs
docker-compose logs -f kestra

# Stop
docker-compose down
```

### Validate Before Committing

Pre-commit hooks run automatically, but you can run manually:

```bash
# Run all hooks
pre-commit run --all-files

# Run specific hook
pre-commit run yamllint --all-files
```

## Flow Development Best Practices

### 1. Start Simple
```yaml
id: simple_flow
namespace: homelab

tasks:
  - id: test
    type: io.kestra.plugin.core.log.Log
    message: "Testing"
```

### 2. Add Inputs for Flexibility
```yaml
inputs:
  - id: environment
    type: STRING
    defaults: "development"

tasks:
  - id: log_env
    type: io.kestra.plugin.core.log.Log
    message: "Running in {{ inputs.environment }}"
```

### 3. Use Subflows for Reusability
```yaml
tasks:
  - id: common_task
    type: io.kestra.plugin.core.flow.Subflow
    namespace: subflows
    flowId: example_subflow
    inputs:
      message: "Hello from parent flow"
```

### 4. Handle Outputs
```yaml
tasks:
  - id: generate_data
    type: io.kestra.plugin.scripts.shell.Commands
    commands:
      - echo "result" > output.txt
    outputFiles:
      - "output.txt"

  - id: use_data
    type: io.kestra.plugin.core.log.Log
    message: "{{ outputs.generate_data.outputFiles['output.txt'] }}"
```

## Debugging Tips

### Check YAML Syntax
```bash
# Validate specific file
yamllint _flows/homelab/my_flow.yaml

# Validate all flows
yamllint _flows/

# Check for specific issues
yamllint -f parsable _flows/
```

### Common YAML Issues

**Indentation:**
- Always use 2 spaces
- Never use tabs
- Be consistent

**Long Lines:**
- Keep lines under 120 characters
- Use YAML multi-line strings for long values:
```yaml
description: |
  This is a long description
  split across multiple lines
```

**Quotes:**
- Use quotes for strings with special characters
- Use quotes for Jinja templates: `"{{ variable }}"`

### Test Flow Locally

1. Start local Kestra: `docker-compose up -d`
2. Copy flow to Kestra UI
3. Click "Execute"
4. Check logs for errors
5. Iterate until working
6. Copy back to file

## Git Workflow

```bash
# 1. Create feature branch
git checkout -b feature/new-flow

# 2. Make changes
# Edit files...

# 3. Validate
./scripts/validate-flows.sh

# 4. Commit (pre-commit hooks run automatically)
git add .
git commit -m "Add new flow for X"

# 5. Push
git push origin feature/new-flow

# 6. Create PR
# CI validation runs automatically
```

## Environment Variables

Never commit secrets! Use one of these approaches:

### Option 1: Kestra KV Store
```yaml
env:
  SECRET_KEY: "{{ kv('SECRET_KEY') }}"
```

### Option 2: Namespace Variables
Configure in Kestra UI under Namespace settings

### Option 3: Environment Variables
```yaml
env:
  API_KEY: "{{ envs.API_KEY }}"
```

## Troubleshooting

### Pre-commit Hooks Failing

```bash
# Update hooks
pre-commit autoupdate

# Clear cache
pre-commit clean

# Run manually to see detailed errors
pre-commit run --all-files --verbose
```

### YAML Validation Errors

```bash
# Get detailed error output
yamllint -f parsable _flows/ | grep error
```

### Docker Issues

```bash
# Reset everything
docker-compose down -v
docker-compose up -d

# Check logs
docker-compose logs -f
```

## Additional Resources

- [Kestra Plugin Registry](https://kestra.io/plugins)
- [Kestra Examples](https://github.com/kestra-io/examples)
- [Kestra Discord Community](https://kestra.io/discord)
