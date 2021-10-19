#!/bin/bash

# argparse.sh -- https://github.com/maneyko/argparse.sh
#
# Place this file in your `$PATH' and source it at the top of your script using:
#
#     source "argparse.sh"
#
# Or if argparse.sh is in the same directory as your script, you may use:
#
#     source "$(dirname "$0")/argparse.sh"
#
#
# Example of a user calling your script from the command line:
#
#     ./process_file.sh input-data.txt -v --delimiter=',' --expression='$1, $2'
#
# Or more succinctly:
#
#     ./process_file.sh -vd, -e'$1, $2' input-data.txt
#
# Example usage from your script:
#
#     #!/bin/bash
#
#     source "$(dirname "$0")/argparse.sh"
#
#     # Set default value.
#     ARG_DELIMITER=','
#
#     arg_help       "[This script is for processing a text file]"
#     arg_positional "[input-file]     [Input text file to process]"
#     arg_boolean    "[verbose]    [v] [Print information about operations being performed]"
#     arg_optional   "[delimiter]  [d] [Input file field separator. Default: '$ARG_DELIMITER']"
#     arg_optional   "[expression] [e] [Expression passed directly to ( awk '{print ...}' )]"
#     parse_args
#
#     echo $ARG_INFILE
#     # => input-data.txt
#
#     echo $ARG_DELIMITER
#     # => ,
#
#     echo $ARG_VERBOSE
#     # => true
#
#     if [ -n "$ARG_VERBOSE" ]; then
#       echo 'Beginning processing...'
#     fi
#
#     awk -F "$ARG_DELIMITER" "{print $ARG_EXPRESSION}" "$ARG_INPUT_FILE"
#
#
# The functions the programmer can use when sourcing this file in their script are:
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
#   - Full (expanded) path of the directory where your script is located. Does not resolve symlinks.
#     To resolve symlinks you can use Perl:
#       __DIR__="$(perl -MCwd -e "print Cwd::abs_path shift" "$__DIR__")"
#
# * `$__FILE__'
#   - Full (expanded) path of the script location. Does not resolve symlinks.
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
# @param text [String]
bprint() { printf -- "%b" "\033[1m$1\033[0m"; }

# Color print.
#
# @param number [Integer]
# @param text   [String]
cprint()   { printf -- "%b" "\033[38;5;$1m$2\033[0m"; }
cprint_q() {  cprint_string="\033[38;5;$1m$2\033[0m"; }

optional_space_pat='([[:space:]]+)?'
arg_name_pat="([0-9A-Za-z_-]{2,})"
arg_flag_pat="([[:alnum:]]{1,2})"
arg_help_pat="(\[(.*)\])"
arg_positional_pat="\[${arg_name_pat}\]${optional_space_pat}${arg_help_pat}?"
three_arg_pat="\[${arg_name_pat}?\]?${optional_space_pat}\[?${arg_flag_pat}?\]${optional_space_pat}${arg_help_pat}?"

# @param arg_name
# @param arg_description
arg_positional() {
  if [[ "$@" =~ $arg_positional_pat ]]; then
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
    OPTIONAL_FLAGS+=("${BASH_REMATCH[3]}")
    OPTIONAL_DESCRIPTIONS+=("${BASH_REMATCH[6]}")
  fi
}

# @param arg_name
# @param arg_flag
# @param arg_description
arg_boolean() {
  if [[ "$@" =~ $three_arg_pat ]]; then
    BOOLEAN_NAMES+=("${BASH_REMATCH[1]}")
    BOOLEAN_FLAGS+=("${BASH_REMATCH[3]}")
    BOOLEAN_DESCRIPTIONS+=("${BASH_REMATCH[6]}")
  fi
}

arg_array() {
  if [[ "$@" =~ $three_arg_pat ]]; then
    ARRAY_NAMES+=("${BASH_REMATCH[1]}")
    ARRAY_FLAGS+=("${BASH_REMATCH[3]}")
    ARRAY_DESCRIPTIONS+=("${BASH_REMATCH[6]}")
  fi
}

# @param arg_description
arg_help() {
  if [[ "$@" =~ $arg_help_pat ]]; then
    HELP_DESCRIPTION=${BASH_REMATCH[2]}
  fi
  BOOLEAN_NAMES+=('help')
  BOOLEAN_FLAGS+=('h')
  BOOLEAN_DESCRIPTIONS+=('Print this help message.')
}

