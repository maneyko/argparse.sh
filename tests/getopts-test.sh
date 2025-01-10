#!/bin/bash

while getopts ":abcedef" opt; do
  case $opt in
    a)
      a=1
      ;;
    b)
      b=1
      ;;
    c)
      c=1
      ;;
    d)
      d=1
      ;;
    e)
      e=1
      ;;
    f)
      f=1
      ;;
  esac
done

cat << EOT
a=$a
b=$b
c=$c
d=$d
e=$e
f=$f
EOT
