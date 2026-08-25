# Decision 0085: Darwin runtime integration is explicit and sampling stays repository-local

- **Status:** Accepted
- **Date:** 2026-08-25
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.2`
- **Refines:** [0084](0084-macos-premain-stalls-retain-guarded-qualification-not-backend-workarounds.md)

## Context

The pre-push full regression and a separate unchanged `t/1558` run each failed
one first generated executable at the fixed 30-second wall. The failing
scenario moved from phase rollover to the baseline API, while immediate
byte-identical repeats and all later routes passed. A fresh one-primary guarded
observation failed with zero output and sampled 895/895 main-thread frames at
`_dyld_start`, before a binary-image map existed. Its byte-identical
different-path control passed but needed 10.823397 seconds to first output;
fresh minimal C++ and platform controls also passed. This is direct host-loader
delay evidence, not deterministic VIAL scenario semantics.

The guarded watcher also exposed a separate locality defect: `/usr/bin/sample`
defaults its report to `/tmp` when no `-file` argument is supplied. The exact
992-byte residue was copied to the repository volume, hash/size verified,
consumed, deleted, and censused absent. Project data may not depend on that
default.

## Decision

1. On Darwin, `t/1558-vial-verilator-run-integration.t` is explicit
   qualification selected by `FSMGEN_VIAL_DARWIN_RUNTIME_INTEGRATION=1`.
   Standard regression emits an explicit TAP skip before tool discovery or
   generated execution. Non-Darwin behavior remains unchanged.
2. An opted-in `t/1558` run remains ordinary truth: there is no internal or
   external retry, a first timeout fails the test, and later controls cannot
   promote it.
3. The one-primary Darwin diagnostic remains
   `t/1665-vial-macos-premain-qualification.t`. Its stack sampler must pass
   `-file` with a prevalidated repository-derived sidecar, read that exact
   regular file, and retain no `/tmp` report.
4. The bounded evidence projection retains both passing controls and the fresh
   failed primary. Default `t/1666` validates producer identity, the Darwin
   opt-in boundary, failed-primary truth, sample identity, control outcomes,
   and repository-local sampling without executing a host probe.
5. The fixed 30-second wall, process-group containment, capture ceilings,
   lifecycle, Runner, signing/security state, cleanup, qualified support, and
   public API remain unchanged.

## Rationale

A standard regression must be deterministic and must not reinterpret an
operating-system loader stall as a compiler semantic result. Explicit Darwin
qualification preserves the executable evidence and its failures, while the
default suite verifies the durable contract without launching a host-sensitive
primary. Keeping non-Darwin integration unchanged avoids weakening portable
runtime coverage where this Darwin-specific condition does not apply.

Passing `sample -file` is the tool-supported way to preserve the same
read-only diagnostic while honoring repository-volume ownership. It removes an
off-volume side effect rather than hiding or deleting ambiguous shared data.

## Alternatives rejected

- Retry or widen the deadline: conceals the first failed primary.
- Treat a byte-identical control as success for the primary: fabricates a pass.
- Disable security, rewrite signatures/xattrs, or kill unrelated work: unsafe
  and unsupported by causal evidence.
- Remove runtime integration everywhere: unnecessarily weakens non-Darwin
  coverage.
- Keep unconditional Darwin execution in standard CI: retains a known
  host-conditioned nondeterministic gate.
- Let `sample` use `/tmp` and clean later: violates locality during execution
  and can strand residue after interruption.

## Claim verification

- **Re-derivation:** the explicit guarded watcher reconstructs the canonical
  route and records primary/control/sample/cleanup evidence; opted-in `t/1558`
  runs the complete public API/CLI integration.
- **Falsification:** the moving scenario failure, byte-identical different-path
  control, fresh minimal C++, platform true, passing historical observations,
  and default static source/evidence checks challenge semantic, binary, path,
  supervisor, and hidden-pass hypotheses.
- **Durability:** this decision, the bounded qualification projection,
  t/1558/t1665/t1666, mdBook, Knowledge Map, owning task tree, doctrine gates,
  and Git retain the outcome after raw records are consumed and removed.
