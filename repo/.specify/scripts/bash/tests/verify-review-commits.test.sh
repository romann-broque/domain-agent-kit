#!/usr/bin/env bash
# Tests for verify-review-commits.sh. Each case builds a throw-away git repository,
# marks a base, adds commits, and asserts the script's exit code.
#
# Usage: verify-review-commits.test.sh
# Exit:  0 = every case passed, 1 = at least one failed

set -u

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/verify-review-commits.sh"
FAILURES=0
PASSES=0

new_repo() {
  REPO="$(mktemp -d)"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email test@example.com
  git -C "$REPO" config user.name test
  git -C "$REPO" config commit.gpgsign false
  write_file README.md "base"
  commit_all "chore: start"
}

write_file() {
  mkdir -p "$REPO/$(dirname "$1")"
  printf '%b\n' "$2" > "$REPO/$1"
}

commit_all() {
  git -C "$REPO" add -A
  git -C "$REPO" commit -q --no-verify -m "$1"
}

mark_base() {
  git -C "$REPO" branch -q -f base
}

switch_to() {
  git -C "$REPO" checkout -q "$1"
}

new_branch() {
  git -C "$REPO" checkout -q -b "$1"
}

merge_in() {
  git -C "$REPO" merge -q --no-ff --no-edit --no-verify "$1"
}

expect_exit() {
  local name="$1" expected="$2" base="${3:-base}" output code
  output="$(cd "$REPO" && "$SCRIPT" "$base" HEAD 2>&1)"
  code=$?
  if [ "$code" -eq "$expected" ]; then
    PASSES=$((PASSES + 1))
    echo "  PASS  $name"
  else
    FAILURES=$((FAILURES + 1))
    echo "  FAIL  $name — expected exit $expected, got $code"
    echo "$output" | sed 's/^/        | /'
  fi
  rm -rf "$REPO"
}

FEATURE='src/test/resources/behaviors/ctx/do_thing.feature'
SPEC='specs/001-thing/spec.md'
MAIN='src/main/java/com/x/Thing.java'
TEST='src/test/java/com/x/ThingTest.java'

new_repo; mark_base
write_file "$TEST" "class ThingTest {}"; commit_all "test(ctx): pin the thing"
write_file "$MAIN" "class Thing {}"; commit_all "feat(ctx): add the thing"
expect_exit "a test then its implementation passes" 0

new_repo; write_file "$FEATURE" "Feature: Do a thing\n  Scenario: ✅ Works\n    Given the user has a thing"; commit_all "test(ctx): pin"; mark_base
write_file "$FEATURE" "Feature: Do a thing\n  Scenario: ✅ Works\n    Given the user has another thing"; commit_all "refactor(ctx): apply the review"
expect_exit "a refactor that edits a feature file is drift" 1

new_repo; write_file "$SPEC" "- **FR-001**: the thing is kept"; commit_all "docs(spec): spec"; mark_base
write_file "$SPEC" "- **FR-001**: the thing is dropped"; commit_all "refactor(ctx): apply the review"
expect_exit "a refactor that edits a spec is drift" 1

new_repo; write_file "$SPEC" "- **FR-001**: the thing is kept"; write_file "$MAIN" "class Thing {}"; commit_all "feat(ctx): start"; mark_base
write_file "$SPEC" "- **FR-001**: the thing is dropped"; commit_all "docs(spec): amend FR-001 after review"
write_file "$MAIN" "class Thing { int x; }"; commit_all "fix(ctx): drop the thing"
expect_exit "an amended requirement implemented without a test commit is drift" 1

new_repo; write_file "$SPEC" "- **FR-001**: the thing is kept"; write_file "$MAIN" "class Thing {}"; commit_all "feat(ctx): start"; mark_base
write_file "$SPEC" "- **FR-001**: the thing is dropped"; commit_all "docs(spec): amend FR-001 after review"
write_file "$TEST" "class ThingTest { void dropped() {} }"; commit_all "test(ctx): pin the dropped thing"
write_file "$MAIN" "class Thing { int x; }"; commit_all "fix(ctx): drop the thing"
expect_exit "an amended requirement, then its test, then its fix passes" 0

new_repo; mark_base
write_file "$FEATURE" "Feature: Do a thing\n  Scenario: ✅ Works"; write_file "$MAIN" "class Thing {}"; commit_all "feat(ctx): do it all at once"
expect_exit "a scenario and production code in one commit is drift" 1

new_repo; write_file "$FEATURE" "Feature: Do a thing\n  Scenario Outline: ✅ Works\n    Given the user has <n> things\n    Examples:\n      | n |\n      | 1 |"; commit_all "test(ctx): pin"; mark_base
write_file "$FEATURE" "Feature: Do a thing\n  Scenario Outline: ✅ Works\n    Given the user has <n> things\n    Examples:\n      | n |\n      | 0 |"; write_file "$MAIN" "class Thing {}"; commit_all "feat(ctx): accept zero"
expect_exit "an examples table row and production code in one commit is drift" 1

