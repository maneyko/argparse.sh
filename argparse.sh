#!/bin/bash

ARGS_STR="$@"
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
  arg_name="help"
  arg_flag="h"
  parse_arg3 "$1"
  HELP_DESCRIPTION="$parse_arg3_result"
  OPTIONAL_BOOLEAN_NAMES+=($arg_name)
  OPTIONAL_BOOLEAN_FLAGS+=($arg_flag)
  OPTIONAL_BOOLEAN_DESCRIPTIONS+=("Print this help message.")
}

remove_leading_whitespace() {
  eval "$(printf "$1=\"\${$1#\"\${$1%%%%[![:space:]]*}\"}\"")"
}

parse_args() {
  parse_args2 $ARGS_STR
}

parse_args2() {
  POSITIONAL=()
  while test $# -gt 0; do
    key=$1
    i=0
    found=
    for opt_name in "${OPTIONAL_SINGLE_NAMES[@]}"; do
      opt_flag="${OPTIONAL_SINGLE_FLAGS[$i]}"
      i=$(($i+1))
      case $key in
        -$opt_flag|--$opt_name)
          name_upper="$(echo $opt_name | tr '/a-z/' '/A-Z/' | tr '-' '_')"
          eval "$(printf "ARG_$name_upper=\"$2\"")"
          found=1
          shift
          shift
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
  FILENAME=
  printf "usage:  `basename $MAIN_FILE` "
  for p_name in "${POSITIONAL_NAMES[@]}"; do
    printf "[$p_name] "
  done
  for bool_flag in "${OPTIONAL_BOOLEAN_FLAGS[@]}"; do
    printf "[-$bool_flag] "
  done
  for opt_name in "${OPTIONAL_SINGLE_NAMES[@]}"; do
    opt_flag="${OPTIONAL_SINGLE_FLAGS[@]}"
    printf "[-$opt_flag $opt_name] "
  done
  printf "\n\n$HELP_DESCRIPTION\n\n"
  if test -n "${POSITIONAL_NAMES}"; then
    printf "positional arguments:\n"
    i=0
    for p_name in "${POSITIONAL_NAMES[@]}"; do
      printf "  %-25s ${POSITIONAL_DESCRIPTIONS[$i]}\n" "$p_name"
      i=$(($i + 1))
    done
  fi
  if test -n "${OPTIONAL_SINGLE_NAMES}" -o -n "${OPTIONAL_BOOLEAN_NAMES}"; then
    test -n "${POSITIONAL_NAMES}" && printf "\n"
    printf "optional arguments:\n"
    i=0
    for bool_name in "${OPTIONAL_BOOLEAN_NAMES[@]}"; do
      printf "  %-25s ${OPTIONAL_BOOLEAN_DESCRIPTIONS[$i]}\n" "-${OPTIONAL_BOOLEAN_FLAGS[$i]}, --$bool_name"
      i=$(($i + 1))
    done
    i=0
    for opt_name in "${OPTIONAL_SINGLE_NAMES[@]}"; do
      printf "  %-25s ${OPTIONAL_SINGLE_DESCRIPTIONS[$i]}\n" "-${OPTIONAL_SINGLE_FLAGS[$i]}, --$opt_name"
      i=$(($i + 1))
    done
  fi
}
