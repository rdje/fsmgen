# IAL2 Post-Exact-Three Paired Composition Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.817` selects one bounded, data-only
implementation leaf:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.818` will add the matching profile alias
`ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb`
as a byte-identical mirror of the shipped generic `.ppif` source.

The selected alias is the smallest adjacent completion of the current
SystemVerilog-backed IAL2 surface. It does not select the two-subordinate
exact-three topology, a new BUSY policy, HIAL/VIAL architecture, VHDL,
verification generation, or decision `0020` behavior.

## Reconciled Boundary

The clean predecessor `00d71114d` ships the generic one-subordinate
exact-three paired source through the existing requester, subordinate,
interconnect, and aggregate-top generators. Current accounting is:

- 323 protocol fixtures;
- 364 supported-smoke plus strict fixtures;
- 47 AHB paths split 24 `.ppif` / 23 `.ahb`;
- exact three IAL1 artifacts and four IAL0 artifacts;
- normalized semantic and read-only MCP parity; and
- assertion-enabled t1531 runtime at five presentations, four accepted data
  beats, one BUSY episode, three qualified BUSY events, one resumed `SEQ`, and
  final storage `0x44332211`.

Decisions `0015` and `0016` keep `.ahb` as a vocabulary/profile alias over the
same IAL2 model and `.ppif` as the canonical generic container. The current
AHB family consistently closes a shipped generic behavior with a byte-identical
profile alias where the suffix path needs no parser or generator change.

## Disposable Alias Probe

A repository-local, same-volume one-file candidate copied the generic bytes to
the future `.ahb` basename. The probe was removed after exact census (one file,
4,983 bytes) and left no residue.

The existing suffix path produced:

- strict check success with zero diagnostics, module `ahb_tb`, three children,
  28 signals, and intentionally unmatched support accounting before the future
  corpus entry exists;
- report schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1` with the
  unchanged source object and intent name;
- exact IAL1 artifacts `amba_requester_busy_insert_three.isf`,
  `ahb_lite_subordinate_byte_lane_hburst_seq.isf`, and
  `ahb_interconnect.isf`;
- exact IAL0 artifacts `amba_requester_busy_insert_three.fsm`,
  `ahb_lite_subordinate_byte_lane_hburst_seq.fsm`, `ahb_interconnect.fsm`, and
  `ahb_tb.fsm`;
- requester `before_beat=2` and `beats=3`, subordinate and propagated
  `parks_on=[busy]`, and one-hot accepted-subordinate response ownership;
- normalized semantic success with module `ahb_tb`, source root `top`, three
  children, and no diagnostics; and
- removal of only `ahb_profile_alias_deferred`,
  `ahb_aggregate_profile_alias_deferred`, and
  `ahb_subordinate_profile_alias_deferred`, while substantive AHB residue
  remains.

No parser, generator, scheduler, report, semantic, MCP, HDL, or runtime repair
is required for the alias.

## Why This Owner Is Next

The roadmap still names the SystemVerilog-backed IAL2 path as the current
feature-completeness priority. The alias closes a one-file generic/profile
pair through already-proven machinery and shared runtime. Every alternative is
larger or separately gated:

- a two-subordinate exact-three composition needs a new public contract and
  two-window runtime proof;
- counts above three need counter-width/range readiness rather than a data-only
  source;
- policy-selected, runtime-selected, random, or multiple-point BUSY insertion,
  distinct local bus-BUSY status, wider/indefinite bursts, and optional signals
  add new semantics;
- generic rule/transaction selector priority has a separate proposed
  correctness owner;
- decision `0020` remains a director-owned future transaction-layer horizon;
  and
- HIAL/VIAL is high-leverage architecture work, but its topology, typed bridge,
  portable/native split, backend parity, simulator availability, migration,
  and large-design gates form a broad audit. Its task was deliberately parked
  without pivoting the IAL2 priority, so selecting it ahead of the immediately
  ready alias would not be the smallest roadmap-aligned step.

The HIAL/VIAL requirement remains durable and proposed. A later clean selector
can activate its architecture audit after adjacent IAL2 closure or an explicit
director priority change.

## Verilator Capability Clarification

The director-approved VIAL validation boundary is preserved rather than used
as a reason to overclaim the current tool. Verilator's official documentation
describes it as a compiler rather than a traditional simulator. Its generated
model is evaluated explicitly; with `--timing`, supported delays, event
controls, waits, forks, and delayed processes participate in a timing-aware
evaluation loop. Verilator therefore provides event-capable compiled
simulation for its supported subset, but it is not the full-language/UVM
authority represented by a traditional general-purpose event-driven
simulator.

VIAL must retain separate capability profiles:

- portable-fast SystemVerilog subset validation with Verilator;
- authoritative advanced SystemVerilog/UVM validation with a separately
  capability-qualified simulator; and
- separately qualified VHDL and mixed-language validation.

Primary references:

- <https://verilator.org/guide/latest/overview.html>
- <https://verilator.org/guide/latest/languages.html#time>
- <https://verilator.org/guide/latest/connecting.html#wrappers-and-model-evaluation-loop>

## Selected `.818` Contract

The implementation must:

1. add only the byte-identical `.ahb` mirror of the generic exact-three paired
   source;
2. register support identity
   `intent.ahb_profile_alias_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park`,
   coverage
   `ial2_ahb_profile_alias_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli`,
   source kind `ial2_profile_alias`, supported-smoke plus strict status, module
   `ahb_tb`, semantic root `top`, and three children;
3. move accounting to 324 protocol / 365 supported-smoke plus strict / 48 AHB
   paths split 24 `.ppif` / 24 `.ahb`;
4. add focused t1532 proof for byte parity, parse/report identity, alias-residue
   removal, strict check, schedule, exact artifacts, normalized semantics, real
   read-only and shell-disabled MCP, repository-local outdir, HDL verification,
   diagnostics, and generic/existing-alias preservation;
5. reuse t1531 as the shared assertion-enabled behavioral proof rather than
   compile and run a duplicate testbench; and
6. synchronize support/language/capability/current docs, mdBook, task tree,
   Memory, behavior/fact continuity, and Knowledge Map.

The leaf must stop and select a smaller prerequisite if the tracked alias
disproves the disposable probe. It must not alter parser/generator algorithms,
semantic/MCP APIs, runtime behavior, ports, artifacts, exact-three semantics,
other sources, other aliases, backends, VHDL, HIAL/VIAL activation, or decision
`0020`.

## Validation And Resource Boundary

The selector itself changes documentation and task ownership only. Its gate is
Knowledge Map generation/check, mdBook build and exact cleanup, focused
current-surface/task-owner tests, all doctrine checks, and diff/path checks.
Heavy commands use the authorized `--host-max-pct 100
--process-max-rss-mb 4096` profile. Capacity truth uses the Stats-compatible
Mach-page formula and reports kernel pressure separately; the RAM guard's
heuristic percentage is not capacity truth. All disposable data remains under
repository-derived same-volume paths.

## Rollback

Rollback of this selector removes only the `.818` pending node and this
selection record/fact, returns the frontier to `.817`, and leaves the shipped
323/364/47 behavior untouched. A later `.818` rollback must remove the alias,
support entry, focused test, and current-doc additions together, restoring the
generic exact-three paired source as the sole member of that pair.
