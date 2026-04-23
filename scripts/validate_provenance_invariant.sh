#!/usr/bin/env bash
# Enforces AGENTS.md §1.1: no Solution may be returned with an empty
# provenance_chain. This hook catches the obvious failure mode — a
# literal Solution(..., [], ...) or Solution(..., ProvenanceNode[], ...)
# constructor call — that would sneak past the runtime check.
#
# The runtime constructor in strategic-jl/src/core/types.jl already
# throws on empty chains. This hook fails the commit earlier and with
# a clearer pointer to the contract.
#
# Usage: invoked by pre-commit via .pre-commit-config.yaml.

set -euo pipefail

status=0

for file in "$@"; do
  # Match: Solution(...empty_vector_literal...)
  # Heuristic patterns for empty provenance chain arguments:
  #   Solution(..., [], ...)
  #   Solution(..., ProvenanceNode[], ...)
  if grep -nE 'Solution\([^)]*(\[\]|ProvenanceNode\[\])[^)]*\)' "$file" >/dev/null 2>&1; then
    echo "provenance invariant violation: ${file}"
    grep -nE 'Solution\([^)]*(\[\]|ProvenanceNode\[\])[^)]*\)' "$file" | sed 's/^/  /'
    echo "  Solution requires a non-empty provenance_chain."
    echo "  see AGENTS.md §1.1 and strategic-jl/src/core/types.jl"
    status=1
  fi
done

exit $status
