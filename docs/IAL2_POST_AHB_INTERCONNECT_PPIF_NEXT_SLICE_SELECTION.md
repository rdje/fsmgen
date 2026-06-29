# Post AHB Interconnect PPIF Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.724`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.724` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.725`, AHB aggregate `.ahb`
profile-alias contract selection.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Shipped Behavior

`.723` ships the generic public AHB interconnect/decode source:

```text
ppif/ahb_interconnect.ppif
```

The source embeds one requester, one subordinate, and one interconnect object,
lowers through generated requester/subordinate/interconnect `.isf` and `.fsm`
review artifacts, emits aggregate `ahb_tb.fsm`, and generates HDL module
`ahb_tb`. Its report schema is
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, and support accounting is:

```text
entry_id: intent.ppif_ahb_interconnect
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_pipeline_cli
```

The `.ahb` endpoint aliases are also shipped:

```text
ppif/ahb_requester.ahb
ppif/ahb_lite_subordinate.ahb
```

The aggregate `.ahb` interconnect alias is not shipped. A source with the
`ppif/ahb_interconnect.ppif` body and an `.ahb` source label currently fails
closed because `.ahb` accepts exactly one bounded requester endpoint or one
bounded subordinate endpoint in the shipped surface.

The interconnect report keeps this residue explicit:

```text
ahb_aggregate_profile_alias_deferred
```

## Selection Rationale

The aggregate `.ahb` alias is the narrowest next public-surface owner after
the interconnect `.ppif` shipment:

- requester and subordinate `.ahb` endpoint aliases already establish the
  suffix/profile-alias model;
- `ppif/ahb_interconnect.ppif` already proves the aggregate generated-artifact
  chain and HDL entry;
- the remaining alias work is a public file-surface and support-accounting
  contract, not new AHB decode behavior;
- selecting the alias contract before implementation keeps `.ahb` behavior
  bounded and avoids accidentally widening to multi-subordinate decode or
  bus-matrix behavior; and
- broader AHB residues should remain explicit until each has its own exact
  task-tree owner.

Multi-subordinate decode, multiple managers, arbitration, bus matrices,
optional signals, burst `SEQ` continuation, byte-lane/narrow-transfer
behavior, AHB completer behavior, direct backend behavior, verification-output
generation, AXI/APB behavior, and VHDL are larger behavior-bearing slices and
are not the next owner selected by `.724`.

## Selected `.725` Owner

`.725` must select the exact public aggregate AHB `.ahb` profile-alias
contract before behavior changes. The expected future alias candidate is:

```text
ppif/ahb_interconnect.ahb
```

The selected contract should decide and record:

- whether the alias mirrors `ppif/ahb_interconnect.ppif` byte-for-byte except
  for the authored path;
- explicit `(profile ahb)` requirements and suffix/profile mismatch
  diagnostics;
- cardinality rules for one requester, one subordinate, and one interconnect
  object under `.ahb`;
- generated review artifacts
  `amba_requester.isf`, `ahb_lite_subordinate.isf`, `ahb_interconnect.isf`,
  `amba_requester.fsm`, `ahb_lite_subordinate.fsm`,
  `ahb_interconnect.fsm`, and `ahb_tb.fsm`;
- generated HDL entry `ahb_tb`;
- report schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`;
- support identity, likely `intent.ahb_profile_alias_interconnect`;
- coverage key, likely `ial2_ahb_profile_alias_interconnect_pipeline_cli`;
- source kind `ial2_profile_alias`;
- semantic JSON source-root kind `top`;
- removal of `ahb_aggregate_profile_alias_deferred` from aggregate `.ahb`
  reports only, while preserving it in generic `.ppif` reports;
- preservation of broader residue:
  `ahb_multi_subordinate_decode_deferred`,
  `ahb_optional_signal_residue`,
  `ahb_burst_seq_support_deferred`,
  `ahb_direct_backend_deferred`, and
  `ahb_verification_output_deferred`;
- focused implementation test name, expected to extend or pair with
  `t/1478-ial2-ahb-interconnect.t`; and
- closeout gates, rollback, and docs/mdBook/Knowledge Map expectations.

`.725` is a contract-selection owner. It must not implement the alias.

## Non-Goals

`.724` does not add or accept any new source. `.725` must not be used to add
multi-subordinate decode, multiple managers, arbitration fabrics, bus matrices,
programmable/multiple windows, optional/property-gated AHB signals, burst
`SEQ` continuation, byte-lane/narrow-transfer behavior, legacy two-bit
subordinate `HRESP`, AHB completer behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, or VHDL behavior.

## Validation

Closeout for this selector is documentation-only plus current-behavior
reverification:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ppif
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'local $/ = undef; open my $fh, "<", "ppif/ahb_interconnect.ppif" or die $!; my $src = <$fh>; my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($src, "ahb_interconnect.ahb"); 1 }; print $ok ? "unexpected success\n" : $@;'
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

At `.724` closeout, the aggregate `.ahb` probe is expected to fail closed
until a later implementation owner ships the selected alias.

## Rollback

Rollback is documentation-only: remove this selector document, its Knowledge
Map fact card, task-tree advancement, README/ROADMAP_V2/mdBook sync, and
Memory pointer. No parser, generator, source, sample, support-accounting,
generated artifact, HDL/runtime, direct backend, verification-output,
backend-language, AXI, APB, broader AHB, or VHDL rollback is required.
