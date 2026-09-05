#!/bin/bash

cd "${0%/*}/../"

source "./argparse.sh"

ARG_N_ITERATIONS=1000

arg_help     "[Perform speed tests on 'argparse.sh' using the 'usage-example.sh' script.]"
arg_optional "[n-iterations] [n] [Number of iterations to perform. Default: '$ARG_N_ITERATIONS']"
arg_boolean  "[full]         [f] [Run full test suite.]"
parse_args

N=$ARG_N_ITERATIONS

execute_command() {
  ./examples/advanced-usage-example.sh \
    -p2020 \
    -cfr'/^\d+(\S+)\s+[[:alnum:]]/' \
    --host google.com \
    --outputs=3 \
    --host amazon.com \
    -qve 'print "hello world: $1" if /^\s+(.).*$/' \
    --delimiter '/\s+/' \
    --percentage=75%
}

# A failing command still gets timed, and the result looks impressively fast.
if ! execute_command >/dev/null; then
  echo 'ERROR: the example script did not run; timings would be meaningless.' >&2
  exit 1
fi

echo "Speed test for processing several flags (N = $N) ..."
time for (( i=0; i < $N; i++ )); do
  execute_command >/dev/null
done

if [[ -n $ARG_FULL ]]; then
  echo -e "\nSpeed test for help message (N = $N) ..."
  time for (( i=0; i < $N; i++ )); do
    ./examples/usage-example.sh -h >/dev/null
  done
fi
