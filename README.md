# argparse.sh

The interface for this script was inspired by [Argbash](https://argbash.io/).

## Usage

To use `argparse.sh`, source it in your script then let it parse your arguments for you.
Let's say you are writing a script, `process_file.sh`, to process a file, and it is called
with some arguments:

```bash
process_file.sh input-data.txt --filetype csv -v
```

This is how argument parsing would be configured in your script to use `argparse.sh`:

```bash
#!/bin/bash

source "./argparse.sh"

arg_positional_single "[infile] [Input text file to process]"
arg_optional_single   "[filetype] [t] [Type of text file. Can be txt, csv or tsv]"
arg_optional_boolean  "[verbose] [v] [Print information about operations being performed]"
arg_optional_single   "[replace] [r] [Replace first column text with second column text]"

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

## Caveats

* Positional arguments must be first, so right now you cannot do `./process_file.sh -v input-data.txt`.
  It must be `./process_file.sh input-data.txt -v`.

* Optional arguments with a corresponding value may be passed without whitespace in between. So you
  may do `./process_file.sh input-data.txt -tcsv`.

## Requirements

bash >= 3, awk, perl
