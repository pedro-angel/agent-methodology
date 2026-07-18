# BRIEF — packaging this pack into tiers, and consuming it by a SHA-pinned read-only plugin instead of vendoring

*Status: **model accepted + forks F1–F5 DECIDED 2026-07-18** (see Decisions); propose-only PR.
Adversarial round 1 incorporated (see [reviews/adversarial-round-1.md](reviews/adversarial-round-1.md)) —
the trust mechanism is hardened and the evidence claims are downgraded to what was observed.
Feeds: [RESEARCH.md](RESEARCH.md), then SPECS → DESIGN → TASKS. Date: 2026-07-18. This is the WHAT and
WHY: the problem, the decided model, the resolved forks, and the reviewable slices. It is the pack's own
equivalent of an architecture decision record for how the pack is distributed and consumed.*

## Decisions (2026-07-18 — owner, via the F1–F5 walk-through)

- **F1 — one repo.** The agent-specific tier is a sibling subtree here, on the repo's single tag stream. No
  second repo.
- **F2 — both tiers are one-symlink namespaced plugins.** The portable tier also gains a thin
  `.claude-plugin/` manifest over `skills/`; other agents ignore it and read `skills/<slug>/SKILL.md` by
  path. Namespacing (`<pack>:<slug>`) on the plugin path is accepted. Building both tiers as real plugins
  deliberately keeps a future marketplace distribution open (see Non-goals).
- **F3 — collapsed.** The reusable consumption guidance lands as an `INSTALL.md` mode, not a new skill. The
  consumer is early work-in-progress and freely rewritable — its de-vendoring needs no superseding-ADR
  ceremony; just change it.
- **F4 — freeze to an exact commit, read-only, SHA-pinned. No signing in the base.** The target is an
  immutable read-only materialization of a specific commit; the pin of record is the SHA; the boot check
  asserts HEAD == the pinned SHA. Signature verification is an optional later upgrade, added only if push
  access widens or the content becomes tamper-sensitive — not now.
- **F5 — each worker materializes its own copy at startup (self-contained).** Chosen over a shared host
  copy because these workers belong to a consumer that must spin up on different machines; a per-worker copy
  travels, a shared-host copy assumes a fixed host. Kept simple — the worker copy's tamper-resistance is not
  over-engineered (consistent with F4).

## Problem

The pack is currently consumed by **copying its files into each project** (vendoring), or by
**symlinking each skill directory into a live working tree** (see `INSTALL.md`). Both were honest
starting points; at scale on the maintainer's own machines they now bite:

- **The vendored copy inverts the source of truth.** A consuming project holds a *copy* of `skills/`
  plus a sha-pin manifest and a drift-guard test. When the canonical pack improves, the copy is stale;
  when the consumer edits the copy, the canonical pack is behind. Neither direction is authoritative, and
  every skill edit pays sha-pin + drift-guard ceremony. This is the "biting."
- **Per-skill symlinks require manual wiring.** Symlinking one directory per skill means **adding a skill
  silently under-installs** — the new slug has no link until a human remembers to create it.
  Field-observed: a freshly graduated skill was invisible for a session because its symlink was not added.
- **A live-tree symlink is an auto-updating trust surface.** Pointing the consumer at the pack's *working
  tree* (or at `main`) means the next `git pull` changes what every session loads, with no review gate.
  The pack's own `currency-and-audit-before-trust` skill forbids exactly that.
- **One tier serves two audiences that want different things.** The portable rules are for *any* agent
  (and other people); a subset of guidance is specific to one agent runtime (namespacing, hooks,
  slash-commands). Flattening both into one `skills/` dir has no clean home for the agent-specific bits.

## Goal

Make the canonical pack the **single source of truth that consumers pull from, never copy**, on terms
that satisfy the pack's own doctrine:

