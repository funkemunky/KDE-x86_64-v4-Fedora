#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz863384-getaddrinfo-fails-to-return-FQDN-for-AF_INET-and-AF_INET6
#   Description: Tests if 'getaddrinfo' returns FQDN in ai_canonname.
#   Author: Arjun Shankar <ashankar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2013 Red Hat, Inc. All rights reserved.
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

PACKAGES=(glibc glibc-devel gcc perl-Net-DNS-Nameserver)

rlJournalStart
    rlPhaseStartSetup
        #rlRun "rlImport glibc/gtu"
        rlFileBackup /etc/hosts
        #gtuAddLabController

        # Standard prep: check "Requires", create testdir, copy files
        for p in "${PACKAGES[@]}"; do
            rlAssertRpm "$p"
        done; unset p
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp gai-tst.c ns.pl $TmpDir"
        rlRun "pushd $TmpDir"

        # Compile the query program
        rlRun "gcc gai-tst.c -o gai-tst"
        rlAssertExists "gai-tst"

        # Start the local NS and make sure it is running
        rlRun "./ns.pl > ns.log 2>&1 &"
        rlRun "NS_PID=$!"
        sleep 10
        rlRun "kill -0 $NS_PID"

        if rlIsFedora
        then
            rlServiceStop systemd-resolved.service
        else
            # Back up resolver configuration
            rlFileBackup "/etc/resolv.conf"
        fi
    rlPhaseEnd

    function performTest 
    {
        # $1 is query, $2 is FQDN
        rlPhaseStartTest $1
            rlRun "./gai-tst $1 > gai-tst.out"
            rlLog "Contents of 'gai-tst.out':"
            rlLog "$(cat gai-tst.out)"
            rlAssertEquals "gai-tst.out should not contain 'ERROR's." "$(cat gai-tst.out | grep '^ERROR:' | wc -l)" 0
            if [[ $(cat gai-tst.out | grep '^WARN:' | wc -l) > 0 ]]
            then
                rlLogWarning "'gai-tst.out' contains:'"
                rlLogWarning "$(cat gai-tst.out | grep '^WARN:')"
            fi
            rlRun "cat gai-tst.out | grep -v '^WARN:\|^INFO:\|^ERROR:\|^query=' | sort -u > result_fqdn.out"
            rlAssertEquals "There must be exactly one unique result for all tests" "$(cat result_fqdn.out | wc -l)" 1
            rlAssertEquals "Result must match FQDN." "$(cat result_fqdn.out)" "$2"
        rlPhaseEnd
    }

    # Test with 'red.hat' domain
    rlPhaseStartSetup resolvConfChangeA
        rlRun "echo -e 'domain red.hat\nnameserver 127.0.0.1' > /etc/resolv.conf"
    rlPhaseEnd

    performTest     "foo"     "foo.red.hat"
    performTest "bar.foo" "bar.foo.red.hat"

    # Test with 'hat' domain
    rlPhaseStartSetup resolvConfChangeA
        rlRun "echo -e 'domain hat\nnameserver 127.0.0.1' > /etc/resolv.conf"
    rlPhaseEnd

    performTest     "foo.red"     "foo.red.hat"
    performTest "bar.foo.red" "bar.foo.red.hat"
    performTest         "red"         "red.hat"

    rlPhaseStartCleanup
        rlFileRestore
        if rlIsFedora
        then
            rlServiceRestore systemd-resolved.service
        fi

        # Stop local NS and ensure it is dead
        rlRun "kill $NS_PID"
        sleep 10
        rlRun "kill -0 $NS_PID" 1-255
        
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd

    rlLog "$(cat gai-tst.out)"

rlJournalPrintText
rlJournalEnd
