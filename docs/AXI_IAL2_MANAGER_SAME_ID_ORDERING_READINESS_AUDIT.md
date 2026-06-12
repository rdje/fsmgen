# AXI IAL2 Manager Same-ID Ordering Readiness Audit

This note records the readiness audit outcome for
`IAL2-FEATURE-COMPLETENESS-FRONTIER.34`.

## Inputs Read

The audit reviewed the shipped AXI manager IAL2 path and the current
IAL1/IAL0/SystemVerilog substrate:

- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md`
- `docs/book/src/13g-rules.md`
- `docs/book/src/14-feature-backlog.md`
- `ROADMAP_V2.md`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`
- `ppif/axi_manager_capacity_status_response_demux.ppif`

The current generated report was inspected with:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
```

## Findings

The AXI evidence says same-ID read responses and same-ID write responses are
ordered by issue order inside their response families. A complete AXI manager
therefore eventually needs per-ID issue-order queues or scoreboards when it
allows multiple outstanding transactions to share an ID.

The current generated auto-ID lifecycle is more conservative than that full
model. Its allocator uses first-free pool order and treats a pool ID as free
only when no active transaction state is busy with that selected ID. It also
emits runtime assertions for no-ID-available, inactive completion, and
same-family simultaneous auto-ID requests. The generated write `BID` demux
then matches each response against active selected IDs and asserts that an
accepted response matches at most one active auto-ID write transaction.

That means the current auto-ID write-demux path is ready for a bounded
"same-ID ordering by avoidance" contract: for generated auto-ID families,
FSMGen can make the unique-active-ID invariant explicit and machine-readable
without building a per-ID response queue. This is a legal conservative first
boundary because if two active generated auto-ID transactions cannot share an
ID, there is no same-ID response-order queue to maintain for that generated
auto-ID subset.

The existing substrate is sufficient for the first boundary:

- generated IAL1 storage already carries selected-ID and busy state;
- IAL1 assertions already lower through `.fsm` `+assert` carriers;
- SystemVerilog assertion emission already covers equality, implication,
  conjunction, and negation shapes used by the generated checks;
- no new public `.ppif` syntax is needed;
- no IAL1/IAL0/SystemVerilog prerequisite is required before the first slice.

## Selected Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.35`:

```text
Implement bounded AXI auto-ID same-ID avoidance assertions and report metadata.
```

The first implementation should formalize the existing allocator constraint
instead of introducing per-ID response queues. It should:

- emit pairwise generated assertions for active auto-ID transaction states in
  the same family, proving that two busy transactions do not hold the same
  selected ID;
- add machine-readable `same_id_ordering` report metadata with an
  `avoid_same_id_concurrency` strategy, covered families, generated assertion
  names, source anchors, and residue;
- update report residue so the generated auto-ID lifecycle and generated
  write response-demux path no longer leave `same_id_ordering` as residue for
  the covered auto-ID write-demux subset;
- keep `id_response_rule_engine.residue` honest for concrete-ID same-ID
  cases, read `RID` demux, and future per-ID ordering queues;
- preserve generated `.isf`, `.fsm`, SystemVerilog, check JSON, semantic JSON,
  mdBook, Knowledge Map, task tree, and memory synchronization.

## Non-Goals

The selected implementation must not claim full AXI same-ID ordering. These
remain future exact-owner work:

- per-ID issue-order queues or response scoreboards;
- multiple outstanding authored concrete-ID transactions sharing an ID;
- read `RID` response demux;
- read-data interleaving/reassembly;
- bursts and last-beat tracking;
- queued/blocking policy;
- profile aliases or full AXI manager syntax;
- VHDL backend or VHDL reroute behavior.

## Validation Gates For `.35`

Focused implementation gates should include:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
prove -Iperl t/1436-ial2-ppif-parser-cli.t
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_response_demux.ppif
```

Continuity gates should include:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

## Rollback Boundary

This audit is documentation and task-tree state only. If the implementation
uncovers a need for broader queues, new source syntax, or new IAL1/IAL0/SV
substrate, that work must be selected by a later task-tree leaf before code
changes.
