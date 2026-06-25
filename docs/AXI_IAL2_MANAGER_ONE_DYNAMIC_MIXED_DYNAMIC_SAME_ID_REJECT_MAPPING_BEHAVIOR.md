# AXI IAL2 Manager One-Dynamic Mixed Dynamic Same-ID Reject Mapping Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.446`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.446` ships the `.445` selected
one-dynamic mixed dynamic/static dynamic same-ID reject report/acceptance
mapping. Same-family `response-demux.<family>` plus
`same-id-ordering.<family> (dynamic-id-reuse reject)` is now accepted for
generated mixed dynamic/static response-demux shapes with exactly one dynamic
transaction plus one, two, or three pairwise-distinct concrete static
transactions in these families:

- write `BID`;
- read single-beat `RID`;
- read burst-last `RID && RLAST`.

The mapping does not add parser syntax, generated rules, storage, assertions,
HDL, runtime behavior, direct backend behavior, backend-language variants,
queues, scoreboards, support-accounting entries, public samples, or VHDL
behavior. It changes only acceptance, report metadata, and residue movement
when existing generated mixed response-demux evidence is already present.
`.446` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.447`, the next
post-mapping selector.

## Public Samples

`.446` adds no new public PPIF sample. Focused tests insert:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse reject)))
```

or the write-family equivalent into existing support-accounted mixed
response-demux samples in memory. The generated IAL1 and IAL0 artifacts are
checked against the original samples to prove the mapping is report/residue
only.

## Report Contract

Covered reports use:

```text
same_id_ordering.dynamic_id_reuse_policy.<family>.implementation_status:
  generated_mixed_static_id_exclusion_reject
same_id_ordering.dynamic_id_reuse_policy.<family>.enforcement:
  generated_static_id_exclusion_assertions
same_id_ordering.dynamic_id_reuse_policy.<family>.assertion_enforcement:
  runtime_assertion
same_id_ordering.dynamic_id_reuse_policy.<family>.response_demux_covered:
  true
same_id_ordering.dynamic_id_reuse_policy.<family>.mixed_dynamic_static_covered:
  true
same_id_ordering.dynamic_id_reuse_policy.<family>.mixed_dynamic_static_request_policy:
  onehot0_mixed_request
same_id_ordering.dynamic_id_reuse_policy.<family>.static_id_conflict_policy:
  static_concrete_ids_reserved
same_id_ordering.dynamic_id_reuse_policy.<family>.static_id_exclusion_policy:
  dynamic_id_must_not_equal_static_concrete_id
```

The report also lists:

- `response_demux_mode`;
- `response_demux_transaction_completion_source`;
- `covered_dynamic_transactions`;
- `covered_static_transactions`;
- `static_id_reservations`;
- `generated_request_availability_assertions`;
- `generated_mixed_request_onehot_assertions`;
- `generated_dynamic_request_static_id_exclusion_assertions`;
- `generated_dynamic_active_static_id_exclusion_assertions`;
- `generated_response_active_match_assertions`;
- `generated_response_unique_match_assertions`;
- `generated_completion_active_assertions`.

It continues to report:

```text
policy: reject
accepted_same_id_reuse: false
request_conflict_policy: no_active_same_id
generated_queue_behavior: false
generated_scoreboard_behavior: false
```

The mapping intentionally does not use the `.438`
`generated_no_active_same_id_assertions` and
`generated_active_id_uniqueness_assertions` fields, because the covered mixed
shapes have only one dynamic transaction. It also does not use the `.442`
`generated_idle_or_releasing_assertions` and `single_active_covered` fields,
because the mixed proof depends on dynamic-vs-static static-ID exclusion,
mixed request onehot0, response active/unique-match, and completion-active
assertions.

## Residue

The covered family removes `same_id_ordering` from
`response_demux.residue`. Unrelated residue remains explicit; read single-beat
and read burst-last mappings still leave `read_data_interleaving` and
`bursts` until those features are selected in a separate owner.

`same_id_ordering.residue` removes `dynamic_id_same_id_ordering` only when all
selected dynamic policy families are covered by generated multi-active,
single-active, or mixed static-ID exclusion reject enforcement.

## Deferred Work

Dynamic issue-order queues, dynamic scoreboards, accepted dynamic same-ID
reuse, same-cycle request widening, direct backend behavior, backend-language
variants, VHDL behavior, new generated HDL, and any new generated
rule/storage/assertion/runtime behavior remain separate exact-owner work.

## Validation

Validation for `.446` included syntax checks for the touched Perl module and
focused tests. Guarded `prove` execution for
`t/1437-axi-ial2-manager-capacity-status-generator.t` first stopped
immediately while host memory was already at 99.2% and 98.8%, above the 88%
guard cutoff and the user's 90% danger zone. After host memory dropped, a
guarded full `t/1437` run started at 66.3% host memory and ran to a real test
result; it exposed stale malformed-contract fixtures whose negative cases
still assumed one-dynamic-plus-two-static write and one-dynamic-plus-one-static
read were unsupported. `.446` updated those fixtures to the remaining
unsupported four-static boundary. A guarded rerun then started at 73.6% host
memory but was stopped when host memory reached 88.7%, and a compact guarded
PPIF adapter probe was initially stopped immediately at 99.5% host memory due
to unrelated host pressure. After that pressure cleared, compact guarded PPIF
adapter and CLI probes passed for the one-static read sample and the
three-static read burst-last sample. A final guarded full `t/1437` retry
started at 61.8% host memory but was stopped when host memory reached 89.8%.
The top memory consumers observed during blocked attempts were unrelated
processes in other workspaces or the guarded test itself. No unguarded broad
run, cutoff raise, or unrelated process termination was used.

## Rollback

Rollback for `.446` is the implementation commit. Reverting it restores the
previous fail-closed one-dynamic mixed dynamic same-ID reject boundary while
removing the report mapping, tests, docs, fact card, task-tree advancement,
and resume pointer update.
