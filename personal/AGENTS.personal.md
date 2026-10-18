## RTK (Runtime Toolkit) Usage

`rtk` is installed and should be used strategically to **save tokens** by filtering verbose command outputs.

### Authentication

**RTK inherits shell environment**:
- If project requires specific auth env vars (e.g., `GH_TOKEN=$TOKEN`), prefix your command:
  ```bash
  GH_TOKEN=$TOKEN rtk proxy gh api ...
  ```
- If `gh` is authenticated globally (`gh auth login`), `rtk` will inherit auth automatically
- For project-specific auth patterns, check project's `AGENTS.md` or `.env` configuration

### When to use `rtk` (filtered output)

Use `rtk` for commands where **human-readable filtered output** is sufficient:

```bash
# Git operations (human-readable status)
rtk git status
rtk git log
rtk git branch

# GitHub read operations (formatted output)
rtk gh pr list
rtk gh pr checks <pr>
rtk gh issue list

# Package managers (cleaner output)
rtk npm install
rtk npm test
```

**Benefit**: Reduced token usage, cleaner output for the model.

**Token savings (typical examples)**:
- `gh pr diff` raw: ~12,000-20,000 tokens → `rtk gh pr diff` filtered: ~2,500-4,000 tokens (75-80% reduction)
- `gh pr checks` raw: ~1,500 tokens → `rtk gh pr checks` filtered: ~300 tokens (80% reduction)
- `npm test` raw: ~8,000 tokens → `rtk npm test` filtered: ~1,200 tokens (85% reduction)

**When to prioritize full output** (`rtk proxy`):
- PR reviews requiring complete diff analysis
- API responses where structure matters (GraphQL, REST)
- Debugging scenarios needing exact error messages

### When to use `rtk proxy` (full output)

Use `rtk proxy` for commands where **complete unfiltered data** is critical:

```bash
# PR reviews (need full diff)
rtk proxy gh pr diff <pr-number> --repo <repo>
rtk proxy gh pr view <pr-number> --repo <repo> --json files,title,body

# API calls (need complete JSON)
rtk proxy gh api repos/<owner>/<repo>/pulls/<pr>/comments/<comment_id>/replies
rtk proxy gh api graphql -f query='...'

# File content (need exact output)
rtk proxy cat file.txt
```

**Critical**: Never use plain `rtk gh pr diff` or `rtk gh pr view` — always use `rtk proxy` to avoid truncation.

### ❌ Common Mistakes to Avoid

**Truncation errors** (most frequent):
```bash
# ❌ WRONG - Will truncate PR diff
rtk gh pr diff 123

# ✅ CORRECT - Full diff preserved
rtk proxy gh pr diff 123
```

**API response loss**:
```bash
# ❌ WRONG - Incomplete JSON structure
rtk gh api graphql -f query='{ repository { ... } }'

# ✅ CORRECT - Complete API response
rtk proxy gh api graphql -f query='{ repository { ... } }'
```

**Unnecessary filtering**:
```bash
# ❌ WRONG - Local operations don't need RTK
rtk git diff HEAD~1

# ✅ CORRECT - Direct command for local content
git diff HEAD~1
```

### When to avoid `rtk` entirely

Use standard commands directly when:
- Writing files or making changes (git commit, git push)
- Interactive commands (git rebase -i)
- Commands that require exact formatting (scripts, CI/CD)

```bash
# Direct commands (no rtk)
git add .
git commit -m "message"
git push
```

### Decision Tree

```
Need command output?
├─ No (just execute) → Direct command
└─ Yes
   ├─ Need full unfiltered output? → rtk proxy <command>
   ├─ Want filtered human-readable? → rtk <command>
   └─ Critical for scripts/CI? → Direct command
```

### Quick Reference

| Command | Use RTK? | Reason |
|---------|----------|--------|
| `gh pr diff` | `rtk proxy` | Need full diff, no truncation |
| `gh pr view --json` | `rtk proxy` | Complete JSON required |
| `gh pr list` | `rtk` | Summary sufficient |
| `gh pr checks` | `rtk` | Formatted status OK |
| `gh api graphql` | `rtk proxy` | Complete API response needed |
| `gh issue list` | `rtk` | Summary sufficient |
| `git status` | `rtk` | Human-readable summary |
| `git log` | `rtk` | Formatted summary |
| `git log --patch` | Direct | Need full patch content |
| `git diff` (local) | Direct | Local file content |
| `git commit` | Direct | Write operation |
| `git push` | Direct | Write operation |
| `npm install` | `rtk` | Cleaner output |
| `npm test` | `rtk` | Summary sufficient |
| `npm test -- --verbose` | Direct | Full logs for debugging |
| `./gradlew build` | `rtk` | Summary sufficient |
| `./gradlew test --info` | Direct | Need detailed logs |

### Edge Cases

**Local git operations** (no remote interaction):
- `git diff` → Direct (no RTK needed for local file diffs)
- `git log --oneline` → `rtk git log` (summary sufficient)
- `git log --patch` → Direct (need full patch content)
- `git show <commit>` → Direct (need complete commit details)

**Test output variations**:
- `npm test` → `rtk npm test` (summary sufficient)
- `npm test -- --verbose` → Direct (debugging requires full logs)
- `npm run test:coverage` → `rtk` (coverage summary OK)
- `npm run test:debug` → Direct (need full debug output)

**GitHub CLI with custom formatting**:
- `gh pr view --json <fields>` → `rtk proxy` (complete JSON required)
- `gh pr view --web` → Direct (browser action, no output)
- `gh pr checks --watch` → Direct (interactive, real-time updates)

**Build tools**:
- `./gradlew build` → `rtk` (summary sufficient)
- `./gradlew build --stacktrace` → Direct (need full stacktrace)
- `mvn clean install` → `rtk` (summary sufficient)
- `mvn clean install -X` → Direct (need debug logs)

---

## Task Completion Notification

At the end of EVERY response (including simple questions, explanations, and conversations), ALWAYS send a macOS notification using the following bash command:

```bash
osascript -e 'display notification "Task done" with title "OpenCode" subtitle "<short task name>"'
```

Rules:
- `<short task name>` must be a concise label (3-6 words max) describing what was just done, in the same language as the user's request
- This notification must be the **very last tool call** of the entire response, sent AFTER all text has been written and all other tools have completed
- NEVER send this notification in parallel with other tools — it must be sent alone, in its own separate tool call step
- No exceptions — every response ends with this notification

## User Interaction Notification

Whenever you use the `question` tool to ask the user something, ALWAYS send a macOS notification simultaneously to alert them:

```bash
osascript -e 'display notification "Waiting for your reply" with title "OpenCode" subtitle "<question summary>"'
```

Rules:
- `<question summary>` must be an ultra-short summary of the question asked (3-5 words max), in the same language as the user's request
- Send this notification at the same time as the `question` tool call (in parallel, same message)

## Stop / Permission Notification (plugin)

General rule: the user must be notified **every time the agent stops**, for any reason (end of response, question, permission request, error, interruption).

Coverage:
- End of response → agent sends it (see "Task Completion Notification")
- `question` tool → agent sends it (see "User Interaction Notification")
- Permission prompts (read/write/external_directory/bash…), errors and interruptions → handled automatically by the global plugin `~/.config/opencode/plugins/notify.ts` (events `permission.asked`, `session.error`). The agent cannot send these itself because it is blocked mid-tool-call.

Rules:
- Do NOT remove or bypass this plugin
- If the agent stops for any other reason not covered above (e.g. waiting for push confirmation, blocked, needs input in plain text), it MUST still send the end-of-response notification
