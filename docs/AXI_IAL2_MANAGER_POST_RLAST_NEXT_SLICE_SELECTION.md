# AXI IAL2 Manager Post-RLAST Next Slice Selection

Status: selection complete; no parser/generator/HDL behavior changes in this
slice.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.54`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This selector follows
[docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md).

## Evidence Read

The selector re-read the shipped write response-demux, read response-demux,
single-beat read-data capture, and burst-last `RLAST` completion notes, plus
the live schedule reports for these checked-in samples:

```text
ppif/axi_manager_capacity_status_response_demux.ppif
ppif/axi_manager_capacity_status_read_response_demux.ppif
ppif/axi_manager_capacity_status_read_data.ppif
ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
```

The burst-last sample now reports generated behavior in its structured
`response_demux.read` block:

```text
generated_behavior: true
response_scope: burst_last
response_event_role: raw_accepted_read_response_beat
last_signal: axi0_rlast
transaction_completion_source: generated_demux_last_beat
transaction_completion_semantics: matched_rid_and_last_signal
generated_rules:
  - axi0_r0_response_demux
  - axi0_r1_response_demux
generated_completion_signals:
  - axi0_r0_complete
  - axi0_r1_complete
generated_assertions:
  - axi0_read_response_demux_active_match
  - axi0_r0_r1_read_response_demux_unique_match
residue:
  - read_data_interleaving
  - bursts
```

`auto_id_lifecycle.residue` is empty for the burst-last sample, and the read
same-ID family reports `response_demux_covered: true`.

The read-data sample separately reports generated single-beat `RDATA`/`RRESP`
capture:

```text
read_data.generated_behavior: true
read_data.read.capture_scope: single_beat
read_data.read.completion_source: response_demux
read_data.read.interleaving_policy: single_beat_by_rid
read_data.residue:
  - rlast_completion
  - bursts
  - multi_beat_read_data_reassembly
```

The current public contract still rejects `read-data` when paired with
`response_demux.read.response_scope burst_last`. The code and focused tests
still enforce:

```text
read_data requires response_demux.read.response_scope single_beat in this slice
```

## Drift Found

The generated behavior is correct, but two schedule-report prose fields still
describe the post-`.51` metadata-only state:

```text
response_demux.read response_scope burst_last requires one-bit last_signal
metadata and remains report-only until generated RLAST completion behavior is
explicitly owned
```

and:

```text
report-only burst-last RLAST response-demux metadata are supported
generated burst/last-beat tracking remain outside this capacity/status shell
```

Those strings now conflict with the structured report and generated artifacts
shipped by `.53`. They are user-facing report text, so they must be aligned
before a larger read-data reassembly or manager-behavior slice.

## Selection

The next exact slice is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.55
```

`.55` owns a narrow AXI `RLAST` report-alignment implementation slice. It
must update generated schedule-report prose and focused tests so the report
states that burst-last `RLAST` completion behavior is generated, while still
leaving broader burst payload assembly, `ARLEN` or beat-count validation,
per-beat outputs, per-ID queues, authored concrete-ID same-ID ordering,
queued/blocking policy, profile aliases, full-manager behavior, direct
backend lowering, and VHDL out of scope.

## Why Not Multi-Beat Read-Data Yet

Multi-beat read-data reassembly remains the likely next feature cluster after
report alignment, but direct implementation would currently skip one contract
step. The existing public `read-data` contract is single-beat only and is
explicitly invalid with burst-last response demux. A later owner must first
select or audit the public combined burst read-data shape before behavior can
ship.

The post-report-alignment owner should decide whether the next real feature
slice is a burst read-data contract selector, a readiness audit for
multi-beat reassembly, a per-ID response queue prerequisite, or another
smaller report/static-validation prerequisite discovered by `.55`.

## Validation Gates For `.55`

The `.55` implementation should run:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
prove -Iperl t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

`--verify-hdl` is optional for `.55` because the selected repair should not
change generated `.isf`, `.fsm`, or HDL behavior. It should be run if the
implementation touches anything beyond report strings or report assertions.

## Explicit Non-Goals

This selector does not change public syntax, parser behavior, generated
`.isf`, generated `.fsm`, HDL, support accounting, check JSON, semantic JSON,
or validation behavior. It only selects the next exact owner and records why
the report-alignment prerequisite comes before larger AXI manager work.
