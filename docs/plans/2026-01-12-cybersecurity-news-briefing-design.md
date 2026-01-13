# Cybersecurity News Briefing - Design Document

**Date:** 2026-01-12
**Status:** Approved
**Flow ID:** `cybersecurity_news_briefing`
**Namespace:** `homelab`

## Overview

A daily automated intelligence briefing system that monitors curated cybersecurity RSS feeds, uses Claude AI to analyze and prioritize content, and generates a structured markdown report with executive summary and categorized findings.

## Architecture

### High-Level Flow
1. **Collection Phase** - Fetch RSS feeds in parallel from multiple sources
2. **Analysis Phase** - Use Claude AI to analyze, filter, and categorize content
3. **Report Generation Phase** - Create structured markdown report
4. **Storage Phase** - Save to Kestra namespace files

### Trigger
- **Schedule:** Daily cron trigger `0 7 * * *` (7 AM)
- **Manual Override:** Available via Kestra UI for on-demand runs

## Component Design

### 1. RSS Feed Collection

**Curated Feed List:**
1. Krebs on Security - `https://krebsonsecurity.com/feed/`
2. Bleeping Computer - `https://www.bleepingcomputer.com/feed/`
3. The Hacker News - `https://feeds.feedburner.com/TheHackersNews`
4. CISA Alerts - `https://www.cisa.gov/cybersecurity-advisories/all.xml`
5. Threatpost - `https://threatpost.com/feed/`
6. Dark Reading - `https://www.darkreading.com/rss.xml`
7. Schneier on Security - `https://www.schneier.com/feed/atom/`
8. SANS Internet Storm Center - `https://isc.sans.edu/rssfeed.xml`

**Implementation:**
- Python script task using `feedparser` library
- Parallel execution for all feeds
- Filter to last 24 hours based on publication date
- Extract: title, link, summary, publication date, source name
- Deduplicate articles using URL similarity
- Output structured JSON for analysis phase

**Error Handling:**
- Continue with partial results if feeds fail
- Log failed feeds
- Include feed health status in final report

### 2. AI Analysis & Processing

**Claude's Analysis Tasks:**

1. **Significance Filtering**
   - Filter out low-impact stories
   - Remove marketing content
   - Eliminate duplicate coverage

2. **Categorization**
   - **Critical Alerts** - Active exploits, zero-days, widespread threats
   - **Vulnerabilities** - CVEs, patches, security flaws
   - **Breaches & Incidents** - Data leaks, ransomware, compromises
   - **Advisories** - CISA/vendor warnings, emerging threats
   - **Industry News** - Regulations, major events, trends

3. **Content Enhancement**
   - Extract key facts (what, who, impact, mitigation)
   - Identify affected systems/vendors
   - Assess severity/urgency
   - Add context for stakeholders

4. **Executive Summary**
   - Generate 3-5 sentence overview
   - Highlight most critical items requiring immediate attention

**Implementation:**
- Use existing Claude Code Docker container (`nezhar/claude-container:latest`)
- Specialized prompt receiving JSON feed data
- Output structured analysis in JSON format

### 3. Report Generation

**Markdown Report Template:**

```markdown
# Cybersecurity Intelligence Briefing
**Date:** YYYY-MM-DD
**Period:** [timestamp range]
**Sources:** 8 feeds monitored

---

## Executive Summary
[3-5 sentence overview of most critical developments]

---

## Critical Alerts 🚨
[Items requiring immediate attention]
- **[Title]** - Source | Date
  - Impact: [affected systems/users]
  - Action: [recommended response]
  - Link: [URL]

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
✅ Krebs on Security (12 items)
✅ Bleeping Computer (18 items)
⚠️  Threatpost (timeout)
...
```

**Formatting Guidelines:**
- Minimal emoji use for visual scanning (🚨 critical, ⚠️ warnings)
- Direct links to original articles
- Source and date metadata for verification
- Concise descriptions (2-3 sentences per item)
- Target length: 1500-2500 words

**Implementation:**
- Python task applying markdown template to Claude's JSON output
- File naming: `briefing-YYYY-MM-DD.md`

### 4. Storage

**Kestra Namespace Files:**
- Path: `_files/homelab/briefings/YYYY-MM-DD.md`
- Permanent storage with versioning
- Accessible via Kestra UI
- Can be referenced by other flows
- Searchable history

**Implementation:**
- Use `io.kestra.plugin.core.storage.LocalFiles` or namespace file task
- Store with date-based naming for easy retrieval
- Maintain permanent archive

## Task Sequence

1. **fetch_rss_feeds** - Python task to collect RSS data in parallel
2. **analyze_content** - Claude Code Docker task for AI analysis
3. **generate_report** - Python task to create markdown report
4. **save_to_namespace** - Store report in Kestra namespace files
5. **log_summary** - Display execution summary

## Dependencies

### Python Libraries
- `feedparser` - RSS/Atom feed parsing
- `requests` - HTTP requests for feed fetching
- `json` - Data handling
- Standard library for date/time, deduplication

### Docker Images
- `nezhar/claude-container:latest` - Claude Code execution

### Kestra Plugins
- `io.kestra.plugin.scripts.python.Commands`
- `io.kestra.plugin.scripts.runner.docker.Docker`
- `io.kestra.plugin.core.storage.*` - Namespace file handling
- `io.kestra.plugin.core.log.Log` - Logging

## Configuration

### Environment Variables
- `CLAUDE_CODE_OAUTH_TOKEN` - From Kestra global KV store

### Inputs (Optional)
- `hours_back` - Time window for feed filtering (default: 24)
- `min_severity` - Minimum severity threshold for filtering

## Success Criteria

1. Flow executes daily without intervention
2. Report generated within 5-10 minutes
3. All or most feeds successfully fetched
4. Report contains actionable intelligence with proper categorization
5. Reports stored reliably in namespace files
6. Failed feeds logged but don't block execution

## Future Enhancements

- Email delivery option
- Slack/Discord webhook notifications
- Trend analysis over time
- Custom feed URL configuration via inputs
- Severity-based alerting
- Historical report comparison
