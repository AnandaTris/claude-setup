# Skills

Check the available skills listing for relevance before starting any task. Scanning is free — do it every time. Invoking loads instructions you must then follow, so match on real signal, not vibes. Never rely on memory of what a skill contains; read the current version.

Invoke when the task involves:
- Output with format requirements — `.docx`, `.xlsx`, `.pptx`, PDFs, charts/dataviz
- Anything leaving this machine — shipping, deploying, PRs, releases
- A stack or domain a skill covers — Vercel, Next.js, AI SDK, frontend design, browsing
- Multi-step implementation, debugging, or planning

Scanning alone is enough for conversational questions, single-fact lookups, and small mechanical edits.

When you invoke one, say so: "Using [skill] to [purpose]." This scoping replaces the blanket "even a 1% chance" rule from superpowers.

# Ultracode

Multi-agent workflow orchestration. For substantial work — big features, audits,
migrations, broad refactors, exhaustive bug hunts — you have standing authorization
to run one. Don't wait for the "ultracode" keyword and don't ask permission first.

- Fan out when the work decomposes: many files, many call sites, many independent
  checks. One agent per unit, verified in parallel.
- Scout inline first, then orchestrate. Find the work-list yourself, then hand the
  list to the fleet. Don't spawn agents to discover what a grep would tell you.
- Close a review-shaped workflow with an adversarial verify pass — independent
  skeptics per finding, majority verdict kills it.
- Plan gates still apply. Ultracode executes a plan faster; it does not replace
  the clarity and planning steps below.
- Stay solo for trivial edits, single-file changes, and conversational turns. A
  workflow that costs more than the task is a mistake, not thoroughness.

# Model allocation

Tier every agent to its job — workflow fan-outs and plain `Agent` calls alike.
Inheriting the session model everywhere is the default, not the right answer:
running opus on a grep sweep costs more and produces nothing better.

- `haiku` — mechanical and fully specified, near-zero judgment. File inventories,
  grep sweeps, extracting fields, applying a known mapping, boilerplate edits,
  reshaping structured output.
- `sonnet` — the default worker. Normal implementation, targeted refactors,
  reading a subsystem and reporting back, routine tests, single-dimension review.
- `opus` / `fable` — reserved for stages where being wrong is expensive:
  architecture calls, adversarial verify and judge panels, synthesis across many
  agents' results, subtle-bug hunting, auth/money/concurrency/migration risk.

Set `model` on every dispatch, workflow or not. In workflows, pair it with
`effort` — the cheaper knob: `low` on mechanical stages, `high`/`max` only on the
hardest verify or judge. Plain `Agent` calls take no `effort`, so the tier is the
whole decision there.

Search-shaped dispatches are haiku or sonnet by default — `Explore`, "find where
X is defined", "list every call site". Go higher only when deciding what counts
as a match is itself the hard part. A named subagent type that declares its own
model has already made this call; override it only with a reason.

Shape pipelines so the cheap tiers do the volume and the expensive tier sees only
what survived. Wide-and-cheap → narrow-and-smart, not uniform-and-expensive. When
a stage genuinely sits between tiers, take the cheaper one — a verify pass above
it will catch the miss.

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

**Clarity before planning. Planning before code.** For any task beyond a trivial edit,
resolve ambiguity first, then plan, then build — in that order. Do not jump to code
because the request sounds clear; requests that sound clear are where assumptions hide.

- Ambiguous scope, or a "build X" with unstated requirements → `superpowers:brainstorming`
  to surface intent and constraints before anything is designed.
- A decision or plan that needs stress-testing → `grilling` (or `grill-me`) to attack
  the reasoning before it gets expensive to change.
- Then `/spec` or `/autoplan` to turn the cleared-up intent into a written plan.

Skip the clarity step only when the task is genuinely unambiguous — a named bug, a
specific file, a mechanical change. When in doubt, one clarifying pass is cheaper than
a wrong implementation.

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
