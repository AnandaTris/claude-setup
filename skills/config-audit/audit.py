#!/usr/bin/env python3
"""Measure what this Claude Code install costs in context.

Splits spend into two buckets, because they are not comparable:

  ALWAYS-ON   loaded into every single session before you type anything —
              CLAUDE.md, memory index, and the name+description line of every
              skill, agent, and command. Pay it 100% of the time.
  ON-DEMAND   the body of a skill or agent, loaded only when invoked. A 2,000
              line skill you call twice a month is cheap; a 40-word description
              on a skill you never call is not.

Token counts are chars/4 estimates. Good to roughly +/-15% for English prose,
which is accurate enough to rank things. They are not billing figures.

Usage:
  python3 audit.py             full report
  python3 audit.py --json      machine-readable
  python3 audit.py --top 15    change how many rows each table shows
"""

import json
import os
import re
import sys
from collections import defaultdict

HOME = os.path.expanduser("~")
CLAUDE = os.path.join(HOME, ".claude")

# Thresholds. Tuned to flag the top decile, not to nag.
DESC_WORDS_MAX = 30       # a listing line longer than this is doing too much
SKILL_LINES_HEAVY = 500   # split the body into references/ past this
AGENT_LINES_HEAVY = 200
ALWAYS_ON_BUDGET = 25_000  # rough ceiling before the listing itself is a tax
DUP_BLOCK_MIN = 8         # shortest run of lines counted as duplication
DUP_MIN_FILES = 3         # must appear in at least this many files


def est_tokens(text):
    return max(1, round(len(text) / 4))


def read(path):
    try:
        with open(path, encoding="utf-8", errors="ignore") as fh:
            return fh.read()
    except OSError:
        return ""


def parse_frontmatter(text):
    """Return (meta, body). Deliberately minimal: no YAML dependency."""
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text
    raw, body = text[3:end], text[end + 4:]
    meta, key = {}, None
    for line in raw.splitlines():
        m = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if m:
            key = m.group(1)
            meta[key] = m.group(2).strip().strip("'\"")
        elif key and line.startswith((" ", "\t")):
            meta[key] += " " + line.strip()
    return meta, body


def enabled_plugins():
    settings = json.loads(read(os.path.join(CLAUDE, "settings.json")) or "{}")
    enabled = {k for k, v in settings.get("enabledPlugins", {}).items() if v}
    disabled = {k for k, v in settings.get("enabledPlugins", {}).items() if not v}
    installed = json.loads(
        read(os.path.join(CLAUDE, "plugins", "installed_plugins.json")) or "{}"
    ).get("plugins", {})
    roots = {}
    for name, entries in installed.items():
        if name in enabled and entries:
            path = entries[0].get("installPath", "")
            if path and os.path.isdir(path):
                roots[name] = path
    return roots, enabled, disabled


def collect(kind, root, source, out):
    """Skills live in <root>/<name>/SKILL.md; agents and commands are flat .md."""
    if kind == "skill":
        base = os.path.join(root, "skills")
        if not os.path.isdir(base):
            return
        for entry in sorted(os.listdir(base)):
            path = os.path.join(base, entry, "SKILL.md")
            if os.path.isfile(path):
                out.append(describe(kind, path, entry, source))
    else:
        base = os.path.join(root, kind + "s")
        if not os.path.isdir(base):
            return
        for entry in sorted(os.listdir(base)):
            if entry.endswith(".md"):
                path = os.path.join(base, entry)
                out.append(describe(kind, path, entry[:-3], source))


def describe(kind, path, fallback_name, source):
    text = read(path)
    meta, body = parse_frontmatter(text)
    desc = meta.get("description", "")
    name = meta.get("name", fallback_name)
    # What the model sees before invoking: the name and the description.
    listing = f"{name}: {desc}"
    # Skills carry their whole directory, not just SKILL.md.
    extra = 0
    if kind == "skill":
        d = os.path.dirname(path)
        for dirpath, _, files in os.walk(d):
            for f in files:
                if f != "SKILL.md":
                    try:
                        extra += os.path.getsize(os.path.join(dirpath, f))
                    except OSError:
                        pass
    return {
        "kind": kind,
        "name": name,
        "source": source,
        "path": path,
        "desc_words": len(desc.split()),
        "listing_tokens": est_tokens(listing),
        "body_tokens": est_tokens(body),
        "body_lines": body.count("\n") + 1,
        "sidecar_bytes": extra,
        "body": body,
    }


