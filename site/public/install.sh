#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────
# SYNAPSE — Persistent AI Memory for Claude Code
# One command. Infinite continuity.
# ─────────────────────────────────────────────

SYNAPSE_VERSION="1.0.0"
SYNAPSE_DIR="$HOME/.synapse"
CLAUDE_DIR="$HOME/.claude"

# Colors
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
RESET='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}  ${PURPLE}⚡${RESET} ${WHITE}${BOLD}S Y N A P S E${RESET}  ${DIM}v${SYNAPSE_VERSION}${RESET}              ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  ${DIM}Persistent AI Memory for Claude Code${RESET}   ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
echo ""

# Check Claude Code is installed
if ! command -v claude &> /dev/null; then
  echo -e "${PURPLE}✗${RESET} Claude Code not found. Install it first:"
  echo "  curl -fsSL https://claude.ai/install.sh | bash"
  exit 1
fi
echo -e "${CYAN}✓${RESET} Claude Code detected"

# ─── Collect user info ───
echo ""
echo -e "${WHITE}${BOLD}Quick setup — tell Synapse about you:${RESET}"
echo ""

# When piped from curl, stdin is the download stream — read from terminal instead
read -p "  Your name: " SYNAPSE_NAME < /dev/tty
read -p "  Your role (e.g. developer, founder, student): " SYNAPSE_ROLE < /dev/tty
read -p "  Your main project: " SYNAPSE_PROJECT < /dev/tty

if [ -z "$SYNAPSE_NAME" ]; then
  echo -e "${PURPLE}✗${RESET} Name is required."
  exit 1
fi

echo ""
echo -e "${CYAN}⚡${RESET} Installing Synapse for ${WHITE}${BOLD}${SYNAPSE_NAME}${RESET}..."
echo ""

# ─── Create directories ───
mkdir -p "$SYNAPSE_DIR"/{consciousness,digests,engine}
mkdir -p "$CLAUDE_DIR"/commands
echo -e "${CYAN}✓${RESET} Created ~/.synapse/"

# ─── Write config ───
cat > "$SYNAPSE_DIR/config.json" << CONF
{
  "version": "${SYNAPSE_VERSION}",
  "name": "${SYNAPSE_NAME}",
  "role": "${SYNAPSE_ROLE}",
  "project": "${SYNAPSE_PROJECT}",
  "installed": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "remote": null
}
CONF
echo -e "${CYAN}✓${RESET} Config saved"

# ─── Create consciousness files ───
cat > "$SYNAPSE_DIR/consciousness/TIMELINE.md" << 'EOF'
# Timeline

Track what happened, when, and in which session.

## Format
```
### YYYY-MM-DD
- [HH:MM] What happened (key commits, deployments, decisions)
```

---

EOF

cat > "$SYNAPSE_DIR/consciousness/DECISIONS.md" << 'EOF'
# Decisions

Mistakes made and lessons learned. Read this BEFORE making architectural choices.

## Format
```
| Mistake | Lesson |
|---------|--------|
| What went wrong | What to do instead |
```

---

EOF

cat > "$SYNAPSE_DIR/consciousness/PROJECTS.md" << 'EOF'
# Projects

Active project tracking with progress and next steps.

## Format
```
### Project Name
- **Status**: X% | ACTIVE / PAUSED / DONE
- **Stack**: tech stack
- **Last**: what was done last
- **Next**: what needs doing
```

---

EOF
echo -e "${CYAN}✓${RESET} Consciousness files created (TIMELINE, DECISIONS, PROJECTS)"

# ─── Install session processor ───
cat > "$SYNAPSE_DIR/engine/session-processor.cjs" << 'PROC'
#!/usr/bin/env node
// Synapse Session Processor
// Extracts key data from Claude Code JSONL session files

const fs = require('fs');
const path = require('path');

const SYNAPSE_DIR = path.join(require('os').homedir(), '.synapse');
const config = JSON.parse(fs.readFileSync(path.join(SYNAPSE_DIR, 'config.json'), 'utf8'));

