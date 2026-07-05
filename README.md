# Agent Methodology

[![checks](https://github.com/pedro-angel/agent-methodology/actions/workflows/checks.yml/badge.svg)](https://github.com/pedro-angel/agent-methodology/actions/workflows/checks.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A portable engineering methodology for AI coding agents, distilled from one real, shipped build: a hexagonal, human-in-the-loop AI agent deployed to a serverless cloud runtime, behind a framework-free domain, with a CI-able eval harness gating its LLM decisions. Every rule here earned its place by surviving that build — docs that drifted from code, integrations that passed mocks and failed live, models that over-flagged, secrets, and teardown. The result is provenance you can trust without lore you have to learn: nothing below assumes a particular language, framework, or agent runtime, and you never need to know the source project to apply a single rule.

## Philosophy

- **Process before code.** For anything non-trivial, run the relevant process skill *before* implementing — don't back-fill the design after the fact.
- **Machines enforce, not memory.** A linter, a gate, an eval harness — encode the discipline so it survives the next contributor who didn't read this.
- **Reality is the only proof.** Mocks prove wiring; only a live run against real infrastructure proves the guarantee. An unverified claim is a hope.
- **Reversible by default, a human on the irreversible 1%.** The cheap, undoable work flows freely; consequential acts pause for explicit approval.

## Skill index

Match your task to the skills below — most non-trivial work touches two or three — then read the full `SKILL.md` for each match before acting.

| Skill | When to use |
| --- | --- |
| [spec-driven-development](skills/spec-driven-development/SKILL.md) | Starting any non-trivial feature, or when docs and code have drifted — write the BRIEF → RESEARCH → SPECS → DESIGN → TASKS chain before or alongside the code, and reconcile specs onto what actually shipped. |
| [hexagonal-with-enforced-contracts](skills/hexagonal-with-enforced-contracts/SKILL.md) | Building anything that touches external systems (LLMs, databases, cloud SDKs, HTTP APIs) — isolate a framework-free core behind ports, and let an import-linter, not reviewer discipline, fail the build on a boundary violation. |
| [configuration-single-source-of-truth](skills/configuration-single-source-of-truth/SKILL.md) | A value (project id, model name, threshold, rubric) would otherwise be duplicated across build scripts, code, docs, and CI — collapse it to one authoritative source everything else derives from. |
| [surgical-changes-with-checkpoints](skills/surgical-changes-with-checkpoints/SKILL.md) | Every edit — make the smallest correct diff, save a known-good checkpoint before risky work, and write each commit so a stranger can see what changed, why, and what proved it correct. |
| [additive-default-off-feature-flags](skills/additive-default-off-feature-flags/SKILL.md) | Adding a capability to a system that already works — ship it behind a default-off switch or optional collaborator so the proven path stays untouched and the blast radius starts at zero. |
| [battle-testing-on-real-infra](skills/battle-testing-on-real-infra/SKILL.md) | About to call an integration, deployment, or durability guarantee "done" — prove it live, end-to-end, against the real systems and capture the run as an evidence artifact someone else can open. |
| [grounded-verifiable-gates](skills/grounded-verifiable-gates/SKILL.md) | An LLM or agent emits a decision or claim that drives what happens next — force every claim to cite real source text, gate it with a deterministic function, and guard that function with a CI eval harness. |
| [honest-reframing-over-overclaiming](skills/honest-reframing-over-overclaiming/SKILL.md) | A live result contradicts the hoped-for story, or a metric is one tweak from green — rewrite the claim to the measured number; never bend tests, fixtures, thresholds, or ground truth to manufacture a pass. |
| [reversible-by-default-confirm-consequential](skills/reversible-by-default-confirm-consequential/SKILL.md) | An agent or automation can touch systems you don't own (ticketing, repos, email, payments, prod data) — stay read-only/reversible by default and gate consequential acts behind a durable human approval. |
| [structural-security-boundary](skills/structural-security-boundary/SKILL.md) | Containing untrusted or agent-generated execution — put the real boundary in a layer the actor can't reach (separate UID, read-only mount, namespace), keep string guards as fail-toward-ask defense-in-depth, and pin what you can't yet enforce. |
| [secrets-and-teardown-discipline](skills/secrets-and-teardown-discipline/SKILL.md) | Handling credentials, infrastructure-as-code, or ephemeral cloud — make secrets structurally un-committable, grant least privilege, tear down what you stood up and verify it reached zero, and own only your scope. |
| [docs-as-deliverable](skills/docs-as-deliverable/SKILL.md) | Shipping or handing off code — treat docs as first-class: present-tense prose, diagrams authored as code, every claim verified against the running reality, comprehension proven by an actual reader. |
| [decision-memory](skills/decision-memory/SKILL.md) | A decision, gotcha, or preference would otherwise be re-derived next session — capture it as a small, dated, indexed note at the moment of discovery, and verify a note still holds before trusting it. |
| [autonomous-self-improvement-loop-safety](skills/autonomous-self-improvement-loop-safety/SKILL.md) | Building automation that edits, tests, or deploys itself — disposable fresh-clone per cycle, decide success by a mechanical check not the worker's word, bind tested==shipped, and keep an adversarial pass plus a human on the merge. |

## Repo layout

```text
AGENTS.md     Canonical methodology — the single source of truth. Read this first.
skills/       One directory per skill; each holds a SKILL.md with rules, red-flags, and worked examples.
adapters/     Per-agent entry points (claude/, cursor/, copilot/, gemini/, …) that point back to AGENTS.md.
INSTALL.md    How to wire this pack into your agent.
README.md     This file.
```

`AGENTS.md` is canonical: the skills are its detail, and the adapters are per-agent entry points. The Claude and Gemini adapters are thin pointers back to `AGENTS.md`; the Cursor and Copilot adapters inline a *condensed index* (those tools don't reliably follow a bare pointer) that is kept in sync with this file and still directs the reader to the full `SKILL.md` for detail. The methodology speaks in **actions** — "run the test suite against real infrastructure," "create a checkpoint commit," "pause for human approval" — so it applies whether your tool is Claude Code, Cursor, GitHub Copilot, Gemini CLI, Codex, or anything else. Where a capability is agent-specific, the skills name two or three equivalents rather than assuming one runtime.

## Quickstart

Drop the source of truth and the skills into your project, then add your agent's adapter:

```bash
PACK=/path/to/agent-methodology   # this repo
PROJECT=/path/to/your/project     # where you're installing it
cp "$PACK/AGENTS.md" "$PROJECT/AGENTS.md"
cp -R "$PACK/skills"  "$PROJECT/skills"
cp "$PACK/adapters/claude/CLAUDE.md" "$PROJECT/CLAUDE.md"   # or cursor / copilot / gemini
```

That is the whole install for most agents. See [INSTALL.md](INSTALL.md) for every agent, the symlink/submodule options, and how to keep it updated.

## Deterministic git controls (optional)

[`templates/git-controls/`](templates/git-controls/) packages the same machine-checks that guard this repo — a pinned pre-commit config, a CI workflow, and zero-dependency POSIX-sh validators — so you can drop them into any prose- or spec-shaped repo and have a broken invariant fail like a red build instead of slipping past review. See its [INSTALL](templates/git-controls/INSTALL.md).

## License, provenance & prior art

Released under the [MIT License](LICENSE) — copy it into your own projects, proprietary ones included, with no obligation beyond keeping the copyright notice. The author owns this material and releases it freely; the "real, shipped build" it was distilled from is used only as an illustrative source, and its identifying details have been genericized — you never need to know that project to apply a rule.

This pack follows two open conventions it does not own — the [`AGENTS.md`](https://agents.md) root-instruction convention and the `skills/<slug>/SKILL.md` Agent Skills format — while the methodology content itself is original.

*Claude, Cursor, GitHub Copilot, and Gemini are trademarks of their respective owners; this project is independent and not affiliated with or endorsed by any of them.*
