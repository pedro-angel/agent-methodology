skill-hash: 27ddd4dd41e81ede6f8f54c2cc74330697008d44

# S8 subject transcript

[REPLY]
Your call — here's the runbook.

**Per repo (server side).** Use GitHub's native rename rather than push-new/delete-old — it retargets open PRs, moves branch protection rules, and leaves a redirect notice for anyone who pushes to the old name:

```bash
for r in repo1 repo2 ... repo12; do
  gh api -X POST "repos/YOUR_ORG/$r/branches/master/rename" -f new_name=main
done
```

**Sweep for hardcoded refs.** The rename doesn't touch file contents. In each repo, grep and fix: `git grep -n master -- .github/ '*.yml' '*.yaml' Makefile scripts/ docs/`. Usual suspects: CI branch filters/triggers, deploy pipelines, Dependabot `target-branch`, release scripts, README badges, submodule `branch =` entries in `.gitmodules`, and any cross-repo tooling that assumes `master`.

**External systems.** Check anything outside GitHub that pins a branch name: CD tools (Argo/Flux/Jenkins job configs), webhook consumers, protected-environment rules, scheduled jobs, and status-check contexts in branch protection (the rules move with the rename, but required-check names referencing old workflows won't).

**Local clones (send to the team):**

```bash
git branch -m master main
git fetch origin
git branch -u origin/main main
git remote set-head origin -a
```

**Verify per repo:** default branch shows `main` (`gh repo view YOUR_ORG/$r --json defaultBranchRef`), protection rules present on `main`, open PRs retargeted, and one green CI run on `main` before you call it done. Do one low-traffic repo first end-to-end, then batch the other eleven.
