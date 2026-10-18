# Changelog — Skill Creator

All notable changes to this skill will be documented here.

---

## [2.1.0] - 2026-04-03

### Added
- **Eval isolation rules** — subagents must write only to their designated `outputs/` directory; any file created elsewhere must be deleted before the run ends; undeletable files documented in `outputs/user_notes.md` for orchestrator cleanup
- **Step 6: Cleanup** — orchestrator deletes all eval artifacts automatically after feedback is read: workspace directory, `/tmp` static viewers, `~/Downloads/eval_set.json`, `~/Downloads/feedback.json`, and any orphaned files flagged by subagents

---

## [2.0.0] - 2026-04-03

### Changed
- **Understand the Problem** — Merged `Capture Intent` and `Interview and Research` into a single phase anchored on two foundational questions (what problem, how will we know it's solved); external research guidance integrated
- **Write the SKILL.md** — Replaced placeholder line with guidance: skill body must express intent and reasoning behind each part, not just steps; sections must be justifiable before being organized
- **Skill Writing Guide** — Added principle that structure serves content: write substance first, organize second; sections without clear purpose should be removed
- **Step 2: assertions** — Added distinction between conformance assertions (skill followed instructions) and impact assertions (output achieved the goal); impact assertions prioritized
- **How to think about improvements** — Added point 5: challenge the intent before rewriting when multiple iterations produce no meaningful progress
- **Branding** — Replaced all 6 remaining occurrences of "Claude" with "OpenCode"

---

## [1.2.0] - 2026-04-02

### Changed
- **Description** — Rewritten to intention-based style; explicit trigger keyword list removed (all skills updated in v2.11.2)
- **Bundled Resources Guidelines** — New rule added: descriptions must be intent/context-based, not keyword lists; short "pushy" closing example acceptable for implicit/ambiguous cases
- **eval-viewer/viewer.html** — Replaced 2 occurrences of "Claude Code" with "OpenCode"

---

## [1.1.0] - 2026-04-02

### Changed
- **Step 1 (runs)** — Replaced native Claude Code subagents with `Task(subagent_type="general")` (environment adaptation)
- **Step 4 (viewer)** — Replaced `nohup` server with `generate_review.py --static` (standalone HTML, no server required)
- **Step 3 (description optimization)** — Replaced `run_loop.py` automated loop with manual procedure (`claude` CLI unavailable)
- **Scripts** — Removed 7 scripts depending on `claude` CLI (`run_loop.py`, `run_eval.py`, `improve_description.py`, `generate_report.py`, `quick_validate.py`, `utils.py`, `aggregate_benchmark.py`); kept `package_skill.py` only
- **Bundled Resources Guidelines** — Added 6 rules (R1–R6) covering scripts, examples, references, config.yaml, behavioral defaults, and active-only content

---

## [1.0.0] - 2026-03-18

### Added
- Initial version: official Anthropic skill-creator adapted for OpenCode environment
- Skill creation workflow: capture intent → interview → write SKILL.md → evaluate → iterate
- Skill writing guide with anatomy, progressive disclosure, bundled resources guidelines
- Eval runner: `Task(subagent_type="general")` for with_skill / without_skill runs
- Static HTML viewer via `generate_review.py --static`
