# templates/git-controls — deterministic git controls for a docs/spec pack

This is the methodology pack **eating its own cooking**: the same controls that guard this
repo, packaged so you can drop them into any prose- or spec-shaped repository. They make a
*machine* enforce the structure (see [`hexagonal-with-enforced-contracts`](../../skills/hexagonal-with-enforced-contracts/SKILL.md))
and machine-check the commit discipline (see [`surgical-changes-with-checkpoints`](../../skills/surgical-changes-with-checkpoints/SKILL.md)),
so a broken invariant fails like a red build instead of slipping past a tired reviewer.

## What's here

```text
.pre-commit-config.yaml            # the contract: hygiene + markdown + commit-msg + invariants
.markdownlint-cli2.yaml            # markdown style, relaxed for hand-wrapped prose
.github/workflows/checks.yml       # CI re-runs the SAME hooks, so local and CI can't drift
scripts/checks/*.sh                # eight POSIX-sh invariant validators, zero runtime deps
```

## The two kinds of hook

1. **Off-the-shelf, generic** — file hygiene (`pre-commit/pre-commit-hooks`), markdown style
   (`markdownlint-cli2`), and the conventional-commit type prefix (`conventional-pre-commit`).
   These work on any repo unchanged.
2. **Project-invariant validators** (`scripts/checks/*.sh`) — these encode *this pack's*
   contract: every `skills/<slug>/SKILL.md` has `name:`==slug + a `Use when` description,
   `AGENTS.md` links every skill, the `README` index matches the `skills/` directories, every
   `../<slug>/SKILL.md` cross-link resolves, adapters carry no stale `../../` links, every
   enumerating adapter lists all skills, and (in the source repo) the distributable
   `templates/git-controls/` copy stays byte-identical to the root controls.
   **Adapt these to your repo's own invariants** — they are the part worth keeping, because no
   generic linter can check the contract that is specific to your structure. Two of them assume
   this pack's exact shape: `check-adapters-complete.sh` (drop it if you have no `adapters/`) and
   `check-templates-in-sync.sh` (a no-op unless your repo itself vendors a `templates/git-controls/`).

## Install

```bash
# 0. you need a git repo
git init

# 1. copy the controls to your repo root
cp -R templates/git-controls/. .

# 2. install a hook MANAGER (pick one):
pipx install pre-commit        # Python; or:  brew install pre-commit
#   zero-Python alternative — a single static binary that reads the same config:
brew install prek

# 3. wire the hooks (installs BOTH the pre-commit and commit-msg stages)
pre-commit install --install-hooks    # prek:  prek install
```

`default_install_hook_types: [pre-commit, commit-msg]` in the config is what makes a bare
`install` wire the commit-msg hooks too — without it they are silently skipped.

## Why pre-commit (run via prek), not husky/lefthook

The committed artifact is just `.pre-commit-config.yaml`; each hook's toolchain is provisioned
in an isolated env that never touches your tree, so the repo stays language-agnostic. `prek` (a
single Rust binary) runs that identical config with **no Python runtime**, and CI runs canonical
`pre-commit` on the same file — so local and CI cannot drift. `husky`/`lint-staged` would
manufacture a `package.json` + `node_modules` in a docs repo; `lefthook` uses its own file and
loses the "same config in CI" guarantee plus the pinned third-party hooks.

The load-bearing invariant checks are `language: script` POSIX sh — **zero runtime deps**, so
they run under pre-commit, prek, lefthook, or a raw `.git/hook`, on any machine with a shell.

## Adapting the validators

Each `scripts/checks/*.sh` is small and self-documenting. The three reusable shapes:

- **schema check** (`check-skill-frontmatter.sh`) — assert each file of a kind carries required
  frontmatter keys.
- **index-vs-tree parity** (`check-agents-links-skills.sh`, `check-readme-index.sh`) — assert a
  list in one file equals a set of paths on disk, two-way (nothing missing, nothing stale).
- **link resolution** (`check-crosslinks-resolve.sh`, `check-adapters-no-stale-links.sh`) —
  assert every relative link resolves; ban a forbidden path shape.

Change the globs and the grep/`sed` patterns to your repo's structure and the logic transfers.

## Tiers

- **Minimal floor** (100% POSIX sh + git, no Node/Python linters): the hygiene subset + the
  `repo:local` validators (adapt or drop the two that assume this pack's exact layout). Adopt
  this first if you want zero new toolchains.
- **Recommended** (this config): adds `markdownlint-cli2` and the conventional-commit prefix.
- **Comprehensive**: add `lychee --offline` (once you have external URLs/anchors), `gitleaks`
  in CI, and `mdformat` for auto-formatting. Keep heavy scanners in CI, not on a fresh clone.

## Team opt-in

This config omits `no-commit-to-branch` because the source repo is solo and `main` is its
working branch. For a team that wants a PR workflow, add it back under the
`pre-commit/pre-commit-hooks` repo:

```yaml
      - id: no-commit-to-branch
        args: [--branch, main]
```

## Determinism

Every external `rev:` is pinned to an immutable tag, and the shipped `checks.yml` pins its
GitHub Actions to full commit SHAs (with the tag in a trailing comment). For maximum
reproducibility of the pre-commit hooks too, run `pre-commit autoupdate --freeze` (rewrites each
`rev:` to a commit SHA). Pick **one** autoupdate path — pre-commit.ci's monthly PR or a manual
reviewed `autoupdate` — not both. The `repo:local` validators carry no `rev:`; they are
versioned by the committed script itself.

## License

These controls are part of the agent-methodology pack, released under the
[MIT License](../../LICENSE). Copy and adapt them into your own repositories — proprietary
ones included — freely.
