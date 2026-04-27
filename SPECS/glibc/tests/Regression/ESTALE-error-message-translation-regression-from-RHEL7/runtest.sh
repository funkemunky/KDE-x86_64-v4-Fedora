#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/ESTALE-error-message-translation-regression-from-RHEL7
#   Description: What the test does
#   Author: Sergey Kolosov <skolosov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2023 Red Hat, Inc.
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
TESTPROG="estale-test"
TESTED_LANGS="de_AT de_DE en_US es_ES fr_FR fr_FR.utf8 it_IT ja_JP ja_JP.utf8 ko_KR.utf8 pt_BR.utf8 ru_UA.utf8 zh_CN.utf8 zh_TW.utf8"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        PACKNVR=$(rpm -q ${PACKAGE}.`arch`)
        rlRun "TESTTMPDIR=$(mktemp -d)"
        rlRun "cp ${TESTPROG}.c $TESTTMPDIR"
        rlRun "cp refs/orig_* $TESTTMPDIR"
        rlRun "pushd $TESTTMPDIR"
    rlPhaseEnd

    rlPhaseStartTest prepare
        rlRun -c "gcc ${TESTPROG}.c -o $TESTPROG"
        rlAssertExists "$TESTPROG"
    rlPhaseEnd

    for L in $TESTED_LANGS
    do
        rlPhaseStartTest estale-test-$L
            rlRun -c "LANG=$L ./${TESTPROG} 2> out_$L"
            if rlIsRHEL "<=9" && [ -f orig_${L}_rhel ]
            then
                rlAssertNotDiffer out_$L orig_${L}_rhel
            else
                rlAssertNotDiffer out_$L orig_$L
            fi
            rlLogInfo "out_$L:\n$(cat out_$L)"
        rlPhaseEnd
    done

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TESTTMPDIR"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
