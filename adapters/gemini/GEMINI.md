# GEMINI.md — Gemini CLI adapter

Gemini CLI loads this file as context. It is a thin pointer, not the rules themselves. The methodology is canonical and lives in **`AGENTS.md`**, with one skill per file at **`skills/<slug>/SKILL.md`**.

Read `AGENTS.md` first. Then, for any non-trivial task, open the SKILL files it points you to and follow them.

## Instruction priority

When guidance conflicts, follow this order:

1. **The user's explicit instructions** — always win.
2. **This methodology** (`AGENTS.md` + the `skills/`) — the default posture for any non-trivial work.
3. **Your built-in Gemini defaults** — only where the two above are silent.

If a user instruction contradicts a principle, do what the user asked; note the trade-off if it matters, but do not override them.

## How to use it

1. Read `AGENTS.md` — it is the index and the source of truth.
2. Match the task to its principles; most non-trivial work touches two or three.
3. Open `skills/<slug>/SKILL.md` for each match and follow the rules, red-flags, and examples there. The paragraphs in `AGENTS.md` are only the index; the SKILL files carry the detail.
4. For non-trivial work, follow the relevant process skill **before** writing code — don't implement first and back-fill the process.

"Non-trivial" means anything beyond a one-file, fully-understood change. When in doubt, treat it as non-trivial.

## Available skills

`spec-driven-development` · `environment-research` · `adversarial-lens-review` · `hexagonal-with-enforced-contracts` · `configuration-single-source-of-truth` · `dev-environment-facade` · `surgical-changes-with-checkpoints` · `additive-default-off-feature-flags` · `battle-testing-on-real-infra` · `acceptance-tests-observable-outcomes` · `grounded-verifiable-gates` · `definition-of-done-tooling` · `honest-reframing-over-overclaiming` · `currency-and-audit-before-trust` · `evidence-over-deference` · `reversible-by-default-confirm-consequential` · `structural-security-boundary` · `secrets-and-teardown-discipline` · `docs-as-deliverable` · `decision-memory` · `autonomous-self-improvement-loop-safety` · `parallel-agent-fan-out`

## A note on tools

The methodology speaks in **actions**, not tool names — "run the test suite against real infrastructure," "create a checkpoint commit," "gate a consequential action behind a human approval pause." Map each action to whatever Gemini CLI gives you (shell execution, file edits, web fetch, MCP servers). Where a rule names a capability you don't have, use the nearest equivalent or do it manually; never skip the rule because the exact tool isn't wired up.

## Install

Copy this file to your project root as `GEMINI.md`, and make the methodology pack reachable from there — vendor or symlink `AGENTS.md` and `skills/` alongside it (or point the references at wherever the pack lives). The paths above are relative to the pack root; keep them resolvable from the project.
