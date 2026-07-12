#!/bin/sh
set -eu

config_path="${CLI_PROXY_CONFIG_PATH:-/var/lib/cliproxy/config.yaml}"

if [ -n "${CLI_PROXY_CONFIG_B64:-}" ]; then
  umask 077
  mkdir -p "$(dirname "$config_path")"
  printf '%s' "$CLI_PROXY_CONFIG_B64" | base64 -d > "$config_path"
fi

if [ ! -s "$config_path" ]; then
  echo "CLIProxyAPI configuration is missing: set CLI_PROXY_CONFIG_B64 or mount $config_path" >&2
  exit 1
fi

exec /usr/local/bin/cli-proxy-api --config "$config_path" --local-model "$@"
