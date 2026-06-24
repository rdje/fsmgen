# AXI IAL2 Manager Single-Active Dynamic Same-ID Reject Mapping Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.442`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.442` ships the `.441` selected
single-active dynamic same-ID reject report/acceptance mapping. Same-family
`response-demux.<family>` plus `same-id-ordering.<family>
(dynamic-id-reuse reject)` is now accepted for these already generated
single-active dynamic response-demux shapes:

- write `BID`;
- read single-beat `RID`;
- read burst-last `RID && RLAST`.

The mapping does not add generated rules, storage, assertions, HDL, runtime
behavior, direct backend behavior, backend-language variants, queues,
scoreboards, or VHDL behavior. It only changes acceptance, report metadata,
and residue movement when existing generated response-demux evidence is
present.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_same_id_reject.ppif
```

It combines the existing single-active dynamic read single-beat response-demux
shape with:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse reject)))
```

The sample is cataloged as
`intent.ppif_axi_manager_capacity_status_dynamic_read_response_demux_same_id_reject`
with coverage bucket
`ial2_ppif_manager_capacity_status_dynamic_read_response_demux_same_id_reject_pipeline_cli`.

## Report Contract

Covered reports use:

```text
same_id_ordering.dynamic_id_reuse_policy.<family>.implementation_status:
  generated_single_active_reject
same_id_ordering.dynamic_id_reuse_policy.<family>.enforcement:
  generated_idle_or_releasing_assertions
same_id_ordering.dynamic_id_reuse_policy.<family>.assertion_enforcement:
  runtime_assertion
same_id_ordering.dynamic_id_reuse_policy.<family>.response_demux_covered:
  true
same_id_ordering.dynamic_id_reuse_policy.<family>.single_active_covered:
  true
same_id_ordering.dynamic_id_reuse_policy.<family>.single_active_request_policy:
  idle_or_releasing
```

The report also lists the response-demux mode, transaction-completion source,
covered dynamic transaction, generated idle-or-releasing assertion, generated
response active-match assertion, and generated completion-active assertion.

It continues to report:

```text
accepted_same_id_reuse: false
request_conflict_policy: no_active_same_id
generated_queue_behavior: false
generated_scoreboard_behavior: false
```

Single-active reports intentionally do not use the `.438` multi-active fields
`generated_no_active_same_id_assertions` or
`generated_active_id_uniqueness_assertions`, because one-dynamic-transaction
families do not generate sibling no-active-same-ID or active-ID uniqueness
assertions.

## Residue

The covered family removes `same_id_ordering` from `response_demux.residue`.
Unrelated residue remains explicit; for example, the read single-beat public
sample still leaves `read_data_interleaving` and `bursts` in
`response_demux.residue`.

`same_id_ordering.residue` removes `dynamic_id_same_id_ordering` only when all
selected dynamic policy families are covered by generated enforcement.

## Deferred Work

One-dynamic mixed dynamic/static response-demux still fails closed at the
existing generated multi-active no-active-same-ID diagnostic. Dynamic
issue-order queues, dynamic scoreboards, request arbitration widening, direct
backend behavior, backend-language variants, VHDL behavior, and new generated
HDL remain separate exact-owner work.

## Validation

Validation for `.442` included syntax checks for the touched Perl module,
support registry, and focused tests; guarded direct probes for write `BID`,
read single-beat `RID`, and read burst-last `RID && RLAST`; guarded
`--emit-schedule-json`, strict `--check --json`, and strict
`--emit-semantic-json` probes for the new public sample; and guarded regression
corpus accounting.

The broad guarded `t/1437` run was stopped after it stayed silent for an
extended interval, and the guarded focused `t/1438` run hit existing mixed
dynamic/static expectation failures before the host RAM guard stopped it at the
88% cutoff. Targeted `.442` probes passed; no unguarded run or cutoff raise was
used.

## Rollback

Rollback for `.442` is the implementation commit. Reverting it removes the
single-active report/acceptance mapping, public sample/support-accounting
entry, focused tests, docs, fact card, task-tree advancement, and resume
pointer update while restoring the previous fail-closed behavior for
single-active dynamic same-ID reject over response-demux.
