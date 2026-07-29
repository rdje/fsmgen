# IAL2 Post-Two-Subordinate Exact-Three Paired Composition Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.820` selects one bounded, data-only
implementation leaf:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.821` will add
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb`
as a byte-identical profile alias of the shipped generic `.ppif` source.

The matching alias is the smallest adjacent completion of the current
SystemVerilog-backed IAL2 surface. Counts above three, new BUSY semantics,
generic selector-priority work, HIAL/VIAL activation, VHDL, verification
generation, and decision `0020` remain separately owned.

## Reconciled Boundary

Clean behavior commit `1a73bc65e` ships the generic two-window exact-three
source through unchanged requester, subordinate, interconnect, and aggregate
top generators. Current accounting is 325 protocol fixtures, 366
supported-smoke plus strict fixtures, and 49 AHB paths split 25 `.ppif` / 24
`.ahb`.

The source produces four IAL1 and five IAL0 artifacts, four-child `ahb_tb`, 29
top signals, two static windows, requester `before_beat=2` / `beats=3`, both
child and propagated `parks_on=[busy]`, and one-hot retained response
ownership. Normalized semantic JSON and real read-only MCP agree on module
`ahb_tb`, root `top`, four children, and support identity. Assertion-enabled
t1533 proves two commands, ten presentations, eight accepted beats, two BUSY
episodes, six qualified BUSY events, two resumed `SEQ` events, and final
status/control `44332211` / `88776655`.

Decisions `0015` and `0016` keep `.ahb` as a vocabulary/profile alias over the
same IAL2 model and `.ppif` as the canonical generic container. The adjacent
exact-two two-window alias and exact-three one-window alias already establish
the required byte-identical, shared-runtime cadence.

## Disposable Alias Probe

A repository-local same-volume candidate copied the exact 6,650 generic bytes
to the future `.ahb` basename. It was removed after a one-file/6,650-byte
census and left no residue. Existing suffix and lowering machinery produced:

- byte identity with the generic source;
- strict success with zero diagnostics, module `ahb_tb`, four children, 29
  signals, and intentionally unmatched support before the future corpus entry;
- schedule schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, exact four
  IAL1/five IAL0 artifacts, requester `before_beat=2` / `beats=3`, and one-hot
  accepted-subordinate ownership;
- normalized semantic module `ahb_tb`, source root `top`, four children, and
  intentionally unmatched support;
- real `fsmgen_semantic_introspect` parity with `read_only=true`,
  `shell_access=false`, and the repository-relative candidate identity; and
- successful public `--verify-hdl` validation.

Existing `.ahb` suffix handling removes only alias-specific aggregate,
requester, and subordinate residue. No parser, generator, scheduler, report,
semantic, MCP, HDL, simulator, or runtime repair is required.

## Why This Owner Is Next

The roadmap still prioritizes SystemVerilog-backed IAL2 feature completeness.
This alias closes one shipped generic/profile pair through proven machinery,
changes no generated behavior, and reuses t1533 runtime. Every competing owner
is larger or independently gated:

- counts above three require counter-width and public-range readiness;
- policy-selected, runtime-selected, random, or multiple-point BUSY insertion,
  distinct bus-BUSY status, wider/indefinite bursts, and optional signals add
  new semantics;
- generic rule/transaction selector priority has a separate correctness tree;
- decision `0020` remains an inactive transaction-layer horizon; and
- HIAL/VIAL remains a broad architecture audit covering layer topology, typed
  bridges, portable/native verification intent, backend parity, tool profiles,
  migration, and very-large-design gates.

HIAL/VIAL remains durable and proposed. Verilator continues to qualify the
portable-fast supported subset as event-capable compiled simulation, not as a
traditional full-language event-driven SystemVerilog/UVM authority. Advanced
VIAL still requires a separately qualified full-language/UVM simulator, with
VHDL and mixed-language profiles qualified independently.

## Selected `.821` Contract

Implementation `.821` must:

1. add only the byte-identical `.ahb` mirror of the shipped generic source;
2. register support identity
   `intent.ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park`,
   coverage
   `ial2_ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli`,
   source kind `ial2_profile_alias`, supported-smoke plus strict status, module
   `ahb_tb`, semantic root `top`, and four children;
3. preserve exact four IAL1/five IAL0 artifacts, 29 signals, two address
   windows, width-two `3 -> 2 -> 1 -> 0`, both BUSY-parking contexts, one-hot
   response ownership, no top `busy_flow`, and all substantive residue;
4. move accounting to 326 protocol / 367 supported-smoke plus strict / 50 AHB
   paths split 25 `.ppif` / 25 `.ahb`;
5. add
   `t/1534-ial2-ahb-two-subordinate-exact-three-paired-busy-composition-profile-alias.t`
   for byte/parse/report/residue/strict/schedule/artifact/normalized-semantic/
   real read-only MCP/repository-local output/HDL-verifier/diagnostic and
   preservation parity;
6. retain t1533 as the sole shared assertion-enabled runtime and add no second
   testbench; and
7. synchronize support/language/capability/current docs, mdBook, task tree,
   Memory, behavior/fact continuity, and Knowledge Map.

The leaf must stop and select a prerequisite if the tracked alias disproves
the disposable probe. It must not change parser/generator algorithms,
reports/schemas, semantic/MCP APIs, runtime/HDL behavior, ports, existing
source bytes, other aliases, BUSY semantics, backends, VHDL, verification
generation, HIAL/VIAL activation, or decision `0020`.

## Validation And Resource Boundary

The selector changes documentation and task ownership only. Focused
current-surface/backlog/path tests, Knowledge Map generation/check, mdBook
build with exact cleanup, diff/path checks, and all doctrine gates close the
slice. Heavy commands use authorized `--host-max-pct 100
--process-max-rss-mb 4096`. Capacity truth uses the Stats-compatible Mach-page
formula, with kernel pressure reported separately. All disposable data remains
under repository-derived same-volume paths.

## Rollback

Rollback removes only the proposed `.821` node and this selection record/fact,
returning the frontier to `.820` while leaving shipped 325/366/49 behavior
untouched. A later `.821` rollback must remove the alias, support entry,
focused test, and synchronized accounting together, restoring the generic
source as the sole two-window exact-three member.
