# argparse.sh

Bash script to parse command line arguments.

## Usage

To use `argparse.sh`, source it in your script then let it parse your arguments for you.
Let's say you are writing a script, `process_file.sh`, to process a file, and it is called
with some arguments:

```bash
./process_file.sh input-data.txt -v --delimiter=',' --columns='$1, $2'
```

This is how argument parsing would be configured in your script to use `argparse.sh`:

```bash
#!/bin/bash

source "$(dirname "$0")/argparse.sh"

# Default values for some arguments:
ARG_COLUMNS='$1, $2, $3'
ARG_DELIMITER=','

arg_positional "[input-file]    [Input text file to process]"
arg_boolean    "[verbose]   [v] [Print information about operations being performed]"
arg_optional   "[delimiter] [d] [Delimiter which splits columns in the input file.]"
arg_optional   "[columns]   [c] [Only print certain numbered columns. Passed directly to awk script. Default are '$ARG_COLUMNS'.]"
arg_help       "[This script is for processing a text file]"
parse_args

echo $ARG_INFILE
# => input-data.txt

echo $ARG_DELIMITER
# => ,

echo $ARG_VERBOSE
# => true

echo $ARG_COLUMNS
# => $1, $2

if [ -n "$ARG_VERBOSE" ]; then
 echo 'Beginning processing...'
fi

awk -F "$ARG_DELIMITER" "{print $ARG_COLUMNS}" "$ARG_INPUT_FILE"
```

To get a better idea of the usage in a real shell script, look at
[usage-example.sh](https://github.com/maneyko/argparse.sh/blob/master/usage-example.sh).
The script may be called like this:

```bash
./usage-example.sh -f -p2020 infile.txt -n2 --verbose outfile.txt --outputs 3 -n 4 --numbers 8

infile:      infile.txt
outfile:     outfile.txt
port-number: 2020
outputs:     3
verbose:     true
flag:        true
numbers:     2 4 8
```

## Installation

The recommended installation is to include `argparse.sh` in your `$PATH`. Do not make
it executable as this is not necessary and not supported. Then, from any script you write
on your filesystem, you may do:

```bash
#!/bin/bash

source "argparse.sh"

arg_help "[This is the help option.]"
parse_args
```

Another installation option is to include `argparse.sh` in the same directory in your script
as is done in [Usage](#usage).

## Advanced Usage

Boolean flags and options that take values may be bundled together, like so:

```bash
$ ./usage-example.sh -vfp2020 --outputs 4 infile.txt
infile:      infile.txt
outfile:
port-number: 2020
outputs:     4
verbose:     true
flag:        true
numbers:
```

## Notes

* The `parse_args` function needs to be ran last after all the other functions in `argparse.sh` have been called.
  This is so that it will know all the possible arguments.

* Passing invalid arguments to the user script results in unexpected behavior from `argparse.sh`.

## Requirements

bash >= 3.1

## API Documentation

All parameters passed to any function in `argparse.sh` must be surrounded by square brackets,
as done in [Usage](#usage).

Functions for parsing arguments:
* `arg_positional`
  * Arguments:
    - `arg_name`
    - `arg_description`
* `arg_optional`
  * Arguments:
    - `arg_name`
    - `arg_flag`
    - `arg_description`
* `arg_boolean`
  * Arguments:
    - `arg_name`
    - `arg_flag`
    - `arg_description`
* `arg_array`
  * Arguments:
    - `arg_name`
    - `arg_flag`
    - `arg_description`
* `arg_help`
  * Arguments:
    - `arg_description`
* `parse_args`
  * Arguments:
    - None

Additional helper functions and variables:
* `__DIR__`
  - Full path of the directory which contains the script.
* `${POSITIONAL[@]}`
  - Array of additional positional arguments not parsed by argparse.sh
* `print_help`
  - Function to print the help page, automatically done if `-h` flag is present
* `bprint`
  - Function to print the text as bold, without a trailing newline
* `cprint`
  - Function to print the text as [8-bit color](https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit),
    without a trailing newline
