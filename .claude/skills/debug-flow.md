---
name: debug-flow
description: Debug Kestra flows and troubleshoot execution issues
---

# Debug Kestra Flow

Systematic approach to debugging Kestra flow execution issues.

## When to Use This Skill

Use when flows:
- Fail during execution
- Produce unexpected results
- Have performance issues
- Don't trigger as expected
- Have dependency problems

## Debugging Process

### 1. Gather Information

Ask the user:
- **What's the flow ID and namespace?**
- **What's the error message?** (if any)
- **When does it fail?** (which task, what stage)
- **What's the expected behavior?**
- **Does it work locally?** (in docker-compose)
- **Recent changes?** (what was modified)

### 2. Read the Flow

First, read the flow file to understand its structure:
```bash
cat src/namespace/flow_id.yaml
```

Understand:
- Flow structure and task sequence
- Task dependencies
- Inputs and their usage
- External dependencies (APIs, databases, etc.)

### 3. Check YAML Syntax

Run validation first:
```bash
yamllint src/namespace/flow_id.yaml
```

Common YAML issues:
- **Indentation errors**: Must be 2 spaces, no tabs
- **Missing quotes**: Jinja templates need quotes: `"{{ var }}"`
- **Incorrect nesting**: Check task structure
- **Invalid characters**: Special chars in unquoted strings

### 4. Validate Kestra Structure

Check required fields:
```yaml
id: flow_id          # ✓ Present?
namespace: namespace # ✓ Present?
tasks:               # ✓ At least one task?
  - id: task_id      # ✓ All tasks have IDs?
    type: plugin     # ✓ Valid plugin type?
```

### 5. Common Error Patterns

#### Error: "Task not found" or "Unknown task ID"

**Cause**: Referenced task doesn't exist or wrong ID
```yaml
# BAD
tasks:
  - id: task1
    type: io.kestra.plugin.core.log.Log
    message: "{{ outputs.task_2.message }}"  # task_2 doesn't exist!
```

**Fix**: Check task IDs match references
```yaml
# GOOD
tasks:
  - id: task1
    type: io.kestra.plugin.core.log.Log
    message: "First"

  - id: task2
    type: io.kestra.plugin.core.log.Log
    message: "{{ outputs.task1.vars.something }}"
```

#### Error: "Input not found" or "Variable not found"

**Cause**: Referenced input doesn't exist
```yaml
# BAD
inputs:
  - id: name
    type: STRING

tasks:
  - id: task1
    message: "{{ inputs.username }}"  # Should be 'name'!
```

**Fix**: Match input references to declared inputs
```yaml
# GOOD
inputs:
  - id: name
    type: STRING

tasks:
  - id: task1
    message: "{{ inputs.name }}"
```

#### Error: "Invalid template" or "Jinja2 error"

**Cause**: Syntax error in Jinja template
```yaml
# BAD - missing closing braces
message: "Hello {{ inputs.name }"

# BAD - missing quotes
message: {{ inputs.name }}

# BAD - wrong filter
message: "{{ inputs.name | invalid_filter }}"
```

**Fix**: Proper Jinja syntax
```yaml
# GOOD
message: "Hello {{ inputs.name }}"
message: "{{ inputs.name | upper }}"
message: "{{ inputs.date | date('yyyy-MM-dd') }}"
```

#### Error: "Plugin not found" or "Unknown plugin type"

**Cause**: Invalid plugin type or missing plugin
```yaml
# BAD - invalid plugin type
type: io.kestra.plugin.DoSomething  # Doesn't exist!
```

**Fix**: Use valid plugin types
```yaml
# GOOD - valid plugin types
type: io.kestra.plugin.core.log.Log
type: io.kestra.plugin.scripts.shell.Commands
type: io.kestra.plugin.core.http.Request
```

