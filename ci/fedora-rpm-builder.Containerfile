FROM fedora:43

# Keep downloaded RPMs in the image layer cache so rebuilds are cheaper.
RUN printf '%s\n' 'keepcache=True' 'max_parallel_downloads=10' > /etc/dnf/dnf.conf.d/99-ci-cache.conf

RUN dnf -y upgrade --refresh \
    && dnf -y install \
        'dnf-command(builddep)' \
        fedpkg \
        git \
        nodejs \
        python3 \
        rpm-build \
        rpmdevtools \
    && dnf clean all

