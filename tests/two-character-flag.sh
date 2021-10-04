#!/bin/bash

ARG_PERCENT2="100%"

source "${0%/*}/../argparse.sh"

arg_optional '[percent1] [p1] [Percentage of something.]'
arg_optional "[percent2] [p2] [Percentage of something. Default is $ARG_PERCENT2.]"
arg_help                     "[Example showing percentage (%) in help message.]"
parse_args

cat << EOT

ARG_PERCENT1:            ${ARG_PERCENT1}
ARG_PERCENT2:            ${ARG_PERCENT2}

EOT
