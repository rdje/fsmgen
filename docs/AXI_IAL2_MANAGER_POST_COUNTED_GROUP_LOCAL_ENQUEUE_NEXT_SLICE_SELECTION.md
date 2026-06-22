# AXI IAL2 Manager Post Counted Group-Local Enqueue Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.215` on 2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.215`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.216`, readiness audit for dynamic
same-ID issue-order queues beyond the selected counted concrete-ID queue-head
groups.

`.214` removed the local blocker that kept group-local same-ID enqueue
widening unsafe: counted multi-group queue-head families now gate
admitted-request pulses with the same request-set capacity-fit semantics used
by the counted capacity/status matrix, and the counted request assertions are
per concrete-ID queue group. There is no immediate stale support-accounting or
public-report cleanup that must precede the next feature-completeness audit.

The remaining local AXI manager same-ID ordering residue is broader per-ID
issue-order behavior for dynamic/authored IDs outside the selected concrete-ID
queue-head groups. That boundary is too broad for direct implementation, so
the next safe owner is an audit of the public contract, report shape,
diagnostics, queue/scoreboard substrate, response matching, and lowering
prerequisites.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior.

## Evidence Read

The selector read:

- `.214` counted admitted-request guard behavior:
  `docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR.md`.
- `.213` admitted guard audit, `.212` post-counted-capacity selector, `.211`
  counted capacity substrate behavior, `.210` counted admission/capacity
  audit, and `.209` group-local enqueue readiness audit.
- Representative generated read/write multi-group queue-head reports,
  generated admitted-request boundary metadata, `same_id_ordering.residue`,
  `response_demux.residue`, and unsupported-residue wording.
- Generator code around counted request accounting, admitted request pulses,
  same-ID issue-order queue behavior, response-demux report projection, and
  unsupported-residue prose.
- Focused generator and PPIF/CLI tests that now assert
  `counted_request_set_capacity_fit`, `request_assertion_scope:
  concrete_id_group`, and mixed single concrete-group Boolean preservation.
- Support accounting, README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and
  Knowledge Map.

## Current Boundary

Compact schedule probes over representative public samples show the `.214`
boundary is now coherent:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  same_id_ordering.residue=[per_id_issue_order_queues]
  response_demux.residue=[read_data_interleaving, bursts]
  admitted guard_source=counted_request_set_capacity_fit
  request_assertion_scope=concrete_id_group

ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  same_id_ordering.residue=[per_id_issue_order_queues]
  response_demux.residue=[read_response_demux, read_data_interleaving, bursts]
  admitted guard_source=counted_request_set_capacity_fit
  request_assertion_scope=concrete_id_group

ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif
  admitted guard_source=counted_request_set_capacity_fit
  request_assertion_scope=concrete_id_group
```

The broad unsupported-residue detail now correctly distinguishes shipped
counted concrete-ID queue-head behavior from the still-deferred dynamic
arbitration boundary:

```text
dynamic user-ID arbitration beyond selected counted concrete-ID queue-head groups
```

The public support-accounting catalog already marks the representative
queue-head samples as supported smoke entries. No catalog drift was found that
needs a cleanup owner before the next audit.

## Candidate Comparison

A report/static cleanup is not selected first. `.214` already updated the
static rules, unsupported-residue detail, README, roadmap, mdBook, behavior
doc, task tree, Memory, and Knowledge Map. Live reports for the selected
counted multi-group queue-head families now expose the counted guard source
and group-local assertion scope, while non-counted and mixed auto-ID single
concrete-group directions preserve the Boolean boundary.

Another concrete queue-head expansion is not selected first. The selected
read single-beat, read burst-last, write, depth-2 multi-group, depth-3,
multiple/mixed depth-3, same-family mixed auto-ID, runtime-validation, and
multi-beat queue-head subsets are already represented in the public sample
set. The remaining `same_id_ordering.residue` on the representative generated
queue-head reports is `per_id_issue_order_queues`, not a missing concrete
queue-head response-demux/read-data sibling.

Packed burst-vector outputs and alternate full burst payload assembly are not
selected first. They are output-shape work on the read-data/burst side, while
the current local AXI ordering residue is still the more fundamental dynamic
same-ID ordering model.

Direct backend lowering, verification-output generation, VHDL, backend
language variants, public `.pif`/`.ppi`/`.axi` aliases, and full AXI manager
behavior remain separate roadmap/task-tree boundaries.

## Selected `.216` Audit Boundary

`.216` must audit dynamic same-ID issue-order queues beyond selected counted
concrete-ID queue-head groups. The audit should decide:

- what public source contract, if any, can safely describe dynamic same-ID
  ordering beyond enumerated concrete transaction groups;
- whether the first bounded owner should be a report/static contract, a
  fail-closed diagnostic, a generated per-ID queue/scoreboard substrate, or a
  narrower prerequisite;
- how dynamic request IDs, response IDs, selected transactions, outstanding
  tracking, completion release, and same-ID response ordering interact with
  existing auto-ID lifecycle and concrete queue-head behavior;
- whether existing IAL1/IAL0/SystemVerilog lowering supports the required
  queue/scoreboard state, indexed matching, and assertions;
- how reports should distinguish selected counted concrete-ID queue-head
  groups from broader dynamic per-ID issue-order queues;
- how support accounting, strict check JSON, semantic JSON, HDL generation,
  and mdBook examples would be validated if behavior is later selected.

No parser, generator, PPIF sample, support-accounting catalog, validation,
generated artifact, test, or HDL behavior belongs in `.216` unless that audit
first selects a later implementation or prerequisite leaf.

## Preservation Matrix

`.216` must preserve:

- counted request-set capacity-fit guards and per concrete-ID group request
  assertions from `.214`;
- counted capacity/status substrate and over-capacity semantics from `.211`;
- generated queue-head response-demux, read-data, burst-length,
  runtime-validation, multi-beat output-bank, and scalar status aggregation
  behavior for the selected public samples;
- same-family mixed auto-ID plus concrete queue-head behavior;
- non-counted Boolean admitted-request boundaries and family-wide request
  assertions where `.214` intentionally preserved them;
- support-accounting identities, strict check JSON, semantic JSON, and HDL
  generation for public samples;
- parser syntax, public PPIF sample set, direct backend deferral,
  verification-output deferral, VHDL deferral, and backend-language neutrality.

## Non-Goals

- Do not implement dynamic per-ID queues or scoreboards in `.215` or `.216`.
- Do not add PPIF syntax or public samples in `.215`.
- Do not change parser, generator, support accounting, tests, generated
  artifacts, validation, or HDL behavior in `.215`.
- Do not add packed burst-vector outputs or alternate full burst payload
  assembly.
- Do not change direct backend, verification-output generation, VHDL, or
  backend-language variant behavior.
- Do not bypass the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering path.

## Validation Gates

For `.215`, the required gates are documentation and continuity gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

The selector also used compact schedule probes over the read multi-group,
write multi-group, and read single-beat multi-group queue-head samples to
confirm the current report boundary. Any broad `prove` or supported-corpus
gate remains RAM-guarded.

## Rollback Boundary

Rollback for `.215` is limited to this selector record, task-tree frontier
movement, Memory, README, roadmap, mdBook, and Knowledge Map/fact-card
updates. No parser, generator, public sample, support-accounting catalog,
generated artifact, test, validation, or HDL behavior is part of this slice.
