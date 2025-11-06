#!/usr/bin/env bash

# AI-assisted

set -xue -o pipefail

SKK_RULESET="https://ruleset.skk.moe/List/domainset/reject.conf"

for var in BLOCKLIST_DNSCRYPT BLOCKLIST_UNBOUND; do
    # AI: I'd not know ${!var} syntax
    if [[ -z "${!var:-}" ]]; then
        echo "$var not set or empty" >&2
        exit 1
    fi
done

DOWNLOADED_RULE="$(mktemp)"

# shellcheck disable=SC2064
trap "rm -f $DOWNLOADED_RULE" EXIT

curl -vL "$SKK_RULESET" -o "$DOWNLOADED_RULE"

echo "Transform the ruleset to unbound format"

# 1. remove "#" comment lines
# 2. remove leading "."
# 3. remove empty lines
# 4. transform the remaining into local-zone syntax
# 5. zstd it
sed \
    -e '/^#/d' \
    -e 's/^\.//' \
    -e '/^\s*$/d' \
    -e 's/.*/local-zone: "&." always_nxdomain/' \
    "$DOWNLOADED_RULE" \
| zstd -T0 -19 -o "$BLOCKLIST_UNBOUND"

echo "Transform the ruleset to dnscrypt format"

# dnscrypt just accepts the syntax :) no processing needed

zstd -T0 -19 "$DOWNLOADED_RULE" -o "$BLOCKLIST_DNSCRYPT"
