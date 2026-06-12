# AXI IAL2 Valid-Ready Implementation Readiness Audit

Status: readiness audit complete; no IAL2 implementation shipped.

Task tree:
[docs/tasks/AXI-IAL2-VALID-READY-READINESS-AUDIT.md](tasks/AXI-IAL2-VALID-READY-READINESS-AUDIT.md).

Inputs:

- [docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md](AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md)
- [docs/AXI_VALID_READY_INTENT_PROBE.md](AXI_VALID_READY_INTENT_PROBE.md)
- [docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md](IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md)
- [docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md](decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md)
- [docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md](decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md)

## Purpose

This audit maps the existing code and test surfaces that a future AXI
Valid-Ready IAL2 implementation must use or extend.

It does not implement syntax, parser behavior, lowering behavior, generated
`.isf`, generated `.fsm`, HDL, tests, or CLI support.

## Code Surfaces Read

The audit inspected these current implementation owners:

- `bin/fsmgen`: CLI resolution, `.isf` detection, schedule JSON, `--outdir`,
  and downstream `.fsm`/HDL pipeline handoff.
- `perl/FSM/Adapter/ISF.pm`: public IAL1 parser facade.
- `perl/FSM/Adapter/ISF/Parser.pm`: `.isf` actor parser, validation,
  deprecated handshake handling, transaction stage handling, and actor shell
  finalizers.
- `perl/FSM/Scheduler/ISF.pm`: public IAL1 lower/report facade and lower
  result file-map behavior.
- `perl/FSM/Scheduler/ISF/LoweringIR.pm`: transaction-to-IR lowering,
  ready/valid stage lowering, immediate-check collection, sample handling,
  storage roles, and generated child/report metadata.
- `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`: scheduled `.fsm` emission,
  including the `+assert` carrier.
- `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`: schedule-report JSON emission,
  including transaction-stage and storage-role summaries.
- `perl/FSM/Support/ISFPublicInterfaceContract.pm`: machine-readable ISF
  public contract and capability-manifest metadata.
- Focused tests around public entrypoints, lower-result files, stage lowering,
  assertion carriers, assertion HDL emission, sampled-value properties,
  implication/window properties, mdBook lowering examples, and relative path
  hygiene.

## Current Pipeline Facts

The current public implementation is an IAL1 pipeline:

```text
.isf text -> FSM::Adapter::ISF -> actor hash
actor hash -> FSM::Scheduler::ISF -> reviewable .fsm files + schedule JSON
.fsm files -> existing FSMGen HDL pipeline
```

`FSM::Adapter::ISF->parse_file(...)` only accepts readable `.isf` paths.
`bin/fsmgen` resolves bare names as `.fsm` and recognizes only `.fsm` and
`.isf` suffixes today. Therefore `.pif`, `.ppi`, `.ppif`, or profile aliases
such as `.axi` are not current CLI surfaces.

`FSM::Scheduler::ISF->lower($actor)` returns a hash with `files`, where each
key is a `.fsm` basename and each value is reviewable scheduled `.fsm` text.
The CLI can materialize those files through `--outdir`, or use a temporary
single lowered `.fsm` for direct HDL generation.

`FSM::Scheduler::ISF->report($actor)` emits schedule JSON for the generated
IAL1-to-IAL0 lowering. It does not currently emit an IAL2 protocol-intent
report with source anchors, source-object identity, unsupported residue, or
generated IAL1 artifact links.

## Existing Substrates

### Deprecated Handshake Metadata

`(handshake name (valid signal) (ready signal))` is parser-validated and then
ignored. It exists only as compatibility input. It must not be revived as the
AXI Valid-Ready implementation path.

### Transaction Stage

Transaction `(stage name (ready READY) (valid VALID))` lowers to a top-level
ready-gated stage state. The state drives `VALID = 1` while active and
advances only under `READY`. The older `(input READY)` / `(output VALID)`
spelling remains an alias.

This is useful prior art for ready/valid naming, endpoint validation, report
projection, and same-target conflict checks. It is not a complete AXI
Valid-Ready monitor because it does not by itself prove reset-low valid,
valid-hold until handshake, transmitter independence from ready, payload
stability while stalled, source anchors, or residue.

### Immediate Verification Checks

Transaction-level `(assert ...)`, `(assume ...)`, and `(cover ...)` already
lower through the IAL1-to-IAL0 path as a `+assert` carrier in scheduled `.fsm`.
FSMGenFull parses that carrier into module assertions, and
`GeneratedModuleEmitter` emits clocked SystemVerilog properties for the
SystemVerilog target.

The useful existing property leaves for a Valid-Ready monitor are:

- overlapping implication `(=> A B)`, which remains simulable,
- sampled-value predicates `(stable SIG)`, `(changed SIG)`, `(rose SIG)`,
  `(fell SIG)`, which remain simulable,
- value-returning `(past SIG [N])`, which remains simulable when used inside a
  boolean property expression.

Delayed `(next ...)` and `(within ...)` properties are formal-only because they
emit `##` sequences. They can be used later, but the first implementation
should not require them for the core pass/fail path if the focused gate is
expected to stay Verilator-clean.

## Readiness Conclusions

The safest first code implementation should not extend the `.isf` parser with
IAL2 source forms. `.isf` is IAL1 and should remain the reviewable generated
artifact.

The future implementation should introduce a separate IAL2 front-end or
protocol-intent generator that produces:

- a reviewable generated IAL1 `.isf` file or text artifact,
- a protocol-intent report with source anchors and residue,
- then a normal IAL1 parse/lower step that produces reviewable IAL0 `.fsm`
  artifacts through `FSM::Adapter::ISF` and `FSM::Scheduler::ISF`.

