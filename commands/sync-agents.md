---
description: Regenerate CLAUDE.md and AGENTS.md from the shared template and report config drift
---

Bring the Claude Code and Codex configs back into sync.

Run the check first, so you know what was actually wrong:

```bash
sh ~/.claude/sync/sync.sh --check
```

Then regenerate and re-link:

```bash
sh ~/.claude/sync/sync.sh apply
```

Confirm it took:

```bash
sh ~/.claude/sync/sync.sh --check && sh ~/.claude/sync/test-sync.sh
```

## What this owns

`apply` rewrites `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` from
`sync/core.md` + `sync/overlay.<host>.md`, and symlinks the shared skills into
Codex. **Those two files are generated — never edit them directly.** Edit the
source instead:

- shared rules → `~/.claude/sync/core.md`
- Claude-only rules → `~/.claude/sync/overlay.claude.md`
- Codex-only rules → `~/.claude/sync/overlay.codex.md`
- per-host wording (`{{REVIEW}}`, `{{OTHER}}`, …) → `~/.claude/sync/vars.claude` / `vars.codex`

If `--check` reports a `GAP` on `CLAUDE.md` or `AGENTS.md`, someone hand-edited a
generated file. Move that edit into the right source file above before running
`apply`, or `apply` will discard it. Recover the lost text with
`git -C ~/.claude diff` before regenerating.

## Versioned Codex config

`~/.codex` is not a git repo, so the hand-authored parts live in `~/.claude/sync/codex/`
and are versioned there:

- `hooks.json` — the real file; `~/.codex/hooks.json` is a symlink to it. Edit either.
- `config.settings.toml` — a read-only snapshot of the scalar settings in
  `~/.codex/config.toml` (model, effort, approval policy, sandbox mode).

If `--check` says a codex setting drifted, Ado changed it in Codex. That is normal.
Update the snapshot to match if the change was intentional — **never write to
`config.toml`**, which Codex rewrites itself as projects get trusted.

## What this only reports

`settings.json` and `~/.codex/config.toml` have different vendor schemas and are
partly machine-written, so sync.sh audits them and never edits them. Acting on the
audit is your call — tell Ado what it found rather than silently changing them.

Never version `~/.codex/auth.json` (live OAuth tokens), `history.jsonl`, or any
`*.sqlite` — they are private session state, and two of those databases are
several hundred MB.
