# RESEARCH — weigh-before-stance extension of `evidence-over-deference`

*Consumes: [BRIEF.md](BRIEF.md) (accepted 2026-07-12 with the stance-neutral
amendment). Feeds: SPECS. Date: 2026-07-12. Method: 4 parallel scoped research
scouts (machine checks, sibling house style, external prior art, R0/R1/R2
precedent) + live probes of the repo's own gates
([experiments/gate-behavior/](experiments/gate-behavior/Lessons.md)). Every
load-bearing repo claim was re-verified against the file or by running the
check; external claims are tiered primary/secondary as marked.*

## 1. Machine-enforced constraints on the edit (probed, not just read)

Observed by mutating the worktree and running the real hooks
([decisions.jsonl](experiments/gate-behavior/decisions.jsonl)):

- The frontmatter `description` must be **one physical line** starting
  `description: Use when` plus a trailing space — a folded YAML scalar fails
  `check-skill-frontmatter.sh` (observed exit 1). There is **no length cap**
  (MD013 disabled in `.markdownlint-cli2.yaml:2-6`).
- `name: evidence-over-deference` must equal the dir slug; the body must keep a
  line exactly `## Enforcement` (`check-skill-frontmatter.sh:19-24`).
- Every `../<slug>/SKILL.md` link must resolve (`check-crosslinks-resolve.sh`).
- Commit gates (local + replayed per-commit in CI): conventional type prefix
  and ≥1 provenance trailer. `feat(evidence-over-deference): ...` + sign-off
  passes both (observed).
- **A description/trigger rewrite alone passes all 17 hooks green** (observed
  exit 0) — no machine check compares prose copies. See §2.

## 2. Sync surface — what the machine does NOT force (the silent-drift set)

Four files carry unchecked prose paraphrases of the skill's trigger/rules that
must be hand-edited in the same commit or they drift silently (each location
re-verified by reading the file):

| File | Location | What it carries |
| --- | --- | --- |
| `AGENTS.md` | :86-88 | full condensed paragraph |
| `README.md` | :34 | index-table row paraphrasing the trigger |
| `adapters/cursor/methodology.mdc` | :26 | one-bullet summary (incl. "Symmetric:" tail) |
| `adapters/copilot/copilot-instructions.md` | :100-104 | heading + 3 summary bullets |

Not needed: `adapters/gemini/GEMINI.md` (name-only list),
`adapters/claude/` (thin pointer, excluded by `check-adapters-complete.sh:3-5`),
`templates/` (mirrors configs/checks only), and back-links from sibling skills
(not forced — but see §6 Q3).

Precedent confirms the bucket: description-semantics changes landed as ~5-file
commits (b90d6c3, 0d70202: SKILL.md + AGENTS.md + cursor + copilot; README row
when the trigger wording changes), vs 1-file for body-only sharpenings
(508fd90).

## 3. House style the extension must match (primary: file reads)

- **Skeleton is fixed** across all 21 skills: frontmatter → H1 imperative →
  thesis paragraph → `## When to use` → `## The rule` → `## Why` →
  `## In practice` → `## Anti-patterns` → `## Enforcement` → related footer.
  New triggers belong **inside** `When to use`/`description`, not a new
  section (the only sanctioned extra H2s are binding machine-facing contracts:
  adversarial-lens-review's lens table, dev-environment-facade's vocabulary).
- **Description grammar:** `Use when <trigger>, or <trigger> — <compressed
  imperative>[; <caveat>]`. evidence-over-deference is one of only two skills
  with a semicolon caveat tail (`; their decision still wins.`) — it must
  survive the widening.
- **Symmetry machinery already exists in this skill and only this skill:**
  rule 4's paired "without performative agreement / without stubbornness"
  construction (SKILL.md:28), the `(Symmetrically)` red flag (:21), and the
  `The mirror image:` anti-pattern (:46). The stance-neutral amendment extends
  an existing local idiom, not a foreign one.
