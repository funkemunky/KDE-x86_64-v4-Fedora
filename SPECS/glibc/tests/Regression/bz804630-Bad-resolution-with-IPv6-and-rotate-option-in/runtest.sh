#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz804630-Bad-resolution-with-IPv6-and-rotate-option-in
#   Description: Test for BZ#804630 (Bad resolution with IPv6 and rotate option in)
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

PACKAGES=(bind glibc policycoreutils)

rlJournalStart
    rlPhaseStartSetup
#        rlRun "rlImport glibc/gtu"
        for p in "${PACKAGES[@]}"; do
            rlAssertRpm "$p"
        done; unset p
        rlFileBackup /etc/hosts
#        gtuAddLabController
        rlFileBackup /etc/resolv.conf
        [ -e /etc/named.conf ] && rlFileBackup /etc/named.conf    # RHEL5... no comment ;-)
        rlRun "cp -f named.conf /etc && restorecon /etc/named.conf && chgrp named /etc/named.conf"
        rlRun "cp -f resolv.conf /etc && restorecon /etc/resolv.conf"
        rlRun "cp -f named.taktik /var/named && restorecon -R /var/named"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp testcase.c $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "gcc -g testcase.c -o testcase"
        rlAssertExists "./testcase"
        # bz#678227 etc. - start and stop are not idempotent operations for many initscripts (RHEL5)
        service named stop
        sleep 3
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "service named start"
        rlRun "./testcase > log 2>&1"
        rlLog "$(<log)"
        rlRun "service named stop"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm /etc/named.conf" # RHEL5
        rlRun "rm /var/named/named.taktik"
        rlFileRestore
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
