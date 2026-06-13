# AXI IAL2 Manager RLAST Report Alignment First Slice

Status: shipped.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.55`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the report/static-text repair selected by
[docs/AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md](AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md).

## What Changed

The generated structured report for
`ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`
already reported generated burst-last behavior after `.53`:

```text
response_demux.read.generated_behavior: true
transaction_completion_source: generated_demux_last_beat
transaction_completion_semantics: matched_rid_and_last_signal
generated_completion_signals:
  - axi0_r0_complete
  - axi0_r1_complete
generated_rules:
  - axi0_r0_response_demux
  - axi0_r1_response_demux
generated_assertions:
  - axi0_read_response_demux_active_match
  - axi0_r0_r1_read_response_demux_unique_match
```

This slice aligns the prose fields that summarize the same report. The
`enforced_static_rules` entry now says:

```text
response_demux.read response_scope burst_last requires one-bit last_signal
metadata and generates matched-RID-and-RLAST last-beat completion behavior
for explicit opt-in contracts
```

The `axi_id_ordering_and_response_matching` unsupported-residue detail now
lists generated burst-last `RLAST` response-demux completion as supported, and
keeps only the broader unimplemented work as residue:

```text
broader burst payload assembly
ARLEN or beat-count validation
per-beat outputs
read-data interleaving/reassembly
per-ID same-ID response queues
different-ID interleaving
dynamic user-ID arbitration
```

The report no longer describes burst-last `RLAST` as report-only and no longer
says generated burst/last-beat tracking remains outside the capacity/status
shell.

## Behavior Boundary

No public syntax changed. No generated `.isf`, `.fsm`, or HDL behavior
changed. The shipped generated behavior remains:

- raw read response beat input;
- generated `RID` input;
- generated one-bit `RLAST` input;
- generated per-transaction completion pulse outputs;
- one response-demux rule per read auto-ID transaction, gated by raw response
  beat, active transaction, matching `RID`, and asserted `RLAST`;
- response-demux active-match and unique-match assertions;
- auto-ID lifecycle release from generated last-beat completion pulses.

## Focused Checks

The focused generator and PPIF/CLI tests now assert both sides of the report
contract:

- corrected `enforced_static_rules` prose is present;
- stale report-only `RLAST` static-rule prose is absent;
- corrected unsupported-residue prose says generated burst-last `RLAST`
  response-demux completion is supported;
- stale report-only and stale burst-tracking unsupported-residue prose are
  absent.

The live report can be inspected with:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
```

## Explicit Residue

Multi-beat read-data reassembly, burst payload assembly, `ARLEN` or
beat-count validation, missing/extra beat validation, per-beat outputs,
per-ID response queues, authored concrete-ID same-ID ordering, queued/blocking
policy, profile aliases, full AXI manager syntax, direct backend lowering,
and VHDL backend/reroute behavior remain future exact-owner work.

## Next Owner

`IAL2-FEATURE-COMPLETENESS-FRONTIER.56` owns the next selector. It must choose
the exact public contract/readiness step for combining generated `RLAST`
completion with read-data behavior, or select a smaller prerequisite if the
current single-beat `read-data` contract and burst-last response-demux
boundary are still not sufficient.
