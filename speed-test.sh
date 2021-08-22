#!/bin/bash

source "${0%/*}/argparse.sh"

ARG_N_ITERATIONS=1000

arg_help    "[Perform speed tests on 'argparse.sh' using the 'usage-example.sh' script.]"
arg_boolean "[n-iterations] [n] [Number of iterations to perform. Default: '$ARG_N_ITERATIONS']"
arg_boolean "[test-help]    [x] [Test the '-h' flag to 'usage-example.sh' script.]"
parse_args

N=$ARG_N_ITERATIONS

echo "Speed test for processing several flags ..."
cmd="./usage-example.sh -n1 -n 2 infile.txt --numbers '-29' outfile.txt -fo4 -vp2060"
time for (( i=0; i < $N; i++ )); do
  $cmd >/dev/null
done

if [[ -n $ARG_TEST_HELP ]]; then
  echo "Speed test for help message ..."
  time for (( i=0; i < $N; i++ )); do
    ./usage-example.sh -h >/dev/null
  done
fi
