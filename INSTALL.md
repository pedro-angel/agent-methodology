# INSTALL — drop this methodology into any project

This pack teaches any AI coding agent one engineering methodology. It is designed to be agent-neutral: a single source of truth (`AGENTS.md`) plus a `skills/` library, with thin per-agent adapters that just point the agent at them. Install takes about a minute.

## What's in the pack

```text
AGENTS.md                         # single source of truth — the principles + index
skills/<slug>/SKILL.md            # one folder per skill: rules, red-flags, examples
adapters/claude/CLAUDE.md         # thin shim: "read AGENTS.md, load the matching skill"
adapters/cursor/methodology.mdc
adapters/copilot/copilot-instructions.md
adapters/gemini/GEMINI.md
templates/methodology-sync.yml    # weekly sync-bot workflow for repos that vendor the pack
templates/git-controls/           # offline-vendorable copy of the git controls; their distribution home is the standalone git-controls-starter repo — prefer consuming remotely from there (its README, mode 1)
```

`AGENTS.md` holds the methodology. Every adapter is a few lines that say "read `AGENTS.md`, find the matching skill(s), load `skills/<slug>/SKILL.md` before acting." You edit `AGENTS.md` and the `SKILL.md` files; you almost never touch an adapter. That is what keeps one pack working across every agent.

## Installing alongside the git controls

