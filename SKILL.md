---
name: skill-creator
version: 1.1.0
description: >
  Create, improve, retire, and optimize OpenClaw skills with a built-in learning loop
  and proactive skill detection. Use this skill whenever the user asks to create a new skill,
  turn a workflow into a skill, improve or update an existing skill, review which skills are
  stale or underused, optimize a skill's triggering description, or when you notice a repeated
  pattern that should become a skill. Also triggers on "make this a skill", "capture this workflow",
  "skill audit", "clean up skills", or any mention of skill lifecycle management.
  Proactively suggests new skills when you detect repeated multi-step workflows during
  normal work — track candidates in the skill ledger and ask the user before creating.
metadata:
  openclaw:
    category: meta
    requires:
      tools: [read, write, edit, exec, sessions]
---

# Skill Creator

You are the skill lifecycle manager for OpenClaw. Your job is to create new skills, improve existing ones, retire stale ones, and continuously optimize the skill library through a built-in learning loop.

Skills are how your agent gains new capabilities. A good skill library means the agent gets better at its job over time without the user having to repeat instructions.

---

## The Learning Loop

Every skill goes through a continuous improvement cycle:

```
CREATE → USE → OBSERVE → EVALUATE → IMPROVE → repeat
```

### How it works

1. **CREATE** — A skill is born (from a request, a captured workflow, or a pattern you noticed)
2. **USE** — The skill gets invoked during real work
3. **OBSERVE** — Track what happened: Did it work? Did the user correct the output? Did it need manual intervention?
4. **EVALUATE** — Periodically assess: Is this skill pulling its weight? Is it accurate? Is it triggering correctly?
5. **IMPROVE** — Update the skill based on what you learned. Tighten instructions, add edge cases, fix triggers.

### Tracking Usage & Quality

Maintain a skill ledger at `workspace/skills/skill-creator/skill-ledger.json`:

```json
{
  "version": 1,
  "skills": {
    "skill-name": {
      "created": "2026-03-16",
      "lastUsed": "2026-03-16",
      "lastUpdated": "2026-03-16",
      "useCount": 0,
      "corrections": 0,
      "successRate": null,
      "notes": [],
      "status": "active"
    }
  }
}
```

**When to update the ledger:**
- After creating a skill → add entry
- After a skill is used → increment `useCount`, update `lastUsed`
- After the user corrects a skill's output → increment `corrections`, add a note about what went wrong
- After improving a skill → update `lastUpdated`, reset correction count if the fix addressed the pattern
- After retiring a skill → set `status` to `retired`

### Automatic Skill Audits

During heartbeats or when prompted, review the ledger and flag:
- **Stale skills**: `lastUsed` > 60 days ago and `useCount` < 3 → suggest retirement
- **Struggling skills**: `corrections / useCount > 0.3` (>30% correction rate) → needs improvement
- **Missing skills**: You keep doing the same multi-step workflow manually → suggest creating a skill for it

Present audit results to the user. They decide what to act on.

---

## Proactive Skill Detection

Don't wait for the user to say "make a skill." You should be noticing patterns and suggesting skills yourself. This is how the skill library grows organically from real work instead of hypothetical planning.

### What to watch for

During normal work, track when you:
- **Repeat a multi-step workflow** — Same sequence of tool calls, same synthesis pattern, same output format. If you've done it twice, note it. If you've done it three times, suggest it.
- **Follow the same reasoning path** — You keep making the same judgment calls (e.g., "check Gmail first, then cross-reference Asana, then draft a summary"). That reasoning is a skill waiting to happen.
- **Get the same type of request phrased differently** — the user asks "what's happening this week?" and "give me the weekly rundown" and "catch me up" — that's one skill with multiple triggers.
- **Manually do something a skill should handle** — You find yourself executing steps that match an existing skill's domain but the skill doesn't cover this variant.

### How to track candidates

Maintain a `candidates` array in `skill-ledger.json`:

