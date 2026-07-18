# RESEARCH — probes behind the packaging/consumption model

*Status: mechanical convenience properties observed; **trust properties NOT yet probed** (backlog below).
Consumes: [BRIEF.md](BRIEF.md). Feeds: SPECS. Date: 2026-07-18. Method: `environment-research` — small
real experiments against the actual agent runtime (Claude Code), observation outranks documentation where
they disagree. Adversarial round 1 corrected this doc's overclaims (see
[reviews/adversarial-round-1.md](reviews/adversarial-round-1.md)); it now separates what was **observed**
from what is **assumed** or **doc-only**. Probe labels P2/P3/P4 are inherited from the prior research
iteration; P5+ are this chain's backlog.*

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
| **One per-tier symlink resolves EVERY skill; a new skill needs no new link** | mechanical | ❌ **hypothesis** — never observed (P5) |
| A **tag** (vs working tree) is the pinned surface | trust | ❌ not probed; the tag pin as drafted was **falsified** (P7) |
| An **immutable, SHA-pinned, signed** materialization resists out-of-band mutation | trust | ❌ not probed (P7) |
| A re-pointed / `--force` tag is rejected **loudly** | trust | ❌ not probed; reviewers observed **silent** divergence (P8) |
| The boot check **fires** when the tier is absent/partial | trust | ❌ not probed (P9) |
| Real multi-skill pack packages cleanly at scale | mechanical | ❌ not probed (P10) |
| Marketplace skips outside-symlinks | mechanical | ❌ doc-only (P11) |

**Net (corrected).** The **mechanical** conveniences are observation-backed; the **trust** properties — the
ones that justify pinning to a tag at all — are **not**, and three of them were falsified when reviewers
probed them by hand. The design in BRIEF v2 is written *against* those falsifications (immutable
materialization + SHA pin + signed tag + tier-independent boot check); the observations below-the-line must
be produced before slice 3.

## Probes still required (before slice 3 — do not claim the design done without them)

- **P5 — one-symlink-many-skills + add-mid-stream.** A plugin whose `skills/` holds ≥2 dirs, symlinked once;
  verify all resolve; add a third dir; verify a fresh session finds it with **no** new symlink. *(Proves the
  motivating under-install fix.)*
- **P6 — real tag→tag bump.** Cut a second tag; bump tag-A → tag-B across fresh sessions; confirm pickup.
- **P7 — out-of-band mutation / immutability.** On the chosen materialization (read-only export / read-only
  worktree), attempt a stray `git checkout`/edit at the target; confirm the loader-visible content **cannot**
  change without a reviewed bump, and that a boot-time `HEAD == pinned SHA` assertion catches drift.
  *(Reviewers showed a writable working-tree target DOES silently change — this probe must show the fix
  holds.)*
- **P8 — re-pointed tag, fresh vs warm host, `--force`.** Re-point a tag upstream; confirm a warm host's
  fetch is **rejected loudly** and a fresh host detects the SHA mismatch against the pin — not a silent
  exit-0 adoption.
- **P9 — boot check fires.** A tier-independent check detects an absent, partial (tier resolves but a skill
  dir missing), and malformed-manifest tier, and emits a visible signal.
- **P10 — real-pack packaging at scale.** Package the actual multi-skill tier; re-observe discovery,
  namespacing, and hooks at real scale (not the toy).
- **P11 — marketplace skip (optional).** Install a marketplace plugin, point a skill symlink outside the
  marketplace, observe the skip — or keep the marketplace Non-goal as explicitly doc-only.
- **P12 — signature verification.** Confirm a signed-tag signature check is enforceable on checkout/boot.