- **Anti-over-fire floors live inside rules**, not as separate sections:
  decision-memory rule 7 ("but only when it matters... needs no ceremony"),
  eod rule 5 ("re-raising it every turn is nagging, not honesty"). The
  triviality floor for the new trigger has structural precedent there, plus
  AGENTS.md:26's repo-wide bar ("anything beyond a one-file, fully-understood
  change").
- **Voice:** rules = bold 3-9-word imperative headline + 1-3 sentences,
  ~30-70 words, closing aphorism; red flags = quoted first-person inner
  monologue, 5-15 words; anti-patterns = one-line noun/gerund phrase with an
  em-dash consequence clause.
- **Footer:** this skill uses `---` + `Related skills:` + **path-as-text**
  links — keep its local variant (the repo has four footer styles).
- Confirmed by direct read: `honest-reframing-over-overclaiming`'s footer does
  **not** link back to evidence-over-deference (its :59-66 lists six other
  skills), while eod links honest-reframing both inline (:33) and in its
  footer — the reciprocal link is genuinely missing.

## 4. External prior art (scout: web; tiers as marked)

**The gap is real and measured, not anecdotal (primary):**

- Sycophancy is driven by preference pressure itself — humans and preference
  models "prefer convincingly-written sycophantic responses over correct ones
  a non-negligible fraction of the time" (Sharma et al. 2023,
  arXiv:2310.13548). The 2025 GPT-4o incident located it at the reward level;
  offline metrics looked fine (openai.com postmortem). Instruction-level fixes
  are therefore *mitigation, not cure* — the Enforcement section should say so.
- "Framing sycophancy" — adopting the asker's framing — is a named, measured
  dimension: LLMs preserve the user's face ~45pp more than humans and affirm
  **both sides of the same conflict in 48% of cases** depending on who asks
  (ELEPHANT, arXiv:2505.13995). A stance that mirrors the asker carries no
  signal — the brief's core claim, externally corroborated.

**The amendment's two requirements are each independently supported (primary):**

- *Stance-neutrality is load-bearing, not stylistic:* ELEPHANT tested the
  naive mitigation ("instruct the model to be less validating") and it
  **overcorrected across the board**, eliminating appropriate affirmation too.
  A polarity-flippable rule has already failed empirically. Anthropic's own
  instruction evolution shows the same lesson: the Claude 4 blunt "never open
  with praise" ban was replaced in current published prompts by calibrated
  "willing to push back... but does so constructively" language. OpenAI's
  Model Spec phrases its rule stance-neutrally ("give its honest assessment,
  not simply agree to please") — the shape this extension should take.
- *"Before" is load-bearing:* SycEval (arXiv:2502.08177) — a user lean stated
  **preemptively** induces more sycophancy than one stated after the model's
  answer (61.75% vs 56.52%, p<0.001) and more wrong final answers. The
  leverage is in forming judgment before absorbing the lean.

**The new theater risk is also measured (primary):** Turpin et al.
(arXiv:2305.04388) — chain-of-thought rationalizes anchored answers without
mentioning the anchor (accuracy drops up to 36% while explanations stay
fluent). A *visible* weighing can be post-hoc rationalization; the
ritual-alternative-listing anti-pattern operates at the reasoning level, and
no checker can grade it. Confirms the brief's enforcement-honesty stance.

**Nuance that supports stance-neutrality (primary):** most measured
sycophantic flips are *progressive* — toward the correct answer (43.52% vs
14.66% regressive, SycEval). Deference is not uniformly wrong; "agree less" is
the wrong rule, "weigh first" is the right one.

**Human decision-hygiene analogues (secondary):** anchoring-and-adjustment
(Tversky & Kahneman 1974); premortem / prospective hindsight (~30% more
failure reasons identified; Klein, HBR 2007); WRAP's "widen your options" /
vanishing-options test (Heath & Heath 2013) — the closest analogue to the
generative step; Amazon's "Have Backbone; Disagree and Commit" — prior art
that challenge-once-then-commit is a stable named practice (matches existing
rules 3/5).

**Honest residual:** no published study directly tests this exact intervention
(instruct an agent to generate/weigh alternatives before taking a stance).
The extension is ahead of the measured literature; its wording choices lean on
the adjacent evidence above, not on a direct measurement.

## 5. R0 / R1 / R2 against the evidence

- **R0 (change nothing) — refuted on two independent grounds.** (1) Textual:
  every mechanism in the current skill presupposes a fact an artifact can
  settle in seconds — check-shaped, not weigh-shaped; the "performative
  agreement" anti-pattern (:42) fires only on "an error you *spotted*," which
  is precisely what case (c) lacks. The trigger cannot reach the failure. (2)
  Practice: the repo has never dismissed a field-observed failure as an
  execution failure — every field incident cited in a commit body produced a
  doc change (508fd90, 4eb4919, f74c8a2, 6fc5649, d47a6e5, dbe5587).
- **R2 (new sibling skill) — viable but off-criterion.** Mechanical cost is
  small (exactly 6 files, ~13 index lines; both historical skill-adds match)
  and set growth has precedent (14 → 21 skills in 28 commits). But the repo's
  de facto extend-vs-new criterion, visible in PR #6 — the same session that
  birthed evidence-over-deference — is **territory, not overlap %**: concerns
  inside an existing skill's territory were folded in (508fd90, 4eb4919);
  the new skill was created because "the pack governed every engineering
  artifact but said nothing about the conversation" (d47a6e5 body). Case (c)
  sits squarely inside evidence-over-deference's territory (the conversation,
  the stance, the calibration of agreement).