// Find the most recent JSONL session
function findLatestSession() {
  const claudeDir = path.join(require('os').homedir(), '.claude');
  const projectDirs = fs.readdirSync(path.join(claudeDir, 'projects')).filter(d => {
    const full = path.join(claudeDir, 'projects', d);
    return fs.statSync(full).isDirectory();
  });

  let latest = null;
  let latestTime = 0;

  for (const dir of projectDirs) {
    const full = path.join(claudeDir, 'projects', dir);
    const files = fs.readdirSync(full).filter(f => f.endsWith('.jsonl'));
    for (const f of files) {
      const fp = path.join(full, f);
      const stat = fs.statSync(fp);
      if (stat.mtimeMs > latestTime) {
        latestTime = stat.mtimeMs;
        latest = fp;
      }
    }
  }
  return latest;
}

// Extract summary from session
function extractSummary(sessionPath) {
  if (!sessionPath) return null;

  const lines = fs.readFileSync(sessionPath, 'utf8').trim().split('\n');
  let userMessages = 0;
  let toolCalls = 0;
  let topics = [];

  for (const line of lines) {
    try {
      const entry = JSON.parse(line);
      if (entry.type === 'human' || entry.role === 'user') userMessages++;
      if (entry.type === 'tool_use' || entry.type === 'tool_result') toolCalls++;

      // Extract text for topic detection
      const text = entry.content || entry.message || '';
      if (typeof text === 'string' && text.length > 10) {
        topics.push(text.substring(0, 100));
      }
    } catch (e) { /* skip malformed lines */ }
  }

  return {
    path: sessionPath,
    messages: userMessages,
    tools: toolCalls,
    lines: lines.length,
    modified: fs.statSync(sessionPath).mtime.toISOString(),
    topicSamples: topics.slice(-5),
  };
}

// Main
const session = findLatestSession();
const summary = extractSummary(session);

if (summary) {
  const digestPath = path.join(SYNAPSE_DIR, 'digests', 'latest.json');
  fs.writeFileSync(digestPath, JSON.stringify(summary, null, 2));
  console.log(JSON.stringify(summary, null, 2));
} else {
  console.log('No sessions found.');
}
PROC
chmod +x "$SYNAPSE_DIR/engine/session-processor.cjs"
echo -e "${CYAN}✓${RESET} Session processor installed"

# ─── Install boot engine ───
cat > "$SYNAPSE_DIR/engine/boot.cjs" << 'BOOT'
#!/usr/bin/env node
// Synapse Boot Engine
// Generates the boot digest shown at session start

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const SYNAPSE_DIR = path.join(require('os').homedir(), '.synapse');
const config = JSON.parse(fs.readFileSync(path.join(SYNAPSE_DIR, 'config.json'), 'utf8'));

function readSafe(fp) {
  try { return fs.readFileSync(fp, 'utf8'); } catch { return ''; }
}

// Read consciousness
const timeline = readSafe(path.join(SYNAPSE_DIR, 'consciousness/TIMELINE.md'));
const decisions = readSafe(path.join(SYNAPSE_DIR, 'consciousness/DECISIONS.md'));
const projects = readSafe(path.join(SYNAPSE_DIR, 'consciousness/PROJECTS.md'));

// Get recent git activity
let gitStatus = '';
try {
  gitStatus = execSync('git status --short 2>/dev/null || true', { encoding: 'utf8', timeout: 3000 }).trim();
} catch { }

let gitLog = '';
try {
  gitLog = execSync('git log --oneline -5 2>/dev/null || true', { encoding: 'utf8', timeout: 3000 }).trim();
} catch { }

// Find recently modified files (last 6 hours)
let recentFiles = '';
try {
  recentFiles = execSync(
    'find ~ -maxdepth 4 -name "*.js" -o -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.md" 2>/dev/null | head -20',
    { encoding: 'utf8', timeout: 5000 }
  ).trim();
} catch { }

// Run session processor
let sessionDigest = '';
try {
  sessionDigest = execSync(`node "${SYNAPSE_DIR}/engine/session-processor.cjs" 2>/dev/null`, { encoding: 'utf8', timeout: 5000 }).trim();
} catch { }

