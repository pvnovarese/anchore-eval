# Dockerfile for Anchore Enterprise Evaluation

# use alpine:latest for a smaller image, but it often won't have any published CVEs
FROM cgr.dev/chainguard/wolfi-base:latest

LABEL maintainer="pvn@novarese.net"
LABEL name="anchore-eval"
LABEL org.opencontainers.image.title="anchore-eval"
LABEL org.opencontainers.image.description="Simple image to test anchorectl with Anchore Enterprise."

HEALTHCHECK --timeout=10s CMD /bin/true || exit 1

RUN set -ex && \
    echo "aws_access_key_id=01234567890123456789" > /aws_access && \
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > /ssh_key && \
    apk add --no-cache curl python3 && \
    python3 -m ensurepip && \
    pip3 install --index-url https://pypi.org/simple --no-cache-dir numpy protobuf==3.20 && \
    curl -sSfL  https://anchorectl-releases.anchore.io/anchorectl/install.sh  | sh -s -- -b /usr/local/bin && \
    echo "trigger package verification for wolfi-base" >> /etc/hosts 

# use date to force a unique build every time
RUN date > /image_build_timestamp
ENTRYPOINT /bin/false
