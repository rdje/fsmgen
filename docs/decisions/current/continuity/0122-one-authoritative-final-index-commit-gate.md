---
id: doctrine-enforcement-one-authoritative-commit-gate
title: One authoritative final-index commit gate
answers: ["must the complete doctrine suite run both before and inside every commit?", "can a passed preflight replace final commit validation?"]
date: 2026-10-27
status: current
reverify: scripts/check_doctrines.sh --list
---
# 0122 — One authoritative final-index commit gate

- Type: convention/governance
- Status: accepted
- Owner: `COMMIT-GATE-PERFORMANCE.1`

## Context

The director requests and authorizes faster documentation/commit gates while
retaining high quality. The previous workflow requires a full manual doctrine
run and another full run in the normal pre-commit hook. The registered README
check also invokes the complete live-document suite already registered directly.
Repeated validation is execution overhead, not an independent evidence leg.
The current source slice was committed clean before this workflow task starts.

## Decision

The mandatory pre-commit hook is the authoritative full local gate after it
regenerates and stages derived indexes. Every successful commit must pass every
registered doctrine against that final state, including staged task acceptance.
An identical full manual preflight is optional diagnostic feedback. It cannot
replace, cache, suppress or bypass the final hook. Hooks remain enabled and
normal `git --no-pager commit -F git_message_brief.txt` semantics remain required.

Optional per-check timings describe observations, not validation authority.
Local fail-fast may stop after a failed check and must disclose unrun checks;
it cannot print complete success. Successful runs still execute the registry.
Default CI mode keeps complete failure diagnostics and independent enforcement.

Equivalent deterministic read-only verifier executions may be shared only
within one invocation under their actual root/command contract. Every logical
proof obligation and failure remains required. Cross-run pass caching is not
part of this selection. Subsequent implementation and qualification are owned
by COMMIT-GATE-PERFORMANCE; do not imply deduplication is already implemented.

## Consequences

This supersedes the duplicate full-run cadence in COMMIT.md, not task ownership,
per-slice commits, documentation sync, claim evidence, same-volume data, or
full-CI/exact-SHA publication requirements. The transition commit itself retains
the prior double-check procedure before the new cadence is used.

The director explicitly selects this workflow activity ahead of the preserved
required-delivery frontier. Complete it, then resume
ISF-REDUCTION-DELIVERY.3.3.1.2.2.2 under decision 0121. No required feature,
independent defect, or deferred verification is abandoned or declared complete.
