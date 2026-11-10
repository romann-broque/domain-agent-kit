#!/usr/bin/env bash
# Mechanical checks on docs/domain/.
#
# Doctrine, fixed by `.opencode/commands/workflow.verify.md`:
#   - the output is meant to be reported verbatim, never summarised;
#   - there is no single global tick, and no percentage. Each check reports its
#     own findings or its own silence;
#   - exit 0 = every check that ran found nothing, 1 = findings,
#     2 = a structure was not recognised. Exit 2 is NOT a pass: a check that
#     found nothing because it looked nowhere is worse than no check at all.
#
# Nothing here is a judgement on whether the domain knowledge is *right*. These
# are joins between files: true or false.
#
# Implementation constraints:
#   - bash 3.2 (macOS): no `declare -A`, no `mapfile`, no `${var,,}`;
#   - `set -uo pipefail` and deliberately NOT `set -e`: the script must keep
#     going after a finding;
#   - every loop reads from a process substitution, never from a pipe. A `while`
#     loop on the receiving end of a pipe runs in a subshell, so the counters
#     incremented inside it are discarded and the script prints findings while
#     exiting 0 — the worst possible failure for a check whose whole value is
#     its exit code.
#
# Usage: verify-domain-base.sh
# Exit:  0 = no finding, 1 = findings, 2 = could not check

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)" || exit 2
[ -n "$REPO_ROOT" ] || exit 2
cd "$REPO_ROOT" || exit 2

BASE="docs/domain"
REGISTRY="$BASE/decision-points.md"
GLOSSARY="$BASE/glossary.md"
CONTEXT_MAP="$BASE/context-map.md"
CONTEXT_TEMPLATE=".specify/templates/domain-context-template.md"
STATUSES="EMPTY DRAFT AGREED REVIEWED STABLE"

# A cross-reference, per `docs/domain/README.md` § *Cross-references name a file
# and a section*: path in backticks, then the section title in asterisks, the
# whole thing on one physical line.
REF_RE='`[^`]+\.md` § \*[^*]+\*'

BT='`'

findings=0
unrecognised=0
nothings=0

