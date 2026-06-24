# AXI IAL2 Manager Dynamic Recapture Support Detail Alignment

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.375`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.375` aligns the generated
`dynamic_transaction_id_behavior` support-detail prose with the shipped
single-active dynamic read burst-last same-cycle release-and-recapture behavior
from `IAL2-FEATURE-COMPLETENESS-FRONTIER.372`.

The slice changes generated report/support prose and focused expectations only.
It does not change parser syntax, PPIF samples, support-accounting identities,
response-demux semantics, generated state, generated rules, assertions, HDL,
or runtime behavior.

## Alignment

The generated support detail now describes the supported single-active dynamic
read family as:

- single-beat `RID` response matching with same-cycle release-and-recapture;
  and
- burst-last `RID/RLAST` response matching with same-cycle
  release-and-recapture.

The same support detail no longer says the single-active burst-last
`RID/RLAST` shape is supported without release-and-recapture. Its future-owner
sentence now leaves same-cycle recapture as residue only outside the selected
single-active dynamic write `BID`, read single-beat `RID`, and read burst-last
`RID/RLAST` demux boundaries.

## Focused Test Coverage

The PPIF parser/CLI report-prose alignment check now reads the generated
`dynamic_transaction_id_behavior` unsupported-residue entry and verifies:

- the new single-active read single-beat plus burst-last recapture wording;
- the updated future same-cycle recapture boundary; and
- absence of the stale "without release-and-recapture" and two-boundary future
  wording.

## Deferred Boundaries

At `.375`, multiple dynamic write recapture, multiple dynamic read single-beat
recapture, multiple dynamic read burst-last recapture, mixed dynamic/static
recapture, static busy recapture, dynamic same-ID queues, scoreboards,
queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remained later
exact owners. `.378` later ships the multiple all-dynamic write `BID`
same-cycle recapture boundary; the read, mixed, static-busy, queue,
scoreboard, backend, VHDL, and full-manager boundaries remain future owners.

After this support-detail cleanup, the next owner should return to selecting
the first multiple all-dynamic release-and-recapture contract.

## Validation

Closeout for `.375` is intentionally focused on syntax, generated report prose,
and doctrine/documentation gates:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -c t/1436-ial2-ppif-parser-cli.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif
rg -n 'single-active dynamic read ID capture plus single-beat RID response matching and burst-last RID/RLAST response matching including same-cycle release-and-recapture|same-cycle recapture outside single-active dynamic write BID demux, single-active dynamic read single-beat RID demux, and single-active dynamic read burst-last RID/RLAST demux' /tmp/fsmgen_dynamic_recapture_support_detail_alignment.json
rg -n 'without release-and-recapture|same-cycle recapture outside single-active dynamic write BID demux and single-active dynamic read single-beat RID demux' /tmp/fsmgen_dynamic_recapture_support_detail_alignment.json
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```
