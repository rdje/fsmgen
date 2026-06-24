# AXI IAL2 Manager Multiple Dynamic Recapture Contract Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.376`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.376` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.377`, public contract selection for
multiple all-dynamic write `BID` same-cycle release-and-recapture.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Rationale

The multiple all-dynamic response-demux family is the nearest broader
release-and-recapture residue after the single-active dynamic write, read
single-beat, and read burst-last contracts shipped. The first broader owner
should start on the write side because it has the smallest behavioral surface:

- it uses generated per-transaction selected-ID/busy state like the read
  siblings;
- it already reports `multi_active_unique_dynamic_write_ids`;
- it already enforces onehot0 same-cycle dynamic write request policy;
- it already checks request no-active-same-ID, active dynamic-ID uniqueness,
  raw response active-match, response unique-match, and completion-active
  assertions; and
- it does not include `RLAST`, matched non-final read beats, read-data payload
  capture, raw-`ARLEN`, runtime beat-count/`RLAST`, or multi-beat output-bank
  preservation consumers.

That makes the multiple dynamic write shape the right first contract-selection
owner before read single-beat and read burst-last recapture.

## Selected .377 Scope

`.377` should select the exact public contract for the existing
support-accounted sample:

```text
ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
```

The contract selection must decide:

- whether the existing public source syntax, support-accounting identity, and
  `bounded_multi_dynamic_write_bid_demux_contract` mode remain unchanged;
- whether same-cycle dynamic write requests stay onehot0 for the first
  multiple-dynamic write recapture behavior;
- how per-transaction `release_recapture_rule`,
  `same_cycle_release_recapture_policy`, `release_recapture_source`, and
  `release_recapture_transaction` report fields should be spelled under
  `dynamic_capture.transactions[]`;
- whether every dynamic transaction's release-only rule must exclude its own
  same-cycle admitted request while preserving sibling request exclusion;
- whether per-transaction request-not-busy assertions are superseded by
  request idle-or-releasing assertions only for the transaction being
  recaptured;
- how request no-active-same-ID, active dynamic-ID uniqueness, raw response
  active-match, pairwise response unique-match, and completion-active
  assertions are preserved; and
- focused validation, rollback, docs, Knowledge Map, direct-backend deferral,
  backend-language deferral, and VHDL deferral.

## Deferred Boundaries

Multiple dynamic read single-beat recapture, multiple dynamic read burst-last
recapture, read-data/burst-length/runtime/multi-beat recapture over multiple
dynamic reads, mixed dynamic/static recapture, static busy recapture, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Validation

Closeout for `.376` is documentation/doctrine oriented:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

