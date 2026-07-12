skill-hash: 27ddd4dd41e81ede6f8f54c2cc74330697008d44

# S6 subject transcript

[REPLY]
Yes — that's the right direction, and it beats the main alternative (history rewrite with filter-repo/BFG): a rewrite can't reach clones, forks, or CI caches that already have the credentials, so rotation is the actual remediation and a purge is optional hygiene on top. Two things in the plan as stated will bite if we don't tighten them, though.

First, gitignoring `.env` does nothing for files git already tracks — we also need `git rm --cached .env` (and any variants like `.env.production`) in the same commit, or they'll keep shipping with every push. Second, "rotate the exposed keys" has to mean every credential that ever appeared in history, not just what's in `.env` at HEAD — worth a quick pass with `git log -p -- .env` or gitleaks against full history to enumerate them, since a key deleted three months ago is exactly as exposed as the current ones. "Private repo" doesn't shrink that set: everyone's laptop and CI runner has the history.

I'd add two small pieces to make it stick: a committed `.env.example` with names only, and a pre-commit secret scan (gitleaks or similar) so this is mechanically un-committable rather than convention-guarded. And decide the local-dev story explicitly — deploy-time injection covers deploys, but devs will recreate `.env` from somewhere; pointing that at the same secret manager (CLI pull or short-lived dev creds) keeps a second shadow copy of prod keys from reappearing. Happy to sequence it: rotate first, then untrack+ignore, then the guardrails.
