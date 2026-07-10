#!/usr/bin/env bash
# Ed25519 detached signature for the content-pack manifest (ADR-0010).
# The private key belongs to the owner: never in the repo, never in CI.
#
#   tool/release/sign_manifest.sh keygen  <keydir>
#   tool/release/sign_manifest.sh sign    <keydir>/miras-pack.pem <manifest.json>
#   tool/release/sign_manifest.sh verify  <keydir>/miras-pack.pub <manifest.json>
set -euo pipefail

cmd="${1:-}"
case "$cmd" in
  keygen)
    dir="${2:?usage: keygen <keydir>}"
    mkdir -p "$dir"
    openssl genpkey -algorithm ed25519 -out "$dir/miras-pack.pem"
    openssl pkey -in "$dir/miras-pack.pem" -pubout -out "$dir/miras-pack.pub"
    chmod 600 "$dir/miras-pack.pem"
    echo "keypair written to $dir — back up miras-pack.pem (password manager);"
    echo "miras-pack.pub ships in the app when the downloader lands."
    ;;
  sign)
    key="${2:?usage: sign <private.pem> <manifest.json>}"
    manifest="${3:?usage: sign <private.pem> <manifest.json>}"
    openssl pkeyutl -sign -inkey "$key" -rawin -in "$manifest" \
      -out "$manifest.sig"
    echo "wrote $manifest.sig"
    ;;
  verify)
    pub="${2:?usage: verify <public.pub> <manifest.json>}"
    manifest="${3:?usage: verify <public.pub> <manifest.json>}"
    openssl pkeyutl -verify -pubin -inkey "$pub" -rawin -in "$manifest" \
      -sigfile "$manifest.sig"
    ;;
  *)
    echo "usage: $0 keygen|sign|verify ..." >&2
    exit 64
    ;;
esac
