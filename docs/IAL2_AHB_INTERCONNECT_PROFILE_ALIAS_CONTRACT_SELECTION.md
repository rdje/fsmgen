# IAL2 AHB Interconnect Profile-Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.725`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.725` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.726`, bounded implementation of public
AHB aggregate `.ahb` profile-alias exposure.

The selected alias fixture is:

```text
ppif/ahb_interconnect.ahb
```

It must mirror the shipped generic aggregate interconnect source:

```text
ppif/ahb_interconnect.ppif
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Selected Contract

The aggregate `.ahb` interconnect alias remains the same IAL2
`protocol-platform-intent` form as the generic `.ppif` source. The suffix does
not infer the profile. The source must keep explicit profile review text:

```text
(profile ahb)
```

The aggregate `.ahb` alias supports exactly the already shipped bounded
interconnect aggregate shape:

```text
(ahb-requester amba_requester ...)
(ahb-subordinate ahb_lite_subordinate ...)
(ahb-interconnect ahb_tb ...)
```

The object bodies, child references, one static address window, decode policy,
wiring, generated review artifacts, generated HDL module, and AHB
interconnect report schema remain equivalent to the shipped generic `.ppif`
source.

The mandatory reviewable lowering chain remains:

```text
.ahb / IAL2
  -> generated amba_requester.isf
  -> generated ahb_lite_subordinate.isf
  -> generated ahb_interconnect.isf
  -> generated amba_requester.fsm
  -> generated ahb_lite_subordinate.fsm
  -> generated ahb_interconnect.fsm
  -> generated ahb_tb.fsm
  -> HDL module ahb_tb
```

Direct `.ahb -> .fsm`, direct `.ahb -> HDL`, direct IAL2-to-IAL0 lowering,
and direct backend lowering remain forbidden.

## Required `.726` Implementation Boundaries

`.726` should implement only the selected aggregate AHB interconnect `.ahb`
alias while preserving the existing requester and subordinate `.ahb` aliases.
It should:

- add `ppif/ahb_interconnect.ahb` as the public alias fixture, mirroring
  `ppif/ahb_interconnect.ppif`;
- route aggregate `.ahb` through the same PPIF-backed IAL2 lowering stack;
- keep explicit `(profile ahb)` mandatory and reject non-AHB profiles as
  suffix/profile mismatches;
- update `.ahb` validation to accept either the shipped requester endpoint,
  the shipped subordinate endpoint, or the newly selected aggregate
  interconnect shape;
- reject duplicate requester/subordinate/interconnect objects and unsupported
  mixed objects outside the selected aggregate shape;
- keep generated review artifacts
  `amba_requester.isf`, `ahb_lite_subordinate.isf`,
  `ahb_interconnect.isf`, `amba_requester.fsm`,
  `ahb_lite_subordinate.fsm`, `ahb_interconnect.fsm`, and `ahb_tb.fsm`;
- keep generated HDL module `ahb_tb`;
- keep report schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`;
- keep authored `.ahb` source paths visible in check JSON, semantic JSON,
  diagnostics, reports, and support-accounting evidence;
- support-account the alias fixture as `intent.ahb_profile_alias_interconnect`;
- use coverage key `ial2_ahb_profile_alias_interconnect_pipeline_cli`;
- use `source_kind => 'ial2_profile_alias'`;
- use expected semantic source-root kind `top`;
- remove `ahb_aggregate_profile_alias_deferred` from aggregate `.ahb`
  reports only, while preserving that residue in generic interconnect `.ppif`
  reports;
- preserve broader AHB residue:
  `ahb_multi_subordinate_decode_deferred`,
  `ahb_optional_signal_residue`,
  `ahb_burst_seq_support_deferred`,
  `ahb_direct_backend_deferred`, and
  `ahb_verification_output_deferred`;
- update help text and language-surface/capability-manifest wording so `.ahb`
  is described as a bounded requester, subordinate, and aggregate interconnect
  profile-alias surface;
- keep existing requester and subordinate `.ahb` support identities unchanged;
- add focused aggregate alias coverage, selected as
  `t/1479-ial2-ahb-interconnect-profile-alias.t`; and
- update existing AHB interconnect tests that currently assert aggregate `.ahb`
  rejection.

The implementation may keep the manifest's singular representative
`sample_path` on the existing requester alias if the current contract shape has
only one sample path field, but the manifest/current-boundary prose must name
all three `.ahb` alias fixtures.

## Diagnostics

`.726` should keep `.ahb` diagnostics distinct:

- missing profile: `.ahb` source has no `(profile ...)` clause;
- suffix/profile mismatch: `.ahb` source declares any profile other than
  `ahb`;
- unsupported `.ahb` object breadth: `.ahb` source requests Valid-Ready, AXI,
  APB, a broader AHB object, or another unselected object under
  `(profile ahb)`;
- malformed aggregate shape: `.ahb` source has an interconnect but does not
  have exactly one requester, one subordinate, and one interconnect object;
- duplicate supported objects: `.ahb` source has more than one requester,
  subordinate, or interconnect object; and
- malformed interconnect syntax: the selected aggregate object exists but
  violates the shipped `ppif/ahb_interconnect.ppif` source-shape contract.

The first implementation may continue to rely on focused error-text
assertions rather than a new stable diagnostic-code family.

## Public Contract

The aggregate `.ahb` alias is a public file-surface convenience over the same
IAL2 semantics as `ppif/ahb_interconnect.ppif`. Equivalent `.ppif` and `.ahb`
aggregate inputs must preserve the same AHB behavior and review artifacts
while reporting the authored source path of the file the user ran.

The generic interconnect `.ppif` report should continue to carry
`ahb_aggregate_profile_alias_deferred` as historical/future-surface residue.
Only the aggregate `.ahb` alias report should remove that stale alias residue.

## Non-Goals

This contract selection does not implement `.ahb` aggregate behavior and does
not accept any new source. It does not infer AHB profiles from suffixes, change
requester or subordinate `.ahb` behavior, add `.chi`, `.ace`, `.atb`,
`.smbus`, `.i2s`, `.pif`, or `.ppi`, add multi-subordinate decode, multiple
managers, arbitration fabrics, bus matrices, optional signals, burst `SEQ`,
byte-lane/narrow-transfer behavior, legacy two-bit `HRESP` compatibility,
scoreboards, full-manager behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, or VHDL behavior.

## Validation

Closeout for this selector is documentation-only plus direct current-behavior
reverification:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'local $/ = undef; open my $fh, "<", "ppif/ahb_interconnect.ppif" or die $!; my $src = <$fh>; my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($src, "ahb_interconnect.ahb"); 1 }; print $ok ? "unexpected success\n" : $@;'
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

At `.725` closeout, the aggregate `.ahb` probe is expected to fail closed
until `.726` implements the selected contract.

## Rollback

Rollback is documentation-only: remove this contract-selection document, its
Knowledge Map fact card, task-tree advancement, README/ROADMAP_V2/mdBook sync,
and Memory pointer. No parser, manifest, generator, sample, support-accounting,
generated HDL, runtime, or backend artifact rollback is required.
