import type { Plugin } from "@opencode-ai/plugin"

// Sends a macOS notification whenever OpenCode stops for a reason the agent
// cannot report itself: permission prompts (the agent is blocked mid-tool-call)
// and session errors / interruptions.
// End-of-response and `question` notifications are sent by the agent itself
// (see personal/AGENTS.personal.md).

const esc = (s: string) => s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').slice(0, 80)

export default (async ({ $ }) => {
  const notify = async (message: string, subtitle: string) => {
    const script = `display notification "${esc(message)}" with title "OpenCode" subtitle "${esc(subtitle)}"`
    try {
      await $`osascript -e ${script}`.quiet()
    } catch {
      // never break the session because of a notification
    }
  }

  const seen = new Set<string>()

  return {
    event: async ({ event }) => {
      const e = event as { type: string; properties?: any }
      const p = e.properties ?? {}

      if (e.type === "permission.asked" || e.type === "permission.updated") {
        const id: string | undefined = p.id
        if (id) {
          if (seen.has(id)) return
          seen.add(id)
        }
        const kind: string = p.permission ?? p.type ?? "permission"
        const target: string = Array.isArray(p.patterns)
          ? p.patterns.join(", ")
          : Array.isArray(p.pattern)
            ? p.pattern.join(", ")
            : (p.pattern ?? p.title ?? "")
        await notify("Permission required", target ? `${kind}: ${target}` : kind)
        return
      }

      if (e.type === "session.error") {
        const name: string = p.error?.name ?? "Error"
        if (name === "MessageAbortedError") {
          await notify("Session interrupted", "Stop requested")
        } else {
          await notify("Session stopped on an error", name)
        }
      }
    },
  }
}) satisfies Plugin
