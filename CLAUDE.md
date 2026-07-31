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

## Skill routing

Codex is a read-only second opinion from a different model. It only runs at gates —
it never writes code. Route work through these gates so the outside voice actually
gets used instead of sitting idle.

**Open non-trivial work with a plan gate.** Before building a feature, a migration,
or anything touching more than a couple of files, run `/spec` (precise requirements)
or `/autoplan` (full review chain). Codex critiques the plan before code exists,
which is the cheapest place to catch a bad decision.

**Close substantial code changes with `/review`.** After finishing a meaningful chunk
of work, run `/review` before treating it as done — it runs the Codex diff pass.
Don't wait to be asked. Use `/ship` instead when the work is ready to land.

**Reach for `/codex challenge` on risky code** — auth, money, concurrency, migrations,
anything with a nasty failure mode. A different model has different blind spots.

**Do not gate trivial work.** One-line fixes, typos, comment edits, and renames don't
need a plan gate or a review pass. `/autoplan` chains four review passes; it is for
big features, not small edits.

**Codex requires a git repo.** It refuses to run outside one, so invoke it from inside
a project (`~/dev/<project>`), never from `~/dev` itself.
