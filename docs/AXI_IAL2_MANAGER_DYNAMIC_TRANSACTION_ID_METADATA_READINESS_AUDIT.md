# AXI IAL2 Manager Dynamic Transaction-ID Metadata Readiness Audit

Task owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.218`

Status: completed on 2026-06-22. This audit selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.219`, direct metadata-first
`(id dynamic)` parser/report support.

## Decision

Implement the selected transaction-local dynamic transaction-ID contract
directly in `.219`. The implementation scope is metadata only:

- accept `(id dynamic)` in PPIF transaction envelopes;
- normalize it as a dynamic/user-supplied transaction ID for the named
  positive-width ID family;
- report the dynamic metadata selected by `.217`;
- fail closed for behavior clauses that would require dynamic response
  matching, per-ID queues, scoreboards, or capture state.

No parser, generator, sample, support-accounting, test, generated artifact,
validation, or HDL behavior changed in `.218`.

## Evidence Read

- `.217` selected transaction-local `(id dynamic)` as the public dynamic/user
  transaction-ID spelling.
- `.216` established that dynamic same-ID issue-order queues need a public
  transaction-ID contract before parser, queue, or scoreboard behavior.
- The PPIF parser currently accepts only `(id auto)` and `(id (value N))`.
- AXI manager transaction-ID normalization currently handles only `auto` and
  concrete values.
- `id-families` already provide positive-width request and response ID signal
  names, which is the selected source for dynamic IDs.
- Transaction-event dispatch, concrete-ID assertions, auto-ID lifecycle,
  same-ID ordering, response-demux, read-data, support detail, and focused
  parser/generator tests were checked for interaction points.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map were
  checked for active-frontier and public-contract alignment.

## Live Probe Results

Current PPIF parser behavior rejects all dynamic/user spellings:

```text
(id dynamic) => Error: .ppif ... requires (id auto) or (id (value N))
(id user) => Error: .ppif ... requires (id auto) or (id (value N))
(id (signal axi0_arid)) => Error: .ppif ... requires (id auto) or (id (value N))
(id (dynamic)) => Error: .ppif ... requires (id auto) or (id (value N))
```

The current transaction report distinguishes only auto and concrete IDs:

```text
write w0 policy=auto
read r0 policy=concrete value=3 family=read width=4
```

The policy-only issue-order probe remains non-generated:

```text
generated=0 policy=issue_order_queue enforcement=admitted_request_boundary accepted=0 queue=0 residue=[concrete_id_same_id_ordering,per_id_issue_order_queues]
```

Generated concrete multi-group queue-head samples still report counted
admitted-request guard alignment and concrete-ID group request assertions:

```text
read status=generated_read_burst_last_queue_head_demux queues=2 guard=counted_request_set_capacity_fit scope=concrete_id_group residue=[per_id_issue_order_queues]
write status=generated_write_bid_queue_head_demux queues=2 guard=counted_request_set_capacity_fit scope=concrete_id_group residue=[per_id_issue_order_queues]
id_engine=concrete_id_assertions inputs=[axi0_arid,axi0_rid] checks=2 residue=[auto_id_allocation,id_release,same_id_ordering,response_demux]
```

## Readiness Findings

- The parser and normalizer are intentionally narrow today, which gives `.219`
  a small, reviewable additive parser/report path.
- `_report_transaction_id` is isolated and can publish the new dynamic report
  shape without changing existing auto or concrete reports.
- Positive-width `id-families` already enforce request and response ID signal
  presence; zero-width families already forbid those signals.
- Concrete-ID assertions are selected only for `policy concrete`, and auto-ID
  lifecycle behavior selects only `policy auto`; dynamic metadata can be kept
  behavior-free if same-family behavior clauses fail closed.
- Same-ID ordering, response-demux, read-data routing, and auto-ID lifecycle
  family-local behavior must not silently treat dynamic IDs as auto or
  concrete IDs.

## Selected .219 Boundary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.219` owns the first implementation slice:

- PPIF parser support for exactly `(id dynamic)`.
- Static rejection of unsupported spellings such as `(id user)`,
  `(id (signal ...))`, and `(id (dynamic ...))`.
- Normalization requiring a declared positive-width `id-families` entry for
  the transaction family, including request and response ID signals.
- Transaction-ID reports with:
  - `policy: dynamic`;
  - `family`;
  - `family_width`;
  - `request_id_source`;
  - `response_id_signal`;
  - `ownership: user_supplied`;
  - `implementation_status: selected_not_generated`.
- Fail-closed diagnostics for same-family behavior clauses that need dynamic
  matching: `auto-id-lifecycle`, `response-demux`, `read-data`, and
  `same-id-ordering`.
- A support-accounted public metadata-only PPIF sample with no same-family
  dynamic behavior clauses.
- Focused parser/generator/CLI tests and strict check, semantic, schedule, and
  HDL probes for the new metadata-only sample.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map updates.

## Preservation Matrix

| Surface | `.219` preservation requirement |
| --- | --- |
| Auto transaction IDs | Existing parser, normalization, report, auto-ID lifecycle, and generated behavior stay unchanged. |
| Concrete transaction IDs | Existing parser, normalization, concrete assertions, same-ID queue-head behavior, and reports stay unchanged. |
| Counted group-local enqueue | Counted request-set fit guards and concrete-ID group request assertions stay unchanged. |
| Dynamic matching | No capture, outstanding tracking, response matching, queues, scoreboards, or HDL behavior is introduced. |
| Behavior clauses | Same-family dynamic interactions fail closed until explicitly owned. |
| Support accounting | Only the metadata-only dynamic sample becomes support-accounted. Behavior-bearing dynamic samples remain unsupported. |
| Backend portability | The contract remains PPIF/IAL2 metadata and backend-language neutral. |

## Non-Goals

- No generated dynamic-ID arbitration.
- No dynamic same-ID issue-order queues.
- No response demux or read-data routing over dynamic IDs.
- No auto-ID pool reuse for dynamic IDs.
- No direct backend, VHDL, or verification-code behavior.
- No cleanup of unrelated support/residue wording.

## Gates

The `.218` audit closeout uses documentation and continuity gates:

- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- README docs-index numbering scan

The `.219` implementation must add focused parser/generator/CLI tests and live
metadata-only sample probes before committing.

## Rollback

`.218` is documentation and continuity metadata only. Reverting the `.218`
commit removes the audit record and restores `.218` as the active frontier; it
does not alter parser, generator, support catalog, tests, generated artifacts,
or HDL behavior.
