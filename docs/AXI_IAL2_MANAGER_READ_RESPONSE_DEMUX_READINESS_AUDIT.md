# AXI IAL2 Manager Read Response-Demux Readiness Audit

Status: contract-selection boundary selected; no parser, generator, HDL, or
CLI behavior changed by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.37`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md](AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md](AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md](AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)

## Purpose

This audit checks whether bounded read `RID` response demux can be implemented
directly after generated write `BID` response demux and generated auto-ID
same-ID avoidance, or whether a smaller public contract owner must come first.

## Readiness Conclusion

Do not implement read response demux directly yet.

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.38`: a public contract-selection
slice for bounded read response demux before parser/report metadata,
generated `.isf`/`.fsm`/HDL behavior, or sample changes.

The current substrate can likely carry a narrow read demux later, but the
public `.ppif` contract still has to decide what a read `response-event`
means. AXI read responses are data-beat transfers, not just a single
write-style response packet. Full read behavior also involves `RVALID/RREADY`,
`RID`, `RLAST`, burst or last-beat ownership, and different-ID interleaving or
reassembly policy. The first bounded contract must state whether it is
single-beat/non-burst only and whether top-level `read-complete` is the raw
accepted read response event under the opt-in.

## Evidence

Shipped substrate that can support a later bounded implementation after the
contract is selected:

- ID-family metadata already records read `request-id`/`response-id` signal
  names and widths, including `ARID`/`RID`.
- Transaction metadata already records read transaction request and completion
  event names.
- Auto-ID lifecycle metadata already supports read families in principle:
  generated request-ID outputs, selected-ID/busy state, first-free allocation,
  completion-event release, and same-family request assertions are
  direction-generic.
- Concrete transaction ID assertions already prove read `ARID`/`RID` inputs
  can lower through `.isf -> .fsm -> SystemVerilog`.
- IAL1 rule-owned `(pulse TARGET)` actions can emit generated one-cycle
  transaction completion pulses.
- Generated auto-ID same-ID avoidance already covers any generated auto-ID
  family with more than one active transaction state.

Current blockers to direct implementation:

- The `.ppif` parser rejects `(response-demux (read ...))`; the current slice
  supports `(write ...)` only.
- Generator normalization rejects read `response_demux` families and requires
  a write family.
- Event-input, generated-completion, generated-signal, demux-rule,
  demux-assertion, and report helper paths are all write-shaped today.
- Existing `transactions (read ... (completion NAME) ...)` names are authored
  completion inputs unless an explicit future opt-in reclassifies them as
  generated demux pulse outputs.
- The current public surface does not say whether `read-complete` is a raw
  accepted `RVALID && RREADY` beat event, a last-beat transaction completion,
  or an already-demuxed per-transaction completion.
- The current public surface does not state the first read demux scope:
  single-beat/non-burst, burst last-beat only, or full read-data collection.

Silently treating existing read completion names as generated demux outputs
would create contract drift. The next exact owner must select the public
surface first.

## Selected Boundary For `.38`

The next selector should choose the smallest honest public contract for read
response demux. The likely shape to evaluate is additive under the existing
`response-demux` clause:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (transaction-completion generated)))
```

The selector must decide and document:

- whether `(read ...)` is accepted alongside or independently from the shipped
  `(write ...)` arm;
- whether the first bounded read demux is explicitly single-beat/non-burst;
- whether `response-event` must equal top-level `read-complete` in the first
  slice;
- whether `response-event` means the raw accepted read response transfer or a
  transaction-level last-beat event;
- whether read demux requires positive-width read `id-families` metadata;
- whether read demux requires at least one read `(id auto)` transaction;
- whether read demux requires explicit read `auto-id-lifecycle` metadata;
- whether `transaction-completion generated` reclassifies read transaction
  completion names as generated pulse outputs only under the explicit opt-in;
- what report key shape records read response-event, `RID`, generated
  completion ownership, residue, and future generated artifacts;
- what diagnostics reject ambiguous event ownership, missing metadata,
  zero-width read IDs, missing read auto-ID lifecycle, or unsupported burst and
  interleaving assumptions.

## Future Generated Behavior To Audit Later

After public contract selection and parser/report metadata, a later
behavior-bearing owner may be able to:

- declare `RID` as a generated IAL1 input with the declared read ID width;
- treat `response-event` as the raw accepted read response event for the
  selected bounded scope;
- match `response_event && busy && (RID == selected_id)` for each active
  auto-ID read transaction;
- pulse the generated transaction completion signal selected by the matching
  transaction;
- release the selected read ID from the matched generated completion pulse;
- assert unmatched/inactive read responses and ambiguous matches.

That later behavior must not claim full read-data interleaving/reassembly,
burst or last-beat tracking, per-ID response queues, or full AXI manager
behavior unless those are separately task-tree owned.

## Non-Goals

This audit does not implement or select final parser/report syntax. It also
does not implement:

- read response-demux parser/report metadata;
- generated read `RID` response-demux rules;
- generated read transaction completion pulses;
- read-data interleaving or reassembly;
- burst or last-beat tracking;
- per-ID same-ID response queues or scoreboards;
- authored concrete-ID same-ID ordering;
- queued/blocking policy;
- profile aliases or full AXI manager syntax;
- VHDL backend or VHDL reroute behavior.

## Validation Expectations

This readiness audit should run:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

The eventual contract-selection slice should run the same continuity gates.
The eventual parser/report or behavior-bearing implementation slices should
add focused generator/PPIF/CLI tests and supported corpus checks.

## Rollback

This audit changes only documentation, task-tree, Knowledge Map, roadmap,
book, and memory surfaces. Rolling it back restores `.37` as pending and does
not require reverting parser, generator, HDL, CLI, sample, or test behavior.
