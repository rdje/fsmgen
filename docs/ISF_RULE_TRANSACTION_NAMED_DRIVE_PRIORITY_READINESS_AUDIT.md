# ISF Rule/Transaction Named-Drive Priority Readiness Audit

Task-tree owner:
`ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1`

Date: `2026-07-30`

## Outcome

The gap is reproduced protocol-neutrally and a bounded repair is ready for
contract selection. Audit `.1` selects proposed no-behavior contract `.2` for
caller-aware, target-local priority handling when a named drive has exactly one
local transaction caller. Ambiguous shared/multi-caller or generated-child
drive ownership must fail closed until a later exact owner preserves call-site
identity; whole-drive suppression is rejected.

No parser, scheduler, selector, generator, public source, support-accounting,
report, semantic/MCP API, generated HDL, runtime, backend, protocol, HIAL/VIAL,
VHDL, scale, decision-`0020`, or transaction behavior changes in this audit.

## Protocol-Neutral Reproducer

Tracked fixture
`t/data/isf_rule_transaction_named_drive_priority_probe.isf` contains one
transaction `main`, one named drive `drive_zero`, one concurrent rule
`force_out`, and actor priority `force_out over main`. `main` calls
`drive_zero`, which selects `out=0`; the rule selects `out=1`.

Focused t1542 proves the public and internal current boundary:

- strict `--check --json` succeeds with zero diagnostics;
- schedule JSON has no `priority_resolutions[]` entry and reports exactly one
  warning `isf_unproven_rule_drive_overlap` with `proof_status=not_doable`;
- the transaction-owned `drive_call_start` assignment targets
  `drive_zero_start`, but the output assignment changes to owner kind `drive`,
  source kind `drive_body`, and sees only the aggregate start guard;
- generated HDL enables `drive_zero_out_0_en` from `drive_zero_start` without
  an inverse `force_out` condition and retains the authoritative
  `selector multi-value conflict: out` assertion;
- normalized semantics expose one `out` drive family with blocks
  `-drive_zero` and `-force_out`, values zero and one; and
- assertion-enabled Verilator runtime drives the rule and named drive together
  and fails exactly on `selector multi-value conflict: out`.

The adjacent tracked control
`t/data/isf_rule_transaction_direct_priority_control.isf` replaces the named
drive call with direct transaction `(update out 0)`. It reports one
`force_out`-over-`main` resolution, records `priority_suppressed_by`, guards the
transaction assignment with `(! override_req)`, and passes assertion-enabled
runtime with `out=1`. The contrast proves the issue is not generic
rule/transaction priority.

## Lowering Boundary

Current lowering retains caller identity at the call site:

```text
main_drive_1
  drive_zero_start = 1
  owner=main, owner_kind=transaction, source_kind=drive_call_start
```

It then creates one shared drive body:

```text
drive_zero
  out <- 0 when drive_zero_start
  owner=drive_zero, owner_kind=drive, source_kind=drive_body
```

`_apply_rule_transaction_priority_resolution` collects only rule and
transaction data assignments. A drive-call start belongs to the request domain,
not the output data domain; the drive-body output belongs to owner kind `drive`,
not transaction. `_build_conflict_issues` consequently retains the
rule/drive warning, and backend output-family analysis correctly retains both
different-value selectors plus its assertion.

## Why Whole-Drive Masking Is Rejected

A named drive can write several outputs. Actor-level priority currently masks
only conflicting direct assignments; unrelated assignments in the lower actor
still execute. Masking `drive_zero_start` would instead suppress every output
in the named drive. A disposable single-caller/multi-output candidate proves
the required target-local shape: with the rule conflicting only on `out`, the
candidate completes assertion-clean with `out=1` and unrelated `side=1`.

A named drive can also be called by more than one transaction. A
protocol-neutral two-caller probe produces transaction-owned start records for
both `main` and `auxiliary`, but both feed one aggregate `drive_zero_start` seen
by the shared drive body. Priority `force_out over main` says nothing about
`auxiliary`; adding `!force_out` to the whole drive body would wrongly suppress
an auxiliary call. Current public issue provenance names only `drive_zero`, so
the ambiguity cannot be resolved safely after caller fan-in.

