# DESIGN — how the tiered SHA-pinned read-only plugin model is built (v2)

*Consumes: [SPECS.md](SPECS.md) (v5). Feeds: [TASKS.md](TASKS.md). Date: 2026-07-18. v2 applies plan review
round 1 ([reviews/plan-adversarial-round-1.md](reviews/plan-adversarial-round-1.md)): boot-check format
fixed, all guard literals pinned, produce-time fidelity is a hash compare, `bump.sh` fetches, the empty agent
tier's runtime consumption is deferred (scaffold only), and the mutation harness + negative scan are
specified. The HOW; guarantees are SPECS's. Anonymized; consumer-specific cutover lives in the consumer repo.*

## Mechanism overview

The **portable tier** is a `.claude-plugin/plugin.json` at the repo root over the existing `skills/`
(REQ-1/2), consumed via one symlink `~/.claude/skills/agent-methodology` → a read-only export. The **agent
tier** `claude-tier/` is scaffolded (manifest + README + empty `skills/`) so the F1/F2 decision is
git-addressable, but its **runtime consumption is deferred** until a Claude-only skill exists — wiring an
empty plugin through materialize/symlink/boot-check on every consumer is machinery for zero skills (plan
round-1 M5); adding it later is one already-designed symlink. A consumer **materializes** a pinned commit
into a per-consumer read-only export (`git archive`, no `.git`); a **bump** re-points the symlink after the
operator reviews the hooks/scripts diff; a tier-independent **boot check**, installed into the consumer's
config at provision time, asserts the tier resolves and is complete on every session start.

## Pinned literals (SPECS: "every pattern/token is a literal DESIGN must fix")

- Boot-check line: `printf 'METHODOLOGY %s %s\n' "$msg" "$TOKEN"` on **stderr**, `$TOKEN ∈ {MISSING, PARTIAL}`,
  matching AC-4 `^METHODOLOGY .* (MISSING|PARTIAL)$` (token **last**).
- INSTALL.md own-host mode marker heading (exact): `## Tag-pinned plugin (maintainer's own hosts)`.
- AC-8 retired-model reject regex: `(ln -s.*~/.claude/skills/[^ ]*/|for d in .*skills.*ln -sfn)` (the per-slug
  symlink loop) — zero matches over the doc set.
- AC-8 namespaced-handle regex: `` `agent-methodology(-claude)?:[a-z-]+` `` — zero matches in prose.
- AC-9 marketplace/signing artifact globs: `marketplace.json`, `**/*.sig`, `**/*.asc`, and the key
  `"marketplace"` in any `.claude-plugin/*.json` — zero matches.
- AC-4c hand-maintained-skillset reject pattern: a `.skillset`-shaped list committed **outside** an export
  dir, i.e. any tracked file named `*.skillset` (the only legitimate one is produced read-only, untracked).
- AC-6 working-tree predicate: `git -C "$(readlink -f <target>)" rev-parse --is-inside-work-tree` **fails**.

## Plugin manifests (REQ-1, REQ-2; AC-1, AC-1b)

Portable `/.claude-plugin/plugin.json`: `{"name":"agent-methodology","version":"0.0.0","description":"…"}`
over the repo-root `skills/`. Agent `claude-tier/.claude-plugin/plugin.json`: `name:"agent-methodology-claude"`
(scaffold). **Packaging-verify (extends P10):** the portable check re-runs `claude plugin details` against a
**full-repo export root** (extra files beside `.claude-plugin/`+`skills/`) and confirms every skill still
lists; if the mixed root is rejected, fall back to `git archive <sha> skills .claude-plugin`.

## `materialize.sh <sha> <dest-root>` (REQ-3, REQ-4a; AC-2)

1. `tmp=$(mktemp -d "<dest-root>.tmp.XXXX")`.
2. `git -C <checkout> archive <sha> | tar -x -C "$tmp"`, **both pipe exit codes checked**; non-zero →
   `rm -rf "$tmp"`, fail loud.
3. **Fidelity (AC-2, required — not the path-set floor):** compare a content hash of the export to the
   commit's tree — `git -C <checkout> archive <sha> | git hash-object --stdin` vs a hash recomputed from
   `$tmp` (or per-file `sha` of `git ls-tree -r <sha>` vs `$tmp`); mismatch → fail loud. Catches a truncated
   file, not only a dropped one.
4. Derive `"$tmp/.skillset"` = `basename` of each `"$tmp"/skills/*/` (sorted; never hand-authored — AC-4c).
5. `chmod -R a-w "$tmp"`; the materialization dir is `<dest-root>.<sha>`.
6. Publish atomically (AC-3d): `ln -s "$tmp" "<dest-root>.newlink" && mv -T "<dest-root>.newlink" "$symlink"`
   — an atomic rename, no missing-target window. *(No `.pinned-sha` is written — it was unread, plan M-minor.)*

Interrupt safety: steps 1–5 are in `$tmp`; an interrupt leaves the prior symlink intact; a retry makes a new
`$tmp` (idempotent); orphaned `.tmp.*` are reaped at the next bump.

