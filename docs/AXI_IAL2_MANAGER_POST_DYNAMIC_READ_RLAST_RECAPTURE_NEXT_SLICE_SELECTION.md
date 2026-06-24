# AXI IAL2 Manager Post Dynamic Read RLAST Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.373`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.373` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.374`, readiness audit for multiple
all-dynamic same-cycle release-and-recapture after the single-active dynamic
write, read single-beat, and read burst-last recapture contracts shipped.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence

The smallest same-cycle release-and-recapture contracts now have generated
behavior:

- single-active dynamic write `BID`;
- single-active dynamic read single-beat `RID`; and
- single-active dynamic read burst-last `RID && RLAST`.

Those contracts all have one selected dynamic ID/busy slot and no sibling
request arbitration. They share the same core update shape: capture only when
idle, release only when no same-cycle request is present, and add a separate
release-and-recapture update that uses the pre-update selected ID for response
matching while capturing the next request ID for the next cycle.

The next closest residue is the multiple all-dynamic response-demux family.
It is closer than mixed dynamic/static and static busy recapture because it
still has dynamic selected-ID/busy ownership only, but it is materially larger
than the single-active shape:

- multiple dynamic write and read single-beat demux already report onehot0
  same-cycle request policy;
- multiple dynamic read burst-last demux already preserves raw matched
  non-last read beats and completes only on `RID && RLAST`;
- active dynamic selected IDs must stay pairwise unique;
- each dynamic transaction emits request no-active-same-ID checks; and
- ambiguous response matching is prevented by active-match, unique-match, and
  completion-active assertions rather than queues or scoreboards.

The current generated multi-dynamic contracts therefore cannot be widened by
simply copying the single-active release-recapture helper. A readiness audit
must decide whether recapture is per-transaction under the existing onehot0
request boundary, whether sibling completion/request interactions need a
contract selection first, and how the report/assertion vocabulary should
preserve active-ID uniqueness.

## Selected .374 Scope

`.374` should be an audit-only slice for multiple all-dynamic same-cycle
release-and-recapture readiness. It should read:

- `.373`, `.372`, `.371`, `.370`, `.368`, and `.365`;
- `.247` multiple dynamic write response-demux behavior;
- `.251` multiple dynamic read single-beat response-demux behavior;
- `.255` multiple dynamic read burst-last response-demux behavior;
- current dynamic capture/release normalizers, generated assertion helpers,
  report vocabulary, static-rule prose, and focused t/1437/t/1438
  expectations;
- current multiple dynamic read-data, burst-length, runtime-validation, and
  multi-beat deferrals;
- mixed dynamic/static and static busy recapture residue; and
- support accounting, README, ROADMAP_V2, mdBook, Memory, task tree, and
  Knowledge Map.

The audit should decide:

- whether the first multiple-dynamic recapture contract should start on write,
  read single-beat, read burst-last, or a shared prerequisite;
- whether the existing public samples and mode strings remain unchanged;
- whether onehot0 same-cycle request policy remains the boundary for the
  first multiple-dynamic recapture behavior;
- how per-transaction release-and-recapture rules, report fields, and
  assertion names should be spelled;
- how active selected-ID uniqueness, request no-active-same-ID checks,
  unique-match assertions, and completion-active assertions are preserved;
- how burst-last matched non-last beats and final `RLAST` completion interact
  with recapture;
- which read-data, burst-length, runtime-validation, and multi-beat consumers
  are preservation-only for the first behavior owner;
- focused validation and preservation gates, including RAM-guard constraints;
  and
- rollback, docs, Knowledge Map, direct-backend deferral, and VHDL deferral.

## Non-Goals

`.374` should not implement behavior unless it explicitly creates a later
implementation leaf. It should not change parser, generator, PPIF samples,
support-accounting catalog, tests, schedule/check/semantic JSON, HDL output, or
runtime behavior.

Mixed dynamic/static recapture, static busy recapture, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Validation

Closeout for `.374` should be documentation/doctrine oriented unless the audit
discovers a required cleanup owner:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Guarded `fsmgen` schedule probes for the existing multiple dynamic write,
read single-beat, and read burst-last samples are useful if host memory permits,
but `.374` should not force heavyweight probes outside the RAM guard because it
is an audit slice.
