#!/bin/bash
# One-time setup for the browser-tool-router plugin. Safe to run again.
# An agent can run this; it never asks for input and never touches secrets.
#
#   1. Install playwright-cli and chrome-devtools (npm) if missing.
#   2. Install Chrome for Testing, the separate browser agents drive.
#   3. Write ~/.playwright/cli.config.json if it does not exist.
#   4. macOS: link agent-chrome into ~/.local/bin, then print the manual
#      steps for the Playwright Extension (real-Chrome access).

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$HOME/.playwright/cli.config.json"
ok() { printf '  [ok]   %s\n' "$*"; }
todo() { printf '  [todo] %s\n' "$*"; }
fail() { printf '  [fail] %s\n' "$*"; }

echo "browser-tool-router setup"

# 1. CLIs
if ! command -v npm >/dev/null 2>&1; then
  fail "npm not found. Install Node.js (https://nodejs.org), then run this again."
  exit 1
fi
for pair in "playwright-cli:@playwright/cli" "chrome-devtools:chrome-devtools-mcp"; do
  bin="${pair%%:*}" pkg="${pair#*:}"
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$bin is installed"
  elif npm install -g "$pkg@latest" >/dev/null 2>&1 && command -v "$bin" >/dev/null 2>&1; then
    ok "installed $bin ($pkg)"
  else
    fail "could not install $pkg. Run: npm install -g $pkg@latest"
  fi
done

# 2. Chrome for Testing
if command -v playwright-cli >/dev/null 2>&1; then
  if playwright-cli install-browser chrome-for-testing >/dev/null 2>&1; then
    ok "Chrome for Testing is installed"
  else
    fail "Chrome for Testing install failed. Run: playwright-cli install-browser chrome-for-testing"
  fi
fi

# 3. Config: headless Chrome for Testing, 30-minute idle timeout
if [ -f "$CONFIG" ]; then
  if cmp -s "$CONFIG" "$ROOT/config/cli.config.json"; then
    ok "$CONFIG is set"
  else
    todo "$CONFIG exists and differs from the plugin default. Not changed."
    echo "         Compare with: $ROOT/config/cli.config.json"
  fi
else
  mkdir -p "$(dirname "$CONFIG")" && cp "$ROOT/config/cli.config.json" "$CONFIG" \
    && ok "wrote $CONFIG" || fail "could not write $CONFIG"
fi

# 4. Real Chrome (macOS only)
if [ "$(uname -s)" != "Darwin" ]; then
  todo "real-Chrome access (agent-chrome) is macOS only; skipped"
  exit 0
fi
"$ROOT/hooks/link-agent-chrome.sh"
if command -v agent-chrome >/dev/null 2>&1; then
  ok "agent-chrome is on PATH"
elif [ -x "$HOME/.local/bin/agent-chrome" ]; then
  todo "agent-chrome is in ~/.local/bin, which is not on PATH. Add to ~/.zshrc:"
  echo '         export PATH="$HOME/.local/bin:$PATH"'
else
  fail "could not link agent-chrome into ~/.local/bin"
fi
if security find-generic-password -a "$USER" -s playwright-extension-token >/dev/null 2>&1; then
  ok "Playwright Extension token is in the Keychain"
else
  todo "optional, for logins and bot walls: connect your real Chrome"
  cat <<'STEPS'
         a. In Google Chrome, install the "Playwright Extension":
            https://chromewebstore.google.com/detail/mmlmfjhmonkocbjadbfplnigmagldckm
         b. Open the extension and copy its token.
         c. In a terminal, run this and paste the token when asked:
              security add-generic-password -a "$USER" -s playwright-extension-token -w
         Do these steps yourself. Do not give the token to an agent.
STEPS
fi
