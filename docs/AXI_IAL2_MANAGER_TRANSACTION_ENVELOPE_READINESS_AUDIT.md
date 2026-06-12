# AXI IAL2 Manager Transaction Envelope Readiness Audit

Status: implementation boundary selected; no parser, generator, HDL, or CLI
behavior changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md](AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md](AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)

## Purpose

This audit maps the selected AXI manager logical transaction-envelope/static
validation subset to current code, tests, public reports, and documentation
before implementation changes.

## Readiness Conclusion

The first implementation should be an additive optional `(transactions ...)`
clause under the existing public `(manager-capacity-status ...)` object, not a
new broad `(axi-manager ...)` object yet.

No IAL1, IAL0, or SystemVerilog prerequisite is required first for this first
transaction-envelope slice if it remains static/report metadata and binds each
transaction to the existing direction-level abstract submit/complete events.

Rationale:

- the current public manager shell already owns capacity/status, abstract
  read/write submit/complete events, and optional static ID-family metadata;
- a static transaction envelope can be validated and reported without changing
  generated `.isf`, generated `.fsm`, or SystemVerilog;
- introducing a broader manager object before allocation, ordering, response
  matching, bursts, payload binding, and queue policy are selected would make
  the source name look more complete than the behavior;
- per-transaction event ports or generated dynamic transaction behavior would
  require a later IAL1/IAL0/SystemVerilog owner, but this first slice can avoid
  that by requiring request/completion bindings to reference the existing
  direction-level events.

## Selected Implementation Boundary

The next implementation leaf should accept an optional `(transactions ...)`
clause under one public `(manager-capacity-status ...)` object:

```text
(manager-capacity-status axi0
  (clock clk)
  (reset (rst_n active_low async))
  (read-max-pending 4)
  (write-max-pending 2)
  (submit-policy try)
  (read-submit axi0_read_submit)
  (read-complete axi0_read_complete)
  (write-submit axi0_write_submit)
  (write-complete axi0_write_complete)
  (id-families
    (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
    (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
  (transactions
    (write w0
      (tag wr0)
      (request axi0_write_submit)
      (completion axi0_write_complete)
      (id auto))
    (read r0
      (tag rd0)
      (request axi0_read_submit)
      (completion axi0_read_complete)
      (id auto)))
  (status
    ...))
```

Concrete requested IDs should use a fielded form:

```text
(id (value 3))
```

The source spelling is concise, but the implementation contract must normalize
it to AST/structural data, not to raw line strings.

The in-process contract shape should be:

```perl
transactions => [
    {
        kind             => 'write',
        name             => 'w0',
        tag              => 'wr0',
        request_event    => 'axi0_write_submit',
        completion_event => 'axi0_write_complete',
        id               => { policy => 'auto' },
    },
    {
        kind             => 'read',
        name             => 'r0',
        tag              => 'rd0',
        request_event    => 'axi0_read_submit',
        completion_event => 'axi0_read_complete',
        id               => { value => 3 },
    },
]
```

For this first implementation, a transaction's request/completion events are
references to the existing direction-level events:

- `write` transactions must bind to `write-submit` and `write-complete`;
- `read` transactions must bind to `read-submit` and `read-complete`.

This keeps generated artifacts unchanged and prevents the source from implying
per-transaction event ports or dynamic dispatch that the slice does not own.

## Code Owners

`perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`:

- allow optional `transactions`;
- normalize an array of machine-readable AST/structural transaction entries;
- validate transaction name, kind, tag, request/completion binding, and ID
  policy/value;
- validate concrete requested IDs against declared ID-family width and
  presence;
- fold transaction names and tags into collision checks without treating
  request/completion event references as newly declared signals;
- add a structured `transactions` report section when supplied;
- leave generated `.isf`, generated `.fsm`, and HDL unchanged.

`perl/FSM/Adapter/IAL2/PPIF.pm`:

- parse `(transactions ...)` under `(manager-capacity-status ...)`;
- map `(write NAME ...)` and `(read NAME ...)` entries to structured contract
  hashes;
- support `(id auto)` and `(id (value N))`;
- reject duplicate transaction names/tags, unsupported kinds, malformed
  clauses, direction/event mismatches, concrete IDs without a matching present
  ID family, and unsupported dynamic behavior clauses.

`perl/FSM/Support/RegressionCorpus.pm`:

- add a separate supported `.ppif` sample for the transaction-envelope slice so
  the existing capacity/status and ID-family samples remain compatibility
  fixtures.

`perl/FSM/Support/LanguageSurfaceSection.pm`:

- widen the `.ppif` boundary text to mention one-object capacity/status
  sources with optional static ID-family metadata and optional static
  transaction-envelope metadata.

## Public Sample

Add a checked-in sample:

```text
ppif/axi_manager_capacity_status_transaction_envelope.ppif
```

Support-account it separately, likely:

```text
intent.ppif_axi_manager_capacity_status_transaction_envelope
```

The sample should pass schedule JSON, `--outdir`, default HDL, `--verify-hdl`,
check JSON, and normalized semantic JSON while preserving public `.ppif`
source identity.

## Report Contract

Retain the current report schema string:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

Reason: this is an additive optional report key on the existing capacity/status
shell. The implementation must not rename, remove, or retype existing report
keys.

When `transactions` is supplied, the report should include:

```text
transactions:
  - name: w0
    kind: write
    tag: wr0
    request_event: axi0_write_submit
    completion_event: axi0_write_complete
    id:
      policy: auto
    source_anchors: [...]
  - name: r0
    kind: read
    tag: rd0
    request_event: axi0_read_submit
    completion_event: axi0_read_complete
    id:
      policy: concrete
      value: 3
      family: read
      family_width: 4
      fits: true
    source_anchors: [...]
```

The report must still keep ID allocation, ordering queues, interleaving,
`BID`/`RID` response matching, bursts, queued/blocking policy, and VHDL in
explicit residue.

## Diagnostics

The implementation must fail closed on:

- missing transaction name, kind, tag, request event, completion event, or ID
  clause;
- unsupported transaction kind;
- duplicate transaction names or tags;
- transaction names or tags that collide with clock, reset, abstract events,
  status outputs, generated storage names, ID-family signal names, or each
  other;
- write transactions bound to read events, or read transactions bound to write
  events;
- request/completion bindings that do not match the existing direction-level
  abstract events;
- concrete requested IDs when `id_families` is absent;
- concrete requested IDs when the direction's ID family has width `0`;
- concrete requested IDs that do not fit the direction's declared ID-family
  width;
- unsupported address/data/control payload binding, allocation, ordering,
  response matching, burst, interleaving, transaction-class, alias,
  queued/blocking, per-transaction event-port, or VHDL clauses.

## Validation Gates

Focused implementation tests should extend:

- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`

Broader gates should include:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`
- `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t`
- `prove -Iperl t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

## Explicit Residue

This readiness audit does not implement:

- ID allocation algorithms,
- dynamic user-ID validation while issuing work,
- same-ID ordering queues,
- different-ID interleaving policy,
- `BID`/`RID` response matching,
- burst and last-beat assembly,
- write-data sequencing,
- address/data/control payload binding,
- per-transaction event ports or generated dynamic dispatch,
- queued or blocking policy behavior,
- transaction-class and unique-in-flight constraints,
- full Easy/Power/supervised Raw manager APIs,
- a broader `(axi-manager ...)` public object,
- `.axi` or other profile aliases,
- VHDL backend or VHDL rerouting behavior.

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.12`: implement the additive
transaction-envelope/static-validation metadata slice under the existing
`manager-capacity-status` object.