def find_duplication(items):
    """Shared boilerplate: identical runs of >=DUP_BLOCK_MIN normalised lines."""
    seen = defaultdict(set)
    lines_by_file = {}
    for it in items:
        norm = [ln.strip() for ln in it["body"].splitlines()]
        lines_by_file[it["path"]] = norm
        for i in range(len(norm) - DUP_BLOCK_MIN + 1):
            block = norm[i:i + DUP_BLOCK_MIN]
            if sum(1 for b in block if b) < DUP_BLOCK_MIN - 1:
                continue  # mostly blank, not real content
            seen["\n".join(block)].add(it["path"])

    hits = {b: f for b, f in seen.items() if len(f) >= DUP_MIN_FILES}
    if not hits:
        return [], {"total": 0, "avg_per_skill": 0, "files": 0}

    # Cost of duplication = every copy after the first.
    covered = defaultdict(set)
    for block, files in hits.items():
        for path in files:
            norm = lines_by_file[path]
            blines = block.split("\n")
            for i in range(len(norm) - DUP_BLOCK_MIN + 1):
                if norm[i:i + DUP_BLOCK_MIN] == blines:
                    covered[path].update(range(i, i + DUP_BLOCK_MIN))

    per_file = {}
    for path, idxs in covered.items():
        text = "\n".join(lines_by_file[path][i] for i in sorted(idxs))
        per_file[path] = est_tokens(text)

    ranked = sorted(
        ({"name": os.path.basename(os.path.dirname(p)), "tokens": t}
         for p, t in per_file.items()),
        key=lambda r: -r["tokens"],
    )
    total = sum(per_file.values())
    avg = round(total / len(per_file)) if per_file else 0
    return ranked, {"total": total, "avg_per_skill": avg, "files": len(per_file)}


