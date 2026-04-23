#!/usr/bin/env bash
# Validates JGDL JSON files against jgdl/schema/v1.0.0.schema.json using
# ajv-cli when available. Skipped with a warning when ajv isn't installed
# so local hooks don't block contributors who haven't set it up — CI
# runs this check unconditionally.
#
# Install locally:
#   npm install -g ajv-cli ajv-formats
#
# Usage: invoked by pre-commit via .pre-commit-config.yaml.

set -euo pipefail

SCHEMA="jgdl/schema/v1.0.0.schema.json"

if ! command -v ajv >/dev/null 2>&1; then
  echo "note: ajv-cli not installed; skipping local JGDL schema check."
  echo "      install with: npm install -g ajv-cli ajv-formats"
  echo "      (CI runs the full schema check regardless)"
  exit 0
fi

status=0

for file in "$@"; do
  # Compliance test files wrap the JGDL under a `jgdl` key; examples are
  # top-level JGDL documents. Detect and route accordingly.
  if jq -e '.jgdl' "$file" >/dev/null 2>&1; then
    # Extract the embedded jgdl block for validation.
    tmp=$(mktemp)
    jq '.jgdl' "$file" > "$tmp"
    if ! ajv validate -s "$SCHEMA" -d "$tmp" --spec=draft2020 --strict=false 2>/dev/null; then
      echo "schema violation in embedded jgdl of: $file"
      status=1
    fi
    rm -f "$tmp"
  else
    if ! ajv validate -s "$SCHEMA" -d "$file" --spec=draft2020 --strict=false 2>/dev/null; then
      echo "schema violation: $file"
      status=1
    fi
  fi
done

exit $status
