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

new_repo() {
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
  write_file specs/001-thing/tasks.md "# Tasks\n\n- [x] T001 [US1] Write src/test/java/app/ThingTest.java\n- [x] T002 [GATE] Run the tests and paste the failure\n\n\`\`\`text\nBUILD FAILED\n\`\`\`\n\n- [x] T003 [US1] Implement $1"
}

expect_exit() {
  local name="$1" expected="$2" output code
  output="$(cd "$REPO" && BASE_REF=base .specify/scripts/bash/verify-implementation.sh specs/001-thing 2>&1)"
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

echo "verify-implementation.sh"

new_repo
write_tasks "src/main/java/app/Thing.java"
expect_exit "checked tasks naming existing files pass" 0

new_repo
write_tasks "src/main/java/app/Ghost.java"
expect_exit "a checked task naming a missing file is drift" 1

echo
echo "$PASSES passed, $FAILURES failed"
[ "$FAILURES" -eq 0 ]
