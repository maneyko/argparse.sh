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
  echo 'ERROR: argparse.sh is not supported for Bash 2.x or lower.' >&2
  exit 1
fi

if [[ ${BASH_SOURCE[0]} == $0 ]]; then
  echo 'ERROR: You may not execute argparse.sh directly.' >&2
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

impossible_match_pat='$.^'
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
    POSITIONAL_NAMES[${#POSITIONAL_NAMES[@]}]=${BASH_REMATCH[1]}
    POSITIONAL_DESCRIPTIONS[${#POSITIONAL_DESCRIPTIONS[@]}]=${BASH_REMATCH[4]}
  fi
}

# @param arg_name
# @param arg_flag
# @param arg_description
long_flag_regex=
short_flag_regex=
arg_boolean() {
  if [[ "$@" =~ $three_arg_pat ]]; then
    opt_name=${BASH_REMATCH[1]}
    opt_flag=${BASH_REMATCH[3]}
    BOOLEAN_NAMES[${#BOOLEAN_NAMES[@]}]=$opt_name
    BOOLEAN_FLAGS[${#BOOLEAN_FLAGS[@]}]=$opt_flag
    BOOLEAN_DESCRIPTIONS[${#BOOLEAN_DESCRIPTIONS[@]}]=${BASH_REMATCH[6]}

    export -n _ARG_${opt_flag:-${opt_name//-/_}}_NAME=$opt_name
    long_flag_regex+="(${opt_name:-$impossible_match_pat})|"
    short_flag_regex+="(${opt_flag:-$impossible_match_pat})|"
  fi
}

# @param arg_name
# @param arg_flag
# @param arg_description
long_opt_regex=
short_opt_regex=
arg_optional() {
  if [[ "$@" =~ $three_arg_pat ]]; then
    opt_name=${BASH_REMATCH[1]}
    opt_flag=${BASH_REMATCH[3]}
    OPTIONAL_NAMES[${#OPTIONAL_NAMES[@]}]=$opt_name
    OPTIONAL_FLAGS[${#OPTIONAL_FLAGS[@]}]=$opt_flag
    OPTIONAL_DESCRIPTIONS[${#OPTIONAL_DESCRIPTIONS[@]}]=${BASH_REMATCH[6]}

    export -n _ARG_${opt_flag:-${opt_name//-/_}}_NAME=$opt_name
    long_opt_regex+="(${opt_name:-$impossible_match_pat})|"
    short_opt_regex+="(${opt_flag:-$impossible_match_pat})|"
  fi
}

# @param arg_name
# @param arg_flag
# @param arg_description
long_arr_regex=
short_arr_regex=
arg_array() {
  if [[ "$@" =~ $three_arg_pat ]]; then
    opt_name=${BASH_REMATCH[1]}
    opt_flag=${BASH_REMATCH[3]}
    ARRAY_NAMES[${#ARRAY_NAMES[@]}]=$opt_name
    ARRAY_FLAGS[${#ARRAY_FLAGS[@]}]=$opt_flag
    ARRAY_DESCRIPTIONS[${#ARRAY_DESCRIPTIONS[@]}]=${BASH_REMATCH[6]}

    export -n _ARG_${opt_flag:-${opt_name//-/_}}_NAME=$opt_name
    long_arr_regex+="(${opt_name:-$impossible_match_pat})|"
    short_arr_regex+="(${opt_flag:-$impossible_match_pat})|"
  fi
}

# @param arg_description
arg_help() {
  if [[ "$@" =~ $arg_help_pat ]]; then
    HELP_DESCRIPTION=${BASH_REMATCH[2]}
  fi
  BOOLEAN_NAMES[${#BOOLEAN_NAMES[@]}]=help
  BOOLEAN_FLAGS[${#BOOLEAN_FLAGS[@]}]=h
  BOOLEAN_DESCRIPTIONS[${#BOOLEAN_DESCRIPTIONS[@]}]='Print this help message.'

  export -n _ARG_h_NAME=help
  long_flag_regex+="(help)|"
  short_flag_regex+="(h)|"
}

get_name_upper() {
  local res=${name_upper_arg//-/_}
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
  cd "${0%/*}"
  __DIR__=$PWD
  cd "$OLDPWD"
}

parse_args() {
  argparse.sh::parse_args "${ARGS_ARR[@]}"
  get__dir__
  __FILE__=$__DIR__/${0##*/}
}

# @param args_arr
argparse.sh::parse_args() {
  long_flag_regex=${long_flag_regex%|}
  : ${long_flag_regex:=($impossible_match_pat)}
  short_flag_regex=${short_flag_regex%|}
  : ${short_flag_regex:=($impossible_match_pat)}
  long_opt_regex=${long_opt_regex%|}
  : ${long_opt_regex:=($impossible_match_pat)}
  short_opt_regex=${short_opt_regex%|}
  : ${short_opt_regex:=($impossible_match_pat)}
  long_arr_regex=${long_arr_regex%|}
  : ${long_arr_regex:=($impossible_match_pat)}
  short_arr_regex=${short_arr_regex%|}
  : ${short_arr_regex:=($impossible_match_pat)}

  local match opt_name opt_flag name_var value

  while [[ $# -gt 0 ]]; do
    key=$1
    value=
    shift

    if [[ $key =~ ^--($long_flag_regex)$ ]]; then
      opt_name=${BASH_REMATCH[1]}
      name_upper_arg=$opt_name
      get_name_upper
      export -n ARG_$name_upper=true

    elif [[ $key =~ ^-($short_flag_regex) ]]; then
      opt_flag=${BASH_REMATCH[1]}
      name_var=_ARG_${opt_flag}_NAME
      opt_name=${!name_var}

      name_upper_arg=${opt_name:-$opt_flag}
      get_name_upper
      export -n ARG_$name_upper=true
      bundled_args=${key#-$opt_flag}
      [[ -z $bundled_args ]] && continue

      # <Bundled arguments>

      match_o_n=-1
      match_a_n=-1

      if [[ $bundled_args =~ ($short_opt_regex)(.*) ]]; then
        match_o=${BASH_REMATCH[@]: -1}
        match_o_n=${#match_o}
        opt_flag_o=${BASH_REMATCH[1]}
        name_var=_ARG_${opt_flag_o}_NAME
        opt_name_o=${!name_var}
      fi

      if [[ $bundled_args =~ ($short_arr_regex)(.*) ]]; then
        match_a=${BASH_REMATCH[@]: -1}
        match_a_n=${#match_a}
        opt_flag_a=${BASH_REMATCH[1]}
        name_var=_ARG_${opt_flag_a}_NAME
        opt_name_a=${!name_var}
      fi

      if [[ $match_o_n -gt -1 || $match_a_n -gt -1 ]]; then
        if [[ $match_o_n -ge $match_a_n ]]; then
          bundled_flag=$opt_flag_o
          bundled_name=$opt_name_o
          value=$match_o
        else
          bundled_flag=$opt_flag_a
          bundled_name=$opt_name_a
          value=$match_a
        fi
        name_upper_arg=${bundled_name:-$bundled_flag}
        get_name_upper
        if [[ -z $value ]]; then
          value=$1
          shift
        fi
        bundled_args=${bundled_args%%$bundled_flag*}

        if [[ $match_a_n -gt $match_o_n ]]; then
          found_name=_found_$name_upper

          if [[ -z ${!found_name} ]]; then
            unset ARG_$name_upper
            export -n $found_name=true
          fi
          eval "ARG_$name_upper[\${#ARG_$name_upper[@]}]=\$value"
        else
          export -n ARG_$name_upper="$value"
        fi
      fi

      while [[ $bundled_args =~ ($short_flag_regex) ]]; do
        opt_flag=${BASH_REMATCH[1]}
        name_var=_ARG_${opt_flag}_NAME
        opt_name=${!name_var}
        name_upper_arg=${opt_name:-$opt_flag}
        get_name_upper
        export -n ARG_$name_upper=true
        bundled_args=${bundled_args//$opt_flag}
      done
      # </Bundled arguments>

    elif [[ $key =~ ^--($long_opt_regex) ]]; then
      opt_name=${BASH_REMATCH[1]}
      if [[ $key == --$opt_name ]]; then
        value=$1
        shift
      elif [[ $key == --$opt_name=* ]]; then
        value=${key#*=}
      else
        continue
      fi

      name_upper_arg=$opt_name
      get_name_upper
      export -n ARG_$name_upper="$value"

    elif [[ $key =~ ^-($short_opt_regex) ]]; then
      opt_flag=${BASH_REMATCH[1]}
      name_var=_ARG_${opt_flag}_NAME
      opt_name=${!name_var}
      if [[ $key == -$opt_flag ]]; then
        value=$1
        shift
      else
        value=${key#-$opt_flag}
      fi

      name_upper_arg=${opt_name:-$opt_flag}
      get_name_upper
      export -n ARG_$name_upper="$value"

    elif [[ $key =~ ^--($long_arr_regex) ]]; then
      opt_name=${BASH_REMATCH[1]}
      if [[ $key == --$opt_name ]]; then
        value=$1
        shift
      elif [[ $key == --$opt_name=* ]]; then
        value=${key#*=}
      else
        continue
      fi
      name_upper_arg=$opt_name
      get_name_upper

      found_name=_found_$name_upper

      if [[ -z ${!found_name} ]]; then
        unset ARG_$name_upper
        export -n $found_name=true
      fi
      eval "ARG_$name_upper[\${#ARG_$name_upper[@]}]=\$value"

    elif [[ $key =~ ^-($short_arr_regex) ]]; then
      opt_flag=${BASH_REMATCH[1]}
      name_var=_ARG_${opt_flag}_NAME
      opt_name=${!name_var}
      if [[ $key == -$opt_flag ]]; then
        value=$1
        shift
      else
        value=${key#-$opt_flag}
      fi

      name_upper_arg=${opt_name:-$opt_flag}
      get_name_upper

      found_name=_found_$name_upper

      if [[ -z ${!found_name} ]]; then
        unset ARG_$name_upper
        export -n $found_name=true
      fi
      eval "ARG_$name_upper[\${#ARG_$name_upper[@]}]=\$value"
    else
      POSITIONAL[${#POSITIONAL[@]}]=$key
    fi
  done

  if [[ -n $ARG_HELP ]]; then
    print_help
    exit 0
  fi

  i=0; for pos_val in "${POSITIONAL[@]}"; do
    name_upper_arg=${POSITIONAL_NAMES[$i]}
    get_name_upper
    export -n ARG_$name_upper="$pos_val"
    : $((i++))
  done

  unset ${!_ARG_*}

  set -- "${POSITIONAL[@]}"
}

print_help() {
  : ${HELP_WIDTH:=30}
  local X_POS=$(($HELP_WIDTH + 10))
  local X_OPT=$(($HELP_WIDTH + 23))
  local X_OPT_NL=$(($HELP_WIDTH - 3))
  local opt_flag opt_name flag_disp printf_s var
  bprint "usage:"
  printf_s="  ${0##*/} "
  for p_name in "${POSITIONAL_NAMES[@]}"; do
    printf_s+="[$p_name] "
  done
  i=0; for bool_name in "${BOOLEAN_NAMES[@]}"; do
    if [[ -n $bool_name ]]; then
      printf_s+="[--$bool_name] "
    else
      printf_s+="[-${BOOLEAN_FLAGS[$i]}] "
    fi
    : $((i++))
  done
  i=0; for opt_name in "${OPTIONAL_NAMES[@]}"; do
    : ${opt_name:=STRING}
    opt_flag=${OPTIONAL_FLAGS[$i]}
    if [[ -n $opt_flag ]]; then
      printf_s+="[-$opt_flag $opt_name] "
    else
      printf_s+="[--$opt_name=STRING] "
    fi
    : $((i++))
  done
  i=0; for opt_flag in "${ARRAY_FLAGS[@]}"; do
    opt_name="${ARRAY_NAMES[$i]}"
    : ${opt_name:=STRING}
    if [[ -n $opt_flag ]]; then
      printf_s+="[-$opt_flag $opt_name -$opt_flag ...] "
    else
      printf_s+="[--$opt_name=ARG1 --$opt_name=ARG2 ...] "
    fi
    : $((i++))
  done
  if [[
    ${#BOOLEAN_FLAGS[@]}  -gt 0 ||
    ${#OPTIONAL_FLAGS[@]} -gt 0 ||
    ${#ARRAY_FLAGS[@]}    -gt 0
  ]]; then
    has_any_optional_flags=true
  else
    unset has_any_optional_flags
  fi
  printf -- "%b\n%b\n" "$printf_s" "$HELP_DESCRIPTION"
  printf_s=
  [[ -n $has_any_optional_flags || ${#POSITIONAL_NAMES[@]} -gt 0 ]] && printf_s+="\n"
  [[ ${#POSITIONAL_NAMES[@]} -gt 0 ]]                               && printf_s+="positional arguments:\n"
  i=0; for pos_name in "${POSITIONAL_NAMES[@]}"; do
    cprint_q 3 "$pos_name"
    j=
    while read -r; do
      if [[ -z $j ]]; then
        j=1
        printf -v var -- "  %-${X_POS}b %b\n" "${cprint_string}" "$REPLY"
      else
        printf -v var -- "  %-${X_OPT_NL}s %b\n" ' ' "$REPLY"
      fi
      printf_s+=$var
    done < <(echo "${POSITIONAL_DESCRIPTIONS[$i]}")
    : $((i++))
  done
  [[ ${#POSITIONAL_NAMES[@]} -gt 0 ]] && printf_s+="\n"
  [[ -n $has_any_optional_flags ]]    && printf_s+="optional arguments:\n"
  i=0; for bool_name in "${BOOLEAN_NAMES[@]}"; do
    bool_flag=${BOOLEAN_FLAGS[$i]}
    if [[ -n $bool_flag ]]; then
      cprint_q 3 "-$bool_flag"
      flag_disp=$cprint_string
    else
      cprint_q 3 "  "
      flag_disp="$cprint_string "
    fi
    if [[ -n $bool_name ]]; then
      cprint_q 3 "--$bool_name"
    else
      cprint_q 3 "  "
    fi
    if [[ -n $bool_flag && -n $bool_name ]]; then
      flag_disp=$flag_disp,
    fi
    j=
    while read -r; do
      if [[ -z $j ]]; then
        j=1
        printf -v var -- "  %-${X_OPT}b %b\n" "$flag_disp $cprint_string" "$REPLY"
      else
        printf -v var -- "  %-${X_OPT_NL}s %b\n" ' ' "$REPLY"
      fi
      printf_s+=$var
    done < <(echo "${BOOLEAN_DESCRIPTIONS[$i]}")
    : $((i++))
  done
  i=0; for opt_name in "${OPTIONAL_NAMES[@]}"; do
    opt_flag=${OPTIONAL_FLAGS[$i]}

    if [[ -n $opt_flag ]]; then
      cprint_q 3 "-$opt_flag"
      flag_disp=$cprint_string
    else
      cprint_q 3 "  "
      flag_disp="$cprint_string "
    fi
    if [[ -n $opt_name ]]; then
      cprint_q 3 "--$opt_name"
    else
      cprint_q 3 "  "
    fi
    if [[ -n $opt_flag && -n $opt_name ]]; then
      flag_disp="$flag_disp,"
    fi
    j=
    while read -r; do
      if [[ -z $j ]]; then
        j=1
        printf -v var -- "  %-${X_OPT}b %b\n" "$flag_disp $cprint_string" "$REPLY"
      else
        printf -v var -- "  %-${X_OPT_NL}s %b\n" ' ' "$REPLY"
      fi
      printf_s+=$var
    done < <(echo "${OPTIONAL_DESCRIPTIONS[$i]}")
    : $((i++))
  done
  i=0; for opt_name in "${ARRAY_NAMES[@]}"; do
    opt_flag=${ARRAY_FLAGS[$i]}
    if [[ -n $opt_flag ]]; then
      cprint_q 3 "-$opt_flag"
      flag_disp=$cprint_string
    else
      cprint_q 3 "  "
      flag_disp="$cprint_string "
    fi
    if [[ -n $opt_name ]]; then
      cprint_q 3 "--$opt_name"
    else
      cprint_q 3 "  "
    fi
    if [[ -n $opt_flag && -n $opt_name ]]; then
      flag_disp=$flag_disp,
    fi
    j=
    while read -r; do
      if [[ -z $j ]]; then
        j=1
        printf -v var -- "  %-${X_OPT}b %b\n" "$flag_disp $cprint_string" "$REPLY"
      else
        printf -v var -- "  %-${X_OPT_NL}s %b\n" ' ' "$REPLY"
      fi
      printf_s+=$var
    done < <(echo "${ARRAY_DESCRIPTIONS[$i]}")
    : $((i++))
  done
  printf -- "%b" "$printf_s"
}
