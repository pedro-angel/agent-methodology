# SPECS — packaging & consuming the pack as tiered, SHA-pinned, read-only plugins (v5, lean)

*Consumes: [BRIEF.md](BRIEF.md) (Decisions F1–F5), [RESEARCH.md](RESEARCH.md) +
[experiments/probe-run-2026-07-18.md](experiments/probe-run-2026-07-18.md) (P5–P10). Feeds: DESIGN. Date:
2026-07-18. Review history: [round 1](reviews/spec-adversarial-round-1.md) →
[round 2](reviews/spec-adversarial-round-2.md) → [round 3](reviews/spec-adversarial-round-3.md) →
[round-4 verification](reviews/spec-verification-round-4.md). **v4 was the lean pivot; v5 applies the
round-4 verification** — honesty + subtraction: REQ-4b's self-improve-safety claim is downgraded to what
this layer delivers, the vacuous "unprovisioned-pin" check is deleted, export fidelity is guaranteed at
produce time, and the boot-check-liveness promise is scoped honestly. Removed machinery (distributed approval
record, `CORRUPTED`, generation GC, fleet conformance) is deferred residuals R1–R5. Specifies WHAT must hold;
scripts/manifests are DESIGN's. Scope: the maintainer's own multi-host consumption — marketplace and signing
are out (F4, Non-goals).*

## The records (fixed once)

- **Materialization** — a read-only export of one commit (no `.git`), holding the skill content and one
  frozen descriptor: `.skillset`, the skill-slug set auto-derived from the export's own `skills/*/` at
  export time (never hand-maintained). A `.pinned-sha` provenance label may accompany it, but it is **not** a
  boot-time integrity oracle (nothing in a `.git`-less export recomputes it).
- **Symlink target** — the atomically-published `~/.claude/skills/<tier>` → a materialization. The **sole
  per-consumer record** of which pin the consumer is on. Nothing external anchors it.
- **The pin** — which SHA a consumer is on is set by the **operator** (per consumer) after the operator
  reviews the bump (REQ-4). There is no distributed approval artifact; the operator's act of setting the pin
  *is* the approval.

## Requirements

**REQ-1 — Two tiers, one repo (F1).** A **portable tier** (`skills/` + `AGENTS.md` + adapters,
agent-agnostic) and an **agent-specific tier** as a sibling subtree — its own `.claude-plugin/` manifest, any
hooks/commands, and rules that only make sense in one agent runtime — both on the repo's single tag stream.

**REQ-2 — Both tiers are namespaced skills-directory plugins (F2).** Each tier carries a
`.claude-plugin/plugin.json` over a `skills/` dir and is consumed via **one symlink** into
`~/.claude/skills/<tier-name>`; when loaded, its inventory lists **every** skill in the tier. Skills are
namespaced per the F2 decision. The portable tier's manifest is inert to non-Claude consumers, which read
`skills/<slug>/SKILL.md` by path. *(Proven scope, P5/P10: one symlink lists every skill; a skill added to the
target is listed after a fresh read with no new symlink. The `<tier>:<slug>` form is the F2 decision,
annotated by P3 which RESEARCH marks a reconstruction.)*

**REQ-2b — Prose addresses skills by path, not invocation handle (F2 residual).** No methodology prose or
cross-link relies on a bare or namespaced invocation handle; references use `skills/<slug>/SKILL.md`.

**REQ-3 — Immutable, read-only, SHA-pinned materialization; the symlink target is the sole local record
(F4).** The consumption target is a materialization (above), read-only. The boot check and every consumer
read only the symlink target and the `.skillset` frozen inside it; there is no external record. *(Proven:
P7 — export has no `.git`, read-only blocks edits.)*

