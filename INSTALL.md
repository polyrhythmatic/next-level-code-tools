# Install instructions for coding agents

You are Claude Code or Codex. The user asked you to install the
`browser-tool-router` plugin from this repo. Do these steps in order. Show the
user the output of each step. The repo is `polyrhythmatic/next-level-code-tools`.

## 1. Install the plugin

Claude Code:

```bash
claude plugin marketplace add polyrhythmatic/next-level-code-tools
claude plugin install browser-tool-router@next-level-code-tools
```

Codex (CLI or the ChatGPT desktop app; both use `~/.codex`):

```bash
codex plugin marketplace add polyrhythmatic/next-level-code-tools
codex plugin add browser-tool-router@next-level-code-tools
```

If the user uses both apps, do both.

## 2. Run the setup script

The script installs `playwright-cli`, `chrome-devtools`, and Chrome for
Testing, and writes `~/.playwright/cli.config.json` if it is missing. It needs
Node.js. It does not overwrite existing files.

Find the installed copy and run it:

```bash
bash "$(find ~/.claude/plugins ~/.codex/plugins -path '*browser-tool-router*/scripts/setup.sh' 2>/dev/null | head -1)"
```

If network access or global npm installs are blocked in your sandbox, ask the
user to approve the command, or to run it with `!` (Claude Code).

## 3. Tell the user what is left

- Restart the app so it loads the plugin's skill and hooks.
- Codex only: run `/hooks` and trust the browser-tool-router hooks. Codex does
  not run plugin hooks until the user trusts them.
- Optional, macOS only: the `[todo]` lines from the setup script for the
  Playwright Extension. The user does these steps. Do not ask for the token
  and do not handle it.

## Uninstall

```bash
claude plugin uninstall browser-tool-router@next-level-code-tools
codex plugin remove browser-tool-router@next-level-code-tools
rm -f ~/.local/bin/agent-chrome   # only if it is a link
```
