#!/bin/bash

BASH_MAJOR=$(echo $BASH_VERSION | awk -F'.' '{print $1}')
ALL_ARGS=($@)
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

arg_positional_single() {
  IFS="|" read arg_name arg_desc <<< "$(
    echo "$1" | awk -F '[][]' '{print $2 "|" $4}'
  )"
  POSITIONAL_NAMES+=($arg_name)
  POSITIONAL_DESCRIPTIONS+=("$arg_desc")
  parse_args $arg_name "positional"
}

arg_optional_single() {
  IFS="|" read arg_name arg_flag arg_desc <<< "$(
    echo "$1" | awk -F '[][]' '{print $2 "|" $4 "|" $6}'
  )"
  OPTIONAL_SINGLE_NAMES+=($arg_name)
  OPTIONAL_SINGLE_FLAGS+=($arg_flag)
  OPTIONAL_SINGLE_DESCRIPTIONS+=("$arg_desc")
  parse_args $arg_name $arg_flag
}

arg_optional_boolean() {
  IFS="|" read arg_name arg_flag arg_desc <<< "$(
    echo "$1" | awk -F '[][]' '{print $2 "|" $4 "|" $6}'
  )"
  OPTIONAL_BOOLEAN_NAMES+=($arg_name)
  OPTIONAL_BOOLEAN_FLAGS+=($arg_flag)
  OPTIONAL_BOOLEAN_DESCRIPTIONS+=("$arg_desc")
  parse_args $arg_name $arg_flag "true"
}

arg_help() {
  arg_name="help"
  arg_flag="h"
  HELP_DESCRIPTION="$(echo "$1" | awk -F '[][]' '{print $2}')"
  OPTIONAL_BOOLEAN_NAMES+=($arg_name)
  OPTIONAL_BOOLEAN_FLAGS+=($arg_flag)
  OPTIONAL_BOOLEAN_DESCRIPTIONS+=("Print this help message.")
  parse_args $arg_name $arg_flag "true"
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
  i=0
  for opt_name in "${OPTIONAL_SINGLE_NAMES[@]}"; do
    opt_flag="${OPTIONAL_SINGLE_FLAGS[@]}"
    printf "[-$opt_flag $opt_name]"
  done
  echo; echo
  echo "$HELP_DESCRIPTION"
  echo
  if test -n "${POSITIONAL_NAMES}"; then
    echo 'positional arguments:'
    i=0
    for p_name in "${POSITIONAL_NAMES[@]}"; do
      echo -e "  $p_name\t${POSITIONAL_DESCRIPTIONS[$i]}"
      i=$(($i + 1))
    done
    if test -n "${OPTIONAL_SINGLE_NAMES}" -o -n "${OPTIONAL_BOOLEAN_NAMES}"; then
      echo -e '\noptional arguments:'
    fi
    i=0
    for bool_name in "${OPTIONAL_BOOLEAN_NAMES[@]}"; do
      echo -e "  -${OPTIONAL_BOOLEAN_FLAGS[$i]}, --$bool_name\t${OPTIONAL_BOOLEAN_DESCRIPTIONS[$i]}"
      i=$(($i + 1))
    done
    i=0
    for opt_name in "${OPTIONAL_SINGLE_NAMES[@]}"; do
      echo -e "  -${OPTIONAL_SINGLE_FLAGS[$i]}, --$opt_name\t${OPTIONAL_SINGLE_DESCRIPTIONS[$i]}"
      i=$(($i + 1))
    done
  fi

}

parse_args() {
  name_upper="$(echo $1 | tr '/a-z/' '/A-Z/' | tr '-' '_')"
  if test "$2" = "positional"; then
    arg_val="$(echo "$ARGS_STR" | perl -ne '/[^-][^-]?([\S]+)/ && print $1')"
    eval "$(printf "ARG_%s=%s" "$name_upper" "$arg_val")"
  elif test -n "$(echo "$ARGS_STR" | awk "/--$1/ || /-$2/")"; then
    if test -z "$3"; then
      arg_val="$(echo "$ARGS_STR" \
        | perl -ne "( /--$1 ([\S]+)/ || /-$2[ ]?([\S]+)/ ) && print \$1")"
      eval "$(printf "ARG_%s=%s" "$name_upper" "$arg_val")"
    else
      eval "$(printf "ARG_%s=true" "$name_upper")"
    fi
  fi
  if test -n "$ARG_HELP"; then
    print_help
    exit 0
  fi
}

# arg_positional_single '[filename] [f] [the name of the file]'
# arg_optional_boolean  '[flagname] [f] [my important flag]'
# arg_optional_single   '[port] [p] [the port number]'
# arg_help              '[This is the help message for the script]'

# echo $ARG_1
# echo $ARG_FILENAME
# echo $ARG_FLAGNAME
# echo $ARG_PORT
