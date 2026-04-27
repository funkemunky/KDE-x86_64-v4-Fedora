#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz692177-sysconf-SC-CACHE-returns-0-for-all-caches-on
#   Description: Test for bz692177 (sysconf(_SC_*CACHE) returns 0 for all caches on)
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

PACKAGE="glibc-common"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
    rlPhaseEnd

    rlPhaseStartTest "Cache sizes are reported with nonzero sizes"
        rlRun "test $(getconf -a | grep -i cache | awk '{i+=$2} END{print i}') != 0" 0\
        "Sum of cache sizes is non-zero."
        rlLog "$(getconf -a | grep -i cache)"
    rlPhaseEnd

    rlPhaseStartTest "(Xeon 5670 only - only L4 is missing)"
    if grep 'model name' /proc/cpuinfo | grep -q 5670; then
        rlRun "getconf -a | grep -i cache | grep -vi LEVEL4 | awk '0 == \$2 {exit 1}'" 0\
        "All caches on Xeon 5670 are non-zero."
        rlLog "$(getconf -a | grep -i cache | grep -vi LEVEL4)"
    else
        rlLog "This machine is not Xeon 5670"
        rlLog "$(grep 'model name' /proc/cpuinfo)"
    fi
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
