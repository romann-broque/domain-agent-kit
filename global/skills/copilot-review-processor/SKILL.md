---
name: copilot-review-processor
description: Process automated code review comments (GitHub Copilot, bots, linters) systematically. Use when user asks to "check copilot reviews", "list review comments", "apply copilot suggestions", "address review feedback", or after pushing a PR. Filters scope-relevant fixes from noise (pre-existing issues, cosmetic style), applies pertinent corrections, and documents decisions. Works with any automated reviewer (Copilot, CodeRabbit, SonarQube, etc.).
---

# Copilot Review Processor

A universal workflow for processing automated code review comments systematically, applying scope-relevant fixes while filtering out noise.

## Purpose

This skill provides a structured approach to:
- **Fetch** automated review comments from GitHub PRs
- **Analyze** each comment for relevance to PR scope (not pre-existing issues)
- **Apply** pertinent fixes with build verification before commit
- **Document** decisions in commit messages (addressed + skipped comments)
- **Filter** cosmetic noise that doesn't impact functionality

Works with GitHub Copilot, CodeRabbit, SonarQube bots, linters, or any automated reviewer that posts PR comments.

## When to Use This Skill

Use this skill when:
- User explicitly asks: "check copilot reviews", "liste les commentaires copilot", "apply review suggestions"
- After pushing a PR: proactively check for new automated comments
- User mentions review feedback needs addressing
- Automated reviewer posts comments and user wants systematic triage

**Do NOT use if**: User asks to debug failing tests or explain review concepts (not about processing reviews).

---

## Core Principle

**Scope-Relevant vs Out-of-Scope**:

A review comment is **pertinent** (must fix) if it directly relates to:
- Logic introduced or modified by this PR
- Data integrity bugs introduced by this PR
- Functional correctness of PR changes
- Missing fields/parameters in code added by PR

