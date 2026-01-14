# Agent Container Migration Design

**Date:** 2026-01-13
**Status:** Approved for Implementation

## Overview

Replace the CLAUDE.md workspace pattern with a pre-built agent container approach for cybersecurity intelligence analysis. The new agent container (`dapperdivers/cybersecurity_news_agent`) includes built-in skills, MCP servers, and agent configurations.

## Current Architecture

**Flow:** RSS Collector → Claude Analyzer (CLAUDE.md) → Markdown Generator

- `rss_feed_collector.yaml`: Fetches RSS feeds from multiple sources
- `claude_content_analyzer.yaml`: Uses CLAUDE.md instructions to analyze content
- `markdown_report_generator.yaml`: Generates formatted markdown reports

## New Architecture

**Flow:** Agent (fetches + analyzes) → Markdown Generator

- Agent container handles both RSS fetching and analysis internally
- Removes need for separate RSS collector
- Removes CLAUDE.md workspace pattern

## Key Benefits

1. **Version-controlled logic:** Analysis logic lives in the agent repository, not YAML heredocs
2. **Built-in capabilities:** Agent includes MCP servers (RSS fetcher, text analyzer) and pre-configured skills
3. **Simplified flow:** Fewer steps, less data passing between tasks
4. **Same output format:** Agent produces identical JSON schema as current implementation

## Technical Changes

### 1. `claude_content_analyzer.yaml` Subflow

**Inputs (before):**
- `content_data` (JSON): Content to analyze
- `analysis_type` (STRING): 'daily' or 'weekly'
- `prompt_override` (STRING, optional): Custom prompt

**Inputs (after):**
- `analysis_type` (STRING): 'daily' or 'weekly'

**Docker image:**
- Old: `nezhar/claude-container:latest`
- New: `ghcr.io/dapperdivers/cybersecurity_news_agent:latest`

**Command structure:**
```bash
# No input staging - agent fetches its own feeds
claude --dangerously-skip-permissions --agent news-aggregator "use the security-intelligence-analysis skill to create a daily briefing"

# Copy agent output to Kestra expected location
if [ -f /app/outputs/daily-brief-*.json ]; then
    cp /app/outputs/daily-brief-*.json analyzed_content.json
else
    echo '{"error": "Agent did not create the output file"}' > analyzed_content.json
fi

# Debug output
echo "=== Analysis Output Debug ==="
ls -lh analyzed_content.json
head -c 500 analyzed_content.json
echo "=== End Debug ==="
```

**Environment variables:**
- `CLAUDE_CODE_OAUTH_TOKEN` (from globals, unchanged)

**Important notes:**
- Uses `--dangerously-skip-permissions` to avoid interactive permission prompts in CI/CD
- Container runs as `agent` user (no user override needed, entrypoint handles permissions)
- RSS feeds configured in container at `/app/mcp-servers/rss_fetcher/config/default_feeds.json`

### 2. `daily_cybersecurity_news_briefing.yaml` Main Flow

**Changes:**
- Remove `collect_feeds` task entirely
- Remove `feed_status` parameter when calling `generate_report`
- Update task numbering/naming

**New task flow:**
```yaml
tasks:
  - id: analyze_content  # Was step 2, now step 1
    type: io.kestra.plugin.core.flow.Subflow
    namespace: subflows
    flowId: claude_content_analyzer
    inputs:
      analysis_type: "daily"

  - id: generate_report  # Was step 3, now step 2
    type: io.kestra.plugin.core.flow.Subflow
    namespace: subflows
    flowId: markdown_report_generator
    inputs:
      analyzed_content: "{{ outputs.analyze_content.outputs.analyzed_content }}"
      report_type: "daily"
      report_date: "{{ execution.startDate | date('yyyy-MM-dd') }}"
      # feed_status removed
```

### 3. `markdown_report_generator.yaml` Subflow

**Changes:**
- Remove `feed_status` input definition
- Remove any feed_status references in report template

## Output Schema

Agent produces identical JSON structure to current implementation:

```json
{
  "executive_summary": "...",
  "categories": {
    "critical_alerts": [...],
    "vulnerabilities": [...],
    "breaches_incidents": [...],
    "advisories": [...],
    "industry_news": [...]
  },
  "metadata": {
    "total_articles": 0,
    "analyzed_count": 0,
    "timestamp": "..."
  }
}
```

Each category item includes: `title`, `source`, `date`, `summary`, `impact`, `affected_systems`, `severity`, `recommended_actions`, `link`.

## Error Handling

1. **Agent execution failures:** Check if output file exists, generate error JSON if missing
2. **File pattern matching:** Use `daily-brief-*.json` glob to handle dynamic dates
3. **Debug output:** Maintain existing debug logs for troubleshooting

## Out of Scope

- **Weekly analysis:** `weekly_cybersecurity_summary.yaml` remains unchanged for now
- The `analysis_type: weekly` parameter exists but won't function with the new agent yet
- Future work: Adapt agent for weekly analysis or keep CLAUDE.md pattern for weekly only

## Testing Plan

1. Test `claude_content_analyzer` subflow independently
2. Run `daily_cybersecurity_news_briefing` end-to-end
3. Verify markdown report generates correctly
4. Validate agent fetches feeds and produces expected JSON

## Migration Strategy

Direct replacement - no rollback plan needed since this is development environment. The old pattern can be restored from git history if needed.

## References

- Agent repository: https://github.com/dapperdivers/cybersecurity_news_agent
- Example agent output: `/home/derek/projects/agents/cybersecurity_news_agent/outputs/daily-brief-2026-01-13.json`
