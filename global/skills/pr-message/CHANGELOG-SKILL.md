# Changelog - pr-message skill

All notable changes to the `pr-message` skill will be documented in this file.

## [1.0.1] - 2026-05-21

### Added
- **Token optimization section** to prevent unnecessary searches:
  - Explicit guidance: do NOT explore codebase or search for ticket references
  - Data sources clearly defined: git diff, git log, gh pr view, user input
  - Principle: "packaging existing information", not researching
- **Commands section**:
  - Use `gh` for GitHub operations (complete data)
  - Use direct `git` commands for diffs (already concise)

### Changed
- Skill now emphasizes minimal token usage by design

## [1.0.0] - 2026-05-21

### Added
- Initial creation of the `pr-message` skill
- Standard PR template enforcement with 5 sections:
  - 📋 Ticket (ID, title, description, issue link)
  - 📝 Changes (high-level code changes summary)
  - 🔄 Type of Change (checkboxes for bug/feature/breaking/refactor/docs/CI)
  - ⚠️ Reviewer Notes (special attention items)
  - 📦 Impacted Dependencies (added/updated/removed packages)
- Two-phase workflow:
  - **First PR creation**: Explicit user confirmation for ticket ID, title, and description
  - **Subsequent commits**: Automatic PR body updates from cumulative branch diff
- Strict "ask, never improvise" policy — no invented facts, placeholders for missing data
- Ticket section freeze policy — ticket identity preserved for PR lifetime
- Dependency detection from lockfiles (package.json, pyproject.toml, go.mod, Cargo.toml)

### Integration
- Added to AGENTS.md "Skill Selection Rules" section as mandatory for all PR message operations
- Replaces manual PR description template in "PR Description Update Policy" section
- Triggers on: PR creation, PR body drafting, commits to PR branches, phrases like "PR message", "PR description", "update the PR"

### Rules enforced
- All sections required (use "None." if empty)
- English only, regardless of conversation language
- Factual descriptions only — no marketing tone
- High-level changes, not line-by-line details
- Ticket description captures the *why* (goal, problem, business context)
- Changes section captures the *what* (code modifications only)
