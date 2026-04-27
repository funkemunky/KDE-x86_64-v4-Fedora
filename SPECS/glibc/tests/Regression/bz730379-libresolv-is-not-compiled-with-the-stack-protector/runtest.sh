#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz730379-libresolv-is-not-compiled-with-the-stack-protector
#   Description: Test for bz730379 (libresolv is not compiled with the stack protector)
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

PACKAGES=(glibc binutils)
test -d /lib64 && dlib="/lib64" || dlib="/lib"
TSTLIB="libresolv.so.2"

rlJournalStart
    rlPhaseStartSetup
        for p in "${PACKAGES[@]}"; do
            rlAssertRpm "$p"
        done; unset p
        if rlIsRHEL "<9"
        then
            TSTLIB="libresolv-2.*.so"
        fi
    rlPhaseEnd

    rlPhaseStartTest
        rlRun -l "readelf -sW /$dlib/${TSTLIB} 2>/dev/null | grep -q '__stack_chk_fail'" 0 "Canary found"
        rlRun -l "readelf -Wl /$dlib/${TSTLIB} 2>/dev/null | grep GNU_STACK | grep RWX" 1 "NX enabled"
    rlPhaseEnd

rlJournalPrintText
rlJournalEnd
