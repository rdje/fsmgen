# IAL2 APB Profile-Alias Completer/Composition Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.568`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.568` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.569`, direct bounded implementation of APB
`.apb` profile-alias widening for the already-shipped APB completer and fixed
requester/completer composition shapes.

This selector changes no parser, generator, sample, support-accounting,
manifest, test, schedule/check/semantic JSON, HDL/runtime, direct backend,
verification-output, backend-language variant, AXI, APB, or VHDL behavior.

## Evidence Read

The selector read the shipped APB profile and generic-container surfaces:

- APB requester-transfer `.ppif` behavior from `.550`;
- APB requester-transfer `.apb` alias behavior from `.554`;
- APB completer `.ppif` behavior from `.562`;
- fixed APB requester/completer composition `.ppif` behavior from `.566`;
- the `.567` post-composition selector;
- `ppif/apb_requester_transfer.apb`;
- `ppif/apb_completer.ppif`;
- `ppif/apb_composition.ppif`;
- current APB report schemas, generated review artifacts, and residue;
- current `FSM::Adapter::IAL2::PPIF` profile-alias validation;
- `RegressionCorpus` support-accounting identities;
- `LanguageSurfaceSection` source-kind boundaries; and
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

Exact probes confirmed the current public boundary:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition.ppif
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-pnt568-apb-completer.apb
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-pnt568-apb-composition.apb
```

The first three probes pass. Temporary `.apb` copies of the APB completer and
APB composition sources still fail closed with the current requester-transfer-
only alias diagnostic.

## Selected Public Contract

The next behavior slice must add these authored source paths:

```text
ppif/apb_completer.apb
ppif/apb_composition.apb
```

Both files must mirror the already-shipped generic `.ppif` source shapes and
must keep explicit APB profile declaration:

```text
(profile apb)
```

The `.apb` suffix remains a profile alias over IAL2
`protocol-platform-intent`. It does not infer the profile from the suffix, does
not define a separate APB language, does not lower directly to `.fsm`, and does
not bypass generated `.isf` review artifacts.

After `.569`, `.apb` should accept exactly these bounded APB source shapes:

- one APB requester-transfer object, already shipped as
  `ppif/apb_requester_transfer.apb`;
- one APB completer object:
  `(apb-completer apb_completer ...)`; or
- the fixed composition aggregate with one requester, one completer, and one
  explicit `(apb-composition apb_tb ...)` object.

## Support And Source Identity

The selected support-accounting entries are:

```text
intent.apb_profile_alias_completer
intent.apb_profile_alias_composition
```

The selected coverage names are:

```text
ial2_apb_profile_alias_completer_pipeline_cli
ial2_apb_profile_alias_composition_pipeline_cli
```

Both entries must use:

```text
source_kind: ial2_profile_alias
```

Check JSON and semantic JSON must preserve the authored `.apb` source path as
the public source identity.

The APB completer alias must keep the existing generated behavior contract:

```text
report schema: fsmgen.ial2.protocol_intent.apb_completer.v1
generated artifacts: apb_completer.isf, apb_completer.fsm
HDL module: apb_completer
semantic root kind: fsm
```

The APB composition alias must keep the existing generated behavior contract:

```text
report schema: fsmgen.ial2.protocol_intent.apb_composition.v1
generated artifacts: apb_requester.isf, apb_completer.isf,
  apb_requester.fsm, apb_completer.fsm, apb_tb.fsm
HDL entry: apb_tb.fsm
expected top: apb_tb
expected children: apb_requester, apb_completer
expected instance count: 2
semantic root kind: top
```

## Diagnostics

`.569` must preserve focused fail-closed diagnostics for:

- missing `(profile ...)`;
- non-APB profiles under `.apb`;
- Valid-Ready, AXI manager, bundle, and other non-APB source shapes under
  `.apb`;
- APB mixed requester/completer files that omit the explicit
  `(apb-composition ...)` object;
- malformed APB composition objects;
- multi-peripheral APB interconnect/decode attempts;
- unsupported APB source shapes; and
- still-unsupported aliases such as `.chi`, `.ace`, `.ahb`, `.atb`,
  `.smbus`, `.i2s`, `.pif`, and `.ppi`.

## Validation Plan

The implementation owner should add focused coverage for:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_completer.apb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_completer.apb
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_composition.apb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition.apb
```

It should also prove generated review-artifact materialization with `--outdir`,
support-accounting coverage, capability-manifest/source-kind alignment, the
existing requester-transfer `.apb` path, the generic `.ppif` completer and
composition paths, targeted negative diagnostics, mdBook synchronization,
Knowledge Map synchronization, memory/doc path gates, and the doctrine gate.

## Rejected Alternatives

Splitting APB completer alias exposure and APB composition alias exposure into
separate implementation leaves is rejected for this bounded widening because
both underlying generic `.ppif` behaviors already exist, both use the same
profile-alias mechanism, and the selected diagnostics are shared.

Immediate multi-peripheral APB interconnect/decode is rejected because the
shipped composition is fixed one-requester/one-completer wiring. Address maps,
peripheral selection, decode errors, and top-level port shape need a separate
public contract.

Requester `busy`/status exposure, multi-register decode, sidebands/strobes,
alternate widths, back-to-back requester policy, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, and
VHDL remain deferred because they change endpoint or backend behavior rather
than exposing the already-shipped behavior through the existing alias suffix.

## Rollback

Rollback of `.568` removes this selector record, its Knowledge Map fact card,
and the README/ROADMAP/mdBook/task-tree/memory updates. No runtime behavior,
sample, parser rule, generator, support-accounting entry, test, generated
artifact, or public suffix behavior is changed by this selector.