**REQ-4 — Operator bump: one resolved SHA, diff review, fail-loud, no `--force`, no signing (F4).** An
operator bump (a human act, on the operator's machine) resolves **one** target SHA **once** and uses it for
the diff, the export, and the pin it sets (no re-resolution — closes the review-vs-ship TOCTOU). It **fails
loud** (non-zero, stderr) on any mismatch with the operator's intended SHA or a rejected-tag/divergence
condition, never trusting a fetch's exit status, and refuses `--force`. Before setting the new pin it
presents `git diff <old-pin> <new-pin> -- hooks scripts` (first bump diffs against empty) for the operator to
review — the human step that gates executable content. For a fresh consumer with no prior pin, executable
content is covered by the operator's **cumulative** bump reviews of that SHA, not a per-consumer diff. No
signature check (deferred). *(Proven scope: P6 — a new pin changes content, old pin untouched; P8 — a moved
tag's SHA mismatch is caught by `rev-parse`.)*

**REQ-4a — Atomic publish; produce-time fidelity; idempotent retry.** Producing/replacing a materialization
is all-or-nothing: export into a unique temp path, **verify the export equals the resolved commit's tree**
(the export command is exit-checked and its content compared to the commit — a truncated or disk-full export
**fails loud**, since read-only + `MISSING`/`PARTIAL` cannot catch an export that never matched the pin), set
read-only, then publish by an **atomic** symlink replace (`mv -T`) — no missing/half-written-target window.
An interrupted bump leaves the prior pin intact; retry is idempotent; the orphaned temp export is reaped. A
reap never deletes the **current or immediately-previous** target while a boot check or skill read may hold
it. *(Concurrent bumps on one consumer are out of scope — residual R1.)*

**REQ-4b — Automated materialization installs the operator-provided pin, headless.** A host, the disposable
fresh-clone worker, or a separate UID materializes the **SHA its provisioning was given by the operator** and
runs the boot check. It **does not resolve or choose a SHA itself**, and there is no human gate to deadlock a
headless run. *(Scope: this delivers "the materialize step does not pick its own SHA." End-to-end
self-improve-safety — an untrusted worker cannot tamper with what it runs post-materialize — is the
**consumer's** structural boundary (separate UID / read-only mount + propose-only review; ADR-0007/0008-class),
NOT this packaging layer, which REQ-6 states is not a security boundary. Residual R4.)*

**REQ-4c — One rollback copy.** Retain the **previous** materialization so rollback (REQ-8) has a target;
reap older materializations opportunistically at bump time. *(Session-lease GC is out of scope — residual R2,
which rests on: sessions are on-demand and short (ADR-0011), and readers re-follow the symlink per read
rather than caching the resolved realpath at session start.)*

**REQ-5 — Tier-independent, integrity-only boot check; pinned channel; provisioned base case (design; P9).**
A check that lives **outside** any tier it verifies reads **only** the current symlink target and its frozen
`.skillset`, and asserts: (a) the symlink resolves — else `MISSING`; (b) `.skillset` equals the actual
`skills/*/` present — else `PARTIAL`. No external comparison (no race). On failure it exits non-zero and
writes to **stderr** a line carrying the fault token (`MISSING` / `PARTIAL`). It **fires on session/worker
start**; **provisioning asserts the boot-check wiring is installed and fails the provisioning step if not**.
The guarantee is **loud while the provisioned wiring persists** — a routine `claude` upgrade, a settings
edit, or a host reinstall can drop the SessionStart wiring, so DESIGN places the wiring where such rewrites
do not clobber it and the operator re-runs a cheap health check; the env-drift trigger is named, not promised
away (residual R3). *(Read-only + the frozen `.skillset` make silent content-drift structurally impossible,
so `CORRUPTED`/`DRIFTED` are retired. Proven scope, P9: flags absent/partial and runs when the tier is
removed.)*

**REQ-6 — Every consumer self-materializes under a unique root (F5=B).** The three consumer classes — an
interactive host's agent-config, the disposable fresh-clone worker, and a separate worker UID — each
materialize their own read-only copy under a **per-consumer-unique** root (so two consumers sharing a
host+UID do not collide) and each run the boot check. A worker copy's tamper-resistance is **not** a security
boundary (F4/F5).

**REQ-7 — Placement rules + the port policy.** A documented decision procedure routes a new lesson:
**generic → portable tier; agent-specific → agent tier; project-only → the consumer as a proper artifact**; a
project-only lesson later assessed as generic is **promoted upward** into the appropriate tier (its own
review).

**REQ-8 — Reversible, teardown-first cutover.** The cutover (1) tears down the legacy per-slug working-tree
symlinks, (2) stands up the symlink→pinned layout on every consumer and proves the full skill set resolves
(boot check green everywhere), then (3) removes the vendored copy + sha-pin manifest + drift-guard. Rollback
re-points to the retained fallback — during cutover the vendored copy, after cutover the previous
materialization (REQ-4c). Stated for the model; a specific consumer's internal state is asserted in that
consumer's own repo.

**REQ-9 — Consumption docs name one maintainer-own-host mode; other-people modes stay.** Over the enumerated
set — `INSTALL.md`, `adapters/claude/CLAUDE.md`, `adapters/cursor/*`, `adapters/copilot/*`,
`adapters/gemini/*`, `README.md` — no doc references the retired per-skill-symlink model, and exactly **one
maintainer-own-host** mode (tag-pinned plugin) is named via a pinned mode-heading marker. The copy /
submodule / sync-bot modes for other people remain in `INSTALL.md` (F3/slice 5), not counted against "one".

**REQ-10 — Non-goal fence (F4).** The base ships **no** marketplace or signing artifacts (checkable
negative). "Keeps a future marketplace possible" is explicitly non-verifiable and not gated.

**REQ-11 — House-conformant + deny-path-tested (currency-and-audit, grounded-verifiable-gates r10).** New
prose is anonymized (CI private-identifier gate). Any new validator/hook is byte-mirrored into
`templates/git-controls/`. The materialize/bump/boot scripts are POSIX sh, zero-dependency
(shellcheck-gated). Each deny path is mutation-verified: the test asserts the deny signal **and** goes red
when the fail-closed return is flipped. The CI/DoD gate collects the deny-path tests against an **enumerated
expected set** and fails closed if the set is empty or missing a member.

## Acceptance criteria

*(Executable; CLI-dependent ACs pin `claude` 2.1.214; every pattern/token is a literal DESIGN must fix.)*

- **AC-1 (REQ-2)** — one tier symlinked, `claude plugin details <tier>` lists every skill (plugin loaded); a
  bump to a SHA that adds a skill dir surfaces it after a fresh read with no new symlink, `.skillset` updated.
- **AC-1b (REQ-1)** — both tiers carry a `.claude-plugin/` manifest and are exported/addressable from the one
  resolved SHA under one tag (git assertion).
- **AC-2 (REQ-3, REQ-4a)** — a materialization contains no `.git`; after a naive write its content hash is
  unchanged (permission-denied string advisory); and the produce step **fails loud** when the export does not
  equal the resolved commit's tree (simulate a truncated export).
- **AC-3 (REQ-4)** — a bump to a new pin changes loaded content while a consumer on the old pin is unchanged.
- **AC-3b (REQ-4 diff review)** — a bump whose `hooks/`/scripts differ from the old pin surfaces the exact
  `git diff <old> <new> -- hooks scripts` before the pin is set (assert the diff is presented and the pin-set
  is gated on the operator step); a doc-only bump presents an empty exec-diff; the first bump diffs against
  the empty tree.
- **AC-3c (REQ-4 resolution/`--force`)** — a `--force` bump exits non-zero without re-pointing; a fetch
  driven to exit 0 while the resolved SHA diverges from the intended SHA fails loud; a tag moved *after* first
  resolution does **not** change what is exported (the export pins the first-resolved SHA — no second
  resolution).
- **AC-3d (REQ-4a atomicity)** — killing a bump between temp-export and publish leaves the prior pin
  resolving (`readlink` still valid, no `MISSING`); a retry is idempotent; the orphaned temp export path is
  gone after retry. The mechanism asserted is `mv -T` (an atomic rename), not a timing window.
- **AC-4 (REQ-5)** — the boot check exits non-zero with a stderr line matching `^METHODOLOGY .* (MISSING|PARTIAL)$`
  for an absent / incomplete target respectively.
- **AC-4b (REQ-5 wiring)** — a fresh session/worker start (the named start command) on a broken consumer
  appends the fault token to **one named log file** the SessionStart wiring writes, with no manual
  invocation; provisioning a consumer without the wiring **fails at provision time**.
- **AC-4c (REQ-5 snapshot)** — bump a SHA whose `skills/*/` = {X,Y,Z}; assert `.skillset` == {X,Y,Z} derived
  from the export's own dirs; assert no hand-maintained skillset list matches a pinned pattern anywhere
  outside an export.
- **AC-5 (REQ-6, REQ-4b)** — a CI-runnable proxy (interactive config + a local-clone worker + a
  distinct-`$HOME` standing in for the UID) runs `materialize + boot-check` green on each, asserts two
  consumers on one host+UID get distinct roots, and asserts a worker `materialize` installs exactly the
  operator-provided SHA (it resolves none itself). *(Named-host acceptance — a real separate UID on a named
  host — is AC-5h, with its own start command + pass condition, satisfying the owner's separate-UID evidence
  directive.)*
- **AC-6 (REQ-8)** — after cutover, over `~/.claude/skills`: `find -type l` shows only the tier plugin
  symlink(s), zero bare per-slug links, and for each target `git -C <realpath> rev-parse --is-inside-work-tree`
  fails (no target under a live working tree). *(The consumer-tree vendored-artifacts scan runs in that
  consumer's own PR.)*
- **AC-6b (REQ-8, REQ-4c)** — the cutover emits an ordered log with tokens `TEARDOWN`, `STANDUP`,
  `BOOTCHECK_GREEN`, `REMOVE_FALLBACK`; assert `TEARDOWN` ≺ `STANDUP`, and `BOOTCHECK_GREEN` (over the proxy
  consumer set) ≺ `REMOVE_FALLBACK`; a rollback re-points to the retained fallback and the boot check is green
  after.
- **AC-7 (REQ-7)** — the placement doc has named criteria sections (portable / agent / project +
  upward-promotion) and a frozen table of **≥3** labeled example lessons; assert each row's tier ∈
  {portable, agent, project} and its recorded rationale text references that tier's stated criterion (a
  stability check, not a functional classifier).
- **AC-8 (REQ-9, REQ-2b)** — over the enumerated doc set: a pinned reject-regex finds no retired-model
  reference; exactly one maintainer-own-host mode-heading marker string is present; a pinned regex finds zero
  namespaced (`<pack>:<slug>`) invocation handles in prose. A non-Claude path-read of `skills/<slug>/SKILL.md`
  resolves (a labeled proxy for manifest-inertness).
- **AC-9 (REQ-11, REQ-10)** — the enumerated deny-path set — `{t_missing, t_partial, t_sha_mismatch,
  t_force_refused, t_first_resolution_wins, t_export_fidelity_mismatch, t_reap_preserves_current_previous,
  t_review_fail_closed, t_wiring_absent_at_provision}` (9; = the collector's `EXPECTED`) — is all
  present in the collected tests; removing any member turns the gate red (a meta-test); each asserts its deny
  signal and goes red when its fail-closed return is flipped; a pinned scan finds zero marketplace/signing
  artifacts (`marketplace.json`, `*.sig`, `*.asc`, signing-manifest keys); shellcheck/POSIX, the anonymization
  gate, and the templates mirror pass in CI.

## Traceability

| REQ | Basis | Acceptance |
| --- | --- | --- |
| REQ-1 two tiers, one repo | F1 | AC-1b |
| REQ-2 both tiers plugins | F2; P5/P10 | AC-1 |
| REQ-2b path-not-handle | F2 residual | AC-8 |
| REQ-3 read-only SHA-pin, sole record | F4; P7 | AC-2 |
| REQ-4 operator bump / diff review | F4; P6/P8 | AC-3, AC-3b, AC-3c |
| REQ-4a atomic publish / fidelity / retry | round-1 M1/M2; round-4 | AC-2, AC-3d |
| REQ-4b headless installs operator pin | F5 (materialize ≠ resolve) | AC-5 |
| REQ-4c one rollback copy | round-2 df | AC-6b |
| REQ-5 integrity-only boot check | design; P9 | AC-4, AC-4b, AC-4c |
| REQ-6 per-consumer self-materialize | F5 | AC-5 |
| REQ-7 placement + port policy | must-cover item 1 | AC-7 |
| REQ-8 reversible, teardown-first cutover | BRIEF slice 4 | AC-6, AC-6b |
| REQ-9 one own-host mode; others stay | round-1 #8; F3 | AC-8 |
| REQ-10 non-goal fence | Non-goals, F4 | AC-9 |
| REQ-11 house + deny-path | currency-and-audit; grounded-gates r10 | AC-9 |

## Deferred residuals (documented, not dropped — each grows without rework)

- **R1 — concurrent-bump serialization** (per-consumer lock): a single operator does not bump concurrently,
  and per-consumer-unique roots (REQ-6) make single-writer structural; add a lock if bumps become
  multi-actor/automated.
- **R2 — session-lease / generation GC**: keep one rollback copy, reap older at bump time. Rests on sessions
  being on-demand/short (ADR-0011) and readers re-following the symlink per read. Revisit if long-lived or
  realpath-caching readers become common.
- **R3 — continuous boot-check-wiring verification**: asserted at provision time, loud-while-it-persists; a
  routine env change (upgrade / settings edit / reinstall) can drop it — mitigated by a durable wiring
  location (DESIGN) + a periodic operator health check.
- **R4 — distributed approval record + fleet conformance + end-to-end worker tamper-resistance**: the
  operator sets each pin after reviewing the diff; the untrusted-worker boundary is the consumer's structural
  isolation (separate UID / ro-mount), not this layer. Revisit if hosts multiply or bumps automate.
- **R5 — signature verification**: deferred (F4).

Namespacing splits invocation identity across modes; REQ-2b keeps prose path-addressed. `CORRUPTED` boot-time
integrity is unnecessary given produce-time fidelity (REQ-4a) + read-only + non-boundary tamper (F4/F5).
