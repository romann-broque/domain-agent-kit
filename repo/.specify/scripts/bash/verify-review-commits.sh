#!/usr/bin/env bash
# Mechanical check on the shape of a branch's commits.
#
# Answers: "did the changes made after a review go through the chain?".
# Not "was the review comment right" — that is a judgement, made by the
# review-triage skill and approved by a human.
#
# A comment that changes what the code must do is a spec change: it is written in
# the spec, turned into a failing test, then implemented. A commit typed refactor:
# claims nothing observable changed; if it edits a scenario, it says otherwise.
#
# Usage: verify-review-commits.sh [base-ref] [head-ref]
#        base-ref defaults to $BASE_REF, then origin/main. Pass the PR's base branch.
# Exit:  0 = no drift, 1 = drift found, 2 = could not check

set -u

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "CANNOT CHECK: not inside a git repository." >&2
  exit 2
}
cd "$REPO_ROOT" || exit 2

BASE_REF="${1:-${BASE_REF:-origin/main}}"
HEAD_REF="${2:-HEAD}"

CONVENTIONAL='^((feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|tech)(\([^)]+\))?!?: .+|Revert ".+")$'
SPEC_OWNED='(\.feature$|^specs/[^/]+/(spec|plan|tasks|data-model|research)\.md$|^specs/[^/]+/(contracts|checklists)/|^\.specify/memory/)'
SCENARIO_LINE='^[+-][[:space:]]*(Feature|Background|Rule|Scenario Outline|Scenario Template|Scenarios|Scenario|Examples|Example|Given|When|Then|And|But)([[:space:]:]|$)|^[+-].*(FR-[0-9]{3}|\*\*(Given|When|Then)\*\*)'
GHERKIN_TABLE_ROW='^[+-][[:space:]]*\|'
# Where production and test code live — same defaults as verify-implementation.sh.
MAIN_RE="${SPECIFY_MAIN_RE:-(^|/)src/main/}"
TEST_RE="${SPECIFY_TEST_RE:-(^|/)src/test/}"

DRIFT=0
UNCHECKABLE=0

for ref in "$BASE_REF" "$HEAD_REF"; do
  if ! git rev-parse --verify --quiet "$ref^{commit}" >/dev/null; then
    echo "CANNOT CHECK: ref '$ref' does not exist. Pass the PR's base branch, e.g. origin/feat/…" >&2
    exit 2
  fi
done

FORK_POINT="$(git merge-base "$BASE_REF" "$HEAD_REF")" || {
  echo "CANNOT CHECK: '$BASE_REF' and '$HEAD_REF' share no history." >&2
  exit 2
}

RANGE="$BASE_REF..$HEAD_REF"
COMMITS="$(git rev-list --reverse --first-parent --no-merges "$RANGE")"

label() { git log -1 --format='%h %s' "$1"; }
# Unquoted paths: git's default C-quotes non-ASCII names, which no pattern matches.
files_of() { git -c core.quotePath=false show --name-only --format= "$1"; }
# Test paths the commit adds or modifies — a deleted test proves nothing.
tests_written_by() {
  git -c core.quotePath=false show --name-status --format= "$1" \
    | awk -F'\t' -v re="$TEST_RE" 'NF >= 2 && $1 !~ /^D/ && $NF ~ re'
}
# Diff of the given paths only, one path per line on stdin.
diff_of() {
  local sha="$1" paths=() p
  while IFS= read -r p; do [ -n "$p" ] && paths+=("$p"); done
  git -c core.quotePath=false show --format= -U0 "$sha" -- "${paths[@]}"
}
type_of() { git log -1 --format=%s "$1" | sed -nE 's/^([a-z]+)(\([^)]*\))?!?: .*/\1/p'; }

echo "REVIEW COMMITS — $RANGE"
echo

# ------------------------------------------------------------- commit messages
echo "## Commit messages follow Conventional Commits"
PARSED=0
for sha in $COMMITS; do
  if git log -1 --format=%s "$sha" | grep -qE "$CONVENTIONAL"; then
    PARSED=$((PARSED + 1))
  else
    echo "  UNPARSABLE    $(label "$sha")"
    echo "                its type is unknown, so what it claims cannot be checked"
    UNCHECKABLE=1
  fi
done
if [ -z "$COMMITS" ]; then
  echo "  INFO          no commit in $RANGE — nothing to look at. This is not a pass."
elif [ "$UNCHECKABLE" -eq 0 ]; then
  echo "  OK            $PARSED commit(s) parsed"