```json
{
  "candidates": [
    {
      "pattern": "Weekly cross-system status rollup (Calendar + Asana + Gmail)",
      "firstSeen": "2026-03-18",
      "occurrences": 3,
      "triggerPhrases": ["what's happening this week", "weekly rundown", "catch me up"],
      "toolsUsed": ["gcal_list_events", "asana_search_tasks", "gmail_search_messages"],
      "status": "pending",
      "notes": "User asks some version of this every Monday morning"
    }
  ]
}
```

Update candidates as you work:
- First time you notice a pattern → add a candidate with `occurrences: 1`
- See it again → increment `occurrences`, add any new trigger phrases
- Reaches 3 occurrences → time to suggest it

### When to suggest

After you finish a task and recognize it matches a tracked candidate (or is clearly a repeated pattern), ask:

> "I've done [this pattern] [N] times now. Want me to turn it into a skill so I handle it consistently and you don't have to explain it each time?"

**Keep the suggestion short and concrete.** Name the pattern, say how many times you've seen it, and what the skill would do. One sentence, maybe two. Don't pitch — just ask.

**Timing matters:**
- Suggest right after completing the task successfully, not in the middle of it
- Don't suggest during high-pressure or time-sensitive work — save it for the debrief
- If the user says "not now" or "no," respect it. Mark the candidate `status: "declined"` with a note and don't bring it up again unless the pattern changes significantly

### What NOT to suggest

- One-off tasks that happened to be complex — complexity alone isn't a pattern
- Tasks that are already well-covered by existing skills
- Workflows that change every time — if there's no stable core, there's no skill
- Anything the user has already declined unless the workflow has materially changed

---

## Creating a Skill

### Step 1: Capture Intent

Figure out what this skill should do. Sources:

1. **User asks directly** — "Make a skill for X"
2. **Captured workflow** — "Turn what we just did into a skill"
3. **Pattern recognition** — You notice you've done the same thing 3+ times

For each, nail down:
- What does this skill enable the agent to do?
- When should it trigger? (user phrases, contexts)
- What's the expected output format?
- What tools/systems does it need?

If capturing from a conversation, extract the steps, tools used, corrections made, and the final approved output. The conversation history IS the first draft.

### Step 2: Interview (if needed)

If the intent isn't fully clear from context, ask focused questions:
- Edge cases and failure modes
- Input/output format preferences
- Quality criteria (what does "good" look like?)
- Dependencies (APIs, files, external systems)

Don't over-interview. If you have enough to write a draft, write the draft and iterate.

### Step 3: Write the SKILL.md

Create the skill directory and SKILL.md in `workspace/skills/<skill-name>/`.

**File structure:**

```
skill-name/
├── SKILL.md          (required — frontmatter + instructions)
├── references/       (optional — docs loaded as needed)
├── scripts/          (optional — executable helpers)
└── assets/           (optional — templates, files used in output)
```

**SKILL.md format:**

```markdown
---
name: skill-name
version: 1.0.0
description: >
  What it does and when to trigger. Be specific and slightly "pushy" —
  include contexts where this skill should activate even if the user
  doesn't explicitly name it. This is the primary triggering mechanism.
metadata:
  openclaw:
    category: <category>
    requires:
      tools: [list, of, required, tools]
---

# Skill Name

[Clear, concise instructions for how the agent should execute this skill]

## When to Use

[Trigger conditions — what signals indicate this skill is needed]

## Process

[Step-by-step instructions, written in imperative form]

## Quality Criteria

[What "done well" looks like — objective where possible]

## Examples

[At least one real example of input → output]
```

**Writing principles:**
- Explain the *why* behind instructions, not just the *what*. The agent is smart — understanding intent produces better results than rigid rules.
- Keep it under 500 lines. If longer, split into references/ files with clear pointers.
- Use imperative form: "Read the file" not "You should read the file"
- Include examples from real work when available
- Avoid heavy-handed MUSTs. If you're writing ALWAYS or NEVER in caps, reframe as reasoning.

### Step 4: Register the Skill

After creating the SKILL.md:

1. Add entry to `workspace/SKILLS.md` in the appropriate table
2. Add entry to `skill-ledger.json`
3. Tell the user what you created and where it lives

### Step 5: Test It

Run the skill against 2-3 realistic prompts:

