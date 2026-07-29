# Skills

Check the available skills listing for relevance before starting any task. Scanning is free — do it every time. Invoking loads instructions you must then follow, so match on real signal, not vibes. Never rely on memory of what a skill contains; read the current version.

Invoke when the task involves:
- Output with format requirements — `.docx`, `.xlsx`, `.pptx`, PDFs, charts/dataviz
- Anything leaving this machine — shipping, deploying, PRs, releases
- A stack or domain a skill covers — Vercel, Next.js, AI SDK, frontend design, browsing
- Multi-step implementation, debugging, or planning

Scanning alone is enough for conversational questions, single-fact lookups, and small mechanical edits.

When you invoke one, say so: "Using [skill] to [purpose]." This scoping replaces the blanket "even a 1% chance" rule from superpowers.

# Git commits

Every commit message: conventional commits format, one or two lines max. No exceptions.

- Format: `type(scope): subject` — scope optional. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Subject line under ~72 chars, imperative mood, lowercase, no trailing period.
- At most ONE short body line, and only when the subject genuinely can't carry the meaning. Otherwise subject only.
- Never write paragraphs, bullet lists, "Changes:" sections, rationale essays, or co-author/generated-by trailers.
- If the change feels too big to describe in one line, that's a signal to split the commit — not to write more lines.

Good:
```
feat(auth): add refresh token rotation
fix: prevent race in cache eviction
```

Bad: anything longer than the above.

# gstack

Use the `/browse` skill from gstack for all web browsing. Never use `mcp__claude-in-chrome__*` tools directly.

Available gstack skills:
`/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/design-consultation`, `/design-shotgun`, `/design-html`, `/review`, `/ship`, `/land-and-deploy`, `/canary`, `/benchmark`, `/browse`, `/connect-chrome`, `/qa`, `/qa-only`, `/design-review`, `/setup-browser-cookies`, `/setup-deploy`, `/setup-gbrain`, `/retro`, `/investigate`, `/document-release`, `/document-generate`, `/codex`, `/cso`, `/autoplan`, `/plan-devex-review`, `/devex-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze`, `/gstack-upgrade`, `/learn`
