# Dapper Cluster Kestra Flows

A repository for managing Kestra workflow orchestration flows using infrastructure-as-code principles.

## Overview

This repository contains Kestra flow definitions organized by namespace, following best practices for version control, validation, and CI/CD deployment.

## Project Structure

```
.
├── _flows/              # Kestra flow definitions (organized by namespace)
│   └── homelab/         # Homelab namespace flows
│       └── cybersecurity_news_briefing.yaml
├── subflows/            # Reusable subflow components
├── modules/             # Modular workflow patterns (optional)
├── scripts/             # Helper scripts for development
├── .github/
│   └── workflows/       # CI/CD validation and deployment
├── .pre-commit-config.yaml
├── .yamllint.yaml
└── README.md
```

## Getting Started

### Prerequisites

- Python 3.11+ (for development tools)
- Access to a Kestra instance
- Git

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd dapper-cluster-kestra-flows
   ```

2. **Install development dependencies:**
   ```bash
   pip install pre-commit yamllint
   ```

3. **Set up pre-commit hooks:**
   ```bash
   pre-commit install
   ```

4. **Configure Kestra connection (optional for local validation):**
   Create a `.env` file with your Kestra instance details:
   ```bash
   KESTRA_HOST=https://your-kestra-instance.com
   KESTRA_USER=your-username
   KESTRA_PASSWORD=your-password
   ```

## Development Workflow

### Creating a New Flow

1. Create your flow YAML file in the appropriate namespace directory:
   ```
   _flows/<namespace>/<flow-name>.yaml
   ```

2. Follow Kestra's flow structure:
   ```yaml
   id: flow_id
   namespace: your_namespace

   description: |
     Flow description

   inputs:
     - id: input_name
       type: STRING
       description: "Input description"

   tasks:
     - id: task_name
       type: io.kestra.plugin.core.log.Log
       message: "Hello from Kestra!"
   ```

3. Validate your flow locally:
   ```bash
   yamllint _flows/
   ```

### Using Subflows

For reusable workflow components, create subflows in the `subflows/` directory:

```yaml
id: reusable_task
namespace: subflows

inputs:
  - id: message
    type: STRING

tasks:
  - id: log_message
    type: io.kestra.plugin.core.log.Log
    message: "{{ inputs.message }}"
```

Reference subflows in your main flows:

```yaml
tasks:
  - id: call_subflow
    type: io.kestra.plugin.core.flow.Subflow
    namespace: subflows
    flowId: reusable_task
    inputs:
      message: "Hello from main flow!"
```

## Namespace Organization

Namespaces provide logical grouping and isolation of flows. Current namespaces:

- `homelab`: Home laboratory automation and tools

To add a new namespace:
1. Create a directory under `_flows/<namespace-name>`
2. Add flows with the corresponding namespace in their YAML definition

## CI/CD Pipeline

This repository includes GitHub Actions workflows for:

### Validation (runs on every PR)
- YAML syntax validation
- Kestra flow schema validation
- Linting checks

### Deployment (optional, configure in `.github/workflows/validate.yaml`)
- Automatic deployment to Kestra instance on merge to main
- Requires GitHub secrets:
  - `KESTRA_HOST`: Your Kestra server URL
  - `KESTRA_USER`: API username
  - `KESTRA_PASSWORD`: API password

## Local Development

### Running YAML Validation
```bash
# Lint all YAML files
yamllint .

# Check specific files
yamllint _flows/homelab/cybersecurity_news_briefing.yaml
```

### Testing Flows Locally

You can run a local Kestra instance using Docker:

```bash
docker run --rm -p 8080:8080 kestra/kestra:latest server standalone
```

Access the UI at `http://localhost:8080`

## Best Practices

1. **Version Control**: Always commit flow changes with descriptive messages
2. **Testing**: Test flows in development namespace before promoting to production
3. **Documentation**: Add clear descriptions to flows and complex tasks
4. **Secrets**: Never commit credentials - use Kestra's KV Store or environment variables
5. **Modularity**: Use subflows for reusable patterns
6. **Validation**: Always run pre-commit hooks before pushing

## Common Tasks

### Validate all flows
```bash
yamllint _flows/
```

### Add a new namespace
```bash
mkdir -p _flows/<namespace-name>
```

### Update pre-commit hooks
```bash
pre-commit autoupdate
```

## Claude Code Skills

This repository includes custom Claude Code skills to accelerate Kestra flow development.

### Available Skills

- **`/create-flow`** - Generate new flows with best practices
- **`/validate-flow`** - Validate flows for syntax, structure, and security
- **`/create-subflow`** - Create reusable subflow components
- **`/debug-flow`** - Debug flow execution issues

### Using Skills

Start Claude Code in this directory:
```bash
claude
```

Then use any skill:
```
/create-flow
```

Or just describe what you need:
```
"Help me create a new flow for processing logs"
"Validate my cybersecurity flow"
"Debug the error in my data pipeline"
```

See [`.claude/README.md`](.claude/README.md) for detailed documentation.

## Resources

- [Kestra Documentation](https://kestra.io/docs)
- [Kestra GitHub Actions](https://kestra.io/docs/how-to-guides/github-actions)
- [Flow Components](https://kestra.io/docs/workflow-components/flow)
- [Version Control Best Practices](https://kestra.io/docs/version-control-cicd/git)
- [Namespace Files](https://kestra.io/docs/concepts/namespace-files)

## Troubleshooting

### YAML validation errors
- Check indentation (use 2 spaces, not tabs)
- Verify required flow fields: `id`, `namespace`, `tasks`
- Ensure custom YAML tags are properly formatted

### Flow execution errors
- Check logs in Kestra UI
- Verify input types match expected values
- Ensure required secrets/KV values are configured

## Contributing

1. Create a feature branch
2. Add or modify flows
3. Run validation locally
4. Submit a pull request
5. Wait for CI validation to pass

## License

[Your License Here]
