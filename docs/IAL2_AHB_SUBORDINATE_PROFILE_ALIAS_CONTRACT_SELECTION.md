# IAL2 AHB Subordinate Profile-Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.717`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.717` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.718`, bounded implementation of public
AHB subordinate `.ahb` profile-alias exposure.

The selected alias fixture is:

```text
ppif/ahb_lite_subordinate.ahb
```

It must mirror the shipped generic subordinate source:

```text
ppif/ahb_lite_subordinate.ppif
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test behavior,
schedule/check/semantic JSON behavior, generated artifact, HDL/runtime
behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Selected Contract

The `.ahb` subordinate alias remains the same IAL2
`protocol-platform-intent` form as the generic `.ppif` source. The suffix does
not infer the profile. The source must keep explicit profile review text:

```text
(profile ahb)
```

The first subordinate `.ahb` alias supports exactly one bounded subordinate
object:

```text
(ahb-subordinate ahb_lite_subordinate ...)
```

The object body, control signal, bus bindings, one-register storage, transfer
semantics, output reset/default policy, generated `ahb_lite_subordinate.isf`,
generated `ahb_lite_subordinate.fsm`, AHB subordinate report schema, generated
HDL module, and broader residue remain equivalent to the shipped subordinate
`.ppif` source.

The mandatory reviewable lowering chain remains:

```text
.ahb / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

Direct `.ahb -> .fsm`, direct `.ahb -> HDL`, direct IAL2-to-IAL0 lowering,
and direct backend lowering remain forbidden.

## Required `.718` Implementation Boundaries

`.718` should implement only the selected AHB subordinate `.ahb` alias while
preserving the existing requester `.ahb` alias. It should:

- add `ppif/ahb_lite_subordinate.ahb` as the public alias fixture, mirroring
  `ppif/ahb_lite_subordinate.ppif`;
- route subordinate `.ahb` through the same PPIF-backed IAL2 lowering stack;
- keep explicit `(profile ahb)` mandatory and reject non-AHB profiles as
  suffix/profile mismatches;
- update `.ahb` validation to accept either the already shipped requester
  object or the newly selected subordinate object, but never mixed requester
  and subordinate objects;
- keep generated subordinate review artifacts
  `ahb_lite_subordinate.isf` and `ahb_lite_subordinate.fsm`;
- keep generated HDL module `ahb_lite_subordinate`;
- keep report schema `fsmgen.ial2.protocol_intent.ahb_subordinate.v1`;
- keep authored `.ahb` source paths visible in check JSON, semantic JSON,
  diagnostics, reports, and support-accounting evidence;
- support-account the alias fixture as `intent.ahb_profile_alias_subordinate`;
- use coverage key `ial2_ahb_profile_alias_subordinate_pipeline_cli`;
- use `source_kind => 'ial2_profile_alias'`;
- remove `ahb_subordinate_profile_alias_deferred` from subordinate `.ahb`
  reports only, while preserving that residue in generic subordinate `.ppif`
  reports;
- preserve broader AHB residue:
  `ahb_interconnect_generation_deferred`,
  `ahb_subordinate_optional_signal_residue`,
  `ahb_burst_seq_support_deferred`, and
  `ahb_verification_output_deferred`;
- update help text and language-surface/capability-manifest wording so `.ahb`
  is described as a bounded requester and subordinate profile-alias surface;
- keep the existing requester `.ahb` support identity
  `intent.ahb_profile_alias_requester` unchanged;
- add focused subordinate alias coverage, selected as
  `t/1477-ial2-ahb-subordinate-profile-alias.t`; and
- update existing subordinate/profile-alias tests that currently assert
  requester-only `.ahb` behavior.

The implementation may keep the manifest's singular representative
`sample_path` on the existing requester alias if the current contract shape has
only one sample path field, but the manifest/current-boundary prose must name
both the requester and subordinate alias fixtures.

## Diagnostics

`.718` should keep `.ahb` diagnostics distinct:

- missing profile: `.ahb` source has no `(profile ...)` clause;
- suffix/profile mismatch: `.ahb` source declares any profile other than
  `ahb`;
- unsupported `.ahb` object breadth: `.ahb` source requests Valid-Ready, AXI,
  APB, AHB interconnect/decode, or another unselected object under
  `(profile ahb)`;
- mixed AHB objects: `.ahb` source mixes requester and subordinate objects;
- duplicate supported objects: `.ahb` source has more than one requester or
  more than one subordinate object; and
- malformed subordinate syntax: the selected subordinate object exists but
  violates the shipped subordinate source-shape contract.

The first implementation may continue to rely on focused error-text
assertions rather than a new stable diagnostic-code family.

## Public Contract

The subordinate `.ahb` alias is a public file-surface convenience over the
same IAL2 semantics as `ppif/ahb_lite_subordinate.ppif`. Equivalent `.ppif`
and `.ahb` subordinate inputs must preserve the same AHB behavior and review
artifacts while reporting the authored source path of the file the user ran.

The generic subordinate `.ppif` report should continue to carry
`ahb_subordinate_profile_alias_deferred` as historical/future-surface residue.
Only the subordinate `.ahb` alias report should remove that stale alias
residue.

## Non-Goals

This contract selection does not implement `.ahb` subordinate behavior and
does not accept any new source. It does not infer AHB profiles from suffixes,
change requester `.ahb` behavior, add `.chi`, `.ace`, `.atb`, `.smbus`, `.i2s`,
`.pif`, or `.ppi`, add AHB interconnect/decode, optional signals, burst `SEQ`,
byte-lane/narrow-transfer behavior, legacy two-bit `HRESP` compatibility,
scoreboards, full-manager behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, or VHDL behavior.

## Validation

Closeout for this selector is documentation-only plus direct current-behavior
reverification:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'local $/ = undef; open my $fh, "<", "ppif/ahb_lite_subordinate.ppif" or die $!; my $src = <$fh>; my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($src, "ahb_lite_subordinate.ahb"); 1 }; print $ok ? "unexpected success\n" : $@;'
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

At `.717` closeout, the subordinate `.ahb` probe is expected to fail closed
until `.718` implements the selected contract.

## Rollback

Rollback is documentation-only: remove this contract-selection document, its
Knowledge Map fact card, task-tree advancement, README/ROADMAP_V2/mdBook sync,
and Memory pointer. No parser, manifest, generator, sample, support-accounting,
generated HDL, runtime, or backend artifact rollback is required.