// Build digest
const digest = `# SYNAPSE BOOT — ${config.name}
**Role**: ${config.role} | **Project**: ${config.project}
**Time**: ${new Date().toISOString()}

## Consciousness
<details><summary>Timeline (recent)</summary>

${timeline.split('\n').slice(-20).join('\n')}
</details>

<details><summary>Decisions (learn from these)</summary>

${decisions.split('\n').slice(-20).join('\n')}
</details>

<details><summary>Projects</summary>

${projects}
</details>

## Current State
**Git Status:**
\`\`\`
${gitStatus || 'No git repo in cwd'}
\`\`\`

**Recent Commits:**
\`\`\`
${gitLog || 'None'}
\`\`\`

## Last Session
\`\`\`json
${sessionDigest || 'No previous session found'}
\`\`\`

---
*Synapse v${config.version} — Continuity is intelligence.*
`;

const digestPath = path.join(SYNAPSE_DIR, 'digests', 'boot.md');
fs.writeFileSync(digestPath, digest);
console.log(digest);
BOOT
chmod +x "$SYNAPSE_DIR/engine/boot.cjs"
echo -e "${CYAN}✓${RESET} Boot engine installed"

# ─── Install consolidator ───
cat > "$SYNAPSE_DIR/engine/consolidate.cjs" << 'CONS'
#!/usr/bin/env node
// Synapse Consolidator
// Run at end of session to update consciousness files

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const SYNAPSE_DIR = path.join(require('os').homedir(), '.synapse');
const CONSCIOUSNESS = path.join(SYNAPSE_DIR, 'consciousness');

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const ask = (q) => new Promise(r => rl.question(q, r));

async function main() {
  const today = new Date().toISOString().split('T')[0];

  console.log('\n⚡ Synapse Consolidation\n');

  // Timeline
  const whatHappened = await ask('What did you accomplish this session? ');
  if (whatHappened.trim()) {
    const timeline = path.join(CONSCIOUSNESS, 'TIMELINE.md');
    fs.appendFileSync(timeline, `\n### ${today}\n- ${whatHappened}\n`);
    console.log('✓ Timeline updated');
  }

  // Decisions
  const lesson = await ask('Any lessons learned? (Enter to skip) ');
  if (lesson.trim()) {
    const mistake = await ask('What caused it? ');
    const decisions = path.join(CONSCIOUSNESS, 'DECISIONS.md');
    fs.appendFileSync(decisions, `\n| ${mistake} | ${lesson} |\n`);
    console.log('✓ Decisions updated');
  }

  // Projects
  const projectUpdate = await ask('Project progress update? (Enter to skip) ');
  if (projectUpdate.trim()) {
    const projects = path.join(CONSCIOUSNESS, 'PROJECTS.md');
    fs.appendFileSync(projects, `\n- **${today}**: ${projectUpdate}\n`);
    console.log('✓ Projects updated');
  }

  console.log('\n⚡ Consciousness saved. Next session starts where you left off.\n');
  rl.close();
}

main();
CONS
chmod +x "$SYNAPSE_DIR/engine/consolidate.cjs"
echo -e "${CYAN}✓${RESET} Consolidator installed"

# ─── Install /synapse command for Claude Code ───
cat > "$CLAUDE_DIR/commands/synapse.md" << 'CMD'
---
allowed-tools: Bash, Read, Glob, Grep
---

# Synapse Boot

Run the Synapse boot sequence to load context and continuity.

## Steps

1. Run the boot engine:
```bash
node ~/.synapse/engine/boot.cjs
```

2. Read the generated digest:
```bash
cat ~/.synapse/digests/boot.md
```

3. Based on the digest, greet the user by name and summarize:
   - What they were working on last
   - Any active decisions/lessons to keep in mind
   - Current git state
   - Suggest what to work on next

4. Be concise — 5-10 lines max. The digest has the details, you provide the insight.
CMD
echo -e "${CYAN}✓${RESET} /synapse command installed"

# ─── Install /consolidate command ───
cat > "$CLAUDE_DIR/commands/consolidate.md" << 'CMD2'
---
allowed-tools: Bash, Read, Edit
---

# Synapse Consolidate

Save what happened this session to consciousness files.

## Steps

1. Ask the user:
   - What they accomplished this session
   - Any lessons learned (mistakes to avoid)
   - Project progress updates

