# IAL2 AHB Subordinate Profile-Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.718`

Date: 2026-06-29

## Outcome

FSMGen now ships the bounded AHB subordinate profile-alias source:

```text
ppif/ahb_lite_subordinate.ahb
```

The alias mirrors the shipped generic subordinate source:

```text
ppif/ahb_lite_subordinate.ppif
```

`.ahb` remains an IAL2 profile-alias surface over the same
`protocol-platform-intent` model as `.ppif`. It is not a separate language,
not an AHB-to-FSM shortcut, not a direct backend path, and not broader AHB
behavior.

## Source Shape

The checked-in alias keeps explicit profile intent:

```text
(protocol-platform-intent ahb_lite_subordinate
  (profile ahb)
  (source
    (object fsmgen-ahb-lite-subordinate)
    (anchor
      (document ARM-AMBA-AHB-IHI0033-C-2021-09)
      (section bounded-ahb-lite-subordinate)
      (page first-public-contract)))
  (ahb-subordinate ahb_lite_subordinate
    ...))
```

The suffix does not infer the profile. `.ahb` accepts explicit `(profile ahb)`
and exactly one selected AHB object: either the shipped requester
`(ahb-requester amba_requester ...)` or the shipped subordinate
`(ahb-subordinate ahb_lite_subordinate ...)`.

## Lowering And Reports

The subordinate alias lowers through the same reviewable chain as the generic
`.ppif` source:

```text
.ahb / IAL2 -> generated ahb_lite_subordinate.isf / IAL1 -> generated ahb_lite_subordinate.fsm / IAL0 -> HDL module ahb_lite_subordinate
```

The generated review artifacts are byte-for-byte equivalent to the generic
`.ppif` source:

```text
ahb_lite_subordinate.isf
ahb_lite_subordinate.fsm
```

Check JSON and semantic JSON keep the authored `.ahb` source path. Schedule
JSON reports schema `fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, target
profile `ahb`, target object `ahb-subordinate`, generated
`ahb_lite_subordinate.isf`, generated `ahb_lite_subordinate.fsm`, selected
output defaults, and direct IAL2-to-IAL0 lowering disabled.

The generic subordinate `.ppif` report still preserves its historical
`ahb_subordinate_profile_alias_deferred` residue. The subordinate `.ahb` alias
removes that stale residue from alias reports because the alias itself is now
shipped. Broader AHB residue remains explicit:

```text
ahb_interconnect_generation_deferred
ahb_subordinate_optional_signal_residue
ahb_burst_seq_support_deferred
ahb_verification_output_deferred
```

## Support Accounting

The alias fixture is support-accounted as:

```text
id: intent.ahb_profile_alias_subordinate
relpath: ppif/ahb_lite_subordinate.ahb
family: protocol_fixture
classification: supported_smoke
coverage: ial2_ahb_profile_alias_subordinate_pipeline_cli
source_kind: ial2_profile_alias
strict_supported: 1
expected_module_name: ahb_lite_subordinate
expected_semantic_source_root_kind: fsm
```

The generic `.ppif` fixture keeps its existing identity
`intent.ppif_ahb_lite_subordinate` with `source_kind` `ppif`.

## Diagnostics

`.ahb` diagnostics stay distinct:

- missing `(profile ...)` is rejected as a missing profile;
- a profile other than `ahb` is rejected as a `.ahb` suffix/profile mismatch;
- a non-AHB object under `(profile ahb)` is rejected as unsupported `.ahb`
  object breadth;
- mixed requester/subordinate objects are rejected;
- duplicate AHB requester or subordinate objects are rejected;
- malformed bounded AHB subordinate fields use the same subordinate
  diagnostics as the generic `.ppif` source;
- `.chi`, `.ace`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` remain known
  unsupported aliases;
- unrelated suffixes remain unknown source suffixes.

## Residue

The subordinate `.ahb` behavior slice does not implement:

- AHB completers;
- AHB interconnect/decode, arbitration fabrics, or bus matrices;
- optional/property-gated AHB signals;
- burst `SEQ` continuation beyond selected ERROR behavior;
- byte-lane or narrow-transfer behavior;
- legacy two-bit `HRESP` compatibility;
- AHB scoreboards;
- full AHB manager behavior beyond the bounded requester;
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
perl -Iperl -c t/1477-ial2-ahb-subordinate-profile-alias.t
prove -Iperl t/1474-ial2-ahb-profile-alias.t t/1475-ial2-ahb-subordinate.t t/1477-ial2-ahb-subordinate-profile-alias.t t/297-capability-manifest.t
scripts/run_with_ram_guard.sh prove -Iperl t/248-regression-corpus-accounting.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ahb
```

The alias probes passed, support accounting matched
`intent.ahb_profile_alias_subordinate`, generated review artifacts remained
equivalent to the `.ppif` source, and the generic subordinate `.ppif` report
continued to carry `ahb_subordinate_profile_alias_deferred`.
