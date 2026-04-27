# Makefile - bz464146-sp-corruption - Bugzilla(s) 464146
# Author: Petr Muller <pmuller@redhat.com>
# Location: /tools/glibc/Regression/bz464146-sp-corruption/Makefile

# Description: Test for bz464144, a stack pointer corruption problem

# Copyright (c) 2008 Red Hat, Inc. All rights reserved. This copyrighted material 
# is made available to anyone wishing to use, modify, copy, or
# redistribute it subject to the terms and conditions of the GNU General
# Public License v.2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 


TOPLEVEL_NAMESPACE=/tools
PACKAGE_NAME=glibc
RELATIVE_PATH=Regression/bz464146-sp-corruption

export TEST=$(TOPLEVEL_NAMESPACE)/$(PACKAGE_NAME)/$(RELATIVE_PATH)
export TESTVERSION=1.0

BUILT_FILES=

FILES=$(METADATA) runtest.sh Makefile PURPOSE testit.c

.PHONY: all install download clean

run: $(FILES) build
	./runtest.sh

build: $(BUILT_FILES)
	chmod a+x ./runtest.sh

clean:
	rm -f *~ $(BUILT_FILES)


include /usr/share/rhts/lib/rhts-make.include


$(METADATA): Makefile
	@touch $(METADATA)
	@echo "Owner:        Petr Muller <pmuller@redhat.com>" > $(METADATA)
	@echo "Name:         $(TEST)" >> $(METADATA)
	@echo "Path:         $(TEST_DIR)"       >> $(METADATA)
	@echo "TestVersion:  $(TESTVERSION)"    >> $(METADATA)
	@echo "Description:  Test for bz464144, a stack pointer corruption problem" >> $(METADATA)
	@echo "Bug:          464146" >> $(METADATA)
	@echo "Type:         Regression" >> $(METADATA)
	@echo "TestTime:     15m" >> $(METADATA)
	@echo "RunFor:       $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Requires:     $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Requires:     quota-devel" >> $(METADATA)
	@echo "Requires:     gcc" >> $(METADATA)
	@echo "License:      GPLv2" >> $(METADATA)
	@echo "Architectures: x86_64 ia64 s390x" >> $(METADATA)
	@echo "Releases:      -RHEL3 -RHEL4" >> $(METADATA)

	rhts-lint $(METADATA)
