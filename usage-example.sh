#!/bin/bash

source "./argparse.sh"

arg_optional_single   "[port-number] [p] [The port number]"
arg_positional_single "[thefile] [The file to parse]"
arg_optional_boolean  "[flag] [f] [My important flag]"
arg_help              "[This is the help message]"

echo $ARG_PORT_NUMBER
echo $ARG_THEFILE
echo $ARG_FLAG
