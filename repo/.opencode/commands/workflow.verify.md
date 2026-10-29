---
description: Run the mechanical drift checks on the ticket-to-code chain and on the domain knowledge base.
---

# /workflow.verify

Run the four mechanical checks and report their output as-is.

This command is named `workflow.` and not `speckit.` deliberately: the `speckit.`
prefix belongs to the CLI, and a future `specify upgrade` may overwrite files that
carry it.

## What to do

1. Determine the feature directory: the argument if given, otherwise the
   `feature_directory` value in `.specify/feature.json`.

2. Run, from the repository root:

   ```bash
   ./.specify/scripts/bash/verify-traceability.sh [feature-dir]
   ./.specify/scripts/bash/verify-implementation.sh [feature-dir]
   ./.specify/scripts/bash/verify-domain-base.sh
   ./.specify/scripts/bash/verify-review-commits.sh [pr-base-ref]
   ```

   Run the second one only if implementation has started. Before that, it has
   nothing to look at and will say so.

   The third takes no argument and runs whether or not a feature is in flight: it
   reads `docs/domain/`, which every ticket reads in turn, so a broken pointer in
   it is a defect now, not at implementation time. Report its counts verbatim with
   the rest — they are the reason no file in the knowledge base states one in
   prose.

   The fourth checks the shape of the branch's commits: no `refactor:` editing a
   scenario or a spec, a test commit between a changed requirement and its
   implementation, no `Covers:` group lost. Pass the pull request's base branch
   (`gh pr view --json baseRefName`, prefixed `origin/`); a stacked PR does not
   target `main`, and comparing against `main` would report the parent's commits.
   It reads first-parent commits only, so merging the base in does not pull the
   base's history into the check.

3. **Report the output verbatim.** Do not summarise it, do not soften it, do not
   turn `INCOMPLETE` into "mostly fine". The value of these scripts is that they
   are not a judgement — restating them in your own words destroys exactly that.

4. Add, separately and clearly labelled, your own reading of whether the code does
   what the ticket asked.

## The separation that must never collapse

Two kinds of verification live here, and merging them into one score would sell
confidence that was never earned:

- **Mechanical** — "does FR-003 appear in `tasks.md`?" True or false. A script
  answers. No room for error.
- **Semantic** — "does the code do what the ticket asked?" This is the same model
  that wrote the code judging its own work. It catches outright omissions. It does
  **not** catch misunderstandings, because a misunderstanding is coherent with
  itself: wrong code, wrong tests, all agreeing with each other.

Report them apart:

```
Mechanically verified   12/14   (2 drifts, listed above)
Semantically judged     no gap detected
                        ⚠ the model judging its own output
```

**Never emit a single global ✅.** "93% compliant" is a number that means nothing
and reassures anyway.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | No drift detected by the mechanical checks |
| 1 | Drift found — listed in the output |
| 2 | **Could not check** — a structure was not recognised. This is not a pass. |

Exit code 2 matters more than it looks. These scripts parse markdown, which is
fragile by nature: a `specify upgrade` changing how requirements are numbered would
break them. They are written to fail loudly rather than silently report zero
drift — a check that finds nothing because it looked nowhere is worse than no check
at all, because it produces false confidence.

If you see exit code 2, fix what blocks the check before proceeding. Do not
proceed on the assumption that silence means clean.
