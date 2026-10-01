#!/bin/bash
# SessionStart hook: put the plugin's agent-chrome on PATH as
# ~/.local/bin/agent-chrome. The plugin cache path changes on each plugin
# update, so the link is refreshed every session. A real file at that path
# (not a link) is the user's own copy and stays untouched.
# macOS only: agent-chrome uses osascript and the Keychain.
# Fails open: any error exits 0 with no output.

[ "$(uname -s)" = "Darwin" ] || exit 0
root="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}}"
src="$root/bin/agent-chrome"
dest="$HOME/.local/bin/agent-chrome"
[ -x "$src" ] || exit 0
if [ -e "$dest" ] && [ ! -L "$dest" ]; then
  exit 0
fi
mkdir -p "$HOME/.local/bin" 2>/dev/null && ln -sfn "$src" "$dest" 2>/dev/null
exit 0
