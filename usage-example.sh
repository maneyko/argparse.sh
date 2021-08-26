#!/bin/bash

source "${0%/*}/argparse.sh"

ARG_NUMBERS=(1 2 3)

: ${HELP_WIDTH:=35}

arg_positional "[infile]          [The file to parse]"
arg_positional "[outfile]         [The output file.
    The following image will be output to the specified file:
      ____
     /   /
    /   /
   /   /---/
  /---/   /
     /   /
    /___/]"
arg_optional   "[port-number]        [p] [The port number (as a percent %)]"
arg_optional   "[grep-regex-pattern] [g] [Grep regex pattern to use when searching files. Default: [[space]]+]"
arg_optional   "[outputs]            [o] [The number of outputs]"
arg_boolean    "[verbose]            [] [Do verbose output]"
arg_boolean    "[flag]               [f] [My important flag]"
arg_array      "[numbers]            [n] [Numbers to add together. Default is: [${ARG_NUMBERS[@]}]]"

read -d '' helptxt << EOT
This file illustrates how argparse.sh can be used
The help can be multiple lines
EOT

arg_help              "[$helptxt]"
parse_args

cat << EOT
infile:      $ARG_INFILE
outfile:     $ARG_OUTFILE
port-number: $ARG_PORT_NUMBER
outputs:     $ARG_OUTPUTS
verbose:     $ARG_VERBOSE
flag:        $ARG_FLAG
numbers:     ${ARG_NUMBERS[@]}

Script '${0##*/}' is in '$__DIR__'
EOT
