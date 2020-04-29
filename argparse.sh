#!/bin/bash

# argparse.sh
#
# Place this file in your $PATH and source it using:
#   source "$(type -P argparse.sh)"
#
# Add it to the top of your script as if it is a library you are using in a programming
# language such as Python.
#
# The functions the user is supposed to use when sourcing this file in their script are:
#
# * arg_positional_single
#   - This parses positional arguments to your script
#   - Usage example: arg_positional_single "[infile] [The input file]"
#   - CLI example: ./myscript.sh myfile.txt
#     The value will be accessible to you via `$ARG_INFILE` after calling `parse_args`.
#
# * arg_optional_single
#   - This parses optional arguments with a flag and a value arguments to your script
#   - Usage example: arg_optional_single "[port] [p] [The port to use]"
#   - CLI example: ./myscript.sh --port 8080
#     The value will be accessible to you via `$ARG_PORT` after calling `parse_args`.
#     If the flag is not used, the variable `$ARG_PORT` will not be set.
#   - CLI example: ./myscript.sh -p8080
#     Notice there is no space between the flag and the variable, argparse.sh will parse
#     this correctly and `$ARG_PORT` will be set.
#
# * arg_optional_boolean
#   - This parses optional flags
#   - Usage example: arg_optional_boolean "[verbose] [v] [Do verbose output]"
#   - CLI example: ./myscript.sh -v
#     The value will be accessible to you via `$ARG_VERBOSE` after calling `parse_args`.
#     If the flag is not used, the variable `$ARG_VERBOSE` will not be set.
#
# * arg_help
#   - This is optional and will add the '-h' and '--help' flags as arguments to your script.
#   - Usage example: arg_help "[My custom help message]"
#   - CLI example: ./myscript.sh -h
#     The commands you registered with argparse.sh will be printed to the console in a smart way.
#
# * parse_args
#   - This is a required step and must be run after registering all your variables with argparse.sh.


ARGS_ARR=("$@")
MAIN_FILE=$0

POSITIONAL_NAMES=()
POSITIONAL_DESCRIPTIONS=()

OPTIONAL_BOOLEAN_NAMES=()
OPTIONAL_BOOLEAN_FLAGS=()
OPTIONAL_BOOLEAN_DESCRIPTIONS=()

OPTIONAL_SINGLE_NAMES=()
OPTIONAL_SINGLE_FLAGS=()
OPTIONAL_SINGLE_DESCRIPTIONS=()

HELP_DESCRIPTION=

clr() {  # (number, text)
  printf "\033[38;5;${1}m${2}\033[0m"
}

parse_arg1() {
  t1="${1%%\]*}"
  parse_arg1_result="${t1#\[}"
}

parse_arg2() {
  t1="${1#*[ ]}"
  parse_arg1 "$t1"
  parse_arg2_result="$parse_arg1_result"
}

parse_arg3() {
  t1="${1##*\[}"
  parse_arg3_result="${t1%\]}"
}

arg_positional_single() {
  parse_arg1 "$1"
  arg_name="$parse_arg1_result"
  parse_arg3 "$1"
  arg_desc="$parse_arg3_result"
  POSITIONAL_NAMES+=($arg_name)
  POSITIONAL_DESCRIPTIONS+=("$arg_desc")
}

arg_optional_single() {
  parse_arg1 "$1"
  arg_name="$parse_arg1_result"
  parse_arg2 "$1"
  arg_flag="$parse_arg2_result"
  parse_arg3 "$1"
  arg_desc="$parse_arg3_result"
  OPTIONAL_SINGLE_NAMES+=($arg_name)
  OPTIONAL_SINGLE_FLAGS+=($arg_flag)
  OPTIONAL_SINGLE_DESCRIPTIONS+=("$arg_desc")
}

arg_optional_boolean() {
  parse_arg1 "$1"
  arg_name="$parse_arg1_result"
  parse_arg2 "$1"
  arg_flag="$parse_arg2_result"
  parse_arg3 "$1"
  arg_desc="$parse_arg3_result"
  OPTIONAL_BOOLEAN_NAMES+=($arg_name)
  OPTIONAL_BOOLEAN_FLAGS+=($arg_flag)
  OPTIONAL_BOOLEAN_DESCRIPTIONS+=("$arg_desc")
}

