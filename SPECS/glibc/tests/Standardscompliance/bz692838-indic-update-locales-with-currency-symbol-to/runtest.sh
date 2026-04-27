#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Standardscompliance/bz692838-indic-update-locales-with-currency-symbol-to
#   Description: Test for bz692838 ([indic] update locales with currency symbol to)
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

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGES=(glibc glibc-common sed)
LOCALES=(ar_IN as_IN bn_IN en_IN gu_IN hi_IN kn_IN kok_IN ks_IN ml_IN mr_IN or_IN pa_IN sa_IN sd_IN ta_IN te_IN)

rlJournalStart
    rlPhaseStartSetup
        for p in "${PACKAGES[@]}"; do
            rlAssertRpm "$p"
        done; unset p
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "cp symbol.txt $TmpDir"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest
        for l in "${LOCALES[@]}"; do
            rlRun "LC_MONETARY=$l locale -c LC_MONETARY | sed -n 3p > $l"
            rlAssertNotDiffer "$l" symbol.txt
        done; unset l
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
