# 0050 — VIAL native UVM is open-source-first with capability-gated runtime

- Date: 2026-08-01
- Type: verification backend/runtime architecture
- Status: accepted by director clarification during
  `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.12`
- Refines: `0032`, `0034`, `0036`, `0039`, `0043`

## Context

FSMGen already emits an inert passive-monitor package labelled UVM 1.2. That
compatibility output has no virtual interface, sampling, publication, driver,
agent, scoreboard, coverage, compile validation, or runtime claim. Promoting it
in place would conflate a stable legacy artifact with VIAL's first native
methodology backend.

Accellera lists UVM 2020-3.1 as its current reference implementation for IEEE
1800.2-2020. Its official release is Apache-2.0 licensed and content-addressed
by tag `2020.3.1` at commit
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. That is a sound exact source and
methodology contract.

A commercial simulator is not a sound near-term FSMGen dependency. The
director states that commercial HDL simulators are prohibitively expensive
for this project and UVM simulation through one will not happen in the short
term. The director's separately developed NEXSIM project aims to provide an
open-source commercial-grade HDL simulator, with HDL parsing supplied by the
separately developed PGEN project. PGEN and NEXSIM are both progressing but
are not yet ready to form a UVM execution authority. Verilator's own ecosystem
describes its UVM support as still in development, so the currently installed
Verilator cannot be relabelled as full UVM authority either.

## Decision

Select IEEE 1800.2-2020 with the Accellera UVM 2020-3.1 reference
implementation as VIAL's native UVM methodology and source contract. FSMGen
will use the exact upstream tag and commit. A project-local verified copy and
complete content/license/notice manifest become mandatory before any
library-dependent parser, compile, or runtime gate; deterministic source
emission itself does not wait for a network fetch or installed UVM library.
Vendor-bundled or UVM 1.2 compatibility libraries cannot silently replace the
selected identity.

Separate native work into three honest capability tiers:

1. `sv_uvm_emit.accellera_2020_3_1` is the near-term open-source emission
   profile. It can grow across the complete selected UVM environment shape,
   producing deterministic, efficient, readable, source-mapped artifacts,
   representative review galleries, and closed capability/manifests without
   claiming compile, elaboration, simulation, or runtime results.
2. `sv_uvm_experimental` is an optional probe tier for open-source tools whose
   UVM support is incomplete. Every exercised feature, failure, deviation, and
   non-claim is recorded. Probe success cannot become product qualification.
3. `sv_uvm_qualified` remains the full runtime family. The intended open-source
   provider is a future capability-qualified tuple of PGEN parser and NEXSIM
   simulator releases. Their exact concrete profile ID, versions, commands,
   handoff schema, and capability record will be selected only when executable
   releases exist; inventing them now would be false precision.

Commercial Xcelium, VCS, and Questa may be comparison or user-contributed
qualification profiles later, but none is a required FSMGen roadmap gate and
their absence blocks no near-term emission work.

Canonical native artifacts are simulator-neutral IEEE SystemVerilog plus the
selected Accellera UVM API. They contain no Xcelium/VCS/Questa/Verilator/
NEXSIM-specific source, preprocessor branch, package, pragma, hierarchy API, or
workaround. A provider-specific requirement may exist only in an isolated,
declared adapter or command/evidence layer and cannot define VIAL semantics or
change canonical source bytes.

Simulator absence does not bound generation breadth. FSMGen may emit and
iterate full tests, environments, agents, interfaces, sequences, TLM,
factory/configuration, RAL, coverage, properties, models, scoreboards, faults,
and result plumbing before a full UVM simulator exists. Static structural
checks and director visual review are legitimate emission evidence, and
review findings become ordinary exact task-tree defects. They do not establish
SystemVerilog syntax, UVM compile/elaboration, runtime correctness, or complete
VIAL authoring support. Undetected defects may therefore remain until stronger
tools arrive, without turning unavailable simulation into an emission blocker.

Experimental open-source probes start with the first reviewable artifact
gallery rather than waiting for emission breadth to close. Each exact tool may
catch preprocessing, parsing, type, package, class, compile, or elaboration
defects within the subset it supports. A demonstrated generator defect is
distinguished from a tool limitation; unsupported stages are evidence and do
not narrow canonical generation.

Generated UVM is compiler output. Its standards-compliant syntax, expression
forms, helper decomposition, macro choices, and class structure may iterate in
response to visual review and exact tool diagnostics. The manifest pins the
FSMGen/emitter identity, so byte determinism is relative to that exact
identity. Representation-only changes preserve VIAL meaning, capability truth,
public artifact schemas, and source-map obligations; semantic, profile, public
schema, or compatibility changes require explicit versioning. Tool workarounds
remain provider adapters unless they are valid neutral improvements to the
canonical source.

VIAL remains the semantic authority. The backend maps typed verification
intent to UVM events/callbacks, phases/objections, sequences, TLM,
factory/configuration services, RAL, constrained randomization, covergroups,
assertions, virtual interfaces, and clocking blocks. These mechanisms remain
compiler-private. Authored VIAL exposes identity, ordering, lifecycle,
communication, substitution, configuration, register, decision, coverage,
property, timed-interaction, scenario, model, scoreboard, fault, and result
intent; it does not rename UVM APIs.

Near-term emission must preserve `VIALExecutionIR` logical
`drive -> sample -> react -> check` time, pre-resolved portable random choices,
atomic repository-local artifacts, complete source maps, and explicit
capability negotiation. It must report compile/elaboration/run/result as
`not_run` or `unavailable`, never as inferred success.

The existing `uvm-passive-monitor` command, UVM 1.2 label, generated package
shape, manifest schema, and compile/runtime non-claims remain unchanged.
Native VIAL uses a separate artifact graph and profile identity. Any later
migration or retirement of the legacy command requires an explicit versioned
owner and compatibility proof.

## Consequences

- `.13` is decomposed so deterministic native emission can proceed without a
  commercial license; PGEN+NEXSIM runtime integration remains a separately
  blocked child until the necessary parser, handoff, and simulator capabilities
  exist.
- A Verilator UVM probe may be valuable engineering evidence, but official
  “support still in development” status prevents it from satisfying
  `sv_uvm_qualified` today.
- The absence of commercial tools is a deliberate product constraint, not a
  recurring blocker or reason to leave emission architecture unimplemented.
- The absence of any full UVM simulator is also not a reason to restrict source
  generation to a toy subset: broad reviewable emission proceeds first, with
  static/manual and experimental-tool evidence kept separate from qualification.
- No UVM runtime, four-state simulation, or cross-backend parity claim exists
  until an exact PGEN+NEXSIM tuple passes parse, compile, elaboration,
  execution, normalized-result, rerun, and cleanup gates.
- The first native subset is evidence for later expressive-frontier work, not
  VIAL's language ceiling. Leaf `.19` still owns complete source-taxonomy
  decomposition after bounded backend evidence exists.
- The detailed profile, mapping, artifact, compatibility, and gate contract is
  part of `docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md`.