This pack and [git-controls-starter](https://github.com/pedro-angel/git-controls-starter)
are complementary and don't overlap: the starter owns the git gate
(`.pre-commit-config.yaml`, `scripts/checks/`, CI workflows), this pack owns the prose
(`AGENTS.md`, `skills/`, agent adapters). Install in either order; for the controls,
prefer the starter's remote-consumption mode (its README, mode 1).

## Setup

Set two paths once; every block below reuses them. (If your shell loses them between blocks, re-export.)

```bash
export PACK=/path/to/agent-methodology   # where this pack lives
export PROJECT=/path/to/your/project     # the repo you're installing into
```

## Step 1 — Core (every agent)

Copy the source of truth and the skills to the target project root:

```bash
cp "$PACK/AGENTS.md" "$PROJECT/AGENTS.md"
mkdir -p "$PROJECT/skills" && cp -R "$PACK/skills/." "$PROJECT/skills/"
```

That is the minimum viable install. `AGENTS.md` at the repo root is an emerging cross-agent convention. OpenAI Codex reads it natively, so for Codex this single step is the whole install; a growing set of other tools support the convention but may need a one-line pointer to it (for example, Aider loads it only when you pass `--read AGENTS.md` or add it to `.aider.conf.yml`) — check your agent's docs. The per-agent adapter in Step 2 covers agents that look for their own instruction file first.

## Step 2 — Per-agent adapter

Add the shim for whichever agent(s) you use. Each one is independent; install as many as apply.

### Claude Code

```bash
cp "$PACK/adapters/claude/CLAUDE.md" "$PROJECT/CLAUDE.md"
```

Skills already sit at `$PROJECT/skills/` from Step 1, and `CLAUDE.md` references them by path. To also make them natively discoverable (invokable as slash-skills), place them in one of the two locations Claude Code auto-loads from:

```bash
# this project only:
mkdir -p "$PROJECT/.claude/skills" && cp -R "$PACK/skills/." "$PROJECT/.claude/skills/"

# or, available across all your projects:
mkdir -p ~/.claude/skills && cp -R "$PACK/skills/." ~/.claude/skills/

# (The pack's own maintainer, on their own hosts, should instead use the pinned-plugin
# mode below — one symlink to a SHA-pinned materialization, reviewed on each bump.)
```

Pick **one** discovery location: with skills installed at the user level, also keeping a
copy in `$PROJECT/.claude/skills/` gives the agent duplicates of every skill. Projects on
a machine with the user-level install should drop the project-level copy (the repo can
still vendor `skills/` for other agents and contributors — that path is not auto-loaded).

### Cursor

```bash
mkdir -p "$PROJECT/.cursor/rules"
cp "$PACK/adapters/cursor/methodology.mdc" "$PROJECT/.cursor/rules/methodology.mdc"
```

### GitHub Copilot

```bash
mkdir -p "$PROJECT/.github"
cp "$PACK/adapters/copilot/copilot-instructions.md" "$PROJECT/.github/copilot-instructions.md"
```

### Gemini

```bash
cp "$PACK/adapters/gemini/GEMINI.md" "$PROJECT/GEMINI.md"
```

### Any other agent

If your agent reads `AGENTS.md` at the repo root, Step 1 already covered it. If it expects its own instruction file (some custom name), create that file and make it a one-liner pointing at the source of truth:

```text
Follow the methodology in ./AGENTS.md. For each task, load the matching skills/<slug>/SKILL.md before acting.
```

Keep your custom adapter thin — a pointer, not a copy of the rules; the canonical rules live in `AGENTS.md`. (The bundled Cursor and Copilot adapters are the deliberate exception: those tools don't reliably follow a bare pointer, so they inline a *condensed index* derived from `AGENTS.md`. If you edit the skill set, update that index too — CI checks that every adapter enumerates all skills.)

## Symlink instead of copy (avoid drift)

Copies are self-contained but go stale when the pack updates. To stay in sync, symlink the pack files into place instead of copying — edit the pack once and every project sees it:

```bash
ln -s "$PACK/AGENTS.md"                              "$PROJECT/AGENTS.md"
ln -s "$PACK/skills"                                 "$PROJECT/skills"
ln -s "$PACK/adapters/claude/CLAUDE.md"              "$PROJECT/CLAUDE.md"
mkdir -p "$PROJECT/.cursor/rules" "$PROJECT/.github"
ln -s "$PACK/adapters/cursor/methodology.mdc"        "$PROJECT/.cursor/rules/methodology.mdc"
ln -s "$PACK/adapters/copilot/copilot-instructions.md" "$PROJECT/.github/copilot-instructions.md"
ln -s "$PACK/adapters/gemini/GEMINI.md"              "$PROJECT/GEMINI.md"
```

Caveat: a committed symlink with an absolute target breaks for any collaborator whose pack lives elsewhere. For a shared repo, vendor the pack as a git submodule and use relative symlinks, or just copy and re-sync on update (below). For a solo repo or a monorepo where the pack lives at a stable path, absolute symlinks are fine.

## Tag-pinned plugin (maintainer's own hosts)

For the pack's own maintainer, on hosts where they **consume** the methodology (as opposed to developing
the pack itself), install it as a **SHA-pinned, read-only plugin** rather than copies or working-tree
symlinks. `tools/consume/install-consumer.sh` materializes one specific commit into a per-consumer root
(a read-only export, no `.git`), symlinks it as a single namespaced plugin into `~/.claude/skills/`, and
wires a tier-independent boot check that runs on session start. A bump is a reviewed move to a new SHA —
never a live `git pull` — so what runs is always an audited, immutable commit, not whatever the working
tree happens to hold. This is the maintainer's **consumption** path; other people use the copy, symlink,
submodule, or sync modes above, and developing the pack itself still uses a plain working-tree checkout.

## Updating

Three modes, by how updates reach the project:

- **Copied install (manual):** re-run the Step 1 and Step 2 commands — `cp` overwrites in place. Fine for a one-off; in practice manually-synced copies go stale fast (field data: three times in one week).
- **Symlink or submodule (always-current):** pull the pack (`git -C "$PACK" pull`, or `git submodule update --remote`); every linked project picks up the change with nothing to re-run. Best when **developing** the pack, or on machines that are not the maintainer's own consumption hosts — for those, the Tag-pinned plugin mode (above) supersedes this, pinning a reviewed SHA instead of tracking the working tree.
- **Sync bot (copied + weekly PR):** for shared repos that must vendor real files, add [`templates/methodology-sync.yml`](templates/methodology-sync.yml) as `.github/workflows/methodology-sync.yml`. Every week (or on manual dispatch) it re-syncs `AGENTS.md`, `skills/`, and the adapter from this pack's main and opens a PR only when something changed — drift becomes a reviewable diff instead of a silent gap. Verified live: a dispatch on an in-sync repo runs green and opens nothing.

Because the principles live only in `AGENTS.md` and the `SKILL.md` files, an update never has to touch a per-agent adapter.

## Migrating between modes

- **Copied → sync bot:** just add the workflow (above). Its first run PRs the delta between your copy and current main — merging that PR *is* the catch-up.
- **Copied → symlink:** `git rm -r` the vendored files, then create the links from the symlink section. Only for repos that never leave machines where `$PACK` exists.
- **Symlink → copied (a collaborator joined):** delete the links **first**, then re-run the copy commands from Steps 1–2, commit the real files, and add the sync bot so the new copies don't rot. (Order matters: copying onto an existing symlinked destination follows the link and writes into the pack itself.)

  ```bash
  rm "$PROJECT/AGENTS.md" "$PROJECT/CLAUDE.md" "$PROJECT/skills"   # remove links, not content
  cp "$PACK/AGENTS.md" "$PROJECT/AGENTS.md"
  mkdir -p "$PROJECT/skills" && cp -R "$PACK/skills/." "$PROJECT/skills/"
  cp "$PACK/adapters/claude/CLAUDE.md" "$PROJECT/CLAUDE.md"
  ```

- **Trimming a dual install:** if skills are discoverable both user-level (`~/.claude/skills`) and project-level (`.claude/skills/`), keep the user-level one and `git rm -r .claude/skills` — the repo's `skills/` directory (for other agents and contributors) is unaffected.

## Verify it took

Open the project in your agent and give it a real task, then confirm it engages the methodology — for example ask: "Which methodology skills apply here, and what does each require?" A correct install responds by citing `AGENTS.md` and loading the relevant `skills/<slug>/SKILL.md` before proposing code.

If the agent doesn't see the methodology, check that the file landed at the path that agent actually reads: `AGENTS.md` or `CLAUDE.md` at the repo root, `.cursor/rules/methodology.mdc`, `.github/copilot-instructions.md`, or `GEMINI.md`.

---

This methodology was distilled from real builds — primarily a shipped, hexagonal, human-in-the-loop AI agent deployed to a cloud platform, gated by a CI-able eval harness, plus a second build (a REST API client covering an external system's full API against a live server) that earned the fan-out and large-surface live-testing rules — used here only as illustrative sources. You need to know nothing about either project to install or apply the pack — every rule stands on its own on any stack. The pack is released under the [MIT License](LICENSE); copy it into your own projects, proprietary ones included, freely.
