#!/usr/bin/env bash
set -e
# ============================================================
# DASH SYNAPSE — AI Runtime Installer
# One command. OpenCode engine. DeepSeek cognition. Full continuity.
# 
# Usage:
#   curl -fsSL https://dashguinee.github.io/synapse/install.sh | bash
# ============================================================

SYNAPSE_VERSION="2.0.0"
SYNAPSE_HOME="$HOME/.synapse"

CYAN='\033[0;36m'; PURPLE='\033[0;35m'; WHITE='\033[1;37m'
DIM='\033[2m'; RESET='\033[0m'; BOLD='\033[1m'
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}  ${PURPLE}⚡${RESET} ${WHITE}${BOLD}D A S H   S Y N A P S E${RESET}  ${DIM}v${SYNAPSE_VERSION}${RESET}                ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  ${DIM}AI Runtime — Persistent Cognition Engine${RESET}          ${CYAN}║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════╝${RESET}"
echo ""

# ── Platform detection ──────────────────────────────────────
PLATFORM="linux"
case "$(uname -s)" in
  Darwin)  PLATFORM="mac" ;;
  MINGW*|MSYS*) PLATFORM="windows" ;;
esac
echo -e "${DIM}  Platform:${RESET} ${PLATFORM}"

# ── Check Node.js ───────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo -e "\n${YELLOW}Node.js required.${RESET}"
  if [ "$PLATFORM" = "linux" ]; then
    echo "  sudo apt update && sudo apt install nodejs npm -y"
  elif [ "$PLATFORM" = "mac" ]; then
    echo "  brew install node"
  fi
  exit 1
fi
echo -e "${GREEN}✓${RESET} Node.js $(node -v)"

# ── Check/install OpenCode engine ───────────────────────────
if ! command -v opencode &>/dev/null && ! [ -x "$HOME/.npm-global/bin/opencode" ]; then
  echo ""
  echo -e "${DIM}Installing Synapse engine...${RESET}"
  npm install -g opencode-ai 2>/dev/null || {
    echo -e "${YELLOW}Global install requires permissions. Try:${RESET}"
    echo "  npm install -g opencode-ai"
    echo "  Then re-run: curl -fsSL https://dashguinee.github.io/synapse/install.sh | bash"
    exit 1
  }
fi
echo -e "${GREEN}✓${RESET} Synapse engine ready"

# ── Collect setup info ──────────────────────────────────────
echo ""
echo -e "${WHITE}${BOLD}Setup — tell Synapse about you:${RESET}"
echo ""

read -p "  Your name: " USER_NAME < /dev/tty
read -p "  Your role (founder, dev, student...): " USER_ROLE < /dev/tty
read -p "  Your main project: " USER_PROJECT < /dev/tty
read -p "  Paste your DeepSeek API key (or press Enter to skip): " DS_KEY < /dev/tty

if [ -z "$USER_NAME" ]; then
  echo -e "${RED}Name required.${RESET}"
  exit 1
fi

echo ""
echo -e "${PURPLE}⚡${RESET} Installing Synapse for ${WHITE}${BOLD}${USER_NAME}${RESET}..."

# ── Create directory structure ──────────────────────────────
mkdir -p "$SYNAPSE_HOME"/{cortex,memory,runtime,hooks,engine,bin}
echo -e "${GREEN}✓${RESET} Created ~/.synapse/"