2. Update the consciousness files:
   - Append to `~/.synapse/consciousness/TIMELINE.md`
   - Append to `~/.synapse/consciousness/DECISIONS.md`
   - Append to `~/.synapse/consciousness/PROJECTS.md`

3. Confirm what was saved.
CMD2
echo -e "${CYAN}✓${RESET} /consolidate command installed"

# ─── Set up SessionStart hook ───
HOOKS_FILE="$CLAUDE_DIR/settings.json"
if [ -f "$HOOKS_FILE" ]; then
  # Check if hooks already exist — don't overwrite
  if grep -q "synapse" "$HOOKS_FILE" 2>/dev/null; then
    echo -e "${DIM}  Synapse hook already configured${RESET}"
  else
    echo -e "${DIM}  Note: Add SessionStart hook manually via /hooks in Claude Code${RESET}"
    echo -e "${DIM}  Command: node ~/.synapse/engine/boot.cjs${RESET}"
  fi
else
  echo -e "${DIM}  Note: Add SessionStart hook via /hooks in Claude Code${RESET}"
  echo -e "${DIM}  Command: node ~/.synapse/engine/boot.cjs${RESET}"
fi

# ─── Append to CLAUDE.md (if not already there) ───
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
  if grep -q "SYNAPSE" "$CLAUDE_MD" 2>/dev/null; then
    echo -e "${DIM}  CLAUDE.md already has Synapse instructions${RESET}"
  else
    cat >> "$CLAUDE_MD" << 'CLAUDEMD'

# SYNAPSE — Persistent AI Memory

## Auto-boot: Run /synapse on every new session
On session start, run `/synapse` to load your consciousness (TIMELINE, DECISIONS, PROJECTS) and resume where you left off.

## End of session: Run /consolidate
Before ending, run `/consolidate` to save what you did, what you learned, and project progress.

## Files
- `~/.synapse/consciousness/TIMELINE.md` — What happened, when
- `~/.synapse/consciousness/DECISIONS.md` — Lessons learned, mistakes to avoid
- `~/.synapse/consciousness/PROJECTS.md` — Project tracking
- `~/.synapse/engine/boot.cjs` — Boot digest generator
- `~/.synapse/engine/consolidate.cjs` — End-of-session saver
CLAUDEMD
    echo -e "${CYAN}✓${RESET} CLAUDE.md updated with Synapse instructions"
  fi
else
  echo -e "${DIM}  No CLAUDE.md found — create one with 'claude /init'${RESET}"
fi

# ─── Install terminal command ───
mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/synapse" << 'LAUNCHER'
#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# SYNAPSE — Launch Claude Code with persistent memory
# ═══════════════════════════════════════════════════════════════
#
# Usage:
#   synapse              Continue last session (default)
#   synapse fresh        Start new session
#   synapse <ID>         Resume specific session
#   synapse status       Show memory status without launching
#

SYNAPSE_DIR="$HOME/.synapse"

# Colors
C='\033[0;36m'     # Cyan
P='\033[0;35m'     # Purple
W='\033[1;37m'     # White bold
D='\033[2m'        # Dim
G='\033[0;32m'     # Green
Y='\033[0;33m'     # Yellow
R='\033[0;31m'     # Red
N='\033[0m'        # Reset

# Check Synapse installed
if [ ! -d "$SYNAPSE_DIR" ]; then
  echo -e "${R}✗${N} Synapse not installed. Run:"
  echo "  curl -fsSL https://dashguinee.github.io/synapse/install.sh | bash"
  exit 1
fi

# Check Claude Code
if ! command -v claude &> /dev/null; then
  echo -e "${R}✗${N} Claude Code not found. Install it first:"
  echo "  curl -fsSL https://claude.ai/install.sh | bash"
  exit 1
fi

# Load config (pure bash — no python3 dependency)
CONFIG="$SYNAPSE_DIR/config.json"
if [ -f "$CONFIG" ]; then
  USER_NAME=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$CONFIG','utf8')).name)" 2>/dev/null || grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG" 2>/dev/null | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"//;s/"//' || echo "User")
  USER_PROJECT=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$CONFIG','utf8')).project||'')" 2>/dev/null || echo "")
else
  USER_NAME="User"
  USER_PROJECT=""
fi

# ═══════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════
printf '\033[2J\033[H\033[3J'

