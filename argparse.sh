#!/bin/bash

# argparse.sh
#
# https://github.com/maneyko/argparse.sh
#
# Place this file in your `$PATH' and source it at the top of your script using:
#
#       source "argparse.sh"
#
# Or if argparse.sh is in the same directory as your script, you may use:
#
#       source "$(dirname "$0")/argparse.sh"
#
#
# Example of user calling your script from the command line:
#
#       ./process_file.sh input-data.txt -v --delimiter=',' --expression='$1, $2'
#
# Or more succinctly:
#
#       ./process_file.sh -vd, -e'$1, $2' input-data.txt
#
# Example usage from your script:
#
#       #!/bin/bash
#
#       source "$(dirname "$0")/argparse.sh"
#
#       # Set default value.
#       ARG_DELIMITER=','
#
#       arg_help       "[This script is for processing a text file]"
#       arg_positional "[input-file]     [Input text file to process]"
#       arg_boolean    "[verbose]    [v] [Print information about operations being performed]"
#       arg_optional   "[delimiter]  [d] [Input file field separator. Default: '$ARG_DELIMITER']"
#       arg_optional   "[expression] [e] [Expression passed directly to \`awk '{print ...}'\`]"
#       parse_args
#
#       echo $ARG_INFILE
#       # => input-data.txt
#
#       echo $ARG_DELIMITER
#       # => ,
#
#       echo $ARG_VERBOSE
#       # => true
#
#       if [ -n "$ARG_VERBOSE" ]; then
#        echo 'Beginning processing...'
#       fi
#
#       awk -F "$ARG_DELIMITER" "{print $ARG_EXPRESSION}" "$ARG_INPUT_FILE"
#
#
# The functions the user can use when sourcing this file in their script are:
#
# * arg_positional
#   - This parses positional arguments to your script
#   - The value will be accessible to you via `$ARG_INFILE' after calling `parse_args'.
#   - Usage example: arg_positional "[infile] [The input file]"
#   - CLI example: ./myscript.sh myfile.txt
#
# * arg_optional
#   - This parses optional flags that take a corresponding value
#   - The value will be accessible to you via `$ARG_PORT' after calling `parse_args'.
#     If the flag is not used, the variable `$ARG_PORT' will not be set.
#   - Usage example: arg_optional "[port] [p] [The port to use]"
#   - CLI examples:
#     * ./myscript.sh --port 8080
#     * ./myscript.sh --port=8080
#     * ./myscript.sh -p8080
#
# * arg_boolean
#   - This parses optional flags thats corresponding variable is set to `true'.
#   - The value will be accessible to you via `$ARG_VERBOSE' after calling `parse_args'.
#     If the flag is not used, the variable `$ARG_VERBOSE' will not be set.
#   - Usage example: arg_boolean "[verbose] [v] [Do verbose output]"
#   - CLI example: ./myscript.sh -v
#
# * arg_array
#   - This parses any number of the same flag and stores the values in an array
#   - Usage example: arg_array "[numbers] [n] [Numbers to add together.]"
#   - CLI example: ./myscript.sh -n2 --numbers 12 -n4 --numbers=29
#   - The value will be accessible to you via `$ARG_NUMBERS' after calling `parse_args'.
#     You may access the fourth value by calling `${ARG_NUMBERS[3]}'.
#     In this example `${ARG_NUMBERS[3]}' is `29'.
#     If the flag is not used, the variable `$ARG_NUMBERS' will not be set.
#
# * arg_help
#   - This is optional and will add the `-h' and `--help' flags as arguments to your script.
#   - Usage example: arg_help "[My custom help message]"
#   - CLI example: ./myscript.sh -h
#     All the commands you registered with argparse.sh will be printed to the console in a smart way.
#
# * parse_args
#   - This is a required step and must be run after registering all your variables with argparse.sh.
#
#
# Other methods and variables that will become available to you:
#
# * `$__DIR__'
#   - Full (expanded) path of the directory where your script is located
#
# * `${POSITIONAL[@]}'
#   - Array of positional arguments (including those not parsed by argparse.sh)
#
# * bprint
#   - Print the text as bold, without a trailing newline
#   - Example: bprint "Important!!"
#
# * cprint
#   - Print the text as 8-bit color, without a trailing newline
#   - Example: cprint 1 "ERROR"  # Prints 'ERROR' as red
#
# * print_help
#   - Function to print the help page, automatically done if `-h' flag is present