1. **Two tiers, one repo.** A **portable tier** (agent-agnostic — what other agents and other people
   consume) and an **agent-specific tier** (packaging, hooks, and any rules that only make sense in one
   agent runtime). Placement rules decide where a new lesson lands; the default is portable.
2. **Consume by pinning to an exact commit, materialized immutably read-only, never a live tree.**
   A tag *name* is a movable ref and a working-tree checkout is writable — neither is a trustworthy pin on
   its own (round-1 finding #1). The consumption target is an **immutable, read-only materialization** of a
   specific commit (a read-only export the loader cannot re-checkout); the **pin of record is the resolved
   commit SHA**; the boot check **asserts HEAD == the pinned SHA**. A bump — moving to a new pinned SHA — is
   the only moment new content enters a session, and it is a deliberate, reviewed act. This closes the
   auto-updating-trust-surface hole. *(Signature verification of the commit/tag is an optional later upgrade
   — F4 chose the read-only + SHA base without signing; see Decisions.)*
3. **Package each plugin-packaged tier as a namespaced skills-directory plugin, symlinked once.** One
   symlink per plugin-packaged tier (not one per skill) is designed to end the under-install failure mode
   and bundle any hooks/commands as one versioned unit, namespaced so it can't collide with another pack.
   *(That one-symlink-resolves-every-skill behavior is the design's hypothesis, not yet observed — probe
   P5.)*
4. **Consumers stop vendoring — reversibly.** Retire the copied `skills/`, the sha-pin manifest, and the
   drift-guard, but only **after** the pull layout is proven to resolve the full set on every consumer
   (see slices 4a/4b). Only genuinely project-only methodology stays in the consumer, written as a proper
   project artifact — never re-vendored.
5. **A missing or drifted tier fails loud, not silent.** A dangling tag fails *safe* (the skill is silently
   dropped) — safe is right, silent is not. A **tier-independent** boot check (living **outside** any
   checked plugin, so a dangling tier can't disable it — round-1 finding #3) asserts on every host and
   worker that (a) the expected skill **set** resolves and (b) HEAD == the pinned SHA, emitting to a named
   human-visible channel.

## Non-goals

- **Not a marketplace/registry distribution *now*.** A marketplace plugin is *copied to a cache* and skips
  outside-symlinks — it would cost the in-place bump. Marketplace-with-ref+sha pins is the right model for
  distributing to *other people*, and building both tiers as real plugins (F2) deliberately keeps that door
  open for later — the packaging is the shared substrate, symlink→pin and marketplace are two modes over it.
  *(The "marketplace skips outside-symlinks" claim is doc-only, not yet probed — see RESEARCH.)*
- **Not a rewrite of the skills' content.** The rules don't change; how the pack is *packaged and pulled*
  changes.
- **Not the consumer's own de-vendoring PR.** That is a downstream change in the consumer's repo (removing
  the vendored files). The consumer is early WIP and freely rewritable, so it needs no ADR ceremony (F3) —
  this brief defines the model it then adopts.

## Decided (owner-confirmed — do not relitigate the decisions; critique the record of them)

- One canonical repo, two tiers (portable + agent-specific); the agent-specific tier is a subtree here (F1).
- Consumption = a consumer's agent-config symlinked to an **immutable, read-only, SHA-pinned materialization
  of a specific commit**; deliberate reviewed bumps; **never `main`, never a live working tree**. (Signing
  is an optional later upgrade, not the base — F4.)
- **Both tiers are namespaced skills-directory plugins, each symlinked once** (F2 — packaging + hooks +
  commands as one versioned unit; the portable tier's manifest is inert to non-Claude agents).
- Porting is **downward/outward**: an agent-native lesson is *generalized and promoted* into the portable
  tier so non-native agents get the idea — not back-ported as-is.
- The consumer **stops vendoring** and consumes from its agent-config like everything else; project-only
  methodology stays in the consumer as a proper artifact, never a bare session note. A project-only lesson
  later assessed as generic is **promoted upward** into the appropriate tier (its own review) rather than
  staying pinned in the consumer.
- Systemic-discovery routing by placement: generic → portable tier, agent-specific → agent tier,
  project-only → the consumer as a project artifact (then promoted upward if it generalizes).

## Forks — resolved 2026-07-18 (recommendation → the owner's decision)

**F1 — Physical layout of the two tiers. → DECIDED: one repo (subtree).** The agent-specific tier is a
**sibling subtree in this same repo** carrying its own `.claude-plugin/` manifest, on the repo's single tag
stream (one bump moves both tiers coherently). Rejected: a second repo with its own tag stream — it
re-introduces the cross-repo version-skew this project removes.

**F2 — Does the *portable* tier also become a one-symlink plugin? → DECIDED: yes.** The portable tier gains
a **thin `.claude-plugin/` manifest over the existing `skills/` dir** so the agent consumes it as one
namespaced plugin via a single symlink — ending per-skill wiring for it too. Content stays agent-agnostic
(other agents read `skills/<slug>/SKILL.md` by path and ignore the manifest). Accepted cost: skills become
**namespaced** on the plugin path (`<pack>:<slug>`), while bare slugs persist on every other consumption
path (copy-mode, per-slug symlink, and all non-Claude agents) — so an invocation identity **coexists in two
forms across modes**. That split, not a global rename, is the real ripple; SPECS decides whether any prose
may use a bare invocation handle given the ambiguity.

**F3 — Where the consumer's de-vendoring is recorded. → DECIDED: collapsed.** No superseding-ADR ceremony —
the consumer is early WIP and freely rewritable; when it de-vendors, just remove the files. The reusable
consumption guidance lands as an `INSTALL.md` mode here (a full pack skill only if a second project ever
needs it — not speculatively).

**F4 — Tag-bump operating model + the executable-content gate. → DECIDED: read-only + SHA pin, no signing.**
A bump fetches the target commit, resolves its SHA, and **fails loud** on any mismatch with the recorded
pin or any rejected-tag/divergence warning (never trusting `git fetch`'s exit 0; `--force` forbidden), then
materializes it read-only and re-points the symlink. **No signature check in the base** — signing is the
deferred upgrade. Because a bump is not a consumer-repo PR, the old "human merge" does not exist — so a bump
whose `hooks/`/scripts differ from the pinned SHA gets a **pre-checkout diff review of the changed
executable content** before it is accepted (round-1 finding #2). Where that review lives per consumer class
is named in the inventory below.

**F5 — Distribution to the fresh-clone worker and a separate worker UID. → DECIDED: each worker
self-materializes (B), kept simple.** Every consumer — including a self-improve worker in a **disposable,
freshly-cloned** workspace and a **separate worker UID** — **materializes its own read-only copy of the
pinned commit at setup** and runs the same boot check. Chosen over a shared host copy because these workers
belong to a consumer that must **spin up on different machines**: a per-worker copy travels, a shared-host
copy assumes a fixed host. The worker copy's tamper-resistance is **not** over-engineered (consistent with
the F4 no-signing choice).

## Consumer inventory (every consumer materializes its own copy — F5=B)

Each consumer materializes its **own** read-only copy of the pinned commit at setup and runs the same boot
check — nothing is shared across a fixed host, so any consumer can spin up on any machine:

1. **Each host's interactive agent-config** — symlink → its own read-only materialization; boot check on.
2. **The self-improve worker's disposable fresh-clone workspace** — materializes the pinned commit at setup;
   same boot check.
3. **A separate worker UID** — its own read-only materialization; boot check on. Tamper-resistance is kept
   simple (F4/F5), not hardened into a security boundary.

The check on a bump for executable content is a **pre-checkout diff review of any changed
`hooks/`/scripts** — the same act everywhere, stated honestly rather than dressed as automation.

## Reviewable slices (roadmap — only slice 1 is in flight)

1. **This BRIEF + RESEARCH + review round 1** — frame + honest evidence, propose-only PR (← in flight).
2. **Run the required probes (RESEARCH backlog) → SPECS + DESIGN + TASKS** — F1–F5 are decided (above); next:
   the read-only-materialization method, the SHA-pin and boot-check mechanics, the bump's
   fail-loud-on-mismatch plus a pre-checkout executable-content review, the per-worker self-materialization,
   and the placement rules, each with acceptance criteria.
3. **Package the tiers** in this repo (add the `.claude-plugin/` manifest(s)) — additive, default-off for
   existing consumers until they switch; gated on the real-pack packaging probe (P10).
4. **Consumer cutover — reversibly.**
   - **4a:** stand up the symlink→pinned-tier layout on **every** host + worker + UID and verify the full
     set resolves (boot check green everywhere), while the vendored copy remains as the default-on
     fallback. Tear down the pre-existing per-slug working-tree symlinks (teardown-first).
   - **4b:** only after 4a passes on all consumers, remove the vendored `skills/` + sha-pin manifest +
     drift-guard (a plain change — no ADR ceremony, F3). Rollback = re-point to the vendored copy.
5. **Reconcile the consumption docs** — update `INSTALL.md` (tag-pinned plugin mode as the
   maintainer-recommended mode, alongside copy/submodule/sync-bot for other-people repos) **and the Claude
   adapter's Install section** (`adapters/claude/CLAUDE.md`, which documents the retired per-skill model
   and is **not** covered by any validator — round-1 finding #8), so no consumption doc names the retired
   model. Write this runbook **before** slice 4 executes.

## Success criteria

- On a plugin-packaged tier, a single symlink resolves **every** skill in that tier, and adding a skill
  needs **no** new symlink *(hypothesis — must be shown by probe P5 before this is claimed)*.
- A fresh session after a bump loads the new pinned content; a session on the old pin does not — because
  the target is immutable and SHA-asserted, not merely a promise to only-checkout-on-bump.
- A dangling, drifted, or partial tier produces a **visible** "methodology missing/drifted" signal on every
  host and worker (tier-independent boot check), not a silent clean start.
- After cutover, `find ~/.claude/skills -type l` on every consumer shows exactly the plugin symlink(s) —
  zero bare per-slug links, zero targets under a live working tree.
- The consuming project holds **zero** vendored skill copies, sha-pins, or drift-guards; its methodology is
  entirely pulled.
- Other-agent consumption (reading `skills/<slug>/SKILL.md` by path) is unaffected by the plugin manifest
  *(reasoned: an inert JSON manifest is not read by agents that address skills by path — not separately
  probed)*.

## Risks & residuals

- **Namespacing splits invocation identity (F2).** Bare and namespaced handles coexist across modes; any
  doc that types a bare invocation handle is correct for most paths and ambiguous for the plugin path.
  Mitigated by keeping content addressable by path (`skills/<slug>/SKILL.md`) unchanged — but path-reading
  is not the same as the invocation name, so SPECS must rule on prose handles.
- **Per-host/UID provisioning is a new under-install surface.** The one-symlink plugin ends per-skill
  under-install **within a wired host**, but each host, worker, and UID must create its own symlink (per-host,
  uncommitted, absolute-pathed, outside any repo → no CI, no drift-guard). Mitigation: the boot check runs
  on **every** consumer so an unwired one fails loud; confirm the checkout path is identical across hosts or
  use a `$HOME`-relative indirection.
- **Executable content on a bump is consequential.** A pre-checkout diff review of any changed
  `hooks/`/scripts (F4) covers it; the boot check verifies presence + SHA, not correctness. This is human
  review, not a machine gate — an accepted limit of the no-signing choice.
- **Trust properties are not yet probed.** The read-only-materialization, SHA-assert, re-pointed-tag, and
  boot-check-fires behaviors are the RESEARCH backlog — the design is specified against them but must be
  observed before slice 3 (honest-reframing: no green is claimed that wasn't measured).