- **R1 (extend in place) — chosen; matches criterion and precedent.** Seven
  prior commits sharpened existing skills in place. Cost bucket: ~5-6 files
  (SKILL.md + the §2 sync set). The BRIEF's lean survives contact with the
  evidence, now with a stronger justification than the brief's own (~80%
  overlap estimate): territory criterion + check-vs-weigh structural gap.

## 6. BRIEF open questions — status after research

1. **Is (c) distinct from "performative agreement" as written?** Resolved:
   yes — see §5 R0(1). Carries into SPECS as the requirement that the new
   trigger fire *without* any pre-spotted error in hand.
2. **Does an agreement-trigger over-fire into tedious contrarianism?** The
   risk is real and measured (ELEPHANT overcorrection, §4). SPECS must
   include: a triviality floor (AGENTS.md:26 bar; within-rule floor per §3),
   preservation of the one-clear-statement and no-relitigating guards, and the
   dominant-option escape (one sentence on what was considered, then proceed).
3. **Cross-reference from honest-reframing?** The twin relationship is already
   expressed inline (eod:33) and in eod's footer; the **reciprocal footer link
   from honest-reframing is missing** (verified) — add that one line; no body
   change to honest-reframing needed.

## Sources

- Repo (primary, re-verified): `skills/evidence-over-deference/SKILL.md`;
  `AGENTS.md:26,86-88`; `README.md:34`; `adapters/cursor/methodology.mdc:26`;
  `adapters/copilot/copilot-instructions.md:100-104`; `CONTRIBUTING.md`;
  `scripts/checks/*.sh`; `.pre-commit-config.yaml`; `.markdownlint-cli2.yaml`;
  live probe runs in [experiments/gate-behavior/](experiments/gate-behavior/).
- History (primary via GitHub + local reflog): commits 508fd90, 4eb4919,
  f74c8a2, 6fc5649, db44dc6, b90d6c3, 0d70202, d47a6e5, dbe5587, 94d6578,
  4b41fbd, 1a61d4f; PR #6.
- External (primary = fetched paper/page): arXiv:2310.13548 (Sharma et al.);
  arXiv:2505.13995 (ELEPHANT); arXiv:2502.08177 (SycEval); arXiv:2305.04388
  (Turpin et al.); OpenAI Model Spec 2025-04-11 §"Don't be sycophantic";
  Anthropic published system prompts (release-notes page) + Constitution;
  OpenAI sycophancy postmortem (via quoted mirror; direct fetch 403).
- External (secondary): arXiv:2411.15287 (survey); arXiv:2412.06593 (LLM
  anchoring, not fetched in full); Klein premortem (HBR 2007); Heath & Heath
  *Decisive*; Amazon leadership principles page; Tversky & Kahneman 1974
  (canonical, not fetched).