fi
echo

# ----------------------------------------------- refactor leaves the spec alone
echo "## refactor: and style: leave scenarios and specs alone"
FOUND=0
for sha in $COMMITS; do
  case "$(type_of "$sha")" in refactor|style) ;; *) continue ;; esac
  owned="$(files_of "$sha" | grep -E "$SPEC_OWNED")"
  if [ -n "$owned" ]; then
    FOUND=1
    DRIFT=1
    echo "  DRIFT         $(label "$sha")"
    echo "                claims no behaviour change, yet edits:"
    echo "$owned" | sed 's/^/                  /'
  fi
done
[ "$FOUND" -eq 0 ] && echo "  OK            no refactor: or style: commit edits a scenario or a spec"
echo

# ------------------------------------------ a changed scenario is tested first
echo "## A changed scenario or requirement is tested before it is implemented"
FOUND=0
# One line per change still waiting for its test: "<sha> <FR ids it touches>".
PENDING=""
# Requirements a test commit claims: FR ids in the test files it writes.
claimed_by() {
  local sha="$1" p
  tests_written_by "$sha" | awk -F'\t' '{ print $NF }' | while IFS= read -r p; do
    git -c core.quotePath=false show "$sha:$p" 2>/dev/null
  done | grep -oE 'FR-[0-9]{3,}' | sort -u
}
# Keeps the pending changes a test commit does not answer. A change naming no FR
# is answered by any test written; one naming FRs needs a test covering one of them.
discharge() {
  local claimed="$1" psha pfrs fr kept=""
  while read -r psha pfrs; do
    [ -z "$psha" ] && continue
    if [ -n "$pfrs" ]; then
      for fr in ${pfrs//,/ }; do
        if echo "$claimed" | grep -qxF "$fr"; then pfrs=""; psha=""; break; fi
      done
    else
      psha=""
    fi
    [ -n "$psha" ] && kept="$kept$psha $pfrs"$'\n'
  done <<< "$PENDING"
  PENDING="$kept"
}
pending_shas() { echo "$PENDING" | awk 'NF { printf "%s%s", (n++ ? ", " : ""), $1 }'; }

for sha in $COMMITS; do
  files="$(files_of "$sha")"
  has_main=$(echo "$files" | grep -cE "$MAIN_RE")
  has_test=$(tests_written_by "$sha" | grep -c .)
  owned="$(echo "$files" | grep -E "$SPEC_OWNED")"
  features="$(echo "$owned" | grep -E '\.feature$')"
  changes_scenario=0
  changed_frs=""
  if [ -n "$owned" ]; then
    changed="$(echo "$owned" | diff_of "$sha" | grep -vE '^(\+\+\+|---) ' | grep -E "$SCENARIO_LINE")"
    if [ -n "$changed" ]; then
      changes_scenario=1
      changed_frs="$(echo "$changed" | grep -oE 'FR-[0-9]{3,}' | sort -u | paste -sd, -)"
    fi
  fi
  if [ "$changes_scenario" -eq 0 ] && [ -n "$features" ]; then
    if echo "$features" | diff_of "$sha" | grep -vE '^(\+\+\+|---) ' | grep -qE "$GHERKIN_TABLE_ROW"; then
      changes_scenario=1
    fi
  fi
  if [ "$changes_scenario" -eq 1 ] && [ "$has_main" -gt 0 ]; then
    FOUND=1
    DRIFT=1
    echo "  DRIFT         $(label "$sha")"
    echo "                a scenario or requirement and production code change in one commit:"
    echo "                the failing test cannot have been observed"
    continue
  fi
  if [ "$has_main" -gt 0 ] && [ -n "$(pending_shas)" ]; then
    FOUND=1
    DRIFT=1
    echo "  DRIFT         $(label "$sha")"
    echo "                implements the change of $(pending_shas) with no test commit covering it in between"
    PENDING=""
  fi
  if [ "$changes_scenario" -eq 1 ] && [ "$has_test" -eq 0 ]; then
    PENDING="$PENDING$(git log -1 --format=%h "$sha") $changed_frs"$'\n'
  elif [ "$has_test" -gt 0 ] && [ "$has_main" -eq 0 ]; then
    discharge "$(claimed_by "$sha")"
  fi
done
[ -n "$(pending_shas)" ] && echo "  INFO          $(pending_shas) change(s) a scenario or requirement; nothing implements it yet"
[ "$FOUND" -eq 0 ] && echo "  OK            every implemented scenario or requirement change was tested first"
echo

# ---------------------------------------------------- covers groups never lost
echo "## Covers lines keep every group the base had"

covers_groups() {
  git show "$1:$2" 2>/dev/null | awk '
    /(#|\/\/)[[:space:]]*Covers:/ {
      line = $0
      sub(/.*Covers:[[:space:]]*/, "", line)
      n = split(line, groups, ";")
      for (i = 1; i <= n; i++) {
        g = groups[i]
        q = ""
        if (match(g, /^[[:space:]]*[0-9][0-9][0-9][0-9]*:/)) {
          q = substr(g, RSTART, RLENGTH)
          gsub(/[[:space:]:]/, "", q)
          g = substr(g, RSTART + RLENGTH)
        }
        m = split(g, toks, ",")
        out = ""
        for (j = 1; j <= m; j++) {
          t = toks[j]
          gsub(/[[:space:]]/, "", t)
          if (t != "") out = out (out == "" ? "" : ",") t
        }
        if (out != "") print q "|" out
      }
    }' | sort -u
}

group_kept() {
  local qualifier="$1" tokens="$2" candidates="$3" hq htoks t missing all
  if [ -z "$qualifier" ]; then
    all=""
    while IFS='|' read -r hq htoks; do
      [ -n "$htoks" ] && all="$all,$htoks"
    done <<< "$candidates"
    for t in ${tokens//,/ }; do
      case "$all," in *",$t,"*) ;; *) return 1 ;; esac
    done
    return 0
  fi
  while IFS='|' read -r hq htoks; do
    [ -z "$htoks" ] && continue
    [ "$hq" != "$qualifier" ] && continue
    missing=0
    for t in ${tokens//,/ }; do
      case ",$htoks," in *",$t,"*) ;; *) missing=1; break ;; esac
    done
    [ "$missing" -eq 0 ] && return 0
  done <<< "$candidates"
  return 1
}

