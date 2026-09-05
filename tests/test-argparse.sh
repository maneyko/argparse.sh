#!/bin/bash

# Regression tests for argparse.sh.
#
#     tests/test-argparse.sh                 # test against /bin/bash
#     tests/test-argparse.sh /usr/local/bin/bash
#
# The shell under test is a plain positional argument on purpose: a test suite
# that used argparse.sh to read its own flags could not report that argparse.sh
# is broken.
#
# Fixture scripts are generated rather than checked in, so that a case and the
# assertions about it read together in one place. They are left in
# tests/fixtures (gitignored) afterwards so a failing one can be run by hand.

BASH_BIN=${1:-/bin/bash}
REPO=$(cd "${0%/*}/.." && pwd)
ARGPARSE_SH=$REPO/argparse.sh
FIXTURES=$REPO/tests/fixtures
export ARGPARSE_SH

if [[ ! -x $BASH_BIN ]]; then
  echo "ERROR: no such shell: $BASH_BIN" >&2
  exit 1
fi

mkdir -p "$FIXTURES"

n_pass=0
n_fail=0

pass() {
  n_pass=$((n_pass + 1))
  printf 'PASS  %s\n' "$1"
}

fail() {
  n_fail=$((n_fail + 1))
  printf 'FAIL  %s\n' "$1"
  printf '        wanted: %s\n' "$2"
  printf '        got:    %s\n' "$(printf '%s' "$3" | tr '\n' '|')"
}

# Sets $OUT and $RC for the assertions below.
run() {
  local fixture=$1
  shift
  OUT=$("$BASH_BIN" "$FIXTURES/$fixture.sh" "$@" 2>&1)
  RC=$?
}

line_is() {
  case $'\n'$2$'\n' in
    *$'\n'"$3"$'\n'*) pass "$1" ;;
    *) fail "$1" "$3" "$2" ;;
  esac
}

line_absent() {
  case $'\n'$2$'\n' in
    *$'\n'"$3"$'\n'*) fail "$1" "no line reading: $3" "$2" ;;
    *) pass "$1" ;;
  esac
}

contains() {
  case $2 in
    *"$3"*) pass "$1" ;;
    *) fail "$1" "contains: $3" "$2" ;;
  esac
}

lacks() {
  case $2 in
    *"$3"*) fail "$1" "must not contain: $3" "$2" ;;
    *) pass "$1" ;;
  esac
}

equals() {
  if [[ $2 == "$3" ]]; then pass "$1"; else fail "$1" "$3" "$2"; fi
}

cat > "$FIXTURES/full.sh" <<'FIXTURE'
#!/bin/bash
source "$ARGPARSE_SH"
ARG_NUMBERS=(9 9)
arg_positional "[infile]  [Input file]"
arg_positional "[outfile] [Output file]"
arg_boolean    "[verbose] [v] [Verbose]"
arg_boolean    "[quiet]   [q] [Quiet]"
arg_boolean    "          [f] [Flag with no long name]"
arg_optional   "[port]    [p] [Port]"
arg_optional   "[delim]   [d] [Delimiter]"
arg_optional   "[percent]     [Long name only]"
arg_array      "[numbers] [n] [Numbers]"
arg_help       "[Fixture for the argparse.sh test suite]"
parse_args
printf 'INFILE=[%s]\n'  "$ARG_INFILE"
printf 'OUTFILE=[%s]\n' "$ARG_OUTFILE"
printf 'VERBOSE=[%s]\n' "$ARG_VERBOSE"
printf 'QUIET=[%s]\n'   "$ARG_QUIET"
printf 'F=[%s]\n'       "$ARG_F"
printf 'PORT=[%s]\n'    "$ARG_PORT"
printf 'DELIM=[%s]\n'   "$ARG_DELIM"
printf 'PERCENT=[%s]\n' "$ARG_PERCENT"
printf 'NUMBERS=[%s]\n' "${ARG_NUMBERS[*]}"
printf 'POSITIONAL=[%s] COUNT=[%s]\n' "${POSITIONAL[*]}" "${#POSITIONAL[@]}"
printf 'LEAK=[%s%s]\n' "${!_ARG_*}" "${!_found_*}"
printf 'DIR_OK=[%s]\n' "$([[ -d $__DIR__ && -f $__FILE__ ]] && echo yes || echo no)"
FIXTURE

