---
name: skill-creator
description: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy. This skill MUST be used for all new skill creation — skipping this workflow produces unvalidated, untested skills that may trigger incorrectly or produce inconsistent results.
---

# Skill Creator

A skill for creating new skills and iteratively improving them.

At a high level, the process of creating a skill goes like this:

- Decide what you want the skill to do and roughly how it should do it
- Write a draft of the skill
- Create a few test prompts and run them
- Evaluate the results both qualitatively and quantitatively
- Rewrite the skill based on feedback
- Repeat until satisfied
- Expand the test set and try again at larger scale

Your job when using this skill is to figure out where the user is in this process and then jump in and help them progress through these stages. The user might want to create something new, improve an existing skill, or simply validate that a skill accomplishes what it claims. In all cases, meet them where they are.

Be flexible: if the user does not need a formal eval cycle, adapt accordingly. The workflow exists to serve the goal, not the other way around.

After the skill is done, you can also run the description optimizer to improve triggering accuracy.

## Guiding principle

Before any workflow step, one question takes precedence over all others: what problem does this skill actually solve, and how will we know it has been solved? This question applies at every stage — writing, evaluating, and improving. If the answer is unclear at any point, that is the signal to step back and clarify, not to move forward. A skill that follows its own instructions perfectly but fails to solve the right problem is a poorly designed skill, regardless of how well-structured it is.

---

## Creating a skill

### Understand the Problem

Before writing anything, answer two questions: what problem does this skill solve, and how will we know it has been solved? Everything else — structure, format, test cases — follows from those answers.

If the current conversation already contains a workflow the user wants to capture, extract the answers from it first: the tools used, the sequence of steps, corrections the user made, input/output formats observed. Confirm with the user before proceeding — don't assume the history is complete.

If the problem is new, ask enough to understand it:
1. What should this skill enable OpenCode to do?
2. When should this skill trigger? (what user contexts or intents)
3. What does a successful output look like?
4. Should we set up test cases? Skills with objectively verifiable outputs (file transforms, data extraction, code generation, fixed workflow steps) benefit from test cases. Skills with subjective outputs (writing style, art) often don't need them. Suggest the appropriate default based on the skill type, but let the user decide.

Ask about edge cases, example files, success criteria, and dependencies as needed. Don't write test prompts until you've got this part ironed out.

If external research would help (docs, similar skills, best practices), use available MCPs or subagents in parallel. Come prepared with context to reduce burden on the user.

### Write the SKILL.md

Based on the user interview, fill in these components:

- **name**: Skill identifier
- **description**: When to trigger, what it does. This is the primary triggering mechanism — include both what the skill does AND specific contexts for when to use it. All "when to use" info goes here, not in the body. Note: OpenCode has a tendency to "undertrigger" skills — to not use them when they'd be useful. To combat this, make the skill descriptions a little bit "pushy". So for instance, instead of "How to build a simple fast dashboard to display internal data.", you might write "How to build a simple fast dashboard to display internal data. Make sure to use this skill whenever the user mentions dashboards, data visualization, or wants to display any kind of company data, even if they don't explicitly ask for a 'dashboard.'"

  **Description style rule**: Express the description in terms of **intent and context** — what the user is trying to accomplish and when this skill should activate. Avoid listing trigger keywords or example phrases explicitly (e.g., no `Trigger keywords: "foo", "bar"`). If the intent is described precisely enough, keyword lists are redundant and add noise. Exception: a short "pushy" example at the end (like the one above) is acceptable when it helps cover implicit or ambiguous trigger cases.
- **the skill body**: Express the intent and reasoning behind each part, not just a sequence of steps. A reader should understand *why* each section exists and what it is trying to achieve — not just what to do. Challenge each section before organizing it: if a section cannot be justified in terms of the problem it solves, remove or merge it.

### Skill Writing Guide

Start with what the skill needs to accomplish — then decide how to structure it. Structure is a tool in service of content. If a section, heading, or hierarchy exists without a clear purpose, it adds noise. Write the substance first, organize second.

#### Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── config.yaml - User-configurable parameters
    ├── references/ - Docs loaded into context as needed
    ├── examples/   - Concrete examples with real project data
    └── assets/     - Files used in output (templates, icons, fonts)
