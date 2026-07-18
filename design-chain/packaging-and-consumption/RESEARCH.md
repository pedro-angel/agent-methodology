# RESEARCH — probes behind the packaging/consumption model

*Status: **value-prop + trust mechanics now OBSERVED** — P5/P6/P7/P8/P9/P10 run 2026-07-18, captured verbatim
in [experiments/probe-run-2026-07-18.md](experiments/probe-run-2026-07-18.md) (Claude Code 2.1.214). Only
P11 (marketplace, doc-only) and P12 (signature, deferred by F4) remain un-run.
Consumes: [BRIEF.md](BRIEF.md). Feeds: SPECS. Date: 2026-07-18. Method: `environment-research` — small
real experiments against the actual agent runtime (Claude Code), observation outranks documentation where
they disagree. Adversarial round 1 corrected this doc's overclaims (see
[reviews/adversarial-round-1.md](reviews/adversarial-round-1.md)); it separates what was **observed** from
what is **assumed** or **doc-only**. Probe labels P2/P3/P4 are inherited from the prior research iteration;
P5–P12 are this chain's backlog, now largely discharged.*

## Why probe at all

The model rests on assumptions in two classes. **Mechanical:** a symlinked skill directory is discovered,
swapping the target is picked up cleanly, a bad target fails safe, a plugin namespaces, hooks fire.
**Trust:** an immutable materialization actually resists out-of-band mutation, a signed tag's signature is
verified, a re-pointed tag is rejected loudly, the boot check fires when the tier is absent. The prior
probes covered the **mechanical** class only. The **trust** class — which is the whole reason to pin to a
tag instead of `main` — was not probed, and when round-1 reviewers ran three of those trust probes by hand
they **falsified** the draft's mechanism (see backlog P7/P8). This doc records both honestly.

## Evidence-capture caveat

P2/P3/P4 were run in prior sessions; their raw captures (exact `claude --version`, commands, slugs, tag
names, marker paths, exit codes) were **not** recorded into this chain, so the summaries below are
reconstructions, not the reviewer-checkable artifacts the `environment-research` skill requires. Before
slice 3, the probes must be **re-run and captured** as dated `experiments/` notes (the shape used by the
sibling `design-chain/eod-weigh-before-stance/experiments/`).

## P2 — per-skill symlink discovery, target-swap pickup, fail-safe (mechanical)

**Setup.** The maintainer's machine symlinks `~/.claude/skills/<slug>` → a live checkout of this pack, one
link per skill, pointing at the **working tree** (not a tag). Three fresh headless sessions (`claude -p`)
exercised the loader.

**Observed.**

- **(A) Discovery works.** A symlinked skill directory is discovered and invocable like a real-file skill.
- **(B) A target swap is picked up cleanly.** Changing what the symlink points at (a `git checkout` at the
  target) is reflected in the **next** session — no stale content observed across the one swap. **This was
  a working-tree checkout swap, not a tag→tag bump** (the repo has exactly one tag, so a real bump has never
  run — see P6). Tag semantics are *assumed* identical; untested.
- **(C) A dangling/bad target fails SAFE.** A missing target → the skill is **silently dropped**, the session
  starts clean, exit 0.

**What it licenses.** Discovery and clean target-swap are sound. **(C) motivates the boot check**: "safe"
here means *silent*, and silent absence is the failure the design wants visible. It does **not** license the
tag-vs-working-tree immutability claim — see P7.

**Doc cross-check (not a probe).** Claude Code's guidance says these must be served as **personal skills**,
not a *marketplace* plugin — marketplace symlinks pointing outside their marketplace are skipped for
security. This is **doc-only, unversioned, not observed** (optional confirming probe P11); it is the basis
for the BRIEF's marketplace Non-goal, flagged as such.

## P3 — a *single-skill* skills-directory plugin (mechanical, feasibility-only)

**Question.** Can the agent-specific tier be a *plugin* (namespaced, one versioned unit) without losing the
symlink-target-swap of P2?

**Setup.** A **minimal, single-skill** plugin — `.claude-plugin/plugin.json` + one `skills/<name>/SKILL.md`
— under `~/.claude/skills/<name>`, symlinked to an external checkout.

**Observed.** It loads in place; its one skill is **namespaced** (`<plugin>:<skill>`); a target swap is
picked up by a fresh session; a dangling target fails safe.

**What it licenses (and what it does NOT).** A plugin *can* be namespaced and symlink-swapped — feasibility.
It does **not** show that one symlink resolves **many** skills, nor that a **newly added** skill dir appears
without a new link (the marquee under-install fix — that is **hypothesis P5**, never observed), nor that the
**real** multi-skill pack packages cleanly at scale (**P10**). A *marketplace* plugin (copied to cache,
skips outside-symlinks) is a different topology, not tested here.

