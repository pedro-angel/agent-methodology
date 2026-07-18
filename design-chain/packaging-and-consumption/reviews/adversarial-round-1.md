# Adversarial review — round 1 (BRIEF + RESEARCH)

*Date: 2026-07-18. Method: `adversarial-lens-review` — five fresh reviewers, one binding lens
each, tasked to REFUTE the artifact; every BLOCKER/MAJOR finding independently verified against
the text before disposition. This note is the audit trail: what was found, and how the v2 of
BRIEF/RESEARCH answers it. Findings are the reviewers' words in brief; dispositions are the author's.*

## Verdict

The review was productive: it exposed one **core design defect** (the tag pin does not actually
deliver immutability) and a cluster of **evidence overclaims** in RESEARCH. Both are now fixed in v2
by hardening the design and downgrading the evidence to what was actually observed — not by defending
the draft. No finding was rejected as wrong; the low-severity ones are folded or explicitly deferred.

## BLOCKER / MAJOR findings and dispositions

| # | Lens | Finding (brief) | Verdict | Disposition in v2 |
| --- | --- | --- | --- | --- |
| 1 | currency | Symlink → live working-tree checkout + movable tag ref ≠ immutable; a stray checkout or a re-pointed/`--force`-fetched tag silently changes what every session loads — the same auto-update hole, relocated. | CONFIRMED | **Core fix.** The consumption target is now an **immutable, SHA-asserted materialization of a signed tag** (read-only export / read-only worktree), never a writable working tree. The **pin is the resolved SHA**; the tag is signed + upstream-protected; checkout and boot **verify signature + assert SHA**. BRIEF Goal 2 + Model rewritten. |
| 2 | currency | De-vendoring deletes the executable-content audit gate F4/Risks then invoke — a bump is `git checkout`, no PR/diff/merge, so "human merge" doesn't exist. | CONFIRMED | Added a **machine bump-gate**: a bump that changes `hooks/`/scripts vs the pinned SHA **fails closed** pending a recorded disposition. Named per consumer class (BRIEF §Bump gate). |
| 3 | currency | Boot check is self-referential: a hook inside the checked tier can't fire when the tier is dangling. | PARTIAL (logic sound) | Boot check is now **tier-independent** (outside any checked plugin), asserts (a) expected set resolves + (b) HEAD == pinned SHA, emits to a named visible channel, runs on **every host + worker + UID**. |
| 4 | completeness | Consumer inventory drops the fresh-clone self-improve worker + separate worker UID; "stable paths" scoping actively excludes them. | CONFIRMED | Added an explicit **consumer inventory** (interactive config / disposable fresh-clone worker / separate UID) and a new open fork **F5** for the worker+UID distribution mechanism. "Stable paths" scoping removed. |
| 5 | currency | `git fetch --tags` rejects a re-pointed tag but exits 0 (silent divergence); `--force` silently replaces reviewed content. | PARTIAL (observed) | Bump forbids `--force`, fetches to a temp ref, compares fetched SHA to the pinned SHA, **fails loud** on mismatch/rejected-tag rather than trusting exit 0. |
| 6 | probe | RESEARCH: no trust property was probed; "every load-bearing assumption is observation-backed" false for security. | CONFIRMED | Net downgraded; trust properties explicitly moved to the **Probes still required** backlog. |
| 7 | currency | No tag signing / protected-tag / signature verification; a mutable unsigned tag is writable by the threat it must gate. | CONFIRMED | Folded into fix #1: signed annotated tags, upstream protected/immutable-tag rule, signature+SHA verification on checkout and boot. |
| 8 | portability | F2 obsoletes a **second** consumption doc (the Claude adapter's Install section); slices name only INSTALL.md; no validator guards the adapter. | CONFIRMED | Added the Claude adapter to the doc-reconciliation slice; noted CI does not cover it (manual). |
| 9 | portability | Namespacing is plugin-mode-specific, not agent-agnostic; BRIEF overclaims "renames every slug" and under-weights split invocation identity. | PARTIAL | Namespacing reframed as an **agent-tier-plugin-path artifact only**; bare + namespaced handles coexist across modes; SPECS decides prose handling. |
| 10 | migration | No order-of-operations; migration scheduled before its runbook; pre-existing per-slug working-tree symlinks never torn down → double-install with the live surface still active. | PARTIAL | Slices reordered (runbook first); **teardown-first** of the pre-existing per-slug symlinks; post-migration assertion `find … -type l` shows only the plugin symlink(s). |
| 11 | migration | Plugin symlink "ends under-install" only within a tier; re-creates it at host/UID granularity (per-host, uncommitted, absolute, no CI/guard/boot-check). | PARTIAL | Claim downgraded to "ends per-skill under-install **within a wired host**"; per-host/UID provisioning is a named residual; boot check runs on every host/worker. |
| 12 | migration | Slice 4 is a destructive, non-additive, non-reversible cutover — violates the pack's own additive-default-off + reversible-by-default skills. | PARTIAL | Split into **4a** (stand up + verify full set resolves + boot-check green everywhere, vendored copy stays as default-on fallback) and **4b** (remove only after 4a passes); explicit rollback. |
| 13 | probe / completeness | The marquee fix — one per-tier symlink resolves **every** skill, a new skill needs no new link — was never probed (P3 was single-skill). | CONFIRMED | Downgraded to a **hypothesis**; added as required probe P5. Success criterion scoped accordingly. |
| 14 | probe | A tag→tag bump was never exercised (repo has one tag); "tag-bump observed / probe-proven" describes a working-tree swap. | CONFIRMED | Reworded to "working-tree target-swap observed; tag semantics assumed identical — untested"; added as required probe P6. |
| 15 | probe | The real pack was never packaged as a plugin; all plugin claims extrapolate from a toy. | PARTIAL | Marked feasibility-only; real-pack packaging is a slice-3 acceptance probe (P10). |
| 16 | probe | No probe evidence artifact captured — violates the environment-research skill RESEARCH claims to apply. | PARTIAL | RESEARCH now states the P2/P3/P4 raw captures (version/commands/exit codes) were **not** recorded in this chain; re-run + capture as `experiments/` artifacts before slice 3. |
| 17 | completeness | F2 (portable tier as plugin?) is silently decided in Goals/Success/Risks while flagged open. | CONFIRMED | Goal 3 / Success 1 / namespacing Risk made **conditional on F2**; agent-tier-as-plugin moved into Decided so only the portable-tier question stays open. |
| 18 | completeness | Marketplace exclusion is doc-checked only but presented as an observed "Result" row. | PARTIAL | Marked **doc-only, not observed** in both the table and the Net sentence; optional confirming probe P11. |
| 19 | completeness | No Status/decided-ledger line (the sibling entry has one); Decided section omits the agent-tier-as-plugin decision. | PARTIAL | Added a **Status** line to BRIEF + RESEARCH; added the Decided bullet. |

## MINOR / NIT (folded or deferred)

Reviewed-tag TOCTOU (subsumed by the SHA pin, #1) · `templates/git-controls` mirror obligation for any
new validator (flagged for SPECS) · repo-wide markdownlint + private-identifier scanner apply to any
markdown/JSON the plugin scaffolding ships (constrain the manifest; flagged for SPECS) · de-vendoring
inventory must enumerate **every** auto-load location, not just repo-root `skills/` · P4 "no caveat/full
package" softened to "one SessionStart hook observed" · "no stale cache" softened to "no stale content
across one bump" · boot-check scope disambiguated to the **expected set**, derived from the manifest ·
port policy gains the **upward-promotion** path (project-only → generic → promoted) · probe numbering
note added · other-agent-unaffected criterion labeled reasoned-not-observed.

## Net effect

v2 is a **harder, more honest** artifact: the trust model now rests on an immutable SHA-pinned signed
materialization with a fail-closed bump gate and a tier-independent boot check; the evidence claims match
what was observed; the missing probes are an explicit backlog, not silent gaps. The design is stronger for
having been refuted.