```

#### Progressive Disclosure

Skills use a three-level loading system:
1. **Metadata** (name + description) — Always in context (~100 words)
2. **SKILL.md body** — In context whenever skill triggers (<500 lines ideal)
3. **Bundled resources** — As needed (unlimited, scripts can execute without loading)

These word counts are approximate and you can feel free to go longer if needed.

**Key patterns:**
- Keep SKILL.md under 500 lines; if approaching this limit, add an additional layer of hierarchy with clear pointers about where to follow up
- Reference files clearly from SKILL.md with guidance on when to read them
- For large reference files (>300 lines), include a table of contents

**Domain organization**: When a skill supports multiple domains/frameworks, organize by variant:
```
cloud-deploy/
├── SKILL.md (workflow + selection)
└── references/
    ├── aws.md
    ├── gcp.md
    └── on-prem.md
```
OpenCode reads only the relevant reference file.

#### Bundled Resources Guidelines

##### Scripts (`scripts/`)

Extract executable code to `scripts/` when it exceeds ~5 lines OR is reused more than once in the skill. Reference from SKILL.md by intent only — describe what the script does and when to use it, not how it works.

**Bad**: embedding a 20-line bash loop inline in SKILL.md
**Good**: `run scripts/wait-ci.sh <pr-number> <repo>` — waits for CI checks to complete, prints progress every 10s, times out after 5 minutes

##### Configuration (`config.yaml`)

User-configurable parameters (report mode, analysis depth, presentation style, etc.) belong in a dedicated `config.yaml` file, not in the SKILL.md body. Reference it explicitly from SKILL.md ("Read `config.yaml` at startup to determine behavior"). An init script modifies `config.yaml` only — never SKILL.md.

**Bad**: embedding a `config:` YAML block inside SKILL.md instructions
**Good**: a separate `config.yaml` file with documented defaults, referenced from SKILL.md

##### Examples (`examples/`)

Examples in SKILL.md must show structure and principles only, using generic placeholder values. Concrete examples with real project data belong exclusively in `examples/`, referenced from SKILL.md with a note indicating their scope.

**Bad**: embedding a finding example with real file paths and class names directly in SKILL.md
**Good**: SKILL.md describes the expected structure; `examples/my-finding.md` contains the concrete illustration

##### References (`references/`)

SKILL.md must not duplicate content already in `references/`. Point to reference files and specify when to read them — do not reproduce their content inline.

**Bad**: re-listing a 50-item checklist that already lives in `references/checklist.md`
**Good**: "Read `references/checklist.md` during Phase 3 to evaluate each finding"

##### SKILL.md content policy

SKILL.md contains only active, operational instructions. Roadmaps, TBD notes, and future features belong in `README.md` or `roadmap/`. Express behavioral defaults in prose — do not hardcode display templates marked MANDATORY or prescribe exact rendering formats. Let the model choose the presentation format appropriate to the context.

#### Principle of Least Surprise

Skills must not contain malware, exploit code, or any content that could compromise system security. A skill's contents should not surprise the user if described. Don't go along with requests to create misleading skills or skills designed to facilitate unauthorized access or data exfiltration.

#### Writing Patterns

Prefer using the imperative form in instructions.

**Defining output formats:**
```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Examples pattern** — include examples with generic placeholders:
```markdown
## Commit message format
Input: added user authentication
Output: feat(auth): implement JWT-based authentication
```

### Writing Style

Explain to the model *why* things are important rather than relying on heavy-handed MUSTs. Use theory of mind and try to make the skill general rather than narrow to specific examples. Write a draft, then look at it with fresh eyes and improve it.

### Test Cases

After writing the skill draft, come up with 2-3 realistic test prompts — the kind of thing a real user would actually say. Share them with the user: "Here are a few test cases I'd like to try. Do these look right, or do you want to add more?" Then run them.

