# argparse.sh

Bash script to parse command line arguments.

## Usage

To use `argparse.sh`, source it in your script then let it parse your arguments for you.
Let's say you are writing a script, `process_file.sh`, to process a file, and it is called
with some arguments:

```bash
./process_file.sh input-data.txt -v --delimiter=',' --expression='$1, $2'
```

Or more succinctly:

```bash
./process_file.sh -vd, -e'$1, $2' input-data.txt
```

This is how argument parsing would be configured in your script to use `argparse.sh`:

```bash
#!/bin/bash

source "$(dirname "$0")/argparse.sh"

# Set default value.
ARG_DELIMITER=','

arg_help       "[This script is for processing a text file]"
arg_positional "[input-file]     [Input text file to process]"
arg_boolean    "[verbose]    [v] [Print information about operations being performed]"
arg_optional   "[delimiter]  [d] [Input file field separator. Default: '$ARG_DELIMITER']"
arg_optional   "[expression] [e] [Expression passed directly to \`awk '{print ...}'\`]"
parse_args

echo $ARG_INFILE
# => input-data.txt

echo $ARG_DELIMITER
# => ,

echo $ARG_VERBOSE
# => true

if [ -n "$ARG_VERBOSE" ]; then
 echo 'Beginning processing...'
fi

awk -F "$ARG_DELIMITER" "{print $ARG_EXPRESSION}" "$ARG_INPUT_FILE"
```

To get a better idea of the usage in a real shell script, look at
[usage-example.sh](https://github.com/maneyko/argparse.sh/blob/master/usage-example.sh).
The script may be called like this:

```bash
./usage-example.sh -fp2020 infile.txt -n2 --verbose outfile.txt --outputs 3 -n 4

infile:      infile.txt
outfile:     outfile.txt
port-number: 2020
outputs:     3
verbose:     true
flag:        true
numbers:     2 4
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
$ ./usage-example.sh -vp2020 --outputs 4 infile.txt -fn 32
infile:      infile.txt
outfile:
port-number: 2020
outputs:     4
verbose:     true
flag:        true
numbers:     32
```

## Notes

* The `parse_args` function needs to be ran last after all the other functions in `argparse.sh` have been called.
  This is so that it will know all the possible arguments.

* Passing invalid arguments to the user script results in unexpected behavior from `argparse.sh`.

## Requirements

[Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) >= 3.1

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

Set `HELP_WIDTH` (before calling `parse_args`) to set the column width of the help message.

Additional helper functions and variables:

* `$__DIR__`
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