The first implementation should be in-process first, before CLI extension
work. CLI suffix support for `.pif`, `.ppi`, `.ppif`, or future profile
aliases is a public surface and should be a later exact owner after the
generated IAL1 and report contract are stable.

The generated IAL1 should prefer existing assertion/property syntax for
Valid-Ready safety checks. A future owner must still decide the exact generated
actor shape and whether the monitor is:

- assertion-only,
- assertion plus report,
- or behavior-bearing with explicit state/storage beyond assertion carriers.

## Minimum Future Owner Map

| Future concern | Likely owner | Why |
| --- | --- | --- |
| IAL2 source object parsing or construction | New IAL2/protocol-intent front-end module | Keeps `.isf` as IAL1 and avoids mixing protocol-intent syntax into the current ISF parser. |
| Generated IAL1 artifact | New IAL2 generator plus `FSM::Adapter::ISF` validation | The output must be reviewable `.isf` and accepted by the existing IAL1 parser. |
| IAL1-to-IAL0 lowering | `FSM::Scheduler::ISF` and existing emitters | The generated `.isf` should use supported IAL1 forms so existing lower/report paths produce `.fsm`. |
| Assertion/property emission | Existing `+assert` carrier, FSMGenFull parsing, and `GeneratedModuleEmitter` | Valid-hold and payload-stability checks can reuse overlapping implication plus sampled-value properties. |
| Source-anchor/residue report | New IAL2 report surface | Current schedule JSON is an IAL1 lowering report, not an IAL2 source-object report. |
| Public CLI/file suffix support | `bin/fsmgen` plus public contract/manifest metadata | Current resolver and public contract recognize `.fsm`/`.isf` only. |
| Machine-readable contract | New or extended support contract module | IAL2 entrypoints, report keys, and lower-result shapes need exact discovery metadata before public exposure. |
| mdBook user surface | `docs/book/src/14-feature-backlog.md` first, later a dedicated IAL2 chapter when shipped | The book must describe exactly what users can run and inspect. |

## Safe First Implementation Boundary

A later code slice should be considered safe only if it can stay this small:

- accept one AXI Valid-Ready channel contract object in an internal or
  in-process IAL2 representation,
- require explicit clock, reset, channel family, role, valid, ready, and
  payload bindings,
- emit a reviewable generated `.isf` artifact,
- parse that generated `.isf` through `FSM::Adapter::ISF`,
- lower it through `FSM::Scheduler::ISF` to reviewable `.fsm`,
- emit a protocol-intent report with source anchors and explicit residue,
- add focused tests proving no direct IAL2-to-`.fsm` path exists.

The first implementation should not add a public file suffix, not promise a
full AXI manager, not generate ID/order behavior, and not bypass IAL1.

## Focused Validation Mapped For First Implementation

The first implementation leaf was expected to add focused tests or explicit
residue for:

- generated `.isf` exists before generated `.fsm`,
- generated `.isf` is accepted by `FSM::Adapter::ISF`,
- generated `.fsm` is emitted through `FSM::Scheduler::ISF`,
- `VALID && READY` is reported as the transfer/fire condition,
- missing clock/reset/valid/ready/payload bindings fail closed,
- reset-low valid obligation is represented or explicitly reported as an
  unsupported assumption,
- valid-hold and payload-stability checks use the existing assertion/property
  path or are explicitly deferred,
- source anchors and unsupported residue appear in the IAL2 report,
- public CLI suffixes remain unavailable until a dedicated CLI owner selects
  them,
- direct IAL2-to-`.fsm` lowering is rejected or structurally impossible.

Useful existing regression owners include:

- `t/1435-axi-ial2-valid-ready-generator.t`
- `t/1135-isf-public-entrypoint-metadata-audit.t`
- `t/1136-isf-public-cli-option-metadata-audit.t`
- `t/1117-isf-public-lower-result-files-audit.t`
- `t/1223-isf-stage-lowering.t`
- `t/1410-isf-assert-carrier.t`
- `t/1411-isf-assert-emit.t`
- `t/1412-isf-property-implication.t`
- `t/1417-isf-property-sampled-value.t`
- `t/1418-isf-property-window-range.t`
- `t/1376-isf-book-example-lowering-audit.t`

## Explicit Deferrals

This readiness audit does not select:

- final IAL2 file suffix,
- final protocol-intent syntax,
- final module/package names,
- generated fixture names,
- public CLI behavior,
- public machine-readable IAL2 contract shape,
- full AXI manager API,
- ID allocation, outstanding windows, same-ID ordering, interleaving,
  response matching, bursts, or channel dependency scheduling,
- wake-up, ACE, CHI, credited transport, or interconnect behavior.

## Documentation Drift Corrected

During the audit, the public contract prose and downstream integration spec
were found to reference old stage/contract test filenames that are not present
in the current test tree.
The current ready/valid stage coverage is `t/1179-isf-phase-stage-boundary.t`,
`t/1223-isf-stage-lowering.t`, and
`t/1252-isf-actor-phase-stage-report.t`. This slice corrects those pointers
as part of keeping the codebase, docs, and future implementation owner map
aligned.

## Current Conclusion

The codebase was ready for a narrow, in-process AXI Valid-Ready IAL2 generator
slice that emits reviewable `.isf`, uses the existing `.isf` parser/lowerer to
produce `.fsm`, and emits a separate source-anchor/residue report. The first
such slice is now recorded in
[docs/AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md](AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md).

It is not ready for a public `.pif`/`.ppi`/`.ppif`/`.axi` CLI surface or a full
AXI manager in the same slice. Those require later owners after the generated
IAL1 artifact and IAL2 report contract are proven.
