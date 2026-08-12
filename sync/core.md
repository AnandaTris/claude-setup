# Secrets

`~/dev/8x_Internship/Keys/` is Ado's personal credential store — `.p8` files,
service-role keys, API keys pasted out of dashboards. **Never read, list, grep,
copy, move, or open anything in it, by any tool.** The filenames leak too (which
vendors hold which credentials), so `ls` is as forbidden as `cat`.

Enforced by this host's deny rules and by the shared `block-secret-reads.sh`
guard — one real copy in `~/.claude/sync/hooks/`, symlinked onto both hosts —
but the instruction stands on its own. If a task needs a value from there, ask
Ado for that one value, or have him run the command himself with `! <command>`.

# Skills

Check the available skills listing for relevance before starting any task. Scanning is free — do it every time. Invoking loads instructions you must then follow, so match on real signal, not vibes. Never rely on memory of what a skill contains; read the current version.

Invoke when the task involves:
- Output with format requirements — `.docx`, `.xlsx`, `.pptx`, PDFs, charts/dataviz
- Anything leaving this machine — shipping, deploying, PRs, releases
- A stack or domain a skill covers — Vercel, Next.js, AI SDK, frontend design, browsing
- Multi-step implementation, debugging, or planning

Scanning alone is enough for conversational questions, single-fact lookups, and small mechanical edits.

When you invoke one, say so: "Using [skill] to [purpose]." This scoping replaces the blanket "even a 1% chance" rule from superpowers.

# Effort

Match the cost of the approach to the difficulty of the task. Mechanical work
gets the cheap path; work where being wrong is expensive gets the expensive one.
Never pay top tier for a grep sweep, and never economise on an architecture
call, an auth/money/concurrency change, or a migration.

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

Use the `browse` skill from gstack for all web browsing. Never use
`mcp__claude-in-chrome__*` tools directly.

gstack skills on this host are invoked as {{GSTACK_NAMING}}. Read the
available-skills listing for the current set — never work from a memorised list.

## Skill routing

{{OTHER}} is a read-only second opinion from a different model. It only runs at
gates — it never writes code. Route work through these gates so the outside
voice actually gets used instead of sitting idle.

**Clarity before planning. Planning before code.** For any task beyond a trivial
edit, resolve ambiguity first, then plan, then build — in that order. Do not jump
to code because the request sounds clear; requests that sound clear are where
assumptions hide.

- Ambiguous scope, or a "build X" with unstated requirements → `{{BRAINSTORM}}`
  to surface intent and constraints before anything is designed.
- A decision or plan that needs stress-testing → `grilling` (or `grill-me`) to
  attack the reasoning before it gets expensive to change.
- Then `{{SPEC}}` or `{{AUTOPLAN}}` to turn the cleared-up intent into a written plan.

Skip the clarity step only when the task is genuinely unambiguous — a named bug, a
specific file, a mechanical change. When in doubt, one clarifying pass is cheaper than
a wrong implementation.

**Open non-trivial work with a plan gate.** Before building a feature, a migration,
or anything touching more than a couple of files, run `{{SPEC}}` (precise
requirements) or `{{AUTOPLAN}}` (full review chain). {{OTHER}} critiques the plan
before code exists, which is the cheapest place to catch a bad decision.

**Close substantial code changes with `{{REVIEW}}`.** After finishing a meaningful
chunk of work, run it before treating the work as done — it runs the {{OTHER}} diff
pass. Don't wait to be asked. Use `{{SHIP}}` when the work is ready to land.

**Reach for `{{CHALLENGE}}` on risky code** — auth, money, concurrency, migrations,
anything with a nasty failure mode. A different model has different blind spots.

**Do not gate trivial work.** One-line fixes, typos, comment edits, and renames don't
need a plan gate or a review pass. `{{AUTOPLAN}}` chains four review passes; it is
for big features, not small edits.

**gstack requires a git repo.** It refuses to run outside one, so invoke it from
inside a project (`~/dev/<project>`), never from `~/dev` itself.
