#!/bin/bash

#
# Setup task for x86_64 Fedora CI systems. 
# KOJI_TASK_ID per https://github.com/fedora-ci/dist-git-pipeline/pull/50 .
#

set -x

true "V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V-V"

echo "KOJI_TASK_ID=$KOJI_TASK_ID"

. /etc/os-release

if [ "$ID" == "fedora" ] && [ "$(arch)" == "x86_64" ]; then

    if [ -z "${KOJI_TASK_ID}" ]; then
        echo "Missing koji task ID, skipping ..."
        exit 0
    fi

    tmpd=`mktemp -d`
    pushd $tmpd
        koji download-task $KOJI_TASK_ID --noprogress --arch=src
        ls
        VR=$(rpm -qp glibc* --queryformat='%{version}-%{release}')
    popd
    rm -rf $tmpd

    tmpd=`mktemp -d`
    pushd $tmpd
        koji download-task $KOJI_TASK_ID --noprogress --arch=x86_64 --arch=noarch
        rm -f *debuginfo* glibc-headers-s390*
        ls
        dnf -y install *.rpm
    popd
    rm -rf $tmpd

    tmpd=`mktemp -d`
    pushd $tmpd
        koji download-task $KOJI_TASK_ID --noprogress --arch=i686
        rm -f *debuginfo*
        ls
        yum -y install glibc-$VR* glibc-devel-$VR*
    popd
    rm -rf $tmpd
else
    echo "Not Fedora x86_64, skipping..."
fi

true "^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^-^"
