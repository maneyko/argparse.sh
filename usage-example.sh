#!/bin/bash

source "./argparse.sh"

arg_optional_single   "[port-number] [p] [The port number]"
arg_optional_boolean  "[flag] [f] [My important flag]"
arg_positional_single "[infile] [The file to parse]"
arg_positional_single "[outfile] [The output file]"
arg_help              "[This is the help message]"


echo $ARG_PORT_NUMBER
echo $ARG_INFILE
echo $ARG_OUTFILE
echo $ARG_FLAG
