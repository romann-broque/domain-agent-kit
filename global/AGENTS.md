## Superpowers Workflow Files

The `brainstorming` and `writing-plans` skills write files to `docs/superpowers/`.
These files are **internal workflow artefacts**, not project documentation.

**Rule**: before writing any file to `docs/superpowers/` in a project repo:
1. Check whether `docs/superpowers/` is in the project `.gitignore`
2. If not, add it BEFORE creating the files
3. NEVER commit `docs/superpowers/` in a project repo

---

## Skill Loading

Whenever you load a skill using the `skill` tool, ALWAYS display the following banner immediately — before any other content in your response:

```
##############################################################################

                        Skill loaded: <skill-name>

##############################################################################
```

Replace `<skill-name>` with the `name` field from the skill's frontmatter.

---

## GitHub Actions & Pull Request Safety

### Absolute rule — No write actions on GitHub

NEVER perform any write action on GitHub. This includes but is not limited to:

- Posting review comments (`gh pr review --comment`)
- Submitting approvals or change requests (`gh pr review --approve / --request-changes`)
- Creating or closing issues
- Merging pull requests

All analysis (PR reviews, code reviews, etc.) MUST be presented exclusively in the conversation, unless the user explicitly requests otherwise.

### Exceptions

Read-only `gh` commands are always allowed:
- `gh pr view`, `gh pr diff`, `gh pr checks`
- `gh pr list`, `gh issue view`
- Any command that only reads data

The following write actions are explicitly allowed:
- Replying to a review thread to document a fix or a decline decision
- Resolving a review thread via GraphQL `resolveReviewThread`

### Tooling failures — diagnose the root cause before working around it

When a `gh` command fails, **do not immediately reach for a workaround**. A workaround that
papers over an outdated tool becomes stale advice the moment the tool is fixed, and it hides
the real problem from the user.

**Procedure**:

1. **Isolate the failure.** Reproduce the failing call in its smallest form (e.g. replay the
   underlying `gh api graphql` query by hand) to identify the exact field or endpoint at fault.
2. **Check whether the tool is outdated** before blaming the repository or the API:
   ```bash
   gh --version
   brew outdated gh    # or the relevant package manager
   ```
3. **Test the same command against another repository.** If it fails there too, the cause is
   the local tool, not the repo. Never describe a failure as repo-specific without this check.
4. **Fix the root cause** (upgrade the tool) and **verify** with an idempotent operation before
   declaring it resolved.
5. Use a workaround only as a temporary fallback, and state explicitly that it is one.

**Known pattern — deprecated GraphQL fields**: `gh` versions predating a GitHub API sunset may
still request removed fields (e.g. `projectCards`, Projects classic). GraphQL propagates the
error up and nulls the whole parent node, so `gh` aborts before sending its mutation and the
write silently never happens. Symptom: an error mentioning a deprecation notice, and no change
on GitHub. **Fix: upgrade `gh`.** The REST equivalent
(`gh api repos/<owner>/<repo>/pulls/<n> -X PATCH -F body=@file`) bypasses GraphQL entirely and
is a valid fallback while the upgrade is pending.

---

## Git Safety Policies

### Commit Policy

- **Code formatting**: ALWAYS apply the project's formatters and linters before committing, e.g. for JS/TS:
  - Run `npx prettier --write <files>` on all modified files
  - Run `npx eslint --fix <files>` on all modified TypeScript/JavaScript files
  - Verify build passes after formatting
  - Include formatting in the same commit as code changes (not separate commits)
- **Build verification**: Can commit locally ONLY if build passes (`npm run build`, `./gradlew build`, etc.)
- **Incremental commits**: When full test suites may cause timeouts/OOM, commit incrementally but verify build first
- **Branch protection**: NEVER commit directly to `main`/`master` - ALWAYS work on feature branches
- **Same-PR commits**: When fixing review comments on an existing PR, ALWAYS commit to the SAME feature branch

