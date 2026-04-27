#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz1563046-getlogin-r-return-early-when-linux-sentinel-value
#   Description: Test for BZ#1563046 (getlogin_r return early when linux sentinel value)
#   Author: Sergey Kolosov <skolosov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

PACKAGE="glibc"
TESTPROG="tst-getlogin_r"
ITERS=1000
#SUPPORTDIR="support"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun -l "gcc --version"
        rlRun "TESTTMPDIR=$(mktemp -d)"
        rlRun "cp ${TESTPROG}.c $TESTTMPDIR"
        rlRun "cp list.gdb $TESTTMPDIR"
#        rlRun "cp -r support $TESTTMPDIR"
        rlRun "pushd $TESTTMPDIR"
    rlPhaseEnd

#    rlPhaseStartTest "Prepare$"
#        rlRun "pushd $SUPPORTDIR"
#        rlRun -c "mv test-driver.c test-driver.c_"
#        for SFILE in *.c
#        do
#            rlRun -c "gcc -D_GNU_SOURCE -I../ -c $SFILE"
#        done
#        rlRun -c "mv test-driver.c_ test-driver.c"
#        rlRun "popd"
#        SUPPORTFILES=$(echo ${SUPPORTDIR}/*.o)
#    rlPhaseEnd

    rlPhaseStartTest "${TESTPROG}"
        rlRun -c "gcc -g ${TESTPROG}.c -o ${TESTPROG}"
        rlAssertExists "${TESTPROG}"
        rlRun -c "./${TESTPROG}"
        rlRun -l "gdb --batch --command=list.gdb ./${TESTPROG} > gdb_log"
        rlAssertGrep "if (uid == (uid_t) -1)" gdb_log
        rlFileSubmit gdb_log
    rlPhaseEnd

#    rlPhaseStartTest "WithoutLoginuid"
#        rlRun -l "time ./${TESTPROG} $ITERS"
#    rlPhaseEnd

#    rlPhaseStartTest "WithLoginuidminusone"
#        rlRun -c "echo -n -1 > fakeloginuid"
#        rlRun -c "mount -o bind fakeloginuid /proc/self/loginuid"
#        rlRun -l "time ./${TESTPROG} $ITERS"
#        rlRun -c "umount /proc/self/loginuid"
#    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TESTTMPDIR"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