run full in.txt out.txt
line_is 'positional: first value fills the first name'  "$OUT" 'INFILE=[in.txt]'
line_is 'positional: second value fills the second'     "$OUT" 'OUTFILE=[out.txt]'
line_is 'positional: also collected in POSITIONAL'      "$OUT" 'POSITIONAL=[in.txt out.txt] COUNT=[2]'
line_is 'unused boolean stays empty'                    "$OUT" 'VERBOSE=[]'
line_is 'unused optional stays empty'                   "$OUT" 'PORT=[]'
line_is 'array keeps its default when the flag is absent' "$OUT" 'NUMBERS=[9 9]'
line_is 'no _ARG_/_found_ variables survive parse_args' "$OUT" 'LEAK=[]'
line_is '__DIR__ and __FILE__ point at real paths'      "$OUT" 'DIR_OK=[yes]'

run full --verbose
line_is 'boolean: long form'                            "$OUT" 'VERBOSE=[true]'
run full -v
line_is 'boolean: short form'                           "$OUT" 'VERBOSE=[true]'
run full -vq
line_is 'bundled booleans: first is set'                "$OUT" 'VERBOSE=[true]'
line_is 'bundled booleans: second is set'               "$OUT" 'QUIET=[true]'
run full -f
line_is 'boolean with no long name is reachable as ARG_F' "$OUT" 'F=[true]'

run full --port 8080
line_is 'optional: --flag value'                        "$OUT" 'PORT=[8080]'
run full --port=8080
line_is 'optional: --flag=value'                        "$OUT" 'PORT=[8080]'
run full -p 8080
line_is 'optional: -f value'                            "$OUT" 'PORT=[8080]'
run full -p8080
line_is 'optional: -fvalue'                             "$OUT" 'PORT=[8080]'
run full --percent=75%
line_is 'optional with no short flag'                   "$OUT" 'PERCENT=[75%]'
run full -vp8080
line_is 'bundled boolean then optional: boolean set'    "$OUT" 'VERBOSE=[true]'
line_is 'bundled boolean then optional: value captured' "$OUT" 'PORT=[8080]'
run full -vd,
line_is 'bundled form from the README parses the value' "$OUT" 'DELIM=[,]'

run full -n1 -n2 -n3
line_is 'array: repeated short flags replace the default' "$OUT" 'NUMBERS=[1 2 3]'
run full --numbers 1 --numbers=2 -n3
line_is 'array: long, long=value and short forms mix'   "$OUT" 'NUMBERS=[1 2 3]'

run full -p -v
line_is 'a value that looks like a flag is taken as the value' "$OUT" 'PORT=[-v]'
line_is 'a consumed value is not also parsed as a flag' "$OUT" 'VERBOSE=[]'

run full -d 'a b c'
line_is 'value containing spaces survives'              "$OUT" 'DELIM=[a b c]'
run full -d '*'
line_is 'value containing a glob is not expanded'       "$OUT" 'DELIM=[*]'
run full -d 'has=equals'
line_is 'value containing an equals sign survives'      "$OUT" 'DELIM=[has=equals]'
run full --delim='a=b=c'
line_is '--flag=value splits on the first equals only'  "$OUT" 'DELIM=[a=b=c]'
run full -d 'back\slash'
line_is 'value containing a backslash is not expanded'  "$OUT" 'DELIM=[back\slash]'

run full -n 'a;echo INJECTED' -p '$(echo INJECTED)'
line_absent 'values are never evaluated as shell'       "$OUT" 'INJECTED'
line_is 'array value keeps its literal semicolon'       "$OUT" 'NUMBERS=[a;echo INJECTED]'
line_is 'optional value keeps its literal $( )'         "$OUT" 'PORT=[$(echo INJECTED)]'

run full -h
equals  '-h exits 0'                                    "$RC" '0'
contains '-h prints a usage line'                       "$OUT" 'usage:'
contains '-h lists a registered long flag'              "$OUT" '--verbose'
contains '-h lists the auto-added help flag'            "$OUT" '--help'

cat > "$FIXTURES/passthrough.sh" <<'FIXTURE'
#!/bin/bash
source "$ARGPARSE_SH"
arg_positional "[archive] [Archive to unpack]"
arg_boolean    "[keep] [k] [Keep the archive afterwards]"
arg_help       "[Flags this wrapper does not define are handed to tar]"
parse_args
POSITIONAL=("${POSITIONAL[@]:1}")
printf 'ARCHIVE=[%s] KEEP=[%s]\n' "$ARG_ARCHIVE" "$ARG_KEEP"
printf 'FORWARDED=[%s] COUNT=[%s]\n' "${POSITIONAL[*]}" "${#POSITIONAL[@]}"
FIXTURE

run passthrough backup.tar.gz -z -v --strip-components 2 -C /opt
line_is 'unregistered flags do not disturb registered ones' "$OUT" 'ARCHIVE=[backup.tar.gz] KEEP=[]'
line_is 'unregistered short and long flags are forwarded' "$OUT" 'FORWARDED=[-z -v --strip-components 2 -C /opt] COUNT=[6]'