### Push Policy

**ABSOLUTE REQUIREMENT**: NEVER push to remote without EXPLICIT user confirmation.

**Rules**:
1. **Always ask before pushing** - Even if the user says "commit this" or "fix this", do NOT push automatically
2. **Wait for explicit approval** - User must say "push", "push this", "push it" or similar explicit push command
3. **Commit locally is OK** - You can commit locally after completing a task, but NEVER push without asking
4. **Show what will be pushed** - Before asking, show the user what commits will be pushed (`git log origin/<branch>..HEAD --oneline`)
5. **`gh pr create` is a push** - Opening a PR requires a push first. Treat `gh pr create` with the same requirement as `git push`. The user must explicitly say "push" or "open the PR" for both to be executed.
6. **No exception for CI/fix commits** - Even for urgent fixes after a CI failure, ALWAYS show pending commits and ask for authorization before pushing. "It's urgent" is not an exception.
7. **Update PR description after every push** - After EVERY push to a branch that has an associated PR (any status: draft, open, ready for review), ALWAYS invoke the `pr-message` skill to update the PR body. No exception. This is mandatory, not optional.

**Why**:
- User must have full control over what goes to remote
- Commits can be amended/fixed locally before going public
- Avoid pushing broken code or incomplete work
- PR updates trigger CI/CD - user should decide when

**Workflow**:
```bash
# ✅ Allowed without asking
git add <files>
git commit -m "message"

# ❌ FORBIDDEN without explicit user approval
git push origin <branch>

# ✅ Correct flow
# 1. Commit locally
git commit -m "fix: something"

# 2. Show what will be pushed
git log origin/feature-branch..HEAD --oneline

# 3. Ask user
"I've committed the changes locally. The following commits are ready to push:
- abc1234 fix: something
- def5678 test: add tests

Do you want me to push these to origin/feature-branch?"

# 4. Wait for explicit "push" confirmation
# 5. ONLY THEN: git push origin feature-branch
# 6. If the branch has an associated PR → invoke pr-message skill to update PR body
```

**No exceptions** - Even for "urgent fixes" or "obvious corrections", ALWAYS ask first.

### Force Push Policy

- **Default**: NEVER use `git push --force` or `--force-with-lease` unless user explicitly requests it
- **When needed**: If rebase or force push is required, ASK user for approval first
- **Exception**: User explicitly says "force push" or "rebase and force push"
- **Never force push to main/master**: Warn the user if they request it

### Merge vs Rebase

**ABSOLUTE REQUIREMENT**: When updating a feature branch with changes from `main`, ALWAYS use **MERGE**, NEVER use **REBASE**.

**Why**:
- Rebase rewrites commit history and creates divergence (e.g., "14 and 14 different commits each")
- Shared branches (PRs) must preserve their history for reviewers and CI
- Merge commits provide clear integration points and conflict resolution history

**Workflow**:
1. **Use `jj` (Jujutsu) for merge operations** (recommended):
   ```bash
   jj git init --colocate  # First time only
   jj bookmark track <branch-name> --remote=origin
   jj new <feature-branch> main -m "Merge main into <feature-branch>"
   # Resolve conflicts if any
   jj bookmark set <feature-branch>
   git push origin <feature-branch>
   ```

2. **Alternative with standard Git**:
   ```bash
   git checkout <feature-branch>
   git merge origin/main
   # Resolve conflicts if any
   git push origin <feature-branch>
   ```

**NEVER do**:
- `git rebase origin/main` on a shared/PR branch
- `git pull --rebase` on a shared/PR branch
- Any operation that rewrites public history

**Exceptions**: Rebase is acceptable ONLY on local-only branches that have never been pushed or shared.

---

## PR Review Thread Resolution

Whenever a PR review comment is addressed — whether the fix is applied or declined —
the agent MUST:

