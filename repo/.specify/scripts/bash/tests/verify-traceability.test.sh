#!/usr/bin/env bash
# Tests for verify-traceability.sh. Each case builds a throw-away directory holding
# a copy of the script, a spec.md, a tasks.md and, when needed, a feature file.
#
# Usage: verify-traceability.test.sh
# Exit:  0 = every case passed, 1 = at least one failed

set -u

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/verify-traceability.sh"
FAILURES=0
PASSES=0

write_file() {
  mkdir -p "$REPO/$(dirname "$1")"
  printf '%b\n' "$2" > "$REPO/$1"
}

write_spec() {
  write_file "specs/$SPEC_DIR/spec.md" "# Spec\n\n## Source Ticket\n\nAdd a thing.\n\n### User Story 1 - Add a thing (Priority: P1)\n\n**Acceptance Scenarios**:\n\n1. ✅ **Given** nothing, **When** a thing is added, **Then** it is kept\n2. ❌ **When** a blank thing is added, **Then** it is refused\n\n## Requirements\n\n- **FR-001**: a thing has a name\n- **FR-002**: a blank name is refused"
}

# write_tasks FEATURE_REFERENCE [FR_REFERENCE]
write_tasks() {
  local feature="$1" frs="${2-(FR-001, FR-002)}"
  write_file "specs/$SPEC_DIR/tasks.md" "# Tasks\n\n- [x] T001 [US1] Write $feature from the acceptance scenarios $frs\n- [x] T002 [US1] [GATE] Run the tests and paste the failure\n\n\`\`\`text\nBUILD FAILED\n\`\`\`\n\n- [x] T003 [US1] Implement the thing"
}

# write_feature [KEYWORD] [COVERS] — the scenario keyword, so outlines can be written
# too, and the header's covers list, so qualified headers can be written too.
write_feature() {
  local keyword="${1:-Scenario}" covers="${2:-US1, FR-001, FR-002}" examples=""
  [ "$keyword" = "Scenario" ] || examples="\n    Examples:\n      | name |\n      | x    |"
  write_file src/test/resources/behaviors/ctx/add_thing.feature "# Covers: $covers\nFeature: Add a thing\n\n  Rule: a thing has a name\n\n    $keyword: ✅ Valid thing\n      When a thing is added$examples\n\n    $keyword: ❌ Blank thing\n      When a blank thing is added$examples"
}

# new_repo [SPEC_DIR] — the feature directory under specs/, 001-thing by default.
new_repo() {
  SPEC_DIR="${1:-001-thing}"
  REPO="$(mktemp -d)"
  mkdir -p "$REPO/.specify/scripts/bash"
  cp "$SCRIPT" "$REPO/.specify/scripts/bash/"
  write_spec
}

# expect_exit NAME EXPECTED_CODE [PATTERN] — PATTERN, when given, must appear in
# the output, so a case cannot pass on the right exit code for the wrong reason.
expect_exit() {
  local name="$1" expected="$2" pattern="${3:-}" output code
  output="$(cd "$REPO" && .specify/scripts/bash/verify-traceability.sh "specs/$SPEC_DIR" 2>&1)"
  code=$?
  if [ "$code" -eq "$expected" ] && { [ -z "$pattern" ] || echo "$output" | grep -qE -- "$pattern"; }; then
    PASSES=$((PASSES + 1))
    echo "  PASS  $name"
  else
    FAILURES=$((FAILURES + 1))
    echo "  FAIL  $name — expected exit $expected${pattern:+ and /$pattern/}, got $code"
    echo "$output" | sed 's/^/        | /'
  fi
  rm -rf "$REPO"
}

echo "verify-traceability.sh"

new_repo
write_feature
write_tasks "\`src/test/resources/behaviors/ctx/add_thing.feature\`"
expect_exit "a spec traced through tasks and a feature file passes" 0

new_repo
write_feature
write_tasks "\`src/test/resources/behaviors/ctx/add_thing.feature\`" ""
printf '\nNote: FR-001 and FR-002 are deferred to a later ticket.\n' >> "$REPO/specs/$SPEC_DIR/tasks.md"
expect_exit "a requirement named only in prose is not carried by a task" 1 "DRIFT +FR-001"

new_repo
write_feature
write_tasks "the behaviour test"
expect_exit "a feature file on disk that tasks.md does not name cannot be checked" 2 "CANNOT CHECK.*feature"

new_repo
write_feature
write_tasks "\`add_thing.feature\`"
expect_exit "a feature file named by its basename is checked" 0 "OK +US1 -> 2 scenario"

new_repo
write_feature "Scenario Outline"
write_tasks "\`src/test/resources/behaviors/ctx/add_thing.feature\`"
expect_exit "scenario outlines count as scenarios" 0 "OK +US1 -> 2 scenario"

new_repo
write_feature Scenario "001: US1, FR-001, FR-002"
write_tasks "\`add_thing.feature\`"
expect_exit "a header qualified by this spec's number is read" 0 "OK +US1 -> 2 scenario"

new_repo 20261028-141500-thing
write_feature Scenario "20261028-141500: US1, FR-001, FR-002"
write_tasks "\`add_thing.feature\`"
expect_exit "a timestamp-numbered spec reads the groups qualified by its timestamp" 0 "OK +US1 -> 2 scenario"

new_repo 20261028-141500-thing
write_feature Scenario "202: US1, FR-001, FR-002"
write_tasks "\`add_thing.feature\`"
expect_exit "a timestamp-numbered spec does not read another spec's group" 0 "INFO +US1 -> no feature file"

new_repo
write_feature
write_tasks "\`add_thing.feature\`"
printf -- '- [ ] T004 Polish the docs\n' >> "$REPO/specs/$SPEC_DIR/tasks.md"
expect_exit "untagged tasks are reported as a statistic, not a check" 0 "INFO +1 task\\(s\\) carry no \\[USn\\] tag"

echo
echo "$PASSES passed, $FAILURES failed"
[ "$FAILURES" -eq 0 ]
