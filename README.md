# Next Level Code tools

Agent plugins for the Next Level Code class. Each plugin works in Claude Code
and in Codex (CLI and the ChatGPT desktop app).

## browser-tool-router

Rules and helpers so your agent picks the right browser tool and stays off
your screen:

- No browser when a plain fetch works.
- Default: headless Chrome for Testing through `playwright-cli`. It is a
  separate app, so the agent cannot take over your own Chrome.
- Your real, logged-in Chrome only for logins and bot walls, in its own tab
  group, in the background (`agent-chrome`, macOS only).
- `chrome-devtools` for performance and Lighthouse.
- The agent closes what it opens. Hooks clean up when a session ends.

### Install

Paste this into Claude Code or Codex:

> Install the browser tool router from https://github.com/polyrhythmatic/next-level-code-tools.
> Follow INSTALL.md in that repo.

The agent installs the plugin and the tools, then tells you what is left
(restart the app; in Codex, trust the hooks with `/hooks`).

### What it changes on your computer

- Installs `@playwright/cli` and `chrome-devtools-mcp` with `npm install -g`.
- Downloads Chrome for Testing into the Playwright cache.
- Writes `~/.playwright/cli.config.json` if it does not exist.
- macOS: links `~/.local/bin/agent-chrome` to the plugin copy.

### Requirements

Node.js. macOS for real-Chrome access; the rest works on macOS, Linux, and
Windows (WSL or Git Bash, with Python 3 for the hooks).
