# IAL2 AHB Profile-Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.700`

Date: 2026-06-29

## Outcome

FSMGen now ships the bounded AHB requester profile-alias source:

```text
ppif/ahb_requester.ahb
```

The alias mirrors the shipped generic requester source:

```text
ppif/ahb_requester.ppif
```

`.ahb` is an IAL2 profile-alias surface over the same
`protocol-platform-intent` model as `.ppif`. It is not a separate language,
not an AHB-to-FSM shortcut, not a direct backend path, and not broader AHB
behavior.

## Source Shape

The checked-in alias keeps explicit profile intent:

```text
(protocol-platform-intent ahb_requester
  (profile ahb)
  (source
    (object fsmgen-ahb-requester)
    (anchor
      (document FSMGEN-AHB-REQUESTER-CAPTURE-WORKSHEET)
      (section bounded-requester)
      (page stage-1)))
  (ahb-requester amba_requester
    ...))
```

The suffix does not infer the profile. `.ahb` accepts only explicit
`(profile ahb)` and exactly one `(ahb-requester amba_requester ...)` object in
this slice.

## Lowering And Reports

The alias lowers through the same reviewable chain as the generic `.ppif`
source:

```text
.ahb / IAL2 -> generated amba_requester.isf / IAL1 -> generated amba_requester.fsm / IAL0 -> HDL module amba_requester
```

The generated review artifacts are byte-for-byte equivalent to the generic
`.ppif` source:

```text
amba_requester.isf
amba_requester.fsm
```

Check JSON and semantic JSON keep the authored `.ahb` source path. Schedule
JSON reports schema `fsmgen.ial2.protocol_intent.ahb_requester.v1`, target
profile `ahb`, generated `amba_requester.isf`, generated
`amba_requester.fsm`, and direct IAL2-to-IAL0 lowering disabled.

The generic `.ppif` report still preserves its historical
`ahb_profile_alias_deferred` residue. The `.ahb` alias removes that stale
residue from alias reports because the alias itself is now shipped. Broader
AHB residue remains explicit.

## Support Accounting

The alias fixture is support-accounted as:

```text
id: intent.ahb_profile_alias_requester
relpath: ppif/ahb_requester.ahb
family: protocol_fixture
classification: supported_smoke
coverage: ial2_ahb_profile_alias_requester_pipeline_cli
source_kind: ial2_profile_alias
strict_supported: 1
expected_module_name: amba_requester
expected_semantic_source_root_kind: fsm
```

The generic `.ppif` fixture keeps its existing identity
`intent.ppif_ahb_requester` with `source_kind` `ppif`.

## Diagnostics

`.ahb` diagnostics stay distinct:

- missing `(profile ...)` is rejected as a missing profile;
- a profile other than `ahb` is rejected as a `.ahb` suffix/profile mismatch;
- a non-AHB object under `(profile ahb)` is rejected as unsupported `.ahb`
  object breadth;
- duplicate AHB requester objects are rejected;
- malformed bounded AHB requester fields use the same requester diagnostics as
  the generic `.ppif` source;
- `.chi`, `.ace`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` remain known
  unsupported aliases;
- unrelated suffixes remain unknown source suffixes.

## Residue

The `.ahb` behavior slice does not implement:

- AHB completers or subordinates;
- AHB interconnect/decode, arbitration fabrics, or bus matrices;
- scoreboards;
- full AHB manager behavior beyond the bounded requester;
- alternate AHB widths or response policies;
- direct IAL2-to-IAL0 or IAL2-to-HDL lowering;
- direct backend lowering;
- verification-output generation;
- backend-language variants;
- AXI, APB, or VHDL behavior.

## Validation

The slice was validated with:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -c bin/fsmgen
prove -v t/1474-ial2-ahb-profile-alias.t
prove -v t/1473-ial2-ahb-requester.t
prove -v t/248-regression-corpus-accounting.t
prove -v t/297-capability-manifest.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --outdir /tmp/fsmgen-700-ahb-alias-out ppif/ahb_requester.ahb
```

The alias probes passed, support accounting matched
`intent.ahb_profile_alias_requester`, generated review artifacts remained
equivalent to the `.ppif` source, and known unsupported `.chi` plus unknown
`.foo` suffix probes remained fail-closed.
