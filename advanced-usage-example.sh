#!/bin/bash

source "${0%/*}/argparse.sh"

ARG_NUMBERS=(1 2 3)
ARG_PERL_REGEX_PATTERN='/[[:alnum:]]/'
ARG_PERCENTAGE='100%'

: ${HELP_WIDTH:=35}

arg_positional "[infile]  [The file to parse]"
arg_positional "[outfile] [The output file.
    The following image will be output to the specified file:
      ____
     /   /
    /   /
   /   /---/
  /---/   /
     /   /
    /___/]"
arg_optional   "[port-number]        [p] [The port number.]"
arg_optional   "[outputs]            [o] [The number of outputs]"
arg_boolean    "[verbose]            []  [Do verbose output]"
arg_boolean    "                     [f] [Some flag]"
arg_optional   "[delimiter]          [d] [Delimiter for input file.]"
arg_boolean    "[version]            [v] [Show version information.]"
arg_optional   "[percentage]             [Percent of file to process. Default: '$ARG_PERCENTAGE']"
arg_array      "[numbers]            [n] [Numbers to add together. Default is: [${ARG_NUMBERS[@]}]]"
arg_array      "[host]                   [Output host destinations. Example: '8.8.8.8']"
arg_boolean    "[checks]             [c] [Perform validation checks.]"
arg_optional   "[perl-regex-pattern] [] [Perl regex pattern to use when searching files. Default: '$ARG_PERL_REGEX_PATTERN']"
arg_boolean    "[quiet]              [q] [Execute quietly.]"
arg_optional   "                     [e] [Execute an arbitrary Perl command.]"

read -d '' helptxt << EOT
This file illustrates how argparse.sh can be used
The help can be multiple lines
EOT

arg_help "[\n$helptxt]"
parse_args

cat << EOT
ARG_INFILE:             $ARG_INFILE
ARG_OUTFILE:            $ARG_OUTFILE
ARG_PORT_NUMBER:        $ARG_PORT_NUMBER
ARG_OUTPUTS:            $ARG_OUTPUTS
ARG_VERBOSE:            $ARG_VERBOSE
ARG_F:                  $ARG_F
ARG_DELIMITER:          $ARG_DELIMITER
ARG_VERSION:            $ARG_VERSION
ARG_PERCENTAGE:         $ARG_PERCENTAGE
ARG_NUMBERS:            ${ARG_NUMBERS[@]}
ARG_HOST:               ${ARG_HOST[@]}
ARG_CHECKS:             $ARG_CHECKS
ARG_PERL_REGEX_PATTERN: $ARG_PERL_REGEX_PATTERN
ARG_QUIET:              $ARG_QUIET
ARG_E:                  $ARG_E

Script '${__FILE__##*/}' is in '$__DIR__'
EOT