new_repo; write_file "specs/001-thing/contracts/schema.md" "| column | note |\n| name | indexed |"; commit_all "docs(spec): contract"; mark_base
write_file "specs/001-thing/contracts/schema.md" "| column | note |\n| name | indexed on the raw column |"; write_file "$MAIN" "class Thing {}"; commit_all "fix(ctx): adjust"
expect_exit "a markdown table row in a contract is not a scenario change" 0

new_repo; write_file "$SPEC" "## Context\nThe thing exists."; write_file "$MAIN" "class Thing {}"; commit_all "feat(ctx): start"; mark_base
write_file "$SPEC" "## Context\nThe thing exists, and is old."; commit_all "docs(spec): reword the context"
write_file "$MAIN" "class Thing { int x; }"; commit_all "fix(ctx): adjust"
expect_exit "a spec rewording that touches no requirement or scenario is not a scenario change" 0

new_repo; write_file "$MAIN" "class Thing {}"; commit_all "feat(ctx): start"; mark_base
write_file "$MAIN" "class Thing { }"; commit_all "refactor(ctx): tidy"
expect_exit "a refactor of production code alone passes" 0

new_repo; mark_base
write_file "$MAIN" "class Thing {}"; commit_all "apply review"
expect_exit "a non-conventional commit message is incomplete" 2

new_repo; mark_base
write_file "$MAIN" "class Thing {}"; commit_all "feat(ctx): add the thing"
write_file "$MAIN" "class Other {}"; commit_all 'Revert "feat(ctx): add the thing"'
expect_exit "git's default revert subject is parsable" 0

new_repo; mark_base
new_branch upstream; write_file README.md "upstream"; commit_all "apply review"
switch_to main; write_file "$TEST" "class ThingTest {}"; commit_all "test(ctx): pin the thing"
merge_in upstream
expect_exit "commits brought in by a merge are not checked" 0

new_repo; write_file "$TEST" "  // Covers: US2, FR-002"; commit_all "test(ctx): covers"; mark_base
write_file "$TEST" "  // Covers: US1, FR-003"; commit_all "test(ctx): covers for the new spec"
expect_exit "an unqualified covers line overwritten by another spec is drift" 1

new_repo; write_file "$TEST" "  // Covers: US2, FR-002"; commit_all "test(ctx): covers"; mark_base
write_file "$TEST" "  // Covers: 002: US2, FR-002; 005: US1, FR-003"; commit_all "test(ctx): qualify covers"
expect_exit "a covers line qualified with both specs passes" 0

new_repo; write_file "$TEST" "  // Covers: US5, FR-010, FR-011, US1, FR-014, FR-015"; commit_all "test(ctx): covers"; mark_base
write_file "$TEST" "  // Covers: 001: US5, FR-010, FR-011; 004: US1, FR-014, FR-015"; commit_all "test(ctx): qualify covers"
expect_exit "an unqualified covers line split into qualified groups passes" 0

new_repo; write_file "$TEST" "  // Covers: US5, FR-010, FR-011"; commit_all "test(ctx): covers"; mark_base
write_file "$TEST" "  // Covers: 001: US5, FR-010"; commit_all "test(ctx): qualify covers"
expect_exit "a token dropped while qualifying is drift" 1

new_repo; write_file "$TEST" "  // Covers: 002: US2, FR-002; 005: US1, FR-003"; commit_all "test(ctx): covers"; mark_base
write_file "$TEST" "  // Covers: 005: US1, FR-003"; commit_all "test(ctx): rewrite covers"
expect_exit "a dropped spec group in a covers line is drift" 1

new_repo; write_file "$TEST" "  // Covers: US1"; commit_all "test(ctx): covers"; mark_base
switch_to base; write_file "$TEST" "  // Covers: US1, FR-009"; commit_all "test(ctx): covers on the base"
switch_to main; write_file README.md "branch work"; commit_all "docs(ctx): branch work"
expect_exit "a covers token added to the base after the fork is not a loss" 0

new_repo; write_file "$FEATURE" "# Covers: US1, FR-001\nFeature: Do a thing"; commit_all "test(ctx): covers"; mark_base
write_file "$FEATURE" "# Covers: US1, FR-001\nFeature: Do a thing\n"; commit_all "test(ctx): trailing line"
expect_exit "a feature header covers line kept verbatim passes" 0

new_repo; mark_base
expect_exit "a base ref that does not exist is incomplete" 2 does-not-exist

echo
echo "$PASSES passed, $FAILURES failed"
[ "$FAILURES" -eq 0 ]
