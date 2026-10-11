# Claude Code — Revision Notes (Full Course)

18 lessons, built and tested live in this project. Terse by design — this is
for jogging memory, not re-teaching from scratch.

---

## 1. CLAUDE.md
Plain markdown file, project root. Auto-loads **once, at session start** —
not mid-session, not auto-created (needs `/init` or manual write).
Different from Claude's cross-session **memory** (automatic, private, not
shared via git — CLAUDE.md is explicit, shared, in your repo).
**Demo:** `lesson-01-claudemd/` — 3 house rules (British spelling,
`# PURPOSE:` comments, no f-strings), followed with zero in-chat mention.

## 2. Subagents
Separate Claude, fresh context, does messy work, returns only a clean
summary. **Parallel** = multiple `Agent` calls same message. **Sequential**
= wait for result, decide next call from it (no special mode, just timing).
Can nest (subagents spawning subagents).
**HITL pattern:** strongest safety = *missing tool*, not "please ask" (e.g.
reviewer with no Edit tool — can't break things, not "won't").
**Frontmatter:** `tools`, `disallowedTools`, `permissionMode`, `model`.
⚠️ **Real verified bug** (GitHub #94202, #82259, SDK #172, Sept 2026):
`disallowedTools`/`tools`/`permissionMode` are **advisory, not enforced**,
especially via `claude --agent <name>` direct launch vs. delegated. Don't
trust subagent frontmatter for real security — use a hook.
**Invocation:** auto (description match) · name it · `@agent-X` ·
`claude --agent X`.
**Demo:** `.claude/agents/pr-reviewer.md` (Read/Grep/Glob only).

## 3. Skills
Reusable recipe loaded **inline** into current conversation (not isolated
like a subagent — everything stays visible).
**Skill vs Subagent test:** *"Want to watch it happen, or just get the
answer?"* Watch/approve steps → skill. Clean verdict only → subagent.
Location: `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/`
(personal). `description` field = the trigger logic. Can declare
`context: fork` to run itself as an isolated subagent instead.
Invocation: auto · name it · `/skill-name`.
Reload: docs claim live, **did not work live in practice** this session —
needed fresh registry sync (trust but verify, even against docs).
**Demo:** `.claude/skills/bugfix-log/SKILL.md`.
**Real example studied:** `asana-self-task` — draft→show→wait-for-yes
checkpoint baked into its own prose, not a mechanism.

### Scheduling detour
| | Cloud Routines | Desktop tasks | `/loop` |
|---|---|---|---|
| Needs machine on | No | Yes | Yes |
| Needs open session | No | No | **Yes** |
| Survives laptop sleep | **Yes** | No | No |
Rule: asleep/unattended → cloud routine. Actively working → `/loop`.

## 4. Hooks — the one mechanism that's actually enforced
Shell command the **harness** runs, not something Claude can skip/argue
with. Configured in `.claude/settings.json`. Script gets JSON on stdin,
signals via exit code (0 = ok, 2 = block + stderr shown) or JSON stdout.

| Event | Fires | We built |
|---|---|---|
| **PreToolUse** | before a tool runs — can prevent it | `protect-guard.sh`: blocked edits to `session_guard.py`, file never touched |
| **PostToolUse** | after — too late to undo, can flag | `check-python.sh`: syntax-checks after every edit |
| **Stop** | Claude tries to end turn — can refuse | `check-py-syntax.sh`: wouldn't let me finish while any `.py` was broken (tested live — it worked) |
| **Notification** | permission prompt / ~60s idle | macOS `osascript` desktop notification (inline command, no script file) |
| **SessionStart** | `startup\|resume\|clear\|compact\|fork` — broader than "new session" | `session-init.sh`: briefs Claude on project state every start/resume/clear |

**Big three priority:** PreToolUse (block catastrophic) → PostToolUse
(auto-clean every edit) → Stop (don't claim "done" until provably true).
**The big unlock:** write a deterministic check (tests pass? compiles?),
wire as Stop hook → Claude is *mechanically unable* to stop until true.
Real TDD-for-agents. Safety valve: ~8 failed blocks in a row → harness
gives up (community-reported, not official).
**Notification channels reality:** no native Slack/Teams/WhatsApp — only
desktop (osascript/notify-send) is native. Everything else = your own
`curl` to a webhook. Don't confuse with **Channels** (separate feature,
inbound-only, Lesson 16).

### Real-world usage (hooks / subagents / skills)
**Hooks, in priority order:** PreToolUse (block rm -rf/force-push) →
PostToolUse (auto-lint/format/test) → Stop (verification gate). Rest
(Notification, PermissionRequest, SubagentStop, SessionEnd, PreCompact,
UserPromptSubmit) are real but niche.
**Subagents professionals build:** Code Reviewer (most common, often split
into 2-3 parallel specialists) → Test Writer → Debugger. Then: Security
Auditor, Documentation Maintainer, Linter runner. Built-in freebies:
`Explore`, `Plan`, `general-purpose`.
**Skills professionals build:** commit-message formatting, changelogs,
session-handoff summaries — all confirmed via Anthropic's own bundled set
(`code-review`, `simplify`, `write-readme`, `architecture-doc` etc. all
present in this session). Core test: skill-worthy = deterministic template
filling, not novel reasoning.

## 5. MCP Servers
Bridge to systems outside the project (Slack, DBs, live APIs) — "USB-C for
AI." `claude mcp add <name> -- <command>` (stdio) or `--transport http/sse`.
**Scopes:** `local` (default, private, `~/.claude.json`, this project only)
· `project` (`.mcp.json` in repo root, git-shared with team) · `user`
(`~/.claude.json`, all your projects). Tools appear as `mcp__server__tool`.
**Demo:** added official test server `@modelcontextprotocol/server-everything`
(local→then redone as project scope so `.mcp.json` became visible). Needed
fresh session for tools to register — same "needs restart" pattern as
subagents/skills.
**Verify:** `claude mcp list`, `claude mcp get <name>`, `/mcp` in-session.

## 6. Git Worktrees
Separate physical folder, same repo history, own branch — total isolation
for risky agent work (vs. subagent isolation = logical/context-level, vs.
hooks = action-level). `EnterWorktree`/`ExitWorktree` tools — **only on
explicit user instruction**, never self-triggered. Needs an actual git
repo (or WorktreeCreate/WorktreeRemove hooks). This project never got one
(stayed conceptual).

## 7. Background Tasks & Monitor
**`run_in_background: true`** on Bash = one notification when it finishes.
**Monitor tool** = recurring notifications, one per matched event, while
staying unblocked. Monitor filter must cover *every* outcome (success +
failure), not just the happy path — else silence looks like "still fine."
**Demo:** fake 15s "build" (run_in_background, one completion ping) +
fake server log (Monitor + `grep -E "INFO|ERROR"`, got 3 separate events:
batch of INFOs, the ERROR flagged alone, final recovery INFO).

## 8. Claude in Chrome
Real browser control — separate sandboxed tab group, not your regular
tabs. `tabs_context_mcp` first, always. `browser_batch` for multi-step
sequences. Never trigger JS alerts/dialogs (freezes the extension). Clean
up tabs you open. File uploads only work for paths the session can
already read (`/add-dir` needed otherwise — tested: Desktop file rejected,
in-project `NOTES.md` worked).
**Real demos:** queried Gemini twice (self-description + "what do you know
about me" — pulled real chat history), proving the mechanism works
end-to-end on a live, real site, not just a sandbox page.

## 9. Headless Mode
`claude -p "prompt"` — no chat UI, runs once, exits. **Not a scheduler** —
needs something else to trigger it (you, manually; cron; a git hook; CI).
Headless = HOW (no human present); cron/CI = WHEN. `--permission-mode
dontAsk` is critical — without it, a run needing approval just **hangs
forever** (nobody there to answer). `--max-turns`/`--max-budget-usd` as
circuit breakers. `--output-format json` → `jq -r '.result'`.
**Sleep/laptop rule:** if it runs as a local process (your cron, your
`/loop`), laptop asleep = it does not run. Only cloud-hosted execution
(GitHub Actions, Cloud Routines) survives your laptop being off.
**HITL moved, not removed:** human constrains *before* the run (tools,
permission mode, turn limits), not *during* it.
**Demo:** real `claude -p` run, Glob-only, counted lesson folders
correctly (4), `permission_denials: []`, cost `$0.087`.

## 10. Statusline
Live info bar, your choice of fields (model, cost, git branch, context %,
rate limits...). `.claude/settings.json` → `statusLine: {type: "command",
command: "..."}`. Script gets JSON on stdin, prints to stdout. Applies
live (no restart) — contrast with CLAUDE.md/subagents/skills.
**Demo:** `.claude/statusline.sh` — model + running cost + git status (always
"no git repo" here, which is itself the point).
**Vim mode aside:** `vim.mode` field only matters if you've turned on
`/vim` keybindings for the prompt — irrelevant otherwise.

## 11. Mods (Plugin Authoring)
Change Claude Code's own **UI**, not just behavior — panes, toasts, bands
above prompt, custom slash commands, status entries. Written as TS/JSX
hook modules in `~/.claude/dev-mods/<session-id>/<mod-name>/` (three files:
`.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/register.tsx`).
First file written triggers a real "enable hot reloading?" prompt — **only
the user can answer it**, no permission mode bypasses it.
`claude plugin validate <dir>` catches errors before runtime.
Honest ranking: **least-used of everything covered** — hooks/skills cover
most daily needs; mods are for genuine custom UI or distributable plugins
(`/plugin install` + `marketplace.json`).
**Demos built:**
- `lesson-hello` — `/lesson-hello` slash command → `$.ui.toast(...)`.
- `spider-indicator` — `$.clock.every()` persistent timer + `$.state`
  atoms, spider crawls in the `AbovePrompt` band only while `isRunning`
  (set by `prompt.submit`/`turn.complete`). Caught two real bugs myself
  mid-build (wrong session-id folder typo; stray `export {}` broke the
  type contract) — fixed via `claude plugin validate`.
- **Known limit:** `position: absolute` is clipped to its own component's
  site (band/pane/viewport) — can't float freely to a screen corner.
  AbovePrompt is bottom-anchored; true "top-right" would need a
  right-docked Pane instead (bigger UI commitment, didn't rebuild it).
- Live 2-min demo blocked by Claude Code's own built-in anti-idle guard
  (refuses bare `sleep 120`) — even mods are bounded by harness-level
  guardrails.

## 12. Output Styles
Changes **how** I communicate by default — a system-prompt-level swap, not
a CLAUDE.md note. Built-ins: **Default**, **Proactive** (acts immediately,
reasonable calls on routine stuff), **Concise** (result-first, no
preamble), **Explanatory** (adds "Insight" asides), **Learning** (leaves
`TODO(human)` markers). `/output-style <name>`.
**Key distinction:** a custom style can *drop* Claude Code's own built-in
coding instructions entirely unless `keep-coding-instructions: true` is
set. CLAUDE.md always stays loaded regardless of style — style = personality,
CLAUDE.md = project facts. Still advisory, not enforced (hooks are for
"must always happen").
Custom: `.claude/output-styles/*.md`, frontmatter + body.

## 13. Context Management & Compaction
Auto-compaction: clears old tool outputs first, *then* summarizes if still
needed — not a reset. Survives: CLAUDE.md, system prompt, memory, 5 most
recent files (>5K tokens → path ref only), invoked skills (capped 5K
tokens each). **Does NOT survive:** nested/path-scoped CLAUDE.md files
loaded mid-session (root CLAUDE.md only).
`/compact [instructions]` (steer it) vs `/clear` (discard, don't confuse
the two) vs `/rewind` → "Summarize from/up to here" (partial compact).
`PreCompact` hook can only **block** (exit 2) or log — not steer content.
**Beyond summarizing — prevent the bloat instead:** delegate to subagents
(content never arrives at all, strictly better than summarizing later) ·
`/clear` between unrelated tasks · keep CLAUDE.md minimal, use skills
(on-demand load) · `/btw` for asides that shouldn't enter history at all ·
headless mode for one-offs (zero accumulated history by definition).

## 14. Effort Levels & Fast Mode
**Three separate controls**, often confused:
1. **Effort** (`low/medium/high/xhigh`) — how much reasoning per step.
   Real quality/speed tradeoff. `/effort high`, `--effort`, subagent
   frontmatter `effort:`, or `ultrathink` in-prompt for one turn only.
2. **Fast mode** — Opus only, same model/quality, **2.5x faster for
   higher $/token** (NOT less thinking — I guessed wrong, docs corrected
   it). `/fast` toggle.
3. **Extended thinking on/off** — separate toggle (`Option+T`/`Alt+T`),
   independent of how deep each step reasons.
Precedence: env var > per-invocation > subagent frontmatter > session >
model default.

## 15. Checkpointing & /rewind
Checkpoint = file-edit snapshot, created **before every prompt that starts
a turn** (not per-edit/per-tool-call). `/rewind` (or double-`Esc` on empty
prompt) → pick a past prompt → Restore code / conversation / both /
Summarize from-or-up-to-here.
**Does NOT track:** Bash-run file changes (`rm`/`mv`/`cp` invisible to
it), most subagent edits, symlinks. Explicitly "not a replacement for
version control." Cap: 100 checkpoints/session, ~30-day retention
(`cleanupPeriodDays`).
**Configurable:** only on/off (`CLAUDE_CODE_DISABLE_FILE_CHECKPOINTING`)
and retention time. **NOT configurable:** frequency/granularity, the
100-cap — it's deliberately simple, not tunable like hooks.
**Live-tested, resolved a real doc gap:** confirmed working in this
project despite **zero git history** — genuine proof, not assumed.
Storage location undocumented; searched `~/.claude` for it, found no
dedicated snapshot folder — most likely reconstructed from the session's
own `.jsonl` transcript (inference, not confirmed).

## 16. Channels
MCP server with a **push** capability (vs normal MCP = pull-only) —
external events land inside an **already-open** session; doesn't start a
new one, and only works while that session stays open. Shipped:
**Telegram, Discord, iMessage** (macOS-only, reads chat.db + AppleScript),
**fakechat** (local test demo). `/plugin install <x>@claude-plugins-official`
then `claude --channels plugin:<x>`.
Two-way channels expose a `reply` tool. ⚠️ Anthropic's own docs call an
ungated channel "a prompt injection vector" — the only protection is a
sender allowlist. A channel can even relay permission-approval prompts to
your phone — whoever can reply can approve real actions.
Research preview; off by default on Team/Enterprise (Owner must enable).

## 17. Claude Projects
**Not a CLI feature** — lives only at claude.ai/code + mobile apps.
One coordinator conversation that spawns parallel worker **threads** (each
a real cloud session, own branch/clone/PR) for an ongoing multi-piece
goal. Different from classic claude.ai Projects (no coordinator/threads
there, just grouped files). A routine created inside a project runs as
threads there; a routine can also exist fully standalone.
Use for: one goal across many repos, an ongoing bug/review feed, a
migration too big for one session. NOT for a single task (use a session)
or single repeating task with no conversation (use a standalone routine).
Beta: Pro/Max only, 200 threads/day cap, not shareable yet.

## 18. Agent SDK
Same engine as the CLI, packaged as a library (Python `claude-agent-sdk`,
TS `@anthropic-ai/claude-agent-sdk`) — spawns the real `claude` binary as
a subprocess. **Not a simplified model** — hooks, subagents, permission
modes, MCP all carry over with the same vocabulary, just programmatic.
Minimal shape: `query(prompt=..., options=ClaudeAgentOptions(...))`,
iterate messages, grab the final `ResultMessage`.
**Structured JSON output:** `output_format={"type": "json_schema",
"schema": {...}}` on options → validated result in
`message.structured_output` (auto re-prompts on mismatch).
**Internal subagents:** `agents={"name": AgentDefinition(...)}` on
options — the SDK-driven agent can delegate to its own subagents mid-task,
same as the CLI's `Agent` tool.
**When to use which:** interactive terminal → CLI. One-off script/CI →
headless `-p`. Your own hosted product embedding a full agent → SDK. Fully
custom tools, no built-in file/Bash tools wanted → raw Messages API.
**Real use case worked through:** wrapping Claude Code as a LangGraph
node — `allowed_tools=["WebSearch","Edit","Write"]` +
`permission_mode="acceptEdits"` + `output_format` schema = one node that
autonomously researches/edits/returns clean JSON for the graph to route
on. Caveat: `allowed_tools` auto-approves, doesn't *restrict* — use `tools`
for an actual allowlist. Branding rule: can't call your product "Claude
Code."

---

## Where everything lives

```
claude_code/
├── NOTES.md
├── lesson-01-claudemd/          CLAUDE.md house-rules demo
├── lesson-02-subagents/         fake codebase (auth bug, billing bug, dead code)
├── lesson-04-hooks/             broken.py, used to test hooks live
├── lesson-07-background/        fake build + fake server log
├── lesson-15-rewind/            demo.py, version 1 → 2 → rewound live
└── .claude/
    ├── settings.json             all 5 hooks + statusLine registered
    ├── statusline.sh
    ├── hooks/                    protect-guard.sh, check-python.sh,
    │                             check-py-syntax.sh, session-init.sh
    ├── agents/pr-reviewer.md
    └── skills/bugfix-log/SKILL.md
.mcp.json                         @modelcontextprotocol/server-everything (project scope)
~/.claude/dev-mods/<session-id>/
    ├── lesson-hello/              /lesson-hello → toast
    └── spider-indicator/          crawling spider, AbovePrompt band
```

## The real bug found and verified this course
**Subagent permission bypass** — GitHub anthropics/claude-code #94202,
#82259, SDK #172. `disallowedTools`/`permissionMode` not enforced,
especially via `--agent` direct launch.
