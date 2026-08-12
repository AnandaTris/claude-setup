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

## What this only reports

`settings.json`, `~/.codex/config.toml`, and `~/.codex/hooks.json` have different
vendor schemas, so sync.sh audits them and never edits them. Acting on the audit
is your call — tell Ado what it found rather than silently changing those files.
