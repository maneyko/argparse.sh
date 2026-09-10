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
#     echo $ARG_INPUT_FILE
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
# Each registration function accepts its fields either inside square brackets in
# one argument, or as separate arguments. These two lines are equivalent:
#
#     arg_optional "[port] [p] [The port to use]"
#     arg_optional port p "The port to use"
#
# Pass an empty string for a field you are leaving out, as in
# `arg_optional percentage "" "Percent of file to process"'. The bracket form is
# used throughout the examples below and is not going away.
#
#
# The functions the programmer can use when sourcing this file in their script are:
#
# * arg_positional
#   - This parses positional arguments to your script
#   - The value will be accessible to you via `$ARG_INPUT_FILE' after calling `parse_args'.
#   - Usage example: arg_positional "[input-file] [The input file]"
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
bprint() { printf -- '%b' "\033[1m$1\033[0m"; }

# Color print.
#
# @param number [Integer]
# @param text   [String]
cprint()   { printf -- '%b' "\033[38;5;$1m$2\033[0m"; }
cprint_q() {  cprint_string="\033[38;5;$1m$2\033[0m"; }

impossible_match_pat='$.^'
optional_space_pat='([[:space:]]+)?'
arg_name_pat='([0-9A-Za-z_-]{2,})'
arg_flag_pat='([[:alnum:]]{1,2})'
arg_help_pat='(\[(.*)\])'
arg_positional_pat="\[${arg_name_pat}\]${optional_space_pat}${arg_help_pat}?"
three_arg_pat="\[${arg_name_pat}?\]?${optional_space_pat}\[?${arg_flag_pat}?\]${optional_space_pat}${arg_help_pat}?"

