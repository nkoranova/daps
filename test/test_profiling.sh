#!/bin/bash
#
# Copyright (C) 2011-2013 Frank Sundermeyer <fsundermeyer@opensuse.org>
#
# Author:
# Frank Sundermeyer <fsundermeyer@opensuse.org>
#
# Testing DAPS: profiling
#
# Testcases
# All tests have to be run twice, once with saxon and once with xsltproc
#
# * Is the profiling command successfully executed?
# * Does the profiling directory get created?
# * Does the profiling directory contain all files?
#   - Does it contain files not belonging to the set?
# * Have the entities been resolved?
# * Does the profiled XML validate?
# * Is a file that has changed since last profiling updated?
#   - Have files that not have been modified been updated?
# * In case the XML sources contain a profiling urn:
#   - Does the XML contain the correct content?

# Use _VARNAME for variables that also might be used in DAPS itself to 
# avoid potential clashes. Just to be on the safe side.


#--------------------------------
# Global Variable Definitions
#
declare -a _DOC_FILES

_DAPSROOT=".."
DAPSEXEC="${_DAPSROOT}/bin/daps --dapsroot=\"${_DAPSROOT}\""

_DOC_DIR="documents/"
_MAIN="book.xml"
MAINPATH="${_DOC_DIR}/xml/$_MAIN"
_SET_FILES=( appendix.xml book.xml part_blocks.xml part_inlines.xml part_profiling.xml )
_NO_SET_FILE="not_in_set.xml"

SHUNIT2SRC="/usr/share/shunit2/src/shunit2"

#--------------------------------
# Helper functions
#

# Remove the build directory
#
clean_build() {
    rm -rf "${_DOC_DIR}/build"
}


#--------------------------------
# Initiate
# this function is run _before_ the tests are executed
#
oneTimeSetUp() {
    # Clean up the build directory
    clean_build
    # get the profiling directory
    _PROFILEDIR=$(eval "$DAPSEXEC --main $MAINPATH showvariable VARIABLE=PROFILEDIR 2>/dev/null")
    if [ $? -ne 0 ]; then
        echo " └─ The initial DAPS call to determine the profiling directory failed. Skipping tests"
        exit 1
    fi
}

#--------------------------------
# Post
# this function is run _after_ the tests are executed
#
oneTimeTearDown() {
    # Clean up the build directory
    clean_build
}


#---------------------------------------------------------------
# TESTS
#---------------------------------------------------------------

#--------------------------------
# Is the profiling command successfully executed?
#
test_Profiling () {
    eval "$DAPSEXEC -v0 --main $MAINPATH profile >/dev/null"
    assertTrue \
        ' └─ The profiling command itself failed' \
        "[ $? -eq 0 ]"
}

#--------------------------------
# Does the profiling directory get created?
#
test_Profiling_PROFILEDIR () {
    assertTrue \
        " └─ The profiling directory '$_PROFILEDIR' does not exist" \
        "[ -d $_PROFILEDIR ]"
}

#--------------------------------
# Does the profiling directory contain all files?
# Does it contain files not belonging to the set?
#
test_Profiling_filelist () {
    local FILE MISSING
    for FILE in "${_SET_FILES[@]}"; do
        [ -f ${_PROFILEDIR}/$FILE ] || MISSING="$MISSING $FILE"
    done
    assertTrue \
        " └─ File(s) '$MISSING' are missing $_PROFILEDIR" \
        '[ -z "$MISSING" ]'
    # $_NO_SET_FILE is not part of the set and therefore must not
    # be profiled
    assertFalse \
        "$_NO_SET_FILE, which is not part f the set has been profiled" \
        '[ -f ${_PROFILEDIR}/$_NO_SET_FILE ]'
}

