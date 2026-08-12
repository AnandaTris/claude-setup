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
  the clarity and planning steps above.
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