**Reference**: Check [Kestra Plugins](https://kestra.io/plugins)

#### Error: "Docker image pull failed"

**Cause**: Invalid docker image or network issue
```yaml
# BAD
taskRunner:
  type: io.kestra.plugin.scripts.runner.docker.Docker
  image: nonexistent/image:latest  # Doesn't exist!
```

**Fix**: Use valid, accessible images
```yaml
# GOOD
taskRunner:
  type: io.kestra.plugin.scripts.runner.docker.Docker
  image: python:3.11
  pullPolicy: IF_NOT_PRESENT  # Use cached if available
```

#### Error: "Secret not found" or "KV key not found"

**Cause**: Referenced secret doesn't exist in KV store
```yaml
# Flow references secret
env:
  API_KEY: "{{ kv('API_KEY') }}"  # API_KEY not in KV store!
```

**Fix**: Ensure secrets are in KV store
- Check Kestra UI → KV Store
- Add missing secrets
- Verify namespace access

#### Error: "Output file not found"

**Cause**: File specified in outputFiles doesn't exist
```yaml
# BAD
tasks:
  - id: generate
    type: io.kestra.plugin.scripts.shell.Commands
    commands:
      - echo "hello" > /tmp/output.txt  # Wrong path!
    outputFiles:
      - output.txt  # Looking in working directory!
```

**Fix**: Match paths correctly
```yaml
# GOOD
tasks:
  - id: generate
    type: io.kestra.plugin.scripts.shell.Commands
    commands:
      - echo "hello" > output.txt  # Creates in working dir
    outputFiles:
      - output.txt  # Matches!
```

### 6. Add Debug Logging

Insert log tasks to trace execution:

```yaml
tasks:
  - id: debug_inputs
    type: io.kestra.plugin.core.log.Log
    message: |
      DEBUG - Starting flow
      Input 1: {{ inputs.input1 }}
      Input 2: {{ inputs.input2 }}

  - id: main_task
    type: io.kestra.plugin.scripts.python.Script
    script: |
      print("Processing...")

  - id: debug_outputs
    type: io.kestra.plugin.core.log.Log
    message: |
      DEBUG - Task completed
      Output: {{ outputs.main_task.vars }}
```

### 7. Check Task Dependencies

Ensure tasks run in correct order:

```yaml
# If task2 needs task1's output, task1 must complete first
tasks:
  - id: task1
    type: io.kestra.plugin.core.log.Log
    message: "First"

  - id: task2
    type: io.kestra.plugin.core.log.Log
    message: "Second - using {{ outputs.task1 }}"
    # task2 implicitly waits for task1
```

For explicit dependencies:
```yaml
- id: task2
  type: io.kestra.plugin.core.log.Log
  message: "Depends on task1"
  dependsOn:
    - task1  # Explicit dependency
```

### 8. Test Locally

Run the flow in local Kestra:

```bash
# 1. Start local instance
docker-compose up -d

# 2. Access UI
open http://localhost:8080

# 3. Create/update flow in UI
# Copy flow YAML into UI editor

# 4. Execute with test inputs
# Use "Execute" button

# 5. Check execution logs
# View logs for each task
# Look for error messages
# Check output values

# 6. Stop when done
docker-compose down
```

### 9. Isolation Testing

Test problematic task in isolation:

```yaml
id: test_problematic_task
namespace: tests

description: Isolated test for debugging

inputs:
  - id: test_input
    type: STRING
    defaults: "test_value"

tasks:
  # Copy the problematic task here
  - id: isolated_task
    type: io.kestra.plugin.scripts.python.Script
    script: |
      # The script that's failing
      print("Testing...")

  - id: show_output
    type: io.kestra.plugin.core.log.Log
    message: "Output: {{ outputs.isolated_task }}"
```

### 10. Check External Dependencies

For tasks calling external services:

**API Calls:**
```yaml
# Add debug info
- id: api_call
  type: io.kestra.plugin.core.http.Request
  uri: "{{ inputs.api_url }}"
  method: GET

- id: debug_response
  type: io.kestra.plugin.core.log.Log
  message: |
    Status: {{ outputs.api_call.code }}
    Body: {{ outputs.api_call.body }}
```

**Database Connections:**
- Verify connection string
- Check credentials in KV store
- Test network connectivity
- Confirm permissions

**File Access:**
- Check file paths are absolute or relative to working directory
- Verify file permissions
- Ensure files are created before being read

### 11. Performance Debugging

For slow flows:

**Add timestamps:**
```yaml
tasks:
  - id: start_time
    type: io.kestra.plugin.core.log.Log
    message: "Start: {{ now() }}"

  - id: slow_task
    type: io.kestra.plugin.scripts.python.Script
    script: |
      # slow operation

  - id: end_time
    type: io.kestra.plugin.core.log.Log
    message: "End: {{ now() }}"
```

**Check:**
- Docker image size (large images = slow pulls)
- Data volume (processing large files)
- Network latency (external API calls)
- Resource limits (CPU, memory constraints)

### 12. Trigger Debugging

If flow doesn't trigger as expected:

**Schedule triggers:**
```yaml
triggers:
  - id: schedule
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 0 * * *"  # Verify cron syntax!

# Test cron: https://crontab.guru
```

**Webhook triggers:**
- Check webhook URL is accessible
- Verify webhook secret if configured
- Test with curl/Postman
- Check request payload format

**Event triggers:**
- Verify event source is configured
- Check event payload matches conditions
- Ensure flow is enabled

## Debugging Checklist

```markdown
## Debug Checklist for: flow_id

### Initial Checks
- [ ] YAML syntax is valid (yamllint)
- [ ] All required fields present (id, namespace, tasks)
- [ ] All task IDs are unique
- [ ] All referenced tasks exist

### Input/Output Issues
- [ ] Input declarations match usage
- [ ] Jinja templates have proper syntax
- [ ] Quotes around template expressions
- [ ] Output references are correct

### External Dependencies
- [ ] API endpoints are accessible
- [ ] Secrets exist in KV store
- [ ] Docker images are valid and accessible
- [ ] Database connections work
- [ ] File paths are correct

### Execution Flow
- [ ] Task order is correct
- [ ] Dependencies are explicit if needed
- [ ] No circular dependencies
- [ ] Error handling is in place

### Testing
- [ ] Flow passes local validation
- [ ] Flow executes locally without errors
- [ ] All tasks complete successfully
- [ ] Outputs match expectations
```

## Debug Output Format

Present findings as:

```markdown
# Debug Report: flow_id

## Issue Summary
Brief description of the problem

## Root Cause
The specific cause of the issue

## Evidence
```yaml
# Problematic code (line X-Y)
tasks:
  - id: failing_task
    message: "{{ inputs.wrong_name }}"  # ← Input 'wrong_name' doesn't exist
```

## Fix
```yaml
# Corrected code
tasks:
  - id: failing_task
    message: "{{ inputs.correct_name }}"  # ✓ Fixed
```

## Testing
Steps to verify the fix works

## Prevention
How to avoid this issue in the future
```

## Common Solutions Quick Reference

| Error Type | Common Cause | Quick Fix |
|------------|--------------|-----------|
| YAML Syntax | Wrong indentation | Use 2 spaces, no tabs |
| Template Error | Missing quotes | Add quotes: `"{{ var }}"` |
| Task Not Found | Wrong task ID | Check task ID spelling |
| Input Not Found | Wrong input name | Match input declaration |
| Plugin Not Found | Invalid type | Check plugin docs |
| Secret Not Found | Missing KV entry | Add to KV store |
| File Not Found | Wrong path | Check working directory |
| Docker Pull Failed | Bad image name | Use valid image |
| Trigger Not Firing | Wrong cron syntax | Test at crontab.guru |
| Timeout | Long operation | Add timeout/optimize |

## Preventive Measures

After fixing:
1. Add validation to prevent recurrence
2. Add logging for better debugging
3. Document gotchas in flow description
4. Add error handling
5. Create test flow for regression testing
