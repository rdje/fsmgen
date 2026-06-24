# AXI IAL2 Manager Dynamic Same-ID Policy Metadata-First Slice

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.436`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.436` ships metadata-first parser/report
support for the selected dynamic same-ID reject policy:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse reject)))
```

The policy is AXI-manager-capacity-status metadata only in this slice. It does
not generate new dynamic same-ID enforcement, response-demux mapping, queues,
scoreboards, HDL behavior, VHDL behavior, or direct backend behavior.

## Source Contract

Each `same-id-ordering` family arm may now contain:

- `(concrete-id-reuse reject)`;
- `(concrete-id-reuse issue-order-queue)`;
- `(dynamic-id-reuse reject)`;
- both a concrete policy clause and the dynamic reject policy clause.

The parser rejects empty family arms, duplicate `dynamic-id-reuse` clauses,
duplicate `concrete-id-reuse` clauses, unsupported dynamic values such as
`scoreboard`, and unsupported concrete values outside the existing
`reject`/`issue-order-queue` set.

The public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif
```

Its support-accounting entry is:

```text
intent.ppif_axi_manager_capacity_status_dynamic_same_id_reject_policy
```

## Report Contract

Dynamic-only policy reports:

```yaml
same_id_ordering:
  mode: dynamic_id_reuse_policy
  generated_behavior: false
  dynamic_id_reuse_policy:
    read:
      policy: reject
      implementation_status: selected_not_generated
      enforcement: not_generated
      accepted_same_id_reuse: false
      request_conflict_policy: no_active_same_id
      generated_queue_behavior: false
      generated_scoreboard_behavior: false
  residue:
    - dynamic_id_same_id_ordering
```

When a family arm contains both concrete and dynamic policy clauses, the report
uses:

```text
same_id_ordering.mode: id_reuse_policy
```

and carries both `concrete_id_reuse_policy.<family>` and
`dynamic_id_reuse_policy.<family>` without changing the existing concrete
policy behavior.

## Fail-Closed Boundaries

The implementation keeps the following boundaries explicit:

- `dynamic-id-reuse reject` requires transactions metadata.
- The selected family must contain at least one same-family dynamic
  transaction.
- A concrete-only same-ID policy does not cover dynamic transaction-ID
  metadata; sources must select `dynamic-id-reuse reject` for dynamic same-ID
  policy metadata.
- Dynamic response-demux plus same-family `dynamic-id-reuse reject` remains
  fail-closed until a later owner maps the selected policy to generated
  no-active-same-ID assertion enforcement.
- Dynamic `issue-order-queue` and dynamic `scoreboard` remain unsupported
  future exact owners.

## Generated Behavior

For the public sample, generated IAL1/IAL0 behavior remains identical to the
existing metadata-only dynamic transaction-ID sample. The new metadata changes
the capacity/status report and support accounting, not the scheduled FSM or
HDL.

Generated dynamic same-ID enforcement is deliberately deferred. The next owner
should audit how to map selected `dynamic-id-reuse reject` policy onto already
generated dynamic/mixed response-demux no-active-same-ID and active-ID
uniqueness assertions without weakening current diagnostics or overclaiming
coverage.

## Validation

Validation for `.436` included:

- Perl syntax checks for the PPIF adapter, AXI manager capacity/status
  generator, support corpus, and focused tests;
- focused support-accounting test `t/248-regression-corpus-accounting.t`;
- guarded `fsmgen --emit-schedule-json`,
  `fsmgen --check --json`, and `fsmgen --emit-semantic-json` probes for the
  public dynamic same-ID reject sample;
- compact in-memory probes for the dynamic same-ID report shape and
  fail-closed diagnostics.

The full `t/1436` and `t/1437` focused test files were attempted under
`scripts/run_with_ram_guard.sh`; both were terminated by the guard when host
memory crossed the configured cutoff. No failure was emitted by the rerun of
`t/1437` before termination after the stale prose-alignment assertion was
corrected.
