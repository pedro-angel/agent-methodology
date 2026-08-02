# TASKS — build the tiered SHA-pinned read-only plugin model (v2)

> **For agentic workers:** execute slices in order; each is a reviewable propose-only PR. Mechanisms + pinned
> literals come verbatim from [DESIGN.md](DESIGN.md) v2; guarantees from [SPECS.md](SPECS.md) v5; the
> plan-review dispositions from [reviews/plan-adversarial-round-1.md](reviews/plan-adversarial-round-1.md).
> Working dir: the `agent-methodology` checkout. Every PR: anonymized, shellcheck/markdownlint green,
> DCO-signed, provenance trailer. Every scratch check runs under an isolated `HOME`/skills-root with a `trap`
> cleanup — **never touch the operator's live `~/.claude`**.

**Goal:** package the pack as the portable-tier plugin (+ an agent-tier scaffold) and ship the read-only
pinned consumption tooling, gate-tested. **Lean scope:** residuals R1–R5 are NOT built; the agent tier's
runtime consumption is deferred until a Claude-only skill exists.

## Global constraints

- POSIX sh, shellcheck-clean, no consumer identifiers in this repo. The runtime hot path
  (`materialize.sh`/`bump.sh`/`bootcheck.sh`) is zero-dep (SPECS REQ-11). `install-consumer.sh` is a one-shot
  provisioner and may use `jq` **or** `python3` for the `settings.json` merge (a robust JSON merge needs a JSON
  tool; hand-rolling one in sh is the fragile machinery to avoid) — it fails loud if neither is present.
- Deny-test filenames **equal** their tokens (DESIGN); the collector fails closed on a missing member.
- This repo's gate covers **AC-1..AC-4c, AC-5, AC-7, AC-8, AC-9**. AC-5h/AC-6/AC-6b are out-of-repo
  acceptance items (Slice F is a runbook here; the cutover PR lands in the consumer repo).

---

### Slice A — Package the portable tier + scaffold the agent tier (REQ-1, REQ-2; AC-1, AC-1b)

- [x] A1. Root `/.claude-plugin/plugin.json` (`name: agent-methodology`) over `skills/`.
- [x] A2. `claude-tier/` scaffold: `.claude-plugin/plugin.json` (`name: agent-methodology-claude`),
      `README.md` ("Claude-only methodology lands here; consumption wired when the first such skill exists"),
      `skills/.gitkeep`. **No runtime consumption of this tier yet** (plan M5).
- [x] A3. AC-1 under an **isolated** skills-root (`trap` cleanup): export the repo, symlink the portable
      tier, assert `claude plugin details` lists **every** skill — count **derived**, not the literal 22:

```bash
tmp=$(mktemp -d); H=$(mktemp -d); trap 'rm -rf "$tmp" "$H"' EXIT
git archive HEAD | tar -x -C "$tmp"; n=$(ls -1d skills/*/ | wc -l | tr -d ' ')
mkdir -p "$H/.claude/skills"; ln -sfn "$tmp" "$H/.claude/skills/zzA"
CLAUDE_CONFIG_DIR="$H/.claude" claude plugin details zzA | grep -qE "Skills \($n\)" || echo FAIL-count
```

Expected: no `FAIL-*`. *(If `CLAUDE_CONFIG_DIR` isolation is unavailable, use a uniquely-named `zzA-<rand>`
link in the real root and remove it in the trap; still derive `$n`.)* If the mixed export root is rejected,
apply DESIGN's `git archive <sha> skills .claude-plugin` fallback.

- [x] A4. AC-1b: both manifests **parse** and carry their `name` from one `HEAD`:
      `git cat-file -p HEAD:.claude-plugin/plugin.json | grep -q '"agent-methodology"'` and the `claude-tier`
      one carries `agent-methodology-claude`.
- [x] A5. PR **Slice A** (additive, default-off).

### Slice B-materialize — `materialize.sh` + its tests (REQ-3, REQ-4a; AC-2, AC-4c)

- [x] Bm1. `tools/consume/materialize.sh` per DESIGN (pipefail archive, **hash** fidelity compare, `.skillset`
      derive, `chmod -R a-w`, atomic `mv -T`; no `.pinned-sha`).
