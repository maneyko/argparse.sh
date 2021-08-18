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

# Set $__DIR__ variable.
# The full path of the directory of the script.
set__dir() {
  _origin_pwd="$PWD"
  cd "${0%/*}"
  __DIR__="$PWD"
  cd "$_origin_pwd"
}

# @param arg_options
parse_arg1() {
  t1="${1%%\]*}"
  t2="${1#*\]}"
  wo_arg1="[${t2#*\[}"
  parse_arg1_result="${t1#*\[}"
}

# @param arg_name
# @param arg_description
arg_positional() {
  arg="$@"
  parse_arg1 "$arg"
  arg_name="$parse_arg1_result"
  t1="${wo_arg1#*\[}"
  arg_desc="${t1%\]*}"
  POSITIONAL_NAMES+=($arg_name)
  POSITIONAL_DESCRIPTIONS+=("$arg_desc")
}

# @param arg_name
# @param arg_flag
# @param arg_description
arg_optional() {
  arg="$@"
  parse_arg1 "$arg"
  arg_name="$parse_arg1_result"
  parse_arg1 "$wo_arg1"
  arg_flag="$parse_arg1_result"
  t1="${wo_arg1#*\[}"
  arg_desc="${t1%\]*}"
  OPTIONAL_NAMES+=($arg_name)
  OPTIONAL_FLAGS+=($arg_flag)
  OPTIONAL_DESCRIPTIONS+=("$arg_desc")
}

# @param arg_name
# @param arg_flag
# @param arg_description
arg_boolean() {
  arg="$@"
  parse_arg1 "$arg"
  arg_name="$parse_arg1_result"
  parse_arg1 "$wo_arg1"
  arg_flag="$parse_arg1_result"
  t1="${wo_arg1#*\[}"
  arg_desc="${t1%\]*}"
  BOOLEAN_NAMES+=($arg_name)
  BOOLEAN_FLAGS+=($arg_flag)
  BOOLEAN_DESCRIPTIONS+=("$arg_desc")
}

arg_array() {
  arg="$@"
  parse_arg1 "$arg"
  arg_name="$parse_arg1_result"
  parse_arg1 "$wo_arg1"
  arg_flag="$parse_arg1_result"
  t1="${wo_arg1#*\[}"
  arg_desc="${t1%\]*}"
  ARRAY_NAMES+=($arg_name)
  ARRAY_FLAGS+=($arg_flag)
  ARRAY_DESCRIPTIONS+=("$arg_desc")
}

# @param arg_description
arg_help() {
  arg="$@"
  t1="${arg#*\[}"
  HELP_DESCRIPTION="${t1%\]*}"
  BOOLEAN_NAMES+=('help')
  BOOLEAN_FLAGS+=('h')
  BOOLEAN_DESCRIPTIONS+=('Print this help message.')
}

parse_args() {
  parse_args2 "${ARGS_ARR[@]}"
  set__dir
}

