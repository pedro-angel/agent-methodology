# Claude-specific methodology tier

This subtree is the **agent-specific tier** of the pack (decision F1/F2 in
[`../design-chain/packaging-and-consumption/`](../design-chain/packaging-and-consumption/BRIEF.md)):
a second skills-directory plugin (`agent-methodology-claude`) that holds methodology which only makes sense
in the Claude runtime — namespacing, hooks, slash-commands, and any Claude-only rules.

It ships now as a **scaffold** (this README, the manifest, and an empty `skills/`) so the two-tier decision is
git-addressable and versioned on the repo's single tag stream. Its **runtime consumption is deferred**: wiring
an empty plugin through materialize/symlink/boot-check on every consumer would be machinery for zero skills.
When the first Claude-only skill lands here, consumption is one already-designed symlink away
(see the design-chain's DESIGN.md).

The **portable tier** — the 22 agent-agnostic skills every agent consumes — stays at the repo root
(`../skills/`), exposed by the root `agent-methodology` plugin manifest.
