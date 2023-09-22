#!/usr/bin/env python3
"""
truncate files
V1.0 [2022.14MeV]
"""
import argparse
import os
import sys


def parse_arguments():
    """parse the argument list, build help and usage messages

    Command-Line Arguments
    -h
    -v
    FILES

    Returns:
        namespace (ns): namespace with the arguments passed and their values

    """
    parser = argparse.ArgumentParser(
        description='truncate a file to zero size')
    # if omitted, the default value is returned, so arg.input is always defined
    parser.add_argument('files',
                        action='store',
                        help='file to truncate',
                        nargs="+",   # at least one file on command line to truncate
                        )
    parser.add_argument('-s', '--silent',
                        action="store_true",
                        help='don\'t show files being truncated',
                        required=False,
                        )
    args = parser.parse_args()
    return args  # namespace containing the argument passed on the command line


def main():
    """ parse command line for files and truncate them

    :return:
    """
    prog = os.path.basename(sys.argv[0])
    args = parse_arguments()

    # walk through files passed by argument, open them truncated, and close them
    error_found = False
    for file in args.files:
        if not os.path.exists(file):
            print(f'{prog} -- file {file} not found')
            error_found = True
            continue

        if not os.path.isfile(file):
            print(f'{prog} -- file {file} not a file')
            error_found = True
            continue
        # returns PermissionError if x can't be read
        try:
            with open(file, 'a') as f:
                f.truncate(0)
        except PermissionError:
            print(f"{prog}: can't write {file}")
            error_found = True
            continue

        if not args.silent:
            print(f'  >>{prog}: zeroed {file}')

    if error_found:
        return 2
    else:
        return 0


if __name__ == '__main__':
    sys.exit(main())
