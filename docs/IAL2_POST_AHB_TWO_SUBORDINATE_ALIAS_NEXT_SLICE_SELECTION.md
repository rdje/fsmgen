# IAL2 Post-AHB Two-Subordinate Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.733`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.733` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.734`, a no-behavior readiness audit for
the remaining AHB residue after the eight public bounded AHB IAL2 entrypoints
ship.

The selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Boundary

The current public AHB IAL2 surface is:

```text
ppif/ahb_requester.ppif
ppif/ahb_lite_subordinate.ppif
ppif/ahb_interconnect.ppif
ppif/ahb_interconnect_two_subordinate.ppif
ppif/ahb_requester.ahb
ppif/ahb_lite_subordinate.ahb
ppif/ahb_interconnect.ahb
ppif/ahb_interconnect_two_subordinate.ahb
```

The two-subordinate aggregate alias shipped in `.732`:

```text
entry_id: intent.ahb_profile_alias_interconnect_two_subordinate
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_two_subordinate_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
topology: one_requester_two_subordinate_static_window_interconnect
```

All eight public AHB IAL2 entrypoints lower through generated `.isf` and
generated `.fsm` review artifacts before HDL. Direct `.fsm` seeds remain
separate lower-layer coverage and do not expand the IAL2 surface.

## Why `.734` Is A Readiness Audit

After `.732`, the immediate profile-alias parity gap is closed. The remaining
AHB backlog is broader and crosses several independent axes:

- AHB completer behavior;
- broader interconnect/decode beyond the selected one-subordinate and
  two-subordinate static-window aggregate shapes;
- optional/property-gated AHB signals such as `HBURST`, `HPROT`,
  `HMASTLOCK`, and AHB5 additions;
- burst `SEQ` continuation behavior;
- byte-lane and narrow-transfer behavior;
- legacy two-bit subordinate `HRESP` compatibility;
- AHB scoreboards;
- full AHB manager behavior beyond the bounded requester;
- direct backend behavior, verification-output generation, backend-language
  variants, and VHDL.

Those axes should not be selected as implementation work directly from `.733`.
They need an explicit readiness audit to confirm source-backed facts,
current parser/generator assumptions, report/support-accounting boundaries,
diagnostics, validation cost, and whether any lower-layer substrate or docs
repair is required first.

## Selected `.734` Contract

`.734` must audit the remaining AHB residue and select the next exact owner.
It should read at least:

- `.732` two-subordinate profile-alias behavior;
- `.731` selector and `.730` generic two-subordinate behavior;
- `.728` bounded multi-subordinate readiness audit;
- requester/subordinate/interconnect behavior records and fact cards;
- current AHB mdBook surface and feature backlog;
- AHB source-backed subordinate fact inventory and imported source reference;
- PPIF adapter, AHB requester/subordinate/interconnect generators,
  support-accounting catalog, language-surface manifest, and focused AHB tests;
- README, ROADMAP_V2, task tree, Memory, Knowledge Map, and decisions
  `0014`, `0015`, `0016`, and `0018`.

The audit should determine whether the next owner is:

- a public contract selection for one narrowly bounded AHB behavior axis;
- another readiness/source-fact/substrate prerequisite;
- a report/docs cleanup required before behavior; or
- a deferral with a concrete reason.

The selected follow-on must name source paths, public syntax/report
expectations, generated artifact expectations, diagnostics, validation gates,
residue movement, rollback, docs, and VHDL deferral.

## Validation

`.733` validates only the selector state. Focused probes should confirm the
current eight-entrypoint AHB surface still strict-checks where relevant and
that `.732` support accounting remains:

```text
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ahb
```

Closeout must run Knowledge Map generation/check, mdBook build, docs path
audit, memory architecture check, diff check, and the doctrine driver. Broad or
potentially heavyweight Perl/`prove`/`fsmgen` commands must remain RAM-guarded.

## Non-Goals

`.733` and the selected `.734` audit must not add parser/generator/source
sample/support-accounting/manifest/test behavior. They must not implement
broader subordinate cardinality, multiple requesters, arbitration, bus
matrices, optional signals, burst `SEQ` support, byte-lane/narrow-transfer
behavior, legacy two-bit `HRESP` compatibility, scoreboards, full-manager
behavior, direct backend behavior, verification-output generation,
backend-language variants, AXI, APB, broader AHB behavior, or VHDL behavior.
