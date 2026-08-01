#!/usr/bin/env bash
# Generate the bounded deterministic Knowledge Map root and topic shards.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || pwd)"

[ -f "$ROOT/.knowledge_map.conf" ] && source "$ROOT/.knowledge_map.conf"
[ -f "$SCRIPT_DIR/knowledge_map.conf" ] && source "$SCRIPT_DIR/knowledge_map.conf"
: "${KM_SCAN_DIRS:=docs/knowledge docs/decisions}"
: "${KM_OUTPUT:=KNOWLEDGE_MAP.md}"
: "${KM_SHARD_DIR:=knowledge-map/generated}"
: "${KM_QUERY_CACHE_DIR:=.artifacts/knowledge-map/query}"
: "${KM_TITLE:=Knowledge Map}"

case "${1:-}" in
  --print-map-path) printf '%s\n' "$KM_OUTPUT"; exit 0 ;;
  --print-shard-dir) printf '%s\n' "$KM_SHARD_DIR"; exit 0 ;;
  --print-generated-paths)
    printf '%s\n%s\n' "$KM_OUTPUT" "$KM_SHARD_DIR"
    exit 0
    ;;
  '') ;;
  *) printf 'Usage: %s [--print-map-path|--print-shard-dir|--print-generated-paths]\n' "$0" >&2; exit 2 ;;
esac

export KM_ROOT="$ROOT" KM_SCAN_DIRS KM_OUTPUT KM_SHARD_DIR KM_QUERY_CACHE_DIR KM_TITLE
exec perl "$SCRIPT_DIR/knowledge_map.pl" generate
