#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz1305132-segfault-in-hesiod-getgrouplist
#   Description: What the test does
#   Author: Arjun Shankar <ashankar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2016 Red Hat, Inc.
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
REQUIRES="glibc bind"

rlJournalStart
    rlPhaseStartSetup
        rlFileBackup /etc/hosts
        rlAssertRpm --all
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp named.hesiod zone-entry hesiod.conf $TmpDir"
        rlRun "pushd $TmpDir"

        # set up hesiod as a query source
        rlFileBackup --clean "/etc/nsswitch.conf"
        rlRun "sed -i 's/^\(\s*group\s*:.*\)$/# \1/' /etc/nsswitch.conf"
        rlRun "echo 'group: files hesiod' >> /etc/nsswitch.conf"
        rlRun "sed -i 's/^\(\s*passwd\s*:.*\)$/# \1/' /etc/nsswitch.conf"
        rlRun "echo 'passwd: files hesiod' >> /etc/nsswitch.conf"
        rlFileBackup --clean "/etc/hesiod.conf"
        rlRun "cp hesiod.conf /etc/"

        # set up a hesiod server
        rlServiceStop "named"
        rlRun "sleep 10"
        rlFileBackup --clean "/etc/named.conf"
        rlRun "cat zone-entry >> /etc/named.conf"
        rlFileBackup --clean "/var/named/named.hesiod"
        rlRun "cp named.hesiod /var/named"
        rlServiceStart "named"
        rlRun "sleep 10"
    rlPhaseEnd

    rlPhaseStartTest
        # point the resolver at local hesiod server
        # (we want to do this as late as possible since it disables the default
        # DNS server from being used)
        rlRun "cp /etc/resolv.conf /etc/resolv.conf.bz1305132.bak"
        rlRun "echo 'nameserver 127.0.0.1' > /etc/resolv.conf"
        rlRun "groups gnu > groups.out"
        rlAssertGrep "gnu\s*:\s*libc" groups.out
        rlRun "cp /etc/resolv.conf.bz1305132.bak /etc/resolv.conf"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlServiceStop "named"
        rlRun "sleep 10"
        rlRun "popd"
        rlFileRestore
        rlServiceRestore "named"
        rlRun "sleep 10"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
