# AXI IAL2 Manager Post-Write Same-ID Queue Behavior Next-Slice Selection

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.109`.

Date: `2026-06-15`.

## Purpose

This selector audits the remaining AXI concrete same-ID queue-head behavior
after `.106` shipped read burst-last depth-2 queue-head demux and `.108`
shipped write depth-2 queue-head `BID` demux.

The selected next owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.110`: generated AXI read `single-beat`
same-ID queue-head behavior for exactly one duplicate concrete read-ID group
of two transactions at computed depth 2.

## Current State

The shipped behavior now covers two public sample shapes:

- read burst-last queue-head demux:
  `generated_read_burst_last_queue_head_demux`;
- write queue-head demux:
  `generated_write_bid_queue_head_demux`.

Both use the same compact one-hot transaction-slot queue representation,
admitted request pulses for enqueue, finite depth-2 queue update rules,
generated completion pulse outputs, and queue-head response-demux rules.

The live unsupported-residue text now names the remaining concrete same-ID
queue work as read `single-beat`, deeper groups, and multiple groups. It no
longer lists the bounded write shape as unsupported.

## Selection

Select read `single-beat` queue-head demux as the next behavior-bearing slice.

The selected `.110` boundary is:

- one read family only;
- `response-demux.read.response_scope` is `single-beat`;
- exactly one duplicate concrete read-ID group;
- exactly two read transactions in that group;
- computed queue depth is `2`;
- no `last-signal` is present;
- no same-family auto-ID response demux is selected;
- no read-data capture consumes the concrete queue-head demux in this slice.

The generated head match should be:

```text
read response event
&& RID == concrete ID
&& compact slot-0 transaction bit
```

The behavior is the read analogue of the shipped write no-last-signal path,
not a widening of burst-last read behavior. Transaction completion names for
the covered reads become generated pulse outputs. The raw read response event
and `RID` become generated inputs. Queue integrity and response-demux
assertions should remain concrete-ID scoped.

## Why This Slice

Read `single-beat` is the smallest remaining generated same-ID queue expansion:

- the public response-demux contract already accepts read `single-beat`;
- write queue-head behavior has already proven the optional-no-`last_signal`
  queue-head path;
- the compact one-hot depth-2 queue transition table is unchanged;
- no broader queue representation, multi-group scheduler, read-data capture,
  auto-ID coexistence, or direct-backend work is required.

## Deferred Work

The following remain outside `.110`:

- read burst-last groups deeper than two slots;
- write groups deeper than two slots;
- multiple duplicate concrete-ID groups in one family;
- same-family mixed auto-ID response demux plus concrete queue-head demux;
- read-data consumption of concrete same-ID queue-head demux;
- generalized per-ID issue-order queues;
- direct backend lowering;
- VHDL.

## Validation Gates

The `.110` implementation should add a public support-accounted `.ppif`
sample for read `single-beat` queue-head demux and prove:

- focused generator behavior and report tests;
- PPIF adapter and CLI schedule JSON coverage;
- `--check --json` and normalized semantic JSON support accounting;
- `--verify-hdl` for the new read `single-beat` sample;
- regression `--verify-hdl` for the already-shipped read burst-last and write
  queue-head samples;
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map sync;
- `scripts/check_memory_architecture.sh`, Knowledge Map check, mdBook build,
  docs path audit, and diff hygiene.

## Rollback

Rollback is documentation-only for this selector: revert this note plus the
`.109` task-tree, README, roadmap, mdBook, Memory, and Knowledge Map updates.
No parser, generator, support-accounting, sample, test, or HDL behavior is
changed by `.109`.