get_name_upper() {
  local res=${1//-/_}
  res=${res//a/A}
  res=${res//b/B}
  res=${res//c/C}
  res=${res//d/D}
  res=${res//e/E}
  res=${res//f/F}
  res=${res//g/G}
  res=${res//h/H}
  res=${res//i/I}
  res=${res//j/J}
  res=${res//k/K}
  res=${res//l/L}
  res=${res//m/M}
  res=${res//n/N}
  res=${res//o/O}
  res=${res//p/P}
  res=${res//q/Q}
  res=${res//r/R}
  res=${res//s/S}
  res=${res//t/T}
  res=${res//u/U}
  res=${res//v/V}
  res=${res//w/W}
  res=${res//x/X}
  res=${res//y/Y}
  name_upper=${res//z/Z}
}

# Set $__DIR__ variable.
# The full path of the directory of the script.
get__dir__() {
  local _origin_pwd=$PWD
  cd "${0%/*}"
  __DIR__=$PWD
  cd "$_origin_pwd"
}

parse_args() {
  argparse.sh::parse_args "${ARGS_ARR[@]}"
  get__dir__
  __FILE__="$__DIR__/${0##*/}"
}

# @param args_arr
argparse.sh::parse_args() {

  impossible_regex='$.^'

  long_flag_regex=
  for (( i=0; i < ${#BOOLEAN_NAMES[@]}; i++ )); do
    opt_flag=${BOOLEAN_NAMES[$i]}
    : ${opt_flag:=$impossible_regex}
    long_flag_regex="$long_flag_regex($opt_flag)|"
  done
  long_flag_regex=${long_flag_regex%|}

  short_flag_regex=
  for (( i=0; i < ${#BOOLEAN_FLAGS[@]}; i++ )); do
    opt_flag=${BOOLEAN_FLAGS[$i]}
    : ${opt_flag:=$impossible_regex}
    short_flag_regex="$short_flag_regex($opt_flag)|"
  done
  short_flag_regex=${short_flag_regex%|}

  long_opt_regex=
  for (( i=0; i < ${#OPTIONAL_NAMES[@]}; i++ )); do
    opt_flag=${OPTIONAL_NAMES[$i]}
    : ${opt_flag:=$impossible_regex}
    long_opt_regex="$long_opt_regex($opt_flag)|"
  done
  long_opt_regex=${long_opt_regex%|}

  short_opt_regex=
  for (( i=0; i < ${#OPTIONAL_FLAGS[@]}; i++ )); do
    opt_flag=${OPTIONAL_FLAGS[$i]}
    : ${opt_flag:=$impossible_regex}
    short_opt_regex="$short_opt_regex($opt_flag)|"
  done
  short_opt_regex=${short_opt_regex%|}

  long_arr_regex=
  for (( i=0; i < ${#ARRAY_NAMES[@]}; i++ )); do
    opt_flag=${ARRAY_NAMES[$i]}
    : ${opt_flag:=$impossible_regex}
    long_arr_regex="$long_arr_regex($opt_flag)|"
  done
  long_arr_regex=${long_arr_regex%|}

  short_arr_regex=
  for (( i=0; i < ${#ARRAY_FLAGS[@]}; i++ )); do
    opt_flag=${ARRAY_FLAGS[$i]}
    : ${opt_flag:=$impossible_regex}
    short_arr_regex="$short_arr_regex($opt_flag)|"
  done
  short_arr_regex=${short_arr_regex%|}

  while [[ $# -gt 0 ]]; do
    key=$1
    value=

    if [[ $key =~ ^--($long_flag_regex)$ && -n ${BASH_REMATCH[1]} ]]; then
      shift
      matches=("${BASH_REMATCH[@]:2}")
      for (( i=0; i < ${#matches[@]}; i++ )); do
        if [[ -n ${matches[$i]} ]]; then
          opt_name=${BOOLEAN_NAMES[$i]}
          break
        fi
      done
      get_name_upper "$opt_name"
      export -n ARG_$name_upper=true
      continue
    fi

    if [[ $key =~ ^-($short_flag_regex) && -n ${BASH_REMATCH[1]} ]]; then
      shift
      matches=("${BASH_REMATCH[@]:2}")
      for (( i=0; i < ${#matches[@]}; i++ )); do
        if [[ -n ${matches[$i]} ]]; then
          opt_flag=${BOOLEAN_FLAGS[$i]}
          opt_name=${BOOLEAN_NAMES[$i]}
          break
        fi
      done

      if [[ -z $opt_name ]]; then
        get_name_upper "$opt_flag"
      else
        get_name_upper "$opt_name"
      fi
      export -n ARG_$name_upper=true
      additional_opts=${key#-$opt_flag}
      [[ -z $additional_opts ]] && continue

      # <Bundled arguments>

      longest_match_o_n=-1
      longest_match_a_n=-1

      if [[ $additional_opts =~ ($short_opt_regex)(.*) && -n ${BASH_REMATCH[1]} ]]; then
        optional_count=${#OPTIONAL_FLAGS[@]}
        longest_match_o=${BASH_REMATCH[$(($optional_count + 2))]}
        longest_match_o_n=${#longest_match_o}

        matches=("${BASH_REMATCH[@]:2}")
        for (( i=0; i < ${#matches[@]}; i++ )); do
          if [[ -n ${matches[$i]} ]]; then
            opt_flag_o=${OPTIONAL_FLAGS[$i]}
            opt_name_o=${OPTIONAL_NAMES[$i]}
            break
          fi
        done
      fi

      if [[ $additional_opts =~ ($short_arr_regex)(.*) && -n ${BASH_REMATCH[1]} ]]; then
        array_count=${#ARRAY_FLAGS[@]}
        longest_match_a=${BASH_REMATCH[$(($array_count + 2))]}
        longest_match_a_n=${#longest_match_a}

        matches=("${BASH_REMATCH[@]:2}")
        for (( i=0; i < ${#matches[@]}; i++ )); do
          if [[ -n ${matches[$i]} ]]; then
            opt_flag_a=${ARRAY_FLAGS[$i]}
            opt_name_a=${ARRAY_NAMES[$i]}
            break
          fi
        done
      fi

      if [[ $longest_match_o_n -gt -1 || $longest_match_a_n -gt -1 ]]; then
        if [[ $longest_match_o_n -ge $longest_match_a_n ]]; then
          bundled_flag=$opt_flag_o
          bundled_name=$opt_name_o
          value=$longest_match_o
        else
          bundled_flag=$opt_flag_a
          bundled_name=$opt_name_a
          value=$longest_match_a
        fi
        if [[ -n $bundled_name ]]; then
          get_name_upper $bundled_name
        else
          get_name_upper $bundled_flag
        fi
        if [[ -z $value ]]; then
          value=$1
          shift
        fi
        additional_opts=${additional_opts%%$bundled_flag*}

        if [[ $longest_match_a_n -gt $longest_match_o_n ]]; then
          found_name=_found_$name_upper

          if [[ -z ${!found_name} ]]; then
            unset ARG_$name_upper
            export -n "$found_name"=true
          fi
          eval "ARG_$name_upper+=('$value')"
        else
          export -n -- ARG_$name_upper="$value"
        fi
      fi

      if [[ $additional_opts =~ ($short_flag_regex) && -n ${BASH_REMATCH[1]} ]]; then
        matches=("${BASH_REMATCH[@]:2}")
        for (( i=0; i < ${#matches[@]}; i++ )); do
          if [[ -n ${matches[$i]} ]]; then
            opt_name=${BOOLEAN_NAMES[$i]}
            opt_flag=${BOOLEAN_FLAGS[$i]}
            if [[ -z $opt_name ]]; then
              get_name_upper "$opt_flag"
            else
              get_name_upper "$opt_name"
            fi
            export -n ARG_$name_upper=true
          fi
        done
      fi
      continue

      # </Bundled arguments>
    fi

    if [[ $key =~ ^--($long_opt_regex) && -n ${BASH_REMATCH[1]} ]]; then
      shift
      matches=("${BASH_REMATCH[@]:2}")
      for (( i=0; i < ${#matches[@]}; i++ )); do
        if [[ -n ${matches[$i]} ]]; then
          opt_name=${OPTIONAL_NAMES[$i]}
          break
        fi
      done

      if [[ $key =~ ^--$opt_name=(.*) ]]; then
        value=${BASH_REMATCH[1]}
      elif [[ $key =~ ^--${opt_name}$ ]]; then
        value=$1
        shift
      else
        continue
      fi

      get_name_upper "$opt_name"
      export -n -- ARG_$name_upper="$value"
      continue
    fi

    if [[ $key =~ ^-($short_opt_regex) && -n ${BASH_REMATCH[1]} ]]; then
      shift
      matches=("${BASH_REMATCH[@]:2}")
      for (( i=0; i < ${#matches[@]}; i++ )); do
        if [[ -n ${matches[$i]} ]]; then
          opt_name=${OPTIONAL_NAMES[$i]}
          opt_flag=${OPTIONAL_FLAGS[$i]}
          break
        fi
      done

      if [[ $key =~ ^-$opt_flag(.+) ]]; then
        value=${BASH_REMATCH[1]}
      elif [[ $key =~ ^-${opt_flag}$ ]]; then
        value=$1
        shift
      else
        continue
      fi

      if [[ -z $opt_name ]]; then
        get_name_upper "$opt_flag"
      else
        get_name_upper "$opt_name"
      fi
      export -n -- ARG_$name_upper="$value"
      continue
    fi

    if [[ $key =~ ^--($long_arr_regex) && -n ${BASH_REMATCH[1]} ]]; then
      shift
      matches=("${BASH_REMATCH[@]:2}")
      for (( i=0; i < ${#matches[@]}; i++ )); do
        if [[ -n ${matches[$i]} ]]; then
          opt_name=${ARRAY_NAMES[$i]}
          break
        fi
      done

      if [[ $key =~ ^--$opt_name=(.*) ]]; then
        value=${BASH_REMATCH[1]}
      elif [[ $key =~ ^--${opt_name}$ ]]; then
        value=$1
        shift
      else
        continue
      fi
      get_name_upper "$opt_name"

      found_name=_found_$name_upper

      if [[ -z ${!found_name} ]]; then
        unset ARG_$name_upper
        export -n $found_name=true
      fi
      eval "ARG_$name_upper+=('$value')"
      continue
    fi

    if [[ $key =~ ^-($short_arr_regex) && -n ${BASH_REMATCH[1]} ]]; then
      shift
      matches=("${BASH_REMATCH[@]:2}")
      for (( i=0; i < ${#matches[@]}; i++ )); do
        if [[ -n ${matches[$i]} ]]; then
          opt_name=${ARRAY_NAMES[$i]}
          opt_flag=${ARRAY_FLAGS[$i]}
          break
        fi
      done

      if [[ $key =~ ^-$opt_flag(.+) ]]; then
        value=${BASH_REMATCH[1]}
      elif [[ $key =~ ^-${opt_flag}$ ]]; then
        value=$1
        shift
      else
        continue
      fi

      if [[ -z $opt_name ]]; then
        get_name_upper "$opt_flag"
      else
        get_name_upper "$opt_name"
      fi

      found_name=_found_$name_upper

      if [[ -z ${!found_name} ]]; then
        unset ARG_$name_upper
        export -n $found_name=true
      fi
      eval "ARG_$name_upper+=('$value')"
      continue
    fi

    POSITIONAL+=("$key")
    shift
  done

  set -- "${POSITIONAL[@]}"

  for (( i=0; i < ${#POSITIONAL[@]}; i++ )); do
    pos_val=${POSITIONAL[$i]}
    pos_name=${POSITIONAL_NAMES[$i]}
    get_name_upper "$pos_name"
    export -n -- ARG_$name_upper="$pos_val"
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
  local j opt_flag opt_name flag_disp
  bprint "usage:"
  printf "  ${0##*/} "
  for p_name in "${POSITIONAL_NAMES[@]}"; do
    printf "[$p_name] "
  done
  for (( i=0; i < ${#BOOLEAN_FLAGS[@]}; i++ )); do
    bool_flag="${BOOLEAN_FLAGS[$i]}"
    if [[ -n $bool_flag ]]; then
      printf "[-$bool_flag] "
    else
      printf "[--${BOOLEAN_NAMES[$i]}] "
    fi
  done
  for (( i=0; i < ${#OPTIONAL_FLAGS[@]}; i++ )); do
    opt_name="${OPTIONAL_NAMES[$i]}"
    : ${opt_name:="STRING"}
    if [[ -n ${OPTIONAL_FLAGS[$i]} ]]; then
      printf "[-${OPTIONAL_FLAGS[$i]} $opt_name] "
    else
      printf "[--$opt_name=STRING] "
    fi
  done
  for (( i=0; i < ${#ARRAY_FLAGS[@]}; i++ )); do
    opt_flag="${ARRAY_FLAGS[$i]}"
    opt_name="${ARRAY_NAMES[$i]}"
    : ${opt_name:="STRING"}
    if [[ -n $opt_flag ]]; then
      printf "[-$opt_flag $opt_name -$opt_flag ...] "
    else
      printf "[--$opt_name=ARG1 --$opt_name=ARG2 ...] "
    fi
  done
  if [[
    ${#BOOLEAN_FLAGS[@]}  -gt 0 || ${#BOOLEAN_NAMES[@]}  -gt 0 ||
    ${#OPTIONAL_FLAGS[@]} -gt 0 || ${#OPTIONAL_NAMES[@]} -gt 0 ||
    ${#ARRAY_FLAGS[@]}    -gt 0 || ${#ARRAY_NAMES[@]}    -gt 0
  ]]; then
    has_any_optional_flags=true
  else
    unset has_any_optional_flags
  fi
  printf -- "\n%b\n" "$HELP_DESCRIPTION"
  [[ -n $has_any_optional_flags || ${#POSITIONAL_NAMES[@]} -gt 0 ]] && echo
  [[ ${#POSITIONAL_NAMES[@]} -gt 0 ]] && echo "positional arguments:"
  for (( i=0; i < ${#POSITIONAL_NAMES[@]}; i++ )); do
    cprint_q 3 "${POSITIONAL_NAMES[$i]}"
    j=
    echo "${POSITIONAL_DESCRIPTIONS[$i]}" | while read -r; do
      if [[ -z $j ]]; then
        j=1
        printf -- "  %-${X_POS}b %b\n" "${cprint_string}" "$REPLY"
      else
        printf -- "  %-${X_OPT_NL}s %b\n" ' ' "$REPLY"
      fi
    done
  done
  [[ ${#POSITIONAL_NAMES[@]} -gt 0 ]] && echo
  [[ -n $has_any_optional_flags ]] && echo "optional arguments:"
  for (( i=0; i < ${#BOOLEAN_FLAGS[@]}; i++ )); do
    if [[ -n ${BOOLEAN_FLAGS[$i]} ]]; then
      cprint_q 3 "-${BOOLEAN_FLAGS[$i]}"
      flag_disp="$cprint_string"
    else
      cprint_q 3 "  "
      flag_disp="$cprint_string "
    fi
    if [[ -n ${BOOLEAN_NAMES[$i]} ]]; then
      cprint_q 3 "--${BOOLEAN_NAMES[$i]}"
    else
      cprint_q 3 "  "
    fi
    if [[ -n ${BOOLEAN_FLAGS[$i]} && -n ${BOOLEAN_NAMES[$i]} ]]; then
      flag_disp="$flag_disp,"
    fi
    j=
    echo "${BOOLEAN_DESCRIPTIONS[$i]}" | while read -r; do
      if [[ -z $j ]]; then
        j=1
        printf -- "  %-${X_OPT}b %b\n" "$flag_disp $cprint_string" "$REPLY"
      else
        printf -- "  %-${X_OPT_NL}s %b\n" ' ' "$REPLY"
      fi
    done
  done
  for (( i=0; i < ${#OPTIONAL_FLAGS[@]}; i++ )); do
    if [[ -n ${OPTIONAL_FLAGS[$i]} ]]; then
      cprint_q 3 "-${OPTIONAL_FLAGS[$i]}"
      flag_disp="$cprint_string"
    else
      cprint_q 3 "  "
      flag_disp="$cprint_string "
    fi
    if [[ -n ${OPTIONAL_NAMES[$i]} ]]; then
      cprint_q 3 "--${OPTIONAL_NAMES[$i]}"
    else
      cprint_q 3 "  "
    fi
    if [[ -n ${OPTIONAL_FLAGS[$i]} && -n ${OPTIONAL_NAMES[$i]} ]]; then
      flag_disp="$flag_disp,"
    fi
    j=
    echo "${OPTIONAL_DESCRIPTIONS[$i]}" | while read -r; do
      if [[ -z $j ]]; then
        j=1
        printf -- "  %-${X_OPT}b %b\n" "$flag_disp $cprint_string" "$REPLY"
      else
        printf -- "  %-${X_OPT_NL}s %b\n" ' ' "$REPLY"
      fi
    done
  done
  for (( i=0; i < ${#ARRAY_FLAGS[@]}; i++ )); do
    if [[ -n ${ARRAY_FLAGS[$i]} ]]; then
      cprint_q 3 "-${ARRAY_FLAGS[$i]}"
      flag_disp="$cprint_string"
    else
      cprint_q 3 "  "
      flag_disp="$cprint_string "
    fi
    if [[ -n ${ARRAY_NAMES[$i]} ]]; then
      cprint_q 3 "--${ARRAY_NAMES[$i]}"
    else
      cprint_q 3 "  "
    fi
    if [[ -n ${ARRAY_FLAGS[$i]} && -n ${ARRAY_NAMES[$i]} ]]; then
      flag_disp="$flag_disp,"
    fi
    j=
    echo "${ARRAY_DESCRIPTIONS[$i]}" | while read -r; do
      if [[ -z $j ]]; then
        j=1
        printf -- "  %-${X_OPT}b %b\n" "$flag_disp $cprint_string" "$REPLY"
      else
        printf -- "  %-${X_OPT_NL}s %b\n" ' ' "$REPLY"
      fi
    done
  done
}
