# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.409`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.409` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.410`, public contract selection for
one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture.

The selected public sample is unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The audit read or used:

- `.408` post two-dynamic mixed write recapture selector.
- `.407` two-dynamic-plus-one-static mixed write recapture behavior.
- `.406` two-dynamic mixed write recapture contract selection.
- `.405` two-dynamic mixed write recapture readiness audit.
- `.403`, `.400`, and `.389` mixed write recapture behavior records.
- `.392` one-dynamic plus one-static mixed read single-beat recapture
  behavior.
- `.396` one-dynamic plus one-static mixed read burst-last recapture behavior.
- `.398` broader mixed dynamic/static recapture readiness audit.
- `.299` one-dynamic plus two-static mixed read single-beat response-demux
  behavior.
- `.303` one-dynamic plus two-static mixed read burst-last response-demux
  behavior.
- `.307`, `.310`, `.312`, and `.314` scalar read-data, raw-`ARLEN`, runtime
  validation, and multi-beat preservation records over the same one-dynamic
  plus two-static mixed read family.
- Current response-demux read normalization, mixed dynamic/static read state
  builders, dynamic/static release-only and release-recapture rule helpers,
  report projection, assertion helpers, focused t/1436/t1437/t1438
  expectation surfaces, support accounting, README, ROADMAP_V2, mdBook,
  Memory, task tree, and Knowledge Map.

## Guarded Baseline Probe

The audit ran a guarded schedule probe under the repository RAM guard:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

The probe completed below the default cutoff:

```text
host memory at launch: 79.6%
host cutoff: 88%
schedule output: 44021 bytes
```

The live report still has no same-cycle recapture metadata:

```yaml
response_demux:
  mode: bounded_multi_mixed_dynamic_static_read_rid_demux_contract
  read:
    response_scope: single_beat
    transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id_single_beat
    dynamic_transactions: [r0]
    static_transactions: [r1, r2]
    generated_assertions:
      - axi0_r0_dynamic_request_not_busy
      - axi0_r1_static_request_not_busy
      - axi0_r2_static_request_not_busy
      - axi0_read_mixed_dynamic_static_request_onehot0
      - axi0_r0_r1_read_dynamic_request_not_static_id
      - axi0_r0_r1_read_dynamic_active_not_static_id
      - axi0_r0_r2_read_dynamic_request_not_static_id
      - axi0_r0_r2_read_dynamic_active_not_static_id
      - axi0_read_mixed_dynamic_static_response_active_match
      - axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
      - axi0_r0_r2_read_mixed_dynamic_static_response_unique_match
      - axi0_r1_r2_read_mixed_dynamic_static_response_unique_match
      - axi0_r0_dynamic_completion_active
      - axi0_r1_static_completion_active
      - axi0_r2_static_completion_active
    dynamic_capture:
      transactions:
        - transaction: r0
          selected_id_signal: axi0_r0_dynamic_id_q
          busy_signal: axi0_r0_dynamic_busy_q
          capture_rule: axi0_r0_dynamic_id_capture
          release_rule: axi0_r0_dynamic_id_release
    static_capture: absent
```

## Findings

The next owner can be public contract selection. No parser/source syntax,
support-accounting, report-shape prerequisite, or lower IAL1/IAL0/SystemVerilog
prerequisite is required before selecting the exact contract.

The implementation substrate is close:

- `_response_demux_mixed_dynamic_static_read_transaction` already builds
  list-shaped dynamic and static transaction-state records for one dynamic
  plus one, two, or three static reads and for two dynamic plus one static
  reads.
- The candidate report already has list-shaped
  `dynamic_capture.transactions[]`, `static_transactions`,
  `mixed_transactions`, and `static_id_reservations`.
- Dynamic release-recapture rule generation already uses the state's
  static-request and static-ID block expressions for
  `mixed_dynamic_static_dynamic_read`.
- Static release-recapture rule generation already uses the dynamic-request
  block and sibling-static-request block expressions for
  `mixed_dynamic_static_static_read`.