## `bump.sh --ref <ref> --intended-sha <sha>` (REQ-4, REQ-4c; AC-3, AC-3b, AC-3c)

1. Reject `--force` in argv (AC-3c). `git -C <checkout> fetch --tags <remote>` **may exit 0 on a
   clobbered/rejected tag** — its exit code is **not trusted**; resolve `got=$(git -C <checkout> rev-parse
   "<ref>^{commit}")` and **fail loud if `got != <intended-sha>`** (AC-3c; this single SHA-vs-intent compare
   covers both a moved tag and a lying fetch — plan M7).
2. Exec-content review (AC-3b): `git -C <checkout> diff "<old-sha>" "$got" -- hooks scripts claude-tier`
   (first bump: `old = $(git hash-object -t tree /dev/null)`, the empty tree). Present it; **block until the
   operator confirms** before step 3. A doc-only diff is empty; the confirm is still required and recorded.
   No machine token/record (lean; residual R4).
3. `materialize.sh "$got" <dest-root>` — the SAME `$got`, no re-resolution (AC-3c TOCTOU).
4. Reap: keep `<dest-root>.<current>` and `<dest-root>.<previous>`; `rm -rf` only strictly-older
   `<dest-root>.*` and stale `.tmp.*` — **never the current or previous target** (AC-6b; guarded test M14).

Rollback = `mv -T` the symlink to the retained previous dir.

## `bootcheck.sh <skills-root> <tier> <_>` (REQ-5; AC-4)

Reads only the symlink target. `[ -e "$dir" ] || fail MISSING "…"`; then compare `sort "$dir/.skillset"`
to `ls -1d "$dir"/skills/*/ | xargs -n1 basename | sort` → differ → `fail PARTIAL "…"`. `fail(){ printf
'METHODOLOGY %s %s\n' "$2" "$1" >&2; exit 1; }` (token last). No external comparison; no `CORRUPTED` (R3).
Supersedes the P9 prototype `scratchpad/probes/bootcheck.sh` (which used the token-first / `.pinned-sha` /
`DRIFTED` shape — now retired).

## `install-consumer.sh` — provisioning + tier-independent wiring (REQ-5, REQ-6; AC-4b, AC-5)

Per consumer: materialize the operator-provided pin under `${CONSUMER_ROOT:?}` (per-consumer-unique — REQ-6);
create the **portable** tier symlink; install `bootcheck.sh` **outside any tier** and register a
`SessionStart` hook (consumer `settings.json`) that runs it and appends the token to
`${CONSUMER_ROOT}/.methodology-bootcheck.log` (AC-4b observation point). **Assert the wiring is present or
fail the provisioning run** (base case). The **worker** variant takes the pin as an input and **must not**
resolve a ref: it is fed the operator's SHA, and given a non-SHA ref it errors (AC-5 negative).

**Probe P13 (Slice C precondition):** confirm a headless `claude -p` under a provisioned config fires the
user-level `SessionStart` hook and writes the named log; if it does not, AC-4b is honestly downgraded to
"wiring installed + the named start command writes the log" and the trigger is documented.

## Deny-path tests + mutation harness + CI gate (REQ-11; AC-9)

`tools/consume/tests/` — filenames **equal** the enumerated tokens so the collector maps them unambiguously:
`t_missing`, `t_partial`, `t_sha_mismatch`, `t_force_refused`, `t_first_resolution_wins`,
`t_export_fidelity_mismatch`, `t_reap_preserves_current_previous`, `t_wiring_absent_at_provision`. **Mutation
harness (r10):** each test runs its guard **normal** (assert the deny signal) and against a **return-inverted
copy** of the guard (assert the suite reddens) — both in one test.
`scripts/checks/check-consume-deny-paths.sh` collects them against that exact set, **fails closed** if the
set is empty or missing a member, and includes a meta-test that removing a member reddens the gate. It +
a `shellcheck` hook go into `.pre-commit-config.yaml`, and **both the collector AND the modified
`.pre-commit-config.yaml` are byte-mirrored into `templates/git-controls/`** (M11).

## Doc changes (REQ-9; AC-8) + placement (REQ-7; AC-7)

`INSTALL.md`: add the pinned own-host marker heading (above), keep other-people modes. `adapters/claude/CLAUDE.md`:
replace per-slug Install steps with a pointer to the new mode (no validator covers it — manual). `docs/placement.md`:
criteria + a frozen table of **one row per tier {portable, agent, project} + one promotion row** (justified
count; AC-7 asserts each tier value appears and each rationale references its criterion).

## What does NOT change / DoD scope

The 22 portable skills; `AGENTS.md`; existing checks. No marketplace/signing (REQ-10). **This repo's gate
covers AC-1..AC-4c, AC-5, AC-7, AC-8, AC-9.** AC-5h (named-host real UID), AC-6, AC-6b run in the consumer /
acceptance environment and are tracked out-of-repo — DoD-GO here means "A–E merged, CI green"; full GO is the
acceptance gate.
