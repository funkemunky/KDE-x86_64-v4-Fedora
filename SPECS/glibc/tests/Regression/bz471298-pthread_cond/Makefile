# Makefile - bz471298-pthread_cond - Bugzilla(s) 471298
# Author: Petr Muller <pmuller@redhat.com>
# Location: /tools/glibc/Regression/bz471298-pthread_cond/Makefile

# Description: Contains one simple testcase, hanging when exhibiting the bug

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
RELATIVE_PATH=Regression/bz471298-pthread_cond

export TEST=$(TOPLEVEL_NAMESPACE)/$(PACKAGE_NAME)/$(RELATIVE_PATH)
export TESTVERSION=1.0

BUILT_FILES=

FILES=$(METADATA) runtest.sh Makefile PURPOSE pthread_cond_test.c

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
	@echo "Description:  Contains one simple testcase, hanging when exhibiting the bug" >> $(METADATA)
	@echo "Bug:          471298" >> $(METADATA)
	@echo "Type:         Regression" >> $(METADATA)
	@echo "TestTime:     15m" >> $(METADATA)
	@echo "RunFor:       $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Requires:     $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Requires:     gcc" >> $(METADATA)
	@echo "License:      GPLv2" >> $(METADATA)
	@echo "Releases:			-RHEL2.1 -RHEL3 -RHEL4" >> $(METADATA)

	rhts-lint $(METADATA)