run passthrough backup.tar.gz -k -zxvf
line_is 'a registered flag is still consumed'           "$OUT" 'ARCHIVE=[backup.tar.gz] KEEP=[true]'
line_is 'an unregistered bundle is forwarded intact'    "$OUT" 'FORWARDED=[-zxvf] COUNT=[1]'

run passthrough backup.tar.gz --exclude 'build output'
line_is 'a forwarded value keeps its spaces'            "$OUT" 'FORWARDED=[--exclude build output] COUNT=[2]'

cat > "$FIXTURES/twochar.sh" <<'FIXTURE'
#!/bin/bash
source "$ARGPARSE_SH"
arg_optional "[port]  [p]  [One character flag]"
arg_optional "[port1] [p1] [Two character flag]"
arg_optional "[port2] [p2] [Two character flag]"
arg_help     "[Two character flags]"
parse_args
printf 'PORT=[%s] PORT1=[%s] PORT2=[%s]\n' "$ARG_PORT" "$ARG_PORT1" "$ARG_PORT2"
FIXTURE

run twochar -p 1
line_is 'one character flag is not shadowed by -p1'     "$OUT" 'PORT=[1] PORT1=[] PORT2=[]'
run twochar -p1 10
line_is 'two character flag wins over its own prefix'   "$OUT" 'PORT=[] PORT1=[10] PORT2=[]'
run twochar -p2foo -pbar
line_is 'attached values on one and two character flags' "$OUT" 'PORT=[bar] PORT1=[] PORT2=[foo]'

cat > "$FIXTURES/describe.sh" <<'FIXTURE'
#!/bin/bash
source "$ARGPARSE_SH"
arg_optional "[regex] [r] [Matches \d+ under C:\new\temp]"
arg_optional "[pct]   [c] [Percent 100% and a format %s]"
arg_positional "[infile] [First line of the description
    Second line of the description]"
arg_help     "[Descriptions are printed literally]"
parse_args
FIXTURE

run describe -h
contains 'backslashes in a description are not interpreted' "$OUT" 'Matches \d+ under C:\new\temp'
contains 'percent and format specifiers survive'        "$OUT" 'Percent 100% and a format %s'
contains 'multi-line description keeps its first line'  "$OUT" 'First line of the description'
contains 'multi-line description keeps its later lines' "$OUT" 'Second line of the description'

cat > "$FIXTURES/strict.sh" <<'FIXTURE'
#!/bin/bash
set -euo pipefail
source "$ARGPARSE_SH"
arg_positional "[infile] [Input]"
arg_boolean    "[verbose] [v] [Verbose]"
arg_optional   "[port] [p] [Port]"
arg_array      "[numbers] [n] [Numbers]"
arg_help       "[Runs under set -euo pipefail]"
parse_args
printf 'SURVIVED INFILE=[%s] PORT=[%s]\n' "${ARG_INFILE:-}" "${ARG_PORT:-}"
case $- in
  *u*) printf 'NOUNSET=[restored]\n' ;;
  *)   printf 'NOUNSET=[lost]\n' ;;
esac
FIXTURE

for args in "" "in.txt" "in.txt out.txt extra" "-v" "-vn5 -n 6" "--numbers=7 -n8" "-p8080"; do
  run strict $args
  equals  "set -u: exits 0 with [$args]"                "$RC" '0'
  line_is "set -u: nounset restored with [$args]"       "$OUT" 'NOUNSET=[restored]'
done

cat > "$FIXTURES/scope.sh" <<'FIXTURE'
#!/bin/bash
source "$ARGPARSE_SH"
arg_positional "[infile] [Input]"
arg_boolean    "[verbose] [v] [Verbose]"
arg_optional   "[port] [p] [Port]"
arg_array      "[numbers] [n] [Numbers]"
arg_help       "[Caller variables must survive parse_args]"
key=caller-key
value=caller-value
i=42
j=43
parse_args
printf 'key=[%s] value=[%s] i=[%s] j=[%s]\n' "$key" "$value" "$i" "$j"
FIXTURE

run scope in.txt -vn5 -p8080
line_is 'parse_args does not clobber caller variables'  "$OUT" 'key=[caller-key] value=[caller-value] i=[42] j=[43]'

cat > "$FIXTURES/errexit.sh" <<'FIXTURE'
#!/bin/bash
set -e
source "$ARGPARSE_SH"
arg_boolean "[verbose] [v] [Verbose]"
arg_optional "[port] [p] [Port]"
arg_help    "[Runs under set -e]"
parse_args
printf 'SURVIVED VERBOSE=[%s]\n' "$ARG_VERBOSE"
FIXTURE

