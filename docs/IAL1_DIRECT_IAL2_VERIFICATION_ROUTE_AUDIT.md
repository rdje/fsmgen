# IAL1 Direct IAL2 Verification Route Audit

## Metadata

- Owner leaf: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6`
- Date: `2026-06-26`
- Status: `complete`
- Outcome: no direct IAL2-to-verification route for the current verification
  output lane; keep generated verification output sourced from reviewable
  IAL1 `.isf` artifacts.

## Question

Should FSMGen generate verification artifacts directly from IAL2 `.ppif`
protocol/platform intent, or should IAL2 verification facts lower through
generated IAL1 before any verification-output target consumes them?

## Evidence Read

- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` and
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`: `.ppif` is the first shipped
  IAL2 surface and always lowers through generated `.isf` before generated
  `.fsm`; direct IAL2-to-IAL0 lowering is not public.
- `perl/FSM/Support/LanguageSurfaceSection.pm` and
  `t/297-capability-manifest.t`: `.isf` advertises the UVM and VHDL
  verification-output CLI modes; `.ppif` deliberately does not.
- `bin/fsmgen`: `--emit-verification-output` rejects non-`.isf` sources before
  the PPIF lowering branch. The PPIF branch remains schedule/check/semantic
  JSON and HDL lowering only.
- `perl/FSM/Adapter/IAL2/PPIF.pm`: shipped PPIF reports record layering as
  IAL2 source, generated IAL1 `.isf`, generated IAL0 `.fsm`, and
  `direct_ial2_to_ial0 => 0`.
- `docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md`,
  `docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md`,
  `docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md`, and
  `docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md`: the shipped
  verification-output targets consume passive `verification_observations[]`
  metadata from `.isf` schedule reports.
- `t/1464-isf-verification-output-uvm-passive-monitor.t` and
  `t/1465-isf-verification-output-vhdl-observation-package.t`: direct `.fsm`
  sources fail closed for verification output; capability tests also prove
  `.ppif` does not advertise these modes.

## Findings

The current verification-output contract is intentionally IAL1-first. It
consumes parser-validated actor-level passive observation metadata:
`(observe NAME (role passive_monitor) (signals SIG...))`, projected into
`verification_observations[]`. That metadata has reviewable source text in
`.isf`, stable schedule-report shape, support accounting, and focused artifact
tests.

The current `.ppif` surface carries protocol/platform facts such as
Valid-Ready channels, AXI manager capacity/status objects, ID-family metadata,
transaction envelopes, response demux, issue-order queues, read-data capture,
burst length, and runtime validation. Those facts are meaningful future inputs
for protocol checkers, scoreboards, and coverage, but they are not passive
observation metadata today and they are not exposed as generated verification
artifact contracts.

A direct IAL2-to-verification route would bypass the same reviewability
doctrine that keeps `.ppif` lowering through generated `.isf` before `.fsm`.
It would also create a second source of truth for source identity, diagnostics,
support accounting, and artifact manifests before any concrete protocol
verification target has selected its input schema.

## Decision

Do not add a direct IAL2-to-verification generation route for the current
verification-output lane.

The selected route is:

1. Current `--emit-verification-output` remains `.isf`-only.
2. `.ppif` remains unsupported for verification-output CLI modes and remains
   unadvertised in `language_surface.file_surfaces.entries[]`.
3. Future IAL2 protocol verification work should first lower or annotate the
   generated IAL1 `.isf` artifact with explicit verification metadata, then
   reuse the IAL1 verification-output path.
4. A later exact owner may select a direct IAL2 verification-output route only
   if it proves that the required protocol verification facts cannot be made
   reviewable in generated IAL1 without losing semantics.

## Consequences

- The shipped UVM passive-monitor and VHDL observation-package targets remain
  reviewable, IAL1-sourced, and bounded.
- PPIF users must inspect generated `.isf` and `.fsm` review artifacts for
  current verification-output preparation; they cannot request direct `.ppif`
  verification artifacts.
- Future protocol checker, scoreboard, coverage, or reusable VIP work needs a
  new task-tree owner to define the IAL2-to-IAL1 annotation contract before any
  artifact generator consumes protocol-specific facts.
- This audit changes documentation and durable routing only; no parser,
  lowering, CLI, generated artifact, manifest, support-accounting, or HDL
  behavior changes.
