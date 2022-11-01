# =============================================================================
# Core: Build
# =============================================================================
ARG GO_VERSION=1.18

FROM golang:${GO_VERSION}-buster AS build

WORKDIR /tmp/build

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o /tmp/build/app

# =============================================================================
# Core: Base
# =============================================================================
FROM debian:buster-slim AS base

# Application directory
ARG APP_HOME="/var/app"

# App user (worker) for manual UID and GID set
ARG UID="1000"
ARG GID="1000"

# https://github.com/grpc-ecosystem/grpc-health-probe
ARG GRPC_HEALTH_PROBE_VERSION="v0.4.11"

SHELL ["/bin/bash", "-c"]

# Install tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-$(dpkg --print-architecture) \
    && chmod +x /bin/grpc_health_probe

# Change working directory
WORKDIR ${APP_HOME}

# Create app user and set as app owner
RUN groupadd --gid ${GID} worker \
    && useradd  --system --uid ${UID} --gid ${GID} --create-home worker \
    && chown -R worker:worker ${APP_HOME} /home/worker

EXPOSE 50051

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
    CMD ["grpc_health_probe", "-addr", "localhost:50051"]

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["start.sh"]

# =============================================================================
# Environment: Development
# =============================================================================
FROM base AS development

ARG GO_VERSION

ENV GOBIN="/usr/local/go/bin"
ENV PATH="${GOBIN}:${PATH}"

# Install development utility dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    git \
    gnupg2 \
    make \
    pkg-config \
    python3-pip \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Install Golang
RUN curl -fsSL https://dl.google.com/go/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz \
    | tar -xz -C /usr/local

# Install pre-commit
RUN pip3 install --no-cache-dir --upgrade pip && pip install --no-cache-dir pre-commit

# Install golangci-lint
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \
    | sh -s -- -b ${GOBIN} v1.45.2

# Other go tools for CI (testing, linting, report conversion, etc.)
RUN go install golang.org/x/tools/cmd/goimports@latest
RUN go install gotest.tools/gotestsum@v1.7.0
RUN go install github.com/t-yuki/gocover-cobertura@master

# Install Air for hot reloading
RUN curl -sSfL https://raw.githubusercontent.com/cosmtrek/air/master/install.sh \
    | sh -s -- -b ${GOBIN}

COPY --from=build --chown=worker:worker --chmod=755 /tmp/build/app /usr/local/bin/app

# Copy script files implicitly
COPY --chown=worker:worker --chmod=755 \
    ./scripts/docker-entrypoint.sh ./scripts/start.sh \
    /usr/local/bin/

USER worker:worker

# =============================================================================
# Environment: Production
# =============================================================================
FROM base AS production

COPY --from=build --chown=worker:worker --chmod=755 /tmp/build/app /usr/local/bin/app

# Copy script files implicitly
COPY --chown=worker:worker --chmod=755 \
    ./scripts/docker-entrypoint.sh ./scripts/start.sh \
    /usr/local/bin/

USER worker:worker
