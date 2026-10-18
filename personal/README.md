# personal/

Optional, personal habits. Nothing in `global/` or `repo/` depends on them.
Most of it is macOS-specific.

| Path | How to install | What it does |
|---|---|---|
| `AGENTS.personal.md` | Append to `~/.config/opencode/AGENTS.md` | `rtk` output-filtering rules, macOS notifications at the end of each response and on every `question` |
| `plugins/notify.ts` | Copy to `~/.config/opencode/plugins/` | Notifies when OpenCode stops for a reason the agent cannot report itself (permission prompt, error, interruption) |

Requirements: macOS (`osascript`) for notifications; `rtk` installed if you keep the RTK section.

Auth pattern: if a project needs a dedicated GitHub token, prefix commands with it
(`GH_TOKEN=$TOKEN gh api ...`, or `GH_TOKEN=$TOKEN rtk proxy gh api ...`).
Keep the token in your shell profile, never in a repository.
