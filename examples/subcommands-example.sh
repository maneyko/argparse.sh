#!/bin/bash

source "$(dirname "$0")/../argparse.sh"

STOP_AT_POSITIONAL=true

arg_help       "[A tool with subcommands. Run '${0##*/} <command> -h' for a command's own flags.]"
arg_positional "[command]     [build or clean]"
arg_boolean    "[verbose] [v] [Print information about operations being performed.]"
parse_args

build() {
  source "$(dirname "$0")/../argparse.sh" "$@"
  arg_help     build "Build the project."
  arg_optional "[target]  [t] [What to build. Default: all]"
  arg_boolean  "[release] [r] [Build with optimizations.]"
  parse_args

  echo "build: target=${ARG_TARGET:-all} release=$ARG_RELEASE verbose=$ARG_VERBOSE"
}

clean() {
  source "$(dirname "$0")/../argparse.sh" "$@"
  arg_help    clean "Remove build output."
  arg_boolean "[all] [a] [Also remove downloaded dependencies.]"
  parse_args

  echo "clean: all=$ARG_ALL verbose=$ARG_VERBOSE"
}

case $ARG_COMMAND in
  build|clean)
    $ARG_COMMAND "${POSITIONAL[@]:1}"
    ;;
  *)
    print_help
    exit 1
    ;;
esac
