---
name: pr-message
description: Generate and maintain a pull request description following the project's standard template. Use whenever opening a PR/MR, drafting a PR body, or when new commits are pushed to a branch with an existing PR (any status — draft, open, ready for review). Also triggers on phrasings like "the PR message", "PR description", "update the PR". MANDATORY after every push: if the pushed branch has an associated PR, always invoke this skill to update the PR body — no exception.
metadata:
  audience: contributors
  scope: git-workflow
---

## When to use this skill

Trigger this skill any time you are about to push a branch, open a PR/MR, or the user asks you to draft a pull request message. Always use it — never improvise a freeform PR body.

Also trigger it after **every new commit pushed to a branch that already has an associated PR**, regardless of the PR's status (`draft`, `open`, `ready for review`). The PR body must stay in sync with the branch's actual contents.

## Token optimization

**Do NOT perform exploratory searches** when using this skill. You already have all the data you need:

- **Ticket information**: Ask the user explicitly (never search)
- **Code changes**: Use `git diff <base-branch>...HEAD` (cumulative branch diff)
- **Commit history**: Use `git log <base-branch>..HEAD --oneline` (compact format)
- **Dependency changes**: Use `git diff <base-branch>...HEAD -- package-lock.json` (or other lockfiles)
- **Existing PR body**: Use `gh pr view --json body` when updating

**Never**:
- Search the codebase for ticket references
- Read multiple files to "understand" the change
- Fetch external ticket system APIs
- Analyze code in depth

This skill is about **packaging existing information**, not researching it. Keep token usage minimal.

## Commands

GitHub operations:

```bash
# Check if PR exists for branch
gh pr list --head <branch-name> --json number,title,state

# Fetch current PR body
gh pr view <pr-number> --json body

# Update PR body
gh pr edit <pr-number> --body-file <file>
```

Use direct `git` commands for diffs (they're already concise):

```bash
# Cumulative branch diff
git diff <base-branch>...HEAD

# Lockfile diff only
git diff <base-branch>...HEAD -- package-lock.json package.json

# Commit history
git log <base-branch>..HEAD --oneline
```

## Workflow

### First time (PR does not yet exist)

1. **Ask the user explicitly** for the two pieces of information that cannot be inferred from the diff:
   - The **ticket ID and title** (e.g. `PROJ-142 — Fix login redirect on Safari`).
   - The **ticket description**: the goal, the problem it addresses, or the business context (one to three sentences).
   Do this even if a ticket-shaped string appears in the branch name — the branch name is a hint, not a source of truth. Confirm it.
2. Fill the rest of the template from the diff, the commits, and the lockfile changes.
3. Open the PR with the resulting body.

Do not proceed to step 2 until the user has answered. If the user declines to provide a ticket, leave `[TICKET-000]` and the one-line description as placeholders and flag this explicitly in your response.

### Subsequent commits (PR already exists)

After pushing any new commit to a branch that has an associated PR:

1. Fetch the current PR body (e.g. `gh pr view --json body`).
2. Re-derive each section from the **full branch diff against the base branch**, not just the latest commit.
3. Update only the sections whose factual content has changed:
   - **Type of Change** — re-evaluate; a refactor PR that gains a bug fix should check both boxes.
   - **Changes** — extend or rewrite to reflect the new scope.
   - **Reviewer Notes** — add any new gotchas introduced by the latest commits.
   - **Impacted Dependencies** — recompute from the cumulative lockfile diff.
4. Preserve the **📋 Ticket** section verbatim — do not regenerate it unless the user explicitly asks. The ticket identity is fixed for the life of the PR.
5. Push the updated body (e.g. `gh pr edit --body-file <file>`).

This applies to **draft PRs too** — keeping a draft's description fresh is part of the workflow, not optional.

## The template

Output the PR body using exactly this structure:

```markdown
## 📋 Ticket
**[TICKET-000] <Ticket title>**
<Short description of the ticket: the goal, the problem it addresses, the business context>
Closes #<issue number>

## 🔄 Type of Change
- [ ] 🐛 Bug fix
- [ ] ✨ New feature
- [ ] 💥 Breaking change
- [ ] 🧹 Refactoring / cleanup
- [ ] 📝 Documentation
- [ ] ⚙️ CI/CD / config

## 📝 Changes
<Straightforward summary of what was changed in the code — high-level only, no deep details>

## ⚠️ Reviewer Notes
<Anything that deserves special attention>

## 📦 Impacted Dependencies
<Libraries added, updated, or removed>
```

## How to fill each section

**📋 Ticket**
- **Always ask the user** for the ticket ID, title, and ticket description on the first generation — do not derive them from the branch name alone, even if the branch name contains a ticket-shaped string.
- The **ticket description** captures the *why*: the goal of the ticket, the problem it addresses, or the business context. One to three sentences. It is independent from the code changes and should read identically whether the implementation is one line or one thousand.
- Never invent a ticket ID. If the user has none, use `[TICKET-000]` as a placeholder and flag this in your response.
- If an issue number is unknown, leave `Closes #` as-is for the human to complete; do not delete the line and do not guess a number.
- Once set, **freeze this section** for the life of the PR. Do not regenerate it on subsequent updates unless the user explicitly asks.

**🔄 Type of Change**
- Check exactly one box in the standard case. Multiple boxes are acceptable only when a change genuinely spans categories (e.g. a refactor that also fixes a bug).
- Replace `- [ ]` with `- [x]` for the selected entries. Leave unchecked entries as `- [ ]`.

**📝 Changes**
- Describe **what was changed in the code** — nothing else. No business rationale, no problem statement (those belong to the Ticket section).
- Keep it **straightforward and high-level**: a reviewer should grasp the scope of the diff in 5–10 seconds. Bullet points are fine; 2–4 short bullets is the sweet spot.
- Mention files/modules/features touched, not line-by-line details. "Refactored `AuthService` to use the new token store" — yes. "Renamed `getUser()` to `fetchUser()` on line 42" — no.
- If multiple distinct things changed, list them as bullets rather than packing them into prose.
- On **subsequent updates** (new commits pushed), re-derive this section from the cumulative branch diff. Extend or rewrite it — do not simply append.

**⚠️ Reviewer Notes**
- Use this for anything non-obvious: tricky tradeoffs, intentional omissions, follow-up work, areas needing extra scrutiny, manual test steps.
- If there is genuinely nothing to flag, write `None.` — do not delete the section.

**📦 Impacted Dependencies**
- List packages added, upgraded, downgraded, or removed, with old → new versions when known.
- Detect changes by diffing lockfiles or manifest files (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.).
- If no dependencies changed, write `None.`

## Rules

- **Keep every section.** Do not drop sections even if empty — write `None.` or `N/A` instead.
- **Ask, never improvise.** If any piece of information is not clearly available — business context, the problem being solved, the rationale, the ticket ID, an issue number, the intent behind a change, anything — **ask the user** before writing the PR. Do not hallucinate, do not guess from context, do not paper over a gap with plausible-sounding filler. A pause to ask is always better than a fabricated description that a reviewer has to unlearn.
- **No invented facts.** This applies to every section. If asking is genuinely not possible (e.g. an automated context with no human in the loop), use an explicit placeholder like `[TICKET-000]`, `Closes #`, or `<missing: business context — please fill in>` and flag every placeholder in your response so the human sees what is incomplete.
- **Stay factual.** Describe what the diff does, not what you hope it does. No marketing tone.
- **English only**, regardless of the language of the conversation.
- **Output the markdown body only** — no surrounding commentary, no code fence around the whole thing unless the user explicitly asks for a copy-pasteable block.
