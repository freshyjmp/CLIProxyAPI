FROM golang:1.26.5-bookworm AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends build-essential git && rm -rf /var/lib/apt/lists/*

COPY go.mod go.sum ./

RUN go mod download

COPY . .

ARG VERSION=dev
ARG COMMIT=none
ARG BUILD_DATE=unknown

RUN CGO_ENABLED=1 GOOS=linux go build -buildvcs=false -ldflags="-s -w -X 'main.Version=${VERSION}' -X 'main.Commit=${COMMIT}' -X 'main.BuildDate=${BUILD_DATE}'" -o ./CLIProxyAPI ./cmd/server/

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 10001 cliproxy \
    && useradd --system --uid 10001 --gid cliproxy --home-dir /var/lib/cliproxy cliproxy \
    && install -d -o cliproxy -g cliproxy -m 0700 /var/lib/cliproxy \
    && install -d -o cliproxy -g cliproxy -m 0700 /var/lib/cliproxy/auths

COPY --from=builder /app/CLIProxyAPI /usr/local/bin/cli-proxy-api
COPY --chown=cliproxy:cliproxy docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

USER cliproxy
WORKDIR /var/lib/cliproxy

EXPOSE 8317

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl --fail --silent --show-error http://127.0.0.1:8317/healthz >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