A review comment is **out-of-scope** (skip) if it relates to:
- Pre-existing code not touched by PR
- Cosmetic style issues (semicolons, spacing) already passing linters
- Naming conventions in legacy code (if PR doesn't modify that code)
- Architectural concerns beyond PR scope (e.g., suggesting full rewrite)

**Key Insight**: Automated reviewers often flag pre-existing issues because the PR touches nearby code. Blocking PRs for legacy problems discourages refactoring and punishes contributors for touching old code.

---

## Workflow

### Phase 1: Repository Verification (CRITICAL)

**BEFORE applying ANY corrections, ALWAYS verify**:

1. **Which repository does this PR belong to?**
   - Frontend repo? Backend service repo? Monorepo component?
2. **Current working directory matches target repository?**
   - `pwd` should show the correct repo path
3. **Changes apply to correct codebase?**
   - Backend review comments must NOT be applied to frontend code
   - Service A fixes must NOT be applied to Service B

**Why this matters**: In multi-repo setups, automated reviewers can post comments on multiple PRs. Applying backend fixes to frontend code (or vice versa) is a critical error.

**Example check**:
```bash
# Verify current location
pwd
# Expected: /path/to/frontend-repo or /path/to/backend-service

# If wrong, navigate to correct repo BEFORE fetching comments
cd /path/to/correct-repo
```

**If verification fails**: STOP immediately, ask user to clarify which repo to work in.

---

### Phase 2: Fetch Review Comments

Use GitHub CLI to fetch automated review comments from the PR.

**Command** (generic, adapt to project auth):
```bash
gh api graphql -f query='
{
  repository(owner: "<owner>", name: "<repo>") {
    pullRequest(number: <pr-number>) {
      reviews(first: 10) {
        nodes {
          author { login }
          body
          comments(first: 50) {
            nodes {
              path
              line
              body
              databaseId
            }
          }
        }
      }
    }
  }
}'
```

**Authentication**: If project uses specific auth env vars (e.g., `GH_TOKEN=$TOKEN`), prefix the command:
```bash
GH_TOKEN=$TOKEN gh api graphql -f query='...'
```

**Output**: JSON with all review comments. Parse to extract:
- `path` (file location)
- `line` (line number)
- `body` (comment text)
- `databaseId` (comment ID for reference)

---

### Phase 3: Analyze Each Comment for Relevance

For each comment, ask:

#### ✅ **PERTINENT** (must fix)

Issues **directly related to PR scope**:
- **Data integrity bugs**: Type mismatches, missing required fields, data loss
- **Logic errors in PR changes**: Incorrect conditionals, wrong calculations, broken control flow
- **Missing fields in queries/mutations**: GraphQL query missing field, API call missing parameter
- **Test assertions on wrong paths**: Test added by PR but asserts wrong object property
- **Critical errors introduced by PR**: Null pointer risks, resource leaks, security vulnerabilities

**Example**:
- PR adds GraphQL mutation for user update
- Copilot flags: "Mutation is missing `email` field in response"
- **Verdict**: PERTINENT (functional bug in PR code)

#### ❌ **OUT-OF-SCOPE** (skip)

Issues **NOT related to PR scope**:
- **Style/formatting**: Missing semicolons, spacing, tabs vs spaces (if linters pass)
- **i18n key naming**: Translation key doesn't follow convention (if PR doesn't modify i18n keys)
- **Legacy patterns**: Old code uses outdated pattern (if PR doesn't touch that code)
- **Pre-existing tech debt**: God Class, Long Method (if PR doesn't worsen it)
- **Cosmetic suggestions**: "Consider renaming variable X" (if X is in legacy code)

**Example**:
- PR adds a new field to a service
- Copilot flags: "Service class has 500 lines (God Class)"
- **Verdict**: OUT-OF-SCOPE (pre-existing issue, PR doesn't worsen it)

---

### Phase 4: Apply Pertinent Fixes

For each **pertinent** comment:

1. **Read the file** (confirm line number and context)
2. **Apply the fix** (modify code to address the issue)
3. **Test build BEFORE commit**:
   ```bash
   # Frontend example (adapt to project)
   npm run build -- --skip-nx-cache
   
   # Backend example (adapt to project)
   ./gradlew build
   ```
4. **Only commit if build passes**:
   ```bash
   git add <modified-files>
   git commit -m "fix: apply Copilot review corrections (see message body)"
   ```

**If build fails**: Revert the change, document why it failed, and move to next comment.

---

### Phase 5: Document Decisions in Commit Message

Use a structured commit message template:

```
fix: apply [Reviewer] review corrections

Address X out of Y [Reviewer] review comments (scope-relevant issues only):

**[Category] fixes:**
- Fix [issue description] (comment #N in [file:line])
  [One-line implementation detail]
- Fix [issue description] (comment #M in [file:line])
  [One-line implementation detail]

**Skipped (out of scope):**
- Comments #X-Y: [reason - pre-existing/cosmetic/unrelated]
- Comment #Z: [specific reason]

**Verification**: Build passes, tests green.
```

**Example**:

```
fix: apply Copilot review corrections

Address 3 out of 7 Copilot review comments (scope-relevant issues only):

**Data integrity fixes:**
- Fix missing `email` field in UpdateUserMutation response (comment #42 in user.graphql:15)
  Added email to mutation return type
- Fix incorrect type for `createdAt` field (comment #43 in user.dto.ts:8)
  Changed string to Date type

**Test fixes:**
- Fix assertion on wrong object path (comment #44 in user.service.spec.ts:22)
  Changed `result.data.user` to `result.user` (corrected path after API refactor)

**Skipped (out of scope):**
- Comments #45-47: Style/formatting (semicolons, spacing) - already passing ESLint
- Comment #48: i18n key naming convention - not modified by this PR

**Verification**: Build passes (npm run build), tests green (npm test).
```

---

### Phase 6: Repository-Specific Considerations

**Multi-repo projects**: If project has separate frontend/backend repos, comments may reference different codebases. Always verify:
- Frontend PR → apply fixes in frontend repo
- Backend PR → apply fixes in backend repo
- Never mix: backend fixes in frontend or vice versa

**Build commands**: Adapt to project conventions:
- **Node/npm**: `npm run build`, `npm test`
- **Java/Gradle**: `./gradlew build`, `./gradlew test`
- **Python**: `pytest`, `python -m build`
- **Go**: `go build`, `go test ./...`

**Auth patterns**: Check project's `AGENTS.md` for auth env vars:
- Some projects use `GH_TOKEN=$TOKEN`
- Others rely on `gh auth login` global config

---

## When to Process Reviews

### Explicit User Request
- "check copilot reviews"
- "liste les commentaires copilot"
- "apply review suggestions"
- "address copilot feedback"

### Proactive (After Push)
After pushing a PR, offer to check for new automated comments:
> "I've pushed the changes. Would you like me to check for Copilot review comments?"

### User Mentions Feedback
- "there are review comments"
- "copilot flagged some issues"
- "bot left feedback"

---

## Prioritization Rules

### Always Fix (Blocking Issues)
- Data integrity bugs (data loss, type mismatches)
- Logic errors in PR code
- Missing required fields
- Test failures introduced by PR

### Strong Consider (Important but Not Blocking)
- Performance issues in new code
- Security risks (minor, non-critical)
- Clarity improvements in PR code

### Skip (Noise)
- Style/formatting passing linters
- Pre-existing tech debt
- Subjective naming in legacy code
- Architectural suggestions beyond PR scope

---

## Edge Cases

### Comment References File Not in PR
**Scenario**: Copilot flags `services/user.service.ts:42`, but PR only touches `controllers/user.controller.ts`.

**Action**: OUT-OF-SCOPE (file not modified by PR). Skip and document.

---

### Comment is Ambiguous
**Scenario**: Copilot says "Consider refactoring this method" without specific issue.

**Action**: If PR doesn't introduce new issues in that method → OUT-OF-SCOPE. Skip with reason "Ambiguous suggestion for pre-existing code".

---

### Build Fails After Applying Fix
**Scenario**: Applied fix, but `npm run build` fails.

**Action**:
1. Revert the change (`git reset --hard HEAD`)
2. Document in commit message: "Comment #X: attempted fix caused build failure, requires deeper investigation"
3. Move to next comment

---

### Multiple Reviewers (Copilot + Human)
**Scenario**: PR has comments from Copilot AND human reviewers.

**Action**: This skill handles **automated reviewers only** (Copilot, bots, linters). For human reviewer comments, follow project's standard review process.

---

## Examples

### Example 1: Frontend PR (GraphQL Mutation)

**PR**: Add user profile update feature

**Copilot Comments**:
1. (file: `user.graphql:15`) "Mutation missing `email` field in response"
2. (file: `user.dto.ts:8`) "`createdAt` should be Date, not string"
3. (file: `user.service.ts:42`) "Service class has 500 lines (God Class)"
4. (file: `user.component.ts:12`) "Missing semicolon after return statement"

**Analysis**:
- Comment 1: **PERTINENT** (data integrity, PR code)
- Comment 2: **PERTINENT** (type correctness, PR code)
- Comment 3: **OUT-OF-SCOPE** (pre-existing issue, PR doesn't worsen)
- Comment 4: **OUT-OF-SCOPE** (style, ESLint would catch if enforced)

**Action**: Fix comments 1-2, skip 3-4.

**Commit**:
```
fix: apply Copilot review corrections

Address 2 out of 4 Copilot review comments:

**Data integrity fixes:**
- Fix missing email in UpdateUserMutation response (comment #1)
- Fix createdAt type from string to Date (comment #2)

**Skipped:**
- Comment #3: God Class (pre-existing, not worsened by PR)
- Comment #4: Missing semicolon (ESLint passes, cosmetic)

Build passes, tests green.
```

---

### Example 2: Backend PR (Service Method)

**PR**: Add pagination to user list endpoint

**Copilot Comments**:
1. (file: `UserService.java:78`) "Missing null check for pageSize parameter"
2. (file: `UserService.java:120`) "Method getUsers() is 65 lines (Long Method)"
3. (file: `UserRepository.java:15`) "Consider using Optional<User> instead of null"

**Analysis**:
- Comment 1: **PERTINENT** (logic error in new pagination code)
- Comment 2: **OUT-OF-SCOPE** (pre-existing, PR adds 3 lines to method but doesn't worsen structure)
- Comment 3: **OUT-OF-SCOPE** (pre-existing pattern, PR doesn't modify repository)

**Action**: Fix comment 1 only.

**Commit**:
```
fix: apply Copilot review corrections

Address 1 out of 3 Copilot review comments:

**Logic fixes:**
- Add null check for pageSize parameter (comment #1 in UserService.java:78)
  Defaults to 20 if null

**Skipped:**
- Comment #2: Long Method (pre-existing, PR adds 3 lines but doesn't worsen)
- Comment #3: Optional<User> pattern (pre-existing, not touched by PR)

Build passes (./gradlew build), tests green.
```

---

## Notes

- **Language-agnostic**: Works with Java, TypeScript, Python, Go, etc.
- **Framework-agnostic**: Applies to Spring Boot, Angular, Django, Express, etc.
- **Reviewer-agnostic**: Works with Copilot, CodeRabbit, SonarQube, or any bot posting PR comments
- **Adapt build commands**: Use project-specific build/test commands (check `AGENTS.md` or `package.json`/`build.gradle`)

---

## When NOT to Use This Skill

- **Debugging failing tests**: Use `systematic-debugging` skill instead
- **Explaining review concepts**: User wants to learn about code review, not process comments
- **Human reviewer comments**: Follow project's standard review workflow (not automated processing)
- **Creating TESTING.md documentation**: Use `unit-test-writer` or documentation skills
