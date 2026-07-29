# Skill Guide: Download for Claude

Restore every Claude Code skill and plugin on a new machine. This file exists
because `~/.claude/skills/` is **393 MB** — too large for git — but the list of
*what to reinstall* is a few KB.

**Snapshot taken:** 30 July 2026 · **Machine:** macOS (Apple Silicon)
**Totals:** 4 plugins · 12 standalone skills · ~49 gstack skills · 3 Anthropic document skills

> **To update this file:** tell Claude *"update the skill guide"*. It re-reads
> `~/.agents/.skill-lock.json`, `~/.claude/plugins/installed_plugins.json`, and
> `~/.claude/skills/` and rewrites the tables below.

---

## Quick restore

Run in this order. Steps 1–2 are fast; step 3 is the slow one.

```bash
# 0. Prerequisites
brew install bun jq gh ffmpeg     # bun is required by gstack

# 1. Clone this config repo (brings back CLAUDE.md, settings, hooks, memory)
git clone git@github.com:AnandaTris/claude-setup.git ~/.claude

# 2. Standalone skills — see section 2
# 3. gstack — see section 3
# 4. Plugins — see section 4
```

Then restart Claude Code and run `/plugin` to confirm.

---

## 1. What is NOT in git (and why)

| Path | Size | Restore by |
|---|---|---|
| `skills/gstack/` | 389 MB | re-clone, section 3 |
| `plugins/` | 164 MB | reinstall, section 4 |
| `~/.agents/skills/` | 9.8 MB | `npx skills add`, section 2 |
| `skills/docx`, `pptx`, `xlsx` | 3.7 MB | section 5 |
| transcripts, caches, daemon logs | 620 MB | regenerated automatically |

Everything else — `CLAUDE.md`, `settings.json`, `settings.local.json`,
`hooks/`, `statusline-command.sh`, all 30 memory stores — **is** in the repo and
comes back with the clone.

---

## 2. Standalone skills (12)

