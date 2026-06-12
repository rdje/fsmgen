# IAL2 PPIF Multi Valid-Ready Readiness

Status: readiness/contract-mapping slice. No parser, generator, CLI, report,
HDL, or test behavior changes in this slice.

Task tree:
[docs/tasks/IAL2-PPIF-MULTI-VALID-READY-READINESS.md](tasks/IAL2-PPIF-MULTI-VALID-READY-READINESS.md).

Related shipped surface:
[docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md](IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md).

## Purpose

The first public `.ppif` path intentionally supports one Valid-Ready channel
object per file. The next AXI-shaped pressure point is a single `.ppif` file
that can describe multiple Valid-Ready channels, such as the AW, W, B, AR, and
R channel families that make up the broader AXI transaction surface.

This note records why that is not just a parser relaxation. It maps the current
single-object assumptions and the contract choices that a future behavior leaf
must settle before accepting multiple channel objects.

## Current Behavior

The shipped `.ppif` shape is:

```text
(protocol-platform-intent NAME
  (profile axi4)
  (source ...)
  (valid-ready-channel CHANNEL_OBJECT ...))
```

The public lowering chain remains:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

Direct `.ppif` to `.fsm` lowering is forbidden. The current parser rejects a
second `(valid-ready-channel ...)` object before generation.

## Readiness Findings

`perl/FSM/Adapter/IAL2/PPIF.pm` accepts exactly one top-level
`(protocol-platform-intent ...)` form. Inside that form it accepts one
`(profile ...)`, one `(source ...)`, and one `(valid-ready-channel ...)`.
The duplicate channel diagnostic is deliberate first-slice behavior, not an
accidental parser omission.

`perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm` exposes a singular
generator contract. `generate()` expects exactly one contract hash, emits one
generated `.isf` actor, lowers that actor to generated `.fsm`, and returns one
IAL2 report using the `fsmgen.ial2.protocol_intent.valid_ready_channel.v1`
schema.

The `.ppif` branch in `bin/fsmgen` assumes one generated IAL1 artifact and a
single selected generated IAL0 entry. It reads
`generated_ial1_schedule_report`, `generated_ial1`, `generated_ial0.files`,
and the first report-level `generated_artifacts.ial0.files[]` entry as the HDL
input. A multi-object result needs an explicit aggregate artifact-selection
policy before the CLI can know what to write, report, or feed into HDL.

`perl/FSM/Adapter/ISF/Parser.pm` currently accepts exactly one top-level
`(actor ...)` compile/report entry actor. `docs/ISF_SPEC.md` documents that
multiple sibling actor roots fail closed until actor type resolution is
explicitly selected. A multi-channel PPIF result therefore cannot safely emit
one `.isf` file containing several sibling actors unless an ISF-level
multi-actor or wrapper/top contract is selected first.

The current top-level `(source ...)` object is singular. A five-channel file
needs a source-anchor model that can identify whether anchors apply to the
whole intent, to each channel, or both. Without that, source/residue reporting
would become ambiguous.

## Why Parser Relaxation Is Not Enough

Accepting a second `valid-ready-channel` form without changing the rest of the
contract would create ambiguous behavior:

- the generator has no aggregate input type or report schema;
- the CLI has no rule for which generated `.fsm` file becomes the HDL entry;
- `--outdir` has no stable naming/reporting contract for multiple generated
  `.isf` review artifacts;
- `--emit-schedule-json` has no aggregate IAL2 report schema for a channel
  bundle;
- source anchors and unsupported residue cannot be attributed precisely; and
- one generated `.isf` file with multiple sibling actors would contradict the
  current ISF parser contract.

The current fail-closed boundary is therefore the correct shipped behavior
until a future owner selects those contracts.

## Required Future Contract Choices

A future multi-channel `.ppif` implementation owner must choose one of these
directions before behavior changes:

1. Multi-artifact PPIF result: keep each Valid-Ready channel as a separate
   generated `.isf` actor and return aggregate arrays such as
   `generated_ial1.items[]`, `generated_ial0.items[]`, and an aggregate report
   schema such as `fsmgen.ial2.protocol_intent.valid_ready_bundle.v1`. The CLI
   would need an explicit rule for report-only mode, `--outdir`, check JSON,
   semantic JSON, and HDL entry selection.
2. Wrapper/top actor result: generate one reviewable IAL1 actor that owns or
   instantiates the per-channel monitors. This requires an ISF/ATL owner for
   the wrapper or actor-network shape before `.ppif` can depend on it.
3. One-object-per-file composition: keep the current file boundary and defer
   multi-channel grouping to a higher-level composition layer or manifest. This
   preserves the existing report and CLI contract but does not give users a
   single-file AXI channel bundle.

Whichever direction is selected must preserve the mandatory
`IAL2 -> IAL1 -> IAL0` lowering chain and keep generated IAL1 review artifacts
visible before generated IAL0 exists.

## Selected Prerequisite

Do not relax `FSM::Adapter::IAL2::PPIF` duplicate-channel rejection until a
future exact task-tree owner selects the aggregate result/report/source-artifact
contract.

The next implementation leaf should define, before code changes:

- the authored `.ppif` source shape for more than one Valid-Ready channel;
- whether `source` anchors are intent-level, channel-level, or both;
- the aggregate IAL2 report schema and how residue is attributed;
- the generated IAL1 artifact shape and naming stability;
- the generated IAL0 artifact shape and HDL entry-selection rule;
- `--emit-schedule-json`, `--outdir`, `--check --json`, and
  `--emit-semantic-json` behavior; and
- focused tests that preserve the current single-object behavior while adding
  the selected multi-object behavior.

## User-Facing State

Users can continue to use the shipped single-object `.ppif` path documented in
[docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md](IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md).
Multiple Valid-Ready channel objects in one `.ppif` file remain unshipped and
fail closed.

This readiness slice is a contract map for the next task-tree owner. It does
not claim AXI five-channel manager behavior, transaction concurrency, ID
ordering, outstanding-window scheduling, response matching, bursts, or channel
dependency enforcement.
