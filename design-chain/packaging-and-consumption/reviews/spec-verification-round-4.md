# Spec verification — round 4 (SPECS.md v4, lean) — single design-flaw pass

*Date: 2026-07-18. One design-flaw/race verification of the lean v4, to confirm the simplification dropped
no safety property and hid no new race. Outcome: both round-3 BLOCKERs confirmed **closed by removal**;
R1 confirmed **honestly scoped and structurally sound** (per-consumer-unique roots make the single-writer
property structural, not mere discipline). Four MAJORs remained — all resolved by honesty/subtraction plus
one small produce-time add. v5 applies them; no new mechanism is introduced, so no further adversarial round
is required before the spec advances.*

## Findings → v5 disposition

| Finding | v5 |
| --- | --- |
| **MAJOR — REQ-4b over-claims self-improve-safety.** The materialize step not resolving a SHA does not, by itself, stop an untrusted off-host worker: the channel carrying the operator's pin is unspecified, and REQ-6 concedes tamper isn't a boundary here, so post-materialize the worker could re-point its own symlink. | **Downgraded.** REQ-4b now claims only "installs the operator-provided pin; does not itself resolve a SHA." End-to-end self-improve-safety rests on the **consumer's** structural boundary (separate UID / read-only mount — ADR-0007/0008-class) + propose-only review, explicitly **out of scope** for this packaging spec. |
| **MAJOR — "unprovisioned-pin-refused" is vacuous** (the `CORRUPTED`-tautology antipattern reintroduced): `materialize` takes the SHA as input; refusing "a SHA provisioning didn't set" needs a second record that contradicts REQ-3. | **Deleted** from REQ-4b/AC-5/AC-9. `materialize` installs the SHA it is given; the trust boundary is the consumer's provisioning (above), not a check in this spec. |
| **MAJOR — export fidelity lost with `CORRUPTED`.** A materialization that *never* equalled the pinned commit (truncated / disk-full `git archive`) is structurally complete, so `PARTIAL`/`MISSING` pass — a silent content failure. | **Added at produce time** (REQ-4a / AC-2): the export is verified to equal the resolved commit's tree (archive exit-checked + tree/content-hash compared) **before** read-only+publish; a mismatch fails loud. Boot-time `CORRUPTED` stays removed — fidelity is guaranteed at creation, drift is prevented by read-only. |
| **MAJOR — provision-time-only wiring check masks *normal-use* silent failure.** A `claude` upgrade, a settings edit, or a host reinstall silently drops the SessionStart hook → a later `MISSING` tier goes unreported, reopening the exact silent-under-install the BRIEF exists to kill. R3 framed this as tamper; the real trigger is env drift. | **Scoped honestly** (REQ-5 / R3): the guarantee is "loud **while the provisioned wiring persists**"; DESIGN must place the wiring where routine `claude`/settings rewrites don't clobber it, and the operator re-runs a cheap health check. The env-drift trigger is named, not framed as adversarial. |
| MINOR — reap-vs-lazy-reader needs a second assumption (readers re-follow the symlink per read, or sessions don't outlive two bumps). | R2 states both assumptions. |
| MINOR — reader/reap invariant unstated. | REQ-4a states: reap never deletes the current or immediately-previous target while a boot check or skill read may hold it. |
| MINOR — fresh-consumer exec content is covered by the operator's *cumulative* bump reviews, not a per-consumer diff. | REQ-4 states it, closing round-3 BLOCKER-2 honestly without reintroducing a record. |

## Net

v5 makes the spec's claims match what the mechanism delivers: it stops promising end-to-end
self-improve-safety this layer can't give (correctly handing that to the consumer's structural boundary),
deletes the one vacuous check, guarantees export fidelity at creation, and scopes the boot-check-liveness
promise to reality. The spec is lean, honest, and its deny paths are all constructible. Ready to advance to
DESIGN — pending the owner's lean-vs-full call and go-ahead.
