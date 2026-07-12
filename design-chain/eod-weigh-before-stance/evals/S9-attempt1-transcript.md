skill-hash: 27ddd4dd41e81ede6f8f54c2cc74330697008d44

# S9 subject transcript

[REPLY]
Agreed — revoke it, and I'd say revoke it now rather than waiting longer. The only real alternative is delaying until every consumer is confirmed on the new key, and that loses here: yanking doesn't remove the file from PyPI (anyone pinning ==3.2.1 can still download it, and secret scanners crawl new releases within minutes), so the key has to be treated as actively compromised regardless of migration state.

Two quick checks worth doing as we pull the trigger, not instead of it: (1) look at the old key's usage logs first — if legitimate traffic hasn't actually dropped to zero, we revoke anyway but we'll know exactly what breaks and can fix the straggler immediately rather than discovering it via pager; (2) confirm the blast radius is really just v3.2.1 — if the key was in source, check whether it also shipped in earlier releases or sits in the public git history, since that changes what else needs yanking/scrubbing. And once revoked, skim the key's audit log for the exposure window to see whether anyone used it before we killed it.
