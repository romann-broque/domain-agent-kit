#!/usr/bin/env bash
# Mechanical traceability check.
#
# Answers one kind of question only: "does every element of the spec appear
# downstream?". These are joins. They are true or false, and no judgement is
# involved. Anything requiring interpretation belongs to /speckit.converge or to
# the code-reviewer skill, never here.
#
# Design rule: fail loudly. If the structure is not recognised, say
# "I could not check", never "0 drift". A silent parser that finds nothing is
# indistinguishable from a clean result, and that is the worst possible output.
#
# Usage: verify-traceability.sh [feature-directory]
# Exit:  0 = no drift, 1 = drift found, 2 = could not check

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT" || exit 2

FEATURE_DIR="${1:-}"
if [ -z "$FEATURE_DIR" ] && [ -f .specify/feature.json ]; then
  FEATURE_DIR="$(sed -n 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .specify/feature.json)"
fi

if [ -z "$FEATURE_DIR" ]; then
  echo "CANNOT CHECK: no feature directory given and .specify/feature.json is absent or unreadable." >&2
  echo "  Usage: $0 specs/<feature-dir>" >&2
  exit 2
fi

SPEC="$FEATURE_DIR/spec.md"
TASKS="$FEATURE_DIR/tasks.md"
SPEC_NUMBER="$(basename "$FEATURE_DIR" | grep -oE '^[0-9]{3}')"

for f in "$SPEC" "$TASKS"; do
  if [ ! -f "$f" ]; then
    echo "CANNOT CHECK: $f does not exist. Run /speckit.specify and /speckit.tasks first." >&2
    exit 2
  fi
done

DRIFT=0
UNCHECKABLE=0

echo "TRACEABILITY — $FEATURE_DIR"
echo

# ---------------------------------------------------------------- source ticket
echo "## Source ticket"
if ! grep -q '^## Source Ticket' "$SPEC"; then
  echo "  CANNOT CHECK  spec.md has no '## Source Ticket' section — template not applied."
  UNCHECKABLE=1
elif grep -q '\[PASTE THE TICKET VERBATIM\]' "$SPEC"; then
  echo "  DRIFT         the ticket was never pasted; the placeholder is still there."
  echo "                Every check below compares against an interpretation."
  DRIFT=1
else
  echo "  OK            present"
fi
echo

# ------------------------------------------------- functional requirements
echo "## Functional requirements covered by tasks"
FRS=$(grep -oE '\*\*FR-[0-9]{3}\*\*' "$SPEC" | tr -d '*' | sort -u)
if [ -z "$FRS" ]; then
  echo "  CANNOT CHECK  no FR-NNN found in spec.md. Either the spec has no numbered"
  echo "                requirements, or the numbering convention changed."
  UNCHECKABLE=1
else
  for fr in $FRS; do
    hits=$(grep -cE "^- \[[ xX]\] T[0-9]+ .*$fr([^0-9]|$)" "$TASKS")
    if [ "$hits" -eq 0 ]; then
      echo "  DRIFT         $fr -> no task references it"
      DRIFT=1
    else
      echo "  OK            $fr -> $hits task(s)"
    fi
  done
fi
echo

# --------------------------------------------------------------- user stories
echo "## User stories covered by tasks"
USER_STORIES=$(grep -oE '^### User Story [0-9]+' "$SPEC" | grep -oE '[0-9]+$' | sort -un)
if [ -z "$USER_STORIES" ]; then
  echo "  CANNOT CHECK  no '### User Story N' heading found in spec.md."
  UNCHECKABLE=1
else
  for n in $USER_STORIES; do
    tasks=$(grep -cE "^- \[[ xX]\] T[0-9]+ .*\[US$n\]" "$TASKS")
    if [ "$tasks" -eq 0 ]; then
      echo "  DRIFT         US$n -> no task tagged [US$n]"
      DRIFT=1
    else
      echo "  OK            US$n -> $tasks task(s)"
    fi
  done
fi
echo

