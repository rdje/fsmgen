# IAL0 AHB Direct Subordinate Output-Arbitration Behavior

Task-tree owner:
`IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.2`

Date: 2026-07-29

## Outcome

The hand-authored direct IAL0 seed
`fsm/ahb_lite_subordinate.fsm` now has assertion-clean output ownership. The
repair removes exactly four redundant zero writes:

- `access`: `HREADYOUT = 0`, `HRESP = 0`, and `HRDATA = 0`;
- `unsupported`: `HRESP = 0`.

No value or cycle timing changes. The existing IAL0 SystemVerilog emitter
supplies a zero-valued combinational baseline for outputs when no explicit
source owner is enabled. Conditional nonzero access and ERROR owners remain
unchanged, while the already-exclusive `unsupported` not-ready and zero-data
owners stay explicit.

The focused t1520 runtime no longer passes Verilator `--no-assert`. Generated
same-value and whole-output `onehot0` selector assertions remain enabled and
all four existing success/ERROR/SEQ/IDLE scenarios pass unchanged.

## Exact Source Ownership

| State | Ready ownership | Response ownership | Read-data ownership |
| --- | --- | --- | --- |
| `idle` | explicit ready | explicit OKAY | explicit zero |
| `access` | implicit zero while pending/error; explicit ready on mapped completion | implicit OKAY; explicit ERROR for bad size/address | implicit zero except explicit `reg_data_q` on mapped reads |
| `unsupported` | explicit not-ready | implicit OKAY while waiting; explicit first ERROR | explicit zero |
| `error_complete` | explicit ready | explicit second ERROR | explicit zero |

The repair does not remove any storage assignment, Q-named completion-edge
capture, state transition, wait-counter operation, read-data owner, successful
completion owner, or ERROR owner.

## Emitted SystemVerilog Shape

Generated output muxes retain these baselines:

```systemverilog
HRDATA    = 32'b00000000000000000000000000000000;
HREADYOUT = 1'b0;
HRESP     = 1'b0;
```

The emitted selector set no longer contains access-zero enables for HRDATA,
HREADYOUT, or HRESP, nor an unsupported-response-zero enable. It still
contains `unsupported_hrdata__32_h0_en` and
`unsupported_hreadyout_0_en`.

Verification-only emitted assertions still cover:

- same-value zero-data owners and HRDATA multi-value selection;
- same-value ready owners and HREADYOUT multi-value selection;
- same-value ERROR owners and HRESP multi-value selection; and
- the pre-existing state, phase-capture, wait-counter, and storage selector
  families.

## Assertion-Enabled Runtime Proof

`t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t` now checks
the exact source removals, retained explicit owners, emitted zero baselines,
emitted selector identities, Q-named completion capture, and four-state/no-
relaunch structure before compiling with every generated assertion enabled.

The exact runtime summaries remain:

```text
DIRECT_SUCCESS_ACTIVE_REPAIRED
  accepts/captures/completions = 2/2/2
  ready-low cycles = 4, ERROR cycles = 0
  storage = 0x11111111

DIRECT_ERROR_ACTIVE_REPAIRED
  accepts/captures/completions = 2/2/2
  ERROR cycles = 2, storage = 0xaaaaaaaa

DIRECT_SUCCESS_SEQ_REPAIRED
  accepts/captures/completions = 2/2/2
  ERROR cycles = 2, storage = 0x55555555

DIRECT_ERROR_IDLE_CANCEL
  accepts/captures/completions = 1/1/1
  ERROR cycles = 2, storage = 0x00000000
```

The SystemVerilog file
`t/data/ahb_direct_subordinate_pipelined_active_transfer_audit_tb.svt` remains
a handwritten regression harness. This slice does not claim generated
verification output or implement the separately proposed HIAL/VIAL
architecture.

## Preserved Boundaries

The repair preserves:

- word-only address-zero NONSEQ success, wait timing, live write data,
  registered read data, unsupported size/address/SEQ handling, and two-cycle
  ERROR;
- Q-named same-edge NONSEQ/SEQ capture, four states, ports, widths, reset,
  module/source identity, and support accounting;
- generic selector and rule/transaction priority behavior;
- generated IAL2 AHB subordinate, requester, interconnect, aggregate, report,
  semantic JSON, read-only MCP, and review-artifact behavior;
- all public `.ppif`/`.ahb` sources and support/capability counts;
- other protocols, backends, VHDL, proposed HIAL/VIAL, and proposed decision
  `0020`.

## Validation

Focused and preservation validation includes:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
prove -Iperl t/1211-isf-runtime-selector-conflict-instrumentation.t \
  t/1219-isf-rule-transaction-priority.t
prove -Iperl t/1519-ial2-ahb-pipelined-active-transfer-audit.t
prove -Iperl t/248-regression-corpus-accounting.t \
  t/297-capability-manifest.t
```

The direct check passes with four states, eleven signals, zero diagnostics,
module `ahb_lite_subordinate`, and matched strict support identity
`protocol.ahb_lite_subordinate`. Assertion-enabled t1520 passes two top-level
subtests; t1211/t1219 pass seven tests; generated-endpoint t1519 passes three
tests; and t248/t297 pass 6,911 accounting/capability tests.

Knowledge Map generation/check passes at 1,020 facts / 5,190 question keys;
mdBook and every doctrine check pass. The exact 72-file/16,111,896-byte book
output was removed with no residue. Repo-local test temporaries returned to
the observed six-entry pre-existing baseline, and those entries were left
untouched. Post-gate Stats-compatible capacity was 48.8%
(11.72/24.00 GiB), with kernel pressure level 1 (normal).

Heavy commands use repository-derived same-volume temporary storage and the
director-authorized `--host-max-pct 100 --process-max-rss-mb 4096` profile.
Capacity evidence uses the separate Stats-compatible Mach formula, and kernel
safety uses `kern.memorystatus_vm_pressure_level`; the guard percentage is not
capacity truth.

## Rollback

Rollback restores the four zero writes and t1520's `--no-assert` option as one
unit, then restores its structural expectations and current docs/fact. Generic
selector assertions must not be weakened.
