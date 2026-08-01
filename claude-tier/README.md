# Claude-specific methodology tier

**This directory is intentionally empty of skills.** Nothing here is installed today, and you do not
need it to use the pack.

It exists to hold rules that only make sense inside the Claude runtime — hook lifecycles, plugin and
skill loading, slash-command surfaces — separately from the 22 agent-agnostic skills at the repo root
(`../skills/`), which every agent consumes.

## Why it ships empty

Splitting the pack into a portable tier and an agent tier was a real decision, so it is recorded in
git as a real directory with a real plugin manifest rather than a note promising a future layout.
Wiring an empty plugin through materialize, symlink, and boot-check on every consumer would be
machinery serving zero skills, so runtime consumption is deliberately deferred.

When the first Claude-only rule lands here, turning it on is one already-designed symlink.

## Where a lesson belongs

Use [docs/placement.md](../docs/placement.md) to decide whether something is portable, agent-specific,
or a project detail. The short version: state a lesson at the most general tier its content actually
supports. If you can write it without naming Claude's mechanics, it belongs in `../skills/`, not here.

## Background

The two-tier decision and its deferred-consumption rationale are recorded in the
[packaging-and-consumption design chain](../design-chain/packaging-and-consumption/BRIEF.md).
