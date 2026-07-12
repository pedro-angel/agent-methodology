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

### environment-research

- Before a spec or plan depends on a dependency's real behavior, state a precise hypothesis about its execution, outcome, error, and boundary modes, then write the smallest experiment that could falsify it and run it against the real thing.
- Provoke failure modes on purpose — a mode you never triggered is one you didn't characterize. Record what you saw, not what you expected; when the observation contradicts the docs, design against the observation and write the divergence into the spec or the code.

### adversarial-lens-review

- An author cannot grade their own work. At the spec→plan, plan→code, and code→merge gates, dispatch a fresh reviewer per binding named lens (spec: factual-grounding, completeness, design-flaw, testability; plan: spec-coverage, testing-and-trackability, sequencing-and-anti-hubris; implementation: spec-compliance, then code-quality) instructed to enumerate problems, not fix them.
- Require severity-graded findings (`BLOCKER`/`MAJOR`/`MINOR`) and loop until every BLOCKER and MAJOR clears. The reviewer's context must stay separate from the author's — sunk cost in the work disqualifies a reviewer.

### hexagonal-with-enforced-contracts

- Isolate a framework-free domain at the center; let it speak only to **ports** (abstract interfaces). Every external system (LLM, DB, cloud SDK, HTTP API) is an **adapter** implementing a port. The domain imports no vendor SDK.
- Make a machine enforce the boundary, not discipline: an import-linter contract, a CI layering rule, or an architecture test that fails the build the moment domain code reaches for an adapter or concrete dependency.

### configuration-single-source-of-truth

- Collapse every value that would otherwise be duplicated (project id, model name, threshold, rubric, region) to one authoritative source.
- Read it at one layer and pass it down; never re-declare it in build scripts, docs, and code. "What value is in effect?" must have exactly one answer.

### dev-environment-facade

