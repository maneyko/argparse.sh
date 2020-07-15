#!/bin/bash

source "$(dirname "$0")/argparse.sh"

arg_positional "[infile] [The file to parse]"
arg_positional "[outfile] [The output file]"
arg_optional   "[port-number] [p] [The port number]"
arg_optional   "[outputs] [o] [The number of outputs]"
arg_boolean    "[verbose] [v] [Do verbose output]"
arg_boolean    "[flag] [f] [My important flag]"

read -d '' helptxt << EOT
This file illustrates how argparse.sh can be used
The help can be multiple lines
EOT

arg_help              "[$helptxt]"
parse_args


echo "infile:      $ARG_INFILE"
echo "outfile:     $ARG_OUTFILE"
echo "port-number: $ARG_PORT_NUMBER"
echo "outputs:     $ARG_OUTPUTS"
echo "verbose:     $ARG_VERBOSE"
echo "flag:        $ARG_FLAG"