- [x] Bm2. Tests (each mutation-verified — normal asserts deny, return-inverted variant reddens):
      `t_readonly_export` (AC-2: no `.git`; write → non-zero + content hash intact),
      `t_export_fidelity_mismatch` (AC-2: a truncated file fails the produce step),
      `t_skillset_derived` (AC-4c: `.skillset == basename skills/*/`; and a repo-wide scan finds **no** tracked
      `*.skillset`).
- [x] Bm3. Land `scripts/checks/check-consume-deny-paths.sh` **skeleton** now (collects present tests, notes
      "set completes in Slice D") so tests are gate-collected from their first PR. `shellcheck` clean. PR.

### Slice B-bump — `bump.sh` + its tests (REQ-4, REQ-4c; AC-3, AC-3b, AC-3c)

- [x] Bb1. `tools/consume/bump.sh` per DESIGN (fetch untrusted, resolve-once vs `--intended-sha`, `--force`
      refuse, exec-diff review + operator confirm, materialize same SHA, non-greedy reap keeping
      current+previous).
- [x] Bb2. Tests: `t_sha_mismatch` (AC-3c: resolved ≠ intended — incl. a fetch-exits-0-but-diverges input —
      fails loud), `t_force_refused` (AC-3c), `t_first_resolution_wins` (AC-3c: a tag moved after resolution
      does not change the export), `t_bump_content` (AC-3: new pin's content differs and loads; old pin dir
      unchanged), `t_diff_review` (AC-3b: hooks/scripts change → diff presented + pin-set gated on confirm;
      doc-only → empty diff; first bump → diff vs empty tree), `t_atomic_interrupt` (AC-3d: kill between
      export and publish → prior pin resolves via `readlink`; retry idempotent; temp gone),
      `t_reap_preserves_current_previous` (M14: a reap never deletes current/previous), `t_add_skill_bump`
      (AC-1 2nd clause: bump to a SHA adding a skill → `.skillset` re-derived, no new symlink). PR.

### Slice B-bootcheck — `bootcheck.sh` + its tests (REQ-5; AC-4)

- [x] Bc1. `tools/consume/bootcheck.sh` per DESIGN (token **last**, stderr, MISSING/PARTIAL).
- [x] Bc2. Tests `t_missing`, `t_partial` — assert the stderr line matches `^METHODOLOGY .* (MISSING|PARTIAL)$`
      and exit non-zero; mutation-verified. PR.

### Slice C — Provisioning + tier-independent wiring (REQ-5, REQ-6; AC-4b, AC-5)

- [x] C0. **Probe P13** (precondition): does a headless `claude -p` under a provisioned config fire the
      user-level `SessionStart` hook + write the named log? Capture the result; if no, downgrade AC-4b to
      "wiring installed + named start command writes the log" and document the trigger.
- [x] C1. `tools/consume/install-consumer.sh` per DESIGN (per-consumer-unique root, portable symlink,
      `bootcheck.sh` + `SessionStart` hook **outside any tier**, named log, assert-wiring-or-fail).
- [x] C2. Tests: `t_wiring_absent_at_provision`; AC-5 proxy — install for `interactive` + a `local-clone
      worker` + a `distinct-$HOME` UID stand-in, assert each boot-checks green and two consumers on one
      host+UID get **distinct** roots; **AC-5 negative** — the worker variant fed a *ref* (not a SHA)
      **errors**, and a static grep of the worker path finds no `rev-parse`/`fetch` (it resolves none). AC-4b
      per P13: fresh start on a broken consumer writes the token to the named log with no manual `bootcheck`.
