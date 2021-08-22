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
# @param args [String]
bprint() {
  bprint_string="\033[1m$1\033[0m"
  if [[ "$2" != --quiet ]]; then
    printf "$bprint_string"
  fi
}

# Color print.
#
# @param number [Integer]
# @param text   [String]
# @param args   [String]
cprint() {
  cprint_string="\033[38;5;${1}m${2}\033[0m"
  if [[ "$3" != --quiet ]]; then
    printf "$cprint_string"
  fi
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

get_name_upper() {
  res="${1//-/_}"
  res="${res//a/A}"
  res="${res//b/B}"
  res="${res//c/C}"
  res="${res//d/D}"
  res="${res//e/E}"
  res="${res//f/F}"
  res="${res//g/G}"
  res="${res//h/H}"
  res="${res//i/I}"
  res="${res//j/J}"
  res="${res//k/K}"
  res="${res//l/L}"
  res="${res//m/M}"
  res="${res//n/N}"
  res="${res//o/O}"
  res="${res//p/P}"
  res="${res//q/Q}"
  res="${res//r/R}"
  res="${res//s/S}"
  res="${res//t/T}"
  res="${res//u/U}"
  res="${res//v/V}"
  res="${res//w/W}"
  res="${res//x/X}"
  res="${res//y/Y}"
  name_upper="${res//z/Z}"
}

# Set $__DIR__ variable.
# The full path of the directory of the script.
set__dir() {
  _origin_pwd="$PWD"
  cd "${0%/*}"
  __DIR__="$PWD"
  cd "$_origin_pwd"
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
    for (( i=0; i < ${#BOOLEAN_FLAGS[@]}; i++ )); do
      found_bool=
      opt_flag=${BOOLEAN_FLAGS[$i]}
      opt_name=${BOOLEAN_NAMES[$i]}
      case $key in
        -$opt_flag|--$opt_name)
          found_bool=1
          shift
          ;;
        -$opt_flag*)
          found_bool=1
          shift
          additional_opts="${key#-$opt_flag}"
          for (( j=0; i < ${#OPTIONAL_FLAGS[@]}; j++ )); do
            [[ -z $additional_opts ]] && break
            bundled_flag=${OPTIONAL_FLAGS[$j]}
            if [[ $additional_opts == *$bundled_flag* ]]; then
              value="${additional_opts##*$bundled_flag}"
              get_name_upper "${OPTIONAL_NAMES[$j]}"
              printf -v "ARG_$name_upper" -- "${value//%/%%}"
              additional_opts="${additional_opts%$bundled_flag*}"
            fi
          done
          for (( j=0; j < ${#ARRAY_FLAGS[@]}; j++ )); do
            [[ -z $additional_opts ]] && break
            bundled_flag="${ARRAY_FLAGS[$j]}"
            if [[ $additional_opts == *$bundled_flag* ]]; then
              value="${additional_opts##*$bundled_flag}"
              get_name_upper "${ARRAY_NAMES[$j]}"
              additional_opts="${additional_opts%$bundled_flag*}"
              if [[ -z $found_array_arg ]]; then
                found_array_arg=1
                unset "ARG_$name_upper"
              fi
              eval "ARG_$name_upper+=(${value//%/%%})"
            fi
          done
          for (( j=0; j < ${#BOOLEAN_FLAGS[@]}; j++ )); do
            [[ -z $additional_opts ]] && break
            bundled_flag=${BOOLEAN_FLAGS[$j]}
            if [[ $additional_opts == *$bundled_flag* ]]; then
              get_name_upper "${BOOLEAN_NAMES[$j]}"
              printf -v "ARG_$name_upper" 'true'
              additional_opts="${additional_opts/$bundled_flag/}"
            fi
          done
          ;;
      esac
      if [[ -n $found_bool ]]; then
        get_name_upper "$opt_name"
        printf -v "ARG_$name_upper" 'true'
        found=1
      fi
    done
    for (( i=0; i < ${#OPTIONAL_FLAGS[@]}; i++ )); do
      found_opt=
      opt_flag=${OPTIONAL_FLAGS[$i]}
      opt_name=${OPTIONAL_NAMES[$i]}
      case $key in
        -$opt_flag)
          val="$2"
          found_opt=1
          shift; shift
          ;;
        -$opt_flag*)
          val="${key#-$opt_flag}"
          found_opt=1
          shift
          ;;
        --$opt_name)
          val="$2"
          found_opt=1
          shift; shift
          ;;
        --$opt_name=*)
          val="${key#--$opt_name=}"
          found_opt=1
          shift
          ;;
      esac
      if [[ -n $found_opt ]]; then
        get_name_upper "$opt_name"
        printf -v "ARG_$name_upper" -- "${val//%/%%}"
        found=1
      fi
    done
    for (( i=0; i < ${#ARRAY_NAMES[@]}; i++ )); do
      found_ary_arg=
      opt_flag=${ARRAY_FLAGS[$i]}
      opt_name=${ARRAY_NAMES[$i]}
      case $key in
        -$opt_flag)
          found_ary_arg=1
          val="$2"
          shift; shift
          ;;
        -$opt_flag*)
          found_ary_arg=1
          val="${key#-$opt_flag}"
          shift
          ;;
        --$opt_name)
          found_ary_arg=1
          val="$2"
          shift; shift
          ;;
        --$opt_name=*)
          found_ary_arg=1
          val="${key#--$opt_name=}"
          shift
          ;;
      esac
      if [[ -n $found_ary_arg ]]; then
        get_name_upper "$opt_name"
        if [[ -z $found_array_arg ]]; then
          found_array_arg=1
          unset "ARG_$name_upper"
        fi
        eval "ARG_$name_upper+=(${val//%/%%})"
        found=1
      fi
    done
    if [[ -z $found ]]; then
      POSITIONAL+=("$1")
      shift
    fi
  done
  set -- "${POSITIONAL[@]}"

  for (( i=0; i < ${#POSITIONAL[@]}; i++ )); do
    pos_val=${POSITIONAL[$i]}
    pos_name=${POSITIONAL_NAMES[$i]}
    [[ -z $pos_val ]] && continue
    get_name_upper "$pos_name"
    printf -v "ARG_$name_upper" -- "${pos_val//%/%%}"
  done

  if [[ -n $ARG_HELP ]]; then
    print_help
    exit 0
  fi
}

print_help() {
  : ${HELP_WIDTH:=30}
  X_POS=$(($HELP_WIDTH + 10))
  X_OPT=$(($HELP_WIDTH + 23))
  X_OPT_NL=$(($HELP_WIDTH - 3))
  bprint "usage:"
  printf "  ${0##*/} "
  for p_name in "${POSITIONAL_NAMES[@]}"; do
    printf "[$p_name] "
  done
  for bool_flag in "${BOOLEAN_FLAGS[@]}"; do
    printf "[-$bool_flag] "
  done
  for (( i=0; i < ${#OPTIONAL_FLAGS[@]}; i++ )); do
    printf "[-${OPTIONAL_FLAGS[$i]} ${OPTIONAL_NAMES[$i]}] "
  done
  for (( i=0; i < ${#ARRAY_FLAGS[@]}; i++ )); do
    opt_flag="${ARRAY_FLAGS[$i]}"
    printf "[-$opt_flag ${ARRAY_NAMES[$i]} -$opt_flag ...] "
  done
  echo -e "\n$HELP_DESCRIPTION\n"
  if [[ -n $POSITIONAL_NAMES ]]; then
    printf "positional arguments:\n"
    for (( i=0; i < ${#POSITIONAL_NAMES[@]}; i++ )); do
      cprint 3 "${POSITIONAL_NAMES[$i]}" --quiet
      j=0
      echo "${POSITIONAL_DESCRIPTIONS[$i]}" | while read; do
        if [[ $j -eq 0 ]]; then
          printf "  %-${X_POS}b ${REPLY//%/%%}\n" ${cprint_string}
        else
          printf "  %-${X_OPT_NL}s ${REPLY//%/%%}\n"
        fi
        j=$(($j+1))
      done
    done
  fi
  [[ -z $BOOLEAN_NAMES && -z $OPTIONAL_NAMES && -z $ARRAY_NAMES ]] && return 0
  [[ -n $POSITIONAL_NAMES ]] && printf "\n"
  printf "optional arguments:\n"
  for (( i=0; i < ${#BOOLEAN_FLAGS[@]}; i++ )); do
    cprint 3 "-${BOOLEAN_FLAGS[$i]}" --quiet
    flag_disp="$cprint_string"
    cprint 3 "--${BOOLEAN_NAMES[$i]}" --quiet
    j=0
    echo "${BOOLEAN_DESCRIPTIONS[$i]}" | while read; do
      if [[ $j -eq 0 ]]; then
        printf "  %-${X_OPT}b ${REPLY//%/%%}\n" "$flag_disp, $cprint_string"
      else
        printf "  %-${X_OPT_NL}s ${REPLY//%/%%}\n"
      fi
      j=$(($j+1))
    done
  done
  for (( i=0; i < ${#OPTIONAL_FLAGS[@]}; i++ )); do
    cprint 3 "-${OPTIONAL_FLAGS[$i]}" --quiet
    flag_disp="$cprint_string"
    cprint 3 "--${OPTIONAL_NAMES[$i]}" --quiet
    j=0
    echo "${OPTIONAL_DESCRIPTIONS[$i]}" | while read; do
      if [[ $j -eq 0 ]]; then
        printf "  %-${X_OPT}b ${REPLY//%/%%}\n" "$flag_disp, $cprint_string"
      else
        printf "  %-${X_OPT_NL}s ${REPLY//%/%%}\n"
      fi
      j=$(($j+1))
    done
  done
  for (( i=0; i < ${#ARRAY_FLAGS[@]}; i++ )); do
    cprint 3 "-${ARRAY_FLAGS[$i]}" --quiet
    flag_disp="$cprint_string"
    cprint 3 "--${ARRAY_NAMES[$i]}" --quiet
    j=0
    echo "${ARRAY_DESCRIPTIONS[$i]}" | while read; do
      if [[ $j -eq 0 ]]; then
        printf "  %-${X_OPT}b ${REPLY//%/%%}\n" "$flag_disp, $cprint_string"
      else
        printf "  %-${X_OPT_NL}s ${REPLY//%/%%}\n"
      fi
      j=$(($j+1))
    done
  done
}