# ------------------------------------------------------------- untagged tasks
echo "## Tasks tagged to a user story"
UNTAGGED=$(grep -nE '^- \[[ xX]\] T[0-9]+ ' "$TASKS" | grep -vE '\[US[0-9]+\]' | wc -l | tr -d ' ')
echo "  INFO          $UNTAGGED task(s) carry no [USn] tag"
echo "                (setup, foundational and polish tasks legitimately have none;"
echo "                 an implementation task without one cannot be traced)"
echo

# ----------------------------------------------------------------- test gates
echo "## Test gates"
GATES=$(grep -cE '\[GATE\]' "$TASKS")
if [ "$GATES" -eq 0 ]; then
  echo "  DRIFT         no [GATE] task in tasks.md — the test-first barrier is absent."
  echo "                Constitution Principle II is not enforceable for this feature."
  DRIFT=1
else
  echo "  OK            $GATES gate task(s)"
  for n in $USER_STORIES; do
    g=$(grep -cE "^- \[[ xX]\] T[0-9]+ \[US$n\] .*\[GATE\]" "$TASKS")
    if [ "$g" -eq 0 ]; then
      echo "  DRIFT         US$n -> no [GATE] task"
      DRIFT=1
    fi
  done
fi
echo

# -------------------------------------------------------- scenario coverage
echo "## Acceptance scenarios covered by feature files"
BEHAVIORS_DIR="src/test/resources/behaviors"
if [ ! -d "$BEHAVIORS_DIR" ]; then
  echo "  CANNOT CHECK  $BEHAVIORS_DIR does not exist."
  UNCHECKABLE=1
