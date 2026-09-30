# 0051 — VIAL VHDL uses a provider-free core and OSVVM-qualified tier

- Date: 2026-08-01
- Type: verification backend/runtime architecture
- Status: accepted
- Extends: `0032`, `0034`, `0036`, `0037`, `0039`, `0043`
- Evidence owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.14`

## Context

VIAL needs a VHDL backend that preserves the same target-neutral execution
meaning and normalized results as its portable SystemVerilog backend. The
existing `vhdl-observation-package` output cannot serve that role: it is an
inert metadata package with no entity, architecture, process, driver, sampler,
scoreboard, coverage, analyzer, or runtime claim.

Advanced VHDL verification can be implemented through OSVVM or UVVM, but
making either library mandatory for core VIAL execution would let a provider
API sit too close to the semantic authority. Selecting both would duplicate
adapters and qualification matrices for overlapping randomization, coverage,
scoreboard, reporting, synchronization, and verification-component services.

The exact current open-source evidence is GHDL 6.0.0 tag `v6.0.0`, annotated
tag object `ecfa637741fe259d284dc0b20936acc15bba44df`, peeled commit
`e589c698c351369ac5bcfe7abe1f1152ac5d4727`; OSVVM `2026.05`, commit
`2f7c391051dfb11890fa4bdbda9918d1db492250`; and UVVM `2026.03.20`, commit
`4f1e13bf96dca5571597ca7416b9340e9de94efd`. GHDL is not installed locally,
so these are selection identities rather than executed capability evidence.

GHDL documents partial VHDL-2008 and PSL implementation. A successful future
run therefore must identify `--std=08`, the exact build backend and exercised
features instead of implying complete IEEE 1076-2008 or PSL support.

## Decision

Select a two-tier VHDL architecture:

1. `vhdl_portable_ghdl` is a provider-free IEEE VHDL-2008 core. It statically
   lowers the bounded VIAL execution plan to standard packages, a generated
   scheduler/testbench, declared probe adapters, closed trace output, and
   normalized results. GHDL 6.0.0 is its first exact qualification tool.
2. `vhdl_osvvm_qualified` is the advanced methodology tier. It selects OSVVM
   2026.05 for negotiated constrained-random, coverage, scoreboard, reporting,
   synchronization, data-structure, and verification-component mappings. Its
   first reference simulator tuple is OSVVM 2026.05 plus GHDL 6.0.0.

Core drivers, samplers, deterministic scenarios/fibers, models, bounded
scoreboards, portable coverage counters, substitution faults, checks, and
normalized results remain provider-free. OSVVM implements only exact
negotiated advanced/native requirements or supplementary reporting. It cannot
move logical phase barriers, rerandomize portable keyed decisions, redefine
comparison/coverage semantics, or replace the normalized result oracle.

UVVM is not the version-1 provider. Its capabilities and license are suitable,
but a second overlapping methodology has no demonstrated semantic benefit for
the first backend. A future UVVM profile requires a new decision and its own
exact profile/adapter/qualification identity.

The reference standard is IEEE 1076-2008 with `--std=08`,
`ieee.std_logic_1164`, `ieee.numeric_std`, and `std.textio`. Non-standard
arithmetic packages and VHDL-2019 constructs are excluded. Portable properties
lower to procedural checks; PSL is neither required nor claimed because the
reference tool documents a restricted subset.

Logical time uses one generated scheduler and the inactive clock edge as a
stable barrier: sample the preceding active-edge result, perform react/check in
plan order, then prepare the next active-edge drives. Process wake-up order,
delta order, and methodology-component scheduling never become VIAL meaning.

VIAL's four states drive strong `std_logic` `0/1/X/Z`. Sampling maps `L/H` to
known `0/1`, `Z` to `Z`, and `U/X/W/-` to `X`, retaining the original VHDL
symbol as representation evidence. Version 1 does not claim distinct
nine-state VIAL semantics.

Native VIAL artifacts use a new backend graph and metadata package. The public
legacy `vhdl-observation-package` command, filename, manifest, inert shape, and
no-analysis/no-PSL/no-runtime claims remain byte/schema-compatible and are not
consumed by the backend. This is a parallel versioned successor, not an
in-place promotion.

The exact mapping, artifact graph, source-map/readability rules, GHDL commands,
provider materialization, profile families, qualification gates, migration,
PSL boundary, and non-claims are canonical in the selected VHDL section of
`docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md`.

## Consequences

- Reviewable provider-free VHDL emission may progress before GHDL is locally
  available; analysis, elaboration, runtime, results, and capability discovery
  remain explicitly unqualified until the exact tool runs.
- OSVVM's recursively pinned source, gitlinks, licenses, and notices must be
  materialized and verified under a repository-derived dependency root before
  any provider-dependent gate.
- GHDL-only success does not qualify OSVVM, another simulator, complete
  VHDL-2008, PSL, formal, mixed-language execution, or the legacy package.
- OSVVM reports are useful evidence but cannot replace the normalized FSMGen
  result or applicable cross-backend parity oracle.
- `.15` may decompose emission, gallery/review, GHDL qualification, OSVVM
  integration, and provider qualification into separately committed children
  so tool availability does not block generation work.
