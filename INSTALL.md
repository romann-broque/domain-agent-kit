# Installation — instructions for an agent

You are installing modules of [domain-agent-kit](README.md) for a user. Follow these rules:

- `AGENTS_SETUP` below means the absolute path of this repository, `PROJECT` the project to equip.
- Ask the user which modules they want before copying anything. Never overwrite a file that already
  exists without showing the difference and getting approval: merge instead.
- Do not commit or push in `PROJECT` unless the user asks.
- After each module, run its check and show the output. Stop and report if a check fails.

## Module `global`

1. Check that OpenCode and the Superpowers plugin are installed; if not, tell the user and stop.
2. If `~/.config/opencode/AGENTS.md` exists, merge `AGENTS_SETUP/global/AGENTS.md` into it section by
   section and show the result; otherwise copy it.
3. Copy each folder of `AGENTS_SETUP/global/skills/` into `~/.config/opencode/skills/`, asking before
   replacing a skill of the same name.
4. Check: `ls ~/.config/opencode/skills/` lists the five skills.

## Module `personal` (macOS only, optional)

1. Append `AGENTS_SETUP/personal/AGENTS.personal.md` to `~/.config/opencode/AGENTS.md`. Ask whether
   the user has `rtk`; if not, leave out its section.
2. Copy `AGENTS_SETUP/personal/plugins/notify.ts` into `~/.config/opencode/plugins/`.
3. Check: `osascript -e 'display notification "test" with title "OpenCode"'` shows a notification.

## Module `starter-kit` (new project)

1. `PROJECT` must not exist or be empty.
2. `rsync -a --exclude /README.md --exclude /build --exclude /.gradle AGENTS_SETUP/starter-kit/ PROJECT/`
3. `cd PROJECT && git init && git config core.hooksPath .githooks`
4. Check: `./gradlew build` ends with `BUILD SUCCESSFUL` (it needs Java 21).
5. Install the module `repo` on top, then write a short `README.md` for the user's project.
   `AGENTS_SETUP/starter-kit/README.md` explains the layout and how to replace the example contexts.

## Module `repo` (new or existing project)

1. `PROJECT` must be a git repository. List any of `AGENTS.md`, `.opencode/`, `.specify/`,
   `docs/domain/`, `.githooks/`, `.github/pull_request_template.md` that already exist: these
   need a merge, not a copy. Agree with the user how to merge each one.
2. `rsync -a --exclude /README.md --exclude /.gitignore.snippet AGENTS_SETUP/repo/ PROJECT/`
   (add `--ignore-existing` if the user chose to merge existing files by hand).
3. `cat AGENTS_SETUP/repo/.gitignore.snippet >> PROJECT/.gitignore`
4. `git -C PROJECT config core.hooksPath .githooks`, unless the project already uses another hook
   directory: then copy `.githooks/commit-msg` into it.
5. Adapt to the project: in `AGENTS.md` and `.specify/memory/constitution.md`, replace the base
   package `com.example.starter`, the example contexts `catalog` / `ordering` and the ticket key
   `PROJ-123` with the project's own; ask the user for each value. The rules are written for Java /
   Spring Boot: on another stack, list the sections that do not apply and agree the rewrite with the
   user. [repo/README.md](repo/README.md) lists what to adapt.
6. If production and test code are not under `src/main/` and `src/test/`, tell the user to export
   `SPECIFY_MAIN_RE` and `SPECIFY_TEST_RE` (extended regular expressions matching each path) so the
   verification scripts recognise them; otherwise they answer "could not check".
7. Check: `bash .specify/scripts/bash/verify-domain-base.sh` reports no finding.
8. Tell the user the next step: give the first ticket to the `domain-challenge` skill; on an existing
   project with no domain documentation yet, start with `domain-ingest`, feeding it what the team
   knows of the domain: it compares that knowledge with the existing code before writing it.
