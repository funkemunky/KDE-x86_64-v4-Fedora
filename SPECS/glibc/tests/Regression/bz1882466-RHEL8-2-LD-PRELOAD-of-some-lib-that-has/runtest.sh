#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz1882466-RHEL8-2-LD-PRELOAD-of-some-lib-that-has
#   Description: Test for BZ#1882466 (RHEL8.2 - LD_PRELOAD of <some lib that has)
#   Author: Sergey Kolosov <skolosov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2021 Red Hat, Inc.
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
TESTPROG="testlib"
TESTPRELOADLIBS="libpthread.so.0 libstdc++.so.6 libresolv.so.2"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        PACKNVR=$(rpm -q ${PACKAGE}.`arch`)
        rlRun "TESTTMPDIR=$(mktemp -d)"
        rlRun "cp ${TESTPROG}.cc $TESTTMPDIR"
        rlRun "pushd $TESTTMPDIR"
    rlPhaseEnd

    rlPhaseStartTest "basic"
        rlRun -c "g++ -c  -Wall -pedantic -fPIC -fno-exceptions -fno-rtti -fno-builtin ${TESTPROG}.cc -o ${TESTPROG}.o"
        rlRun -c "g++ -shared -dynamiclib  ${TESTPROG}.o -o lib${TESTPROG}.so.1.0"
        rlAssertExists "lib${TESTPROG}.so.1.0"
        rlRun -c "LD_PRELOAD=${TESTTMPDIR}/lib${TESTPROG}.so.1.0 /lib64/libc.so.6"
    rlPhaseEnd

    rlPhaseStartTest "additional libs"
        rlRun -c "LD_PRELOAD=${TESTTMPDIR}/lib${TESTPROG}.so.1.0 /lib64/libc.so.6"
        for L in $TESTPRELOADLIBS
        do
            rlRun -c "LD_PRELOAD=/usr/lib64/$L /lib64/libc.so.6"
            [[ $(rlGetArch) == "x86_64" ]] && rpm -q glibc.i686 && rlRun -c "LD_PRELOAD=/usr/lib/$L /usr/lib/libc.so.6"
        done
   rlPhaseEnd



    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TESTTMPDIR"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
