#!/usr/bin/env bash
#
# check_docs_relative_paths.sh - doctrine check for repo-root-relative live-doc
# paths. The underlying audit is a Perl regression test because it already owns
# the exact path policy and violation diagnostics.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
