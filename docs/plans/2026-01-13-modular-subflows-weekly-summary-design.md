# Modular Subflows and Weekly Summary - Design Document

**Date:** 2026-01-13
**Status:** Approved
**Related Flows:**
- `cybersecurity_news_briefing` (refactored)
- `weekly_cybersecurity_summary` (new)

## Overview

Refactor the existing daily cybersecurity briefing flow into reusable modular subflows and create a new weekly summary flow that aggregates the past 7 daily reports. This provides maximum code reusability and enables trend analysis across the week.

## Architecture

### Three Core Subflows

1. **`rss_feed_collector`** - Fetches RSS feeds from configured sources
2. **`claude_content_analyzer`** - Uses Claude AI for content analysis
3. **`markdown_report_generator`** - Generates formatted markdown reports

### Two Main Flows

1. **Daily Briefing** (refactored) - Calls all 3 subflows in sequence for daily intelligence
2. **Weekly Summary** (new) - Aggregates 7 daily reports, analyzes trends, generates weekly overview

## Component Design

### Subflow 1: RSS Feed Collector

**Location:** `subflows/rss_feed_collector.yaml`

**Purpose:** Fetch and parse RSS feeds from curated cybersecurity sources

**Inputs:**
- `hours_back` (INT, default: 24) - Time window for article filtering
- `feed_config` (JSON, optional) - Custom feed list, falls back to default curated sources

**Tasks:**
1. Python script task using `feedparser`, `requests`, `python-dateutil`
2. Fetch feeds in parallel from all sources
3. Parse and extract: title, link, summary, publication date, source name
4. Filter articles by time window (published within `hours_back`)
5. Deduplicate based on URL similarity
6. Handle errors gracefully (continue with partial results)

**Outputs:**
- `feeds_data.json` containing:
  - `articles` array with article objects
  - `feed_status` object with health status per feed
  - `total_articles` count
  - `time_range` metadata

**Error Handling:**
- Continue execution if individual feeds fail
- Log failed feeds with error details
- Include feed health status in output

**Default Feed Sources:**
1. Krebs on Security
2. Bleeping Computer
3. The Hacker News
4. CISA Alerts
5. Threatpost
6. Dark Reading
7. Schneier on Security
8. SANS Internet Storm Center

---

### Subflow 2: Claude Content Analyzer

**Location:** `subflows/claude_content_analyzer.yaml`

**Purpose:** Use Claude AI to analyze, categorize, and enhance content

**Inputs:**
- `articles_json` (JSON) - Raw article data or aggregated reports
- `analysis_type` (STRING, default: "daily") - Analysis mode: "daily" or "weekly"
- `prompt_override` (STRING, optional) - Custom analysis prompt

**Tasks:**
1. Load specialized prompt based on `analysis_type`
2. Execute Claude Code Docker container
3. Process content according to analysis type

**Analysis Types:**

**"daily" mode:**
- Filter out low-impact stories and marketing content
- Categorize into: Critical Alerts, Vulnerabilities, Breaches & Incidents, Advisories, Industry News
- Extract key facts: affected systems, severity, recommended actions
- Generate 3-5 sentence executive summary

**"weekly" mode:**
- Analyze 7 daily briefings
- Identify recurring threats and persistent vulnerabilities
- Highlight top critical items from entire week
- Identify trends and patterns (emerging threats, what got patched)
- Consolidate duplicate coverage across days
- Generate executive summary of week's threat landscape

**Outputs:**
- `analyzed_content.json` containing:
  - Categorized articles/items
  - Executive summary
  - Metadata (analysis timestamp, article count, etc.)

**Implementation:**
- Use `nezhar/claude-container:latest` Docker image
- Environment: `CLAUDE_CODE_OAUTH_TOKEN` from Kestra globals
- Structured prompts in heredoc format
- Output pure JSON for downstream processing

---

### Subflow 3: Markdown Report Generator

**Location:** `subflows/markdown_report_generator.yaml`

**Purpose:** Generate formatted markdown reports from analyzed content

