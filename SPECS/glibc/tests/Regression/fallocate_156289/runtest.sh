#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#
#   Copyright (c) 2018 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

TESTPROG="fallocate"

PACKAGE="glibc"
rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun -l "gcc --version"
        rlRun "TESTTMPDIR=$(mktemp -d)"
        rlRun -c "cp ${TESTPROG}.c++ ${TESTTMPDIR}/"
        rlRun "pushd $TESTTMPDIR"
    rlPhaseEnd

    rlPhaseStartTest
        TESTFILE=`pwd`/foo
        rlRun "touch $TESTFILE"
        rlRun -c "g++ ${TESTPROG}.c++ -o ${TESTPROG}"
        rlRun -c "./${TESTPROG} $TESTFILE 10000"
        size=`stat -c %s $TESTFILE`
        rlLog "Checking size of $TESTFILE (should be 1000): %size"

        if [ "$size" -ne "10000" ]
        then
            rlFail "Size differs: FAIL"
        else
            rlPass "Size is 1000: PASS"
        fi
    rlPhaseEnd

        rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TESTTMPDIR"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