#--------------------------------
# Have the entities been resolved?
#
test_Profiling_Entities () {
    egrep "&ent[0-9];" ${_PROFILEDIR}/*.xml >/dev/null 2>&1
    assertFalse \
        ' └─ Not all entities have been resolved' \
        "[ $? -eq 0 ]"
}

#--------------------------------
# Does the profiled XML validate?
#
test_Profiling_validate() {
    xmllint --noent --postvalid --noout --nowarning --xinclude \
        ${_PROFILEDIR}/$_MAIN >/dev/null 2>&1
    assertTrue \
        ' └─ Profiled XML does not validate' \
        "[ $? -eq 0 ]"
}

#--------------------------------
# Is a file that has changed since last profiling updated?
# Have files that not have been modified been updated?
#
test_Profiling_update() {
    local FILE OLDDATE_FILES OLDDATE_MAIN NEWDATE_FILES NEWDATE_MAIN
    # get date for $MAIN from profiling dir (unix timestamp)
    OLDDATE_MAIN=$(stat -c %Y ${_PROFILEDIR}/$MAIN)
    # "update" $MAIN
    sleep 1
    touch $MAINPATH
    # the timestamps of the other files should not have changed
    # because they haven't been updated and therefor do not need to be
    # profiled again. In order to keep the test as simple as possible, we
    # add the timestamps of all other files
    OLDDATE_FILES=0
    NEWDATE_FILES=0
    for FILE in "${_SET_FILES[@]}"; do
        if [[ $FILE == $_MAIN ]]; then continue; fi
        OLDDATE_FILES=$(expr $OLDDATE_FILES + $(stat -c %Y ${_PROFILEDIR}/$FILE))
    done
    # rerun profiling
    eval "$DAPSEXEC -v0 --main $MAINPATH profile >/dev/null"
    # get new date
    NEWDATE_MAIN=$(stat -c %Y $MAINPATH)
    assertTrue \
        ' └─ $MAIN has not been updated by profiling although it had changed' \
        "[ $OLDDATE_MAIN -lt $NEWDATE_MAIN ]"
    for FILE in "${_SET_FILES[@]}"; do
        if [[ $FILE == $_MAIN ]]; then continue; fi
        NEWDATE_FILES=$(expr $NEWDATE_FILES + $(stat -c %Y ${_PROFILEDIR}/$FILE))
    done
    assertTrue \
        ' └─  Files have been updated although they did not change' \
        "[ $OLDDATE_FILES -eq $NEWDATE_FILES ]"
}
    
#--------------------------------
# Is the content correctly profiled?
#
test_Profiling_content () {
    local COUNT _PROFILEDIR
    
    # First test: no profiled paras should appear in the profiled XML
    #             because no profiling attributes are set
    clean_build
    _PROFILEDIR=$(eval "$DAPSEXEC -v0 --main $MAINPATH showvariable VARIABLE=PROFILEDIR")
    eval "$DAPSEXEC -v0 --main $MAINPATH profile >/dev/null"
    COUNT=$(egrep "(arch|condition|os|vendor)=(arch|condition|os|vendor)[12]" \
        ${_PROFILEDIR}/*.xml 2>/dev/null | wc -l)
    assertTrue \
        ' └─ Content has been filtered from XML although no profiling attribute was set' \
        "[ $COUNT -eq 8 ]"
    
    # Second test: no profiled paras should appear in the profiled XML
    #              because profiling parameters have been set to a value that
    #              has no match in the XML
    clean_build
    _PROFILEDIR=$(eval "$DAPSEXEC -v0 --main $MAINPATH showvariable VARIABLE=PROFILEDIR PROFARCH=foo PROFCONDITION=foo PROFOS=foo PROFVENDOR=foo")
    eval "$DAPSEXEC -v0 --main $MAINPATH profile PROFARCH=foo PROFCONDITION=foo PROFOS=foo PROFVENDOR=foo >/dev/null"
    egrep "(arch|condition|os|vendor)=(arch|condition|os|vendor)[12]" \
        ${_PROFILEDIR}/*.xml >/dev/null 2>&1
    assertFalse \
        ' └─ Profiled XML contains content that should have been filtered (all profiling variables have been set to a value that has no match in the XML)' \
        "[ $? -eq 0 ]"
    
    # Third test: arch2 should be filtered out
    #
    clean_build
    _PROFILEDIR=$(eval "$DAPSEXEC -v0 --main $MAINPATH showvariable VARIABLE=PROFILEDIR PROFARCH=arch1")
    eval "$DAPSEXEC -v0 --main $MAINPATH profile PROFARCH=arch1 >/dev/null"
    grep "arch=arch2" ${_PROFILEDIR}/*.xml >/dev/null 2>&1
    assertFalse \
        ' └─ Profiled XML contains arch2 content that should have been filtered' \
        "[ $? -eq 0 ]"
    
    # Fourth test: condition1 should be filtered out
    #
    clean_build
    _PROFILEDIR=$(eval "$DAPSEXEC -v0 --main $MAINPATH showvariable VARIABLE=PROFILEDIR PROFCONDITION=condition2")
    eval "$DAPSEXEC -v0 --main $MAINPATH profile PROFCONDITION=condition2 >/dev/null"
    grep "condition=condition1" ${_PROFILEDIR}/*.xml >/dev/null 2>&1
    assertFalse \
        ' └─ Profiled XML contains condition1 content that should have been filtered' \
        "[ $? -eq 0 ]"
    
    # Fifth test: os2 should be filtered out
    #
    clean_build
    _PROFILEDIR=$(eval "$DAPSEXEC -v0 --main $MAINPATH showvariable VARIABLE=PROFILEDIR PROFOS=os1")
    eval "$DAPSEXEC -v0 --main $MAINPATH profile PROFOS=os1 >/dev/null"
    grep "os=os2" ${_PROFILEDIR}/*.xml >/dev/null 2>&1
    assertFalse \
        ' └─ Profiled XML contains os2 content that should have been filtered' \
        "[ $? -eq 0 ]"
    
    # Sixth test: vendor1 should be filtered out
    #
    clean_build
    _PROFILEDIR=$(eval "$DAPSEXEC -v0 --main $MAINPATH showvariable VARIABLE=PROFILEDIR PROFVENDOR=vendor2")
    eval "$DAPSEXEC -v0 --main $MAINPATH profile PROFVENDOR=vendor2 >/dev/null"
    grep "vendor=vendor1" ${_PROFILEDIR}/*.xml >/dev/null 2>&1
    assertFalse \
        ' └─ Profiled XML contains vendor1 content that should have been filtered' \
        "[ $? -eq 0 ]"  
}



# source shUnit2 test
eval "source $SHUNIT2SRC"
