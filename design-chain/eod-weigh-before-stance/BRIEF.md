# BRIEF — Reflexive-agreement / anchoring gap in `evidence-over-deference`

*Type: BRIEF (problem + goal; feeds RESEARCH → SPECS → DESIGN → TASKS per
`spec-driven-development`). Target repo: **agent-methodology** (not kubara).
Date: 2026-07-12. Status: **accepted by the maintainer 2026-07-12, with the
amendment below** (original: draft). This brief deliberately does **not**
pre-decide the fix.*

## Maintainer amendment (2026-07-12)

Accepted with one reshaping, which supersedes the Goal as originally drafted:
the original goal targeted only the *agreement* reflex. The maintainer's
requirement is **stance-neutral**: the failure is taking *any* stance —
adopting **or** rejecting a proposed direction — before independently
generating and weighing the alternatives. Two consequences the chain must
carry:

1. **Both polarities are in scope.** An agent corrected for sycophancy often
   overshoots into performative contrarianism — manufactured pushback to seem
   independent, which is sycophancy toward the instruction rather than honest
   judgment. A fix that can be satisfied by flipping polarity is not a fix.
2. **The weighing has a generative step.** "There is always more than one way
   to do things": the agent must *produce* the option space itself (at least
   the strongest real alternative), not merely score the user's option against
   whatever runner-up the user happened to mention. When one option genuinely
   dominates, the honest output is a one-sentence statement of the
   alternatives considered and why they lose — not a manufactured rival.

The amendment also names a new failure mode the fix itself could create (see
Constraints): *ritual alternative-listing* — a strawman alternative waved at
and dismissed so the agreement can proceed — which is sycophancy with more
tokens.

## Problem

`evidence-over-deference` is the methodology's anti-sycophancy skill and it is
good, but its **triggers are scoped narrowly**, leaving one common failure mode
outside them. As written, the skill fires on two situations:

- **(a)** the user asserts a **checkable premise** → verify before complying
  (frontmatter; "When to use", SKILL.md:10-12);
- **(b)** the user **challenges a claim of yours** → concede only on evidence,
  "without performative agreement" (rule 4, SKILL.md:28).

Neither covers a third, very frequent situation:

- **(c)** the user **proposes a direction, framing, or option**, and the agent
  reflexively agrees / adopts the framing *without independently weighing the
  alternatives first* — with no contrary evidence in hand and no recorded
  principle in conflict.

Case (c) has no "premise to check" and no "challenge to concede to," so it slips
past the skill's stated triggers. Yet it is where most day-to-day sycophancy
actually lives: the agent mirrors the user's lean, opens with "you're right,"
and ranks the user's idea above its own before it has done the independent
reasoning that would tell it whether that ranking is earned. The skill even
*aspires* to close this — "an agent whose agreement means something"
(SKILL.md:33) — but its rules only guarantee it in cases (a) and (b).

## Grounding (honest scope: n=1 motivating incident, not a measured rate)

Observed in a single real session (revive-vs-rebuild triage of a Terraform
repo). Two *distinct* failures occurred, which is what isolates the gap:

1. A clean **evidence-over-deference violation, already covered**: the agent
   repeated a stale doc claim ("repo not pushed") as fact instead of checking
   `git remote` — a checkable premise (case a). The existing skill would have
   caught this had it been applied.
2. A **case-(c) failure the skill does not name**: when the user reframed the
   first step from "validate the code" to "adopt the methodology first," the
   agent replied "you're right, and it's a better frame than mine" and only then
   offered a token counter-point. It agreed *before* independently weighing
   whether validate-first still held. No premise was checkable; no principle
   conflicted; the user had not challenged a claim — so no current trigger
   fired. This repeated across several turns ("fair," "good pushback") as an
   opening reflex.

The separability of #1 and #2 in one transcript is the evidence that (c) is a
real gap and not just a re-description of (a)/(b). (The skill's own origin note,
SKILL.md:37 — "challenge the user" was once absent and "that gap became this
skill" — is precedent that conversational gaps like this are in-scope for the
methodology.)

