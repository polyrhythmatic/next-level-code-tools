#!/bin/bash
# PreToolUse hook (Bash matcher): one nudge per session to load the
# browser-tool-router skill before driving a browser from raw bash.
# Fails open — any error lets the tool call through untouched.

# Read stdin before the heredoc steals it.
HOOK_INPUT="$(cat)" python3 <<'PYEOF' 2>/dev/null || exit 0
import json, os, re, sys

try:
    data = json.loads(os.environ.get("HOOK_INPUT", ""))
    cmd = data.get("tool_input", {}).get("command", "") or ""
    session = re.sub(r"[^A-Za-z0-9-]", "", str(data.get("session_id", ""))) or "nosession"
except Exception:
    sys.exit(0)

# Real invocation patterns only — audits showed naive substring matching
# over-fires on find/grep commands that merely mention browser tooling
# (e.g. excluding a .playwright-cli/ directory).
PATTERNS = [
    r"(?<!\.)\bplaywright-cli\b",   # the CLI, not the .playwright-cli dir
    r"\bnpx\s+playwright\b",
    r"\b(npm|pnpm|yarn|bun)\s+(add|install|i)\b.*\bplaywright",
    r"\b(chromium|firefox|webkit)\.launch\b",
    r"\bpuppeteer\b",
    r"--remote-debugging-port",
    r"\bchrome-devtools\s+(start|navigate|new_page|lighthouse|performance)",
    r"\bagent-chrome\b",
    r"\bagent-browser\b",
    r"osascript.*tell\s+app(lication)?\s+\"(Google Chrome|Chromium|Safari|Arc|Brave Browser)\"",
]

if not any(re.search(p, cmd) for p in PATTERNS):
    sys.exit(0)

# Map a subagent to the real-Chrome sessions it attaches, so the SubagentStop
# hook (browser-session-cleanup.sh) can release them if the subagent does not.
# The default name mirrors agent-chrome's default_session.
agent_id = re.sub(r"[^A-Za-z0-9._-]", "", str(data.get("agent_id", "") or ""))
if agent_id:
    try:
        default_name = "cc-%s-chrome" % str(data.get("session_id", ""))[:8]
        names = [
            m.group(1) or default_name
            for m in re.finditer(r"\bagent-chrome\s+attach(?:[ \t]+([A-Za-z0-9._-]+))?", cmd)
        ]
        if names:
            state = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
            agents_dir = os.path.join(state, "agent-chrome", "agents")
            os.makedirs(agents_dir, exist_ok=True)
            with open(os.path.join(agents_dir, agent_id), "a") as f:
                f.write("".join(n + "\n" for n in names))
    except Exception:
        pass

sentinel = os.path.join(
    os.environ.get("TMPDIR", "/tmp"),
    f"claude-browser-router-nudge-{session}",
)
if os.path.exists(sentinel):
    sys.exit(0)
try:
    open(sentinel, "w").close()
except Exception:
    sys.exit(0)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": (
            "browser-tool-router: this looks like browser automation. Load the "
            "browser-tool-router skill first to pick the mechanism and "
            "its rules (background by default, focus only for user input, session "
            "naming, cleanup, bot-wall/auth gating). If you have already routed, "
            "just re-run this exact command — this reminder fires once per session."
        ),
    }
}))
sys.exit(0)
PYEOF
