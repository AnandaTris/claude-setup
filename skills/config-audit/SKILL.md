---
name: config-audit
description: Use when asked to audit, trim, or optimise this Claude Code setup — context cost, skill bloat, duplicated boilerplate, plugins worth disabling. Measures with a script; never estimates by eye.
---

# Config audit

Answers one question: **what is this install costing in context, and what can go?**

## Run it

```bash
python3 ~/.claude/skills/config-audit/audit.py          # report
python3 ~/.claude/skills/config-audit/audit.py --json   # for further analysis
```

Run the script. Do not eyeball file sizes and report a guess — the whole point
of this skill is that the numbers are measured. Token figures are chars/4
estimates, accurate enough to rank things and not accurate enough to quote as
billing. Say so when you report them.

## Reading the output

Two buckets, and conflating them is the classic mistake:

**Always-on** is paid in every session before the user types anything: CLAUDE.md,
the memory index, and the name+description line of every skill, agent and
command. A 40-word description on a skill invoked twice a year is pure tax.
MCP tool schemas land here too and the script cannot see them — a connected
server with 30 tools is roughly 10-20k tokens the report does not show.

**On-demand** is the body of a skill, paid only on invocation. A 2,000-line
skill is not a problem if it earns its keep when called. Never recommend
deleting something for being long; recommend it for being long *and* unused.

## Classify before recommending

For anything the report flags, place it in one of three buckets — ECC's
context-budget framing, which is the one genuinely good idea in that repo:

- **Always needed** — leave it alone, even if it is expensive.
- **Sometimes needed** — the body can move to `references/` files the skill
  loads on demand; the description should shrink to one line.
- **Rarely needed** — a candidate for disabling. Plugins toggle with
  `~/.claude/bin/plugin-toggle <name> <on|off>`.

## Rules

- **Measure before claiming.** Every number in your report comes from the
  script or from a command you ran. No invented percentages.
- **Check usage before recommending removal.** "Large" is not "wasteful." Grep
  the transcripts in `~/.claude/projects/*/` for a skill's name before calling
  it dead weight.
- **Never modify anything as part of an audit.** Report and recommend. The
  user decides what goes. Changing config is a separate, explicit request.
- **Do not touch `~/.claude/sync/`-owned files.** `sync.sh` owns CLAUDE.md,
  AGENTS.md and the hook symlinks; edits there get overwritten on the next
  `sync.sh apply`. Recommend changes to the templates instead.
- **Zero findings is a valid result.** If the setup is within budget and
  nothing is obviously dead, say that and stop.

## Reporting

Lead with the always-on total against the budget, because that is the number
that affects every session. Then the top three concrete changes, each with the
tokens it saves and what it costs the user in capability. Skip anything that
saves under ~200 always-on tokens; it is not worth the churn.
