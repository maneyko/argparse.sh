#!/bin/bash

source "$(dirname "$0")/../argparse.sh"

# Set default values.
ARG_INPUT_FILE='/etc/shells'
ARG_EXPRESSION="{ print }"

arg_help       "[This script is for processing a text file]"
arg_positional "[input-file]     [Input text file to read. Default: '$ARG_INPUT_FILE']"
arg_boolean    "[verbose]    [v] [Print information about operations being performed.]"
arg_optional   "[delimiter]  [d] [Input file field separator.]"
arg_optional   "[expression] [e] [Expression passed directly to ( awk '...' ). Default: '$ARG_EXPRESSION']"
parse_args

cat << EOT
ARG_INPUT_FILE: $ARG_INPUT_FILE
ARG_DELIMITER:  $ARG_DELIMITER
ARG_VERBOSE:    $ARG_VERBOSE
EOT

if [ -n "$ARG_VERBOSE" ]; then
  echo "Contents of '$ARG_INPUT_FILE':"
fi

awk -F "$ARG_DELIMITER" "$ARG_EXPRESSION" "$ARG_INPUT_FILE"
