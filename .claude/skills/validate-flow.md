---
name: validate-flow
description: Validate Kestra flows for syntax, structure, and best practices
---

# Validate Kestra Flow

Comprehensive validation of Kestra flows to catch issues before deployment.

## Validation Levels

### Level 1: YAML Syntax
Basic YAML syntax validation using yamllint.

### Level 2: Kestra Schema
Validate against Kestra's flow schema and required fields.

### Level 3: Best Practices
Check for common issues and anti-patterns.

### Level 4: Security Review
Scan for security issues and hardcoded secrets.

## Validation Process

When user requests flow validation, execute all levels:

### 1. YAML Syntax Check

```bash
yamllint _flows/namespace/flow_name.yaml
```

Check for:
- Proper indentation (2 spaces)
- No tabs
- Line length (< 120 chars)
- Trailing whitespace
- Proper quoting
- Valid YAML structure

### 2. Required Fields Check

Read the flow file and verify presence of:

**Required:**
- `id`: Flow identifier
- `namespace`: Namespace name
- `tasks`: At least one task

**Recommended:**
- `description`: What the flow does
- `labels`: For organization
- Input `description` for all inputs
- Task `id` for all tasks

### 3. Structural Validation

Check for common structural issues:

**Task Structure:**
```yaml
tasks:
  - id: task_id           # Required: unique identifier
    type: plugin.Type     # Required: valid plugin type
    # type-specific properties
```

**Input Structure:**
```yaml
inputs:
  - id: input_name        # Required
    type: STRING          # Required: valid type
    description: "..."    # Recommended
    required: false       # Optional
    defaults: value       # Optional
```

**Trigger Structure:**
```yaml
triggers:
  - id: trigger_id        # Required
    type: trigger.Type    # Required
    # trigger-specific properties
```

### 4. Best Practices Check

Scan for anti-patterns:

#### 🚨 Critical Issues

1. **Hardcoded Secrets**
   ```yaml
   # BAD
   password: "mysecretpassword"

   # GOOD
   password: "{{ kv('DATABASE_PASSWORD') }}"
   ```

2. **Missing Error Handling**
   ```yaml
   # BAD - no error handling for external call
   - id: api_call
     type: io.kestra.plugin.core.http.Request
     uri: "https://api.example.com"

   # GOOD - with retry and error handling
   - id: api_call
     type: io.kestra.plugin.core.http.Request
     uri: "https://api.example.com"
     retry:
       maxAttempt: 3
       type: constant
       interval: PT30S
   ```

3. **No Description**
   ```yaml
   # BAD - no description
   id: process_data
   namespace: homelab
   tasks: [...]

   # GOOD - clear description
   id: process_data
   namespace: homelab
   description: |
     Process daily data from source system and load to warehouse.
     Runs every night at 2 AM.
   tasks: [...]
   ```

#### ⚠️ Warnings

1. **Long Tasks** - Tasks doing too much (consider splitting)
2. **No Logging** - Missing log statements for debugging
3. **Hardcoded Values** - Values that should be inputs
4. **No Timeout** - Long-running tasks without timeout
5. **Deprecated Plugins** - Using old plugin versions

### 5. Security Scan

Check for security issues:

**Secret Patterns:**
```regex
password|secret|api[_-]?key|token|credential
```

**Unsafe Patterns:**
- SQL injection risks in dynamic queries
- Command injection in shell scripts
- Exposed endpoints without authentication
- Overly permissive permissions

### 6. Namespace Consistency

Verify namespace matches directory:
```
_flows/homelab/my_flow.yaml
         ^               ^
         |               Must have: namespace: homelab
         Namespace directory
```

### 7. Dependencies Check

For flows using plugins, verify:
- Plugin types are valid
- Required plugin properties are present
- Plugin versions are compatible

## Validation Checklist

Create this checklist for each validation:

```markdown
## Validation Results for: flow_name

### ✅ YAML Syntax
- [ ] Valid YAML structure
- [ ] Proper indentation (2 spaces)
- [ ] No trailing whitespace
- [ ] Line length acceptable
- [ ] Proper quoting

### ✅ Required Fields
- [ ] Has 'id' field
- [ ] Has 'namespace' field
- [ ] Has 'tasks' array with at least one task
- [ ] Has 'description' field (recommended)

### ✅ Structure
- [ ] All tasks have unique IDs
- [ ] All tasks have valid types
- [ ] All inputs properly structured
- [ ] All triggers properly structured
- [ ] Proper use of outputs/inputs

### 🔒 Security
- [ ] No hardcoded secrets
- [ ] No exposed credentials
- [ ] Proper use of KV store for secrets
- [ ] No SQL injection risks
- [ ] No command injection risks

### 📋 Best Practices
- [ ] Clear descriptions
- [ ] Appropriate error handling
- [ ] Reasonable task timeouts
- [ ] Logging for debugging
- [ ] Inputs instead of hardcoded values
- [ ] Using subflows for reusable logic

### 🏷️ Namespace
- [ ] Namespace matches directory
- [ ] Namespace exists in project

### Issues Found: X
### Warnings: Y
### Suggestions: Z
```

## Validation Commands

Run these validations:

```bash
# 1. YAML syntax
yamllint _flows/namespace/flow_name.yaml

# 2. Full validation (if available)
./scripts/validate-flows.sh

# 3. Check for secrets (basic grep)
grep -iE 'password.*:.*["\'].*["\']|secret.*:.*["\'].*["\']|api.?key.*:.*["\'].*["\']' \
  _flows/namespace/flow_name.yaml

# 4. Check namespace consistency
grep "^namespace:" _flows/namespace/flow_name.yaml
```

## Common Issues and Fixes

### Issue: Indentation Error
```yaml
# BAD
tasks:
- id: task1
  type: io.kestra.plugin.core.log.Log
   message: "Hello"  # Wrong indentation

# GOOD
tasks:
  - id: task1
    type: io.kestra.plugin.core.log.Log
    message: "Hello"
```

### Issue: Missing Quotes in Jinja
```yaml
# BAD
message: {{ inputs.name }}

# GOOD
message: "{{ inputs.name }}"
```

### Issue: Invalid Task Type
```yaml
# BAD
type: LogMessage  # Not a valid plugin type

# GOOD
type: io.kestra.plugin.core.log.Log
```

### Issue: Hardcoded Secret
```yaml
# BAD
env:
  API_KEY: "sk-1234567890abcdef"

# GOOD
env:
  API_KEY: "{{ kv('API_KEY') }}"
```

## Output Format

Present validation results as:

```markdown
# Validation Report: flow_name

## Summary
✅ YAML Syntax: PASSED
✅ Required Fields: PASSED
⚠️ Best Practices: 2 warnings
🚨 Security: 1 issue found

## Details

### Critical Issues (Must Fix)
1. **Hardcoded Secret (Line 25)**
   - Found: `password: "secret123"`
   - Fix: Use KV store: `password: "{{ kv('DB_PASSWORD') }}"`

### Warnings (Should Fix)
1. **Missing Description (Line 1)**
   - Flow has no description field
   - Add description explaining flow purpose

2. **No Error Handling (Line 15)**
   - HTTP request has no retry configuration
   - Add retry policy for resilience

### Suggestions (Nice to Have)
1. **Add Logging**
   - Add log statements between major steps for debugging

## Recommended Actions
1. Fix critical security issue with hardcoded password
2. Add flow description
3. Add retry logic to HTTP task
4. Add logging statements

## Validation Command Used
\`\`\`bash
yamllint _flows/namespace/flow_name.yaml
\`\`\`
```

## When to Validate

Validate flows:
- Before committing to git
- After making changes
- Before deployment
- When troubleshooting issues
- As part of PR review

## Auto-Validation

This project has pre-commit hooks that auto-validate on commit. To run manually:

```bash
pre-commit run --all-files
```