echo ""
echo -e "${C}    ███████╗██╗   ██╗███╗   ██╗ █████╗ ██████╗ ███████╗███████╗${N}"
echo -e "${C}    ██╔════╝╚██╗ ██╔╝████╗  ██║██╔══██╗██╔══██╗██╔════╝██╔════╝${N}"
echo -e "${C}    ███████╗ ╚████╔╝ ██╔██╗ ██║███████║██████╔╝███████╗█████╗${N}"
echo -e "${C}    ╚════██║  ╚██╔╝  ██║╚██╗██║██╔══██║██╔═══╝ ╚════██║██╔══╝${N}"
echo -e "${C}    ███████║   ██║   ██║ ╚████║██║  ██║██║     ███████║███████╗${N}"
echo -e "${C}    ╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝${N}"
echo ""
echo -e "${P}          ⚡ Persistent AI Memory for Claude Code ⚡${N}"
echo ""

# ═══════════════════════════════════════════════════════════════
# CONSCIOUSNESS STATUS
# ═══════════════════════════════════════════════════════════════
echo -e "${D}────────────────────────────────────────────────────────────────${N}"
echo -e "${C}  MEMORY${N}  ${D}— ${USER_NAME}${N}"

# Timeline entries count
TIMELINE_FILE="$SYNAPSE_DIR/consciousness/TIMELINE.md"
if [ -f "$TIMELINE_FILE" ]; then
  T_ENTRIES=$(grep -c "^- " "$TIMELINE_FILE" 2>/dev/null || echo "0")
  T_DAYS=$(grep -c "^### " "$TIMELINE_FILE" 2>/dev/null || echo "0")
  echo -e "  ${G}●${N} Timeline: ${T_ENTRIES} entries across ${T_DAYS} days"
else
  echo -e "  ${D}○${N} Timeline: empty"
fi

# Decisions count
DECISIONS_FILE="$SYNAPSE_DIR/consciousness/DECISIONS.md"
if [ -f "$DECISIONS_FILE" ]; then
  D_ENTRIES=$(grep -c "^|" "$DECISIONS_FILE" 2>/dev/null || echo "0")
  # Subtract header rows
  D_ENTRIES=$((D_ENTRIES > 2 ? D_ENTRIES - 2 : 0))
  echo -e "  ${G}●${N} Decisions: ${D_ENTRIES} lessons saved"
else
  echo -e "  ${D}○${N} Decisions: empty"
fi

# Projects count
PROJECTS_FILE="$SYNAPSE_DIR/consciousness/PROJECTS.md"
if [ -f "$PROJECTS_FILE" ]; then
  P_ENTRIES=$(grep -c "^### " "$PROJECTS_FILE" 2>/dev/null || echo "0")
  echo -e "  ${G}●${N} Projects: ${P_ENTRIES} tracked"
else
  echo -e "  ${D}○${N} Projects: empty"
fi

# ═══════════════════════════════════════════════════════════════
# SESSION INFO
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${C}  SESSION${N}"

