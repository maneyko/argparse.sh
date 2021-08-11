#!/bin/bash

# argparse.sh
#
# https://github.com/maneyko/argparse.sh
#
# Place this file in your $PATH and source it using:
#     source "argparse.sh"
#
# Or if argparse.sh is in the same directory as your script, you may use:
#     source "$(dirname "$0")/argparse.sh"
#
# Add it to the top of your script as if it is a library you are using in a programming
# language such as Python.
#
# The functions the user can use when sourcing this file in their script are:
#
# * arg_positional
#   - This parses positional arguments to your script
#   - Usage example: arg_positional "[infile] [The input file]"
#   - CLI example: ./myscript.sh myfile.txt
#     The value will be accessible to you via `$ARG_INFILE` after calling `parse_args`.
#
# * arg_optional
#   - This parses optional flags that take a corresponding value
#   - Usage example: arg_optional "[port] [p] [The port to use]"
#   - CLI example: ./myscript.sh --port 8080
#     The value will be accessible to you via `$ARG_PORT` after calling `parse_args`.
#     If the flag is not used, the variable `$ARG_PORT` will not be set.
#   - CLI example: ./myscript.sh -p8080
#     Notice there is no space between the flag and the variable, argparse.sh will parse
#     this correctly and `$ARG_PORT` will be set to 8080.
#
# * arg_boolean
#   - This parses optional flags thats corresponding variable is set to "true".
#   - Usage example: arg_boolean "[verbose] [v] [Do verbose output]"
#   - CLI example: ./myscript.sh -v
#     The value will be accessible to you via `$ARG_VERBOSE` after calling `parse_args`.
#     If the flag is not used, the variable `$ARG_VERBOSE` will not be set.
#
# * arg_array
#   - This parses any number of the same flag and stores the values in an array
#   - Usage example: arg_array "[numbers] [n] [Numbers to add together.]"
#   - CLI example: ./myscript.sh -n2 --numbers 12 -n4 --numbers 29
#     The value will be accessible to you via `$ARG_NUMBERS` after calling `parse_args`.
#     You may access the fourth value by calling "${ARG_NUMBERS[3]}".
#     In this example "${ARG_NUMBERS[3]}" is 29.
#     If the flag is not used, the variable `$ARG_NUMBERS` will not be set.
#
# * arg_help
#   - This is optional and will add the '-h' and '--help' flags as arguments to your script.
#   - Usage example: arg_help "[My custom help message]"
#   - CLI example: ./myscript.sh -h
#     All the commands you registered with argparse.sh will be printed to the console in a smart way.
#
# * parse_args
#   - This is a required step and must be run after registering all your variables with argparse.sh.


ARGS_ARR=("$@")

POSITIONAL_NAMES=()
POSITIONAL_DESCRIPTIONS=()

BOOLEAN_NAMES=()
BOOLEAN_FLAGS=()
BOOLEAN_DESCRIPTIONS=()

OPTIONAL_NAMES=()
OPTIONAL_FLAGS=()
OPTIONAL_DESCRIPTIONS=()

ARRAY_NAMES=()
ARRAY_FLAGS=()
ARRAY_DESCRIPTIONS=()

HELP_DESCRIPTION=

# Bold print.
#
# @param text [String]
bprint() {
  printf "\033[1m$1\033[0m"
}

# Color print.
#
# @param number [Integer]
# @param text   [String]
cprint() {
  printf "\033[38;5;${1}m${2}\033[0m"
}

FOO=$(/usr/bin/perl -x "$0" "${ARGS_ARR[@]}")

echo << '__END__' > /dev/null
#!/usr/bin/perl

use Getopt::Long;

my $data   = "file.dat";
my $length = 24;
my $verbose;
GetOptions ("length=i" => \$length,     # numeric
            "file=s"   => \$data,       # string
            "verbose"  => \$verbose);   # flag

print "$verbose\n";

print "@ARGV[1]\n";
print "In perl\n\n\n";

__END__

cat << EOT
$(/usr/bin/perl -x "$0" "${ARGS_ARR[@]}")
EOT
