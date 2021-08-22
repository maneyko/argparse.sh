#!/bin/bash

source "${0%/*}/argparse.sh"

arg_help    "[Perform speed tests on 'argparse.sh' using the 'usage-example.sh' script.]"
arg_boolean "[full]  [f] [Test the '-h' flag to 'usage-example.sh' script.]"
parse_args

echo "Speed test for processing several flags ..."
cmd="./usage-example.sh -n1 -n 2 infile.txt --numbers '-29' outfile.txt -fo4 -vp2060"
time for i in {1..500}; do
  $cmd >/dev/null
done

if [[ -n $ARG_FULL ]]; then
  echo "Speed test for help message ..."
  time for i in {1..500}; do
    ./usage-example.sh -h >/dev/null
  done
fi
