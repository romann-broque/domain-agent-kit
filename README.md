# agentic-setup

A catalogue of modules for [OpenCode](https://opencode.ai), the AI coding agent, to start a
project from scratch or bring discipline to an existing one:

- **A clean-architecture starter-kit**: a Java 21 / Spring Boot service, one package per bounded
  context, four layers inside each, and tests that fail the build when the layout drifts.
  It compiles, its tests pass, and it is ready to receive your first feature.
- **An agentic workflow** that takes a ticket to merged code: the ticket is challenged, specified,
  tested first, implemented, verified and reviewed, one step at a time, the agent stopping after
  each one.
- **A living domain documentation.** The workflow writes the domain knowledge down in
  `docs/domain/` (vocabulary, bounded contexts, rules) and keeps confronting it with the tickets and
  the code, so the three stay consistent instead of drifting apart.

Every module can be taken alone. In particular the workflow can be added to a project that already
exists, with or without the starter-kit.

## The fastest way: let an agent install it

Clone this repository, open your agent in the project you want to equip, and give it this prompt:

> Read `<path to agentic-setup>/README.md`, including the section "Installation — instructions for an
> agent". Explain to me in a few lines what each module does, ask me which ones I want, then
> install them into this project by following those instructions, and show me the result of each
> check.

The rest of this file explains what you are installing, then gives the agent its instructions.

## The modules

| Folder | What it gives you | Installed into |
|---|---|---|
| [`starter-kit/`](starter-kit/README.md) | A clean-architecture Spring Boot project, ready to start a product from scratch | a new folder |
| [`repo/`](repo/README.md) | The agentic workflow and the domain documentation for one project | the root of a project, new or existing |
| [`global/`](global/README.md) | Safety rules and generic skills the agent applies in every project | `~/.config/opencode/` |
| [`personal/`](personal/README.md) | Optional comfort: a macOS notification when the agent stops, shorter command output | `~/.config/opencode/` |

### starter-kit/: clean architecture, ready to embark

- **One top-level package per bounded context** (`catalog`, `ordering`), so the code says what the
  business does before it says which framework it uses.
- **Four layers inside each context**: `domain` (models and rules, no framework), `application` (use
  cases and ports), `infrastructure` (database, other contexts), `presentation` (HTTP).
- **Contexts talk only through an anti-corruption layer**, the single class allowed to reach into
  another context.
- **Three kinds of tests**: ArchUnit rules on layers, naming and isolation; one Cucumber feature per
  use case, written from the spec; one creation test per domain model.
- **Locked supply chain**: every dependency version is locked and every artifact checksum verified.

The two example contexts show every convention once; you replace them with your own.

### repo/: the agentic workflow and its domain documentation

Every ticket goes through the same chain. Each step ends with a card listing what the agent
**decided**, **assumed** and is **unsure of**; nothing moves on until you type the next step.

| Folder | What it is for | Where it goes |
|---|---|---|
| [`global/`](global/README.md) | Rules and skills the agent follows in **every** project: never push without asking, never write on GitHub, review a PR, write a PR description, write tests | `~/.config/opencode/` |
| [`personal/`](personal/README.md) | Optional habits: a macOS notification each time the agent stops, `rtk` to shorten command output | `~/.config/opencode/` |
| [`repo/`](repo/README.md) | A workflow for **one** project: a ticket becomes a spec, then tests, then code, and scripts check that nothing was lost on the way | the root of a project |
| [`starter-kit/`](starter-kit/README.md) | An empty Java 21 / Spring Boot service already laid out for that workflow, with two tiny example features and tests that keep the layout honest | a new folder |

`global/` and `personal/` change how the agent behaves. `repo/` and `starter-kit/` change a project.

## Install what you need

Run the commands from a clone of this repository.

### The agent's global rules

Requires the [Superpowers](https://github.com/obra/superpowers) plugin, which `global/` builds on.

```bash
mkdir -p ~/.config/opencode
cp global/AGENTS.md ~/.config/opencode/AGENTS.md      # overwrites an existing file: merge by hand if you have one
cp -R global/skills ~/.config/opencode/
```
ticket ──▶ domain-challenge ──▶ spec ──▶ plan ──▶ tasks ──▶ verify ──▶ test (RED) ──▶ code (GREEN) ──▶ verify + review ──▶ PR
              │        ▲                                                                                                │
              ▼        │                                                                                                ▼
         domain-ingest ─┘  writes docs/domain/                                                           review-triage routes each
         ticket-writer     splits a ticket too large                                                     comment back to its step
```

How it keeps tickets, documentation and code consistent:

| Confrontation | Who does it |
|---|---|
| Ticket ↔ domain documentation: does the ticket use known words, respect known rules, fit one context? | `domain-challenge` |
| New knowledge ↔ documentation and code: is it consistent, sourced, not already written, and does the running code agree? | `domain-ingest` |
| Ticket ↔ spec ↔ tasks: did every requirement and scenario reach a task? | `/workflow.verify` (`verify-traceability.sh`) |
| Tasks ↔ commits: was each test committed and seen failing before its code? | `/workflow.verify` (`verify-implementation.sh`) |
| Spec ↔ code: does the code do what was specified, and only that? | `code-reviewer`, `/speckit.converge` |
| Review comments ↔ workflow: is a comment a refactor, a bug, a spec change or a domain change? | `review-triage` (`verify-review-commits.sh`) |
| Documentation ↔ itself: are references, statuses and open points intact? | `verify-domain-base.sh` |

The checks are shell scripts: they say "drift", "OK" or "could not check", never a silent pass.

**Skills** (in `repo/.opencode/skills/`, used by the agent when the step comes):

| Skill | What it does |
|---|---|
| `domain-challenge` | First step of every ticket. Confronts it with `docs/domain/` and answers READY, NEEDS ANSWERS (blocking questions), DOMAIN GAP (the documentation does not know enough) or TOO LARGE. |
| `domain-ingest` | Brings domain knowledge into `docs/domain/`: a modelling session, a new context, a term, a rule, a correction. Challenges it first (contradictions, missing sources, duplicates), writes only what lasts beyond one feature, and lists what it set aside. Usually runs after a DOMAIN GAP. |
| `ticket-writer` | Writes tickets in a standard format and splits a ticket that is too large into independent ones. |
| `test-first` | Writes the failing test before any production code: a Cucumber scenario per use case, a creation test per model. Stops at RED. |
| `craftsman` | Writes the minimum code that turns the failing test green, following the clean-architecture conventions. |
| `code-reviewer` | Reviews the green code against the constitution and `AGENTS.md` before commit or PR. |
| `review-triage` | Classifies each human review comment and routes it back to the right step instead of patching code directly. |

**Commands** (in `repo/.opencode/commands/`, typed by you):

| Command | What it does |
|---|---|
| `/speckit.constitution` | Writes the project's constitution, once |
| `/speckit.specify`, `/speckit.clarify` | Turn the ticket, pasted verbatim, into user stories and acceptance scenarios; encode the answers to open questions |
| `/speckit.plan`, `/speckit.checklist` | Design the change and check the spec's quality |
| `/speckit.tasks`, `/speckit.analyze` | Split the plan into tasks, tests first, with a gate where the failing test must be pasted |
| `/speckit.taskstoissues` | Create one tracker issue per task, only on request |
| `/speckit.implement` | Run the tasks through `test-first` then `craftsman` |
| `/workflow.verify` | Run the mechanical checks above |
| `/speckit.converge` | Compare the code with the spec, plan and tasks, and add what is still missing as new tasks |

Also in `repo/`: `AGENTS.md` (the project rules the agent reads first), the constitution
(`.specify/memory/constitution.md`), the `docs/domain/` skeleton, a commit-message hook and a PR
template. [repo/docs/WORKFLOW.md](repo/docs/WORKFLOW.md) details every step.

### global/: rules and skills for every project

`AGENTS.md`: the agent never pushes, merges or writes on GitHub without your explicit go-ahead,
works on feature branches, merges rather than rebases, and proposes improvements to its own rules.
It relies on the [Superpowers](https://github.com/obra/superpowers) plugin.

| Skill | What it does |
|---|---|
| `code-review-standards` | Reviews any PR in two levels: what blocks the merge, and the technical debt it reveals |
| `copilot-review-processor` | Sorts bot review comments (Copilot, CodeRabbit, Sonar…) into fixes to apply and noise |
| `pr-message` | Writes the PR description from a fixed template and refreshes it after each push |
| `unit-test-writer` | Writes tests after loading the project's own testing conventions |
| `skill-creator` | Creates and evaluates new skills |

### personal/: optional, macOS

A notification each time the agent finishes, asks a question or waits for a permission, and
rules for `rtk`, a tool that shortens command output to save tokens.

---

## Installation — instructions for an agent

You are installing modules of this catalogue for a user. Follow these rules:

- `AGENTS_SETUP` below means the absolute path of this repository, `PROJECT` the project to equip.
- Ask the user which modules they want before copying anything. Never overwrite a file that already
  exists without showing the difference and getting approval: merge instead.
- Do not commit or push in `PROJECT` unless the user asks.
- After each module, run its check and show the output. Stop and report if a check fails.

### Module `global`

1. Check that OpenCode and the Superpowers plugin are installed; if not, tell the user and stop.
2. If `~/.config/opencode/AGENTS.md` exists, merge `AGENTS_SETUP/global/AGENTS.md` into it section by
   section and show the result; otherwise copy it.
3. Copy each folder of `AGENTS_SETUP/global/skills/` into `~/.config/opencode/skills/`, asking before
   replacing a skill of the same name.
4. Check: `ls ~/.config/opencode/skills/` lists the five skills.

### Module `personal` (macOS only, optional)

1. Append `AGENTS_SETUP/personal/AGENTS.personal.md` to `~/.config/opencode/AGENTS.md`. Ask whether
   the user has `rtk`; if not, leave out its section.
2. Copy `AGENTS_SETUP/personal/plugins/notify.ts` into `~/.config/opencode/plugins/`.
3. Check: `osascript -e 'display notification "test" with title "OpenCode"'` shows a notification.

### Module `starter-kit` (new project)

1. `PROJECT` must not exist or be empty.
2. `rsync -a --exclude /README.md --exclude /build --exclude /.gradle AGENTS_SETUP/starter-kit/ PROJECT/`
3. `cd PROJECT && git init && git config core.hooksPath .githooks`
4. Check: `./gradlew build` ends with `BUILD SUCCESSFUL` (it needs Java 21).
5. Install the module `repo` on top, then write a short `README.md` for the user's project.
   `AGENTS_SETUP/starter-kit/README.md` explains the layout and how to replace the example contexts.

### Module `repo` (new or existing project)

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

## Credits

- [spec-kit](https://github.com/github/spec-kit) (MIT): the `speckit.*` commands, templates and scripts derive from it.
- `skill-creator` is adapted from Anthropic's skill-creator (Apache-2.0).
- Fixtures are generated by [java-fixture-generator](https://github.com/romann-broque/java-fixture-generator)
  (Apache-2.0), used as a Maven Central dependency.

Details in [NOTICE](NOTICE). Licensed under MIT, see [LICENSE](LICENSE).