- [x] C3. Register C's tests in the collector. **AC-5h** (real separate-UID on a named host) recorded as a
      named out-of-repo acceptance step (start command + pass condition — owner's evidence directive). PR.

### Slice D — Complete the CI/DoD deny-path gate (REQ-11; AC-9)

- [x] D1. `check-consume-deny-paths.sh` enumerates the 9-member set (source of truth = its `EXPECTED`);
      fail-closed on empty/missing; `t_collector_fails_closed` asserts removing a member reddens. SPECS AC-9 +
      DESIGN reconciled to the same 9 filenames (added `t_review_fail_closed`, the fail-closed exec-review
      guard from Slice B-bump). *(Surfaced by Slice C spec-compliance review, finding #5.)*
- [x] D2. Added a scoped `shellcheck` (shellcheck-py, pinned) hook + the `check-consume-deny-paths` collector
      hook to `.pre-commit-config.yaml`; **mirrored only the `.pre-commit-config.yaml` change** (byte-identical)
      into `templates/git-controls/`. The collector/runner/scan scripts are NOT mirrored, and every consume hook
      is scoped to `^tools/consume/` so it stays DORMANT for adopters (no `tools/consume/` there → never fires).
      *(Corrects the earlier "byte-mirror both the collector AND the config" — mirroring the consumption
      toolchain into the generic starter would be wrong; DESIGN already said "only the config change is mirrored.")*
- [x] D3. `run-consume-tests.sh` runs the POSITIVE (non-deny) suite — every `t_*` except the collector's
      `EXPECTED` members (which the collector runs) — wired as a scoped hook, so the AC-5 proxy, negatives,
      hygiene, dedup, and collector/scan meta-tests are gate-executed. *(Slice C spec-compliance review, finding #6.)*
- [x] D4. `check-no-marketplace-artifacts.sh` (AC-9 non-goal fence): zero `marketplace.json`/`*.sig`/`*.asc`
      and no signing-manifest keys; wired as a scoped hook; `t_no_marketplace_scan` covers its deny path.
      `pre-commit run --all-files` green (validated on aarch64 Linux). PR.

### Slice E — Docs + placement (REQ-2b, REQ-7, REQ-9; AC-7, AC-8)

- [x] E1. `INSTALL.md`: add the pinned own-host marker heading; keep other-people modes.
- [x] E2. `adapters/claude/CLAUDE.md`: replace per-slug Install steps with a pointer to the new mode.
- [x] E3. `docs/placement.md`: criteria sections + the frozen table (one row per tier + a promotion row).
- [x] E4. AC-8 (pinned regexes, DESIGN): zero retired-model matches; exactly one own-host marker; zero
      namespaced handles in prose; a non-Claude path-read of `skills/<slug>/SKILL.md` resolves. AC-7: each row's
      tier ∈ {portable, agent, project} and its rationale references that tier's criterion. PR.

### Slice F — Cutover **runbook** (REQ-8; AC-6/AC-6b tracked out-of-repo)

- [x] F1. Write the reusable runbook: the ordered-log contract (`TEARDOWN` ≺ `STANDUP` ≺ `BOOTCHECK_GREEN` ≺
      `REMOVE_FALLBACK`), teardown-first of legacy per-slug symlinks, stand-up + boot-check-green **before**
      any removal, and the rollback drill. **The actual de-vendoring is a referenced downstream PR in the
      consumer's repo** over a **named finite** consumer set (BRIEF non-goal here). AC-6/AC-6b are asserted in
      that PR, not this repo's CI.

## Definition of Done

- **This repo (CI):** AC-1..AC-4c, AC-5, AC-7, AC-8, AC-9 green; the deny-path gate collects the full set;
  `definition-of-done` reports GO for scope "A–E merged, CI green".
- **Acceptance (out-of-repo):** AC-5h (named-host UID), AC-6, AC-6b in the consumer/host environment.
- Residuals R1–R5 remain documented, not built.

## Decision log

- P-1 (plan round 1): defer the empty agent tier's runtime consumption (M5); Slice F is a runbook, the
  consumer de-vendoring is downstream (M9); DoD scope split repo-CI vs acceptance (M10).
- R-1 (2026-08-02, reconciliation): checkboxes A/B/C/E flipped to done — their slices merged as PRs
  #21–#27 on 2026-07-18/19 but the boxes were never ticked (doc drift, caught in review). F1 ticked by
  the PR landing `docs/cutover-runbook.md`. First real cutover execution (a maintainer host on the
  retired per-slug mode) recorded in `experiments/cutover-run-2026-08-02.md`.
- R-2 (2026-08-02): SPECS v6 addendum — consumer-side skill exclusion (REQ-12/AC-10), motivated by
  four-skill overlap with a consumer's other installed plugin; deny set grown 9 → 10.
