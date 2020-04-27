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
  parse_args $arg_name "positional"
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
  parse_args $arg_name $arg_flag
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
  parse_args $arg_name $arg_flag "true"
}

arg_help() {
  arg_name="help"
  arg_flag="h"
  parse_arg3 "$1"
  HELP_DESCRIPTION="$parse_arg3_result"
  OPTIONAL_BOOLEAN_NAMES+=($arg_name)
  OPTIONAL_BOOLEAN_FLAGS+=($arg_flag)
  OPTIONAL_BOOLEAN_DESCRIPTIONS+=("Print this help message.")
  parse_args $arg_name $arg_flag "true"
}

parse_args() {
  name_upper="$(echo $1 | tr '/a-z/' '/A-Z/' | tr '-' '_')"

  if test "$2" = "positional"; then
    arg_val="${ARGS_STR%%[ ]*}"
    ARGS_STR="${ARGS_STR#*[ ]}"
    eval "$(printf "ARG_%s=%s" "$name_upper" "$arg_val")"

  elif [[ $ARGS_STR =~ "--$1" || $ARGS_STR =~ "-$2" ]]; then
    if test -n "$3"; then
      eval "$(printf "ARG_%s=$3" "$name_upper")"
      ARGS_STR="$(echo " $ARGS_STR" | \
        perl -pe "s/ -$2//; s/ --$1//; s/^ //")"
    else
      arg_val="$(echo "$ARGS_STR" \
        | perl -ne "( /--$1 ([\S]+)/ || /-$2[ ]?([\S]+)/ ) && print \$1")"
      eval "$(printf "ARG_%s=%s" "$name_upper" "$arg_val")"
      ARGS_STR="$(echo " $ARGS_STR" | \
        perl -pe "s/ -$2[ ]?([\S]+)//; s/ --$1[ ]([\S]+)//; s/^ //")"
    fi
  fi

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
  fi
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
}
