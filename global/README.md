# global/

The agent's rules for every project. Left alone, an agent can push, merge or comment on GitHub on
its own, rebase a shared branch or commit to `main`. This module makes those actions wait for your
explicit go-ahead, and adds generic skills for reviews and pull requests.

What it brings:

- **Nothing reaches GitHub without you.** No push, merge, review or issue without your explicit
  go-ahead; work happens on feature branches, merged rather than rebased.
- **Reviews and PRs with a method.** A two-level code review, a triage of bot comments, PR
  descriptions from a fixed template.
- **Rules that improve.** When you correct the agent, it proposes a change to its own rules and logs
  it.

## Install

Let an agent follow [INSTALL.md](../INSTALL.md) (module `global`), or copy the content of this
folder into `~/.config/opencode/`.

Prerequisites:

- [OpenCode](https://opencode.ai).
- The [Superpowers](https://github.com/obra/superpowers) plugin. `AGENTS.md` and some skills rely on its process skills (`brainstorming`, `writing-plans`, `systematic-debugging`, …). Its `brainstorming` and `writing-plans` skills write drafts to `docs/superpowers/`, which is why `AGENTS.md` keeps that folder out of every project's history.

## What is inside

| Path | Goes to | What it is |
|---|---|---|
| `AGENTS.md` | `~/.config/opencode/AGENTS.md` | Global rules: workflow artefacts, skill banner, GitHub write safety, git commit/push/merge policy, review-thread resolution, proactive self-improvement |
| `skills/code-review-standards/` | `~/.config/opencode/skills/` | Generic two-level code review (merge readiness vs technical debt) |
| `skills/copilot-review-processor/` | `~/.config/opencode/skills/` | Triage of bot review comments (Copilot, CodeRabbit, Sonar…) |
| `skills/pr-message/` | `~/.config/opencode/skills/` | PR description from a fixed template, refreshed after every push |
| `skills/skill-creator/` | `~/.config/opencode/skills/` | Create and evaluate skills (adapted from Anthropic's skill-creator, Apache-2.0). Its sub-folders serve the eval loop and are referenced from its `SKILL.md`: `agents/` grader, comparator and analyzer prompts; `eval-viewer/` and `assets/` the HTML review pages; `references/` the JSON schemas; `scripts/` the packaging script; `evals/` the skill's own test prompts |
| `skills/unit-test-writer/` | `~/.config/opencode/skills/` | Write tests after loading the project's `TESTING.md` / `rules/` conventions |

`AGENTS.md` mentions `~/.config/opencode/SELF_IMPROVEMENT_LOG.md`: it is created on first use.

Project-level rules (architecture, test-first workflow, spec-kit) are in [`../repo/`](../repo/).
Personal habits (notifications, CLI wrappers) are in [`../personal/`](../personal/).
