#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Sanity/bz2023420-glibc-Backport-ld-so-list-diagnostics
#   Description: Test for BZ#2023420 (glibc: Backport ld.so --list-diagnostics)
#   Author: Martin Coufal <mcoufal@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2017 Red Hat, Inc.
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

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "LDSO_PATH=$(rpm -ql ${PACKAGE}-common | grep ld.so)"
        rlRun "tmpdir=$(mktemp -d)"
        rlRun "pushd $tmpdir"
    rlPhaseEnd

    rlPhaseStartTest
        if [[ -z "$LDSO_PATH" ]]; then
            rlFail "Shared library 'ld.so' not found!"
        elif [[ ! -L "$LDSO_PATH" ]]; then
            rlFail "$LDSO_PATH should be a symbolic link!"
        else
            rlRun "$LDSO_PATH --help >> help.log"
            rlAssertGrep "Usage:.*ld\.so" help.log
            rlAssertGrep "--list-diagnostics" help.log
            rlRun "$LDSO_PATH --list-diagnostics >> list-diagnostics.log"
            rlAssertGreaterOrEqual "Basic sanity line count check" $(cat list-diagnostics.log | wc -l)  10
            rlAssertGrep "dso" list-diagnostics.log
            rlAssertGrep "env_filtered" list-diagnostics.log
            rlAssertGrep "auxv" list-diagnostics.log
            rlAssertGrep "uname" list-diagnostics.log
        fi
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -rf $tmpdir"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