run errexit -v
equals  'set -e: exits 0'                               "$RC" '0'
line_is 'set -e: parsing completes'                     "$OUT" 'SURVIVED VERBOSE=[true]'
run errexit
equals  'set -e: exits 0 with no arguments'             "$RC" '0'

cat > "$FIXTURES/helponly.sh" <<'FIXTURE'
#!/bin/bash
set -u
source "$ARGPARSE_SH"
arg_boolean "[verbose] [v] [Verbose]"
arg_help    "[print_help is public and may be called directly]"
parse_args
print_help
case $- in
  *u*) printf 'NOUNSET=[restored]\n' ;;
  *)   printf 'NOUNSET=[lost]\n' ;;
esac
FIXTURE

run helponly
equals  'print_help called directly under set -u exits 0' "$RC" '0'
contains 'print_help called directly prints usage'      "$OUT" 'usage:'
line_is 'print_help restores nounset'                   "$OUT" 'NOUNSET=[restored]'

cat > "$FIXTURES/nocd.sh" <<'FIXTURE'
#!/bin/bash
source "$ARGPARSE_SH"
arg_help "[Changing directory before parse_args must be reported]"
cd /
parse_args
printf 'REACHED=[yes]\n'
FIXTURE

cat > "$FIXTURES/nocd-errexit.sh" <<'FIXTURE'
#!/bin/bash
set -e
source "$ARGPARSE_SH"
arg_help "[Changing directory before parse_args, under set -e]"
cd /
parse_args
printf 'REACHED=[yes]\n'
FIXTURE

OUT=$(cd "$FIXTURES" && "$BASH_BIN" ./nocd.sh 2>&1); RC=$?
equals  'cd before parse_args exits 1'                  "$RC" '1'
contains 'cd before parse_args explains the fix'        "$OUT" 'before changing directories'
lacks   'cd before parse_args does not continue'        "$OUT" 'REACHED=[yes]'

# Invoked through a relative subdirectory, so get__dir__'s own `cd' fails
# rather than merely landing somewhere wrong.
OUT=$(cd "$FIXTURES/.." && "$BASH_BIN" ./fixtures/nocd.sh 2>&1); RC=$?
equals  'a failing get__dir__ still reaches the check'  "$RC" '1'
contains 'a failing get__dir__ explains the fix'        "$OUT" 'before changing directories'
lacks   'a failing get__dir__ is not reported by cd'    "$OUT" 'No such file or directory'

OUT=$(cd "$FIXTURES/.." && "$BASH_BIN" ./fixtures/nocd-errexit.sh 2>&1); RC=$?
equals  'set -e does not skip the check'                "$RC" '1'
contains 'set -e still gets the explanation'            "$OUT" 'before changing directories'
lacks   'set -e run does not continue'                  "$OUT" 'REACHED=[yes]'

OUT=$("$BASH_BIN" -c 'cd /tmp; source "$ARGPARSE_SH"; arg_help "[x]"; parse_args; pwd' 2>&1)
line_is 'parse_args leaves the caller in its own directory' "$OUT" '/tmp'
lacks   'a skipped check does not print a cd error'     "$OUT" 'No such file or directory'

OUT=$("$BASH_BIN" -c 'source "$ARGPARSE_SH"; arg_help "[x]"; parse_args; printf "RAN=[yes]\n"' 2>&1); RC=$?
equals  'bash -c is not refused by the path check'      "$RC" '0'
line_is 'bash -c still parses'                          "$OUT" 'RAN=[yes]'

OUT=$(PATH=${BASH_BIN%/*}:$PATH "${BASH_BIN##*/}" -c 'source "$ARGPARSE_SH"; arg_help "[x]"; parse_args
  if [[ -d $__DIR__ ]]; then printf "DIR=[usable]\n"; else printf "DIR=[unusable]\n"; fi' 2>&1)
line_is 'a failed lookup leaves __DIR__ visibly unusable' "$OUT" 'DIR=[unusable]'

OUT=$(printf '%s\n' 'source "$ARGPARSE_SH"; arg_help "[x]"; parse_args; printf "RAN=[yes]\n"' | "$BASH_BIN" 2>&1); RC=$?
equals  'a piped script is not refused by the path check' "$RC" '0'
line_is 'a piped script still parses'                   "$OUT" 'RAN=[yes]'

OUT=$("$BASH_BIN" "$ARGPARSE_SH" 2>&1); RC=$?
equals  'executing argparse.sh directly exits 1'        "$RC" '1'
contains 'executing argparse.sh directly explains why'  "$OUT" 'may not execute argparse.sh directly'

printf '\n%s: %d passed, %d failed\n' "$("$BASH_BIN" -c 'echo bash $BASH_VERSION')" "$n_pass" "$n_fail"
[[ $n_fail -eq 0 ]]
