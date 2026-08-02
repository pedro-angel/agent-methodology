# BRIEF — a canonical terse agent layer, with AGENTS.md as the human book

*Status: **DRAFT for owner review** — nothing decided, forks open. Date: 2026-08-02. This is the WHAT
and WHY: the problem, the proposed model, the forks the owner must decide, and what would prove it
done. Feeds: RESEARCH → SPECS → DESIGN → TASKS once the forks are decided.*

## Problem

The pack's prose is written for two audiences at once and serves the agent one badly.

- **The always-on surface is the wrong shape for agents.** `AGENTS.md` is ~30 KB (~7k tokens) of
  narrative — provenance stories, worked examples, cross-reference essays. The Claude adapter tells
  every session to read it; a session that obeys spends those tokens on prose written to persuade a
  human, and a session that doesn't is governed by nothing. Observed on the owner's own machine: the
  rules bound nobody until a 30-line `~/.claude/CLAUDE.md` was written by hand — a file the pack
  neither ships nor derives.
- **The condensed form exists but is unowned.** The Cursor and Copilot adapters each carry a
  hand-maintained one-line-per-skill index — the terse form agents actually need — kept in sync with
  `AGENTS.md` by machine checks that verify *presence*, not *fidelity*. Three prose renderings of
  every rule now exist (SKILL.md, AGENTS.md paragraph, adapter line), and the destructive-scope audit
  of 2026-08-02 showed they drift in exactly the dangerous direction: the adapters had stripped the
  ownership scopes their sources carried ("Run teardown unconditionally.").
- **Rules, workflows, and reference are one undifferentiated genre.** The owner's stated discovery:
  some "skills" were never optional workflows — they were rules wanted always-on. The every-turn
  communication rules already escaped skill-space for this reason; nothing classifies the remaining
  content, so each future rule will re-fight that placement battle.

## Proposed model (to review, not yet decided)

One canonical terse layer, machine-derived consumers, AGENTS.md rewritten as the human book.

- **`rules/` — the new canonical agent layer.** Every principle as imperative rules, each rule one
  sentence plus at most one why-clause (zero-rationale imperatives measurably degrade compliance;
  narrative belongs to the book). Explicitly classified: `always` (bind every turn → memory files,
  hook-injected context), `task` (bind when matched → skills), `reference` (bind when consulted).
- **Consumers derive, never hand-copy.** The Cursor/Copilot adapters and a shipped
  `CLAUDE.local`-style always-on file become *generated* from `rules/` (or byte-checked against it),
  the way `templates/git-controls` already mirrors `scripts/checks/` — fidelity enforced, not
  presence.
- **`AGENTS.md` becomes the human book.** Provenance, worked examples, the "why" essays — for the
  reader who wants to understand, linked from every rule, loaded by no agent by default.
- **`SKILL.md` files stay** as the on-demand deep layer for task-matched work (rules point into
  them; the skills keep red-flags and worked examples).

## Evidence this is worth doing

- The owner's direct request (2026-08-02): human docs with explanations linking to terse prose
  dedicated to agents; agents "are more efficient communicating than us humans".
- The 2026-08-02 audit: sentence-level scope drift between the three renderings, in the
  destructive-verb class — the class with the worst failure mode.
- The delivery gap PR #31 closed for six rules exists for every other always-on candidate: nothing
  makes a rule reach a session unless it lands in a memory file or hook by hand.

## Non-goals

- No change to the 22-skill set's content or the tier/packaging model (SPECS v6 stands).
- No new agent targets; the four adapters remain the consumer set.
- No generation tooling beyond what the repo's existing check patterns support (POSIX sh, byte
  comparison) unless RESEARCH proves it insufficient.
- The standing placement constraint holds: nothing Claude loads grows to serve another agent.

## Forks for the owner

- **F1 — derivation direction.** (a) `rules/` is source; adapters + always-on file are generated
  artifacts committed alongside (a build step, mirrors-in-sync check), or (b) `rules/` is source;
  consumers are hand-edited but byte-diff-checked against a rendered form (no generator, stricter
  authoring). (a) removes drift by construction; (b) keeps the toolchain zero-build.
- **F2 — what Claude consumes always-on.** (a) The pack ships a canonical always-on file the
  consumer symlinks/copies into `~/.claude/CLAUDE.md` (single source, but overwrites a user's
  personal file — merge question), or (b) the pack ships it as a fragment the user's file imports,
  keeping personal content separate. (b) fits the existing hand-written `~/.claude/CLAUDE.md`.
- **F3 — classification of the 22.** Which existing skills carry `always`-class rules that should be
  extracted into the always-on layer (candidates from the owner's history: verification-before-claims,
  destructive-verb scoping, evidence-over-deference's premise-check)? Needs a one-pass triage with
  the owner, not a unilateral call.
- **F4 — scope of the first slice.** Everything at once, or the proven pattern: one skill's rule
  rendered, derived, checked, consumed — then the sweep.

## Done means

- An agent session loads ≤ a stated token budget of always-on rules (budget decided in SPECS), and
  every rule in it traces to `rules/`.
- A fidelity check (not a presence check) fails CI when any consumer rendering drifts from source.
- The Cursor/Copilot adapters carry no hand-maintained rule text.
- `AGENTS.md` reads as a book; no agent is instructed to read it wholesale per session.
- The scope guarantees from the 2026-08-02 audit survive verbatim in every rendering — asserted by
  the fidelity check, not re-audited by hand.