FOUND=0
COMPARED=0
COVERED_ON_BASE=0
# Where each covered file of the base lives at HEAD, following renames.
RENAMES="$(git -c core.quotePath=false diff --find-renames --name-status "$FORK_POINT" "$HEAD_REF" -- src/test \
  | awk -F'\t' '$1 ~ /^R/ { print $2 "\t" $3 }')"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  COVERED_ON_BASE=$((COVERED_ON_BASE + 1))
  at_head="$f"
  if ! git cat-file -e "$HEAD_REF:$f" 2>/dev/null; then
    at_head="$(echo "$RENAMES" | awk -F'\t' -v old="$f" '$1 == old { print $2; exit }')"
    if [ -z "$at_head" ]; then
      echo "  CANNOT CHECK  $f removed — its covers groups have nowhere to be kept"
      echo "                confirm in the review-triage card that the requirement is covered elsewhere"
      UNCHECKABLE=1
      continue
    fi
  fi
  COMPARED=$((COMPARED + 1))
  head_groups="$(covers_groups "$HEAD_REF" "$at_head")"
  while IFS='|' read -r q toks; do
    [ -z "$toks" ] && continue
    if ! group_kept "$q" "$toks" "$head_groups"; then
      FOUND=1
      DRIFT=1
      echo "  DRIFT         $at_head lost the ${q:-unqualified} group: $toks"
      echo "                a later spec qualifies every group (002: …; 005: …), it never overwrites one"
    fi
  done <<< "$(covers_groups "$FORK_POINT" "$f")"
done <<< "$(git -c core.quotePath=false grep -lE '(#|//)[[:space:]]*Covers:' "$FORK_POINT" -- src/test | sed "s|^$FORK_POINT:||")"
if [ "$COVERED_ON_BASE" -eq 0 ]; then
  echo "  INFO          no covers line on the base to compare"
elif [ "$FOUND" -eq 0 ] && [ "$COMPARED" -gt 0 ]; then
  echo "  OK            $COMPARED file(s) keep every group"
fi
echo

# --------------------------------------------------------------------- verdict
echo "-----------------------------------------------------------"
if [ "$UNCHECKABLE" -eq 1 ]; then
  echo "VERDICT: INCOMPLETE — some commits could not be read. This is not a pass."
  exit 2
elif [ "$DRIFT" -eq 1 ]; then
  echo "VERDICT: DRIFT — see the lines marked DRIFT above."
  exit 1
else
  echo "VERDICT: no review drift detected."
  echo "         Mechanical checks only. Whether each comment was classified right"
  echo "         is a judgement — see the review-triage card."
  exit 0
fi