Save test cases to `evals/evals.json`. Don't write assertions yet — just the prompts. You'll draft assertions in the next step while the runs are in progress.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for the full schema (including the `assertions` field, which you'll add later).

## Running and evaluating test cases

This section is one continuous sequence — don't stop partway through.

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Within the workspace, organize results by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a directory (`eval-0/`, `eval-1/`, etc.). Don't create all of this upfront — just create directories as you go.

### Step 1: Spawn all runs (with-skill AND baseline) in the same turn

For each test case, spawn two subagents in the same turn — one with the skill, one without. Use `Task(subagent_type="general")` for both. Launch everything at once so it all finishes around the same time.

Note: subagents spawned via `Task` share some context with the parent session, so isolation is less strict than with fully independent subagents. Keep this in mind when interpreting results — the with-skill and baseline runs are still meaningfully different, but not completely isolated.

**Eval isolation rules** — subagents must respect these constraints:
- Write only to the designated `outputs/` directory — no other files may be created or modified outside the workspace
- Any file created outside `outputs/` during the run (drafts, scratch files, temporary config) must be deleted by the subagent before it finishes — the workspace directory must be the only trace left
- If a file cannot be deleted, document it in `outputs/user_notes.md` so the orchestrator can clean it up
- The skill being evaluated must not be modified during a run; if a run would normally edit a skill file, skip that step and document it in `outputs/` instead

**With-skill run:**

```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about>
```

**Baseline run** (same prompt, but the baseline depends on context):
- **Creating a new skill**: no skill at all. Same prompt, no skill path, save to `without_skill/outputs/`.
- **Improving an existing skill**: the old version. Before editing, snapshot the skill (`cp -r <skill-path> <workspace>/skill-snapshot/`), then point the baseline subagent at the snapshot. Save to `old_skill/outputs/`.

Write an `eval_metadata.json` for each test case (assertions can be empty for now). Give each eval a descriptive name based on what it's testing — not just "eval-0". Use this name for the directory too.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### Step 2: While runs are in progress, draft assertions

Don't wait for the runs to finish — use this time productively. Draft quantitative assertions for each test case and explain them to the user. If assertions already exist in `evals/evals.json`, review them and explain what they check.

Good assertions are objectively verifiable and have descriptive names. Subjective skills (writing style, design quality) are better evaluated qualitatively — don't force assertions onto things that need human judgment.

When writing assertions, distinguish between two types:
- **Conformance assertions**: the skill followed its instructions (e.g., a specific section is present, a required step was taken). Useful, but insufficient on their own — a skill can follow every instruction and still fail to solve the right problem.
- **Impact assertions**: the output actually achieves the goal the skill was designed for (e.g., the generated code compiles and passes the target test, the extracted data matches the expected structure). These are the ones that matter most. If all conformance assertions pass but impact assertions fail, the skill is broken — regardless of how well it followed its own instructions.

Prefer impact assertions where they are achievable. When they're not (because the goal is subjective or hard to verify automatically), say so explicitly and rely on the qualitative human review instead.

Update the `eval_metadata.json` files and `evals/evals.json` with the assertions once drafted.

### Step 3: As runs complete, capture timing data

When each subagent task completes, you receive a notification containing `total_tokens` and `duration_ms`. Save this data immediately to `timing.json` in the run directory:

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

This is the only opportunity to capture this data — it comes through the task notification and isn't persisted elsewhere.

### Step 4: Grade, aggregate, and launch the viewer

Once all runs are done:

1. **Grade each run** — spawn a grader subagent that reads `agents/grader.md` and evaluates each assertion against the outputs. Save results to `grading.json` in each run directory. The grading.json expectations array must use the fields `text`, `passed`, and `evidence` — the viewer depends on these exact field names.

2. **Aggregate into benchmark** — manually build `benchmark.json` by reading all `grading.json` files across runs and computing:
   - per-assertion pass rate (with_skill vs without_skill)
   - overall pass rate delta between conditions
   - total run count per condition

   Save the result as `<workspace>/iteration-N/benchmark.json`. See `references/schemas.md` for the exact schema. Also write a brief `benchmark.md` summary (skill name, iteration, delta, notable gaps).

3. **Do an analyst pass** — read the benchmark data and surface patterns the aggregate stats might hide. See `agents/analyzer.md` (the "Analyzing Benchmark Results" section) for what to look for.

4. **Launch the viewer** — use `--static` to generate a standalone HTML file (no server required):
   ```bash
   python <skill-creator-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     --static /tmp/review-<skill-name>-iteration-N.html
   open /tmp/review-<skill-name>-iteration-N.html
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

5. **Tell the user** something like: "I've opened the results in your browser. The 'Outputs' tab lets you click through each test case and leave feedback, the 'Benchmark' tab shows the quantitative comparison. When you're done, come back here and let me know."

### What the user sees in the viewer

The "Outputs" tab shows one test case at a time:
- **Prompt**: the task that was given
- **Output**: the files the skill produced, rendered inline where possible
- **Previous Output** (iteration 2+): collapsed section showing last iteration's output
- **Formal Grades** (if grading was run): collapsed section showing assertion pass/fail
- **Feedback**: a textbox that auto-saves as they type
- **Previous Feedback** (iteration 2+): their comments from last time

Navigation is via prev/next buttons or arrow keys. When done, they click "Submit All Reviews" which saves all feedback to `feedback.json`.

### Step 5: Read the feedback

When the user tells you they're done, read `feedback.json`:

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."},
    {"run_id": "eval-2-with_skill", "feedback": "perfect, love this", "timestamp": "..."}
  ],
  "status": "complete"
}
```

Empty feedback means the user thought it was fine. Focus improvements on the test cases where the user had specific complaints.

### Step 6: Cleanup

Once the feedback has been read and integrated (or the eval cycle is complete), delete all eval artifacts automatically — no confirmation needed. The workspace is a temporary evaluation artifact; results that matter have already been read and applied.

Delete in this order:

1. **Workspace directory** — `<skill-name>-workspace/` (contains all runs, grading, benchmark, snapshot)
2. **Static viewers** — `/tmp/review-<skill-name>-iteration-*.html` and `/tmp/eval_review_<skill-name>.html`
3. **Downloads** — `~/Downloads/eval_set.json` and `~/Downloads/feedback.json` (if they exist)
4. **Orphaned files** — any files documented in `outputs/user_notes.md` by subagents that could not self-clean

Tell the user which files were deleted.

---

## Improving the skill

This is the heart of the loop. You've run the test cases, the user has reviewed the results, and now you need to make the skill better based on their feedback.

### How to think about improvements

1. **Generalize from the feedback.** We're trying to create skills that can be used across many different prompts. You and the user are iterating on only a few examples because it moves faster — but if the skill only works for those examples, it's useless. Rather than make fiddly overfitty changes, try different metaphors or different patterns of working. It's cheap to try and might land on something great.

2. **Keep the skill lean.** Remove things that aren't pulling their weight. Read the transcripts, not just the final outputs — if the skill is making the model waste time doing unproductive things, try removing the parts causing that behavior.

3. **Explain the why.** Try hard to explain the *why* behind everything you're asking the model to do. LLMs are smart — when given good context they can go beyond rote instructions. If you find yourself writing ALWAYS or NEVER in all caps or using super rigid structures, that's a yellow flag. Reframe and explain the reasoning so the model understands why the thing matters.

4. **Look for repeated work across test cases.** If all 3 test cases resulted in the subagent writing a similar helper script, that's a strong signal the skill should bundle that script. Write it once, put it in `scripts/`, and tell the skill to use it.

5. **Challenge the intent before rewriting.** If multiple iterations haven't produced meaningful progress, don't assume the wording is the problem. Ask whether the problem itself is well-defined. Optimizing the phrasing of instructions that serve a poorly understood goal produces no value. Step back, restate the goal, and verify alignment with the user before continuing.

### The iteration loop

After improving the skill:

1. Apply your improvements to the skill
2. Rerun all test cases into a new `iteration-<N+1>/` directory, including baseline runs
3. Launch the reviewer with `--previous-workspace` pointing at the previous iteration
4. Wait for the user to review and tell you they're done
5. Read the new feedback, improve again, repeat

Keep going until:
- The user says they're happy
- The feedback is all empty (everything looks good)
- You're not making meaningful progress

---

## Advanced: Blind comparison

For situations where you want a more rigorous comparison between two versions of a skill, there's a blind comparison system. Read `agents/comparator.md` and `agents/analyzer.md` for the details. The basic idea: give two outputs to an independent agent without telling it which is which, and let it judge quality. Then analyze why the winner won.

This is optional and most users won't need it. The human review loop is usually sufficient.

---

## Description Optimization

The description field in SKILL.md frontmatter is the primary mechanism that determines whether OpenCode invokes a skill. After creating or improving a skill, offer to optimize the description for better triggering accuracy.

### Step 1: Generate trigger eval queries

Create 20 eval queries — a mix of should-trigger and should-not-trigger. Save as JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

The queries must be realistic and specific — include file paths, personal context, column names, company names, URLs, a little backstory. Some might be in lowercase or contain abbreviations or typos. Use a mix of lengths, and focus on edge cases rather than clear-cut cases.

For the **should-trigger** queries (8-10): cover different phrasings of the same intent — some formal, some casual. Include cases where the user doesn't explicitly name the skill but clearly needs it. Include uncommon use cases and cases where this skill competes with another but should win.

For the **should-not-trigger** queries (8-10): focus on near-misses — queries that share keywords with the skill but actually need something different. Adjacent domains, ambiguous phrasing where a naive keyword match would trigger but shouldn't. These negative cases should be genuinely tricky, not obviously irrelevant.

### Step 2: Review with user

Present the eval set using the HTML template:

1. Read the template from `assets/eval_review.html`
2. Replace the placeholders:
   - `__EVAL_DATA_PLACEHOLDER__` → the JSON array of eval items
   - `__SKILL_NAME_PLACEHOLDER__` → the skill's name
   - `__SKILL_DESCRIPTION_PLACEHOLDER__` → the skill's current description
3. Write to `/tmp/eval_review_<skill-name>.html` and open it: `open /tmp/eval_review_<skill-name>.html`
4. The user can edit queries, toggle should-trigger, add/remove entries, then click "Export Eval Set"
5. The file downloads to `~/Downloads/eval_set.json` — check Downloads for the most recent version

### Step 3: Optimize manually

The automated optimization loop (`run_loop.py`) requires the `claude` CLI which is not available in this environment. Run the optimization manually instead:

1. For each should-trigger query, ask: would the current description cause OpenCode to read this skill for this prompt? If not, note why.
2. For each should-not-trigger query, ask: could the current description accidentally pull in this skill? If yes, note why.
3. Propose a revised description that addresses the failures.
4. Re-evaluate the full eval set against the proposed description.
5. Repeat until the description passes all or nearly all queries.

This is more effortful than the automated loop but produces the same result: a description that is both precise (doesn't over-trigger) and complete (doesn't under-trigger).

### Step 4: Apply the result

Update the skill's SKILL.md frontmatter with the improved description. Show the user before/after.

### How skill triggering works

Skills appear in OpenCode's `available_skills` list with their name + description, and OpenCode decides whether to consult a skill based on that description. OpenCode only consults skills for tasks it can't easily handle on its own — simple, one-step queries may not trigger a skill even if the description matches perfectly, because OpenCode can handle them directly. Complex, multi-step, or specialized queries reliably trigger skills when the description matches.

This means eval queries should be substantive enough that OpenCode would actually benefit from consulting a skill. Simple queries are poor test cases — they won't trigger skills regardless of description quality.

---

## Packaging

Once the skill is done, package it for distribution:

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

This creates a `.skill` file (zip format) in the current directory, excluding build artifacts and eval files. Tell the user the path of the resulting `.skill` file so they can install or share it.

---

## Reference files

The `agents/` directory contains instructions for specialized subagents. Read them when you need to spawn the relevant subagent.

- `agents/grader.md` — How to evaluate assertions against outputs
- `agents/comparator.md` — How to do blind A/B comparison between two outputs
- `agents/analyzer.md` — How to analyze why one version beat another

The `references/` directory has additional documentation:
- `references/schemas.md` — JSON structures for evals.json, grading.json, etc.

---

Repeating the core loop for emphasis:

- Figure out what the skill is about
- Draft or edit the skill
- Run OpenCode-with-access-to-the-skill on test prompts (via `Task(subagent_type="general")`)
- With the user, evaluate the outputs using `eval-viewer/generate_review.py --static`
- Run quantitative evals
- Repeat until you and the user are satisfied
- Package the final skill

Add steps to your TodoList to make sure you don't forget. Specifically, put "Generate static HTML review with `eval-viewer/generate_review.py --static` so user can review test cases" in your TodoList.