## P4 — one bundled hook fires through the symlink (mechanical)

**Setup.** A `hooks/` dir with a `hooks.json` (**one** `SessionStart` hook writing a marker) in a symlinked
skills-directory plugin.

**Observed.** The `SessionStart` hook fired through the symlink (marker written); `${CLAUDE_PLUGIN_ROOT}`
resolved to the symlink path.

**What it licenses.** *A single `SessionStart` hook fires through a symlinked plugin.* It does **not**
license "the full package, no caveat": other hook events (Pre/PostToolUse, UserPromptSubmit, Stop), bundled
slash-commands (never probed), and the safety-critical **hook-present-and-target-dangling** case (does the
plugin still fail safe, or does a hook referencing a now-missing script error the session start?) are all
untested — and that last one is exactly what the boot check depends on.

## What was observed vs. what the design assumes

| Assumption | Class | Status |
| --- | --- | --- |
| Symlinked skill is discovered | mechanical | ✅ observed (P2A) |
| A target swap → next session picks it up, no stale content (one swap) | mechanical | ✅ observed for a **working-tree** swap (P2B); tag→tag untested |
| Bad/absent target fails safe (silent, clean, exit 0) | mechanical | ✅ observed (P2C/P3) — motivates the boot check |
| A plugin can be namespaced + symlink-swapped | mechanical | ✅ observed for a **single-skill toy** (P3) |
| One `SessionStart` hook fires through the symlink | mechanical | ✅ observed once (P4) |
| **One per-tier symlink resolves EVERY skill; a new skill needs no new link** | mechanical | ✅ **observed** (P5, 2→3 skills, no new link) |
| An immutable, read-only, SHA-pinned materialization of a commit is the pinned surface | trust | ✅ observed (P7 — no `.git`, read-only blocks edit) |
| The materialization resists out-of-band mutation | trust | ✅ observed (P7 — `permission denied`, content intact) |
| A bump (re-point to a new materialization) changes content; old pin untouched | trust | ✅ observed (P6) |
| A re-pointed tag is caught by the SHA pin (not silently adopted) | trust | ✅ observed (P8 — `rev-parse` mismatch) |
| The boot check **fires** when the tier is absent/partial/drifted | trust | ✅ observed (P9 — incl. tier removed) |
| Real multi-skill pack packages cleanly at scale | mechanical | ✅ observed (P10 — all 22 skills, one symlink) |
| Marketplace skips outside-symlinks | mechanical | ❌ doc-only (P11 — optional) |
| Signature verification is enforceable | trust | ⏸ deferred (P12 — F4 chose no signing in the base) |

**Net (updated 2026-07-18).** The value-prop (P5, P10) and the trust mechanics (P6, P7, P8, P9) are now
observation-backed at real scale — see [experiments/probe-run-2026-07-18.md](experiments/probe-run-2026-07-18.md).
Round 1 falsified the *first draft's* tag pin (a writable working-tree target + a movable tag name); the
decided F4 model (read-only `git archive` materialization + SHA pin, no signing) was then probed and holds.
The design stands on evidence. Only P11 (doc-only) and P12 (deferred) remain un-run.

## Probe backlog — status

Discharged 2026-07-18 (evidence: [experiments/probe-run-2026-07-18.md](experiments/probe-run-2026-07-18.md)):

- **P5 — one-symlink-many-skills + add-mid-stream.** ✅ DONE — 2→3 skills via one symlink, no new link.
- **P6 — tag→tag bump.** ✅ DONE — re-point to a new read-only materialization changes content; old pin
  untouched. *(Two materializations of two tagged commits; not a live `git fetch` of a moved tag — that path
  is P8.)*
- **P7 — out-of-band mutation / immutability.** ✅ DONE — read-only `git archive` export has no `.git` and
  blocks a stray edit (`permission denied`).
- **P8 — re-pointed tag caught by the SHA pin.** ✅ DONE — `git rev-parse` of the moved tag ≠ the recorded
  pin → fail loud. *(The `git fetch` warm/fresh-host `--force` exit-status behavior is not separately probed;
  the SHA compare makes the fetch's exit code non-load-bearing — the pin, not the fetch, is the gate.)*
- **P9 — boot check fires.** ✅ DONE — a standalone check flags absent, partial, and drifted tiers, and
  still runs when the tier is removed (a bundled hook could not).
- **P10 — real-pack packaging at scale.** ✅ DONE — all 22 real skills resolve through one symlink,
  namespaced. *(Discovery + namespacing at scale; real hooks at scale were not exercised, no hooks ship yet.)*

Still open:

- **P11 — marketplace skip (optional).** Not run; the marketplace Non-goal stays explicitly **doc-only**.
- **P12 — signature verification.** **Deferred** — F4 chose read-only + SHA pin with no signing in the base;
  probe this only if signing is later adopted.
