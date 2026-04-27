#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz1022022-getaddrinfo-behavior-changed-between-RHEL-6-4-and-RHEL-6-5
#   Description: Calls getaddrinfo and verifies behavior as per BZ
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

PACKAGE=glibc
REQUIRES=(gcc glibc glibc-devel)

rlJournalStart
    rlPhaseStartSetup
        for p in "${REQUIRES[@]}"; do
            rlAssertRpm "$p"
        done; unset p
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp tst-getaddrinfo.c $TmpDir"
        rlRun "pushd $TmpDir"

        rlRun "gcc -o tst-getaddrinfo tst-getaddrinfo.c"
        rlAssertExists "tst-getaddrinfo"

        rlRun "ORIG_HOSTNAME=$(hostname)"
        rlFileBackup --clean "/etc/hostname"
        rlRun "echo 'www' > /etc/hostname"
        rlRun "hostname -F /etc/hostname"

        rlFileBackup --clean "/etc/hosts"
        rlRun "echo '127.0.0.1    www.fubar.redhat    www' >> /etc/hosts"
        rlRun "echo '::1          www.fubar.redhat    www' >> /etc/hosts"
        # Note that the 'canonical name' is always the first name entry in
        # each tuple ^, i.e. 'www.fubar.redhat' in our case
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "./tst-getaddrinfo > tst.out"
        rlLog "$(cat tst.out)"
        rlRun "OUT=($(cat tst.out))"
        rlAssertEquals "Correct number of output lines" "${#OUT[@]}" "4"

        if rlIsRHEL 6; then
          # The result 'www' for AF_INET is basically incorrect, but we want to
          # keep it consistent during the life of RHEL 6
          rlAssertEquals "gethostname"            "${OUT[0]}" "www"
          rlAssertEquals "getaddrinfo, AF_INET"   "${OUT[1]}" "www"
          rlAssertEquals "getaddrinfo, AF_UNSPEC" "${OUT[3]}" "www.fubar.redhat"

          rlLog "We don't check (getaddrinfo, AF_INET6) on RHEL 6"
        else
          rlAssertEquals "gethostname"             "${OUT[0]}" "www"
          rlAssertEquals "getaddrinfo, AF_INET"    "${OUT[1]}" "www.fubar.redhat"
          rlAssertEquals "getaddrinfo, AF_INET6"   "${OUT[2]}" "www.fubar.redhat"
          rlAssertEquals "getaddrinfo, AF_UNSPEC"  "${OUT[3]}" "www.fubar.redhat"
        fi
    rlPhaseEnd

    rlPhaseStartCleanup
        rlFileRestore "/etc/hosts"
        rlFileRestore "/etc/hostname"
        rlRun "hostname $ORIG_HOSTNAME"

        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