def main():
    top = 10
    if "--top" in sys.argv:
        top = int(sys.argv[sys.argv.index("--top") + 1])
    as_json = "--json" in sys.argv

    roots, enabled, disabled = enabled_plugins()
    items = []
    collect("skill", CLAUDE, "user", items)
    collect("agent", CLAUDE, "user", items)
    collect("command", CLAUDE, "user", items)
    for name, root in sorted(roots.items()):
        short = name.split("@")[0]
        for kind in ("skill", "agent", "command"):
            collect(kind, root, short, items)

    # ---- always-on -------------------------------------------------------
    always = {}
    text = read(os.path.join(CLAUDE, "CLAUDE.md"))
    if text:
        always["CLAUDE.md (global)"] = est_tokens(text)

    # Only one project's memory index loads per session. Prefer the one for the
    # current directory; fall back to the largest, and say which.
    projects = os.path.join(CLAUDE, "projects")
    here = os.path.join(projects, os.getcwd().replace("/", "-"), "memory", "MEMORY.md")
    mem_path, mem_label = (here, "MEMORY.md (this project)") if os.path.isfile(here) else (None, "")
    if mem_path is None and os.path.isdir(projects):
        cands = []
        for proj in os.listdir(projects):
            cand = os.path.join(projects, proj, "memory", "MEMORY.md")
            if os.path.isfile(cand):
                cands.append((os.path.getsize(cand), cand, proj))
        if cands:
            _, mem_path, proj = max(cands)
            mem_label = f"MEMORY.md (largest: {proj})"
    if mem_path:
        always[mem_label] = est_tokens(read(mem_path))

    by_kind = defaultdict(int)
    for it in items:
        by_kind[it["kind"]] += it["listing_tokens"]
    for kind, tok in by_kind.items():
        n = sum(1 for i in items if i["kind"] == kind)
        always[f"{kind} listing ({n})"] = tok

    mcp = json.loads(read(os.path.join(HOME, ".claude.json")) or "{}")
    servers = sorted((mcp.get("mcpServers") or {}).keys())

    always_total = sum(always.values())

    report = {
        "always_on": always,
        "always_on_total": always_total,
        "always_on_budget": ALWAYS_ON_BUDGET,
        "mcp_servers": servers,
        "counts": {k: sum(1 for i in items if i["kind"] == k) for k in by_kind},
        "enabled_plugins": sorted(enabled),
        "disabled_plugins": sorted(disabled),
    }

    bloated = sorted(
        (i for i in items if i["desc_words"] > DESC_WORDS_MAX),
        key=lambda i: -i["desc_words"])
    heavy = sorted(
        (i for i in items
         if (i["kind"] == "skill" and i["body_lines"] > SKILL_LINES_HEAVY)
         or (i["kind"] == "agent" and i["body_lines"] > AGENT_LINES_HEAVY)),
        key=lambda i: -i["body_lines"])
    dupes, wasted = find_duplication([i for i in items if i["kind"] == "skill"])

    report["bloated_descriptions"] = [
        {"name": i["name"], "source": i["source"], "words": i["desc_words"],
         "tokens": i["listing_tokens"]} for i in bloated[:top]]
    report["heavy_bodies"] = [
        {"name": i["name"], "kind": i["kind"], "source": i["source"],
         "lines": i["body_lines"], "tokens": i["body_tokens"],
         "sidecar_kb": round(i["sidecar_bytes"] / 1024)} for i in heavy[:top]]
    report["duplication"] = dict(wasted, worst=dupes[:top])

    if as_json:
        print(json.dumps(report, indent=2))
        return

    def head(t):
        print(f"\n{t}\n" + "-" * len(t))

    print("Claude Code context audit")
    print("token counts are chars/4 estimates, good for ranking, not billing")

    head("Always-on (every session, before you type)")
    for k, v in sorted(always.items(), key=lambda kv: -kv[1]):
        print(f"  {v:>7,}  {k}")
    verdict = "over budget" if always_total > ALWAYS_ON_BUDGET else "within budget"
    print(f"  {'':>7}  {'-' * 40}")
    print(f"  {always_total:>7,}  TOTAL ({verdict}, ceiling {ALWAYS_ON_BUDGET:,})")
    if servers:
        print(f"\n  plus {len(servers)} MCP server(s): {', '.join(servers)}")
        print("  MCP tool schemas are always-on too and are NOT counted above —")
        print("  budget roughly 300-700 tokens per exposed tool.")

    if bloated:
        head(f"Descriptions over {DESC_WORDS_MAX} words (always-on cost)")
        for i in bloated[:top]:
            print(f"  {i['desc_words']:>4}w  {i['listing_tokens']:>5}tok  "
                  f"{i['name']} [{i['source']}]")

    if heavy:
        head("Heavy bodies (on-demand cost, only when invoked)")
        for i in heavy[:top]:
            side = f"  +{i['sidecar_bytes'] // 1024}KB sidecar" if i["sidecar_bytes"] > 1024 else ""
            print(f"  {i['body_lines']:>5} lines  ~{i['body_tokens']:>6,}tok  "
                  f"{i['name']} [{i['source']}]{side}")

    if dupes:
        head("Shared boilerplate across skills")
        print(f"  {wasted['files']} skills share text with at least "
              f"{DUP_MIN_FILES - 1} others.")
        print(f"  ~{wasted['avg_per_skill']:,} tokens of it in an average "
              f"invocation of one.")
        print(f"  ~{wasted['total']:,} tokens if you invoked every one of them.\n")
        print("  worst offenders, by boilerplate carried:")
        for d in dupes[:top]:
            print(f"  ~{d['tokens']:>6,}tok  {d['name']}")
        print("\n  This is on-demand cost, not always-on. It only bites on the")
        print("  skills you actually call.")

    head("Plugins")
    for p in sorted(enabled):
        print(f"  on   {p}")
    for p in sorted(disabled):
        print(f"  off  {p}")
    print("\n  toggle with: ~/.claude/bin/plugin-toggle <name> <on|off>")


if __name__ == "__main__":
    main()
