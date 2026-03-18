# Circuit: audit-skills

**Trigger:** During heartbeat (every 14 days), or when the user asks for a skill audit, or when you notice repeated manual workflows that should be skills.

**Systems:** File system (workspace/skills/), skill-ledger.json, SKILLS.md

## Steps

1. [AFFERENT] Read `workspace/skills/skill-creator/skill-ledger.json`
2. [AFFERENT] Read recent `memory/` files (last 14 days) for skill usage signals, corrections, and repeated patterns
3. [AFFERENT] List `workspace/skills/` to verify ledger matches reality
4. [AFFERENT] Review recent session history for repeated multi-step workflows that aren't covered by existing skills
5. [SYNTHESIZE] For each skill, evaluate:
   - Last used vs today → stale if >60 days and <3 uses
   - Correction rate → struggling if >30%
   - Missing from ledger → add it
   - In ledger but directory gone → clean up
6. [SYNTHESIZE] Scan recent memory and session history for repeated multi-step workflows → candidate new skills
7. [SYNTHESIZE] Review existing `candidates` in the ledger:
   - Any candidate with `occurrences >= 3` and `status: "pending"` → recommend to user
   - Any candidate with `status: "declined"` and significant workflow changes → reconsider
   - Any candidate not seen in 30+ days → set `status: "stale"` and deprioritize
8. [EFFERENT] Update `skill-ledger.json` — skill entries and candidates
9. [EFFERENT] Present audit report to the user (see skill-creator SKILL.md for format), including a **Skill Candidates** section:

```
### Skill Candidates
| Pattern | Occurrences | First Seen | Status | Recommendation |
|---------|-------------|------------|--------|----------------|
```

## Output Format

Use the Skill Audit Report format from `workspace/skills/skill-creator/SKILL.md`, extended with the Skill Candidates table above.
