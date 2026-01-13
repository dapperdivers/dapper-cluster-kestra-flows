---
name: create-subflow
description: Create reusable Kestra subflows for common patterns
---

# Create Kestra Subflow

Generate reusable subflows that can be called from multiple flows.

## What is a Subflow?

A subflow is a standalone flow that can be invoked from other flows, similar to a function in programming. It:
- Accepts inputs
- Performs tasks
- Returns outputs
- Can be reused across multiple parent flows

## When to Create a Subflow

Create a subflow when:
1. **Logic is repeated** across multiple flows
2. **Task sequence is common** (e.g., send notification, transform data)
3. **Testing in isolation** is needed
4. **Team sharing** - providing reusable components to others
5. **Complexity reduction** - breaking large flows into manageable pieces

## Don't Create a Subflow When:
- Logic is used only once
- Task is too simple (single log statement)
- Overhead of passing inputs/outputs is higher than repeating code

## Subflow Creation Process

### 1. Identify Reusable Pattern

Ask the user:
- What tasks should be in the subflow?
- What inputs does it need?
- What outputs should it return?
- Where will it be used?

### 2. Design Inputs and Outputs

**Inputs:** What data flows IN to the subflow
```yaml
inputs:
  - id: source_url
    type: STRING
    description: "URL to fetch data from"
    required: true

  - id: timeout_seconds
    type: INT
    description: "Request timeout"
    defaults: 30
    required: false
```

**Outputs:** What data flows OUT of the subflow
```yaml
tasks:
  - id: process_data
    type: io.kestra.plugin.scripts.python.Script
    script: |
      result = {"status": "success", "count": 42}
      print(result)

# Parent flow can access: outputs.process_data.vars.result
```

### 3. Create Subflow Structure

```yaml
id: subflow_name
namespace: subflows  # Convention: use 'subflows' namespace

description: |
  Clear description of what this subflow does.
  Include:
  - Purpose
  - Expected inputs
  - Output format
  - Example usage

inputs:
  - id: input_1
    type: STRING
    description: "What this input controls"
    required: true

  - id: input_2
    type: INT
    description: "Optional parameter"
    defaults: 10

tasks:
  - id: validate_inputs
    type: io.kestra.plugin.core.log.Log
    message: "Starting with input_1={{ inputs.input_1 }}"

  - id: main_logic
    type: io.kestra.plugin.scripts.shell.Commands
    commands:
      - echo "Processing..."

  - id: output_results
    type: io.kestra.plugin.core.log.Log
    message: "Completed successfully"
```

### 4. Common Subflow Patterns

#### Pattern 1: Data Transformation
```yaml
id: transform_json
namespace: subflows

description: |
  Transform JSON data according to mapping rules.
  Returns transformed JSON object.

inputs:
  - id: input_json
    type: JSON
    description: "Input JSON to transform"

  - id: mapping_rules
    type: JSON
    description: "Transformation rules"

tasks:
  - id: transform
    type: io.kestra.plugin.scripts.python.Script
    script: |
      import json
      input_data = {{ inputs.input_json }}
      rules = {{ inputs.mapping_rules }}
      # transformation logic
      result = transform(input_data, rules)
      print(json.dumps(result))
```

#### Pattern 2: Notification
```yaml
id: send_notification
namespace: subflows

description: |
  Send notification via multiple channels.
  Supports email, Slack, and webhooks.

inputs:
  - id: message
    type: STRING
    description: "Notification message"

  - id: severity
    type: STRING
    description: "Severity level: info, warning, error"
    defaults: "info"

  - id: channels
    type: ARRAY
    description: "Channels to notify: [email, slack, webhook]"
    defaults: ["email"]

tasks:
  - id: send_email
    type: io.kestra.plugin.core.flow.If
    condition: "{{ 'email' in inputs.channels }}"
    then:
      - id: email_task
        type: io.kestra.plugin.notifications.mail.MailSend
        subject: "[{{ inputs.severity }}] Notification"
        htmlTextContent: "{{ inputs.message }}"

  - id: send_slack
    type: io.kestra.plugin.core.flow.If
    condition: "{{ 'slack' in inputs.channels }}"
    then:
      - id: slack_task
        type: io.kestra.plugin.notifications.slack.SlackIncomingWebhook
        payload: |
          {
            "text": "{{ inputs.message }}"
          }
```

#### Pattern 3: Error Handler
```yaml
id: handle_error
namespace: subflows

description: |
  Standard error handling workflow.
  Logs error, sends notification, and optionally retries.

inputs:
  - id: error_message
    type: STRING
    description: "Error details"

  - id: flow_id
    type: STRING
    description: "ID of flow that failed"

  - id: notify
    type: BOOLEAN
    description: "Send notification"
    defaults: true

tasks:
  - id: log_error
    type: io.kestra.plugin.core.log.Log
    level: ERROR
    message: "Error in {{ inputs.flow_id }}: {{ inputs.error_message }}"

  - id: send_alert
    type: io.kestra.plugin.core.flow.If
    condition: "{{ inputs.notify }}"
    then:
      - id: alert
        type: io.kestra.plugin.core.flow.Subflow
        namespace: subflows
        flowId: send_notification
        inputs:
          message: "Flow {{ inputs.flow_id }} failed: {{ inputs.error_message }}"
          severity: "error"
```

