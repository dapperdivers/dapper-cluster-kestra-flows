---
name: create-flow
description: Generate a new Kestra flow with best practices and proper structure
---

# Create Kestra Flow

Generate a new Kestra flow following best practices and project conventions.

## Process

When the user requests a new Kestra flow, follow this systematic approach:

### 1. Gather Requirements

Ask the user for:
- **Flow ID**: Unique identifier (lowercase, underscores)
- **Namespace**: Which namespace (homelab, production, etc.)
- **Description**: What does this flow do?
- **Task Types**: What operations are needed? (scripts, API calls, data processing, etc.)
- **Inputs**: What parameters should be configurable?
- **Scheduling**: Should it run on a schedule or be triggered?

### 2. Research Similar Flows

Before creating, check existing flows for patterns:
```bash
# Look for similar flows
find _flows -name "*.yaml" | head -5
```

Read similar flows to understand project conventions.

### 3. Generate Flow Structure

Create the flow file with this structure:

```yaml
id: flow_id
namespace: namespace_name

description: |
  Clear description of what this flow does.
  Include purpose, expected outcomes, and any important notes.

# Optional: Labels for organization
labels:
  environment: development
  team: platform

# Optional: Inputs for configurability
inputs:
  - id: parameter_name
    type: STRING  # STRING, INT, FLOAT, BOOLEAN, DATETIME, DATE, TIME, DURATION, FILE, JSON
    description: "What this parameter controls"
    required: false
    defaults: "default_value"

# Optional: Triggers
triggers:
  - id: schedule_trigger
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 0 * * *"  # Daily at midnight

# Required: Tasks
tasks:
  - id: first_task
    type: io.kestra.plugin.core.log.Log
    message: "Starting flow execution"

  # Add more tasks based on requirements
```

### 4. Task Type Guidelines

Choose appropriate task types based on requirements:

**Shell Commands:**
```yaml
- id: run_script
  type: io.kestra.plugin.scripts.shell.Commands
  taskRunner:
    type: io.kestra.plugin.scripts.runner.docker.Docker
    image: ubuntu:latest
  commands:
    - echo "Hello World"
```

**Python Scripts:**
```yaml
- id: python_task
  type: io.kestra.plugin.scripts.python.Script
  script: |
    print("Python code here")
```

**HTTP API Calls:**
```yaml
- id: api_call
  type: io.kestra.plugin.core.http.Request
  uri: "https://api.example.com/endpoint"
  method: GET
```

**Conditional Logic:**
```yaml
- id: conditional_task
  type: io.kestra.plugin.core.flow.If
  condition: "{{ inputs.environment == 'production' }}"
  then:
    - id: production_task
      type: io.kestra.plugin.core.log.Log
      message: "Running in production"
```

**Parallel Execution:**
```yaml
- id: parallel_tasks
  type: io.kestra.plugin.core.flow.Parallel
  tasks:
    - id: task1
      type: io.kestra.plugin.core.log.Log
      message: "Task 1"
    - id: task2
      type: io.kestra.plugin.core.log.Log
      message: "Task 2"
```

### 5. Best Practices

Apply these conventions:

1. **Naming**: Use lowercase with underscores (snake_case)
2. **Description**: Always include clear descriptions
3. **Error Handling**: Add error handling for external calls
4. **Logging**: Log important steps for debugging
5. **Secrets**: Never hardcode secrets, use KV store: `{{ kv('SECRET_NAME') }}`
6. **Outputs**: Capture important outputs for downstream tasks
7. **Modularity**: If tasks repeat, consider creating a subflow

### 6. Validation

After creating the flow:

1. **Validate YAML syntax:**
   ```bash
   yamllint _flows/namespace/flow_id.yaml
   ```

2. **Check structure:**
   - Required fields: id, namespace, tasks
   - Proper indentation (2 spaces)
   - Valid task types
   - No hardcoded secrets

3. **Test locally:**
   - Copy to local Kestra instance (docker-compose up -d)
   - Execute with test inputs
   - Verify outputs and logs

### 7. Documentation

Add inline comments for complex logic:
```yaml
tasks:
  # This task processes data from the API and transforms it
  # Output format: JSON with keys [id, name, status]
  - id: transform_data
    type: io.kestra.plugin.scripts.python.Script
    script: |
      # transformation logic
```

Update README.md if introducing new patterns or namespaces.

### 8. Create the File

Write the flow to: `_flows/<namespace>/<flow_id>.yaml`

## Example Complete Flow

```yaml
id: daily_report_generator
namespace: homelab

description: |
  Generate daily report from system metrics and send via email.
  Runs every day at 8 AM.

labels:
  category: reporting
  frequency: daily

inputs:
  - id: recipient_email
    type: STRING
    description: "Email address to send report"
    defaults: "admin@example.com"

triggers:
  - id: daily_schedule
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 8 * * *"

tasks:
  - id: collect_metrics
    type: io.kestra.plugin.scripts.shell.Commands
    taskRunner:
      type: io.kestra.plugin.scripts.runner.docker.Docker
      image: ubuntu:latest
    commands:
      - echo "Collecting metrics..."
      - date > report.txt
    outputFiles:
      - report.txt

  - id: generate_report
    type: io.kestra.plugin.scripts.python.Script
    script: |
      import json
      report = {
        "date": "{{ now() }}",
        "metrics": "{{ outputs.collect_metrics.outputFiles['report.txt'] }}"
      }
      print(json.dumps(report))

  - id: send_email
    type: io.kestra.plugin.notifications.mail.MailSend
    from: "noreply@example.com"
    to: "{{ inputs.recipient_email }}"
    subject: "Daily Report - {{ now() }}"
    htmlTextContent: |
      <h1>Daily Report</h1>
      <pre>{{ outputs.generate_report.vars.report }}</pre>
```

## Checklist

Before completing, ensure:
- [ ] Flow ID is unique and descriptive
- [ ] Namespace exists in _flows/ directory
- [ ] Description is clear and complete
- [ ] All required inputs are documented
- [ ] Task types are appropriate for requirements
- [ ] No hardcoded secrets or credentials
- [ ] YAML passes yamllint validation
- [ ] Flow tested locally (if possible)
- [ ] Complex logic has comments

## Output

Present the generated flow to the user and ask:
1. Does this meet your requirements?
2. Should I create the file?
3. Any modifications needed?

Only write the file after user approval.
