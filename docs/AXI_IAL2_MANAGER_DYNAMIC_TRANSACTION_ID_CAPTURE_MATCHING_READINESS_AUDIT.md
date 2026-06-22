# AXI IAL2 Manager Dynamic Transaction-ID Capture/Matching Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.221` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.221`

## Conclusion

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.222`, public contract selection for
bounded dynamic write transaction-ID capture and `BID` response matching.

Do not implement generated dynamic response matching directly in `.221`. The
existing IAL1/IAL0/SystemVerilog substrate can likely carry the narrow write
shape once the public contract is explicit, but the source contract still has
to define when the user-supplied request ID is captured, what single-active
dynamic ownership means, how the stored ID is matched against `BID`, and what
runtime assertions protect inactive, unmatched, ambiguous, or repeated
requests.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior.

## Evidence Read

The audit read:

- `.220` post-metadata selector:
  `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_TRANSACTION_ID_METADATA_NEXT_SLICE_SELECTION.md`.
- `.219` dynamic transaction-ID metadata behavior, `.218` metadata readiness
  audit, `.217` dynamic-ID contract selection, and `.216` dynamic same-ID
  issue-order readiness audit.
- Current dynamic PPIF sample:
  `ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif`.
- `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` dynamic ID
  normalization, dynamic fail-closed behavior interactions, auto-ID lifecycle
  state, response-demux normalization, response-demux state/rule/assertion
  helpers, support-detail text, and report projection.
- Existing write `BID` and read `RID` response-demux readiness/behavior notes.
- IAL1 storage, rule-owned pulse action, assertion, width, schedule-report,
  `.fsm`, and SystemVerilog lowering substrate via the existing docs and code
  paths already used by auto-ID lifecycle and response-demux behavior.
- README, `ROADMAP_V2.md`, mdBook backlog, task tree, Memory, and Knowledge
  Map fact cards.

## Current Substrate

The generated response-demux substrate already has the core match shape used
by auto-ID response demux:

```text
response_event && busy && response_id_signal == selected_id_signal
```

The existing helpers already generate:

- selected-ID and busy storage for auto-ID transactions;
- rule-owned one-cycle completion pulses through `(pulse COMPLETION)`;
- response-demux rules and generated completion outputs;
- active-match and unique-match assertions;
- `.isf -> .fsm -> SystemVerilog` lowering for width-bearing response IDs,
  equality expressions, storage updates, pulse outputs, and assertions.

That substrate is close to what dynamic matching needs, but auto-ID selects an
ID from a bounded generated pool. Dynamic matching must instead sample a
user-supplied request-ID signal at the admitted request point and store that
value for later response matching.

## Contract Gaps

The public contract is not yet precise enough for generated behavior:

- `(id dynamic)` currently reports metadata only and marks implementation as
  `selected_not_generated`.
- `response-demux.<family>` is fail-closed when paired with same-family
  dynamic IDs.
- The current source does not say whether an existing `response-demux.write`
  arm is sufficient for dynamic matching or whether an additive dynamic-ID
  lifecycle/capture clause is required.
- The capture point must be an admitted request, not a raw request pulse that
  capacity/status logic may reject.
- The first supported ownership model must define whether one dynamic
  transaction per family is allowed, whether multiple dynamic transactions can
  be active, and how same-ID reuse is rejected or deferred.
- Runtime diagnostics/assertions must be defined for repeated request while
  busy, response when no dynamic transaction is active, response ID mismatch,
  and ambiguous matches.

Silently reusing the existing metadata-only `(id dynamic)` plus
`response-demux.write` behavior would create contract drift. The next owner
must choose the exact public surface before parser/report or generator
behavior changes.

## Selected `.222` Contract Boundary

`.222` must select the public contract for bounded dynamic write response
matching. The selector should decide:

- whether dynamic matching uses existing `(response-demux (write ...))`
  syntax with dynamic transaction IDs, a new additive capture/lifecycle clause,
  or a narrower report/static split first;
- whether the first supported behavior is exactly one dynamic write
  transaction in the write family, or a finite set with fail-closed same-ID
  assertions;
- the admitted-request capture point for the family request-ID signal;
- the generated state names and lifetime: stored dynamic ID, busy bit,
  capture rule, matched-response completion pulse, and release rule;
- the write response match condition: raw accepted write response event,
  active busy state, and `BID == captured_id`;
- diagnostics for dynamic read response matching, dynamic same-ID ordering,
  dynamic read-data routing, queues, scoreboards, bursts, direct backend
  behavior, HDL shapes outside the selected write boundary, and VHDL;
- report vocabulary for generated dynamic capture/matching metadata and
  remaining `dynamic_transaction_id_behavior` residue;
- focused validation gates for parser/report metadata if selected separately,
  and generated `.isf`, `.fsm`, SystemVerilog, schedule JSON, strict check
  JSON, semantic JSON, support accounting, and mdBook if behavior is selected
  later.

## Why Write First

Write response matching is narrower than read matching. One accepted write
response with `BID` completes one write transaction, and the existing write
response-demux behavior already demonstrates the response event plus selected
ID match shape.

Read response matching still needs a separate answer for `RID` scope,
`RLAST`, burst/last-beat ownership, read-data routing, interleaving, and
reassembly. Dynamic read behavior remains future exact-owner work.

## Preservation Matrix

`.222` must preserve:

- metadata-only `(id dynamic)` parser/report support until an explicit later
  owner changes behavior;
- fail-closed dynamic read response matching, same-ID ordering, read-data
  routing, queues, scoreboards, direct backend behavior, HDL behavior outside
  the selected write shape, and VHDL;
- existing auto-ID lifecycle, concrete-ID assertion, counted queue-head,
  response-demux, read-data, burst, runtime-validation, multi-beat, strict
  check JSON, semantic JSON, and HDL behavior;
- support-accounting identities and public sample behavior;
- backend-language neutrality and the required
  `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path.

## Validation Gates

For `.221`, the required gates are documentation and continuity gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

Any broad `prove` or supported-corpus gate remains RAM-guarded.

## Rollback Boundary

Rollback for `.221` is limited to this audit record, task-tree frontier
movement, Memory, README, roadmap, mdBook, and Knowledge Map/fact-card
updates. No parser, generator, public sample, support-accounting catalog,
generated artifact, test, validation, or HDL behavior is part of this slice.
