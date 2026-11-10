#!/usr/bin/env bash
# Tests for verify-implementation.sh. Each case builds a throw-away git repository
# holding a copy of the script, a tasks.md, and a test-then-production history.
#
# Usage: verify-implementation.test.sh
# Exit:  0 = every case passed, 1 = at least one failed

set -u

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/verify-implementation.sh"
FAILURES=0
PASSES=0

empty_repo() {
  REPO="$(mktemp -d)"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email test@example.com
  git -C "$REPO" config user.name test
  git -C "$REPO" config commit.gpgsign false
  mkdir -p "$REPO/.specify/scripts/bash"
  cp "$SCRIPT" "$REPO/.specify/scripts/bash/"
  write_file README.md "base"
  commit_all "chore: start"
  git -C "$REPO" branch -q -f base
}

new_repo() {
  empty_repo
  write_file src/test/java/app/ThingTest.java "class ThingTest {}"
  commit_all "test: thing"
  write_file src/main/java/app/Thing.java "class Thing {}"
  commit_all "feat: thing"
}

write_file() {
  mkdir -p "$REPO/$(dirname "$1")"
  printf '%b\n' "$2" > "$REPO/$1"
}

commit_all() {
  git -C "$REPO" add -A
  git -C "$REPO" commit -q --no-verify -m "$1"
}

write_tasks() {
  local test_path="${2:-src/test/java/app/ThingTest.java}" evidence="${3-\`\`\`text\nBUILD FAILED\n\`\`\`}"
  write_file specs/001-thing/tasks.md "# Tasks\n\n- [x] T001 [US1] Write $test_path\n- [x] T002 [GATE] Run the tests and paste the failure\n\n$evidence\n\n- [x] T003 [US1] Implement $1"
}

# expect_exit NAME EXPECTED_CODE [PATTERN] — PATTERN, when given, must appear in
# the output, so a case cannot pass on the right exit code for the wrong reason.
expect_exit() {
  local name="$1" expected="$2" pattern="${3:-}" output code
  output="$(cd "$REPO" && BASE_REF=base .specify/scripts/bash/verify-implementation.sh specs/001-thing 2>&1)"
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

echo "verify-implementation.sh"

new_repo
write_tasks "src/main/java/app/Thing.java"
expect_exit "checked tasks naming existing files pass" 0

new_repo
write_tasks "src/main/java/app/Ghost.java"
expect_exit "a checked task naming a missing file is drift" 1

empty_repo
write_file src/main/kotlin/app/Thing.kt "class Thing"
commit_all "feat: thing"
write_tasks "src/main/kotlin/app/Thing.kt"
expect_exit "Kotlin production code with no preceding test is drift" 1 "production code committed with no preceding test commit"

empty_repo
write_file src/test/kotlin/app/ThingTest.kt "class ThingTest"
commit_all "test: thing"
write_file src/main/kotlin/app/Thing.kt "class Thing"
commit_all "feat: thing"
write_tasks "src/main/kotlin/app/Thing.kt" "src/test/kotlin/app/ThingTest.kt"
expect_exit "Kotlin production code preceded by a test passes" 0

empty_repo
write_file modules/catalog/src/main/java/app/Thing.java "class Thing {}"
commit_all "feat: thing"
write_tasks "modules/catalog/src/main/java/app/Thing.java"
expect_exit "multi-module production code with no preceding test is drift" 1 "production code committed with no preceding test commit"

empty_repo
write_file src/test/java/app/OldTest.java "class OldTest {}"
commit_all "test: old"
git -C "$REPO" branch -q -f base
git -C "$REPO" rm -q src/test/java/app/OldTest.java
commit_all "test: drop an obsolete test"
write_file src/main/java/app/Thing.java "class Thing {}"
commit_all "feat: thing"
write_tasks "src/main/java/app/Thing.java"
expect_exit "a commit that only deletes a test does not license production code" 1 "production code committed with no preceding test commit"

empty_repo
write_file lib/thing.py "x = 1"
commit_all "feat: thing"
write_tasks "docs/none.md"
expect_exit "a range touching code under no recognised layout cannot be checked" 2 "CANNOT CHECK"

new_repo
write_tasks "src/main/java/app/Thing.java" "" "I ran it and it FAILED, honest."
expect_exit "gate evidence written as prose is drift" 1 "fenced code block"

new_repo
write_tasks "src/main/java/app/Thing.java" "" "\`\`\`text\nBUILD SUCCESSFUL in 3s\n\`\`\`\nIt FAILED before, trust me."
expect_exit "a failure claimed outside the pasted output is drift" 1 "successful run"

empty_repo
write_file src/main/java/app/Thing.java "class Thing {}"
commit_all "feat: thing"
write_file src/test/java/app/ThingTest.java "class ThingTest {}"
commit_all "test: thing"
write_tasks "src/main/java/app/Thing.java"
expect_exit "production code before its test is drift" 1 "production code committed with no preceding test commit"

new_repo
write_file app/src/main/res/layout.xml "<x/>"
commit_all "chore: layout"
write_tasks "\`app/src/main/res/missing.xml\`"
expect_exit "a checked task naming a missing file outside src/ is drift" 1 "missing.xml"

new_repo
write_tasks "src/main/java/app/Thi[n]g.java"
expect_exit "a bracketed path is never glob-expanded into a real file" 0 "1 declared path\(s\) exist"

echo
echo "$PASSES passed, $FAILURES failed"
[ "$FAILURES" -eq 0 ]
