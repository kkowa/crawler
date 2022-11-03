# =============================================================================
# Core: Build
# =============================================================================
ARG GO_VERSION=1.19

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
ARG GRPC_HEALTH_PROBE_VERSION="v0.4.14"

SHELL ["/bin/bash", "-c"]

# Install tools
RUN apt update && apt install --no-install-recommends -y \
    ca-certificates \
    curl \
    && apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /bin/grpc_health_probe "https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-$(dpkg --print-architecture)" \
    && chmod +x /bin/grpc_health_probe

# Change working directory
WORKDIR "${APP_HOME}"

# Create app user and set as app owner
RUN groupadd --gid "${GID}" worker \
    && useradd  --system --uid "${UID}" --gid "${GID}" --create-home worker \
    && chown -R worker:worker "${APP_HOME}" /home/worker

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

ARG PROTOC_VERSION="3.15.8"
ARG GOLANGCI_LINT_VERSION="v1.50.1"

ENV GOBIN="/usr/local/go/bin"
ENV PATH="${GOBIN}:${PATH}"

# Install development utility dependencies
RUN apt update && apt install --no-install-recommends -y \
    build-essential \
    git \
    gnupg2 \
    make \
    pkg-config \
    python3-pip \
    unzip \
    && apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Install Golang
RUN curl -fsSL "https://dl.google.com/go/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz" \
    | tar -xz -C /usr/local

# Install pre-commit
RUN pip3 install --no-cache-dir --upgrade pip && pip install --no-cache-dir pre-commit

# Download protoc
RUN curl -fsSL -O "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-$(uname -s)-$(uname -m).zip" \
    && unzip "protoc-${PROTOC_VERSION}-$(uname -s)-$(uname -m).zip" bin/protoc -d /usr/local/

# Install golangci-lint
RUN curl -fsSL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "${GOBIN}" "${GOLANGCI_LINT_VERSION}"

# Install Air for hot reloading
RUN curl -fsSL https://raw.githubusercontent.com/cosmtrek/air/master/install.sh | sh -s -- -b "${GOBIN}"

# Other go tools for CI (testing, linting, report conversion, etc.)
RUN go install gotest.tools/gotestsum@latest \
    && go install github.com/t-yuki/gocover-cobertura@latest

COPY --from=build --chown=worker:worker --chmod=755 /tmp/build/app /usr/local/bin/app

# Copy script files to executable path
COPY --chown=worker:worker --chmod=755 ./scripts/* /usr/local/bin/

USER worker:worker

# =============================================================================
# Environment: Production
# =============================================================================
FROM base AS production

COPY --from=build --chown=worker:worker --chmod=755 /tmp/build/app /usr/local/bin/app

# Copy script files to executable path
COPY --chown=worker:worker --chmod=755 ./scripts/* /usr/local/bin/

USER worker:worker