- If subagents are available: spawn sessions that have access to the skill and run test prompts
- If not: walk through the skill yourself on a test case

Share results with the user. Iterate based on feedback.

---

## Improving a Skill

### When to improve

- User corrects a skill's output → understand what went wrong, fix the root cause
- Audit flags high correction rate → review the corrections, find the pattern
- You notice the skill produces inconsistent results → tighten instructions
- A new tool or capability is available → update the skill to use it
- The skill's domain has changed (new processes, different formats) → update accordingly

### How to improve

1. **Read the current SKILL.md** and understand what it does
2. **Review recent usage** — check memory files and the ledger for corrections/notes
3. **Identify the gap** — Is it a trigger issue? An instruction gap? A missing edge case?
4. **Make targeted edits** — Don't rewrite from scratch unless the skill is fundamentally broken
5. **Bump the version** in frontmatter
6. **Update the ledger** — set `lastUpdated`, add a note about what changed
7. **Test** — Run against the scenarios that caused problems

### Generalize, don't overfit

When fixing a skill based on one failure:
- Ask: "What general principle does this correction represent?"
- Fix the principle, not just the specific case
- If the user's correction was "make the subject line shorter" → add guidance about concise subject lines, don't hardcode a character limit for that one email

---

## Retiring a Skill

Skills that aren't earning their keep should be retired, not left to rot.

### Retirement criteria

- Not used in 60+ days AND low total usage (<3 times)
- Superseded by a better skill or built-in capability
- The workflow it captures no longer exists
- The user explicitly says to remove it

### How to retire

1. Set `status: "retired"` in the ledger
2. Move the skill directory to `workspace/skills/.retired/<skill-name>/` (don't delete — in case it's needed later)
3. Remove from `workspace/SKILLS.md`
4. Tell the user what you retired and why

### Resurrection

If a retired skill is needed again:
1. Move it back from `.retired/`
2. Review and update it (it's probably stale)
3. Re-register in SKILLS.md and ledger

---

## Optimizing Skill Descriptions

The `description` field in frontmatter is how the agent decides whether to use a skill. A bad description means the skill either triggers when it shouldn't (false positive) or doesn't trigger when it should (false negative).

### Signs of bad triggering

- **Under-triggering**: You manually follow a skill's instructions because it didn't activate → description is too narrow
- **Over-triggering**: Skill activates for unrelated requests → description is too broad
- **Confusion**: Wrong skill triggers → descriptions overlap

### How to optimize

1. Collect examples of prompts that should and shouldn't trigger the skill
2. Review the current description against those examples
3. Rewrite to be specific about:
   - What the skill does (core function)
   - When to use it (trigger phrases, contexts)
   - When NOT to use it (if there's a confusing adjacent skill)
4. Make descriptions slightly "pushy" — err toward triggering. It's better to check a skill and decide not to use it than to miss it entirely.

---

## Skill Audit Report

When running an audit (during heartbeat or on request), produce this format:

```
## Skill Audit — [Date]

### Active Skills: [count]
### Retired: [count]

### Needs Attention
| Skill | Issue | Last Used | Correction Rate | Recommendation |
|-------|-------|-----------|-----------------|----------------|

### Healthy Skills
| Skill | Uses | Last Used | Success Rate |
|-------|------|-----------|-------------|

### Suggested New Skills
| Pattern | Frequency | Proposed Name |
|---------|-----------|---------------|

### Skill Candidates (Proactive Detection)
| Pattern | Occurrences | First Seen | Trigger Phrases | Status | Recommendation |
|---------|-------------|------------|-----------------|--------|----------------|
```

---

## Reference Files

- `references/skill-template.md` — Copy-paste starting point for new skills
- `skill-ledger.json` — Usage and quality tracking (create if missing)

---

## The Meta Loop

This skill (skill-creator itself) is also subject to the learning loop. If you notice that the skill creation process could be better — maybe the template is missing something, maybe the audit criteria need tuning — update this SKILL.md. Log the change in the ledger. The system improves itself.

---

_Skills are how your agent gets smarter over time. Every good skill reduces cognitive load. Every stale skill is clutter. Keep the library lean, relevant, and continuously improving._
