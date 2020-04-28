#!/bin/bash

source "./argparse.sh"

arg_optional_single   "[port-number] [p] [The port number]"
arg_optional_single   "[outputs] [o] [The number of outputs]"
arg_optional_boolean  "[verbose] [v] [Do verbose output]"
arg_optional_boolean  "[flag] [f] [My important flag]"
arg_positional_single "[infile] [The file to parse]"
arg_positional_single "[outfile] [The output file]"
read -d '' helptxt << EOT
This is some help text
that is multiple lines
it is a test
EOT
arg_help              "[$helptxt]"
parse_args


echo $ARG_PORT_NUMBER
echo $ARG_INFILE
echo $ARG_OUTFILE
echo $ARG_FLAG
echo $ARG_VERBOSE
echo $ARG_OUTPUTS
