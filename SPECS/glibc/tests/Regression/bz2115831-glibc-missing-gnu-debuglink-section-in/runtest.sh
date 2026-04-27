#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz2115831-glibc-missing-gnu-debuglink-section-in
#   Description: Test for BZ#2115831 (glibc missing .gnu_debuglink section in libc.so.6,)
#   Author: Sergey Kolosov <skolosov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2022 Red Hat, Inc.
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
LIBC_SO_6_LIBS=$(find /usr/lib/ /usr/lib64/ -name libc.so.6)
TESTL2="/usr/bin/ld.so"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        PACKNVR=$(rpm -q ${PACKAGE}.`arch`)
        rlRun "TESTTMPDIR=$(mktemp -d)"
        rlRun "pushd $TESTTMPDIR"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun -l "rpm -ql glibc-debuginfo"
        for LIB in $LIBC_SO_6_LIBS; do
            rlRun -l "eu-readelf -S $LIB | grep -q .debug_" 1
            rlRun -l "eu-readelf -S $LIB | grep -q .gnu_debuglink" 0
        done
        rlRun -l "eu-readelf -S $TESTL2 | grep -q .debug_" 0
        rlRun -l "eu-readelf -S $TESTL2 | grep -q .gnu_debuglink" 1
        rlRun -l "eu-readelf -s $TESTL2 | grep -q annobin" 1
        if rlIsRHEL "8"; then
            rlRun -l "rpm -ql glibc-debuginfo|sort|grep '/ld-$(rpm -q --qf "%{VERSION}" ${PACKAGE}.`arch`)'" 1
            rlRun -l "rpm -ql glibc-debuginfo|sort|grep '/libc-$(rpm -q --qf "%{VERSION}" ${PACKAGE}.`arch`)'" 0
        elif rlIsRHEL ">=9" || rlIsFedora; then
            rlRun -l "rpm -ql glibc-debuginfo|sort|grep ld-linux-" 1
            rlRun -l "rpm -ql glibc-debuginfo|sort|grep libc.so.6-" 0
        else
            rlFail "Test does not support current distro (yet?)!"
        fi
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TESTTMPDIR"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
