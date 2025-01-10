#!/bin/bash

source "argparse.sh"

arg_boolean "[] [a] [A.]"
arg_boolean "[] [b] [B.]"
arg_boolean "[] [c] [C.]"
arg_boolean "[] [d] [D.]"
arg_boolean "[] [e] [E.]"
arg_boolean "[] [f] [F.]"
arg_help "[Test script.]"
parse_args

cat << EOT
a=$ARG_A
b=$ARG_B
c=$ARG_C
d=$ARG_D
e=$ARG_E
f=$ARG_F
EOT
