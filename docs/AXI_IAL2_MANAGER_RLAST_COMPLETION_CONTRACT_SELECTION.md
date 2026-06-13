# AXI IAL2 Manager RLAST Completion Contract Selection

Status: selected bounded public contract; no parser, generator, HDL, sample,
CLI, or test behavior changed by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.50`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md](AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)

## Purpose

This selector chooses the public `.ppif` contract for the first bounded AXI
read `RLAST` completion surface after generated single-beat read-data capture.

The selected boundary is last-beat transaction completion, not full burst
assembly. It lets a later implementation generate transaction completion
pulses from matched `RID` plus `RLAST`, while leaving beat-count validation,
`ARLEN` ownership, multi-beat payload collection, and per-ID reassembly queues
as explicit future residue.

## Selected Public Syntax

Extend the existing read `response-demux` arm with a second response scope:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The already-shipped single-beat syntax remains valid and unchanged:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

`response-event` still names the raw accepted read response transfer. For
`response-scope burst-last`, it is a beat-valid event for the read response
channel. It must continue to equal the top-level `read-complete` event in this
bounded capacity/status object.

`last-signal` names the AXI `RLAST` source and must declare `(width 1)`. It is
only legal with `response-scope burst-last`; the single-beat scope rejects it.

`transaction-completion generated` keeps the existing transaction
`(completion NAME)` binding model. In the later generated behavior slice, the
generated completion pulse for a read transaction must fire only for a matched
`RID` beat whose `last-signal` is asserted. Non-last matched beats must not
pulse the transaction completion output.

## Why Response-Demux Owns The Contract

The first `RLAST` boundary extends `response-demux.read`, not `read-data` and
not a separate top-level clause.

`response-demux.read` already owns `RID` matching and generated transaction
completion pulses. `RLAST` changes when those completion pulses are emitted.
That makes it a response-demux completion contract.

`read-data` remains single-beat for now. Its existing `completion-source
response-demux` contract uses the generated transaction completion pulse as
the capture strobe. Under burst-last scope, using that same strobe would only
capture the last beat and would not assemble the burst. That behavior must not
be implied. A later read-data reassembly owner must select any multi-beat
payload/status collection syntax.

No separate `read-completion` clause is selected for this first boundary. It
would duplicate completion ownership already carried by `response-demux.read`
without solving the payload/reassembly problem.

## Static Contract

The first parser/report implementation must enforce:

- `response-demux` remains optional and may appear at most once under
  `manager-capacity-status`;
- the read arm supports exactly `response-scope single-beat` or
  `response-scope burst-last`;
- `response-scope single-beat` keeps the shipped rules and rejects
  `(last-signal ...)`;
- `response-scope burst-last` requires exactly one
  `(last-signal NAME (width 1))`;
- `last-signal` widths other than `1`, missing `(width ...)`, non-integer
  widths, and malformed tuple shapes are rejected;
- `response-event` must still equal top-level `read-complete`;
- `transaction-completion` must still be `generated`;
- read response demux still requires positive-width read ID-family metadata,
  read transactions, and read `auto-id-lifecycle` metadata;
- generated names and authored names must remain collision-free, including the
  new `last-signal` input name;
- the first `read-data` contract remains compatible only with
  `response-scope single-beat`; if a source uses `read-data` with
  `response-scope burst-last`, the parser/report implementation must reject it
  until a later reassembly contract selects the behavior.

## Burst Length And Beat Count

The first selected contract uses `RLAST` as the authoritative last-beat marker
and does not select burst length or beat-count metadata.

That is deliberate. The current capacity/status object does not own read
address payload generation, `ARLEN`, or request-channel burst parameters.
Adding a beat-count field here would either duplicate future request-channel
ownership or create a count that the generated manager cannot yet tie back to
the submitted address transaction.

The later generated behavior may assert that a last beat only completes an
active matching transaction. It must not claim to validate missing `RLAST`,
extra beats after `RLAST`, or `ARLEN`/beat-count consistency. Those remain
residue until a request-channel payload and burst assembly owner is selected.

## Beat-Valid Versus Transaction-Complete

The contract keeps one public generated signal per transaction completion:
the existing transaction `(completion NAME)` output.

For `response-scope burst-last`, `response-event` is the raw beat-valid input,
but no generated per-transaction beat-valid output is selected in this slice.
The later behavior owner may use per-transaction beat-match expressions
internally, but it must not publish new beat-valid outputs unless a future
contract selects names and semantics for them.

This keeps the first implementation small: matched non-last beats preserve the
transaction as active; matched last beats pulse the generated completion and
allow existing capacity/auto-ID release rules to run.

## Read-Data Boundary

The shipped `read-data` syntax remains:

```text
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    ...))
```

It is not extended by this selector. `capture-scope burst`, `capture-scope
burst-last`, per-beat outputs, payload banks, packed burst outputs, and
multi-beat reassembly policies remain future exact-owner work.

Because generated single-beat read-data capture uses transaction completion as
the strobe, a source must not combine the current `read-data` contract with
`response-scope burst-last`. A later contract may select last-beat-only
capture explicitly, but this selector does not.

## Report Contract

The first parser/report metadata slice should keep schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`.

