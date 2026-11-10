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

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)" || exit 2
[ -n "$REPO_ROOT" ] || exit 2
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

# Where production and test code live. The defaults match any module depth and
# any JVM language; a project laid out otherwise sets both variables.
MAIN_RE="${SPECIFY_MAIN_RE:-(^|/)src/main/}"
TEST_RE="${SPECIFY_TEST_RE:-(^|/)src/test/}"
# Paths that are never code: a range touching only these has nothing to order.
NOT_CODE_RE='(^|/)(specs|docs)/|^\.(specify|opencode|github)/|\.md$|(^|/)\.gitignore$'

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
    # Evidence is the pasted tool output: the fenced code blocks that follow the
    # gate task, up to the next task line. Prose around them proves nothing.
    region=$(awk -v start="$ln" 'NR>start { if ($0 ~ /^- \[[ xX]\] T[0-9]+ /) exit; print }' "$TASKS")
    evidence=$(echo "$region" | awk '/^[[:space:]]*```/ { inside = !inside; next } inside')
    if [ -z "$(echo "$region" | tr -d '[:space:]')" ]; then
      echo "  DRIFT         $id checked but no output pasted underneath."
      echo "                A gate without evidence is a claim, not a proof."
      DRIFT=1
    elif [ -z "$(echo "$evidence" | tr -d '[:space:]')" ]; then
      echo "  DRIFT         $id checked, but no fenced code block holds the pasted output."
      echo "                A sentence saying it failed is a claim, not a proof."
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
  SEEN_OTHER=0
  for sha in $(git rev-list --reverse --first-parent --no-merges "$RANGE"); do
    # One "STATUS<TAB>PATH" line per file; a rename keeps its new path. A
    # deleted test proves nothing was written first, so it does not count.
    changes=$(git -c core.quotePath=false show --name-status --pretty=format: "$sha" \
      | awk -F'\t' 'NF >= 2 { print substr($1, 1, 1) "\t" $NF }')
    has_test=$(echo "$changes" | awk -F'\t' -v re="$TEST_RE" '$1 != "D" && $2 ~ re' | grep -c .)
    has_main=$(echo "$changes" | awk -F'\t' -v re="$MAIN_RE" '$2 ~ re' | grep -c .)
    has_other=$(echo "$changes" \
      | awk -F'\t' -v m="$MAIN_RE" -v t="$TEST_RE" -v n="$NOT_CODE_RE" '$2 !~ m && $2 !~ t && $2 !~ n' \
      | grep -c .)
    [ "$has_other" -gt 0 ] && SEEN_OTHER=1
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
  if [ "$SEEN_TEST" -eq 0 ] && [ "$SEEN_MAIN" -eq 0 ] && [ "$MIXED" -eq 0 ] && [ "$SEEN_OTHER" -eq 1 ]; then
    echo "  CANNOT CHECK  $RANGE changes code, but none of it under $MAIN_RE or $TEST_RE."
    echo "                Set SPECIFY_MAIN_RE and SPECIFY_TEST_RE to this project's layout."
    UNCHECKABLE=1
  elif [ "$SEEN_TEST" -eq 0 ] && [ "$SEEN_MAIN" -eq 0 ] && [ "$MIXED" -eq 0 ]; then
    echo "  INFO          no source touched in $RANGE"
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
set -f
while IFS= read -r line; do
  for path in $(echo "$line" | grep -oE '([A-Za-z0-9_.-]+/)+[][A-Za-z0-9_.{}-]+\.[A-Za-z0-9]+'); do
    case "$path" in *'['*|*'{'*) continue ;; esac
    case "$line" in *"://$path"*) continue ;; esac
    CHECKED=$((CHECKED + 1))
    if [ ! -e "$path" ]; then
      id=$(echo "$line" | grep -oE 'T[0-9]+' | head -1)
      echo "  DRIFT         $id claims $path — file does not exist"
      MISSING=1
      DRIFT=1
    fi
  done
done < <(grep -E '^- \[[xX]\] T[0-9]+ ' "$TASKS")
set +f
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
