# AXI IAL2 Manager RLAST Completion Readiness Audit

Status: readiness audit complete; no parser, generator, HDL, sample, CLI, or
test behavior changed by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.49`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_POST_READ_DATA_NEXT_SLICE_SELECTION.md](AXI_IAL2_MANAGER_POST_READ_DATA_NEXT_SLICE_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)

## Purpose

This audit decides whether AXI burst/`RLAST` completion can move directly to
parser/report metadata or generated behavior after the shipped single-beat
`RDATA`/`RRESP` capture slice.

It cannot. The current implementation has the IAL1/IAL0/SystemVerilog
building blocks needed for a later bounded implementation, but the public
`.ppif` contract has not selected what "read completion" means for bursts.
The next owner must therefore select the public burst/`RLAST` completion
contract before any parser, generator, HDL, sample, or test behavior changes.

## Current Shipped Boundary

The read response-demux public contract is explicitly single-beat:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

`response-event` is the raw accepted read response transfer input for that
single-beat scope. The generated completion outputs are one-cycle pulses for
the matched logical read transactions. The shipped behavior does not observe
`RLAST`, does not count beats, and does not distinguish beat-valid from
transaction-complete.

The read-data public contract is also single-beat:

```text
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    ...))
```

Generated behavior captures `RDATA`/`RRESP` under the generated read
response-demux completion pulse. The captured data/status outputs are held
register values, not one-cycle pulses.

The live schedule report for
`ppif/axi_manager_capacity_status_read_data.ppif` currently reports:

```text
response_demux.read.response_scope: single_beat
response_demux.residue: [read_data_interleaving, bursts]
read_data.generated_behavior: true
read_data.residue: [rlast_completion, bursts, multi_beat_read_data_reassembly]
same_id_ordering.residue:
  [concrete_id_same_id_ordering, per_id_issue_order_queues,
   read_data_interleaving, bursts]
```

The public parser and generator fail closed today on burst attempts:

- `response-demux.read.response_scope` must be `single-beat`;
- `read-data.read.capture_scope` must be `single-beat`;
- `read-data.read.completion_source` must be `response-demux`;
- `read-data.read.interleaving` must be `single-beat-by-rid`;
- no `RLAST`, burst length, beat-count, `ARLEN`, or multi-beat reassembly
  field is accepted.

## AXI Rule Evidence

The AXI evidence and rule matrix keep the same constraints in view:

- `ARID`/`RID` identify read response streams, and `RID` must match the
  corresponding `ARID`.
- Same-ID read responses remain ordered inside the read response stream, but
  different IDs may interleave.
- A manager issuing different read IDs must either accept interleaved read
  data or constrain issuing when an explicit design-time interleaving policy
  disables it.
- Subordinate read-data reordering depth is static and not dynamically
  discoverable by the manager.
- Exact burst assembly and read-data chunking remain future work unless an
  exact owner selects them.

Those facts make a direct "turn on `RLAST` behavior" slice too broad. A
last-beat completion signal, multi-beat payload/status collection, per-ID
reassembly, same-ID issue-order queues, and full burst assembly are related
but not identical responsibilities.

## Substrate Readiness

No new IAL1/IAL0/SystemVerilog substrate prerequisite is evident for the first
bounded `RLAST` contract once that contract exists:

- IAL1 interface ports already support positive-width inputs and outputs.
- Actor-owned scalar storage supports positive-width registers and reset
  values.
- Rules support guarded flopped assignments for counters/state and `(pulse
  target)` for one-cycle completion pulses.
- Generated read-data capture already reaches `.isf`, `.fsm`, and
  SystemVerilog through the normal guarded assignment path.

A later bounded behavior owner can likely use these existing pieces to add an
`RLAST` input, beat counters or remaining-beat state, last-beat completion
pulses, and assertions. The missing piece is public source semantics, not a
known lowering gap.

## Selected Next Owner

The next owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.50
```

Goal: select the public AXI burst/`RLAST` completion contract after generated
single-beat read-data capture.

