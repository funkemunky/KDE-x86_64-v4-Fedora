# Makefile - bz434601-timedlock-segfault - Bugzilla(s) 434601
# Author: Petr Muller <pmuller@redhat.com>
# Location: /tools/glibc/Regression/bz434601-timedlock-segfault/Makefile

# Description: Tests segfault in pthread_mutex_timedlock function


TOPLEVEL_NAMESPACE=/tools
PACKAGE_NAME=glibc
RELATIVE_PATH=Regression/bz434601-timedlock-segfault

export TEST=$(TOPLEVEL_NAMESPACE)/$(PACKAGE_NAME)/$(RELATIVE_PATH)
export TESTVERSION=1.0

BUILT_FILES=

FILES=$(METADATA) runtest.sh Makefile timedlock.c

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
	@echo "Description:  Tests segfault in pthread_mutex_timedlock function" >> $(METADATA)
	@echo "Bug:          434601" >> $(METADATA)
	@echo "Type:         Regression" >> $(METADATA)
	@echo "TestTime:     6m" >> $(METADATA)
	@echo "RunFor:       $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Requires:     $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Requires:     gcc" >> $(METADATA)
	@echo "License:      GPLv3" >> $(METADATA)

	rhts-lint $(METADATA)