if [[ ${BASH_VERSINFO[0]} -le 2 ]]; then
  echo 'WARN: argparse.sh is not supported for Bash 2.x or lower.'
  return
fi

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo 'ERROR: You may not execute argparse.sh directly.'
  exit 1
fi

ARGS_ARR=("$@")

POSITIONAL=()
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
bprint() { printf "\033[1m$1\033[0m"; }

# Color print.
#
# @param number [Integer]
# @param text   [String]
cprint()   { printf "\033[38;5;$1m$2\033[0m"; }
cprint_q() { cprint_string="\033[38;5;$1m$2\033[0m"; }

var_name='[0-9A-Za-z_-]+'
optional_space_pat='([[:space:]]+)?'
three_arg_pat="\[($var_name)\]$optional_space_pat(\[([[:alnum:]]{1})?\])?$optional_space_pat(\[(.*)?\])?"

# @param arg_name
# @param arg_description
arg_positional() {
  if [[ "$@" =~ \[($var_name)\]$optional_space_pat(\[(.*)?\])? ]]; then
    POSITIONAL_NAMES+=("${BASH_REMATCH[1]}")
    POSITIONAL_DESCRIPTIONS+=("${BASH_REMATCH[4]}")
  fi
}

# @param arg_name
# @param arg_flag
# @param arg_description
arg_optional() {
  if [[ "$@" =~ $three_arg_pat ]]; then
    OPTIONAL_NAMES+=("${BASH_REMATCH[1]}")
    OPTIONAL_FLAGS+=("${BASH_REMATCH[4]}")
    OPTIONAL_DESCRIPTIONS+=("${BASH_REMATCH[7]}")
  fi
}

# @param arg_name
# @param arg_flag
# @param arg_description
arg_boolean() {
  if [[ "$@" =~ $three_arg_pat ]]; then
    BOOLEAN_NAMES+=("${BASH_REMATCH[1]}")
    BOOLEAN_FLAGS+=("${BASH_REMATCH[4]}")
    BOOLEAN_DESCRIPTIONS+=("${BASH_REMATCH[7]}")
  fi
}

arg_array() {
  if [[ "$@" =~ $three_arg_pat ]]; then
    ARRAY_NAMES+=("${BASH_REMATCH[1]}")
    ARRAY_FLAGS+=("${BASH_REMATCH[4]}")
    ARRAY_DESCRIPTIONS+=("${BASH_REMATCH[7]}")
  fi
}

# @param arg_description
arg_help() {
  if [[ $@ =~ \[(.*)?\] ]]; then
    HELP_DESCRIPTION="${BASH_REMATCH[1]}"
  fi
  BOOLEAN_NAMES+=('help')
  BOOLEAN_FLAGS+=('h')
  BOOLEAN_DESCRIPTIONS+=('Print this help message.')
}

