# argparse.sh

The interface for this script was inspired by [Argbash](https://argbash.io/).

## Usage

To use `argparse.sh`, source it in your script then let it parse your arguments for you.
Let's say you are writing a script, `process_file.sh`, to process a file, and it is called
with some arguments:

```bash
./process_file.sh input-data.txt --filetype csv -v
```

This is how argument parsing would be configured in your script to use `argparse.sh`:

```bash
#!/bin/bash

source "argparse.sh"

arg_positional_single "[infile] [Input text file to process]"
arg_optional_single   "[filetype] [t] [Type of text file. Can be txt, csv or tsv]"
arg_optional_boolean  "[verbose] [v] [Print information about operations being performed]"
arg_optional_single   "[replace] [r] [Replace first column text with second column text]"
arg_help              "[This script is for processing a text file]"
parse_args

echo $ARG_VERBOSE
# => true

echo $ARG_REPLACE
# =>

echo $ARG_INFILE
# => input-data.txt

if [ -n $ARG_VERBOSE ]; then
  echo 'Printing first column...'
fi

if [ $ARG_FILETYPE = "csv" ];
  awk -F ',' '{print $1}' $ARG_INFILE
fi
```

To get a better idea of the usage in a real shell script, look at
[usage-example.sh](https://github.com/maneyko/argparse.sh/blob/master/usage-example.sh).
The script may be called like this:

```bash
./usage-example.sh -f -p2020 infile.txt --verbose outfile.txt --outputs 3

infile:      infile.txt
outfile:     outfile.txt
port-number: 2020
outputs:     3
verbose:     true
flag:        true
```

## Installation

The recommended installation is to include `argparse.sh` in your `$PATH`. Do not make
it executable as this is not necessary and not supported. Then, from any script you write
on your filesystem, you may do:

```bash
#!/bin/bash

source "$(type -P argparse.sh)"

arg_help "[This is the help option.]"
parse_args
```

Another installation option is to include `argparse.sh` in the same directory in your script
as it is done in [Usage](#usage).

## Notes

* The `parse_args` function needs to be ran last after all the other functions in `argparse.sh` have been called.
  This is so that it will know all the possible arguments.

* Passing invalid arguments to the user script results in unexpected behavior from `argparse.sh`.

* Optional arguments with a corresponding value may be passed without whitespace in between. So you
  may do `./process_file.sh -tcsv input-data.txt`.

## Requirements

bash >= 3
