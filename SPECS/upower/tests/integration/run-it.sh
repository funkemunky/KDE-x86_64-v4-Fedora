#!/usr/bin/bash
set -u

# main script
IT="${1:-/usr/libexec/installed-tests/upower/integration-test.py}"

# check if we need to install additional packages
# which is the case if we are on RHEL 8
source /etc/os-release || exit 1

if [[ "$ID" = *"rhel"* ]] && [[ "$VERSION_ID" == *"8"* ]]; then
    dnf config-manager -y --add-repo umockdev.repo
    dnf install -y umockdev-devel python3-gobject-base
    pip3 install python-dbusmock
fi

# execute the integration test via umockdev-wrapper
exec umockdev-wrapper "$IT"
