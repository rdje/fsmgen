# IAL2 APB Profile-Alias Behavior

Task-tree owners: `IAL2-FEATURE-COMPLETENESS-FRONTIER.554`,
`IAL2-FEATURE-COMPLETENESS-FRONTIER.569`

Date: 2026-06-26

## Outcome

FSMGen ships `.apb` as the bounded APB IAL2 profile-alias suffix over the same
`protocol-platform-intent` model used by `.ppif`.

The currently supported alias samples are:

```text
ppif/apb_requester_transfer.apb
ppif/apb_requester_transfer_busy.apb
ppif/apb_requester_transfer_status.apb
ppif/apb_completer.apb
ppif/apb_composition.apb
ppif/apb_composition_busy.apb
ppif/apb_composition_status.apb
```

They mirror the generic APB IAL2 samples:

```text
ppif/apb_requester_transfer.ppif
ppif/apb_requester_transfer_busy.ppif
ppif/apb_requester_transfer_status.ppif
ppif/apb_completer.ppif
ppif/apb_composition.ppif
ppif/apb_composition_busy.ppif
ppif/apb_composition_status.ppif
```

`.apb` is not a separate APB language, not an APB-to-FSM shortcut, not a direct
backend path, not implicit profile inference, and not AXI behavior.

## Source Shapes

Every `.apb` source uses the same Lispish IAL2 form as `.ppif` and must declare
the explicit APB profile:

```text
(profile apb)
```

The bounded alias accepts exactly these APB shapes:

- one APB requester-transfer object:
  `(apb-requester apb_requester ...)`;
- one APB completer object:
  `(apb-completer apb_completer ...)`; or
- one explicit fixed composition aggregate containing one requester, one
  completer, and one `(apb-composition apb_tb ...)` object.

Mixed requester/completer files without the explicit `(apb-composition ...)`
object still fail closed. Multi-peripheral APB interconnect/decode is not part
of the alias contract.

Requester-transfer aliases may use the original response shape, the selected
busy-capable response shape with `(busy NAME)`, or the selected busy-gated
status response shape with `(busy NAME)` and `(status NAME width 2)`.

## Lowering And Reports

Each `.apb` source lowers through the same reviewable chain as the matching
`.ppif` source:

```text
.apb / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

The requester-transfer alias generates:

```text
apb_requester.isf
apb_requester.fsm
module apb_requester
schema fsmgen.ial2.protocol_intent.apb_requester_transfer.v1
```

The completer alias generates:

```text
apb_completer.isf
apb_completer.fsm
module apb_completer
schema fsmgen.ial2.protocol_intent.apb_completer.v1
```

The fixed composition alias generates:

```text
apb_requester.isf
apb_completer.isf
apb_requester.fsm
apb_completer.fsm
apb_tb.fsm
modules apb_requester, apb_completer, apb_tb
schema fsmgen.ial2.protocol_intent.apb_composition.v1
semantic root kind top
```

Check JSON and semantic JSON keep the authored `.apb` path as the public source
path while describing the generated `.fsm` or `?top` semantic root.

Support accounting records the alias samples as:

```text
entry_id: intent.apb_profile_alias_requester_transfer
coverage: ial2_apb_profile_alias_requester_transfer_pipeline_cli
source_kind: ial2_profile_alias

entry_id: intent.apb_profile_alias_requester_transfer_busy
coverage: ial2_apb_profile_alias_requester_transfer_busy_pipeline_cli
source_kind: ial2_profile_alias

entry_id: intent.apb_profile_alias_requester_transfer_status
coverage: ial2_apb_profile_alias_requester_transfer_status_pipeline_cli
source_kind: ial2_profile_alias

entry_id: intent.apb_profile_alias_completer
coverage: ial2_apb_profile_alias_completer_pipeline_cli
source_kind: ial2_profile_alias

entry_id: intent.apb_profile_alias_composition
coverage: ial2_apb_profile_alias_composition_pipeline_cli
source_kind: ial2_profile_alias

entry_id: intent.apb_profile_alias_composition_busy
coverage: ial2_apb_profile_alias_composition_busy_pipeline_cli
source_kind: ial2_profile_alias