Installed with the Skills CLI from [skills.sh](https://skills.sh). These live in
`~/.agents/skills/` and are symlinked into `~/.claude/skills/`. The machine-readable
source of truth is `~/.agents/.skill-lock.json`.

```bash
npx skills add vercel-labs/skills              # find-skills
npx skills add higgsfield-ai/skills            # higgsfield-generate, -soul-id, -video-explainer
npx skills add mattpocock/skills               # grill-me, grilling
npx skills add emilkowalski/skills             # emil-design-eng
npx skills add pbakaus/impeccable              # impeccable
npx skills add expo/skills                     # expo-native-ui, expo-router, expo-web-to-native
npx skills add callstackincubator/agent-skills # react-native-best-practices
```

Repos holding several skills will prompt for which ones — pick from this list:

| Skill | Source repo | Path in repo |
|---|---|---|
| `find-skills` | `vercel-labs/skills` | `skills/find-skills/` |
| `higgsfield-generate` | `higgsfield-ai/skills` | `higgsfield-generate/` |
| `higgsfield-soul-id` | `higgsfield-ai/skills` | `higgsfield-soul-id/` |
| `higgsfield-video-explainer` | `higgsfield-ai/skills` | `higgsfield-video-explainer/` |
| `grill-me` | `mattpocock/skills` | `skills/productivity/grill-me/` |
| `grilling` | `mattpocock/skills` | `skills/productivity/grilling/` |
| `emil-design-eng` | `emilkowalski/skills` | `skills/emil-design-eng/` |
| `impeccable` | `pbakaus/impeccable` | `.agents/skills/impeccable/` |
| `expo-native-ui` | `expo/skills` | `plugins/expo/skills/expo-native-ui/` |
| `expo-router` | `expo/skills` | `plugins/expo/skills/expo-router/` |
| `expo-web-to-native` | `expo/skills` | `plugins/expo/skills/expo-web-to-native/` |
| `react-native-best-practices` | `callstackincubator/agent-skills` | `skills/react-native-best-practices/` |

Afterwards: `npx skills check` to see updates, `npx skills update` to take them.

### Do not reinstall these

Present in the lock file but deliberately removed in the 29 July 2026 design-stack swap:

- ~~`design-taste-frontend`~~ (`Leonxlnx/taste-skill`) — replaced by `impeccable`
- ~~`figma-use`~~ (`figma/mcp-server-guide`) — replaced by the Figma MCP server

---

## 3. gstack (~49 skills, 389 MB)

One clone brings back the whole suite. Needs **Bun** on PATH.

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack \
  && cd ~/.claude/skills/gstack \
  && ./setup
```

`./setup` generates the individual skill directories in `~/.claude/skills/`.
Keep current with `/gstack-upgrade`.

<details>
<summary>Skills this provides (~49)</summary>

`_gstack-command`, `autoplan`, `benchmark`, `benchmark-models`, `browse`,
`canary`, `careful`, `codex`, `context-restore`, `context-save`, `cso`,
`devex-review`, `document-generate`, `document-release`, `freeze`,
`gstack-upgrade`, `guard`, `health`, `investigate`, `ios-clean`, `ios-fix`,
`ios-qa`, `ios-sync`, `land-and-deploy`, `landing-report`, `learn`, `make-pdf`,
`office-hours`, `open-gstack-browser`, `pair-agent`, `plan-ceo-review`,
`plan-devex-review`, `plan-eng-review`, `plan-tune`, `qa`, `qa-only`, `retro`,
`review`, `scrape`, `setup-browser-cookies`, `setup-deploy`, `setup-gbrain`,
`ship`, `skillify`, `spec`, `sync-gbrain`, `unfreeze`

</details>

**Note:** `CLAUDE.md` already contains the required gstack section (use `/browse`
for all web browsing, never `mcp__claude-in-chrome__*` directly). It restores
with the repo — no need to re-add it.

---

## 4. Plugins (4)

Marketplaces first, then the plugins. Use `/plugin` in Claude Code, or note that
`settings.json` already lists them under `enabledPlugins` and
`extraKnownMarketplaces`, so a clone plus restart may pull them automatically.

**Marketplaces:**

| Name | Source |
|---|---|
| `claude-plugins-official` | `anthropics/claude-plugins-official` |
| `superpowers-marketplace` | `obra/superpowers-marketplace` |

**Plugins:**

| Plugin | Marketplace | Version at snapshot |
|---|---|---|
| `frontend-design` | claude-plugins-official | unknown (rolling) |
| `vercel` | claude-plugins-official | 0.45.1 |
| `clangd-lsp` | claude-plugins-official | 1.0.0 |
| `superpowers` | superpowers-marketplace | 5.1.0 |

`superpowers` is the big one — it supplies `brainstorming`,
`systematic-debugging`, `test-driven-development`, `writing-plans`,
`verification-before-completion`, and the rest of the process skills.

---

## 5. Anthropic document skills (3)

`docx`, `pptx`, `xlsx` — real directories in `~/.claude/skills/`, not symlinks,
no lock entry. From Anthropic's official skills repo:

```bash
npx skills add anthropics/skills   # then select docx, pptx, xlsx
```

⚠️ These carry a **proprietary licence** (see each skill's `LICENSE.txt`), not
open source. Don't redistribute them.

---

## 6. Tracked in this repo (no upstream exists)

**`skills/gemini-media`** — 28 KB, image/video generation via the Gemini API
(Nano Banana, Veo 3.1). Not from gstack, not in the skill lock, not on any
registry. It only exists on this machine, so it **is committed to this repo** and
restores with the clone. Verified to read its credential from the environment
rather than hardcoding it.

It expects the Gemini API key exported in `~/.zshrc`, which is **not** in this
repo. Re-export it on the new machine before using the skill.

**`skills/connect-chrome`** — an empty directory on this machine. Git cannot
store empty directories, so it will not come back. It appears to be a stub for
the gstack browser launcher; `/connect-chrome` should work from gstack's own
install in section 3.

---

## 7. Verify

```bash
# plugin manifest
jq -r '.plugins | keys[]' ~/.claude/plugins/installed_plugins.json

# standalone skills (expect 12)
ls -1 ~/.agents/skills | wc -l

# total skills visible to Claude Code
ls -1 ~/.claude/skills | wc -l    # expect ~65

# gstack alive?
ls ~/.claude/skills/gstack/setup
```

In Claude Code: `/plugin` lists plugins, and typing `/` shows every skill.

---

## 8. Also needed on a new machine

Not skills, but the restore is incomplete without them:

- **`~/.claude.json`** — MCP server config plus trust and permission allowlists
  for 71 folders. Deliberately **not** in this repo (it rewrites constantly and
  holds account identifiers). Copy it across manually or re-approve permissions.
- **`~/.zshrc`** — API keys live here, including the Gemini one.
- **MCP servers** — 8x, Google Drive, Vercel, Stripe, Influencer Club. Reconnect
  via `/mcp`; several need re-authentication.
- **`brew install ffmpeg`** — required for local video assembly work.
