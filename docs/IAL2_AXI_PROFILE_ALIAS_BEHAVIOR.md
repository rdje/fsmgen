# IAL2 AXI Profile-Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.540`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.540` ships `.axi` as the first bounded
IAL2 profile-alias suffix.

The shipped alias sample is:

```text
ppif/axi_aw_valid_ready.axi
```

It mirrors the existing generic IAL2 sample:

```text
ppif/axi_aw_valid_ready.ppif
```

`.axi` is a profile-alias entrypoint over the same IAL2
`protocol-platform-intent` model. It does not make AXI the definition of IAL2,
does not add `.chi`, `.ace`, `.atb`, `.smbus`, or `.i2s`, and does not allow
direct IAL2-to-IAL0 lowering. The APB `.apb` alias shipped later as its own
bounded APB requester-transfer profile alias in
`IAL2-FEATURE-COMPLETENESS-FRONTIER.554`; the AHB `.ahb` alias shipped later
as its own bounded AHB requester profile alias in
`IAL2-FEATURE-COMPLETENESS-FRONTIER.700`. Neither is part of the `.axi` slice.

## Source Shape

`.axi` sources use the same Lispish IAL2 form as `.ppif` and must declare an
explicit AXI-family profile:

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

Accepted `.axi` profiles are:

```text
axi
axi3
axi4
axi5
```

The first `.axi` behavior is bounded to one AXI-family Valid-Ready channel.
Broader AXI bundles and AXI manager capacity/status behavior remain available
through `.ppif`, but are not exposed through `.axi` in this first alias slice.

## Lowering And Reports

The `.axi` sample lowers through the same reviewable path as `.ppif`:

```text
.axi / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

The generated review artifacts are:

```text
axi_aw_valid_ready_monitor.isf
axi_aw_valid_ready_monitor.fsm
```

The generated HDL module remains:

```text
axi_aw_valid_ready_monitor
```

Check JSON and semantic JSON keep the authored `.axi` path as the public source
path while describing the generated `.fsm` semantic root.

Support accounting records the alias sample as:

```text
entry_id: intent.axi_profile_alias_aw_valid_ready
coverage: ial2_axi_profile_alias_aw_valid_ready_pipeline_cli
source_kind: ial2_profile_alias
```

## CLI Examples

Emit the IAL2 schedule/report JSON:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_aw_valid_ready.axi
```

Run a strict check without writing HDL:

```bash
./bin/fsmgen --strict --check --json ppif/axi_aw_valid_ready.axi
```

Emit normalized semantic JSON:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/axi_aw_valid_ready.axi
```

Materialize the generated review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-axi-review \
  --output /tmp/fsmgen-axi-review/axi_aw_valid_ready_monitor.sv \
  ppif/axi_aw_valid_ready.axi
```

## Diagnostics

`.axi` diagnostics are distinct from generic parse failures:

- a missing `(profile ...)` clause is rejected as a missing profile;
- a non-AXI-family profile such as `(profile valid-ready)` is rejected as a
  suffix/profile mismatch;
- broader `.axi` AXI bundle or manager behavior is rejected as outside the first
  profile-alias slice;
- `.chi`, `.ace`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` are
  known IAL2 alias candidates but remain unsupported;
- `.apb` is a separate shipped APB profile alias after `.554`, not a `.axi`
  source shape;
- `.ahb` is a separate shipped AHB profile alias after `.700`, not a `.axi`
  source shape; and
- an unrelated suffix such as `.foo` is reported as an unknown source suffix.

## Non-Goals

This slice does not change `.ppif` behavior, AXI manager `.ppif` behavior,
protocol-neutral `.ppif` behavior, `.isf` behavior, `.fsm` behavior, backend
behavior, verification-output behavior, backend-language variants, VHDL
behavior, or direct IAL2-to-IAL0 lowering. AXI remains the first profile-alias
example, not the IAL2 definition.

## Validation

The behavior is covered by:

```bash
perl -c bin/fsmgen
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1469-ial2-axi-profile-alias.t
perl -Iperl -c t/248-regression-corpus-accounting.t
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/1469-ial2-axi-profile-alias.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```