entry_id: intent.apb_profile_alias_composition_status
coverage: ial2_apb_profile_alias_composition_status_pipeline_cli
source_kind: ial2_profile_alias
```

## CLI Examples

Emit APB IAL2 schedule/report JSON:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer_busy.apb
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer_status.apb
./bin/fsmgen --emit-schedule-json ppif/apb_completer.apb
./bin/fsmgen --emit-schedule-json ppif/apb_composition.apb
./bin/fsmgen --emit-schedule-json ppif/apb_composition_busy.apb
./bin/fsmgen --emit-schedule-json ppif/apb_composition_status.apb
```

Run strict checks without writing HDL:

```bash
./bin/fsmgen --strict --check --json ppif/apb_requester_transfer.apb
./bin/fsmgen --strict --check --json ppif/apb_requester_transfer_status.apb
./bin/fsmgen --strict --check --json ppif/apb_completer.apb
./bin/fsmgen --strict --check --json ppif/apb_composition.apb
./bin/fsmgen --strict --check --json ppif/apb_composition_status.apb
```

Emit normalized semantic JSON:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/apb_requester_transfer_status.apb
./bin/fsmgen --strict --emit-semantic-json ppif/apb_completer.apb
./bin/fsmgen --strict --emit-semantic-json ppif/apb_composition.apb
./bin/fsmgen --strict --emit-semantic-json ppif/apb_composition_status.apb
```

Materialize generated review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-alias-completer \
  --output /tmp/fsmgen-apb-alias-completer/apb_completer.sv \
  ppif/apb_completer.apb

./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-alias-composition \
  --output /tmp/fsmgen-apb-alias-composition/apb_tb.sv \
  ppif/apb_composition.apb

./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-alias-status \
  --output /tmp/fsmgen-apb-alias-status/apb_requester_status.sv \
  ppif/apb_requester_transfer_status.apb
```

## Diagnostics

`.apb` diagnostics are distinct from generic parse failures:

- a missing `(profile ...)` clause is rejected as a missing profile;
- any non-APB profile such as `(profile valid-ready)` or `(profile axi4)` is
  rejected as a suffix/profile mismatch;
- Valid-Ready, AXI manager, bundle, and other non-APB source shapes are
  rejected as outside the APB profile-alias slice;
- mixed APB requester/completer files without the explicit APB composition
  object are rejected as unsupported implicit composition;
- unsupported APB shapes, malformed composition objects, and multi-peripheral
  interconnect/decode attempts stay fail-closed; and
- `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` remain
  known IAL2 alias candidates but unsupported.

## Non-Goals

This behavior does not change `.ppif` behavior, `.axi` behavior, AXI manager
behavior, `.isf` behavior, `.fsm` behavior, backend behavior,
verification-output behavior, backend-language variants, VHDL behavior, or
direct IAL2-to-IAL0 lowering.

APB multi-register decode, sidebands/strobes, alternate widths,
multi-peripheral decode, back-to-back transfer policy, direct backend lowering,
verification-output generation, backend-language variants, and VHDL remain
deferred. The selected busy output and busy-gated 2-bit requester status
aliases are documented in
[IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR](IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR.md)
and
[IAL2_APB_REQUESTER_STATUS_FIELD_BEHAVIOR](IAL2_APB_REQUESTER_STATUS_FIELD_BEHAVIOR.md).

## Validation

The `.569` alias widening was validated with:

```bash
perl -c bin/fsmgen
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1470-ial2-apb-profile-alias.t
perl -Iperl -c t/1471-ial2-apb-completer.t
perl -Iperl -c t/1472-ial2-apb-composition.t
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/248-regression-corpus-accounting.t
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/1470-ial2-apb-profile-alias.t \
  t/1471-ial2-apb-completer.t \
  t/1472-ial2-apb-composition.t \
  t/248-regression-corpus-accounting.t \
  t/297-capability-manifest.t
```

Direct probes also covered schedule/check/semantic/outdir success for the new
completer and composition aliases, requester `.apb` preservation, `.ppif`
preservation, and fail-closed missing-profile, wrong-profile, Valid-Ready, and
implicit mixed requester/completer diagnostics.
