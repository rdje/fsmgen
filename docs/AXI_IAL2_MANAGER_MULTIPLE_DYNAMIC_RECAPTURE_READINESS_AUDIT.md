# AXI IAL2 Manager Multiple Dynamic Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.374`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.374` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.375`, generated support-detail prose
alignment for the shipped single-active dynamic read burst-last
release-and-recapture behavior, before selecting any multiple-dynamic
recapture contract.

The audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Audit Findings

The existing multiple all-dynamic response-demux family is the nearest broader
same-cycle release-and-recapture candidate after the single-active write,
read single-beat, and read burst-last recapture contracts.

The current generated multiple dynamic shapes have these shipped contracts:

- `ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif`
  reports `bounded_multi_dynamic_write_bid_demux_contract`;
- `ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif`
  reports `bounded_multi_dynamic_read_rid_demux_contract`; and
- `ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif`
  reports `bounded_multi_dynamic_read_rid_rlast_demux_contract`.

Guarded schedule probes confirmed that all three still report:

- onehot0 same-cycle dynamic request policy;
- active dynamic selected-ID uniqueness;
- per-transaction request-not-busy assertions;
- per-transaction request no-active-same-ID assertions;
- response active-match assertions;
- pairwise response unique-match assertions; and
- per-transaction completion-active assertions.

The implementation agrees with the report surface. Multiple dynamic states
carry `capture_rule` and `release_rule`, but they do not carry
`same_cycle_release_recapture_policy`, `release_recapture_rule`, or
`release_recapture_source`. The generated release-recapture helper currently
emits rules only for states marked with `single_active_dynamic_write` or
`single_active_dynamic_read`. Multiple dynamic release-only rules still release
on `completion && busy` without excluding same-cycle requests.

That means the multiple-dynamic contract needs a public contract selection
before behavior changes. The future contract should decide whether the first
behavior owner starts on write, read single-beat, read burst-last, or a shared
multi-dynamic prerequisite.

## Blocking Alignment Finding

The guarded schedule probes also exposed stale generated support-detail prose.
The support detail still says single-active dynamic read burst-last
`RID/RLAST` response matching is supported "without release-and-recapture" and
still lists same-cycle recapture as future outside only the single-active
dynamic write and read single-beat shapes.

That is now stale after `IAL2-FEATURE-COMPLETENESS-FRONTIER.372`, which shipped
single-active dynamic read burst-last release-and-recapture. The stale text is
generated report/support metadata, not just an external document. It should be
aligned before selecting a broader multiple-dynamic recapture contract, because
the next contract selection will depend on the same support/prose surface to
describe what remains future work.

## Selected .375 Scope

`.375` should align the generated dynamic transaction-ID support-detail prose
with the shipped `.372` behavior. It should:

- remove the stale "without release-and-recapture" wording for single-active
  dynamic read burst-last `RID/RLAST` response matching;
- describe single-active dynamic read burst-last response matching as including
  same-cycle release-and-recapture;
- update the remaining future-owner sentence so same-cycle recapture is future
  only outside single-active dynamic write, single-active dynamic read
  single-beat, and single-active dynamic read burst-last demux;
- update focused support-detail expectations;
- refresh README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map;
  and
- run focused syntax/report checks plus documentation/doctrine gates.

## Deferred Boundaries

After `.375`, the next selector should return to multiple all-dynamic
recapture contract selection. Multiple dynamic write recapture, multiple
dynamic read single-beat recapture, multiple dynamic read burst-last recapture,
mixed dynamic/static recapture, static busy recapture, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners until selected.

## Validation

The audit used direct code/report/test inspection and these guarded probes:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
```

Closeout for `.374` remains documentation/doctrine oriented:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```
