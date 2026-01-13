# Claude Code Skills for Kestra Flows

This directory contains custom Claude Code skills to help with Kestra flow development.

## Available Skills

### `/create-flow` - Generate New Flows
Create new Kestra flows with best practices and proper structure.

**Usage:**
```
/create-flow
```

**What it does:**
- Gathers requirements (ID, namespace, description, tasks)
- Researches similar flows for patterns
- Generates properly structured YAML
- Validates syntax and structure
- Creates file in correct location

**Example:**
```
User: /create-flow
Claude: I'll help you create a new Kestra flow. Let me gather the requirements...
        What should be the flow ID?
```

---

### `/validate-flow` - Validate Flows
Comprehensive validation of Kestra flows for syntax, structure, and best practices.

**Usage:**
```
/validate-flow
```

**What it does:**
- Validates YAML syntax
- Checks required fields
- Scans for security issues
- Identifies anti-patterns
- Provides detailed report with fixes

**Example:**
```
User: /validate-flow
Claude: I'll validate your Kestra flow. Which flow should I check?
User: src/homelab/my_flow.yaml
Claude: [Runs validation and provides detailed report]
```

---

### `/create-subflow` - Generate Reusable Subflows
Create reusable subflow components for common patterns.

**Usage:**
```
/create-subflow
```

**What it does:**
- Identifies reusable patterns
- Designs inputs/outputs
- Creates subflow structure
- Provides example usage
- Documents thoroughly

**Example:**
```
User: /create-subflow
Claude: I'll help create a reusable subflow. What pattern should it implement?
User: Send notifications via email and Slack
Claude: [Generates notification subflow with both channels]
```

---

### `/debug-flow` - Debug Flow Issues
Systematic debugging of Kestra flow execution problems.

**Usage:**
```
/debug-flow
```

**What it does:**
- Gathers error information
- Analyzes flow structure
- Identifies root cause
- Suggests fixes
- Provides testing steps

**Example:**
```
User: /debug-flow
Claude: I'll help debug your flow. What's the flow ID and what error are you seeing?
User: homelab.data_processor - getting "Input not found" error
Claude: [Analyzes flow and identifies the issue]
```

---

## Quick Start

To use these skills with Claude Code:

1. **Open your terminal in this project directory**
2. **Start Claude Code:**
   ```bash
   claude
   ```
3. **Use a skill:**
   ```
   /create-flow
   ```

Claude will automatically detect and load the skills from this directory.

## Skill Invocation

You can invoke skills in several ways:

**By command:**
```
/create-flow
/validate-flow
/create-subflow
/debug-flow
```

**By natural language:**
```
"Help me create a new Kestra flow"
"Validate my flow for issues"
"I need to create a reusable subflow"
"Debug this flow that's failing"
```

Claude will automatically select the appropriate skill based on your request.

## Skills Structure

Each skill is a markdown file in `.claude/skills/` with:

```markdown
---
name: skill-name
description: Brief description
---

# Skill Title

Detailed instructions for Claude to follow...
```

## Creating Custom Skills

To add your own skills:

1. Create a new markdown file in `.claude/skills/`
2. Add frontmatter with name and description
3. Write detailed instructions for Claude
4. Skills are automatically loaded by Claude Code

**Example:**
```markdown
---
name: my-custom-skill
description: My custom Kestra workflow skill
---

# My Custom Skill

Instructions for Claude...
```

## Best Practices for Skills

When creating skills:

1. **Be Specific**: Give clear, step-by-step instructions
2. **Include Examples**: Show concrete examples
3. **Add Validation**: Include validation steps
4. **Error Handling**: Cover common error scenarios
5. **Checklists**: Use checklists for consistent execution

## Prompts Directory

The `.claude/prompts/` directory can contain:
- Custom system prompts
- Template prompts for common tasks
- Project-specific context

Currently empty - add your own as needed.

## Tips

### Using Multiple Skills
You can chain skills together:
```
/create-flow
# ... create flow ...
/validate-flow
# ... validate it ...
/debug-flow
# ... if issues found ...
```

### Skill Context
Skills have access to:
- All files in the project
- Git history
- Project structure
- Previous conversation context

### Improving Skills
Skills are living documents. Improve them based on:
- Common issues encountered
- New Kestra features
- Team feedback
- Project evolution

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [Kestra Documentation](https://kestra.io/docs)
- [Kestra Plugins](https://kestra.io/plugins)

## Contributing

Improvements to skills are welcome:
1. Test your changes thoroughly
2. Update this README if adding new skills
3. Document any new patterns discovered
