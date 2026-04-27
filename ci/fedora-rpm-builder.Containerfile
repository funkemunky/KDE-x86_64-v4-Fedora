FROM fedora:43

# Keep downloaded RPMs in the image layer cache so rebuilds are cheaper.
RUN mkdir -p /etc/dnf/dnf.conf.d \
    && printf '%s\n' 'keepcache=True' 'max_parallel_downloads=10' > /etc/dnf/dnf.conf.d/99-ci-cache.conf

RUN dnf -y upgrade --refresh \
    && dnf -y install \
        git \
        make \
        python3 \
        rpm-build \
        copr-cli \
        ca-certificates \
        curl \
    && dnf clean all
