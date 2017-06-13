#!/usr/bin/env bash
# 
# ------------------------------------------------------------
# This file defines bash functions for jobdb. The file can be
# sourced from the .bashrc file, so that it is available in
# all interactive shells.
#
# Author: geertjan.bex@uhasselt.be
# License: GPL 3.0
# ------------------------------------------------------------

PECO="peco"
QSUB="qsub"

# ------------------------------------------------------------
# jdbsub will submit a job to PBS torque using qsub under the
# hood.  It keeps track of job meta-data in the jobs file for
# use with jdbcd.
#
jdbsub () {
    local HELP_STR='
        Usage: jdbsub [--help] [--description <DESCR>] qsub_options

        Submit a job sing qsub, recording the directory in which
        this command is executed, as well as the job ID resulting
        frmo qsub, the job name, if specified on the command line
        using the -N option, and otionally a description.

        Options:
          --description <DESCR>  job description to make retrieving
                                 jobs from the database easier
          --help                 display this help message
          qsub_options           any qsub options'
    show_help "${HELP_STR}" $@
    if [ $? -eq 0 ]
    then
        return 0
    fi
# get jobdb directory, if it doesn't exist, create it
    jdbdir 'new'
    local EXIT_CODE=$?
    if [ ${EXIT_CODE} -eq 2 ]
    then
        mkdir -p "${JOBDB_DIR}"
    elif [ ${EXIT_CODE} -ne 0 ]
    then
        return ${EXIT_CODE}
    fi
    local JOBDB_FILE="${JOBDB_DIR}/jobs"
    local JOB_DIR=$(pwd)
    local QSUB_CMD="${QSUB}"
    while (( "$#" ))
    do
        if [ "$1" == "--description" ]
        then
            shift
            local JOB_DESCR=$1
        elif [ "$1" == "-N" ]
        then
            QSUB_CMD="${QSUB_CMD} \"$1\""
            shift
            local JOB_NAME="$1"
            QSUB_CMD="${QSUB_CMD} \"$1\""
        else
            QSUB_CMD="${QSUB_CMD} $1"
        fi
        shift
    done
    local JOB_ID=$($QSUB_CMD)
    local EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]
    then
        return ${EXIT_CODE}
    fi
    echo "${JOB_ID}"
    local JOB_TIME=$(date  "+%Y-%m-%d %H:%M:%S")
    echo "${JOB_ID},\"${JOB_NAME}\",\"${JOB_DIR}\",\"${JOB_DESCR}\",${JOB_TIME}" \
        >> "${JOBDB_FILE}"
    return 0
}

# ------------------------------------------------------------
# jdbcd will display the jobs in the jobdb file, and lets you
# select one, it will than cd to that directory.
# Alternatively, a job ID can be provided as an argument to
# jdbcd
#
jdbcd () {
    local HELP_STR='
        Usage: jdbcd [<jobdb>] [--help]

        Change to a directory from which a job was submitted.  If a
        job ID is given, go to that directory, otherwise, select one
        from the job database using peco.

        For information on peco, refer to its own documentation:
        https://github.com/peco/peco

        Options:
          <jobid>     job ID to change the directory to
          --help      display this help message'
    show_help "${HELP_STR}" $@
    if [ $? -eq 0 ]
    then
        return 0
    fi
    jdbfile
    local EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]
    then
        return ${EXIT_CODE}
    fi
    local JOB_INFO=''
    if [ $# -eq 0 ]
    then
        JOB_INFO=$("${PECO}" "${JOBDB_FILE}")
    else
        JOB_INFO=$(grep -e "^$1[.,]" "${JOBDB_FILE}")
        if [ "x" == "x${JOB_INFO}" ]
        then
            (>&2 echo "### error: no jobdb entry for '$1'")
            return 1
        fi
    fi
# The job directory is the second field on the selected line,
# the quotes should be removed to keep cd happy
    local JOB_DIR=$(echo "${JOB_INFO}" | cut -d ',' -f 3 | \
                                         sed 's/^"\(.*\)"$/\1/')
    if [ "x" == "x${JOB_DIR}" ]
    then
        return 0
    fi
# if the job directory doesn't exist, exit
    if [ ! -e "${JOB_DIR}" ]
    then
        (>&2 echo "### error: job directory ${JOB_DIR} doesn't exist")
        return 1
    fi
# change to job directory and exit
    cd "${JOB_DIR}"
    return 0
}

jdbdir () {
# check whether the jobdb directory is specified via an
# environment variable, if not, initialize to default
# location
    if [ "x$JOBDB_DIR" == "x" ]
    then
        JOBDB_DIR="${HOME}/.jobdb"
    fi

# if the jobdb directory doesn't exist, exit
    if [ ! -e "${JOBDB_DIR}" ]
    then
        if [ "$1" != 'new' ]
        then
            (>&2 echo "### error: jobdb directory ${JOBDB_DIR} doesn't exist")
            unset JOBDB_DIR
        fi
        return 2
    fi
}

jdbfile () {
# get the job directory, exit when an non-zero exit status was
# returned
    jdbdir
    local EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]
    then
        return ${EXIT_CODE}
    fi
    
    JOBDB_FILE="${JOBDB_DIR}/jobs"

# if the jobdb file doesn't exist, exit
    if [ ! -e "${JOBDB_FILE}" ]
    then
        (>&2 echo "### error: jobdb file ${JOBDB_FILE} doesn't exist")
        return 2
    fi
}

jdbedit () {
    local HELP_STR='
        Usage: jdbedit [--help]

        Edit the jobs list using the editor specified by the EDITOR
        environment variable.

        Options:
          --help      display this help message'
    show_help "${HELP_STR}" $@
    if [ $? -eq 0 ]
    then
        return 0
    fi
# get the jobdb file, exit if non-zero exit status was returned
    jdbfile
    local EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]
    then
        return ${EXIT_CODE}
    fi
# check whether the EDITOR environment variable has been set
    if [ "x" == "x${EDITOR}" ]
    then
        (>&2 echo "### error: EDITOR variable not set")
        return 2 
    fi
# start the editor with the jobs file
    ${EDITOR} "${JOBDB_FILE}"
}

jdbclear () {
    local HELP_STR='
        Usage: jdbclear [--help]

        Removes all jobs from the job database.
        Note: this can not be undone.

        Options:
          --help          display this help message'
    show_help "${HELP_STR}" $@
    if [ $? -eq 0 ]
    then
        return 0
    fi
# get the jobdb file, exit if non-zero exit status was returned
    jdbfile
    local EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]
    then
        return ${EXIT_CODE}
    fi
    
# start the editor with the jobs file
    rm -f "${JOBDB_FILE}"
    touch "${JOBDB_FILE}"
}

show_help () {
    local help_str=$1
    shift
    while (( "$#" ))
    do
        if [ "$1" == '--help' ]
        then
            echo "${help_str}"
            return 0
        fi
        shift
    done
    return 1
}
