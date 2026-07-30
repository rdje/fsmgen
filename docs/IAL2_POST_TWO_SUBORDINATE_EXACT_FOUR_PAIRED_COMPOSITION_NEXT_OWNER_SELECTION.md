# IAL2 Post-Two-Subordinate Exact-Four Paired Composition Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.827` selects one bounded, data-only
implementation leaf:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.828` will add
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb`
as a byte-identical profile alias of the shipped generic `.ppif` source.

The matching alias is the smallest adjacent completion of the current
SystemVerilog-backed IAL2 surface. Counts above four, new BUSY semantics,
generic selector-priority work, HIAL/VIAL activation, verification generation,
VHDL, portability, scale, other protocols/backends, and decision `0020`
remain separately owned.

## Reconciled Boundary

Clean behavior commit `a62ddb705` ships generic two-window exact-four
composition through unchanged requester, subordinate, interconnect, and
aggregate-top generators. Current accounting is 331 protocol fixtures, 372
supported-smoke plus strict fixtures, and 55 AHB paths split 28 `.ppif` / 27
`.ahb`.

The source produces four IAL1 and five IAL0 artifacts, four-child `ahb_tb`, 29
top signals, two static windows, requester `before_beat=2` / `beats=4`,
width-three `4 -> 3 -> 2 -> 1 -> 0` retirement, both child and propagated
`parks_on=[busy]`, one-hot retained response ownership, and no duplicate top
`busy_flow`. Normalized semantic JSON and real read-only MCP agree on module
`ahb_tb`, root `top`, four children, and generic support identity.
Assertion-enabled t1539 proves two commands, ten presentations, eight accepted
data beats, two BUSY episodes, eight qualified BUSY events, two resumed `SEQ`
events, and final status/control `44332211` / `88776655`.

Decisions `0015` and `0016` keep `.ahb` as a vocabulary/profile alias over the
same IAL2 model and `.ppif` as the canonical generic container. The adjacent
exact-three two-window alias and exact-four one-window alias already establish
the required byte-identical, shared-runtime cadence through t1534 and t1538.

## Disposable Alias Probe

A repository-local same-volume candidate copied the exact 6,645 generic bytes
to the future `.ahb` basename. Existing suffix and lowering machinery proved:

- byte identity and identical parsed IAL1/IAL0 payloads;
- strict success with zero diagnostics, module `ahb_tb`, four children, 29
  signals, and intentionally unmatched support before the future corpus entry;
- schedule schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, exact four
  IAL1/five IAL0 artifacts, requester `before_beat=2` / `beats=4`, two
  `[0,4)`/`[4,8)` windows, both child and propagated BUSY parking, one-hot
  accepted-subordinate ownership, and no top `busy_flow`;
- normalized semantic module `ahb_tb`, source root `top`, four children, and
  intentionally unmatched support;
- real `fsmgen_semantic_introspect` parity with `query_kind=semantic`,
  `read_only=true`, `shell_access=false`, and repository-relative identity;
- successful public `--verify-hdl` validation; and
- removal of only `ahb_profile_alias_deferred`,
  `ahb_aggregate_profile_alias_deferred`,
  `ahb_subordinate_profile_alias_deferred`, and `.ahb alias exposure` wording,
  while the generic report retains them.

The exact 11-file/2,180,377-byte candidate workspace was removed without
residue. Only the pre-existing 491-byte `.artifacts/tmp/xcrun_db` cache remains.
No parser, generator, scheduler, report, semantic, MCP, HDL, simulator, or
runtime repair is required.

## Why This Owner Is Next

The roadmap still prioritizes SystemVerilog-backed IAL2 feature completeness.
This alias closes one shipped generic/profile pair through proven machinery,
changes no generated behavior, and reuses t1539 runtime. Every competing owner
is larger or independently gated:

- counts above four require a new public range/counter-width readiness audit;
- policy-selected, runtime-selected, random, or multiple-point BUSY insertion,
  distinct bus-BUSY status, wider/indefinite bursts, and optional signals add
  new semantics;
- generic rule/transaction selector priority has a separate correctness tree;
- decision `0020` remains an inactive transaction-layer horizon;
- HIAL/VIAL and verification generation require broad layer, bridge, backend,
  simulator-profile, migration, and very-large-design architecture work;
- VHDL/mixed-language portability has independent qualification gates; and
- large-design scale and other protocol/backend lanes are not prerequisites
  for this proven data-only sibling closure.

HIAL/VIAL remains durable and proposed. Verilator continues to qualify the
portable-fast supported subset as event-capable compiled simulation, not as a
traditional full-language event-driven SystemVerilog/UVM authority. Advanced
VIAL still requires a separately qualified full-language/UVM simulator, with
VHDL and mixed-language profiles qualified independently.

## Selected `.828` Contract

Implementation `.828` must:

1. add only the byte-identical `.ahb` mirror of the shipped generic source;
2. register support identity
   `intent.ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park`,
   coverage
   `ial2_ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli`,
   source kind `ial2_profile_alias`, supported-smoke plus strict status, module
   `ahb_tb`, semantic root `top`, and four children;
3. preserve exact four IAL1/five IAL0 artifacts, 29 signals, two address
   windows, width-three `4 -> 3 -> 2 -> 1 -> 0`, both BUSY-parking contexts,
   one-hot response ownership, no top `busy_flow`, and all substantive residue;
4. move accounting to 332 protocol / 373 supported-smoke plus strict / 56 AHB
   paths split 28 `.ppif` / 28 `.ahb`;
5. add
   `t/1540-ial2-ahb-two-subordinate-exact-four-paired-busy-composition-profile-alias.t`
   for byte/parse/report/residue/strict/schedule/artifact/normalized-semantic/
   real read-only MCP/repository-local output/HDL-verifier/diagnostic and
   adjacent generic/profile preservation parity;
6. retain t1539 as the sole shared assertion-enabled runtime and add no second
   testbench or simulation; and
7. synchronize support/language/capability/current docs, mdBook, task tree,
   Memory, behavior/fact continuity, HIAL/VIAL deferral, and Knowledge Map.

The leaf must stop and select a prerequisite if tracked alias behavior
disproves the disposable probe. It must not change parser/generator algorithms,
reports/schemas, semantic/MCP APIs, runtime/HDL behavior, ports, existing source
bytes, other aliases, BUSY semantics, backends, VHDL, verification generation,
HIAL/VIAL activation, scale, or decision `0020`.

Clean selector commit `bc29c2e49` activates only `.828`. Activation adds no
alias, support entry, t1540, artifact, API, or runtime behavior; current
accounting remains 331/372/55 split 28 `.ppif`/27 `.ahb`.

## Validation And Resource Boundary

The selector changes documentation and task ownership only. Focused
current-surface/backlog/path tests, Knowledge Map generation/check, mdBook build
with exact cleanup, diff/path checks, and all doctrine gates close the slice.
Heavy commands use authorized `--host-max-pct 100 --process-max-rss-mb 4096`.
Capacity truth uses the Stats-compatible Mach-page formula, with kernel pressure
reported separately. All disposable data remains under repository-derived
same-volume paths.

## Rollback

Rollback of selection removes this record/fact and pending `.828` handoff. It
leaves the generic source, t1539 runtime, current 331/372/55 accounting,
existing generators and aliases, semantic/MCP APIs, HIAL/VIAL proposal, and
decision `0020` unchanged.
