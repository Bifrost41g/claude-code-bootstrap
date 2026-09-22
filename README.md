# claude-code-bootstrap

One-command setup for a new Windows PC: base tools, Claude Code CLI, and this
user's synced Claude Code config (agents, settings, CLAUDE.md).

## Usage

Open PowerShell on the new PC and run:

```powershell
irm https://raw.githubusercontent.com/Bifrost41g/claude-code-bootstrap/main/bootstrap.ps1 | iex
```

You'll be prompted once for GitHub authentication when it fetches the private
[claude-code-config](https://github.com/Bifrost41g/claude-code-config) repo.

Safe to re-run at any time - every step is idempotent.

## What it does

1. Installs Git, Node.js LTS, VS Code, GitHub CLI, and Windows Terminal via `winget`.
2. Installs the Claude Code CLI (native installer, no Node/npm required for this step).
3. Checks out [claude-code-config](https://github.com/Bifrost41g/claude-code-config)
   into `~/.claude`, so only `settings.json`, `CLAUDE.md`, the curated `agents/`,
   `hooks/`, `setup/` and the self-written `skills/` are tracked - sessions,
   cache, credentials, and per-machine plugin state are never touched.
4. Installs the Impeccable design skill via `npx`. Only tools with their own
   installer belong here; the subagents ship inside the config repo from step 3.

## After running it

- Restart the terminal so newly installed programs are on `PATH`.
- Run `claude login` (also enables the official Anthropic-account skills/plugins sync).
- Run `gh auth login`.
- Run `& "$env:USERPROFILE\.claude\setup\projects.ps1"` to create the project
  folder structure and clone the project repos. Needs `gh auth login` first,
  and is safe to re-run.

From then on, Claude Code will ask at the start of a session whether to pull
config changes from another PC, and after a response whether to push local
config changes - both checks run silently and only ask when there's actually
something to sync.
