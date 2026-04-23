#!/usr/bin/env bash
# Enforces docs/trait-composition-contract.md §5.
#
# For each staged Julia chapter file, check that every struct declared
# as `<: GameTrait` has a matching `register_trait!` call in the same
# file. Fails fast with a clear pointer to the contract on violation.
#
# Usage: invoked by pre-commit via .pre-commit-config.yaml.

set -euo pipefail

status=0

for file in "$@"; do
  # Extract trait struct names (handles both `struct X <: GameTrait` and
  # `mutable struct X <: GameTrait`).
  traits=$(grep -E '^(mutable +)?struct +[A-Za-z_][A-Za-z0-9_]* +<: +GameTrait' "$file" \
           | sed -E 's/^(mutable +)?struct +([A-Za-z_][A-Za-z0-9_]*) +<: +GameTrait.*/\2/' \
           || true)

  for trait in $traits; do
    if ! grep -qE "register_trait!\( *${trait} *," "$file"; then
      echo "contract violation: ${file}"
      echo "  trait '${trait}' defined without matching register_trait!(${trait}, Set([...]))"
      echo "  see docs/trait-composition-contract.md §5"
      status=1
    fi
  done
done

exit $status
