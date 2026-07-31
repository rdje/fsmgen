#!/usr/bin/env bash
# Local adapter for the neutral live-document size-containment checker.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
if [ "$#" -gt 0 ]; then
  if [ "$#" -ne 2 ] || [ "$1" != "--root" ] || [ ! -d "$2" ]; then
    printf 'Usage: %s [--root PROJECT_ROOT]\n' "$0" >&2
    exit 2
  fi
  PROJECT_ROOT="$(cd "$2" && pwd)"
fi

CORE="${SCRIPT_DIR}/../live-document-size/scripts/check_live_document_size.pl"
ARGS=(
  --root "${PROJECT_ROOT}"
  --registry doctrine/live_document_size/surfaces.jsonl
  --routes doctrine/readme_entrypoint/routed_destinations.jsonl
  --archives doctrine/live_document_size/archive_descriptors.jsonl
)

if git -C "${PROJECT_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "${PROJECT_ROOT}" ls-files -z -- '*.md' \
    | perl "${CORE}" "${ARGS[@]}" --coverage-stdin
else
  perl "${CORE}" "${ARGS[@]}"
fi