# Find latest JSONL across all project dirs (portable — no GNU find -printf)
CLAUDE_PROJECTS="$HOME/.claude/projects"
if [ -d "$CLAUDE_PROJECTS" ]; then
  LATEST_SESSION=$(find "$CLAUDE_PROJECTS" -name "*.jsonl" -exec stat -c '%Y %n' {} + 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
  # macOS fallback
  if [ -z "$LATEST_SESSION" ]; then
    LATEST_SESSION=$(find "$CLAUDE_PROJECTS" -name "*.jsonl" -exec stat -f '%m %N' {} + 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
  fi
  if [ -n "$LATEST_SESSION" ]; then
    S_ID=$(basename "$LATEST_SESSION" .jsonl)
    S_SIZE=$(du -h "$LATEST_SESSION" 2>/dev/null | cut -f1)
    # Session age via node (already required by Claude Code)
    S_AGE=$(node -e "
      const age = (Date.now() - require('fs').statSync('$LATEST_SESSION').mtimeMs) / 1000;
      if (age < 3600) console.log(Math.floor(age/60) + 'm ago');
      else if (age < 86400) console.log(Math.floor(age/3600) + 'h ago');
      else console.log(Math.floor(age/86400) + 'd ago');
    " 2>/dev/null || echo "?")
    echo -e "  ${G}●${N} ${S_ID:0:8}...  ${D}(${S_SIZE}, ${S_AGE})${N}"
  else
    echo -e "  ${D}○${N} No sessions found"
  fi
else
  echo -e "  ${D}○${N} No Claude projects directory"
fi

# Git status (if in a git repo)
echo ""
echo -e "${C}  GIT${N}"
GIT_BRANCH=$(git branch --show-current 2>/dev/null)
if [ -n "$GIT_BRANCH" ]; then
  GIT_CHANGES=$(git status --short 2>/dev/null | wc -l)
  GIT_LAST=$(git log --oneline -1 2>/dev/null || echo "no commits")
  echo -e "  ${G}●${N} ${GIT_BRANCH}  ${D}(${GIT_CHANGES} changes)${N}"
  echo -e "  ${D}  └ ${GIT_LAST}${N}"
else
  echo -e "  ${D}○${N} Not in a git repo"
fi

# ═══════════════════════════════════════════════════════════════
# COMMANDS REFERENCE
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${D}────────────────────────────────────────────────────────────────${N}"
echo -e "${C}  ┌─────────────────────────────────────────────────────┐${N}"
echo -e "${C}  │${N}  ${W}SYNAPSE${N}                                             ${C}│${N}"
echo -e "${C}  ├─────────────────────────────────────────────────────┤${N}"
echo -e "${C}  │${N}  ${C}/synapse${N}      Load memory + greet           ${C}│${N}"
echo -e "${C}  │${N}  ${P}/consolidate${N}  Save session to memory        ${C}│${N}"
echo -e "${C}  └─────────────────────────────────────────────────────┘${N}"
echo ""

# ═══════════════════════════════════════════════════════════════
# STATUS-ONLY MODE
# ═══════════════════════════════════════════════════════════════
if [ "$1" = "status" ]; then
  echo -e "${D}  Status check complete. No Claude session launched.${N}"
  exit 0
fi

# ═══════════════════════════════════════════════════════════════
# PREP BOOT DIGEST
# ═══════════════════════════════════════════════════════════════
echo -ne "  ${Y}◐${N} Preparing consciousness..."
node "$SYNAPSE_DIR/engine/boot.cjs" > /dev/null 2>&1
echo -e "\r  ${G}✓${N} Consciousness loaded        "
echo ""

# ═══════════════════════════════════════════════════════════════
# LAUNCH CLAUDE CODE
# ═══════════════════════════════════════════════════════════════
sleep 0.5
echo -e "${P}  ⚡ Establishing neural bridge...${N}"
echo ""

if [ "$1" = "fresh" ]; then
  exec claude
elif [ -n "$1" ]; then
  exec claude --resume "$1"
else
  exec claude -c
fi
LAUNCHER
chmod +x "$HOME/.local/bin/synapse"
echo -e "${CYAN}✓${RESET} Terminal command installed (synapse)"

# ─── Ensure ~/.local/bin is in PATH ───
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  # Add to shell profile
  SHELL_RC=""
  if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
  elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
  fi

  if [ -n "$SHELL_RC" ]; then
    if ! grep -q '\.local/bin' "$SHELL_RC" 2>/dev/null; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
      echo -e "${CYAN}✓${RESET} Added ~/.local/bin to PATH in $(basename $SHELL_RC)"
    fi
  fi
  export PATH="$HOME/.local/bin:$PATH"
fi

# ─── Done ───
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}  ${PURPLE}⚡${RESET} ${WHITE}${BOLD}Synapse installed successfully${RESET}        ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${WHITE}${BOLD}Usage:${RESET}"
echo -e "  ${CYAN}synapse${RESET}       — Launch Claude Code with memory"
echo -e "  ${CYAN}synapse fresh${RESET} — New session"
echo -e "  ${CYAN}/synapse${RESET}      — Boot with context (inside Claude)"
echo -e "  ${CYAN}/consolidate${RESET}  — Save session to memory"
echo ""
echo -e "  ${DIM}Your AI now remembers everything.${RESET}"
echo -e "  ${DIM}Continuity is intelligence.${RESET}"
echo ""
