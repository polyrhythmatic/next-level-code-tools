---
name: browser-tool-router
description: >-
  Pick the browser mechanism before touching a browser. Use whenever a task
  involves browser automation, web app QA, screenshots, forms, clicking or
  filling pages, login or auth-gated sites, bot walls
  (Cloudflare/Akamai/CAPTCHA), scraping or reading web pages, file downloads
  from websites, web profiling, Lighthouse, Core Web Vitals, console or network
  debugging, the user's own logged-in browser, or a failed WebFetch/curl (401,
  403, 429, 5xx, timeout, empty or challenge page). Also use when about to
  hand-write a Playwright/puppeteer script or drive a browser from raw bash.
---
# Browser Tool Router

Policy only. Command syntax comes from the tools themselves:
`playwright-cli --help <command>`, `agent-chrome --help`, and
`chrome-devtools <command> --help`. Check `--help` before any unfamiliar
command.

## Setup check

If `playwright-cli` is not on PATH, or `~/.playwright/cli.config.json` does
not exist, run `scripts/setup.sh` from this plugin (two folders up from this
SKILL.md: `../../scripts/setup.sh`). Show its output to the user. Do not
create the Playwright Extension token for the user; the script tells them how.

## Which mechanism

1. **No browser if you can avoid it.** Static pages, docs, APIs, and files:
   use WebFetch, curl, or the service's CLI/API.
2. **A refused fetch is not a dead page.** On 401, 403, 429, 5xx, a timeout, or
   a challenge/empty page, the cause is usually agent blocking. Do not report
   the page as unreachable. Go to step 3; if that is also blocked, go to step 4.
   When you delegate research to a subagent, put this rule in its brief.
3. **Default: `playwright-cli`.** Its global config launches Chrome for Testing,
   a separate app that cannot take over the user's Chrome. It runs headless.
   Pass `--headed` to `open` only when the user asks to watch.
4. **User's logins or a bot wall: `agent-chrome attach <session>`.** It connects
   playwright-cli to the user's real Chrome through the Playwright Extension, in
   its own tab group, in the background. macOS only. On other systems, or if
   the extension is not set up, ask the user to open the page and give you the
   content.
5. **Performance, Lighthouse, memory: `chrome-devtools`.** Always
   `--isolated --executablePath "$(agent-chrome cft-path)"`.
6. **Never launch Google Chrome.app for automation**, and never
   `open -a "Google Chrome"`. Show URLs to the user with plain `open <url>`.

## Focus: the user's screen is theirs

- All work runs in the background: reading, navigation, filling a form,
  screenshots. Do not bring a browser to the front for these.
- Bring the page to the front only when the user must act on it (login,
  CAPTCHA, payment, a final Submit, a choice only they can make):
  `agent-chrome focus <session>`, then tell the user what to do. Do it one
  time, when the page is ready, not at each step.
- In the real Chrome, these steal focus or change the tab the user has in
  view: a second `agent-chrome attach`, `tab-new`, `tab-select`. Thus: attach
  one time per session (attach reuses a live session), keep one tab per
  session, and navigate it with `goto`.
- Run all commands of a session from the directory where you opened or
  attached it. playwright-cli keys sessions by workspace; from a different
  directory the session looks absent. Do not attach again; go back.

## Sessions and cleanup

- Give each session a name that is unique to you: `-s=<task>` for launched
  browsers, `agent-chrome attach <task>-chrome` for the real Chrome. Parallel
  agents must not share a session.
- Close what you open, before your final answer, also when the task fails:
  - launched: `playwright-cli -s=<session> close`
  - real Chrome: `agent-chrome release <session>`. It closes the tabs your
    session opened and detaches. Chrome and the user's tabs stay open. Do not
    use `close` or plain `detach` on an attached session; `detach` leaves
    your tabs open.
  - the user still needs the page after you finish (for example to submit):
    `agent-chrome handoff <session>`. It shows the tab and leaves it open.
- Hooks release forgotten real-Chrome sessions when a subagent or the agent
  session ends. They are a safety net, not the procedure.

## Always

- **Reserved for the user:** passwords, CAPTCHAs, account creation, payments,
  and any consequential Submit.
- **Verify every state change independently** (snapshot, screenshot, or file
  on disk). A tool's own success message is not proof.

Repo memory: if `<repo>/.claude/browser-domains.md` exists, read it first; after
a notable success or failure against a site, append
`- <domain>: <YYYY-MM-DD> <mechanism> <worked|failed> — <why>`.