arg_help() {
  t1="${1#*\[}"
  HELP_DESCRIPTION="${t1%\]*}"
  OPTIONAL_BOOLEAN_NAMES+=("help")
  OPTIONAL_BOOLEAN_FLAGS+=("h")
  OPTIONAL_BOOLEAN_DESCRIPTIONS+=("Print this help message.")
}

parse_args() {
  parse_args2 "${ARGS_ARR[@]}"
}

parse_args2() {
  POSITIONAL=()
  while test $# -gt 0; do
    key=$1
    found=
    i=0
    for opt_name in "${OPTIONAL_SINGLE_NAMES[@]}"; do
      opt_flag="${OPTIONAL_SINGLE_FLAGS[$i]}"
      i=$(($i+1))
      case $key in
        -$opt_flag*|--$opt_name)
          name_upper="$(echo $opt_name | tr '/a-z/' '/A-Z/' | tr '-' '_')"
          if [[ $key =~ ^-$opt_flag ]]; then
            if [[ $key == -$opt_flag ]]; then
              val="$2"
              shift; shift
            else
              val="${key/-"$opt_flag"}"
              shift
            fi
          else
            val="$2"
            shift; shift
          fi
          eval "$(printf "ARG_$name_upper=\"$val\"")"
          found=1
          ;;
      esac
    done
    i=0
    for opt_name in "${OPTIONAL_BOOLEAN_NAMES[@]}"; do
      opt_flag="${OPTIONAL_BOOLEAN_FLAGS[$i]}"
      i=$(($i+1))
      case $key in
        -$opt_flag|--$opt_bool)
          name_upper="$(echo $opt_name | tr '/a-z/' '/A-Z/' | tr '-' '_')"
          eval "$(printf "ARG_$name_upper=true")"
          found=1
          shift
          ;;
      esac
    done
    if test -z "$found"; then
      POSITIONAL+=("$1")
      shift
    fi
  done
  set -- "${POSITIONAL[@]}"

  i=0
  for name in "${POSITIONAL_NAMES[@]}"; do
    name_upper="$(echo $name | tr '/a-z/' '/A-Z/' | tr '-' '_')"
    eval "$(printf "ARG_$name_upper=${POSITIONAL[$i]}")"
    i=$(($i+1))
  done

  if test -n "$ARG_HELP"; then
    print_help
    exit 0
  fi
}

print_help() {
  printf "usage:  `basename $MAIN_FILE` "
  for p_name in "${POSITIONAL_NAMES[@]}"; do
    printf "[$p_name] "
  done
  for bool_flag in "${OPTIONAL_BOOLEAN_FLAGS[@]}"; do
    printf "[-$bool_flag] "
  done
  i=0
  for opt_name in "${OPTIONAL_SINGLE_NAMES[@]}"; do
    opt_flag="${OPTIONAL_SINGLE_FLAGS[$i]}"
    printf "[-$opt_flag $opt_name] "
    i=$(($i+1))
  done
  printf "\n\n$HELP_DESCRIPTION\n\n"
  if test -n "${POSITIONAL_NAMES}"; then
    printf "positional arguments:\n"
    i=0
    for p_name in "${POSITIONAL_NAMES[@]}"; do
      p_disp="$(clr 3 "$p_name")"
      printf "  %-37s ${POSITIONAL_DESCRIPTIONS[$i]}\n" "$p_disp"
      i=$(($i+1))
    done
  fi
  if test -n "${OPTIONAL_SINGLE_NAMES}" -o -n "${OPTIONAL_BOOLEAN_NAMES}"; then
    test -n "${POSITIONAL_NAMES}" && printf "\n"
    printf "optional arguments:\n"
    i=0
    for bool_name in "${OPTIONAL_BOOLEAN_NAMES[@]}"; do
      flag_disp="$(clr 3 "-${OPTIONAL_BOOLEAN_FLAGS[$i]}")"
      name_disp="$(clr 3 "--$bool_name")"
      printf "  %-50s ${OPTIONAL_BOOLEAN_DESCRIPTIONS[$i]}\n" "$flag_disp, $name_disp"
      i=$(($i+1))
    done
    i=0
    for opt_name in "${OPTIONAL_SINGLE_NAMES[@]}"; do
      flag_disp="$(clr 3 "-${OPTIONAL_SINGLE_FLAGS[$i]}")"
      name_disp="$(clr 3 "--$opt_name")"
      printf "  %-50s ${OPTIONAL_SINGLE_DESCRIPTIONS[$i]}\n" "$flag_disp, $name_disp"
      i=$(($i+1))
    done
  fi
}
