# personal/

Optional comfort, mostly for macOS. While the agent works you look elsewhere, and you miss the
moment it stops to wait for you; its command output also fills its context with noise. Nothing in
`global/` or `repo/` depends on this module.

What it brings:

- **You know when the agent waits for you.** A macOS notification when it finishes, asks a question,
  waits for a permission or hits an error.
- **Shorter command output.** Rules for `rtk`, a tool that filters verbose command output to save
  tokens.

## Install

Let an agent follow [INSTALL.md](../INSTALL.md) (module `personal`), or install by hand:

| Path | How to install | What it does |
|---|---|---|
| `AGENTS.personal.md` | Append to `~/.config/opencode/AGENTS.md` | `rtk` output-filtering rules, macOS notifications at the end of each response and on every `question` |
| `plugins/notify.ts` | Copy to `~/.config/opencode/plugins/` | Notifies when OpenCode stops for a reason the agent cannot report itself (permission prompt, error, interruption) |

Requirements: macOS (`osascript`) for notifications; `rtk` installed if you keep the RTK section.

Auth pattern: if a project needs a dedicated GitHub token, prefix commands with it
(`GH_TOKEN=$TOKEN gh api ...`, or `GH_TOKEN=$TOKEN rtk proxy gh api ...`).
Keep the token in your shell profile, never in a repository.