else
  # Feature files are discovered on disk; one belongs to this spec when tasks.md names
  # it, by path or by file name. Several specs share the directory, so a file that
  # tasks.md does not name cannot be attributed.
  ON_DISK=$(find "$BEHAVIORS_DIR" -type f -name '*.feature' | sort)
  FEATURES=$(echo "$ON_DISK" | while IFS= read -r f; do
    [ -n "$f" ] && grep -qF "$(basename "$f")" "$TASKS" && echo "$f"
  done)
  if [ -z "$FEATURES" ] && [ -z "$USER_STORIES" ]; then
    echo "  INFO          the spec declares no user story — scenario coverage not checked"
  elif [ -z "$FEATURES" ]; then
    if [ -z "$ON_DISK" ]; then
      echo "  CANNOT CHECK  $BEHAVIORS_DIR holds no .feature file."
    else
      echo "  CANNOT CHECK  no .feature file under $BEHAVIORS_DIR is named in tasks.md,"
      echo "                so none can be attributed to this spec. Name it in the task that writes it."
    fi
    UNCHECKABLE=1
  else
    for f in $FEATURES; do
      if ! head -5 "$f" | grep -q '^# Covers:'; then
        echo "  UNVERIFIABLE  $f has no '# Covers:' header — coverage cannot be checked."
        UNCHECKABLE=1
      fi
      # A rule's '# Covers:' must sit right above its 'Rule:' (blank lines and tags aside),
      # and must be qualified by spec number when the header is.
      misplaced=$(awk '
        NR <= 5 && /^# Covers:/ { qualified = ($0 ~ /[0-9][0-9][0-9]:/); next }
        /^[[:space:]]*# Covers:/ {
          if (pending) print FILENAME ":" pendingLine " is not right above a Rule:"
          if (qualified && $0 !~ /[0-9][0-9][0-9]:/) print FILENAME ":" NR " is not qualified by spec number, as its header is"
          pending = 1; pendingLine = NR; next
        }
        /^[[:space:]]*Rule:/ { pending = 0; next }
        /^[[:space:]]*$/ || /^[[:space:]]*@/ { next }
        pending { print FILENAME ":" pendingLine " is not right above a Rule:"; pending = 0 }
        END { if (pending) print FILENAME ":" pendingLine " is not right above a Rule:" }' "$f")
      if [ -n "$misplaced" ]; then
        echo "$misplaced" | while read -r line; do echo "  UNVERIFIABLE  the # Covers: line at $line"; done
        UNCHECKABLE=1
      fi
    done
    for n in $USER_STORIES; do
      # A story is claimed by any '# Covers:' line, header or rule, once scoped to this spec.
      covering=""
      for f in $FEATURES; do
        if awk -v us="US$n" -v spec="$SPEC_NUMBER" '
          function scoped(line,   parts, count, i, group) {
            if (line !~ /[0-9][0-9][0-9]:/) return line
            sub(/^[[:space:]]*# Covers:[[:space:]]*/, "", line)
            count = split(line, parts, ";")
            for (i = 1; i <= count; i++) {
              group = parts[i]
              sub(/^[[:space:]]+/, "", group)
              if (index(group, spec ":") == 1) return substr(group, length(spec) + 2)
            }
            return ""
          }
          /^[[:space:]]*# Covers:/ && scoped($0) ~ ("(^|[^A-Za-z0-9])" us "([^0-9]|$)") { found = 1 }
          END { exit found ? 0 : 1 }' "$f"; then
          covering="$covering $f"
        fi
      done
      if [ -z "$covering" ]; then
        echo "  INFO          US$n -> no feature file claims to cover it yet"
        continue
      fi
      # One acceptance scenario must map to exactly one Cucumber scenario.
      declared=$(awk -v us="$n" '
        $0 ~ "^### User Story " us " " {inus=1; next}
        inus && /^### / {inus=0}
        inus && /^[0-9]+\. (✅ |❌ )?\*\*(Given|When)\*\*/ {c++}
        END {print c+0}' "$SPEC")
      # A feature may hold the rules of several stories: a '# Covers:' line right above a
      # 'Rule:' narrows that rule to its own stories; without one, the rule follows the header.
      # A line touched by several specs qualifies each group by its spec number
      # ('# Covers: 002: US2, FR-004; 005: US1, FR-003'); only this spec's group is read.
      written=0
      for f in $covering; do
        written=$((written + $(awk -v us="US$n" -v spec="$SPEC_NUMBER" '
          function scoped(line,   parts, count, i, group) {
            if (line !~ /[0-9][0-9][0-9]:/) return line
            sub(/^[[:space:]]*# Covers:[[:space:]]*/, "", line)
            count = split(line, parts, ";")
            for (i = 1; i <= count; i++) {
              group = parts[i]
              sub(/^[[:space:]]+/, "", group)
              if (index(group, spec ":") == 1) return substr(group, length(spec) + 2)
            }
            return ""
          }
          function covers(line) { return scoped(line) ~ ("(^|[^A-Za-z0-9])" us "([^0-9]|$)") }
          NR <= 5 && /^# Covers:/ { header = $0; next }
          /^[[:space:]]*# Covers:/ { pending = $0; next }
          /^[[:space:]]*Rule:/ { rule = (pending != "" ? pending : header); pending = ""; next }
          /^[[:space:]]*Scenario( Outline| Template)?:/ { if (covers(rule != "" ? rule : header)) c++ }
          END { print c+0 }' "$f")))
      done
      if [ "$declared" -eq 0 ]; then
        echo "  CANNOT CHECK  US$n -> no Given/When/Then acceptance scenario parsed in spec.md"
        UNCHECKABLE=1
      elif [ "$declared" -ne "$written" ]; then
        echo "  DRIFT         US$n -> $declared acceptance scenario(s), $written Cucumber scenario(s)"
        DRIFT=1
      else
        echo "  OK            US$n -> $declared scenario(s), matched"
      fi
    done
  fi
fi
echo

# --------------------------------------------------------------------- verdict
echo "-----------------------------------------------------------"
if [ "$UNCHECKABLE" -eq 1 ]; then
  echo "VERDICT: INCOMPLETE — some checks could not run (see CANNOT CHECK / UNVERIFIABLE)."
  echo "         This is not a pass. Fix what blocks the check, then run again."
  exit 2
elif [ "$DRIFT" -eq 1 ]; then
  echo "VERDICT: DRIFT — see the lines marked DRIFT above."
  exit 1
else
  echo "VERDICT: no traceability drift detected."
  echo "         Mechanical checks only. Nothing here says the content is correct."
  exit 0
fi
