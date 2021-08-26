#!/bin/bash

source "${0%/*}/argparse.sh"

ARG_N_ITERATIONS=1000

arg_help     "[Perform speed tests on 'argparse.sh' using the 'usage-example.sh' script.]"
arg_optional "[n-iterations] [n] [Number of iterations to perform. Default: '$ARG_N_ITERATIONS']"
arg_boolean  "[full]         [f] [Run full test suite.]"
parse_args

N=$ARG_N_ITERATIONS

echo "Speed test for processing several flags (N = $N) ..."
cmd="./usage-example.sh -n1 -n 2 infile.txt --numbers '-29' outfile.txt -fo 4 -vp2060"
time for (( i=0; i < $N; i++ )); do
  $cmd >/dev/null
done

if [[ -n $ARG_FULL ]]; then
  echo -e "\nSpeed test for help message (N = $N) ..."
  time for (( i=0; i < $N; i++ )); do
    ./usage-example.sh -h >/dev/null
  done
fi
