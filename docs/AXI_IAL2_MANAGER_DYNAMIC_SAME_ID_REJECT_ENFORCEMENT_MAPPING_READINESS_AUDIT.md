# AXI IAL2 Manager Dynamic Same-ID Reject Enforcement Mapping Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.437`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.437` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.438`, a narrow generated-enforcement
report mapping for selected dynamic same-ID reject policy over already
generated multi-active dynamic and mixed dynamic/static response-demux shapes.

The audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, schedule/check or semantic
JSON, HDL, runtime behavior, direct backend behavior, or VHDL behavior.

## Inputs Read

The audit read:

- `.436` metadata-first `(dynamic-id-reuse reject)` parser/report behavior;
- `.435` metadata readiness audit, `.434` public policy contract, and `.433`
  dynamic same-ID readiness audit;
- current `AxiManagerCapacityStatus` dynamic and mixed response-demux builders;
- current generated assertion construction for dynamic and mixed
  dynamic/static response-demux families;
- current report projection, including deletion of private
  `dynamic_transaction_state` and `static_transaction_state`;
- focused `t/1436`, `t/1437`, and `t/1438` expectation surfaces for dynamic
  response-demux assertions, dynamic same-ID policy diagnostics, and residue;
- public support-accounted dynamic and mixed response-demux samples;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Existing Generated Enforcement

The existing generated response-demux behavior already has the enforcement
pieces required for selected dynamic same-ID `reject` on multi-active dynamic
families:

- all-dynamic multiple write response demux emits per-transaction
  `*_dynamic_request_no_active_same_id` assertions and pairwise
  `*_write_dynamic_active_id_unique` assertions;
- all-dynamic multiple read single-beat and burst-last response demux emit
  the same request no-active-same-ID and active-ID uniqueness assertion
  families;
- two-dynamic-plus-one-static mixed write, read single-beat, and read
  burst-last response demux emit the dynamic no-active-same-ID and active-ID
  uniqueness assertions, plus dynamic/static request and active static-ID
  exclusion assertions.

The compact guarded report probe read these public samples:

```text
ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif
```

Those samples report `dynamic_capture.same_id_conflict_policy:
active_dynamic_ids_must_be_unique`, request onehot0 assertions,
per-dynamic-transaction no-active-same-ID assertions, and pairwise active-ID
uniqueness assertions while keeping `same_id_ordering` in
`response_demux.residue`.

Single-active dynamic write/read response-demux samples report
`single_active_dynamic_write` or `single_active_dynamic_read` with
idle-or-releasing request assertions, but they do not expose no-active-same-ID
or pairwise active-ID uniqueness artifacts. They are not selected for the
first generated dynamic same-ID reject mapping.

One-dynamic mixed dynamic/static shapes reserve static concrete IDs and prove
dynamic/static exclusion, but they do not contain multiple dynamic
transactions. They are also not selected for the first dynamic same-ID reject
mapping.

## Current Blocker

`.436` intentionally keeps same-family dynamic response demux plus
`dynamic-id-reuse reject` fail-closed:

```text
response_demux.<family> dynamic ID matching cannot be combined with same_id_ordering.<family> in this slice
```

That diagnostic is still correct for `.436`. The generated lowerer already has
the relevant selected-ID state, active bits, request guards, completion pulses,
and runtime assertions for the multi-active shapes above, but the public
contract has not yet connected those existing assertions to
`same_id_ordering.dynamic_id_reuse_policy.<family>`.

No IAL1, IAL0, SystemVerilog, direct backend, support-accounting, Knowledge
Map, or mdBook infrastructure prerequisite is needed before the first bounded
mapping. The missing work is a family-local parser/report acceptance and
residue-movement mapping.

## Selected `.438` Boundary

`.438` should implement the narrow mapping only for generated response-demux
families whose dynamic capture reports:

```text
same_id_conflict_policy: active_dynamic_ids_must_be_unique
```

and whose generated assertions include both:

- one or more `*_dynamic_request_no_active_same_id` assertions;
- one or more `*_dynamic_active_id_unique` assertions.

For those covered families, the implementation may accept the same-family
combination of explicit `response-demux.<family>` and
`same-id-ordering.<family> (dynamic-id-reuse reject)` without generating new
rules, storage, assertions, HDL, or runtime behavior.

The covered dynamic policy report should move from:

```text
implementation_status: selected_not_generated
enforcement: not_generated
```

to generated enforcement metadata such as:

```text
implementation_status: generated_no_active_same_id_reject
enforcement: generated_no_active_same_id_assertions
assertion_enforcement: runtime_assertion
response_demux_covered: true
```

The report should also expose the covered response-demux mode/source and the
generated no-active-same-ID and active-ID uniqueness assertion names. It must
keep:

```text
accepted_same_id_reuse: false
request_conflict_policy: no_active_same_id
generated_queue_behavior: false
generated_scoreboard_behavior: false
```

Residue movement must stay family-local and honest. The implementation may
remove `dynamic_id_same_id_ordering` only when every selected dynamic policy
family is covered by generated no-active-same-ID reject enforcement. It may
remove `same_id_ordering` from `response_demux.residue` only for a covered
response-demux family, preserving unrelated `read_response_demux`,
`read_data_interleaving`, and `bursts` residue.

## Fail-Closed Boundaries

`.438` should keep the following cases fail-closed or selected-not-generated:

- single-active dynamic write/read response-demux shapes until a later owner
  decides whether idle-or-releasing assertions are sufficient public dynamic
  same-ID reject enforcement;
- one-dynamic mixed dynamic/static response-demux shapes;
- any dynamic response-demux family without generated no-active-same-ID and
  active-ID uniqueness assertion names;
- `dynamic-id-reuse issue-order-queue` and `dynamic-id-reuse scoreboard`;
- concrete-only same-ID policy used as a dynamic policy;
- direct queue, scoreboard, request arbitration, overflow, ambiguity, direct
  backend, backend-language, or VHDL behavior.

## Validation For `.438`

The implementation slice should include:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

Focused behavior checks should prove at least one all-dynamic write, one
all-dynamic read burst-last, and one two-dynamic-plus-one-static mixed
response-demux policy mapping. They should also prove fail-closed preservation
for single-active dynamic response demux and one-dynamic mixed response demux.
Broad `prove`, supported-corpus, `fsmgen`, and HDL validation commands remain
RAM-guarded.

Closeout still requires Knowledge Map, memory architecture, mdBook, diff, and
doctrine gates.

## Rollback

Rollback for `.437` is this docs-only audit commit. Reverting it removes the
`.438` selection record, fact card, task-tree advancement, live-doc updates,
and resume pointer update without changing generated behavior.
