#!/usr/bin/env bash
# Tests for verify-domain-base.sh. Each case copies the shipped workflow into a
# throw-away git repository, commits it under a chosen author, edits the domain
# base and runs the script there.
#
# Usage: verify-domain-base.test.sh
# Exit:  0 = every case passed, 1 = at least one failed

set -u

PRODUCT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
FAILURES=0
PASSES=0

# new_repo [AUTHOR] — the commit author, whose name check 8 searches for.
new_repo() {
  local author="${1:-Release Bot [bot]}"
  REPO="$(mktemp -d)"
  rsync -a --exclude /README.md --exclude /.gitignore.snippet "$PRODUCT/" "$REPO/"
  git -C "$REPO" init -q
  git -C "$REPO" add -A
  git -C "$REPO" -c user.name="$author" -c user.email=author@example.com commit -qm "chore: start"
}

# register_point ID ITEM — an open point declaring it blocks ITEM.
register_point() {
  printf '\n### %s — Is a widget a gadget?\n- **state**: open\n- **blocks**: `%s` — whether it can be ordered\n- **decides**: what crosses the boundary\n- **owner**: the product owner\n- **issues**:\n  - yes → nothing changes\n  - no → the catalog says so\n' \
    "$1" "$2" >> "$REPO/docs/domain/decision-points.md"
}

# expect_exit NAME EXPECTED_CODE [PATTERN] — PATTERN, when given, must appear in
# the output, so a case cannot pass on the right exit code for the wrong reason.
expect_exit() {
  local name="$1" expected="$2" pattern="${3:-}" output code
  output="$(cd "$REPO" && .specify/scripts/bash/verify-domain-base.sh 2>&1)"
  code=$?
  if [ "$code" -eq "$expected" ] && { [ -z "$pattern" ] || echo "$output" | grep -qE -- "$pattern"; }; then
    PASSES=$((PASSES + 1))
    echo "  PASS  $name"
  else
    FAILURES=$((FAILURES + 1))
    echo "  FAIL  $name — expected exit $expected${pattern:+ and /$pattern/}, got $code"
    echo "$output" | grep -E 'FINDING|CANNOT|VERDICT' | sed 's/^/        | /'
  fi
  rm -rf "$REPO"
}

echo "verify-domain-base.sh"

new_repo "Jean Doe"
expect_exit "the shipped base reports no finding" 0 "VERDICT: the checks that ran"

new_repo "Jean Price"
expect_exit "a domain word that is one part of an author's name is not a finding" 0 "VERDICT: the checks that ran"

new_repo "Jean Price"
printf '\nAs Jean Price explained, a product has a price.\n' >> "$REPO/docs/domain/glossary.md"
expect_exit "an author named in full is a finding" 1 "FINDING .*glossary.md: names 'Jean Price'"

new_repo "Jean Price"
printf '\nAs Jean\nPrice explained, a product has a price.\n' >> "$REPO/docs/domain/glossary.md"
expect_exit "an author's name split by a line wrap is a finding" 1 "FINDING .*glossary.md: names 'Jean Price'"

new_repo
register_point OP-1 glossary
printf '\nAn unrelated sentence. [blocked: OP-1]\n' >> "$REPO/docs/domain/glossary.md"
expect_exit "a marker is not read as naming its item through the file's path" 1 "FINDING +OP-1 declares it blocks \"glossary\" but no line"

new_repo
register_point OP-1 Widget
printf '\n| `Widget` | Ordering | A thing. [blocked: OP-1] | "a widget" | DRAFT |\n' >> "$REPO/docs/domain/glossary.md"
expect_exit "a marker on the line naming its item passes" 0 "VERDICT: the checks that ran"

echo
echo "$PASSES passed, $FAILURES failed"
[ "$FAILURES" -eq 0 ]