The selector must happen before parser/report metadata or generated behavior
because the contract must decide:

- whether burst completion extends `response-demux`, extends `read-data`, or
  introduces a separate bounded read-completion/burst-completion clause;
- the public spelling for the `RLAST` source signal, its direction, and its
  required one-bit width;
- how burst length or beat count is supplied: explicit authored transaction
  metadata, generated `ARLEN` ownership, or another fail-closed source;
- whether the generated transaction completion pulse remains a last-beat
  pulse, whether a separate beat-valid pulse is reported, or whether both are
  named;
- whether data/status capture remains per accepted beat, last-beat only, or
  defers multi-beat collection to a later reassembly owner;
- how report JSON distinguishes contract metadata from generated behavior;
- which residue can move only after metadata, and which residue can move only
  after generated HDL behavior ships.

## Report And Residue Expectations

The selected contract should keep the existing schedule schema version unless
a later owner explicitly justifies a schema bump. At selection time, no report
behavior changes.

A later parser/report metadata slice should report any new burst/`RLAST`
contract with `generated_behavior: false` until generated behavior ships. It
should leave existing `response_demux.residue`, `read_data.residue`, and
`same_id_ordering.residue` honest.

A later generated behavior slice may remove `rlast_completion` only when it
actually generates the last-beat completion behavior. It may remove `bursts`
or `multi_beat_read_data_reassembly` only when the selected generated behavior
covers those responsibilities, not merely because `RLAST` is parsed.

## Generated Artifact Boundary

This audit changes no generated artifacts. The `.50` selector must also
change no generated artifacts.

A future metadata slice may parse and report new structural fields while
keeping `.isf`, `.fsm`, and HDL behavior unchanged. A later behavior slice may
then own generated artifacts such as:

- a generated `RLAST` input;
- optional burst-length or remaining-beat state;
- beat-valid and last-beat/transaction-complete rules;
- generated assertions for inactive completion, malformed last beat, missing
  last beat, or unexpected extra beat;
- generated report artifact lists for new inputs, outputs, storage, rules, and
  assertions.

## Diagnostics To Select Next

The contract selector should require future parser/report diagnostics for:

- duplicate or malformed burst/`RLAST` clauses;
- unsupported response or capture scopes;
- missing generated read response-demux prerequisite;
- missing generated read-data prerequisite when the selected contract depends
  on captured `RDATA`/`RRESP`;
- malformed or non-one-bit `RLAST` signal declarations;
- absent burst length or beat-count metadata when behavior would need it;
- unsupported generated `ARLEN` ownership if request-channel payload ownership
  is not selected;
- ambiguous beat-valid versus transaction-complete output names;
- unsupported interleaving/reassembly policies;
- generated input, output, storage, rule, assertion, or report artifact name
  collisions.

## Validation Gates

The selector should run at least:

- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

A later parser/report or behavior slice must add focused generator and PPIF
parser/CLI tests, check JSON/semantic JSON support-accounting coverage, and
`--verify-hdl` coverage if generated HDL behavior changes.

## Residue

Still out of scope after this audit until later exact owners:

- the public burst/`RLAST` contract selection itself;
- parser/report metadata for that selected contract;
- generated `RLAST` completion behavior;
- multi-beat read-data reassembly;
- different-ID read-data queues;
- authored concrete-ID same-ID issue-order queues;
- queued/blocking policy;
- request-channel payload generation such as `ARLEN` unless selected by the
  contract owner;
- profile aliases and full AXI manager syntax;
- direct backend lowering;
- VHDL backend or reroute behavior.

## Rollback

This audit changes only documentation, task-tree, Knowledge Map, roadmap, book,
and memory surfaces. Rolling it back restores `.49` as pending and does not
require reverting parser, generator, HDL, CLI, sample, support-accounting, or
test behavior.

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.50`: select the public AXI
burst/`RLAST` completion contract before parser/report metadata or generated
behavior changes.
