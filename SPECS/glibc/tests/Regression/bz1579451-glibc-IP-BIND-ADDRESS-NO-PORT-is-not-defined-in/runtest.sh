#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz1579451-glibc-IP-BIND-ADDRESS-NO-PORT-is-not-defined-in
#   Description: Test for BZ#1579451 (glibc IP_BIND_ADDRESS_NO_PORT is not defined in)
#   Author: Sergey Kolosov <skolosov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2019 Red Hat, Inc.
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
TESTPROG="bug"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        PACKNVR=$(rpm -q ${PACKAGE}.`arch`)
        rlRun "TESTTMPDIR=$(mktemp -d)"
        rlRun "cp ${TESTPROG}.c $TESTTMPDIR"
        rlRun "pushd $TESTTMPDIR"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun -c "gcc ${TESTPROG}.c -o $TESTPROG"
        rlAssertExists "$TESTPROG"
        rlRun -c "./${TESTPROG}"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TESTTMPDIR"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