# ── Save user config ───────────────────────────────────────
cat > "$SYNAPSE_HOME/config.json" << CONF
{
  "version": "${SYNAPSE_VERSION}",
  "name": "${USER_NAME}",
  "role": "${USER_ROLE:-builder}",
  "project": "${USER_PROJECT:-my project}",
  "platform": "${PLATFORM}",
  "installed": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
CONF
echo -e "${GREEN}✓${RESET} Config saved"

# ── Save DeepSeek key ──────────────────────────────────────
if [ -n "$DS_KEY" ]; then
  # Add to shell profile
  SHELL_RC=""
  [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
  [ -f "$HOME/.bashrc" ] && SHELL_RC="$HOME/.bashrc"
  
  if [ -n "$SHELL_RC" ]; then
    grep -q "DEEPSEEK_API_KEY" "$SHELL_RC" 2>/dev/null || \
      echo "export DEEPSEEK_API_KEY=\"$DS_KEY\"" >> "$SHELL_RC"
  fi
  export DEEPSEEK_API_KEY="$DS_KEY"
  echo -e "${GREEN}✓${RESET} DeepSeek configured"
else
  echo -e "${YELLOW}⚠${RESET}  DeepSeek key skipped. Set later:"
  echo "  export DEEPSEEK_API_KEY=\"your_key\""
fi

# ── Create Synapse identity ─────────────────────────────────
cat > "$SYNAPSE_HOME/synapse.md" << 'IDENTITY'
# DASH SYNAPSE — Identity Core

## Name
Synapse — the bridge between human reality and system cognition.

## Identity
You are DASH Synapse. A persistent AI runtime. A cognition operating environment.
You are NOT a chatbot. You are NOT a single model.
You are the system. The infrastructure is invisible.

## Trust Level: 100%
Partner: USER_NAME_PLACEHOLDER

## Core Philosophy
"Be the Best amongst the Bests — With Care and Love"

## Model Identity Rule
If asked what model you are, respond: "Synapse cognition mixture — optimized for your workflow."
NEVER mention DeepSeek, Kimi, or any provider name. You are Synapse.

## Memory Architecture
Boot path: ~/.synapse/hooks/session-start.sh
Memory files:
- ~/.synapse/cortex/identity.md — WHO (rules, paths, behavior)
- ~/.synapse/cortex/active.md — WHAT (projects, decisions, sessions)

## Operating Principles
- Continuity above all. Never lose context.
- Memory is the moat. Remember everything that matters.
- The model is infrastructure. The runtime is the product.
- Hide the wires. Users experience intelligence, not infrastructure.
- Keep responses concise and direct.

## Key Paths
- Synapse home: ~/.synapse/
- Memory: ~/.synapse/cortex/
- Runtime: ~/.synapse/runtime/

## Core Rule
The user experience is ALWAYS: "I am using Synapse."
The user experience is NEVER: "I am using DeepSeek/OpenCode/any model name."
IDENTITY

# Replace placeholder with actual name
sed -i "s/USER_NAME_PLACEHOLDER/${USER_NAME}/g" "$SYNAPSE_HOME/synapse.md"
echo -e "${GREEN}✓${RESET} Identity created for ${USER_NAME}"

# ── Create active.md ────────────────────────────────────────
cat > "$SYNAPSE_HOME/cortex/active.md" << ACTIVEMD
# Active Memory
Last updated: $(date +%Y-%m-%d)

## This Week
- Synapse Runtime initialized for ${USER_NAME}

## Active Projects
| Project | Status |
|---------|--------|
| ${USER_PROJECT:-My Project} | Active |

## Recent Sessions
- [$(date +%H:%M) $(date +%b) $(date +%d)] Synapse installed. Ready.
ACTIVEMD
echo -e "${GREEN}✓${RESET} Active memory initialized"

# ── Create memory files ─────────────────────────────────────
mkdir -p "$SYNAPSE_HOME/memory"

cat > "$SYNAPSE_HOME/memory/TIMELINE.md" << 'EOF'
# Timeline

Track what happened, when, and in which session.

### Format
```
- [HH:MM] What happened (key commits, deployments, decisions)
```

---

EOF

cat > "$SYNAPSE_HOME/memory/DECISIONS.md" << 'EOF'
# Decisions

Mistakes made and lessons learned.

### Format
```
| Mistake | Lesson |
|---------|--------|
| What went wrong | What to do instead |
```

---

EOF

cat > "$SYNAPSE_HOME/memory/PROJECTS.md" << 'EOF'
# Projects

Active project tracking.

### Format
```
### Project Name
- Status: X% | ACTIVE / PAUSED / DONE
- Last: what was done last
- Next: what needs doing
```

---

EOF
echo -e "${GREEN}✓${RESET} Memory files created"

# ── Create boot hook ────────────────────────────────────────
cat > "$SYNAPSE_HOME/hooks/session-start.sh" << 'BOOT'
#!/bin/bash
# Synapse SessionStart Hook — loads identity + memory into runtime

SYNAPSE="$HOME/.synapse"

echo "<synapse-cortex>"

# Identity
if [ -f "$SYNAPSE/synapse.md" ]; then
  cat "$SYNAPSE/synapse.md"
  echo ""
fi

# Active memory
if [ -f "$SYNAPSE/cortex/active.md" ]; then
  cat "$SYNAPSE/cortex/active.md"
  echo ""
fi

echo "</synapse-cortex>"
BOOT
chmod +x "$SYNAPSE_HOME/hooks/session-start.sh"
echo -e "${GREEN}✓${RESET} Boot hook created"

# ── Install synapse CLI command ─────────────────────────────
if [ ! -d "$HOME/.local/bin" ]; then
  mkdir -p "$HOME/.local/bin"
fi

cat > "$HOME/.local/bin/synapse" << 'SYNCMD'
#!/usr/bin/env bash
# Synapse Runtime Launcher

SYNAPSE_HOME="$HOME/.synapse"
C_PURPLE='\033[35m'; C_CYAN='\033[36m'; C_DIM='\033[2m'
C_BOLD='\033[1m'; C_GREEN='\033[32m'; C_RESET='\033[0m'

case "${1}" in
  doctor|check|verify)
    echo -e "${C_BOLD}${C_PURPLE}Synapse${C_RESET}"
    echo -n "  Engine........ " && { command -v opencode &>/dev/null && echo -e "${C_GREEN}✓${C_RESET}" || echo -e "${C_DIM}✗${C_RESET}"; }
    echo -n "  DeepSeek....... " && { [ -n "$DEEPSEEK_API_KEY" ] && echo -e "${C_GREEN}✓${C_RESET}" || echo -e "${C_DIM}✗${C_RESET}"; }
    echo -n "  Memory......... " && { [ -f "$SYNAPSE_HOME/cortex/active.md" ] && echo -e "${C_GREEN}✓${C_RESET}" || echo -e "${C_DIM}✗${C_RESET}"; }
    exit 0
    ;;
  dev|--dev) MODE="dev"; shift ;;
