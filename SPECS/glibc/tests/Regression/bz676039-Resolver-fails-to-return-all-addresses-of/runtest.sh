#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz676039-Resolver-fails-to-return-all-addresses-of
#   Description: Test for bz676039 (Resolver fails to return all addresses of)
#   Author: Miroslav Franc <mfranc@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2011 Red Hat, Inc. All rights reserved.
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

# Include rhts environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGES=(glibc gcc glibc-common)

rlJournalStart
    rlPhaseStartSetup
        for p in "${PACKAGES[@]}"; do
            rlAssertRpm "$p"
        done; unset p
        # currently cannot count on beakerlib, it could be more stable
        rlRun "cp -f /etc/hosts /etc/hosts.backup"
        rlRun "cp -f /etc/host.conf /etc/host.conf.backup"
        rlRun "echo -e '1.1.1.1         multihost\n2.2.2.2         multihost\n3.3.3.3         multihost' >> /etc/hosts"
        rlRun "grep -q 'multi on' /etc/host.conf || echo 'multi on' >> /etc/host.conf"
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "cp 676039-resolver.c a.out-gold getent-gold $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "gcc 676039-resolver.c"
        rlAssertExists "./a.out"
    rlPhaseEnd

    rlPhaseStartTest "Reproducer from bugzilla"
        rlRun "./a.out multihost > a.out-log"
        rlAssertNotDiffer "a.out-log" "a.out-gold"
        rlLog "$(diff a.out-log a.out-gold)"
    rlPhaseEnd

    rlPhaseStartTest "getent ahosts"
        rlRun "getent ahosts multihost multihost > getent-log"
        # trailing spaces can sometimes cause problems
        # different versions have different output
        # that's why I decided to get rid of them
        rlRun "sed -i 's/ *$//' getent-log"
        rlAssertNotDiffer "getent-log" "getent-gold"
        rlLog "$(diff getent-log getent-gold)"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "cp -f /etc/hosts.backup /etc/hosts"
        rlRun "cp -f /etc/host.conf.backup /etc/host.conf"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
