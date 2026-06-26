# IAL2 APB Profile-Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.554`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.554` ships `.apb` as the first bounded
APB IAL2 profile-alias suffix.

The shipped alias sample is:

```text
ppif/apb_requester_transfer.apb
```

It mirrors the generic APB IAL2 sample:

```text
ppif/apb_requester_transfer.ppif
```

`.apb` is a profile-alias entrypoint over the same IAL2
`protocol-platform-intent` model. It is not a separate APB language, not an
APB-to-FSM shortcut, not a direct backend path, and not an AXI behavior.

## Source Shape

`.apb` sources use the same Lispish IAL2 form as `.ppif` and must declare the
explicit APB profile:

```text
(profile apb)
```

The first `.apb` behavior is bounded to exactly one APB requester-transfer
object:

```text
(apb-requester apb_requester ...)
```

The source body, local signals, APB bus bindings, transfer phase semantics,
latency bounds, generated report schema, generated review artifacts, and HDL
module match the selected `.ppif` APB requester-transfer source.

## Lowering And Reports

The `.apb` sample lowers through the same reviewable path as `.ppif`:

```text
.apb / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

The generated review artifacts are:

```text
apb_requester.isf
apb_requester.fsm
```

The generated HDL module remains:

```text
apb_requester
```

The IAL2 report schema remains:

```text
fsmgen.ial2.protocol_intent.apb_requester_transfer.v1
```

Check JSON and semantic JSON keep the authored `.apb` path as the public source
path while describing the generated `.fsm` semantic root.

Support accounting records the alias sample as:

```text
entry_id: intent.apb_profile_alias_requester_transfer
coverage: ial2_apb_profile_alias_requester_transfer_pipeline_cli
source_kind: ial2_profile_alias
```

## CLI Examples

Emit the APB IAL2 schedule/report JSON:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer.apb
```

Run a strict check without writing HDL:

```bash
./bin/fsmgen --strict --check --json ppif/apb_requester_transfer.apb
```

Emit normalized semantic JSON:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/apb_requester_transfer.apb
```

Materialize the generated review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-alias \
  --output /tmp/fsmgen-apb-alias/apb_requester.sv \
  ppif/apb_requester_transfer.apb
```

## Diagnostics

`.apb` diagnostics are distinct from generic parse failures:

- a missing `(profile ...)` clause is rejected as a missing profile;
- any non-APB profile such as `(profile valid-ready)` or `(profile axi4)` is
  rejected as a suffix/profile mismatch;
- Valid-Ready, AXI manager, APB completer, APB interconnect, bundle, mixed
  object, or broader APB behavior is rejected as outside the first APB
  profile-alias slice;
- `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` remain
  known IAL2 alias candidates but unsupported; and
- an unrelated suffix such as `.foo` is reported as an unknown source suffix.

## Non-Goals

This slice does not change `.ppif` behavior, `.axi` behavior, AXI manager
behavior, APB `.ppif` behavior, `.isf` behavior, `.fsm` behavior, backend
behavior, verification-output behavior, backend-language variants, VHDL
behavior, or direct IAL2-to-IAL0 lowering.

APB completer/interconnect generation, sidebands, alternate widths,
multi-peripheral decode, back-to-back transfer policy, implicit profile
inference from the suffix, direct backend lowering, and VHDL remain deferred.

## Validation

The behavior is covered by:

```bash
perl -c bin/fsmgen
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1470-ial2-apb-profile-alias.t
perl -Iperl -c t/248-regression-corpus-accounting.t
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/1470-ial2-apb-profile-alias.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```