1. **Post a reply** on the review thread (in English) explaining what was done:
   - Fix applied: include the commit SHA and a one-line summary of the change
   - Fix declined: explain the rationale clearly
2. **Resolve the thread** via the GitHub GraphQL API

### Repository Verification (Critical)

**BEFORE applying ANY review corrections, ALWAYS verify**:
- Which repository the PR belongs to (especially in monorepo/multi-repo setups)
- Current working directory matches target repository
- Changes apply to correct codebase (frontend vs backend, service A vs service B)
- NEVER apply backend review comments to frontend code or vice versa

### Commands

All commands below must return the complete, unfiltered API response.

**Reply on a thread:**
```bash
gh api repos/<owner>/<repo>/pulls/<pr>/comments/<comment_id>/replies \
  -X POST -f body="<message>"
```

**Get review thread IDs (needed to resolve):**
```bash
gh api graphql -f query='
{
  repository(owner: "<owner>", name: "<repo>") {
    pullRequest(number: <pr>) {
      reviewThreads(first: 20) {
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes { databaseId }
          }
        }
      }
    }
  }
}'
```

**Resolve the thread:**
```bash
gh api graphql -f query='mutation {
  resolveReviewThread(input: {threadId: "<thread_node_id>"}) {
    thread { isResolved }
  }
}'
```

This applies to comments from any reviewer (Copilot, human, bot) on any PR.

---

## Proactive Self-Improvement

### Principle

Agents must **proactively detect and propose configuration improvements** as soon as an opportunity appears, without waiting for repeated patterns.

**Philosophy shift**:
- ❌ Old: "Wait for 2+ repetitions to confirm pattern"
- ✅ New: "Detect opportunity at first signal, propose if context is relevant"

**Traceability**: All improvements are logged in `~/.config/opencode/SELF_IMPROVEMENT_LOG.md`

---

### When to Propose Improvements

#### Immediate Triggers (Propose on FIRST Occurrence)

Propose **immediately** when you detect:

**🔴 Critical (Safety/Data)**:
- User corrects risky behavior (data loss, security vulnerability)
- User adds safety checkpoint ("verify X before Y")
- **Example**: "Make a backup before modifying this file"
- **Action**: Propose adding backup rule immediately

**🔴 Critical (Explicit Rules)**:
- User says "always X" or "never Y"
- User sets explicit constraint
- **Example**: "Always ask before pushing to remote"
- **Action**: Propose adding rule immediately

