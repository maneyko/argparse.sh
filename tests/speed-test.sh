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
  ./advanced-usage-example.sh \
    -p2020 \
    -cfr'/^\d+(\S+)\s+[[:alnum:]]/' \
    --host google.com \
    --outputs=3 \
    --host amazon.com \
    -qve 'print "hello world: $1" if /^\s+(.).*$/' \
    --delimiter '/\s+/' \
    --percentage=75%
}
# ./advanced-usage-example.sh -p2020 -cfr'/^\d+(\S+)\s+[[:alnum:]]/' --host google.com --outputs=3 --host amazon.com -qve 'print "hello world: $1" if /^\s+(.).*$/' --delimiter '/\s+/' --percentage=75

echo "Speed test for processing several flags (N = $N) ..."
time for (( i=0; i < $N; i++ )); do
  execute_command >/dev/null
done

if [[ -n $ARG_FULL ]]; then
  echo -e "\nSpeed test for help message (N = $N) ..."
  time for (( i=0; i < $N; i++ )); do
    ./usage-example.sh -h >/dev/null
  done
fi
