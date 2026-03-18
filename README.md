# OpenClaw Skill Creator

A meta-skill that gives your OpenClaw agent the ability to autonomously create, improve, retire, and optimize its own skills — with a built-in learning loop and proactive skill detection that makes the agent smarter over time.

## What it does

| Capability | Description |
|------------|-------------|
| **Create skills** | Captures workflows into reusable SKILL.md files from user requests, conversations, or detected patterns |
| **Proactive detection** | Tracks repeated workflows as candidates and suggests new skills when patterns emerge (3+ occurrences) |
| **Improve skills** | Tracks corrections and quality, then iteratively improves underperforming skills |
| **Retire skills** | Flags stale/unused skills and archives them cleanly |
| **Audit skills** | Runs periodic health checks on the entire skill library, including candidate review |
| **Optimize triggers** | Tunes skill descriptions so they activate at the right time |

### The Learning Loop

```
CREATE → USE → OBSERVE → EVALUATE → IMPROVE → repeat
```

Every skill is tracked in a **skill ledger** (`skill-ledger.json`) that records usage count, correction rate, last used date, and notes. The agent uses this data to:

- Flag skills with >30% correction rate for improvement
- Suggest retirement for skills unused in 60+ days with <3 total uses
- Detect repeated manual workflows that should become skills
- Continuously refine skill instructions based on real feedback

## Install

### Quick install

```bash
git clone https://github.com/ajdavis21/openclaw-skill-creator.git
cd openclaw-skill-creator
./install.sh
```

The installer will:
1. Detect your OpenClaw workspace (from `~/.openclaw/openclaw.json` or `OPENCLAW_WORKSPACE` env var)
2. Copy the skill into `workspace/skills/skill-creator/`
3. Install the audit circuit into `workspace/CIRCUITS/`
4. Register the skill in your `SKILLS.md`
5. Scan existing skills into the ledger for tracking

### Manual install

If you prefer to do it yourself:

```bash
# Copy into your skills directory
cp -r . ~/.openclaw/workspace/skills/skill-creator/

# Copy the audit circuit
cp circuits/audit-skills.md ~/.openclaw/workspace/CIRCUITS/

# Create the retired skills archive
mkdir -p ~/.openclaw/workspace/skills/.retired/

# Add to your SKILLS.md table (adjust path as needed)
echo "| skill-creator | v1.1.0 — Create, improve, retire, and optimize skills with learning loop + proactive detection | workspace/skills/ | ✅ Active |"
```

### Custom workspace path

If your workspace isn't at the default location:

```bash
OPENCLAW_WORKSPACE=/path/to/your/workspace ./install.sh
```

## Usage

Once installed, your agent responds to natural language:

| Say this | Agent does |
|----------|-----------|
| "Make a skill for weekly email summaries" | Interviews you, drafts SKILL.md, tests it, registers it |
| "Turn what we just did into a skill" | Captures the conversation workflow as a reusable skill |
| "The invoice skill keeps getting the date format wrong" | Logs correction, identifies root cause, improves the skill |
| "Run a skill audit" | Reviews all skills, flags stale/struggling ones, suggests new ones |
| "Retire the old reporting skill" | Archives it to `.retired/`, removes from index |
| "Why didn't the email skill trigger?" | Analyzes the description, optimizes trigger phrasing |

## File structure

```
skill-creator/
├── SKILL.md                        # Main skill instructions
├── skill-ledger.json               # Usage & quality tracking
├── install.sh                      # Installer script
├── references/
│   └── skill-template.md           # Copy-paste template for new skills
└── circuits/
    └── audit-skills.md             # Periodic audit circuit (heartbeat-driven)
```

## Skill ledger schema

```json
{
  "version": 1,
  "skills": {
    "skill-name": {
      "created": "2026-03-16",
      "lastUsed": "2026-03-16",
      "lastUpdated": "2026-03-16",
      "useCount": 12,
      "corrections": 2,
      "successRate": 0.83,
      "notes": ["Fixed date format issue in v1.1"],
      "status": "active"
    }
  },
  "candidates": [
    {
      "pattern": "Weekly cross-system status rollup",
      "firstSeen": "2026-03-18",
      "occurrences": 3,
      "triggerPhrases": ["weekly rundown", "catch me up"],
      "toolsUsed": ["gcal_list_events", "asana_search_tasks"],
      "status": "pending",
      "notes": "User asks some version of this every Monday"
    }
  ],
  "audit": {
    "lastAudit": "2026-03-16",
    "auditIntervalDays": 14
  }
}
```

## SKILL.md format

Skills created by this tool follow the OpenClaw SKILL.md convention:

```yaml
---
name: skill-name
version: 1.0.0
description: >
  What it does and when to trigger.
metadata:
  openclaw:
    category: ops|comms|data|dev|meta|finance|content
    requires:
      tools: [required, tools]
---
```

See `references/skill-template.md` for a full template.

## Configuration

### Audit frequency

Edit `skill-ledger.json`:

```json
{
  "audit": {
    "auditIntervalDays": 14
  }
}
```

### Retirement thresholds

Defaults (configured in SKILL.md — edit to taste):
- **Stale**: >60 days unused AND <3 total uses
- **Struggling**: >30% correction rate

### Circuits

The `audit-skills` circuit integrates with OpenClaw's heartbeat system. If your agent uses circuits (`workspace/CIRCUITS/`), the audit runs automatically. If not, just ask your agent to "run a skill audit" anytime.

## How it compares to Anthropic's skill-creator

| | Anthropic | OpenClaw |
|-|-----------|----------|
| **Eval model** | Heavy — JSON assertions, grader subagents, benchmark viewers | Lightweight — real-world usage tracking + user corrections |
| **Lifecycle** | Create and ship | Continuous loop: create → use → observe → evaluate → improve |
| **Retirement** | None | Auto-flags stale skills, archives to `.retired/` |
| **Usage tracking** | None | Ledger with use count, correction rate, success rate |
| **Self-improvement** | No | Yes — skill-creator tracks and improves itself |
| **Environment** | Claude Code / Claude.ai | OpenClaw agents (any deployment) |

## Requirements

- OpenClaw agent with a workspace directory
- Agent tools: `read`, `write`, `edit`, `exec` (minimum)
- `sessions` tool (optional — enables parallel skill testing with subagents)
- Python 3 (for the install script's existing-skill scanner)

## License

MIT