**🟡 Important (Workflow Corrections)**:
- User corrects workflow step (order, missing action)
- User specifies command sequence
- **Example**: "Run Prettier BEFORE ESLint"
- **Action**: Propose at end of task (don't interrupt)

**🟡 Important (Project Conventions)**:
- Agent discovers undocumented convention
- Pattern observed in project code/config
- **Example**: All `gh` calls need a project-specific token env var
- **Action**: Propose documenting in project AGENTS.md

**🟡 Important (Skill Triggering)**:
- User asks why skill didn't trigger
- Skill description missing common phrasing
- **Example**: "Why didn't code-review-standards load?"
- **Action**: Propose improving skill description

#### Deferred Triggers (Wait for 2+ Occurrences)

**🟢 Minor (Optimizations)**:
- Workflow comfort improvements (not blocking)
- Cosmetic changes (wording, formatting)
- Subjective preferences (communication style)

**When user explicitly frames as exception**:
- "This time, skip X"
- "Just for this PR, do Y"
- **Action**: Do NOT propose (one-off exception)

---

### Detection Guidelines

**Before proposing, evaluate**:

1. **Is it reusable?**
   - ✅ Yes → Propose for global config or skill
   - ❌ No (one-off) → Do NOT propose

2. **Is it a pattern or exception?**
   - ✅ Pattern → Propose
   - ⚠️ Uncertain → Ask: "Should I apply this systematically?"

3. **What's the risk level?**
   - 🔴 Critical (safety, data) → Propose immediately
   - 🟡 Important (workflow) → Propose at end of task
   - 🟢 Minor (comfort) → Wait for 2nd occurrence

4. **Where to apply?**
   - **Global** (`~/.config/opencode/AGENTS.md`) → Applicable to all projects
   - **Project** (`<project>/AGENTS.md`) → Specific to this project
   - **Skill** → Reusable workflow or methodology

---

### Proposal Template

When proposing an improvement, use this format:

```
🔧 IMPROVEMENT DETECTED

**Trigger**: [What user said/did that triggered detection]
**Context**: [Current task/situation]
**Detection**: [First occurrence / 2nd occurrence / Risk level]

**Proposed change**:
- **File**: [Path to file (AGENTS.md, SKILL.md, etc.)]
- **Section**: [Section name to modify]
- **Modification**: [Exact text to add/modify]

**Benefit**: [Why it's useful: consistency, safety, efficiency, clarity]
**Impact**: [What agents/users will experience differently]

---

✅ Approve | ⚠️ Defer | ❌ Decline
```

---

### Application Workflow

**If user approves**:

1. **Log to `~/.config/opencode/SELF_IMPROVEMENT_LOG.md`** (before modification):
   ```markdown
   ## [YYYY-MM-DD HH:MM] [Short Title]
   
   **Trigger**: [...]
   **Context**: [...]
   **Detection**: [First occurrence / Risk level]
   **Proposed**: [...]
   **User response**: Approved
   **Applied to**: [pending]
   **Commit**: [pending]
   **Impact**: [...]
   ```

2. **Apply the modification** (edit AGENTS.md or SKILL.md)

3. **Update log** (complete pending fields):
   ```markdown
   **Applied to**: ~/.config/opencode/AGENTS.md (line X, section "Y")
   **Commit**: abc1234 "feat(scope): description"
   ```

4. **Update project CHANGELOG.md** (if exists)

---

### Anti-Patterns (DO NOT Propose)

**❌ One-off exceptions**:
- User says "this time" or "just for this PR"
- Context clearly indicates temporary deviation

**❌ Contradicting existing rules**:
- User's request conflicts with documented rule
- **Action**: Ask for clarification first, don't propose

**❌ Unclear benefit**:
- Cosmetic change with no measurable impact
- Subjective preference (communication style)

**❌ Other agent's behavior**:
- Pattern observed in subagent's work (not your responsibility)

---

### Examples

**Example 1**: Repository verification (immediate, critical)
- **Trigger**: User said "verify repo before applying fixes"
- **Detection**: First occurrence, critical risk (cross-repo contamination)
- **Proposed**: Add checkpoint in PR Review Thread Resolution
- **Result**: ✅ Approved, applied immediately
- **Impact**: Prevents applying backend fixes to frontend codebase

**Example 2**: Prettier/ESLint order (deferred, important)
- **Trigger**: User corrected "run Prettier BEFORE ESLint"
- **Detection**: First occurrence, workflow optimization
- **Proposed**: Update Commit Policy to specify order
- **Result**: ✅ Approved, applied at end of task
- **Impact**: Avoids Prettier/ESLint conflicts

**Example 3**: Skip tests (anti-pattern, declined)
- **Trigger**: User said "this time, skip tests"
- **Detection**: One-off exception (explicit "this time")
- **Action**: ❌ Did NOT propose (temporary deviation)

---

### Relationship with Skill-Specific Feedback

**Skill improvements** follow a separate workflow documented in `skill-creator` skill.

**Distinction**:
- **Proactive Self-Improvement** (this section): AGENTS.md, global rules, immediate proposals (1st occurrence for critical/important)
- **Skill Feedback Loop**: SKILL.md workflows, systematic evals, higher threshold (3+ sessions)

When improving a skill's **description** (triggering accuracy), use this section.  
When improving a skill's **workflow/instructions**, use skill-creator eval cycle.

---

