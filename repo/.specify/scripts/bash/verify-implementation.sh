#!/usr/bin/env bash
# Mechanical implementation check.
#
# Answers: "is there evidence that the work was done the way it was declared?".
# Not "is the code correct" — that is a judgement, and it is not this script's job.
#
# The strongest check here is the commit order. The [GATE] task is declarative:
# a hurried agent can write the production code, then the test, then paste a
# plausible failure. Git does not lie about the order in which things appeared.
#
# Usage: verify-implementation.sh [feature-directory]
# Exit:  0 = no drift, 1 = drift found, 2 = could not check

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT" || exit 2

FEATURE_DIR="${1:-}"
if [ -z "$FEATURE_DIR" ] && [ -f .specify/feature.json ]; then
  FEATURE_DIR="$(sed -n 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .specify/feature.json)"
fi

if [ -z "$FEATURE_DIR" ]; then
  echo "CANNOT CHECK: no feature directory given and .specify/feature.json is absent." >&2
  exit 2
fi

TASKS="$FEATURE_DIR/tasks.md"
if [ ! -f "$TASKS" ]; then
  echo "CANNOT CHECK: $TASKS does not exist." >&2
  exit 2
fi

BASE_REF="${BASE_REF:-origin/main}"

DRIFT=0
UNCHECKABLE=0

echo "IMPLEMENTATION — $FEATURE_DIR"
echo

# ------------------------------------------------------- gates carry evidence
echo "## Test gates carry an observed failure"
GATE_LINES=$(grep -nE '^- \[[ xX]\] T[0-9]+ .*\[GATE\]' "$TASKS" | cut -d: -f1)
if [ -z "$GATE_LINES" ]; then
  echo "  DRIFT         no [GATE] task found — the test-first barrier is absent."
  DRIFT=1
else
  for ln in $GATE_LINES; do
    line=$(sed -n "${ln}p" "$TASKS")
    id=$(echo "$line" | grep -oE 'T[0-9]+' | head -1)
    if ! echo "$line" | grep -qE '^- \[[xX]\]'; then
      echo "  INFO          $id not checked yet — implementation must not have started"
      continue
    fi
    # Evidence is whatever follows the gate task, up to the next task line.
    evidence=$(awk -v start="$ln" 'NR>start { if ($0 ~ /^- \[[ xX]\] T[0-9]+ /) exit; print }' "$TASKS")
    if [ -z "$(echo "$evidence" | tr -d '[:space:]')" ]; then
      echo "  DRIFT         $id checked but no output pasted underneath."
      echo "                A gate without evidence is a claim, not a proof."
      DRIFT=1
    # A failure marker must be an actual failure. Matching a bare "fail" is a
    # trap: every green Gradle run prints "0 failures", so a passing output
    # would satisfy the check and the gate would prove nothing.
    elif echo "$evidence" | grep -qE 'BUILD SUCCESSFUL' \
         && ! echo "$evidence" | grep -qE 'BUILD FAILED'; then
      echo "  DRIFT         $id checked, but the pasted output is a successful run."
      echo "                A test green before the implementation exists is defective."
      DRIFT=1
    elif ! echo "$evidence" | grep -qE \
         'BUILD FAILED|FAILED|FAILURE|cannot find symbol|does not exist|compilation failed|AssertionError|error:|[1-9][0-9]* (tests? )?(failed|failures|errors)'; then
      echo "  DRIFT         $id checked, output present, but it shows no failure."
      echo "                A test green before the implementation exists is defective."
      DRIFT=1
    else
      echo "  OK            $id evidence present and shows a failure"
    fi
  done
fi
echo

# ----------------------------------------------------------- commit ordering
echo "## Test committed before implementation"
if ! git rev-parse --verify --quiet "$BASE_REF" >/dev/null; then
  echo "  CANNOT CHECK  base ref '$BASE_REF' does not exist. Set BASE_REF and re-run."
  UNCHECKABLE=1
else
  RANGE="$BASE_REF..HEAD"
  MIXED=0
  TEST_FIRST=1
  SEEN_TEST=0
  SEEN_MAIN=0
  for sha in $(git rev-list --reverse "$RANGE"); do
    files=$(git show --name-only --pretty=format: "$sha")
    has_test=$(echo "$files" | grep -cE '^src/test/')
    has_main=$(echo "$files" | grep -cE '^src/main/java/')
    if [ "$has_test" -gt 0 ] && [ "$has_main" -gt 0 ]; then
      MIXED=1
      echo "  UNVERIFIABLE  $(git log -1 --format='%h %s' "$sha")"
      echo "                test and production code in the same commit — order not observable"
    elif [ "$has_main" -gt 0 ]; then
      SEEN_MAIN=1
      if [ "$SEEN_TEST" -eq 0 ]; then
        TEST_FIRST=0
        echo "  DRIFT         $(git log -1 --format='%h %s' "$sha")"
        echo "                production code committed with no preceding test commit"
      fi
    elif [ "$has_test" -gt 0 ]; then
      SEEN_TEST=1
    fi
  done
  if [ "$SEEN_TEST" -eq 0 ] && [ "$SEEN_MAIN" -eq 0 ] && [ "$MIXED" -eq 0 ]; then
    echo "  INFO          no Java source touched in $RANGE"
  elif [ "$MIXED" -eq 1 ]; then
    echo "  VERDICT       order not verifiable for at least one commit."
    echo "                Reported as unverifiable, never as compliant."
    UNCHECKABLE=1
  elif [ "$SEEN_MAIN" -eq 0 ]; then
    echo "  INFO          no production commit in $RANGE — nothing to order."
    echo "                This is not a pass: the check had nothing to look at."
  elif [ "$TEST_FIRST" -eq 1 ]; then
    echo "  OK            every production commit is preceded by a test commit"
  else
    DRIFT=1
  fi
fi
echo

# ----------------------------------------------------- declared task artefacts
echo "## Checked tasks that name a file"
MISSING=0
CHECKED=0
while IFS= read -r line; do
  for path in $(echo "$line" | grep -oE '(src|docs|modules)/[][A-Za-z0-9_./{}-]+\.[a-z]+'); do
    case "$path" in *'['*|*'{'*) continue ;; esac
    CHECKED=$((CHECKED + 1))
    if [ ! -e "$path" ]; then
      id=$(echo "$line" | grep -oE 'T[0-9]+' | head -1)
      echo "  DRIFT         $id claims $path — file does not exist"
      MISSING=1
      DRIFT=1
    fi
  done
done < <(grep -E '^- \[[xX]\] T[0-9]+ ' "$TASKS")
if [ "$CHECKED" -eq 0 ]; then
  echo "  INFO          no checked task names a concrete path"
elif [ "$MISSING" -eq 0 ]; then
  echo "  OK            $CHECKED declared path(s) exist"
fi
echo

# --------------------------------------------------------------------- verdict
echo "-----------------------------------------------------------"
if [ "$UNCHECKABLE" -eq 1 ]; then
  echo "VERDICT: INCOMPLETE — some checks could not run. This is not a pass."
  exit 2
elif [ "$DRIFT" -eq 1 ]; then
  echo "VERDICT: DRIFT — see the lines marked DRIFT above."
  exit 1
else
  echo "VERDICT: no implementation drift detected."
  echo "         Mechanical checks only. Whether the code does what the ticket"
  echo "         asked is a separate, fallible judgement — see /speckit.converge."
  exit 0
fi
