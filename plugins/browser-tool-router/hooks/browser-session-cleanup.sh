#!/bin/bash
# SessionEnd + SubagentStop hook: dispose of the browser sessions THIS Claude
# Code session (or this subagent) opened, and nothing else.
#
# Works in Claude Code and Codex: both send session_id, and SubagentStop
# sends agent_id.
#
# Real-Chrome sessions: `agent-chrome attach` records each session with its
# owner (CLAUDE_CODE_SESSION_ID or CODEX_SESSION_ID), and the
# browser-router-nudge hook maps subagent ids to the sessions they attach. `agent-chrome reap` closes the
# tabs those sessions opened and detaches; Chrome and the user's own tabs
# stay open. Sessions given to the user with `agent-chrome handoff` are no
# longer recorded, so their tabs stay.
#
# Launched (headless) sessions close themselves through the idle timeout in
# ~/.playwright/cli.config.json.
#
# The work runs detached so the hook returns inside the SessionEnd budget.
# Fails open: any error, missing binary, or unparsable input is swallowed.

HOOK_INPUT="$(cat)" python3 <<'PYEOF' 2>/dev/null || exit 0
import json, os, re, shutil, subprocess, sys

try:
    data = json.loads(os.environ.get("HOOK_INPUT", ""))
except Exception:
    sys.exit(0)

def clean(value):
    return re.sub(r"[^A-Za-z0-9._-]", "", str(value or ""))

def spawn(args):
    try:
        subprocess.Popen(
            args,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except Exception:
        pass

agent_chrome = shutil.which("agent-chrome") or os.path.expanduser("~/.local/bin/agent-chrome")
if not os.path.exists(agent_chrome):
    sys.exit(0)
event = data.get("hook_event_name", "")
session_id = clean(data.get("session_id"))
agent_id = clean(data.get("agent_id"))

if event == "SubagentStop":
    if agent_id:
        spawn([agent_chrome, "reap", "--agent", agent_id])
    sys.exit(0)

if not session_id:
    sys.exit(0)
spawn([agent_chrome, "reap", "--owner", session_id])
sys.exit(0)
PYEOF
