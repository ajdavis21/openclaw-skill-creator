#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Skill Creator — Installer
# Copies skill-creator into your OpenClaw workspace and wires up the audit circuit.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---------------------------------------------------------------------------
# Detect workspace
# ---------------------------------------------------------------------------
if [[ -n "${OPENCLAW_WORKSPACE:-}" ]]; then
  WORKSPACE="$OPENCLAW_WORKSPACE"
elif [[ -f "$HOME/.openclaw/openclaw.json" ]]; then
  # Try to read workspace from config
  WORKSPACE=$(python3 -c "
import json, pathlib, sys
cfg = json.loads(pathlib.Path('$HOME/.openclaw/openclaw.json').read_text())
try:
    print(cfg['agents']['defaults']['workspace'])
except KeyError:
    sys.exit(1)
" 2>/dev/null || echo "")
  if [[ -z "$WORKSPACE" ]]; then
    WORKSPACE="$HOME/.openclaw/workspace"
  fi
else
  WORKSPACE="$HOME/.openclaw/workspace"
fi

SKILLS_DIR="$WORKSPACE/skills"
CIRCUITS_DIR="$WORKSPACE/CIRCUITS"

echo "OpenClaw Skill Creator — Installer"
echo "==================================="
echo ""
echo "Workspace:  $WORKSPACE"
echo "Skills dir: $SKILLS_DIR"
echo "Circuits:   $CIRCUITS_DIR"
echo ""

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
if [[ ! -d "$WORKSPACE" ]]; then
  echo "ERROR: Workspace not found at $WORKSPACE"
  echo "Set OPENCLAW_WORKSPACE or ensure ~/.openclaw/openclaw.json exists."
  exit 1
fi

# ---------------------------------------------------------------------------
# Install skill
# ---------------------------------------------------------------------------
DEST="$SKILLS_DIR/skill-creator"

if [[ -d "$DEST" ]]; then
  echo "skill-creator already exists at $DEST"
  read -rp "Overwrite? [y/N] " confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    exit 0
  fi
  rm -rf "$DEST"
fi

echo "Installing skill-creator..."
mkdir -p "$DEST/references"
cp "$SCRIPT_DIR/SKILL.md" "$DEST/SKILL.md"
cp "$SCRIPT_DIR/references/skill-template.md" "$DEST/references/skill-template.md"

# Only create ledger if one doesn't exist (preserve existing tracking data)
if [[ ! -f "$DEST/skill-ledger.json" ]]; then
  TODAY=$(date +%Y-%m-%d)
  sed "s/INSTALL_DATE/$TODAY/" "$SCRIPT_DIR/skill-ledger.json" > "$DEST/skill-ledger.json"
  echo "  Created fresh skill-ledger.json"
else
  echo "  Preserved existing skill-ledger.json"
fi

# ---------------------------------------------------------------------------
# Install audit circuit
# ---------------------------------------------------------------------------
echo "Installing audit-skills circuit..."
mkdir -p "$CIRCUITS_DIR"
cp "$SCRIPT_DIR/circuits/audit-skills.md" "$CIRCUITS_DIR/audit-skills.md"

# ---------------------------------------------------------------------------
# Create .retired directory
# ---------------------------------------------------------------------------
mkdir -p "$SKILLS_DIR/.retired"

# ---------------------------------------------------------------------------
# Register in SKILLS.md (if not already there)
# ---------------------------------------------------------------------------
SKILLS_INDEX="$WORKSPACE/SKILLS.md"
if [[ -f "$SKILLS_INDEX" ]]; then
  if ! grep -q "skill-creator" "$SKILLS_INDEX"; then
    echo "Adding skill-creator to SKILLS.md..."
    # Find the last skill row in the Installed Skills table and append after it
    # This is best-effort — the user can adjust placement manually
    if grep -q "Installed Skills" "$SKILLS_INDEX"; then
      # Use a temp file approach for portability
      awk '/^\| .* \| workspace\/skills\// { last=NR; line=$0 } { lines[NR]=$0 } END { for(i=1;i<=NR;i++) { print lines[i]; if(i==last) print "| skill-creator | v1.0.0 — Create, improve, retire, and optimize skills with learning loop | workspace/skills/ | ✅ Active |" } }' "$SKILLS_INDEX" > "${SKILLS_INDEX}.tmp" && mv "${SKILLS_INDEX}.tmp" "$SKILLS_INDEX"
      echo "  Added to Installed Skills table"
    else
      echo "  Could not find 'Installed Skills' table — add manually."
    fi
  else
    echo "  skill-creator already registered in SKILLS.md"
  fi
else
  echo "  No SKILLS.md found — you may want to register the skill manually."
fi

# ---------------------------------------------------------------------------
# Scan existing skills into ledger
# ---------------------------------------------------------------------------
echo "Scanning existing skills into ledger..."
TODAY=$(date +%Y-%m-%d)
python3 - "$DEST/skill-ledger.json" "$SKILLS_DIR" "$TODAY" << 'PYEOF'
import json, os, sys

ledger_path, skills_dir, today = sys.argv[1], sys.argv[2], sys.argv[3]

with open(ledger_path) as f:
    ledger = json.load(f)

added = 0
for name in sorted(os.listdir(skills_dir)):
    skill_path = os.path.join(skills_dir, name)
    if not os.path.isdir(skill_path):
        continue
    if name.startswith('.'):
        continue
    if name == 'skill-creator':
        continue
    skill_md = os.path.join(skill_path, 'SKILL.md')
    if not os.path.exists(skill_md):
        continue
    if name not in ledger['skills']:
        ledger['skills'][name] = {
            "created": today,
            "lastUsed": None,
            "lastUpdated": None,
            "useCount": 0,
            "corrections": 0,
            "successRate": None,
            "notes": ["Pre-existing skill — usage tracking starts now"],
            "status": "active"
        }
        added += 1
        print(f"  Added: {name}")

with open(ledger_path, 'w') as f:
    json.dump(ledger, f, indent=2)

if added == 0:
    print("  No new skills to add")
else:
    print(f"  Added {added} existing skill(s) to ledger")
PYEOF

echo ""
echo "Done! skill-creator is installed."
echo ""
echo "Your agent can now:"
echo "  - Create new skills:   'make a skill for X'"
echo "  - Improve skills:      'improve the X skill'"
echo "  - Audit skills:        'run a skill audit'"
echo "  - Retire skills:       'retire the X skill'"
echo ""
echo "The audit circuit will run every 14 days during heartbeats."
echo "Edit the interval in skill-ledger.json → audit.auditIntervalDays"