# @param args_arr
parse_args2() {
  POSITIONAL=()
  found_array_arg=
  while [[ $# -gt 0 ]]; do
    key=$1
    found=
    i=0
    for opt_name in "${BOOLEAN_NAMES[@]}"; do
      opt_flag=${BOOLEAN_FLAGS[$i]}
      case $key in
        -$opt_flag*)
          name_upper=$(echo $opt_name | tr '/a-z-/' '/A-Z_/')
          printf -v "ARG_$name_upper" 'true'
          found=1
          if [[ $key != -$opt_flag ]]; then
            additional_opts="${key##-${opt_flag}}"
            j=0
            for flag in ${BOOLEAN_FLAGS[@]}; do
              if [[ -z ${additional_opts##$flag*} ]]; then
                inner_opt_name="${BOOLEAN_NAMES[$j]}"
                name_upper=$(echo $inner_opt_name | tr '/a-z-/' '/A-Z_/')
                printf -v "ARG_$name_upper" 'true'
                additional_opts="${additional_opts##$flag}"
              fi
              [[ -z $additional_opts ]] && break
              j=$(($j+1))
            done
            j=0
            for flag in ${OPTIONAL_FLAGS[@]}; do
              inner_opt_name="${OPTIONAL_NAMES[$j]}"
              if [[ -z ${additional_opts##*$flag*} ]]; then
                value="${additional_opts##*$flag}"
                name_upper=$(echo $inner_opt_name | tr '/a-z-/' '/A-Z_/')
                printf -v "ARG_$name_upper" "$value"
              fi
              j=$(($j+1))
            done
            j=0
            for flag in ${ARRAY_FLAGS[@]}; do
              inner_opt_name="${ARRAY_NAMES[$j]}"
              if [[ -z ${additional_opts##*$flag*} ]]; then
                value="${additional_opts##*$flag}"
                name_upper=$(echo $inner_opt_name | tr '/a-z-/' '/A-Z_/')
                if [[ -z $found_array_arg ]]; then
                  found_array_arg=1
                  unset "ARG_$name_upper"
                fi
                eval "ARG_$name_upper+=($value)"
              fi
              j=$(($j+1))
            done
          fi
          shift
          ;;
        --$opt_name)
          name_upper=$(echo $opt_name | tr '/a-z-/' '/A-Z_/')
          printf -v "ARG_$name_upper" "true"
          found=1
          shift
          ;;

      esac
      i=$(($i+1))
    done
    i=0
    for opt_name in "${OPTIONAL_NAMES[@]}"; do
      opt_flag="${OPTIONAL_FLAGS[$i]}"
      case $key in
        -$opt_flag*|--$opt_name)
          name_upper=$(echo $opt_name | tr '/a-z-/' '/A-Z_/')
          if [[ $key =~ ^-$opt_flag ]]; then
            if [[ $key == -$opt_flag ]]; then
              val="$2"
              shift; shift
            else
              val="${key/-$opt_flag}"
              shift
            fi
          else
            val="$2"
            shift; shift
          fi
          printf -v "ARG_$name_upper" "$val"
          found=1
          ;;
      esac
      i=$(($i+1))
    done
    i=0
    for opt_name in "${ARRAY_NAMES[@]}"; do
      opt_flag="${ARRAY_FLAGS[$i]}"
      case $key in
        -$opt_flag*|--$opt_name)
          name_upper=$(echo $opt_name | tr '/a-z-/' '/A-Z_/')
          if [[ $key =~ ^-$opt_flag ]]; then
            if [[ $key == -$opt_flag ]]; then
              val="$2"
              shift; shift
            else
              val="${key/-$opt_flag}"
              shift
            fi
          else
            val="$2"
            shift; shift
          fi
          if [[ -z $found_array_arg ]]; then
            found_array_arg=1
            unset "ARG_$name_upper"
          fi
          eval "ARG_$name_upper+=($val)"
          found=1
          ;;
      esac
      i=$(($i+1))
    done
    if [[ -z $found ]]; then
      POSITIONAL+=("$1")
      shift
    fi
  done
  set -- "${POSITIONAL[@]}"

  i=0
  for name in "${POSITIONAL_NAMES[@]}"; do
    arg_i="${POSITIONAL[$i]}"
    [[ -z $arg_i ]] && continue
    name_upper=$(echo $name | tr '/a-z-/' '/A-Z_/')
    printf -v "ARG_$name_upper" "$arg_i"
    i=$(($i+1))
  done

  if [[ -n $ARG_HELP ]]; then
    print_help
    exit 0
  fi
}

print_help() {
  bprint "usage:"
  printf "  ${0##*/} "
  for p_name in "${POSITIONAL_NAMES[@]}"; do
    printf "[$p_name] "
  done
  for bool_flag in "${BOOLEAN_FLAGS[@]}"; do
    printf "[-$bool_flag] "
  done
  i=0
  for opt_name in "${OPTIONAL_NAMES[@]}"; do
    opt_flag="${OPTIONAL_FLAGS[$i]}"
    printf "[-$opt_flag $opt_name] "
    i=$(($i+1))
  done
  i=0
  for opt_name in "${ARRAY_NAMES[@]}"; do
    opt_flag="${ARRAY_FLAGS[$i]}"
    printf "[-$opt_flag $opt_name -$opt_flag ...] "
    i=$(($i+1))
  done
  printf "\n\n$HELP_DESCRIPTION\n\n"
  if [[ -n $POSITIONAL_NAMES ]]; then
    printf "positional arguments:\n"
    i=0
    for p_name in "${POSITIONAL_NAMES[@]}"; do
      p_disp="$(cprint 3 "$p_name")"
      j=0
      printf "${POSITIONAL_DESCRIPTIONS[$i]}\n" | while read line; do
        if [[ $j -eq 0 ]]; then
          printf "  %-37s $line\n" "$p_disp"
        else
          printf "  %-24s $line\n"
        fi
        j=$(($j+1))
      done
      i=$(($i+1))
    done
  fi
  if [[ -n $OPTIONAL_NAMES || -n $BOOLEAN_NAMES || -n $ARRAY_NAMES ]]; then
    [[ -n $POSITIONAL_NAMES ]] && printf "\n"
    printf "optional arguments:\n"
    i=0
    for opt_name in "${ARRAY_NAMES[@]}"; do
      flag_disp="$(cprint 3 "-${ARRAY_FLAGS[$i]}")"
      name_disp="$(cprint 3 "--$opt_name")"
      j=0
      printf "${ARRAY_DESCRIPTIONS[$i]}\n" | while read line; do
        if [[ $j -eq 0 ]]; then
          printf "  %-50s $line\n" "$flag_disp, $name_disp"
        else
          printf "  %-24s $line\n"
        fi
        j=$(($j+1))
      done
      i=$(($i+1))
    done
    i=0
    for opt_name in "${OPTIONAL_NAMES[@]}"; do
      flag_disp="$(cprint 3 "-${OPTIONAL_FLAGS[$i]}")"
      name_disp="$(cprint 3 "--$opt_name")"
      j=0
      printf "${OPTIONAL_DESCRIPTIONS[$i]}\n" | while read line; do
        if [[ $j -eq 0 ]]; then
          printf "  %-50s $line\n" "$flag_disp, $name_disp"
        else
          printf "  %-24s $line\n"
        fi
        j=$(($j+1))
      done
      i=$(($i+1))
    done
    i=0
    for bool_name in "${BOOLEAN_NAMES[@]}"; do
      flag_disp="$(cprint 3 "-${BOOLEAN_FLAGS[$i]}")"
      name_disp="$(cprint 3 "--$bool_name")"
      j=0
      printf "${BOOLEAN_DESCRIPTIONS[$i]}\n" | while read line; do
        if [[ $j -eq 0 ]]; then
          printf "  %-50s $line\n" "$flag_disp, $name_disp"
        else
          printf "  %-24s $line\n"
        fi
        j=$(($j+1))
      done
      i=$(($i+1))
    done
  fi
}