## Goal (as amended)

Before an agent takes a stance on a user's proposed direction — **adopting it
or rejecting it** — it should **generate and weigh the alternatives
independently first**, including where it would diverge and what the runner-up
option costs, so that the stance it then takes carries signal rather than
social lubrication (or manufactured independence). Success looks like: the
agent's "I agree" *and* its "I'd push back" are each preceded by a visible,
independent weighing of at least the strongest real alternative — one the
agent generated, not just one the user mentioned; the anchoring/mirroring
reflex *and* its contrarian mirror are named as anti-patterns; the user can
calibrate on the agent's stance because it is no longer free. Explicit
non-goals: turning every agreement into a filibuster — the skill's existing
"one clear statement, not a filibuster" and "no relitigating" guards must
survive — and manufacturing rivals to a genuinely dominant option, where the
honest output is one sentence on what was considered and why it loses.

*(Original goal text covered the agreement polarity only; superseded by the
maintainer amendment above.)*

## Candidate resolutions (for the maintainer to choose — not pre-decided)

- **R0 — Change nothing; treat as an execution failure.** Argue that (c) is
  already covered *in spirit* by "performative agreement" (SKILL.md:42) and the
  fix is consistent application, not more doc. Weakest-looking to me, but it is
  the honest null hypothesis and should be ruled out on merit, not skipped.
- **R1 — Extend `evidence-over-deference`.** Add case (c) as an explicit
  trigger (agreement / adopting the user's framing), plus an anti-pattern for
  anchoring on the user's stated preference before weighing alternatives.
  Pro: avoids ~80% overlap with the existing skill; keeps the set small.
- **R2 — New sibling skill** (e.g. `independent-judgment-before-agreement`).
  Pro: matches the methodology's own precedent — "challenge the user" became a
  standalone skill despite overlapping `honest-reframing`. Con: dilution/overlap.

My lean is **R1, ~60/40 over R2** — but I am flagging that as a weak preference
precisely because case-(c) failure is *why this brief exists*; the maintainer,
with no anchor on my framing, is better positioned to call it. Do not read my
lean as a recommendation to skip R0.

## Enforcement reality (state it plainly, don't promise theater)

Like its parent skill, this governs a conversation; a checker that grades "did
you weigh alternatives before agreeing" would be theater (cf.
`evidence-over-deference` Enforcement, SKILL.md:50). Expect the honest residual
to be "mostly judgment," with at most a weak trail (consequential agreements
recorded where decisions are recorded). The SPECS phase should resist inventing
a gate here just to have one.

## Constraints / non-goals

- Lands in **agent-methodology**, through its own spec chain; not a drive-by edit.
- Keep the principle set from bloating — this is a sharpening, not a new
  subsystem. YAGNI on tooling.
- Preserve `evidence-over-deference`'s existing guards: challenge once, human's
  decision wins after being heard, no relitigation.
- *(Amendment)* The fix must not be satisfiable by **ritual
  alternative-listing** — naming a strawman alternative and dismissing it so
  the pre-decided stance can proceed. Whatever lands needs a guard parallel to
  the existing "vague pushback" anti-pattern: the alternative weighed must be
  the strongest one, with a real cost attached.
- *(Amendment)* Case-(a) verification is not displaced: proposed directions
  often embed checkable premises, and those still get checked first. Case (c)
  covers the residual where the disagreement-space is trade-offs, not facts.

## Open questions

1. Is (c) genuinely distinct from "performative agreement" as already written,
   or a re-description (decides R0)?
2. If extended (R1), does adding an agreement-trigger over-fire and make the
   agent tediously contrarian on trivial proposals? Where is the floor —
   presumably the same "non-trivial work" bar AGENTS.md already uses.
3. Does the fix belong only in `evidence-over-deference`, or also as a one-line
   cross-reference from `honest-reframing-over-overclaiming` (its metric-facing
   twin)?
