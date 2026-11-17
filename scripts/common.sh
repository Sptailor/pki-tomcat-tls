#!/usr/bin/env bash
# Shared helpers. Source this from the other scripts.
set -euo pipefail

# Always run from the repository root so the relative paths in etc/*.conf work.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OPENSSL="${OPENSSL:-openssl}"

# Passphrases. If an env var is set it is used non-interactively; otherwise
# OpenSSL prompts on the terminal, exactly like the tutorial.
pass_args() {   # usage: pass_args <in|out> <ENV_VAR_NAME>
  local dir="$1" var="$2"
  if [[ -n "${!var:-}" ]]; then
    echo "-pass${dir} env:${var}"
  fi
}

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