**Inputs:**
- `analyzed_content` (JSON) - Categorized content from analyzer
- `report_type` (STRING) - "daily" or "weekly"
- `report_date` (STRING) - Date for filename (YYYY-MM-DD format)

**Tasks:**
1. Python script applying markdown templates
2. Select template based on `report_type`
3. Format content with proper markdown structure
4. Generate appropriate filename

**Report Templates:**

**Daily Report Template:**
```markdown
# Cybersecurity Intelligence Briefing
**Date:** YYYY-MM-DD
**Period:** Last 24 hours
**Sources:** X feeds monitored
**Total Articles Analyzed:** Y

---

## Executive Summary
[3-5 sentence overview]

---

## 🚨 Critical Alerts
[Items requiring immediate attention]

## Vulnerabilities & Patches
[CVEs, security flaws, available fixes]

## Breaches & Incidents
[Attacks, data leaks, compromises]

## Advisories & Warnings
[CISA alerts, vendor notifications]

## Industry News
[Trends, regulations, notable events]

---

## Feed Health Status
[Feed status with ✅/⚠️ indicators]
```

**Weekly Report Template:**
```markdown
# Cybersecurity Weekly Summary
**Week Ending:** YYYY-MM-DD
**Period:** Last 7 days
**Daily Reports Analyzed:** 7

---

## Executive Summary
[Overview of week's threat landscape]

---

## Top Critical Items of the Week
[5-7 most important items across all 7 days]

## Trend Analysis
### Emerging Threats
[New threats that appeared this week]

### Persistent Vulnerabilities
[Issues mentioned multiple times]

### Patches & Mitigations
[What got fixed this week]

## Week-over-Week Comparison
[Notable changes from previous week - future enhancement]

---

## Daily Report Archive
[Links to individual daily reports]
```

**Outputs:**
- `briefing-{date}.md` for daily reports
- `weekly-summary-{date}.md` for weekly reports

**Formatting Guidelines:**
- Minimal emoji use for visual scanning
- Direct links to original sources
- Source and date metadata
- Concise descriptions (2-3 sentences per item)
- Target length: 1500-2500 words (daily), 2500-4000 words (weekly)

---

## Flow Implementations

### Daily Briefing Flow (Refactored)

**Location:** `_flows/homelab/cybersecurity_news_briefing.yaml`

**Changes from current implementation:**
- Extract RSS fetching into subflow call
- Extract Claude analysis into subflow call
- Extract report generation into subflow call
- Keep triggers, inputs, storage, and logging logic

**Task Sequence:**
1. `collect_feeds` - Call `rss_feed_collector` subflow
2. `analyze_content` - Call `claude_content_analyzer` subflow with "daily" mode
3. `generate_report` - Call `markdown_report_generator` subflow with "daily" type
4. `save_report` - Save to namespace files (same as current)
5. `display_report` - Log report to console (same as current)
6. `log_summary` - Display summary (same as current)

**Trigger:** `0 7 * * *` (7 AM daily) - unchanged

**Backwards Compatibility:**
- Report format remains identical
- Namespace file storage path unchanged
- All inputs remain the same
- Execution behavior identical to current implementation

---

### Weekly Summary Flow (New)

**Location:** `_flows/homelab/weekly_cybersecurity_summary.yaml`

**Purpose:** Generate weekly intelligence summary by aggregating past 7 daily reports

**Trigger:** `0 8 * * 1` (8 AM every Monday)
- Runs 1 hour after daily briefing to ensure Monday's report is available

**Task Sequence:**

1. **fetch_daily_reports** - Python script task
   - Load last 7 daily briefing files from namespace storage
   - Date range: Previous Monday through current Monday
   - Combine all 7 markdown reports into structured JSON
   - Handle missing reports gracefully (if a day failed)
   - Output: `weekly_data.json` with all 7 reports

2. **aggregate_analysis** - Call `claude_content_analyzer` subflow
   - Input: Combined data from 7 daily reports
   - analysis_type: "weekly"
   - Output: Aggregated and analyzed content with trends

