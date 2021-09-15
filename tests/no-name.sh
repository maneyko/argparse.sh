#!/bin/bash

source "${0%/*}/../argparse.sh"

arg_boolean '   [v]   [Do verbose output.]'
arg_optional "[percent2] [p2] [Percentage of something.]"
arg_optional '   [p] [The port number.]    '
arg_help "[Example using arguments with no long names.]"
parse_args

cat << EOT

ARG_V:        $ARG_V
ARG_P:        $ARG_P
ARG_PERCENT2: $ARG_PERCENT2

EOT
