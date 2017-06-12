# jobdb
Tools to keep track of jobs submitted using PBS torque.

Often, users of an HPC environment submit many jobs from a multitude
of directories, and it is not always trivial to do the bookkeeping.

`jobdb` will help with that by recording the job ID, the submission
time, the directory it was submitted in, and, optionally, the job name
if specified on the command line with the `-N` option, and a description
with the `--description` option.

It is now easy to navigate to the directory using `jdbcd` for a specified
job ID, or choose it interactively from a list that can be filtered.


## Commands

* `jdbsub`: `qsub` wrapper that keeps track of the job's meta-information.
* `jdbcd`: change directory to a job's submission directory.
* `jdbedit`: edit the `jobdb` file in your favorite editor.
* `jdbclear`: clear all entries in the `jobdb` database file.

All commands will provide a help message when the `--help` option is used.
Documentation for `peco` can be found on its
[GitHub site](https://github.com/peco/peco).


## Installation
Simply source the `jobdb.sh` file from your `.bashrc` file, i.e.,
```bash
source "${HOME}/jobdb.sh"
```

## Requriments
`peco` should be in your path.  It can be downloaded from
[GitHub](https://github.com/peco/peco).  Pre-built binaries work just
fine.


## How it works
`jdbsub` will update a job database file `jobs` that is by default
located in the `.jobdb` directory in your home directory.  Its location
can be controlled using the `JOBDB_DIR` environment variable if required.

The "database" is a CSV file that keeps track of the job ID as returned
by `qsub`, the job name if specified on the command line using `qsub`'s
`-N` option, the directory in which `jdbsub` was executed, a description
if provided using the `--description` option, and a timestamp in the
format `YYYY-mm-dd HH:MM:SS`.