For a burst-last metadata slice before generated behavior, the selected report
shape is:

```text
response_demux:
  mode: bounded_response_demux_contract
  generated_behavior: false
  read:
    mode: bounded_read_rid_demux_contract
    generated_behavior: false
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response_beat
    response_scope: burst_last
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    last_signal: axi0_rlast
    last_signal_direction: generated_input
    last_signal_width: 1
    transaction_completion_source: generated_demux_last_beat
    transaction_completion_semantics: matched_rid_and_last_signal
    beat_valid_output: none
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    auto_transactions: [r0, r1]
  residue:
    - generated_burst_last_read_demux
    - read_data_interleaving
    - bursts
```

If a source uses the shipped `single-beat` scope, existing report behavior must
remain unchanged.

For the later generated behavior slice, `response_demux.read.generated_behavior`
may become true for `burst_last`, and generated artifact lists may include the
`RLAST` input, last-beat demux rules, completion signals, and assertions. The
broader `bursts`, `read_data_interleaving`, and
`multi_beat_read_data_reassembly` residue must remain until exact behavior
owners cover them.

## Generated Artifact Boundary

The selected next owner is parser/report metadata and static validation only:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.51
```

That owner should:

- parse and validate `response-scope burst-last` plus `last-signal`;
- normalize the structural read response-demux metadata;
- report `response_demux.read` with `generated_behavior: false` for the
  burst-last scope;
- add focused diagnostics for malformed/unsupported `last-signal` forms;
- add or update a runnable `.ppif` sample only if generated `.isf`, `.fsm`,
  and HDL behavior remain unchanged;
- keep the shipped single-beat read response-demux behavior and the shipped
  single-beat read-data behavior intact;
- reject the existing single-beat `read-data` contract when paired with
  burst-last response-demux;
- update check JSON, semantic JSON, mdBook, roadmap, task tree, Knowledge Map,
  and memory in the same commit.

Generated `RLAST` inputs, last-beat completion rules, completion assertions,
and HDL reachability require a later behavior readiness/implementation owner.

## Future Behavior Boundary

A later behavior owner may use this contract to:

- declare `RLAST` as a generated one-bit IAL1 input;
- include `RLAST` in the generated read response-demux guard for transaction
  completion pulses;
- keep non-last matched beats from releasing capacity or auto-ID state;
- assert that last-beat completion only occurs for an active matching
  transaction;
- preserve generated same-ID avoidance and read capacity release behavior by
  releasing only on last-beat transaction completion pulses.

It must not claim full burst assembly, `ARLEN` validation, read-data
reassembly, per-ID issue-order queues, or VHDL backend behavior.

## Diagnostics Expected In The Parser/Report Slice

The parser/report implementation should reject:

- duplicate `response-demux` clauses;
- duplicate `(read ...)` family arms;
- unsupported read response scopes beyond `single-beat` and `burst-last`;
- missing or duplicate `(last-signal ...)` under `burst-last`;
- any `(last-signal ...)` under `single-beat`;
- malformed `(last-signal NAME (width 1))`;
- non-one-bit `last-signal` widths;
- `last-signal` names that collide with clock, reset, events, ID signals,
  status outputs, generated storage, generated completions, generated
  assertions, read-data sources, or read-data outputs;
- burst-last response demux without generated read `auto-id-lifecycle`;
- burst-last response demux on a zero-width read ID family;
- the current single-beat `read-data` contract when paired with burst-last
  response demux;
- any burst length, beat-count, `ARLEN`, per-beat output, or multi-beat
  reassembly clause in this first contract.

## Validation Gates

The parser/report metadata implementation should run at least:

- `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`
- `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`
- `./bin/fsmgen --emit-schedule-json <new burst-last sample>`
- `./bin/fsmgen --strict --check --json <new burst-last sample>`
- `./bin/fsmgen --strict --emit-semantic-json <new burst-last sample>`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

The later generated behavior slice must add `--verify-hdl` coverage for the
burst-last sample when HDL behavior changes.

## Residue

Still out of scope after this selector until later exact owners:

- parser/report implementation of the selected `burst-last` contract;
- generated `RLAST` completion behavior;
- generated beat-valid output names or semantics;
- burst length, beat-count, or `ARLEN` ownership;
- missing/extra beat validation;
- multi-beat read-data reassembly;
- different-ID read-data queues;
- authored concrete-ID same-ID issue-order queues;
- queued/blocking policy;
- profile aliases and full AXI manager syntax;
- direct backend lowering;
- VHDL backend or reroute behavior.

## Rollback

This selector changes only documentation, task-tree, Knowledge Map, roadmap,
book, and memory surfaces. Rolling it back restores `.50` as pending and does
not require reverting parser, generator, HDL, CLI, sample, support-accounting,
or test behavior.

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.51`: implement parser/report
metadata and static validation for the selected bounded AXI read
`response-scope burst-last` plus `last-signal` contract, with generated
`.isf`, `.fsm`, and HDL behavior unchanged.