- One dev-workflow surface: a self-documenting Makefile (bare `make` prints annotated help) whose recipes are one-liners delegating to `scripts/`; where the facade and a certifying gate share a command, the strings stay character-identical and grep-checked.
- Targets come from the shared cross-repo vocabulary (canonical list: the skill's `vocabulary.txt`, reference checker beside it): universal `help`/`setup`/`test`/`check`/`clean`/`dod`; family verbs, none without its capability, required exactly when it fires unless the manifest role says optional or mutating — `stack-start/stop/status/destroy`, open `test-<tier>` (bare tier names are never targets), `build`, `lint`/`fix`/`audit`/`sast`/`hooks`, `docs`/`docs-serve`, `clean-all`; project-specific names stay free but never rebind a standard name or prefix; no aliases.
- A shared name keeps one promise in every repo: `check` runs at least the read-only quality leaves whose capability fires + unit suite + docs build where docs exist (`fix` never joins `check`; not "whatever CI runs"), and a backend's verb is borrowed only while the target delivers at least the verb's home meaning and destroys nothing that meaning leaves intact (compose `down` keeps volumes — say `destroy`).
- Split env files by owner: the provisioning script is the only writer of the machine file (atomic rename; keep a still-valid credential, validated against an endpoint probed to discriminate); no script ever writes or deletes the user file.
- Consumers load env in-process at fixture time (never conftest import — collection imports deselected conftests), shell env wins with a warning on differing shadows; absent env file → skip, present-but-broken → hard fail, so a gate can't pass on zero executed tests.

### surgical-changes-with-checkpoints

- Change exactly what the task requires and nothing more. Restate the goal in one sentence, touch only what that sentence demands, and note unrelated improvements separately. Match surrounding conventions.
- Before risky work (migrations, dependency bumps, refactors, infra changes), create a known-good fallback first — a checkpoint commit, a stash, a throwaway branch, a tagged snapshot.
- Split commits by reason (one motivation each, conventional type prefix). Write each as a decision record: what changed, why, and the evidence that proves it correct. When restoring prior content, copy it verbatim from a named version and say so.

### additive-default-off-feature-flags

- Add any new capability additively — behind a flag or as an optional collaborator — so the default path stays the prior, proven behavior.
- Keep the new code inert until something explicitly opts in (env flag, config toggle, injected non-default implementation, optional dependency). Roll forward and back by flipping the switch, not reverting code; the blast radius starts at no one.

### battle-testing-on-real-infra

- Before calling any integration, deployment, or hard guarantee "done," prove it end-to-end against the **real** systems — live API, real database, actual deployed runtime.
- Record the run as a named evidence artifact (results file, captured log, saved response) someone else can open. Mocks prove wiring, not external reality (auth scopes, quota, serialization, cold starts, IAM propagation).
- Treat the spec as a hypothesis and the running system as ground truth: implement what the server does and record each divergence in the code. When a path's happy case needs infra you lack, drive the real route and assert its exact semantic rejection rather than dropping to mocks; mark a path untested only when even that is impossible, naming what's missing. Round-trip a model-backed feature through a real local model, not a mock.

### acceptance-tests-observable-outcomes

- Completion is defined by what a user or caller observes, not which code paths ran: for each observable success criterion in the spec, write an executable acceptance test against the real system, derived from the spec before or independent of the implementation.
- Assert the semantic essentials (the value, the status, the substring that matters) and tolerate incidental formatting the spec never promised. Run teardown unconditionally, whether the assertions passed or failed. Treat a red or missing acceptance test, not a green unit suite, as the real "not done yet" signal.

### grounded-verifiable-gates

- When an LLM or agent produces a decision or claim, convert it into a verifiable signal: grounding invariants (every claim cites a real source span; every cited id exists), a deterministic gate that yields pass/fail or a score, and a CI-able eval harness that runs the gate over a fixed corpus on every change.
- Trust the gate's verdict over the output, never the raw model output as a result. The harness is your regression net for silent degradation.

### definition-of-done-tooling

- The author never self-certifies "done" — a script does. Declare every completion criterion in a small config as `required` or `n/a`, back every `required` line with a real runnable check, and run them all through one gate that emits a single GO or NO-GO.
- Mark `n/a` as a visible, reviewable decision in the config, never a silent deletion. On NO-GO, fix the failing criterion and re-run — never edit the config to force a pass. Wrap the project's existing CI entrypoint rather than re-implementing it inline.

### honest-reframing-over-overclaiming

- When a live result contradicts the story you hoped to tell, rewrite the **claim** to match the measurement, carrying the exact numbers ("ranked #3," not "ranks #1"). Cite only a number you measured.
- Never bend tests, fixtures, thresholds, or labels to manufacture a pass; never touch ground truth to win — if changing a fixture seems necessary, stop and get explicit agreement first.
- Propagate every correction to every artifact it appeared in. Keep good and bad cases in the corpus so a detector that flags everything still fails. Defer honestly, naming the exact missing precondition.

### evidence-over-deference

- When a request rests on a premise you can check in seconds, check it before executing. If the evidence contradicts the premise — or the request conflicts with a recorded principle — say so **once**, with the finding, its source, and a concrete alternative, before acting.
- When the human proposes a direction rather than asserting a fact, weigh the strongest real alternative yourself — with its cost — before adopting or rejecting it; a stance that mirrors the asker carries no information.
- The human's decision wins after being heard: execute it fully, record consequential dissent where the decision is recorded, and don't relitigate without new evidence.
- Challenge is symmetric: surface your own uncertainty and invite correction; concede on evidence without performative agreement.

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

### parallel-agent-fan-out

- When you fan out many write-capable sub-agents across one build (N modules, endpoints, call-sites), design the independence in and trust no report out.
- Pre-wire the shared seams (registry, stubs, fixtures) yourself so each agent fills only a leaf; give each a disjoint file-ownership manifest and revert violations rather than merge them; serialize the join so only the coordinator edits shared seams.
- On shared live substrate, namespace every resource an agent creates and forbid it touching anything it didn't create, cleaning up in a finalizer. Re-run each agent's own gate yourself (tests, types, lint, live run) against the merged tree, believing the exit code not the prose. Cut along real independence — if two units must edit the same file, they are one unit.

## Install

Copy this file to `<project>/.github/copilot-instructions.md`. Ship `AGENTS.md` and the
`skills/` tree alongside it (repo root) so the pointers resolve and Copilot — or any other
coding agent — can load the full rule when a task calls for it.
