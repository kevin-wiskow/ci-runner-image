# Self-hosted GitHub Actions runner image for Actions Runner Controller (ARC).
# The upstream runner image plus what the jobs it serves expect from a host:
# Go in the tool cache (setup-go finds it instead of downloading), build-essential,
# python3 with venv, the Compose plugin and the America/Chicago time zone.
# No secrets. Every download is pinned by version and SHA-256, the base by digest.

# actions/runner 2.338.2 (multi-arch index digest, checked 2026-11-13)
FROM ghcr.io/actions/actions-runner:2.338.2@sha256:6d0b2d80d80f143f77dcb676e50920100bbb547e39e883454d57f45ab8c31300

LABEL org.opencontainers.image.source="https://github.com/kevin-wiskow/ci-runner-image" \
      org.opencontainers.image.description="ARC runner image with Go, build-essential, python3-venv, Compose and America/Chicago"

ARG GO_VERSION=1.27.3
ARG GO_SHA256=65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40
ARG COMPOSE_VERSION=5.6.1
ARG COMPOSE_SHA256=47737f4236e6d3ccea7291995203f8f018058783b4c3a9469119811a0b5db8c0

USER root

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends build-essential python3 python3-venv ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

# The jobs' tests render local timestamps and expect the hosts' zone.
ENV TZ=America/Chicago

# Outside _work: ARC mounts an emptyDir over _work, which would hide a cache placed there.
ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache

# setup-go looks for $RUNNER_TOOL_CACHE/go/<version>/x64 plus the x64.complete marker.
RUN curl -fsSL -o /tmp/go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
    && echo "${GO_SHA256}  /tmp/go.tgz" | sha256sum -c - \
    && mkdir -p "${RUNNER_TOOL_CACHE}/go/${GO_VERSION}/x64" \
    && tar -xzf /tmp/go.tgz -C "${RUNNER_TOOL_CACHE}/go/${GO_VERSION}/x64" --strip-components=1 \
    && touch "${RUNNER_TOOL_CACHE}/go/${GO_VERSION}/x64.complete" \
    && rm /tmp/go.tgz \
    && chown -R runner:docker "${RUNNER_TOOL_CACHE}"

RUN curl -fsSL -o /usr/local/lib/docker/cli-plugins/docker-compose \
       "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
    && echo "${COMPOSE_SHA256}  /usr/local/lib/docker/cli-plugins/docker-compose" | sha256sum -c - \
    && chmod 755 /usr/local/lib/docker/cli-plugins/docker-compose

USER runner
