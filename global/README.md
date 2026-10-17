# global/

Configuration that applies to every project. Copy it into `~/.config/opencode/`.

| Path | Goes to | What it is |
|---|---|---|
| `AGENTS.md` | `~/.config/opencode/AGENTS.md` | Global rules: workflow artefacts, skill banner, GitHub write safety, git commit/push/merge policy, review-thread resolution, proactive self-improvement |
| `agents/deps-harden*.md` | `~/.config/opencode/agents/` | Supply-chain hardening subagents: one orchestrator (`deps-harden`) dispatching one agent per ecosystem (npm, pnpm, bun, uv, poetry, gradle, nuget, workflows, dependabot) |
| `skills/code-review-standards/` | `~/.config/opencode/skills/` | Generic two-level code review (merge readiness vs technical debt) |
| `skills/copilot-review-processor/` | `~/.config/opencode/skills/` | Triage of bot review comments (Copilot, CodeRabbit, Sonar…) |
| `skills/pr-message/` | `~/.config/opencode/skills/` | PR description from a fixed template, refreshed after every push |
| `skills/skill-creator/` | `~/.config/opencode/skills/` | Create and evaluate skills (adapted from Anthropic's skill-creator, Apache-2.0) |
| `skills/unit-test-writer/` | `~/.config/opencode/skills/` | Write tests after loading the project's `TESTING.md` / `rules/` conventions |

`AGENTS.md` mentions `~/.config/opencode/SELF_IMPROVEMENT_LOG.md`: it is created on first use.

Project-level rules (architecture, test-first workflow, spec-kit) are in [`../repo/`](../repo/).
Personal habits (notifications, CLI wrappers) are in [`../personal/`](../personal/).