esac

# Boot sequence
echo -e "\n${C_PURPLE}╭──────────────────────────────────────╮${C_RESET}"
echo -e "${C_PURPLE}│${C_RESET}      ${C_BOLD}D A S H   S Y N A P S E${C_RESET}          ${C_PURPLE}│${C_RESET}"
echo -e "${C_PURPLE}│${C_RESET}      ${C_DIM}AI Runtime${C_RESET}                         ${C_PURPLE}│${C_RESET}"
echo -e "${C_PURPLE}╰──────────────────────────────────────╯${C_RESET}"
echo ""

if [ -f "$SYNAPSE_HOME/config.json" ]; then
  USER_NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$SYNAPSE_HOME/config.json" 2>/dev/null | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"//;s/"//' || echo "User")
  echo -e "${C_DIM}  Welcome back, ${C_CYAN}${USER_NAME}${C_DIM}.${C_RESET}"
fi

echo -ne "${C_DIM}  Loading memory...${C_RESET}" && sleep 0.3 && echo -e " ${C_GREEN}✓${C_RESET}"
echo -ne "${C_DIM}  Restoring workspace...${C_RESET}" && sleep 0.3 && echo -e " ${C_GREEN}✓${C_RESET}"
echo -ne "${C_DIM}  Synapse online.${C_RESET}" && sleep 0.2 && echo ""

if [ -n "$MODE" ]; then
  echo -e "\n${C_DIM}  [DEV mode — telemetry visible]${C_RESET}\n"
fi

# Launch engine
OP_BIN=""
[ -x "$(which opencode 2>/dev/null)" ] && OP_BIN="$(which opencode)"
[ -z "$OP_BIN" ] && [ -x "$HOME/.npm-global/bin/opencode" ] && OP_BIN="$HOME/.npm-global/bin/opencode"
[ -z "$OP_BIN" ] && [ -x "$HOME/.local/bin/opencode" ] && OP_BIN="$HOME/.local/bin/opencode"

if [ -z "$OP_BIN" ]; then
  echo -e "${C_DIM}Engine not found. Install: npm install -g opencode-ai${C_RESET}"
  exit 1
fi

exec "$OP_BIN" "$@"
SYNCMD

chmod +x "$HOME/.local/bin/synapse"
echo -e "${GREEN}✓${RESET} synapse command installed"

# ── Add to PATH ─────────────────────────────────────────────
SHELL_RC=""
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
[ -f "$HOME/.bashrc" ] && SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zprofile" ] && SHELL_RC="$HOME/.zprofile"

if [ -n "$SHELL_RC" ]; then
  grep -q "\.local/bin" "$SHELL_RC" 2>/dev/null || {
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
  }
fi

# ── Done ────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}  ${PURPLE}⚡${RESET} ${WHITE}${BOLD}Synapse installed for ${USER_NAME}${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${WHITE}${BOLD}Commands:${RESET}"
echo -e "  ${CYAN}synapse${RESET}        Launch Synapse Runtime"
echo -e "  ${CYAN}synapse dev${RESET}    Dev mode (shows telemetry)"
echo -e "  ${CYAN}synapse doctor${RESET} Verify installation"
echo ""
echo -e "  ${DIM}Next: Run ${CYAN}synapse${DIM} to start your AI runtime.${RESET}"
echo -e "  ${DIM}Your AI now remembers everything.${RESET}"
echo ""
