#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz839572-Anaconda-traceback-when-installing-on-s390x
#   Description: Test for BZ#839572 (Anaconda traceback when installing on s390x)
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
. /usr/share/beakerlib/beakerlib.sh
rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm glibc
        if rlIsRHEL 8; then
            rlAssertExists "/usr/bin/python3"
            USEPYTHON="python3"
        else
            rlAssertExists "/usr/bin/python"
            USEPYTHON="python"
        fi
    rlPhaseEnd

    rlPhaseStartTest
        rlRun -l "$USEPYTHON -c 'import math; print (math.exp(-0.5))'"
        rlRun -l "$USEPYTHON -c 'import math; print (math.exp(10))'"
        rlRun -l "$USEPYTHON -c 'import math; print (math.sqrt(2.0))'"
        rlRun -l "$USEPYTHON -c 'import math; math.exp(0)'"
        rlRun -l "$USEPYTHON -c 'import random;'"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