finding() { printf '  FINDING           %s\n' "$1"; findings=$((findings + 1)); }
cannot()  { printf '  CANNOT CHECK      %s\n' "$1"; unrecognised=$((unrecognised + 1)); }
nocheck() { printf '  NOTHING TO CHECK  %s\n' "$1"; nothings=$((nothings + 1)); }
info()    { printf '  INFO              %s\n' "$1"; }
count()   { printf '  %-50s %s\n' "$1" "$2"; }
oneline() { tr '\n' ' ' < "$1" | sed 's/ *$//'; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/verify-domain-base.XXXXXX")" || exit 2
trap 'rm -rf "$TMP"' EXIT INT TERM

if [ ! -d "$BASE" ]; then
  printf 'CANNOT CHECK: %s does not exist. There is no domain base to verify.\n' "$BASE" >&2
  exit 2
fi

domain_files() { find "$BASE" -name '*.md' -type f | LC_ALL=C sort; }

# ---------------------------------------------------------------------------
# Check 5, and check 5 alone, scans wider than $BASE. Every other check is about
# the knowledge base itself and stays on $BASE.
#
# The cross-reference is what holds the documentation set together — one home,
# references everywhere else — and most of the pointers that now exist live
# outside the base: the skills an agent reads on every single run, the templates
# it fills, the constitution. A pointer that rots in a skill file is worse than
# one that rots in the base, because nobody proofreads a skill. A check that
# ignored them would be looking almost nowhere.
#
# The patterns live here once. The loop below expands them and the intro line of
# check 5 prints them, so the scope the output claims cannot drift from the scope
# actually scanned — the same reason the Counts section exists.
#
# This is bash 3.2 and `nullglob` is not set: a pattern that matches nothing
# arrives as its own literal text. The `-f` test drops it, so a path that does
# not exist is skipped silently rather than opened.
# ---------------------------------------------------------------------------
REF_SCAN_PATTERNS='.opencode/skills/*/SKILL.md
.opencode/commands/workflow.*.md
.specify/templates/domain-*-template.md
.specify/memory/constitution.md
AGENTS.md
docs/WORKFLOW.md'

ref_scan_files() {
  domain_files
  while IFS= read -r pat; do
    [ -n "$pat" ] || continue
    for p in $pat; do
      if [ -f "$p" ]; then printf '%s\n' "$p"; fi
    done
  done < <(printf '%s\n' "$REF_SCAN_PATTERNS")
}

trim() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

in_enum() {
  case " $STATUSES " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

# The first `domain-knowledge` block of a file, from its opening line to the
# first `-->`. Multi-line by construction: `head -1` cannot read it.
# The block is required to open the file — `docs/domain/README.md` says the
# header sits "at the very top", and that same file carries a second, illustrative
# block further down which must not be mistaken for its header.
provenance_block() {
  awk 'NR == 1 && /^[[:space:]]*<!--[[:space:]]*domain-knowledge/ { inb = 1 }
       inb { print }
       inb && /-->/ { exit }' "$1"
}

# Headings of a file, `#` markers and surrounding blanks stripped. Column 0 only:
# a heading indented inside a code block is an example, not a section.
heading_texts() {
  sed -n 's/^#\{1,6\}[[:space:]]\{1,\}//p' "$1" | sed 's/[[:space:]]*$//'
}

has_heading() { heading_texts "$1" | grep -qxF "$2"; }

# ---------------------------------------------------------------------------
# A markdown table, read by section heading. Emits one line per table row:
#   HEADER<TAB>cell<TAB>cell...        the first non-separator row
#   SEP<TAB>...                        the |---|---| row
#   PLACEHOLDER<TAB>...                every cell empty or an em dash
#   ROW<TAB>cell<TAB>cell...           a data row
# Backticks and surrounding blanks are stripped from every cell. Counting rows
# rather than grepping for a marker inside them is deliberate: a term written
# without backticks must still be counted, otherwise the count silently
# disagrees with the table it claims to describe.
# ---------------------------------------------------------------------------
md_table() {
  awk -v want="$2" -F'|' '
    $0 == want { sec = 1; next }
    /^## / && sec == 1 { sec = 0 }
    sec != 1 { next }
    /^[[:space:]]*\|/ {
      delete cells
      lo = 2; hi = NF - 1
      t = $NF; gsub(/^[ \t]+|[ \t]+$/, "", t); if (t != "") hi = NF
      if (hi < lo) next
      sep = 0; ph = 1; n = 0
      for (i = lo; i <= hi; i++) {
        c = $i
        gsub(/`/, "", c)
        gsub(/^[ \t]+|[ \t]+$/, "", c)
        cells[++n] = c
        if (c ~ /^:?-+:?$/) sep++
        if (c != "" && c != "—" && c != "-") ph = 0
      }
      if (n == 0) next
      if (sep == n) kind = "SEP"
      else if (!seenhdr) { kind = "HEADER"; seenhdr = 1 }
      else if (ph) kind = "PLACEHOLDER"
      else kind = "ROW"
      out = kind
      for (i = 1; i <= n; i++) out = out "\t" cells[i]
      print out
    }
  ' "$1"
}

# Index (1-based) of the column whose header cell is $1, in a HEADER line ($2).
header_index() {
  printf '%s\n' "$2" | awk -F'\t' -v want="$1" '
    { for (i = 2; i <= NF; i++) if ($i == want) { print i - 1; exit } }'
}

nth_cell() {
  printf '%s\n' "$1" | awk -F'\t' -v n="$2" '{ print $(n + 1) }'
}

word_to_int() {
  case "$1" in
    one) printf '1' ;; two) printf '2' ;; three) printf '3' ;;
    four) printf '4' ;; five) printf '5' ;; six) printf '6' ;;
    [0-9]|[0-9][0-9]) printf '%s' "$1" ;;
    *) printf '' ;;
  esac
}

printf 'DOMAIN BASE — %s\n' "$BASE"
printf 'Mechanical joins only. No global verdict: read every section.\n'
printf '\n'

# ===========================================================================
# Counts — emitted by the script so that no file, no human and no agent ever
# states one in prose again. A prose counter that disagreed with its own table
# is exactly the defect this section exists to make impossible.
# ===========================================================================
printf '== Counts\n'

n_files=$(domain_files | wc -l | tr -d ' ')
count 'markdown files in the base' "$n_files"

if [ ! -f "$GLOSSARY" ]; then
  cannot "$GLOSSARY not found; no term count and no per-term status count"
else
  md_table "$GLOSSARY" '## Terms' > "$TMP/glossary.tsv"
  g_header=$(grep '^HEADER	' "$TMP/glossary.tsv" | head -1)
  if [ -z "$g_header" ]; then
    cannot "$GLOSSARY: no table found under '## Terms'; terms cannot be counted"
  else
    g_status_col=$(header_index 'Status' "$g_header")
    g_term_col=$(header_index 'Term' "$g_header")
    n_terms=$(grep -c '^ROW	' "$TMP/glossary.tsv" | tr -d ' ')
    n_ph=$(grep -c '^PLACEHOLDER	' "$TMP/glossary.tsv" | tr -d ' ')
    count 'glossary terms' "$n_terms"
    count 'glossary placeholder rows (not counted as terms)' "$n_ph"
    if [ -z "$g_status_col" ] || [ -z "$g_term_col" ]; then
      cannot "$GLOSSARY: the '## Terms' table has no 'Term' and 'Status' column; per-term status cannot be read"
    elif [ "$n_terms" -eq 0 ]; then
      count 'glossary terms by status' 'no term to classify'
    else
      matched=0
      for s in $STATUSES; do
        c=0
        while IFS= read -r row; do
          v=$(nth_cell "$row" "$g_status_col")
          [ "$v" = "$s" ] && c=$((c + 1))
        done < <(grep '^ROW	' "$TMP/glossary.tsv")
        count "glossary terms with status $s" "$c"
        matched=$((matched + c))
      done
      count 'glossary terms whose status is outside the enumeration' \
            "$((n_terms - matched))"
    fi
  fi
fi

if [ ! -f "$CONTEXT_MAP" ]; then
  cannot "$CONTEXT_MAP not found; contexts cannot be counted"
else
  md_table "$CONTEXT_MAP" '## Contexts' > "$TMP/contexts.tsv"
  c_header=$(grep '^HEADER	' "$TMP/contexts.tsv" | head -1)
  if [ -z "$c_header" ]; then
    cannot "$CONTEXT_MAP: no table found under '## Contexts'; contexts cannot be counted"
  else
    count 'contexts named in context-map.md' \
          "$(grep -c '^ROW	' "$TMP/contexts.tsv" | tr -d ' ')"
  fi
fi

n_ctx_dirs=0
for d in "$BASE"/contexts/*/; do
  [ -d "$d" ] && n_ctx_dirs=$((n_ctx_dirs + 1))
done
count 'context directories under docs/domain/contexts/' "$n_ctx_dirs"

if [ ! -f "$REGISTRY" ]; then
  cannot "$REGISTRY not found; open points cannot be counted"
elif ! grep -q '^## Points' "$REGISTRY"; then
  cannot "$REGISTRY has no '## Points' section; the registry shape was not recognised"
else
  grep -E '^### OP-[0-9]+' "$REGISTRY" > "$TMP/ops.txt" 2>/dev/null || true
  n_ops=$(wc -l < "$TMP/ops.txt" | tr -d ' ')
  count 'open point entries' "$n_ops"
  if [ "$n_ops" -eq 0 ]; then
    count 'open point entries by state' 'no entry to classify'
  else
    : > "$TMP/opstates.txt"
    while IFS= read -r line; do
      op=$(printf '%s' "$line" | awk '{ print $2 }')
      st=$(awk -v op="$op" '
        $0 ~ "^### " op "([^0-9]|$)" { f = 1; next }
        f && /^### OP-/ { exit }
        f && /^[-*][[:space:]]*\*\*state\*\*[[:space:]]*:/ {
          l = $0
          sub(/^[-*][[:space:]]*\*\*state\*\*[[:space:]]*:[[:space:]]*/, "", l)
          gsub(/^[ \t]+|[ \t]+$/, "", l)
          print l; exit
        }' "$REGISTRY")
      if [ -z "$st" ]; then
        cannot "$REGISTRY: $op has no readable '- **state**:' field; it cannot be counted by state"
      else
        printf '%s\n' "$st" >> "$TMP/opstates.txt"
      fi
    done < "$TMP/ops.txt"
    if [ -s "$TMP/opstates.txt" ]; then
      while IFS= read -r pair; do
        c=$(printf '%s' "$pair" | awk '{ print $1 }')
        s=$(printf '%s' "$pair" | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
        count "open point entries with state $s" "$c"
      done < <(LC_ALL=C sort "$TMP/opstates.txt" | uniq -c)
    fi
  fi
fi
printf '\n'

# ===========================================================================
# 1. Every OP-n cited anywhere in the base has an entry.
#
#    It does not require that entry to be open. A resolved point stays citable —
#    that is the whole reason it is not deleted, per
#    `.specify/templates/domain-open-point-template.md`. The assertion "the point
#    this line depends on is still open" is true of a `[blocked: OP-n]` marker
#    and of nothing else, so it lives in check 2 instead.
# ===========================================================================
printf '== 1. Cited open points resolve to an entry\n'
if [ ! -f "$REGISTRY" ]; then
  cannot "$REGISTRY not found; every OP-n citation is unverifiable"
else
  grep -rhoE 'OP-[0-9]+' "$BASE" 2>/dev/null | LC_ALL=C sort -u > "$TMP/cited.txt" || true
  if [ ! -s "$TMP/cited.txt" ]; then
    nocheck "no OP-n is cited anywhere under $BASE; there is no citation to resolve"
  else
    info "distinct OP-n cited under $BASE: $(oneline "$TMP/cited.txt")"
    while IFS= read -r op; do
      where=$(grep -rnE "$op([^0-9]|\$)" "$BASE" 2>/dev/null \
              | cut -d: -f1,2 | tr '\n' ' ' | sed 's/ *$//')
      if ! grep -qE "^### $op([^0-9]|\$)" "$REGISTRY"; then
        finding "$op is cited but has no '### $op' entry in $REGISTRY — cited at: $where"
        continue
      fi
      state=$(awk -v op="$op" '
        $0 ~ "^### " op "([^0-9]|$)" { f = 1; next }
        f && /^### OP-/ { exit }
        f && /^[-*][[:space:]]*\*\*state\*\*[[:space:]]*:/ {
          sub(/^[-*][[:space:]]*\*\*state\*\*[[:space:]]*:[[:space:]]*/, "")
          gsub(/^[ \t]+|[ \t]+$/, "")
          print
          exit
        }' "$REGISTRY")
      case "$state" in
        open|resolved) : ;;
        '') cannot "$REGISTRY: $op has an entry but no readable '- **state**:' field" ;;
        *) cannot "$REGISTRY: the state of $op is neither open nor resolved: $state" ;;
      esac
    done < "$TMP/cited.txt"
  fi
fi
printf '\n'

# ===========================================================================
# 2. The direction that matters: every item named under `blocks:` carries
#    `[blocked: OP-n]` at its own point of definition — its glossary row, its
#    aggregate heading, its relationship bullet. One line, one marker, greppable.
#    An item suspended on an unanswered question that says nothing about it is
#    the defect the registry exists to prevent.
# ===========================================================================
printf '== 2. Items declared blocked carry their marker where they are defined\n'
if [ ! -f "$REGISTRY" ]; then
  cannot "$REGISTRY not found; marker symmetry is unverifiable in both directions"
else
  awk '
    /^### OP-[0-9]+/ { op = $2; st = "" }
    /^[-*][[:space:]]*\*\*state\*\*[[:space:]]*:/ {
      st = $0
      sub(/^[-*][[:space:]]*\*\*state\*\*[[:space:]]*:[[:space:]]*/, "", st)
      gsub(/^[ \t]+|[ \t]+$/, "", st)
    }
    /^[-*][[:space:]]*\*\*blocks\*\*[[:space:]]*:/ {
      if (st == "resolved") next
      line = $0
      sub(/^[-*][[:space:]]*\*\*blocks\*\*[[:space:]]*:/, "", line)
      sub(/[[:space:]]—.*$/, "", line)
      n = split(line, parts, ",")
      for (i = 1; i <= n; i++) {
        item = parts[i]
        gsub(/`/, "", item)
        gsub(/^[ \t]+|[ \t]+$/, "", item)
        if (item != "" && op != "") print op "\t" item
      }
    }
  ' "$REGISTRY" > "$TMP/blocks.tsv"

  if [ ! -s "$TMP/blocks.tsv" ]; then
    nocheck "no open point declares a 'blocks:' field; there is no blocked item to look for"
  else
    while IFS="$(printf '\t')" read -r op item; do
      [ -z "${item:-}" ] && continue
      if ! grep -rqF "[blocked: $op]" "$BASE" 2>/dev/null; then
        finding "$op declares it blocks \"$item\" but no line under $BASE carries [blocked: $op]"
      elif ! grep -rhF "[blocked: $op]" "$BASE" 2>/dev/null | grep -qF "$item"; then
        marked=$(grep -rnF "[blocked: $op]" "$BASE" 2>/dev/null | cut -d: -f1,2 | tr '\n' ' ' | sed 's/ *$//')
        finding "$op declares it blocks \"$item\" but no line carrying [blocked: $op] names it — marker found at: $marked"
      fi
    done < "$TMP/blocks.tsv"
  fi

  # The reverse direction, weaker but cheap: a marker that no registry entry
  # backs. It cannot name the item — an arbitrary definition line has no
  # mechanical "item" field — so it checks the entry, its state and its blocks
  # field. A marker pointing at a resolved point is the finding check 1 used to
  # raise: it is here that "the question is still open" is an assertion about the
  # line, and not about the registry quoting its own headings.
  grep -rhoE '\[blocked: OP-[0-9]+\]' "$BASE" 2>/dev/null \
    | sed 's/.*\(OP-[0-9]*\).*/\1/' | LC_ALL=C sort -u > "$TMP/marked.txt" || true
  if [ ! -s "$TMP/marked.txt" ]; then
    nocheck "no line under $BASE carries a [blocked: OP-n] marker; there is no marker to trace back"
  else
    while IFS= read -r op; do
      where=$(grep -rnF "[blocked: $op]" "$BASE" 2>/dev/null | cut -d: -f1,2 | tr '\n' ' ' | sed 's/ *$//')
      if ! grep -qE "^### $op([^0-9]|\$)" "$REGISTRY"; then
        finding "a line carries [blocked: $op] but $op has no entry in $REGISTRY — marker at: $where"
        continue
      fi
      state=$(awk -v op="$op" '
        $0 ~ "^### " op "([^0-9]|$)" { f = 1; next }
        f && /^### OP-/ { exit }
        f && /^[-*][[:space:]]*\*\*state\*\*[[:space:]]*:/ { print; exit }' "$REGISTRY")
      case "$state" in
        *resolved*)
          finding "a line carries [blocked: $op] but $op is resolved — the marker is stale, at: $where"
          continue ;;
      esac
      if ! awk -v op="$op" '
             $0 ~ "^### " op "([^0-9]|$)" { f = 1; next }
             f && /^### OP-/ { exit }
             f && /^[-*][[:space:]]*\*\*blocks\*\*[[:space:]]*:/ { found = 1; exit }
             END { exit(found ? 0 : 1) }' "$REGISTRY"; then
        finding "a line carries [blocked: $op] but $op declares no 'blocks:' field — marker at: $where"
      fi
    done < "$TMP/marked.txt"
  fi
fi
printf '\n'

# ===========================================================================
# 3. The machine-readable provenance block and the human-readable quote agree.
#    The block is multi-line: it is parsed from `<!-- domain-knowledge` to `-->`.
# ===========================================================================
printf '== 3. The provenance header agrees with its quote block\n'
info "source and status are both compared strictly: the quote repeats the block's value,"
info "  it does not rephrase or qualify it (docs/domain/README.md, provenance header rule)"
n_headers=0
n_pairs=0
while IFS= read -r f; do
  block=$(provenance_block "$f")
  if [ -z "$block" ]; then
    finding "$f does not open with a <!-- domain-knowledge ... --> provenance block"
    continue
  fi
  case "$block" in
    *'-->'*) : ;;
    *) cannot "$f: the domain-knowledge block is never closed by '-->'" ;;
  esac
  end_line=$(printf '%s\n' "$block" | wc -l | tr -d ' ')

  h_status=$(printf '%s\n' "$block" | sed -n 's/^[[:space:]]*status:[[:space:]]*\(.*\)$/\1/p' | head -1)
  h_status=$(trim "${h_status:-}")
  h_source=$(printf '%s\n' "$block" | sed -n 's/^[[:space:]]*source:[[:space:]]*\(.*\)$/\1/p' | head -1)
  h_source=$(trim "${h_source:-}")

  q_status=$(sed -n "${end_line},\$p" "$f" \
    | sed -n 's/^>[[:space:]]*\*\*Status\*\*:[[:space:]]*\(.*\)$/\1/p' | head -1)
  q_status=$(trim "${q_status:-}")
  q_source=$(sed -n "${end_line},\$p" "$f" \
    | sed -n 's/^>[[:space:]]*\*\*Source\*\*:[[:space:]]*\(.*\)$/\1/p' | head -1)
  q_source=$(trim "${q_source:-}")

  if [ -z "$h_status" ]; then
    cannot "$f: no 'status:' line inside the domain-knowledge block; agreement unverifiable"
  elif [ -z "$q_status" ]; then
    finding "$f: the block says status $h_status but no '> **Status**:' quote restates it"
  elif [ "$h_status" != "$q_status" ]; then
    finding "$f: the block says status '$h_status', the quote says '$q_status'"
  else
    n_pairs=$((n_pairs + 1))
  fi
  n_headers=$((n_headers + 1))

  if [ -n "$h_source" ] && [ -z "$q_source" ]; then
    finding "$f: the block carries 'source: $h_source' but no '> **Source**:' quote restates it"
  elif [ -n "$h_source" ] && [ -n "$q_source" ]; then
    [ "$h_source" = "$q_source" ] \
      || finding "$f: the block says source '$h_source', the quote says '$q_source'"
  fi
done < <(domain_files)
if [ "$n_headers" -eq 0 ]; then
  nocheck "no file under $BASE opens with a provenance block; there was no pair to compare"
else
  info "provenance blocks parsed: $n_headers — status pairs compared and in agreement: $n_pairs"
fi
printf '\n'

# ===========================================================================
# 4. Every status encountered belongs to the enumeration.
# ===========================================================================
printf '== 4. Every status belongs to the enumeration\n'
info "enumeration: $STATUSES"
seen_status=0
while IFS= read -r f; do
  block=$(provenance_block "$f")
  [ -z "$block" ] && continue
  s=$(trim "$(printf '%s\n' "$block" | sed -n 's/^[[:space:]]*status:[[:space:]]*\(.*\)$/\1/p' | head -1)")
  if [ -n "$s" ]; then
    seen_status=$((seen_status + 1))
    in_enum "$s" || finding "$f: provenance block status '$s' is not one of: $STATUSES"
  fi
  end_line=$(printf '%s\n' "$block" | wc -l | tr -d ' ')
  q=$(trim "$(sed -n "${end_line},\$p" "$f" \
      | sed -n 's/^>[[:space:]]*\*\*Status\*\*:[[:space:]]*\(.*\)$/\1/p' | head -1)")
  if [ -n "$q" ]; then
    seen_status=$((seen_status + 1))
    in_enum "$q" || finding "$f: quote block status '$q' is not one of: $STATUSES"
  fi
done < <(domain_files)

if [ -f "$TMP/glossary.tsv" ] && [ -n "${g_status_col:-}" ]; then
  while IFS= read -r row; do
    v=$(nth_cell "$row" "$g_status_col")
    t=$(nth_cell "$row" "${g_term_col:-1}")
    seen_status=$((seen_status + 1))
    in_enum "$v" || finding "$GLOSSARY: term '$t' carries status '$v', not one of: $STATUSES"
  done < <(grep '^ROW	' "$TMP/glossary.tsv")
fi

[ "$seen_status" -eq 0 ] && nocheck "no status value was found anywhere; there is nothing to match against the enumeration"
[ "$seen_status" -gt 0 ] && info "status values matched against the enumeration: $seen_status"
printf '\n'

# ===========================================================================
# 5. Every cross-reference resolves: the file exists, and the section title
#    appears as one of its headings. Heading level is ignored on purpose — a
#    reference survives a section being promoted or demoted, not renamed.
#
#    This check reads $REF_SCAN_PATTERNS as well as the base: see the comment on
#    that list. Most of the references that exist are not in the base, and a
#    check that looked only there would be looking almost nowhere.
# ===========================================================================
printf '== 5. Cross-references resolve to a file and a heading — scanned beyond the base\n'
info 'form: `<path/relative/to/repo/root.md>` § *<Section title>*, on one physical line'
info "scope: every .md file under $BASE, and outside it these paths, when they exist —"
while IFS= read -r pat; do
  [ -n "$pat" ] || continue
  info "         $pat"
done < <(printf '%s\n' "$REF_SCAN_PATTERNS")

ref_scan_files > "$TMP/reffiles.txt"
n_ref_files=$(wc -l < "$TMP/reffiles.txt" | tr -d ' ')

# One grep per file rather than a recursive grep: the file list is not a tree.
# `-H` forces the `file:line:` prefix that the parsing below relies on, which a
# recursive grep gave for free and a single-file grep does not.
: > "$TMP/refs.txt"
: > "$TMP/sections.txt"
while IFS= read -r f; do
  grep -HnoE "$REF_RE" "$f" >> "$TMP/refs.txt" 2>/dev/null
  grep -Hn '§' "$f" >> "$TMP/sections.txt" 2>/dev/null
done < "$TMP/reffiles.txt"

count 'files scanned for cross-references' "$n_ref_files"
count 'cross-references found' "$(wc -l < "$TMP/refs.txt" | tr -d ' ')"

# A reference broken across a line break is found by no grep. Every `§` must
# therefore belong to a parsable reference, or the check says so.
while IFS= read -r l; do
  src=${l%%:*}
  rest=${l#*:}
  lno=${rest%%:*}
  text=${rest#*:}
  n_sec=$(printf '%s\n' "$text" | grep -o '§' | wc -l | tr -d ' ')
  n_ref=$(printf '%s\n' "$text" | grep -oE "$REF_RE" | wc -l | tr -d ' ')
  if [ "$n_sec" -ne "$n_ref" ]; then
    cannot "$src:$lno: $n_sec '§' on this line but $n_ref parsable reference(s): $(trim "$text")"
  fi
done < "$TMP/sections.txt"

if [ ! -s "$TMP/refs.txt" ]; then
  nocheck "no cross-reference of the documented form was found in the $n_ref_files file(s) scanned"
else
  while IFS= read -r l; do
    src=${l%%:*}
    rest=${l#*:}
    lno=${rest%%:*}
    ref=${rest#*:}
    path=${ref#$BT}
    path=${path%%$BT*}
    title=${ref#*\*}
    title=${title%\*}
    if [ -z "$path" ] || [ -z "$title" ]; then
      cannot "$src:$lno: reference not parsable: $ref"
      continue
    fi
    if [ ! -f "$path" ]; then
      finding "$src:$lno references $path, which does not exist"
    elif ! has_heading "$path" "$title"; then
      finding "$src:$lno references \"$title\" in $path, where no heading carries that text"
    fi
  done < "$TMP/refs.txt"
fi
printf '\n'

# ===========================================================================
# 6. In the `## Contexts` table of context-map.md, the Directory column is an
#    em dash ("named, not detailed") or a directory that really exists.
# ===========================================================================
printf '== 6. The Directory column of context-map.md points somewhere real\n'
if [ ! -f "$CONTEXT_MAP" ]; then
  cannot "$CONTEXT_MAP not found; the Directory column is unverifiable"
elif [ ! -s "$TMP/contexts.tsv" ]; then
  cannot "$CONTEXT_MAP: no table found under '## Contexts'; the Directory column is unverifiable"
else
  ctx_header=$(grep '^HEADER	' "$TMP/contexts.tsv" | head -1)
  dir_col=$(header_index 'Directory' "$ctx_header")
  if [ -z "$dir_col" ]; then
    cannot "$CONTEXT_MAP: the '## Contexts' table has no 'Directory' column"
  elif ! grep -q '^ROW	' "$TMP/contexts.tsv"; then
    nocheck "the '## Contexts' table carries no data row; there is no Directory cell to resolve"
  else
    while IFS= read -r row; do
      ctx=$(nth_cell "$row" 1)
      d=$(nth_cell "$row" "$dir_col")
      case "$d" in
        ''|'—'|'-')
          continue ;;
      esac
      if [ ! -d "$BASE/$d" ] && [ ! -d "$d" ]; then
        finding "$CONTEXT_MAP: context '$ctx' points at Directory '$d', which is neither $BASE/$d nor $d"
      fi
    done < <(grep '^ROW	' "$TMP/contexts.tsv")
  fi
fi
printf '\n'

# ===========================================================================
# 7. Context directories carry the files and the sections the template fixes.
#    The list is DERIVED from `.specify/templates/domain-context-template.md`,
#    never hardcoded here: the template is the governance record of the shape,
#    and a second copy of it in this script would diverge from it.
#    The template writes the prescribed headings inside 4-space-indented blocks,
#    so they are matched as `^ {4}#{2,4} `, not as `^#{2,4} `.
# ===========================================================================
printf '== 7. Context directories carry the shape the template fixes\n'
if [ ! -f "$CONTEXT_TEMPLATE" ]; then
  cannot "$CONTEXT_TEMPLATE not found; the required shape is unknown"
else
  # Sections of the template announcing a shape end with "<number> files".
  awk '
    /^## / {
      sec++; cur = ""
      if ($NF == "files" || $NF == "file") {
        num[sec] = $(NF - 1)
        printf "SHAPE\t%d\t%s\t%s\n", sec, $(NF - 1), $0
      }
      next
    }
    sec == "" { next }
    /^### / {
      t = $0; sub(/^###[[:space:]]+/, "", t); gsub(/[[:space:]]+$/, "", t)
      if (t ~ /\.md$/) { cur = t; printf "FILE\t%d\t%s\n", sec, t }
      next
    }
    cur != "" && /^ {4}#{2,4}[[:space:]]/ {
      h = $0
      sub(/^[[:space:]]*#+[[:space:]]+/, "", h); gsub(/[[:space:]]+$/, "", h)
      printf "SEC\t%d\t%s\t%s\n", sec, cur, h
    }
    {
      line = $0
      while (match(line, /`docs\/domain\/[a-z0-9_-]+\/`/)) {
        d = substr(line, RSTART + 1, RLENGTH - 2)
        printf "DIR\t%d\t%s\n", sec, d
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$CONTEXT_TEMPLATE" > "$TMP/tpl.txt"

  n_tpl_headings=$(grep -c '^SEC	' "$TMP/tpl.txt" | tr -d ' ')
  if [ "$n_tpl_headings" -eq 0 ]; then
    cannot "$CONTEXT_TEMPLATE: no 4-space-indented '## '..'#### ' heading found; the prescribed sections cannot be derived"
  else
    # The shape section that lists `### <name>.md` specs is the full one; the
    # other shape section is the reduced one, and says how many files it keeps.
    full_sec=''
    reduced_sec=''
    while IFS="$(printf '\t')" read -r kind idx numword rest; do
      if grep -q "^FILE	$idx	" "$TMP/tpl.txt"; then
        [ -z "$full_sec" ] && { full_sec=$idx; full_num=$numword; }
      else
        [ -z "$reduced_sec" ] && { reduced_sec=$idx; reduced_num=$numword; }
      fi
    done < <(grep '^SHAPE	' "$TMP/tpl.txt")

    if [ -z "$full_sec" ]; then
      cannot "$CONTEXT_TEMPLATE: no section announcing a file count also lists '### <name>.md' specs"
    else
      grep "^FILE	$full_sec	" "$TMP/tpl.txt" | cut -f3 > "$TMP/full_files.txt"
      n_full=$(wc -l < "$TMP/full_files.txt" | tr -d ' ')
      declared_full=$(word_to_int "$full_num")
      if [ -z "$declared_full" ]; then
        cannot "$CONTEXT_TEMPLATE: the full-shape heading announces '$full_num files', which is not a number"
      elif [ "$declared_full" -ne "$n_full" ]; then
        cannot "$CONTEXT_TEMPLATE: the full-shape heading announces $declared_full files but $n_full '### <name>.md' specs follow"
      fi
      info "full shape derived from the template: $(oneline "$TMP/full_files.txt")"

      # Reduced shape: the first N files of the full list, in template order.
      : > "$TMP/reduced_files.txt"
      : > "$TMP/reduced_dirs.txt"
      if [ -n "$reduced_sec" ]; then
        declared_reduced=$(word_to_int "${reduced_num:-}")
        if [ -z "$declared_reduced" ]; then
          cannot "$CONTEXT_TEMPLATE: the reduced-shape heading announces '${reduced_num:-}' files, which is not a number"
        elif [ "$declared_reduced" -gt "$n_full" ]; then
          cannot "$CONTEXT_TEMPLATE: the reduced shape announces $declared_reduced files, more than the $n_full of the full shape"
        else
          head -n "$declared_reduced" "$TMP/full_files.txt" > "$TMP/reduced_files.txt"
          grep "^DIR	$reduced_sec	" "$TMP/tpl.txt" | cut -f3 | LC_ALL=C sort -u > "$TMP/reduced_dirs.txt"
          info "reduced shape derived from the template: $(oneline "$TMP/reduced_files.txt")"
          info "directories the template puts on the reduced shape: $(oneline "$TMP/reduced_dirs.txt")"
        fi
      else
        info 'the template announces no reduced shape; every directory is checked against the full shape'
      fi

      checked_dirs=0
      for d in "$BASE"/contexts/*/ "$BASE"/shared/ "$BASE"/core/; do
        [ -d "$d" ] || continue
        checked_dirs=$((checked_dirs + 1))
        clean=${d%/}
        list="$TMP/full_files.txt"
        shape='full'
        if [ -s "$TMP/reduced_dirs.txt" ] && grep -qxF "$clean/" "$TMP/reduced_dirs.txt"; then
          list="$TMP/reduced_files.txt"
          shape='reduced'
        elif [ -s "$TMP/reduced_dirs.txt" ] && grep -qxF "$clean" "$TMP/reduced_dirs.txt"; then
          list="$TMP/reduced_files.txt"
          shape='reduced'
        fi
        info "$clean/ — checked against the $shape shape"
        while IFS= read -r want; do
          [ -z "$want" ] && continue
          target="$clean/$want"
          if [ ! -f "$target" ]; then
            finding "$clean/ is missing $want, which the $shape shape of $CONTEXT_TEMPLATE prescribes"
            continue
          fi
          while IFS= read -r sec_title; do
            [ -z "$sec_title" ] && continue
            case "$sec_title" in
              *'<'*) continue ;;   # `### <Aggregate root>` is a placeholder, not a section
            esac
            has_heading "$target" "$sec_title" \
              || finding "$target has no heading \"$sec_title\", prescribed by $CONTEXT_TEMPLATE for $want"
          done < <(awk -F'\t' -v s="$full_sec" -v f="$want" \
                     '$1 == "SEC" && $2 == s && $3 == f { print $4 }' "$TMP/tpl.txt")
        done < "$list"
      done

      if [ "$checked_dirs" -eq 0 ]; then
        nocheck "no directory exists under $BASE/contexts/, and neither $BASE/shared/ nor $BASE/core/ exists"
        info "  the shape above was derived and is ready; it has been applied to nothing"
      fi
    fi
  fi
fi
printf '\n'

# ===========================================================================
# 8. Nobody is named — docs/domain/README.md § *Nobody is named*.
#    The only list of names a script can know is the commit authors'. Each human
#    author's full name is searched, whole words and regardless of case, on one
#    line or across two, so a name the line wrap split in two is still caught.
#    A single word of a name is not searched: 'Price' is a domain word long
#    before it is anyone's surname.
# ===========================================================================
printf '== 8. No commit author is named in the base\n'
info "a statement is attributed to a role, never to a person (docs/domain/README.md, Nobody is named)"
author_names=$(git log --format='%an' 2>/dev/null | grep -v '\[bot\]' \
  | awk '{ gsub(/[[:punct:][:space:]]+/, " "); gsub(/^ | $/, ""); if (length($0) >= 4) print }' \
  | LC_ALL=C sort -fu)
if [ -z "$author_names" ]; then
  nocheck "no human commit author could be read from git; there was no name to search for"
else
  n_names=0
  while IFS= read -r name; do
    n_names=$((n_names + 1))
    while IFS= read -r hit; do
      finding "${hit%%:*}: names '$name', a commit author — at line ${hit#*:}"
    done < <(domain_files | while IFS= read -r f; do
      awk -v name="$name" -v file="$f" '
        function norm(s) { s = tolower(s); gsub(/[[:punct:][:space:]]+/, " ", s); return " " s " " }
        function has(s) { return index(norm(s), norm(name)) > 0 }
        NR > 1 && !has(prev) && !has($0) && has(prev " " $0) { print file ":" NR - 1 }
        has($0) { print file ":" NR }
        { prev = $0 }' "$f"
    done)
  done < <(printf '%s\n' "$author_names")
  info "names searched, taken from the human commit authors: $n_names"
fi
printf '\n'

# ===========================================================================
# Result. Three numbers, no tick, no percentage. The third one exists because a
# check that had nothing to look at must not be readable as a check that passed.
# It counts NOTHING TO CHECK notices, not checks: one check can have two
# independent directions, each with nothing in front of it.
# ===========================================================================
printf '== Result\n'
count 'findings' "$findings"
count 'unrecognised structures' "$unrecognised"
count 'NOTHING TO CHECK notices' "$nothings"
printf '\n'

if [ "$unrecognised" -gt 0 ]; then
  printf 'VERDICT: COULD NOT CHECK — %s structure(s) were not recognised.\n' "$unrecognised"
  printf '         This is not a pass. Whatever those checks would have found is unknown.\n'
  printf '         Fix what blocks them, then run again.\n'
  exit 2
fi

if [ "$findings" -gt 0 ]; then
  printf 'VERDICT: FINDINGS — %s, each listed above with its location.\n' "$findings"
  printf '         Mechanical joins only. Nothing here says the content is right.\n'
  exit 1
fi

printf 'VERDICT: the checks that ran reported no finding.\n'
printf '         %s NOTHING TO CHECK notice(s) above assert nothing at all — read them\n' "$nothings"
printf '         before reading this line as a clean base.\n'
printf '         Mechanical joins only. Nothing here says the content is right.\n'
exit 0
