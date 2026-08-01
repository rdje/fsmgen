#!/usr/bin/env bash
# Validate fact cards, bounded projections, freshness, and query parity.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || pwd)"

# shellcheck source=../../scripts/project_data_locality_env.sh
source "$ROOT/scripts/project_data_locality_env.sh"
[ -f "$ROOT/.knowledge_map.conf" ] && source "$ROOT/.knowledge_map.conf"
[ -f "$SCRIPT_DIR/knowledge_map.conf" ] && source "$SCRIPT_DIR/knowledge_map.conf"
: "${KM_SCAN_DIRS:=docs/knowledge docs/decisions}"
: "${KM_OUTPUT:=KNOWLEDGE_MAP.md}"
: "${KM_SHARD_DIR:=knowledge-map/generated}"
: "${KM_QUERY_CACHE_DIR:=.artifacts/knowledge-map/query}"
: "${KM_TITLE:=Knowledge Map}"

export KM_ROOT="$ROOT" KM_SCAN_DIRS KM_OUTPUT KM_SHARD_DIR KM_QUERY_CACHE_DIR KM_TITLE
exec perl "$SCRIPT_DIR/knowledge_map.pl" check