## Disposable Feasibility Candidate

A repository-local same-volume patched copy of `LoweringIR.pm` tested the
smallest unique-caller route without changing tracked product code. It:

1. retained the transaction caller set already found by
   `_collect_named_drive_call_names`;
2. annotated local drive-body assignments with that set;
3. treated a drive body with exactly one caller as that transaction only for
   target-level priority comparison; and
4. applied the existing priority suppressor to the conflicting drive-body
   assignment, not to the aggregate drive start.

The candidate generated `drive_start && !override_req` only for conflicting
`out`. Assertion-enabled Verilator passed the one-output case with `out=1` and
the multi-output case with `out=1 side=1`. The control continued to pass. The
candidate and every generated artifact/object directory were then removed;
tracked lowering behavior remains unchanged.

## Selected `.2` Contract Boundary

Contract `.2` must freeze these semantics before implementation:

- Scope the first repair to a local named drive with exactly one invoking
  transaction. Preserve the drive as a separate provenance owner while adding
  explicit invoking-transaction metadata for priority analysis and review.
- Apply actor-level rule/transaction priority per conflicting target and in
  both directions. A higher rule masks only the lower named-drive assignment;
  a higher transaction-invoked drive masks only the lower rule assignment.
  The transaction and non-conflicting assignments continue normally.
- Preserve the existing direct rule/transaction path byte-for-byte unless
  shared helper reuse is proven equivalent.
- Fail closed before HDL generation when a prioritized rule/drive overlap has
  zero, multiple, generated-child, or otherwise ambiguous transaction callers.
  Freeze a stable diagnostic that names the rule, drive, candidate callers,
  target, values, and why ownership is ambiguous.
- Keep no-priority different-value unique-caller overlaps fail closed, keep
  priority cycles and mixed timing fail closed, and preserve current
  same-value fan-in/assertion behavior.
- Keep selector assertions. Resolved unique-caller cases must become
  structurally exclusive and pass with assertions enabled; assertions are not
  removed, disabled, or relaxed.
- Freeze schedule resolution, compile-issue, assignment-provenance, normalized
  semantic, SystemVerilog/Verilog/VHDL qualification, diagnostic, focused test,
  broader preservation, resource, same-volume cleanup, and rollback details.

The implementation owner remains `.3` and is not active until `.2` commits a
complete contract.

## Validation And Cleanup

Focused t1542 passes three top-level subtests with 33 internal assertions: the
direct assignment control is assertion-clean, the named-drive case fails on
the intended generated assertion, and the multi-caller provenance boundary is
exact. The disposable feasibility matrix additionally passes one-output and
multi-output target-local candidate runtimes. Broader ISF priority/conflict,
preservation passes t1209+t1211+t1212+t1219+t1220+t1222+t1242+t1255+t1542 as
9 files/28 top-level tests; documentation gates pass 3 files/22 tests.
Knowledge Map generation/check passes at 1,053 facts/5,409 question keys, and
all six doctrine gates pass. The mdBook builds to exactly 72 files/16,431,907
bytes and the exact render is removed.

All disposable candidate code, sources, generated FSM/SystemVerilog, Verilator
objects, and manual test workspaces were removed. The tracked t1542 workspace
uses `FSM::ProjectDataLocality` and cleans `.artifacts/tmp/tests`.
Final canonical Stats-compatible capacity is
15,157,592,064/25,769,803,776 bytes = 14.117/24.000 GiB = 58.82%, with separate
kernel pressure level 1 and `memory_pressure` 70% free.

## Rollback

Rollback removes t1542, its four tracked protocol-neutral source/testbench
fixtures, this record, and its fact, then restores `.1` active. It does not
alter current lowering or hide the original AHB evidence. If superseded, the
replacement must retain both the passing direct control and failing named-drive
runtime evidence.