3. **generate_weekly_report** - Call `markdown_report_generator` subflow
   - Input: Analyzed weekly content
   - report_type: "weekly"
   - report_date: Current Monday's date
   - Output: `weekly-summary-YYYY-MM-DD.md`

4. **save_weekly_report** - Save to namespace files
   - Path: `_files/homelab/weekly-summaries/YYYY-MM-DD.md`
   - Permanent storage with versioning

5. **display_weekly_report** - Log report to console

6. **log_summary** - Display execution summary

**Key Design Decision:**
- Weekly flow does NOT re-fetch RSS feeds
- Works from historical daily reports already generated
- Faster execution and ensures consistency
- Analyzes what was already reported, not raw feeds again

---

## Migration Strategy

**Phase 1: Create Subflows**
1. Create `rss_feed_collector.yaml`
2. Create `claude_content_analyzer.yaml`
3. Create `markdown_report_generator.yaml`
4. Test each subflow independently with manual triggers

**Phase 2: Refactor Daily Flow**
1. Update `cybersecurity_news_briefing.yaml` to use subflows
2. Test daily flow end-to-end
3. Verify report format is identical to previous version
4. Verify namespace storage paths unchanged

**Phase 3: Create Weekly Flow**
1. Implement `weekly_cybersecurity_summary.yaml`
2. Test with existing daily reports
3. Verify weekly aggregation and trend analysis
4. Validate namespace storage for weekly reports

**Phase 4: Validation**
1. Run daily flow for 7 consecutive days
2. Run weekly flow on Monday
3. Compare outputs with expected format
4. Verify all namespace files created correctly

---

## Dependencies

### Python Libraries (Subflows)
- `feedparser` - RSS/Atom parsing
- `requests` - HTTP requests
- `python-dateutil` - Date parsing
- `json` - Data handling
- Standard library (datetime, os, pathlib)

### Docker Images
- `python:3.11-slim` - For Python tasks
- `nezhar/claude-container:latest` - For Claude Code execution

### Kestra Plugins
- `io.kestra.plugin.core.flow.Subflow` - Subflow execution
- `io.kestra.plugin.scripts.python.Script` - Python execution
- `io.kestra.plugin.scripts.shell.Commands` - Shell commands
- `io.kestra.plugin.scripts.runner.docker.Docker` - Docker runtime
- `io.kestra.plugin.core.storage.LocalFiles` - Namespace file handling
- `io.kestra.plugin.core.log.Log` - Logging

### Environment Variables
- `CLAUDE_CODE_OAUTH_TOKEN` - From Kestra global KV store

---

## Benefits

### Code Reusability
- RSS collection logic used by multiple flows
- Claude analysis logic reusable for different analysis types
- Report generation consistent across all flows

### Maintainability
- Single source of truth for each component
- Bug fixes apply to all flows using subflow
- Easier to test individual components

### Extensibility
- Easy to add new report types (monthly, ad-hoc)
- Can create specialized flows (threat intel search, vendor-specific monitoring)
- Subflows can be called from other namespaces

### Consistency
- All reports use same formatting logic
- Consistent error handling across flows
- Unified categorization and analysis approach

---

## Success Criteria

1. All 3 subflows execute successfully in isolation
2. Refactored daily flow produces identical output to current version
3. Weekly flow generates comprehensive weekly summary
4. No breaking changes to namespace storage paths
5. All flows execute within expected timeframes:
   - Daily flow: 5-10 minutes
   - Weekly flow: 3-5 minutes (no RSS fetching)
6. Error handling works correctly (partial failures don't block execution)

---

## Future Enhancements

### Short-term
- Email delivery for weekly summaries
- Slack/Discord webhook notifications
- Configurable feed lists via Kestra KV store

### Medium-term
- Monthly trend analysis flow
- Week-over-week comparison in weekly reports
- Historical report search/query flow

### Long-term
- Machine learning for threat prioritization
- Automated ticket creation for critical alerts
- Integration with SIEM systems
- Custom RSS feed management UI
