#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz804689-getaddrinfo-localhost6-returns-127-0-0-1
#   Description: Test for bz804689 (getaddrinfo("localhost6") returns 127.0.0.1)
#   Author: Miroslav Franc <mfranc@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2012 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGES=(glibc gcc)

rlJournalStart
    rlPhaseStartSetup
        for p in "${PACKAGES[@]}"; do
            rlAssertRpm "$p"
        done; unset p
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "rlFileBackup /etc/hosts"
        rlRun "echo '127.0.0.1 localhost.localdomain localhost' > /etc/hosts"
        rlRun "echo '::1 localhost6.localdomain6 localhost6' >> /etc/hosts"
        rlRun "cp get.c $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "gcc get.c -o get"
        rlAssertExists "./get"
    rlPhaseEnd

    rlPhaseStartTest
        # honestly we clearly need something more elaborate than this to test it
        rlRun "./get localhost6 > log 2>&1"
        rlAssertGrep '::1' log
        rlAssertNotGrep '127.0.0.1' log
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "rlFileRestore /etc/hosts"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
