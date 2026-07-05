# Copilot custom instructions — Engineering Methodology

GitHub Copilot reads this file automatically. These are condensed, imperative rules
distilled from a portable engineering methodology. The full source of truth is
`AGENTS.md` at the repo root; each rule below maps to a skill at
`skills/<slug>/SKILL.md` with the red-flags, worked examples, and edge cases.
**Load the full skill before doing non-trivial work in its area** — these lines are an
index, not the whole rule.

## Priority when guidance conflicts

1. The user's explicit instructions win.
2. This methodology — the default for any non-trivial work.
3. Your built-in defaults — only where the two above are silent.

If the user contradicts a rule here, do what they asked; note the trade-off, don't override them.

## Before you act

Match the task to the rules below (most non-trivial work touches two or three), open the
matching `skills/<slug>/SKILL.md`, and run the relevant **process** skill *before*
implementing — write the spec chain before the feature, set up ports and the boundary check
before touching an external system, define the gate before shipping an LLM decision. Never
back-fill process after the code. "Non-trivial" = anything beyond a one-file, fully-understood change.

## The rules

### spec-driven-development

- For any non-trivial feature, write the design chain — BRIEF → RESEARCH → SPECS → DESIGN → TASKS — before or alongside the code, each phase consuming the one before it.
- Keep *what* (SPECS: behaviors, acceptance criteria) separate from *how* (DESIGN: architecture, trade-offs) so a reviewer can reject a wrong requirement before you build for it.
- Gate each phase behind a review and record the verdict in the doc. When code diverges, reconcile the spec onto the shipped code and bump its version. Strike through resolved open items, don't delete them.

### hexagonal-with-enforced-contracts

- Isolate a framework-free domain at the center; let it speak only to **ports** (abstract interfaces). Every external system (LLM, DB, cloud SDK, HTTP API) is an **adapter** implementing a port. The domain imports no vendor SDK.
- Make a machine enforce the boundary, not discipline: an import-linter contract, a CI layering rule, or an architecture test that fails the build the moment domain code reaches for an adapter or concrete dependency.

### configuration-single-source-of-truth

- Collapse every value that would otherwise be duplicated (project id, model name, threshold, rubric, region) to one authoritative source.
- Read it at one layer and pass it down; never re-declare it in build scripts, docs, and code. "What value is in effect?" must have exactly one answer.

### surgical-changes-with-checkpoints

- Change exactly what the task requires and nothing more. Restate the goal in one sentence, touch only what that sentence demands, and note unrelated improvements separately. Match surrounding conventions.
- Before risky work (migrations, dependency bumps, refactors, infra changes), create a known-good fallback first — a checkpoint commit, a stash, a throwaway branch, a tagged snapshot.
- Split commits by reason (one motivation each, conventional type prefix). Write each as a decision record: what changed, why, and the evidence that proves it correct. When restoring prior content, copy it verbatim from a named version and say so.

### additive-default-off-feature-flags

- Add any new capability additively — behind a flag or as an optional collaborator — so the default path stays the prior, proven behavior.
- Keep the new code inert until something explicitly opts in (env flag, config toggle, injected non-default implementation, optional dependency). Roll forward and back by flipping the switch, not reverting code; the blast radius starts at no one.

### battle-testing-on-real-infra

- Before calling any integration, deployment, or hard guarantee "done," prove it end-to-end against the **real** systems — live API, real database, actual deployed runtime.
- Record the run as a named evidence artifact (results file, captured log, saved response) someone else can open. Mocks prove wiring, not external reality (auth scopes, quota, serialization, cold starts, IAM propagation). If real infra is unavailable, mark that path explicitly untested.

### grounded-verifiable-gates

- When an LLM or agent produces a decision or claim, convert it into a verifiable signal: grounding invariants (every claim cites a real source span; every cited id exists), a deterministic gate that yields pass/fail or a score, and a CI-able eval harness that runs the gate over a fixed corpus on every change.
- Trust the gate's verdict over the output, never the raw model output as a result. The harness is your regression net for silent degradation.

### honest-reframing-over-overclaiming

- When a live result contradicts the story you hoped to tell, rewrite the **claim** to match the measurement, carrying the exact numbers ("ranked #3," not "ranks #1"). Cite only a number you measured.
- Never bend tests, fixtures, thresholds, or labels to manufacture a pass; never touch ground truth to win — if changing a fixture seems necessary, stop and get explicit agreement first.
- Propagate every correction to every artifact it appeared in. Keep good and bad cases in the corpus so a detector that flags everything still fails. Defer honestly, naming the exact missing precondition.

### reversible-by-default-confirm-consequential

- Keep any agent or automation read-only or reversible by default. Default to dry-run, preview, or staged output.
- Gate consequential, hard-to-undo actions (writing to a system of record, sending a message, deleting data, spending money, mutating prod) behind a **durable** human-approval pause — a state a person can inspect and explicitly approve or reject, not a fire-and-forget prompt that times out into doing the thing.

### structural-security-boundary

- When code you don't fully trust will execute (an agent worker with write/exec tools, generated or third-party code, a privileged control store), put the **real** trust boundary in a layer the actor cannot reach: a separate identity that gets a permission error, a read-only mount, dropped capabilities, or a VM. A shared-kernel container only reduces blast radius; it does not fully contain a determined attacker.
- Pattern and command guards are labelled defense-in-depth that **fail toward asking**, never the boundary — prefer an allow-list fast-path plus deny-by-default, and deny on absent or ambiguous input. Grant least privilege and let a machine enforce the seam. When you can't reach the structural bar yet, name the residual and pin it as a passing-by-design test; never self-certify a trust-boundary change.

### secrets-and-teardown-discipline

- Make secrets structurally un-committable: gitignored secret files, env injection, or a secret manager — never a literal in source or history.
- Grant least privilege (narrowest scope and role that works). Tear down what you stood up, and **verify** the teardown left zero behind instead of assuming. Own only your scope — never delete shared or pre-existing resources you didn't create.

### docs-as-deliverable

- Treat documentation as first-class as the code: tight, present-tense prose describing what the system *does*, not what it might do.
- Author diagrams as code (so they version and stay current) over screenshots that rot. Verify every claim against the running reality, and validate the result with an actual reader who can follow it without you in the room.

### decision-memory

- Capture a decision, gotcha, or preference at the moment of discovery as a small, dated, indexed note — what was decided or learned, and why — so it's figured out once.
- Keep notes short and linked from an index, not buried in prose. Before trusting an existing note, verify it still holds; stale memory confidently asserted is worse than none.

### autonomous-self-improvement-loop-safety

- When automation acts on its own substrate (an agent that edits, tests, or deploys its own repo), run each cycle in a disposable, freshly-cloned workspace and destroy it after. Decide success by a **mechanical** version-control check, never the worker's own "done." Bind tested==shipped so the revision that passed the gate is the one that ships.
- Keep a recurring adversarial self-review that assumes the gate is blind on every trust-boundary change; stay propose-only with a human (or a credential that structurally cannot merge) on the landing; sandbox the write-capable worker structurally, not by prompt. Label every step real or mock and fail closed on mock.

## Install

Copy this file to `<project>/.github/copilot-instructions.md`. Ship `AGENTS.md` and the
`skills/` tree alongside it (repo root) so the pointers resolve and Copilot — or any other
coding agent — can load the full rule when a task calls for it.