# @param arg_name
# @param arg_description
arg_positional() {
  local pos_name pos_desc
  if [[ $# -gt 1 && $1 != *\[* ]]; then
    pos_name=$1
    pos_desc=$2
  elif [[ "$@" =~ $arg_positional_pat ]]; then
    pos_name=${BASH_REMATCH[1]}
    pos_desc=${BASH_REMATCH[4]}
  else
    return 0
  fi
  POSITIONAL_NAMES[${#POSITIONAL_NAMES[@]}]=$pos_name
  POSITIONAL_DESCRIPTIONS[${#POSITIONAL_DESCRIPTIONS[@]}]=$pos_desc
}

# Sets $opt_name, $opt_flag and $opt_desc in the caller from either form,
# or returns non-zero if the spec does not parse:
#
#     arg_boolean "[verbose] [v] [Do verbose output]"
#     arg_boolean verbose v "Do verbose output"
#
# A bracket spec may be padded for alignment, so a leading `[' cannot be the
# test; the absence of any `[' in the first argument is. The bracket branch
# matches all arguments joined rather than "$1" because a description
# interpolating "${arr[@]}" arrives here as several words.
argparse.sh::split_spec() {
  if [[ $# -gt 1 && $1 != *\[* ]]; then
    opt_name=$1
    opt_flag=$2
    opt_desc=${3:-}
    return 0
  fi
  [[ "$@" =~ $three_arg_pat ]] || return 1
  opt_name=${BASH_REMATCH[1]}
  opt_flag=${BASH_REMATCH[3]}
  opt_desc=${BASH_REMATCH[6]}
}

# @param arg_name
# @param arg_flag
# @param arg_description
long_flag_regex=
short_flag_regex=
arg_boolean() {
  local opt_name opt_flag opt_desc
  argparse.sh::split_spec "$@" || return 0
  BOOLEAN_NAMES[${#BOOLEAN_NAMES[@]}]=$opt_name
  BOOLEAN_FLAGS[${#BOOLEAN_FLAGS[@]}]=$opt_flag
  BOOLEAN_DESCRIPTIONS[${#BOOLEAN_DESCRIPTIONS[@]}]=$opt_desc

  export -n _ARG_${opt_flag:-${opt_name//-/_}}_NAME=${opt_name:-$opt_flag}
  long_flag_regex+="(${opt_name:-$impossible_match_pat})|"
  short_flag_regex+="(${opt_flag:-$impossible_match_pat})|"
}

# @param arg_name
# @param arg_flag
# @param arg_description
long_opt_regex=
short_opt_regex=
arg_optional() {
  local opt_name opt_flag opt_desc
  argparse.sh::split_spec "$@" || return 0
  OPTIONAL_NAMES[${#OPTIONAL_NAMES[@]}]=$opt_name
  OPTIONAL_FLAGS[${#OPTIONAL_FLAGS[@]}]=$opt_flag
  OPTIONAL_DESCRIPTIONS[${#OPTIONAL_DESCRIPTIONS[@]}]=$opt_desc

  export -n _ARG_${opt_flag:-${opt_name//-/_}}_NAME=${opt_name:-$opt_flag}
  long_opt_regex+="(${opt_name:-$impossible_match_pat})|"
  short_opt_regex+="(${opt_flag:-$impossible_match_pat})|"
}

# @param arg_name
# @param arg_flag
# @param arg_description
long_arr_regex=
short_arr_regex=
arg_array() {
  local opt_name opt_flag opt_desc
  argparse.sh::split_spec "$@" || return 0
  ARRAY_NAMES[${#ARRAY_NAMES[@]}]=$opt_name
  ARRAY_FLAGS[${#ARRAY_FLAGS[@]}]=$opt_flag
  ARRAY_DESCRIPTIONS[${#ARRAY_DESCRIPTIONS[@]}]=$opt_desc

  export -n _ARG_${opt_flag:-${opt_name//-/_}}_NAME=${opt_name:-$opt_flag}
  long_arr_regex+="(${opt_name:-$impossible_match_pat})|"
  short_arr_regex+="(${opt_flag:-$impossible_match_pat})|"
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
  long_flag_regex+='(help)|'
  short_flag_regex+='(h)|'
}

if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
  get_name_upper() {
    local res=${1//-/_}
    name_upper=${res^^}
  }
else
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
fi

# Set $__DIR__ variable.
# The full path of the directory of the script.
get__dir__() {
  # Returning to $OLDPWD unconditionally would move the caller when the first
  # `cd' never happened. A failure here is reported by `parse_args', so this
  # must not exit non-zero and trip the caller's `set -e' on the way.
  if cd "${0%/*}" 2>/dev/null; then
    __DIR__=$PWD
    cd "$OLDPWD"
  else
    # Nothing here would be better than a guess, and a guess that happens to
    # exist is the silent failure this is meant to catch. Nothing can live
    # under /dev/null, so the check in `parse_args' is decisive.
    __DIR__=/dev/null/nonexistent
  fi
}

parse_args() {
  # Parsing reads unset variables as empty throughout, so suspend the caller's
  # `set -u' for the duration and put it back afterwards.
  local nounset=
  if [[ $- == *u* ]]; then
    nounset=1
    set +u
  fi

  argparse.sh::parse_args "${ARGS_ARR[@]}"
  get__dir__
  __FILE__=$__DIR__/${0##*/}

  # `$0' is resolved against the current directory, so changing it before this
  # point makes `$__DIR__' silently wrong. A `-c' or stdin script has no file
  # to find in the first place -- there `$0' is just "bash".
  case $- in
    *c*|*s*) ;;
    *)
      if [[ ! -f $__FILE__ ]]; then
        echo "ERROR: cannot locate the script at '$__FILE__'." >&2
        echo 'Source argparse.sh and call parse_args before changing directories.' >&2
        exit 1
      fi
      ;;
  esac

  if [[ -n $nounset ]]; then
    set -u
  fi
}

# @param args_arr
argparse.sh::parse_args() {
  # Each `arg_*' call appended one alternative plus a trailing "|", leaving
  # something like "(verbose)|(quiet)|(help)|". Drop that trailing "|", and
  # where nothing was registered substitute a pattern that cannot match, so
  # the branch below is simply never taken -- an empty regex would match
  # everything instead.
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

  # $name_var and $found_var hold the *names* of variables, read back with
  # ${!name_var}. $name_upper is set by `get_name_upper' rather than returned.
  local opt_name opt_flag name_var value key i name_upper found_var pos_val

  # Bundled short flags, e.g. the "qp8080" left over from `-vqp8080'.
  local bundle value_name value_flag
  local optional_value optional_value_len optional_flag optional_name
  local array_value array_value_len array_flag array_name

  # The branches are ordered boolean, optional, then array, long form before
  # short. The short-boolean branch is the only one that has to deal with
  # bundling, because it is the only one that can be followed by more flags.
  while [[ $# -gt 0 ]]; do
    key=$1
    value=
    shift

    if [[ $key =~ ^--($long_flag_regex)$ ]]; then
      # `--verbose'. Anchored at both ends: a boolean takes no value, so
      # `--verbose=false' does not match here and ends up in $POSITIONAL.
      get_name_upper ${BASH_REMATCH[1]}
      export -n ARG_$name_upper=true

    elif [[ $key =~ ^-($short_flag_regex) ]]; then
      # A short boolean flag, with anything bundled behind it still attached:
      # `-v', `-vq', `-vp8080' and `-vqp8080' all arrive here.
      opt_flag=${BASH_REMATCH[1]}          # "v"
      name_var=_ARG_${opt_flag}_NAME       # "_ARG_v_NAME", which holds "verbose"
      get_name_upper ${!name_var}          # name_upper="VERBOSE"
      export -n ARG_$name_upper=true

      bundle=${key#-$opt_flag}             # `-vqp8080' leaves bundle="qp8080"
      [[ -z $bundle ]] && continue

      # <Bundled arguments>
      #
      # What is left may hold more booleans and at most one flag that takes a
      # value. That flag swallows the whole remainder of the bundle, so which
      # flag it is has to be settled before anything can be assigned. Walking
      # through bundle="qp8080", where q is a boolean and p is an
      # `arg_optional':
      #
      #   optional match   flag="p"  value="8080"  len=4
      #   array match      no array flag present   len=-1
      #   winner           the optional, so ARG_PORT="8080"
      #   bundle rewritten "q", the boolean sitting in front of p
      #
      # Position is read off the length of the text trailing each candidate
      # rather than an index: the flag with more characters behind it is the
      # one that appeared earlier, and the earlier flag owns the value. With
      # an `arg_array' -n in play, that is what makes `-vpn5' set ARG_PORT to
      # "n5" while `-vnp5' appends "p5" to ARG_NUMBERS. A length of -1 means
      # no flag of that kind is in the bundle at all.

      optional_value_len=-1
      array_value_len=-1

      # The pattern ends in `(.*)', so the last capture group is the text
      # following the matched flag: for "qp8080" that is "8080".
      if [[ $bundle =~ ($short_opt_regex)(.*) ]]; then
        optional_value=${BASH_REMATCH[@]: -1}
        optional_value_len=${#optional_value}
        optional_flag=${BASH_REMATCH[1]}
        name_var=_ARG_${optional_flag}_NAME
        optional_name=${!name_var}         # e.g. "port"
      fi

      if [[ $bundle =~ ($short_arr_regex)(.*) ]]; then
        array_value=${BASH_REMATCH[@]: -1}
        array_value_len=${#array_value}
        array_flag=${BASH_REMATCH[1]}
        name_var=_ARG_${array_flag}_NAME
        array_name=${!name_var}            # e.g. "numbers"
      fi

      if [[ $optional_value_len -gt -1 || $array_value_len -gt -1 ]]; then
        # Longer trailing text wins, so an equal length hands it to the
        # optional. Both being -1 is excluded above, so whichever branch is
        # taken describes a flag that really matched.
        if [[ $optional_value_len -ge $array_value_len ]]; then
          value_name=$optional_name
          value_flag=$optional_flag
          value=$optional_value
        else
          value_name=$array_name
          value_flag=$array_flag
          value=$array_value
        fi
        get_name_upper $value_name

        # Nothing followed the flag, as in `-vp 8080': take the next argument.
        if [[ -z $value ]]; then
          value=$1
          shift
        fi

        # Everything from the value flag rightwards has been consumed as the
        # value, so what stands in front of it is booleans: "qp8080" -> "q".
        bundle=${bundle%%$value_flag*}

        if [[ $array_value_len -gt $optional_value_len ]]; then
          # An `arg_array' flag appends, except on its first appearance, where
          # it has to discard whatever default the script assigned to
          # ARG_<NAME>. This marker is what separates those two cases.
          found_var=_found_$name_upper

          if [[ -z ${!found_var} ]]; then
            unset ARG_$name_upper
            export -n $found_var=true
          fi
          # The array's name is only known at runtime. Expansion happens after
          # this line is parsed, so a value holding `;' or `$(...)' stays data.
          eval "ARG_$name_upper[\${#ARG_$name_upper[@]}]=\$value"
        else
          export -n ARG_$name_upper="$value"
        fi
      fi

      # Whatever survives is booleans in any order: "q" above, or "qt" from
      # `-vqtp8080'. Each match is deleted, which is what ends the loop.
      while [[ $bundle =~ ($short_flag_regex) ]]; do
        opt_flag=${BASH_REMATCH[1]}
        name_var=_ARG_${opt_flag}_NAME
        get_name_upper ${!name_var}
        export -n ARG_$name_upper=true
        bundle=${bundle//$opt_flag}
      done
      # </Bundled arguments>

    elif [[ $key =~ ^--($long_opt_regex) ]]; then
      # `--port 8080' or `--port=8080'.
      opt_name=${BASH_REMATCH[1]}          # "port"
      get_name_upper $opt_name             # name_upper="PORT"

      if [[ $key == --$opt_name ]]; then
        value=$1                           # the value is the next argument
        shift
      elif [[ $key == --$opt_name=* ]]; then
        value=${key#*=}                    # `--port=8080' -> "8080"
      else
        # The regex is unanchored at the end, so `--portfolio' gets in here on
        # the strength of its "port" prefix and is then dropped -- it does not
        # reach $POSITIONAL the way an unrecognised `--zzz' would.
        continue
      fi

      export -n ARG_$name_upper="$value"

    elif [[ $key =~ ^-($short_opt_regex) ]]; then
      # `-p 8080' or `-p8080'. Bundles were handled by the boolean branch
      # above, so anything attached here is the value.
      opt_flag=${BASH_REMATCH[1]}
      name_var=_ARG_${opt_flag}_NAME
      get_name_upper ${!name_var}

      if [[ $key == -$opt_flag ]]; then
        value=$1
        shift
      else
        value=${key#-$opt_flag}            # `-p8080' -> "8080"
      fi
      export -n ARG_$name_upper="$value"

    elif [[ $key =~ ^--($long_arr_regex) ]]; then
      # `--numbers 12' or `--numbers=12', repeatable.
      opt_name=${BASH_REMATCH[1]}
      if [[ $key == --$opt_name ]]; then
        value=$1
        shift
      elif [[ $key == --$opt_name=* ]]; then
        value=${key#*=}
      else
        continue
      fi
      get_name_upper $opt_name

      # See the bundled branch above: the first occurrence replaces the
      # script's default, the rest append.
      found_var=_found_$name_upper

      if [[ -z ${!found_var} ]]; then
        unset ARG_$name_upper
        export -n $found_var=true
      fi
      eval "ARG_$name_upper[\${#ARG_$name_upper[@]}]=\$value"

    elif [[ $key =~ ^-($short_arr_regex) ]]; then
      # `-n 12' or `-n12', repeatable.
      opt_flag=${BASH_REMATCH[1]}
      name_var=_ARG_${opt_flag}_NAME
      get_name_upper ${!name_var}

      if [[ $key == -$opt_flag ]]; then
        value=$1
        shift
      else
        value=${key#-$opt_flag}
      fi

      found_var=_found_$name_upper

      if [[ -z ${!found_var} ]]; then
        unset ARG_$name_upper
        export -n $found_var=true
      fi
      eval "ARG_$name_upper[\${#ARG_$name_upper[@]}]=\$value"
    else
      # Not a flag this script registered. Positionals land here, and so do
      # flags meant for a command this script wraps -- several callers slice
      # their own positionals off the front and forward the rest verbatim.
      POSITIONAL[${#POSITIONAL[@]}]=$key
    fi
  done

  if [[ -n $ARG_HELP ]]; then
    print_help
    exit 0
  fi

  # Positional values are named by the order `arg_positional' was called in,
  # so the first value becomes $ARG_<first registered name>. Extra values stay
  # in $POSITIONAL and are not given a name.
  i=0; for pos_val in "${POSITIONAL[@]}"; do
    get_name_upper ${POSITIONAL_NAMES[$i]}
    export -n ARG_$name_upper="$pos_val"
    : $((i++))
  done

  unset ${!_ARG_*} ${!_found_*}
}

print_help() {
  # Suspend the caller's `set -u' as `parse_args' does; this is a public function.
  local nounset=
  if [[ $- == *u* ]]; then
    nounset=1
    set +u
  fi

  # These are all wider than $HELP_WIDTH on purpose. The colored fields are
  # padded with `%-Nb', and that width counts the literal "\033[38;5;3m" and
  # "\033[0m" wrapping each one -- 19 characters that `%b' then turns into
  # zero visible width. The margins are tuned against real output rather than
  # derived, so adjusting one means looking at the printed help, not at the
  # arithmetic.
  : ${HELP_WIDTH:=30}
  local pos_column=$(($HELP_WIDTH + 10))   # description column, positional block
  local flag_column=$(($HELP_WIDTH + 23))  # description column, optional block
  local wrap_column=$(($HELP_WIDTH - 3))   # indent for a description's later lines
  local opt_flag opt_name flag_disp out line i first_done p_name pos_name bool_name bool_flag
  bprint 'usage:'
  out="  ${0##*/} "
  for p_name in "${POSITIONAL_NAMES[@]}"; do
    out+="[$p_name] "
  done
  i=0; for bool_name in "${BOOLEAN_NAMES[@]}"; do
    if [[ -n $bool_name ]]; then
      out+="[--$bool_name] "
    else
      out+="[-${BOOLEAN_FLAGS[$i]}] "
    fi
    : $((i++))
  done
  i=0; for opt_name in "${OPTIONAL_NAMES[@]}"; do
    : ${opt_name:=STRING}
    opt_flag=${OPTIONAL_FLAGS[$i]}
    if [[ -n $opt_flag ]]; then
      out+="[-$opt_flag $opt_name] "
    else
      out+="[--$opt_name=STRING] "
    fi
    : $((i++))
  done
  i=0; for opt_flag in "${ARRAY_FLAGS[@]}"; do
    opt_name="${ARRAY_NAMES[$i]}"
    : ${opt_name:=STRING}
    if [[ -n $opt_flag ]]; then
      out+="[-$opt_flag $opt_name -$opt_flag ...] "
    else
      out+="[--$opt_name=ARG1 --$opt_name=ARG2 ...] "
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
  printf -- "%s\n%b\n" "$out" "$HELP_DESCRIPTION"
  out=
  [[ -n $has_any_optional_flags || ${#POSITIONAL_NAMES[@]} -gt 0 ]] && out+=$'\n'
  [[ ${#POSITIONAL_NAMES[@]} -gt 0 ]]                               && out+=$'positional arguments:\n'
  # A description may span several lines. The first one is printed beside the
  # argument's name; the rest are indented under it. The three blocks below --
  # positional, boolean and optional, then array -- all repeat this shape.
  i=0; for pos_name in "${POSITIONAL_NAMES[@]}"; do
    cprint_q 3 "$pos_name"
    first_done=
    while read -r; do
      if [[ -z $first_done ]]; then
        first_done=1
        printf -v line -- "  %-${pos_column}b %s\n" "${cprint_string}" "$REPLY"
      else
        printf -v line -- "  %-${wrap_column}s %s\n" ' ' "$REPLY"
      fi
      out+=$line
    done <<< "${POSITIONAL_DESCRIPTIONS[$i]}"
    : $((i++))
  done
  [[ ${#POSITIONAL_NAMES[@]} -gt 0 ]] && out+=$'\n'
  [[ -n $has_any_optional_flags ]]    && out+=$'optional arguments:\n'
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
    first_done=
    while read -r; do
      if [[ -z $first_done ]]; then
        first_done=1
        printf -v line -- "  %-${flag_column}b %s\n" "$flag_disp $cprint_string" "$REPLY"
      else
        printf -v line -- "  %-${wrap_column}s %s\n" ' ' "$REPLY"
      fi
      out+=$line
    done <<< "${BOOLEAN_DESCRIPTIONS[$i]}"
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
    first_done=
    while read -r; do
      if [[ -z $first_done ]]; then
        first_done=1
        printf -v line -- "  %-${flag_column}b %s\n" "$flag_disp $cprint_string" "$REPLY"
      else
        printf -v line -- "  %-${wrap_column}s %s\n" ' ' "$REPLY"
      fi
      out+=$line
    done <<< "${OPTIONAL_DESCRIPTIONS[$i]}"
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
    first_done=
    while read -r; do
      if [[ -z $first_done ]]; then
        first_done=1
        printf -v line -- "  %-${flag_column}b %s\n" "$flag_disp $cprint_string" "$REPLY"
      else
        printf -v line -- "  %-${wrap_column}s %s\n" ' ' "$REPLY"
      fi
      out+=$line
    done <<< "${ARRAY_DESCRIPTIONS[$i]}"
    : $((i++))
  done
  printf -- '%s' "$out"

  if [[ -n $nounset ]]; then
    set -u
  fi
}
