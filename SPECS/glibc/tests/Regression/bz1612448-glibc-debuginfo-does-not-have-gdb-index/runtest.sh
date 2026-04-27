#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz1612448-glibc-debuginfo-does-not-have-gdb-index
#   Description: Test for BZ#1612448 (glibc debuginfo does not have .gdb_index)
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
TESTPROG="put_test_prog_here"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlAssertRpm glibc-debuginfo
        rlAssertRpm binutils
        rlRun "LIBC_SO_DEBUGS=\"$(find /usr -name 'libc*.so*.debug')\""
    rlPhaseEnd

    rlPhaseStartTest
        for LIBC_SO_DEBUG in $LIBC_SO_DEBUGS; do
            rlAssertExists "$LIBC_SO_DEBUG"
            rlRun -l "readelf -S $LIBC_SO_DEBUG | grep -w gdb_index"
        done
    rlPhaseEnd

    rlPhaseStartCleanup

    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
