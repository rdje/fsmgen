# IAL2 PPIF Parser CLI First Slice

Status: first public `.ppif` parser/CLI slice shipped.

Task tree:
[docs/tasks/IAL2-PPIF-PARSER-CLI-FIRST-SLICE.md](tasks/IAL2-PPIF-PARSER-CLI-FIRST-SLICE.md).

Implementation:
`FSM::Adapter::IAL2::PPIF` plus the `.ppif` branch in `bin/fsmgen`.

Runnable sample:
[`ppif/axi_aw_valid_ready.ppif`](../ppif/axi_aw_valid_ready.ppif).

Later bounded bundle slice:
[docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md](IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md).

## Scope

This slice made `.ppif` the first public file-backed IAL2 surface. It supports
one Valid-Ready channel object per file. The checked-in sample above uses this
exact shape:

```text
(protocol-platform-intent axi_aw_valid_ready
  (profile axi4)
  (source
    (object axi-valid-ready-aw)
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40)))
  (valid-ready-channel axi_aw
    (channel AW)
    (role manager-to-subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (valid awvalid)
    (ready awready)
    (payload
      (awaddr width 32)
      (awlen width 8))))
```

The file remains protocol/platform-generic. The `(profile axi4)` clause selects
the AXI vocabulary for this object; `.ppif` is not an AXI-only extension.

The mandatory lowering chain is preserved:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

Direct `.ppif` to `.fsm` lowering is not exposed.

## CLI Usage

Emit the IAL2 source-anchor/residue report without writing HDL:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_aw_valid_ready.ppif
```

Materialize the generated review artifacts and HDL:

```bash
./bin/fsmgen --outdir generated ppif/axi_aw_valid_ready.ppif
```

That writes the generated `.isf` and generated `.fsm` files into `generated/`,
then feeds the selected generated `.fsm` into the existing HDL path.

Run check mode with machine-readable diagnostics:

```bash
./bin/fsmgen --strict --check --json ppif/axi_aw_valid_ready.ppif
```

Emit normalized semantic JSON without writing HDL:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/axi_aw_valid_ready.ppif
```

For the checked-in sample, successful check JSON and normalized semantic JSON
keep `source.resolved_path` on `ppif/axi_aw_valid_ready.ppif` rather than on
the temporary generated `.fsm`, and their report-level `support_accounting`
objects match the PPIF sample corpus entry with source kind `ppif`. The
normalized semantic payload still describes the generated `.fsm` semantic root.

Discover the shipped file suffix stack:

```bash
./bin/fsmgen --capability-manifest
```

The manifest's `language_surface.file_surfaces` section lists `.fsm`, `.isf`,
and `.ppif`; the `.ppif` entry records IAL2, generated `.isf` before generated
`.fsm`, the sample path, supported CLI modes, current bounded-public status,
and the unsupported first-slice aliases.

This document records the original Valid-Ready parser/CLI slice. The current
machine-readable downstream boundary is broader and lives in
`./bin/fsmgen --capability-manifest` under
`language_surface.file_surfaces`: bounded public `.ppif` now includes
one-channel Valid-Ready sources, multi-channel Valid-Ready bundles, and
one-object AXI manager capacity/status sources. Support-accounted AXI manager
coverage includes generated auto-ID write/read response-demux, single-beat,
last-beat, and multi-beat read-data capture, burst-length/runtime validation,
scalar `RRESP` aggregation, one-or-more read burst-last queue-head groups,
one-or-more write queue-head groups, and read single-beat queue-head
response-demux including multiple response-demux-only groups, plus selected
read and write single-group depth-3 queue-head shapes. Broader concrete
same-ID queues,
same-family mixed auto-ID plus concrete queue-head demux, read-data over
multiple read single-beat queue-head groups, aliases, platform clauses, full
AXI manager behavior, direct backend lowering, and VHDL remain deferred.

Malformed `.ppif` source fails closed before claiming generated behavior. The
first slice rejects missing profile/source/channel clauses, malformed reset
tuples, unsupported payload width syntax, and generator-level contract errors
such as invalid signal names or non-positive payload widths. A later bounded
bundle slice accepts multiple unique `valid-ready-channel` objects for
aggregate report/review-artifact modes; duplicate channel object names still
fail closed.

## Report Surface

`--emit-schedule-json` returns the IAL2 report from
`FSM::IAL2::ProtocolIntent::ValidReadyChannel`. The stable first-slice fields
include:

- `schema`: `fsmgen.ial2.protocol_intent.valid_ready_channel.v1`,
- `layering`: evidence that the source is IAL2, generated IAL1 is `.isf`,
  generated IAL0 is `.fsm`, and direct IAL2-to-IAL0 is false,
- `source_object`: authored top-level PPIF intent name, object id, and source
  anchors,
- `generated_artifacts`: generated `.isf` name and generated `.fsm` names,
- `target_channel`: protocol, channel family, and role,
- `bindings`: clock, reset, valid, ready, and payload bindings,
- `transfer_fire_condition`: the `VALID && READY` condition,
- generated monitor/assertion entries, assumptions, enforced static rules, and
  unsupported residue.

The existing `--emit-schedule-json` option is reused for `.ppif` because it is
the public "show me the lowering/report" CLI surface. For `.ppif` it emits the
IAL2 source-anchor/residue report, not the nested IAL1 schedule report.

## Boundaries

The public `.ppif` surface does not support `.pif`, `.ppi`, `.axi`, `.chi`,
`.ace`, `.ahb`, `.apb`, `.atb`, or other aliases. Those remain future
exact-owner decisions.

The bounded bundle slices support multiple unique Valid-Ready channel objects
for aggregate IAL2 reports, check JSON, aggregate semantic JSON, generated
review artifacts, and the tracked aggregate wrapper/top HDL entry. Later
bounded AXI manager capacity/status slices added the support-accounted coverage
advertised by the capability manifest. Platform clauses, full AXI manager
behavior, aliases, VHDL, and any direct `.ppif` to `.fsm` shortcut remain
future exact-owner decisions.

## Validation

Focused coverage lives in
[t/1436-ial2-ppif-parser-cli.t](../t/1436-ial2-ppif-parser-cli.t). It proves:

- the adapter parses the decision-0016 Valid-Ready source shape,
- the IAL2 report preserves the authored top-level PPIF intent name,
- the checked-in `ppif/axi_aw_valid_ready.ppif` sample is the canonical
  runnable first-slice example,
- unsupported or malformed PPIF source fails closed,
- CLI `--emit-schedule-json` emits the IAL2 report,
- CLI `--outdir` writes generated `.isf`, generated `.fsm`, and HDL,
- CLI `--strict --check --json` accepts `.ppif`,
- CLI `--strict --emit-semantic-json` accepts `.ppif`,
- successful `.ppif` check JSON and normalized semantic JSON keep public
  source identity and matched
  support accounting,
- `--capability-manifest` advertises `.ppif` under
  `language_surface.file_surfaces`,
- `.pif` remains unsupported in this first public slice.
