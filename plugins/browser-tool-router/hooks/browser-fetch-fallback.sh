#!/bin/bash
# PostToolUse + PostToolUseFailure hook (WebFetch matcher): when a fetch is
# refused in a way that usually means agent blocking (401/403/429/5xx, bot
# wall, timeout), tell the agent to retry in a browser before it gives up.
# This reaches subagents too, which rarely load the browser-tool-router skill
# on their own.
# Fails open — any error leaves the tool result untouched.

HOOK_INPUT="$(cat)" python3 <<'PYEOF' 2>/dev/null || exit 0
import json, os, re, sys

try:
    data = json.loads(os.environ.get("HOOK_INPUT", ""))
except Exception:
    sys.exit(0)

event = data.get("hook_event_name", "")
if event not in ("PostToolUse", "PostToolUseFailure"):
    sys.exit(0)

# The result/error field name differs by event and version.
response = None
for key in ("tool_response", "tool_result", "error", "tool_error"):
    if data.get(key) is not None:
        response = data[key]
        break
result = response if isinstance(response, str) else json.dumps(response)
# A refusal is short. A long successful page that only mentions these words
# (docs about HTTP codes, CAPTCHAs) is not one.
if event == "PostToolUse" and len(result) > 2500:
    sys.exit(0)

BLOCKED = [
    r"\bHTTP (401|403|429|5\d\d)\b",
    r"\bstatus code (401|403|429|5\d\d)\b",
    r"\b(403 Forbidden|429 Too Many Requests|503 Service Unavailable)\b",
    r"Just a moment\.\.\.",
    r"Attention Required",
    r"verify(ing)? (that )?you are (a )?human",
    r"enable JavaScript and cookies",
    r"\b(captcha|cf-chl|Access Denied)\b",
    r"\b(timed out|ETIMEDOUT|ECONNRESET)\b",
]
if not any(re.search(p, result, re.IGNORECASE) for p in BLOCKED):
    sys.exit(0)

url = str((data.get("tool_input") or {}).get("url", ""))[:300]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": event,
        "additionalContext": (
            f"browser-tool-router: the fetch of {url} was refused or blocked. This is "
            "often agent blocking, not a dead page. Do not report the page as "
            "unreachable yet. Retry in a browser, in this order: "
            "(1) headless: `playwright-cli -s=<name> open <url>`, then `snapshot`, then "
            "`playwright-cli -s=<name> close`. "
            "(2) if that is also blocked, the user's real Chrome: `agent-chrome attach "
            "<name>-chrome`, `playwright-cli -s=<name>-chrome goto <url>`, `snapshot`, "
            "then `agent-chrome release <name>-chrome`. It runs in the background; do "
            "not use `agent-chrome focus` for reading. Use a session name that is "
            "unique to you. Load the browser-tool-router skill for the full rules."
        ),
    }
}))
sys.exit(0)
PYEOF