- Assertion projection already switches dynamic/static request-not-busy
  assertions to idle-or-releasing names when the corresponding states carry
  release-recapture policy metadata.

The missing piece is contract ownership. The current read-side marker
`_response_demux_mark_mixed_dynamic_static_read_recapture` is intentionally
singular: it returns unless there is exactly one dynamic read transaction and
exactly one static read transaction. The contract selection must decide how
the multi-static read report and rule contract widen before behavior changes.

The single-beat one-dynamic plus two-static sample is the smallest read-side
broader-mixed recapture owner. It avoids raw non-final `RID` beat preservation
and final-only `RLAST` release sources from burst-last, and it avoids active
dynamic-ID uniqueness/no-active-same-ID composition from the two-dynamic read
shape. It still has scalar read-data consumers over generated multiple mixed
single-beat completions, so the contract selection must explicitly preserve
that consumer boundary.

## Selected .410 Scope

`.410` should select the public contract for
one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

It should preserve:

- public PPIF syntax and support-accounting identity;
- mode `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`;
- `response_scope: single_beat`;
- `transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux`;
- `transaction_completion_semantics: matched_dynamic_or_static_concrete_id_single_beat`;
- `dynamic_transactions: [r0]`;
- `static_transactions: [r1, r2]`;
- `mixed_transactions.dynamic: [r0]`;
- `mixed_transactions.static: [r1, r2]`;
- `static_id_reservations` for `4'd3` and `4'd5`;
- dynamic capture exclusions against both static concrete IDs;
- onehot0 mixed read request policy;
- dynamic request/static-ID exclusion assertions;
- active dynamic/static-ID exclusion assertions;
- response active-match assertion;
- pairwise response unique-match assertions across dynamic/static/static
  matches;
- completion-active assertions for all three transactions; and
- scalar single-beat read-data capture over generated multiple mixed read
  completion pulses.

It should decide:

- whether the dynamic recapture fields live on
  `response_demux.read.dynamic_capture.transactions[0]`;
- how static concrete busy recapture is reported, with a bias toward
  `response_demux.read.static_capture` as a list of entries ordered by
  `static_transactions`;
- per-transaction rule/source/report spelling:
  `axi0_r0_dynamic_id_release_recapture`,
  `axi0_r1_static_busy_release_recapture`, and
  `axi0_r2_static_busy_release_recapture`;
- whether policy strings remain `mixed_dynamic_static_dynamic_read` and
  `mixed_dynamic_static_static_read`, with the multi-static distinction
  carried by the existing multi-mixed read mode and list fields;
- release-only guard updates so dynamic/static release rules exclude their
  own same-transaction same-cycle requests;
- dynamic release-recapture guards requiring no admitted static sibling
  request and `ARID` not equal to either reserved static ID;
- static release-recapture guards requiring no admitted dynamic request and no
  admitted sibling static request;
- assertion renames from request-not-busy to idle-or-releasing for `r0`,
  `r1`, and `r2`;
- focused validation gates and RAM-guard constraints;
- rollback, docs, Knowledge Map impact; and
- deferred burst-last, two-dynamic, backend, and VHDL boundaries.

`.410` should not change behavior.

## Deferred Boundaries

Direct implementation of the `.410` contract, one-dynamic plus two-static
mixed read burst-last recapture, one-dynamic plus three-static read recapture,
two-dynamic-plus-one-static read recapture, raw non-final `RID` preservation
for burst-last recapture, read-data/raw-`ARLEN`/runtime/multi-beat behavior
changes, static-busy-only recapture outside selected public mixed samples,
request arbitration beyond onehot0, dynamic same-ID queues, scoreboards,
queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Validation

Audit validation is the guarded baseline schedule probe above plus continuity
gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

No parser, support-accounting, strict check, semantic JSON, HDL, or focused
test rerun is required because this audit changes no behavior.

## Rollback

Rollback is the `.409` audit commit. Reverting it restores `.409` as the
active broader mixed read single-beat recapture readiness-audit frontier and
removes `.410` as the selected public contract-selection owner.