#### Pattern 4: API Helper
```yaml
id: api_request_with_retry
namespace: subflows

description: |
  Make HTTP API request with automatic retry and error handling.
  Returns response body and status code.

inputs:
  - id: url
    type: STRING
    description: "API endpoint URL"

  - id: method
    type: STRING
    description: "HTTP method"
    defaults: "GET"

  - id: headers
    type: JSON
    description: "Request headers"
    defaults: {}

  - id: body
    type: STRING
    description: "Request body"
    required: false

  - id: max_retries
    type: INT
    description: "Maximum retry attempts"
    defaults: 3

tasks:
  - id: api_call
    type: io.kestra.plugin.core.http.Request
    uri: "{{ inputs.url }}"
    method: "{{ inputs.method }}"
    headers: "{{ inputs.headers }}"
    body: "{{ inputs.body }}"
    retry:
      maxAttempt: "{{ inputs.max_retries }}"
      type: exponential
      interval: PT10S
      maxInterval: PT60S

  - id: log_response
    type: io.kestra.plugin.core.log.Log
    message: "API call completed: status={{ outputs.api_call.code }}"
```

### 5. Using the Subflow

Parent flows call subflows like this:

```yaml
# In parent flow: src/homelab/my_flow.yaml
tasks:
  - id: call_subflow
    type: io.kestra.plugin.core.flow.Subflow
    namespace: subflows
    flowId: subflow_name
    inputs:
      input_1: "value"
      input_2: 42

  - id: use_subflow_output
    type: io.kestra.plugin.core.log.Log
    message: "Subflow result: {{ outputs.call_subflow.outputs.some_value }}"
```

### 6. Testing Subflows

Test subflows independently:

1. **Create test flow:**
```yaml
id: test_subflow_name
namespace: tests

description: Test for subflow_name

tasks:
  - id: test_case_1
    type: io.kestra.plugin.core.flow.Subflow
    namespace: subflows
    flowId: subflow_name
    inputs:
      input_1: "test_value"
      input_2: 100

  - id: verify_results
    type: io.kestra.plugin.core.log.Log
    message: "Test passed!"
```

2. **Execute in local Kestra:**
```bash
docker-compose up -d
# Navigate to http://localhost:8080
# Execute test flow
```

### 7. Documentation

Document subflows thoroughly:

```yaml
id: subflow_name
namespace: subflows

description: |
  # Purpose
  Brief description of what this subflow does.

  # Inputs
  - input_1: Description and expected format
  - input_2: Description and expected format

  # Outputs
  - output_1: Description and format
  - output_2: Description and format

  # Example Usage
  ```yaml
  - id: example
    type: io.kestra.plugin.core.flow.Subflow
    namespace: subflows
    flowId: subflow_name
    inputs:
      input_1: "example"
      input_2: 42
  ```

  # Notes
  - Special considerations
  - Known limitations
  - Performance characteristics
```

## Subflow Checklist

Before completing a subflow, ensure:

- [ ] ID is descriptive and unique
- [ ] Namespace is `subflows`
- [ ] Description includes purpose, inputs, outputs, and example
- [ ] All inputs have clear descriptions
- [ ] Input types are appropriate
- [ ] Required vs optional inputs are marked correctly
- [ ] Default values make sense
- [ ] Outputs are documented
- [ ] Error handling is included
- [ ] Logging for debugging
- [ ] No hardcoded secrets
- [ ] YAML passes validation
- [ ] Tested independently
- [ ] Example usage provided

## File Location

Create subflows at: `src/subflows/<subflow_name>.yaml`

## Best Practices

1. **Single Responsibility**: Each subflow should do one thing well
2. **Clear Interface**: Inputs and outputs should be obvious
3. **Documentation**: Thorough description with examples
4. **Error Handling**: Handle errors gracefully
5. **Versioning**: Consider versioning for breaking changes (use different IDs)
6. **Testing**: Test subflows independently before integration
7. **Performance**: Be mindful of subflow overhead for simple tasks

## Anti-Patterns to Avoid

❌ **Too Granular**: Don't create subflows for trivial tasks
```yaml
# BAD - too simple for a subflow
id: log_message
inputs:
  - id: msg
    type: STRING
tasks:
  - id: log
    type: io.kestra.plugin.core.log.Log
    message: "{{ inputs.msg }}"
```

❌ **Too Much Logic**: Subflows shouldn't be mini-applications
```yaml
# BAD - doing too much, split into multiple subflows
id: do_everything
inputs: [...]
tasks:
  - fetch_data
  - transform_data
  - validate_data
  - load_to_db
  - send_notifications
  - generate_reports
  - cleanup
```

❌ **Tight Coupling**: Don't make subflows dependent on specific parent flows
```yaml
# BAD - assumes parent flow structure
inputs:
  - id: parent_output_task_id
    type: STRING
# Then accesses parent's specific tasks
```

## Output

Present the subflow design to the user:
1. Show the complete subflow YAML
2. Show example usage in a parent flow
3. Ask for approval before creating file
4. Create in `src/subflows/` directory