get_name_upper() {
  local res="${1//-/_}"
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
get__dir__() {
  local _origin_pwd="$PWD"
  cd "${0%/*}"
  __DIR__="$PWD"
  cd "$_origin_pwd"
}

parse_args() {
  argparse.sh::parse_args "${ARGS_ARR[@]}"
  get__dir__
}

# @param args_arr
argparse.sh::parse_args() {
  while [[ $# -gt 0 ]]; do
    local key=$1
    local found_arg=
    local \
      found_bool found_opt found_array_arg found_any_array_arg \
      opt_name opt_flag additional_opts bundled_flag value
    for (( i=0; i < ${#BOOLEAN_FLAGS[@]}; i++ )); do
      found_bool=
      opt_flag=${BOOLEAN_FLAGS[$i]}
      opt_name=${BOOLEAN_NAMES[$i]}
      case $key in
        --$opt_name)
          found_bool=1
          shift
          ;;
        -$opt_flag*)
          [[ -z $opt_flag ]] && continue
          found_bool=1
          shift
          additional_opts="${key#-$opt_flag}"
          for (( j=0; j < ${#OPTIONAL_FLAGS[@]}; j++ )); do
            [[ -z $additional_opts ]] && break
            bundled_flag=${OPTIONAL_FLAGS[$j]}
            [[ -z $bundled_flag ]] && continue
            [[ $additional_opts != *$bundled_flag* ]] && continue
            value="${additional_opts#*$bundled_flag}"
            if [[ -z $value ]]; then
              value="$1"
              shift
            fi
            get_name_upper "${OPTIONAL_NAMES[$j]}"
            printf -v "ARG_$name_upper" -- "${value//%/%%}"
            additional_opts="${additional_opts%%$bundled_flag*}"
          done
          for (( j=0; j < ${#ARRAY_FLAGS[@]}; j++ )); do
            [[ -z $additional_opts ]] && break
            bundled_flag="${ARRAY_FLAGS[$j]}"
            [[ -z $bundled_flag ]] && continue
            [[ $additional_opts != *$bundled_flag* ]] && continue
            value="${additional_opts#*$bundled_flag}"
            if [[ -z $value ]]; then
              value="$1"
              shift
            fi
            get_name_upper "${ARRAY_NAMES[$j]}"
            additional_opts="${additional_opts%%$bundled_flag*}"
            if [[ -z $found_any_array_arg ]]; then
              found_any_array_arg=1
              unset "ARG_$name_upper"
            fi
            eval "ARG_$name_upper+=('$value')"
          done
          for (( j=0; j < ${#BOOLEAN_FLAGS[@]}; j++ )); do
            [[ -z $additional_opts ]] && break
            bundled_flag=${BOOLEAN_FLAGS[$j]}
            [[ -z $bundled_flag ]] && continue
            [[ $additional_opts != *$bundled_flag* ]] && continue
            get_name_upper "${BOOLEAN_NAMES[$j]}"
            printf -v "ARG_$name_upper" 'true'
            additional_opts="${additional_opts%%$bundled_flag*}"
          done
          ;;
      esac
      if [[ -n $found_bool ]]; then
        found_arg=1
        get_name_upper "$opt_name"
        printf -v "ARG_$name_upper" 'true'
      fi
    done
    for (( i=0; i < ${#OPTIONAL_FLAGS[@]}; i++ )); do
      found_opt=
      opt_flag=${OPTIONAL_FLAGS[$i]}
      opt_name=${OPTIONAL_NAMES[$i]}
      case $key in
        -$opt_flag)
          [[ -z $opt_flag ]] && continue
          found_opt=1
          val="$2"
          shift; shift
          ;;
        -$opt_flag*)
          [[ -z $opt_flag ]] && continue
          found_opt=1
          val="${key#-$opt_flag}"
          shift
          ;;
        --$opt_name)
          found_opt=1
          val="$2"
          shift; shift
          ;;
        --$opt_name=*)
          found_opt=1
          val="${key#--$opt_name=}"
          shift
          ;;
      esac
      if [[ -n $found_opt ]]; then
        found_arg=1
        get_name_upper "$opt_name"
        printf -v "ARG_$name_upper" -- "${val//%/%%}"
      fi
    done
    for (( i=0; i < ${#ARRAY_NAMES[@]}; i++ )); do
      found_array_arg=
      opt_flag=${ARRAY_FLAGS[$i]}
      opt_name=${ARRAY_NAMES[$i]}
      case $key in
        -$opt_flag)
          [[ -z $opt_flag ]] && continue
          found_array_arg=1
          val="$2"
          shift; shift
          ;;
        -$opt_flag*)
          [[ -z $opt_flag ]] && continue
          found_array_arg=1
          val="${key#-$opt_flag}"
          shift
          ;;
        --$opt_name)
          found_array_arg=1
          val="$2"
          shift; shift
          ;;
        --$opt_name=*)
          found_array_arg=1
          val="${key#--$opt_name=}"
          shift
          ;;
      esac
      if [[ -n $found_array_arg ]]; then
        get_name_upper "$opt_name"
        if [[ -z $found_any_array_arg ]]; then
          found_any_array_arg=1
          unset "ARG_$name_upper"
        fi
        eval "ARG_$name_upper+=('$val')"
        found_arg=1
      fi
    done
    if [[ -z $found_arg ]]; then
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
  local X_POS=$(($HELP_WIDTH + 10))
  local X_OPT=$(($HELP_WIDTH + 23))
  local X_OPT_NL=$(($HELP_WIDTH - 3))
  local j opt_flag flag_disp
  bprint "usage:"
  printf "  ${0##*/} "
  for p_name in "${POSITIONAL_NAMES[@]}"; do
    printf "[$p_name] "
  done
  for bool_flag in "${BOOLEAN_FLAGS[@]}"; do
    [[ -z $bool_flag ]] && continue
    printf "[-$bool_flag] "
  done
  for (( i=0; i < ${#OPTIONAL_FLAGS[@]}; i++ )); do
    [[ -z ${OPTIONAL_FLAGS[$i]} ]] && continue
    printf "[-${OPTIONAL_FLAGS[$i]} ${OPTIONAL_NAMES[$i]}] "
  done
  for (( i=0; i < ${#ARRAY_FLAGS[@]}; i++ )); do
    opt_flag="${ARRAY_FLAGS[$i]}"
    [[ -z $opt_flag ]] && continue
    printf "[-$opt_flag ${ARRAY_NAMES[$i]} -$opt_flag ...] "
  done
  echo -e "\n$HELP_DESCRIPTION\n"
  if [[ -n $POSITIONAL_NAMES ]]; then
    printf "positional arguments:\n"
    for (( i=0; i < ${#POSITIONAL_NAMES[@]}; i++ )); do
      cprint_q 3 "${POSITIONAL_NAMES[$i]}"
      j=
      echo "${POSITIONAL_DESCRIPTIONS[$i]}" | while read; do
        if [[ -z $j ]]; then
          j=1
          printf "  %-${X_POS}b ${REPLY//%/%%}\n" ${cprint_string}
        else
          printf "  %-${X_OPT_NL}s ${REPLY//%/%%}\n"
        fi
      done
    done
  fi
  [[ -z $BOOLEAN_NAMES && -z $OPTIONAL_NAMES && -z $ARRAY_NAMES ]] && return 0
  [[ -n $POSITIONAL_NAMES ]] && printf "\n"
  printf "optional arguments:\n"
  for (( i=0; i < ${#BOOLEAN_FLAGS[@]}; i++ )); do
    if [[ -n ${BOOLEAN_FLAGS[$i]} ]]; then
      cprint_q 3 "-${BOOLEAN_FLAGS[$i]}"
      flag_disp="$cprint_string,"
    else
      cprint_q 3 "  "
      flag_disp="$cprint_string "
    fi
    cprint_q 3 "--${BOOLEAN_NAMES[$i]}"
    j=
    echo "${BOOLEAN_DESCRIPTIONS[$i]}" | while read; do
      if [[ -z $j ]]; then
        j=1
        printf "  %-${X_OPT}b ${REPLY//%/%%}\n" "$flag_disp $cprint_string"
      else
        printf "  %-${X_OPT_NL}s ${REPLY//%/%%}\n"
      fi
    done
  done
  for (( i=0; i < ${#OPTIONAL_FLAGS[@]}; i++ )); do
    if [[ -n ${OPTIONAL_FLAGS[$i]} ]]; then
      cprint_q 3 "-${OPTIONAL_FLAGS[$i]}"
      flag_disp="$cprint_string,"
    else
      cprint_q 3 "  "
      flag_disp="$cprint_string "
    fi
    cprint_q 3 "--${OPTIONAL_NAMES[$i]}"
    j=
    echo "${OPTIONAL_DESCRIPTIONS[$i]}" | while read; do
      if [[ -z $j ]]; then
        j=1
        printf "  %-${X_OPT}b ${REPLY//%/%%}\n" "$flag_disp $cprint_string"
      else
        printf "  %-${X_OPT_NL}s ${REPLY//%/%%}\n"
      fi
    done
  done
  for (( i=0; i < ${#ARRAY_FLAGS[@]}; i++ )); do
    if [[ -n ${ARRAY_FLAGS[$i]} ]]; then
      cprint_q 3 "-${ARRAY_FLAGS[$i]}"
      flag_disp="$cprint_string,"
    else
      cprint_q 3 "  "
      flag_disp="$cprint_string "
    fi
    cprint_q 3 "--${ARRAY_NAMES[$i]}"
    j=
    echo "${ARRAY_DESCRIPTIONS[$i]}" | while read; do
      if [[ -z $j ]]; then
        j=1
        printf "  %-${X_OPT}b ${REPLY//%/%%}\n" "$flag_disp $cprint_string"
      else
        printf "  %-${X_OPT_NL}s ${REPLY//%/%%}\n"
      fi
    done
  done
}
