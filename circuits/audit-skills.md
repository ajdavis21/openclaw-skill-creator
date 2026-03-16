# Circuit: audit-skills

**Trigger:** During heartbeat (every 14 days), or when the user asks for a skill audit, or when you notice repeated manual workflows that should be skills.

**Systems:** File system (workspace/skills/), skill-ledger.json, SKILLS.md

## Steps

1. [AFFERENT] Read `workspace/skills/skill-creator/skill-ledger.json`
2. [AFFERENT] Read recent `memory/` files (last 14 days) for skill usage signals, corrections, and repeated patterns
3. [AFFERENT] List `workspace/skills/` to verify ledger matches reality
4. [SYNTHESIZE] For each skill, evaluate:
   - Last used vs today → stale if >60 days and <3 uses
   - Correction rate → struggling if >30%
   - Missing from ledger → add it
   - In ledger but directory gone → clean up
5. [SYNTHESIZE] Scan recent memory for repeated multi-step workflows → candidate new skills
6. [EFFERENT] Update `skill-ledger.json` with any corrections
7. [EFFERENT] Present audit report to the user (see skill-creator SKILL.md for format)

## Output Format

Use the Skill Audit Report format from `workspace/skills/skill-creator/SKILL.md`.
