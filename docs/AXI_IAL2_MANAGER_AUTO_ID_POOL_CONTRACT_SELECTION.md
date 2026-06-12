# AXI IAL2 Manager Auto-ID Pool Contract Selection

Status: selected bounded public contract; no parser, generator, HDL, CLI, or
support-accounting behavior changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md](AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md](AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md](AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)

## Purpose

This selector chooses the exact public IAL2 contract that will make future
AXI manager `(id auto)` transactions behavior-bearing without inferring an
allocation policy from ID width alone.

The `.20` audit found that the current IAL1/IAL0/SystemVerilog path can carry
a bounded scalar request-ID lifecycle, but the public IAL2 source must first
name a bounded pool and the request-ID drive contract.

## Selected Public Syntax

Add an optional `auto-id-lifecycle` clause under the existing
`manager-capacity-status` object:

```text
(auto-id-lifecycle
  (write (pool 0 1))
  (read  (pool 0 1 2 3)))
```

The selected clause is deliberately small. `id-families` already names the
request and response ID signals and declares their widths. `transactions`
already marks each logical transaction as `(id auto)` or `(id (value N))`.
The new clause only supplies the missing bounded allocation pool that makes
`(id auto)` behavior reviewable.

Existing `(id auto)` transactions remain structural/report-only metadata when
`auto-id-lifecycle` is absent.

## Static Contract

The first public parser/report slice should enforce:

- `auto-id-lifecycle` is optional and may appear at most once under
  `manager-capacity-status`;
- the clause requires existing `id-families` metadata;
- the clause requires existing `transactions` metadata with at least one
  `(id auto)` transaction in each named family;
- supported family subclauses are `write` and `read`;
- each family subclause requires exactly one `(pool ...)` clause;
- each pool is a non-empty author-ordered list of unsigned integer IDs;
- the first bounded implementation supports `1..4` pool entries per family;
- pool values must be unique within the family;
- pool values must be less than `2**width` for the declared family width;
- zero-width ID families cannot use auto-ID lifecycle;
- a family with no auto-ID transactions must not be listed in the lifecycle
  clause in the first slice;
- lifecycle family names, request ID signals, response ID signals, events,
  status outputs, and generated storage names must remain collision-free.

The `1..4` pool-entry cap is an implementation boundary, not a permanent
language limit. Lifting it needs a later task-owned slice with matching tests,
docs, report updates, and generated-behavior evidence.

## Behavior Contract For The Future Generator

The first behavior-bearing slice after the parser/report contract should use
these fixed semantics:

- request-side ID-family signals are manager-owned generated outputs:
  `AWID` for write, `ARID` for read;
- response-side ID-family signals remain environment/subordinate inputs:
  `BID` for write, `RID` for read;
- the allocator is deterministic first-free in author pool order;
- each auto-ID transaction is single-active: one outstanding instance of that
  logical transaction may own an ID at a time;
- a transaction request event allocates and drives one free pool ID;
- a transaction completion event releases that transaction's stored ID;
- more than one auto-ID request event in the same family in the same cycle is
  outside the first behavior slice and must be rejected or asserted;
- a request for an already-active auto-ID transaction must be rejected or
  asserted unless a later task explicitly selects same-cycle complete/request
  replacement semantics;
- completion for an inactive auto-ID transaction must be rejected or asserted;
- no-ID-available behavior is a generated runtime assertion in the first
  behavior slice, not a new status output;
- capacity/status outputs remain the existing direction-capacity signals until
  a later slice selects ID-availability-aware status refinement.

This keeps the first behavior slice honest: it proves request-ID drive and
per-transaction ID lifetime without claiming full scoreboards, repeated
logical transaction queuing, response demux, same-ID ordering queues, or
read-data reassembly.

## Report Contract

Add a separate `auto_id_lifecycle` report key. Do not overload
`id_response_rule_engine`, which remains the concrete-ID assertion report.

The first parser/report implementation should emit machine-readable metadata
with this shape:

```text
auto_id_lifecycle:
  mode: bounded_pool_contract
  generated_behavior: false
  max_pool_entries_per_family: 4
  families:
    - family: write
      request_id_signal: axi0_awid
      request_id_direction: generated_output
      response_id_signal: axi0_bid
      response_id_direction: generated_input
      pool: [0, 1]
      allocator: first_free_pool_order
      transaction_lifetime: single_active
      release: transaction_completion_event
      no_id_available: runtime_assertion
      auto_transactions: [w0, w1]
  residue:
    - generated_request_id_drive
    - id_release_rules
    - same_id_ordering
    - response_demux
```

When generated behavior ships later, the same key should switch
`generated_behavior` to true and add generated storage, allocation rule,
release rule, and assertion metadata.

## Generated Artifact Boundary

The selected next implementation owner should be a parser/report metadata
slice, not request-ID drive yet. It should:

- parse and validate the new public `auto-id-lifecycle` clause;
- normalize it into structural data in the capacity/status contract;
- report `auto_id_lifecycle` metadata;
- update check JSON and normalized semantic JSON support accounting;
- add one runnable `.ppif` sample;
- keep generated `.isf`, generated `.fsm`, and HDL behavior unchanged;
- keep mdBook, roadmap, task tree, Knowledge Map, and memory in the same
  commit.

The first request-ID drive implementation should be a later owner after the
public contract is parsed, reported, tested, and documented.

## Diagnostics Expected In The Parser/Report Slice

The selected parser/report implementation should reject:

- duplicate `auto-id-lifecycle` clauses;
- unsupported family names;
- missing `(pool ...)`;
- duplicate `(pool ...)` clauses;
- empty pools;
- pools with more than four entries;
- duplicate pool values;
- non-integer or negative pool values;
- values outside the family width;
- lifecycle use without `id-families`;
- lifecycle use without `transactions`;
- lifecycle use on a zero-width family;
- lifecycle family listed with no auto-ID transaction in that family.

The behavior-bearing slice after that should add diagnostics or assertions for
request-event conflicts, request-while-active, completion-while-inactive, and
no-ID-available runtime cases.

## Validation Gates

The parser/report implementation should run at least:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`
- `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

## Residue

Still out of scope after this selector:

- parser/report implementation of `auto-id-lifecycle`;
- generated request-ID output drive;
- ID busy/free storage and release rules;
- no-ID-available runtime assertions;
- repeated instances of one logical transaction;
- same-cycle multi-allocation in one family;
- same-ID ordering queues;
- different-ID read-data interleaving and reassembly;
- generated `BID`/`RID` response demux;
- burst and last-beat tracking;
- address/data/control payload binding;
- queued or blocking submission policy;
- full AXI manager syntax;
- `.pif`, `.ppi`, `.axi`, or other profile aliases;
- VHDL backend or VHDL rerouting behavior.

## Rollback

This selector changes only documentation, task-tree, Knowledge Map, and memory
surfaces. Rolling it back restores `.21` as pending and does not require
reverting any parser, generator, HDL, CLI, sample, or test behavior.

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.22`: implement the additive
public `.ppif` parser/report metadata slice for the selected
`auto-id-lifecycle` contract, with static validation and no generated
`.isf`, `.fsm`, or HDL behavior changes.
