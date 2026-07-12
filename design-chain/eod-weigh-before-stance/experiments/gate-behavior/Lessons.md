# Lessons — gate-behavior probe (2026-07-12)

Probed the repo's own pre-commit/CI gates in the worktree before the SPECS
phase leans on them. All three hypotheses confirmed by running the real hooks
(see `decisions.jsonl`); the SKILL.md mutation was reverted after observation.

1. **The machine forces only SKILL.md itself.** A description/trigger change
   passes all 17 hooks green with zero other files touched — observed, not
   inferred. The sync of the four prose paraphrases (AGENTS.md:88 paragraph,
   README.md:34 table row, adapters/cursor/methodology.mdc:26,
   adapters/copilot/copilot-instructions.md:100-104) is pure convention and
   will drift silently if the change forgets them. The SPECS must list those
   four as explicit acceptance criteria precisely because no gate will.
2. **Description shape is a hard boundary.** One physical line starting
   `description: Use when` plus a space — a folded scalar fails with a misleading error
   text ("must start with 'Use when '" even though the folded text did). No
   length cap: MD013 is disabled.
3. **Commit gates behave as documented.** Conventional scoped type +
   any-of-five provenance trailers; `feat(evidence-over-deference): ...` with
   sign-off passes both.

**Graduation decision: keep.** Findings feed RESEARCH.md §Constraints. The
scratch/ dir (mutation scripts, msg fixtures) is disposable.
