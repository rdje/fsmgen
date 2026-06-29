# IAL2 Post AHB Subordinate PPIF Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.716`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.716` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.717`, a public contract-selection leaf for
AHB subordinate `.ahb` profile-alias exposure after the public subordinate
`.ppif` path shipped.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test behavior,
schedule/check/semantic JSON behavior, generated artifact, HDL/runtime
behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Evidence Read

The selector read the current shipped AHB surfaces:

- `ppif/ahb_requester.ppif`, the bounded generic AHB requester IAL2 source;
- `ppif/ahb_requester.ahb`, the bounded requester `.ahb` profile alias;
- `ppif/ahb_lite_subordinate.ppif`, the bounded generic AHB subordinate IAL2
  source;
- direct seeds `fsm/amba_requester.fsm` and `fsm/ahb_lite_subordinate.fsm`;
- AHB requester `.ppif` and `.ahb` behavior records;
- AHB subordinate public contract, generated-substrate audit, output
  reset/default substrate, and shipped `.ppif` behavior records;
- the AHB mdBook current-boundary chapter and IAL2 overview;
- `FSM::Adapter::IAL2::PPIF` suffix/profile validation and AHB object dispatch;
- `FSM::IAL2::ProtocolIntent::AhbRequester` and
  `FSM::IAL2::ProtocolIntent::AhbSubordinate` report/residue behavior;
- `RegressionCorpus` and `LanguageSurfaceSection` AHB entries;
- focused AHB requester/profile-alias/subordinate tests; and
- README, ROADMAP_V2, task tree, Memory, Knowledge Map, and decisions
  `0015`, `0016`, and `0018`.

Focused probes revalidated the current public boundary:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'local $/ = undef; open my $fh, "<", "ppif/ahb_lite_subordinate.ppif" or die $!; my $src = <$fh>; my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($src, "ahb_lite_subordinate.ahb"); 1 }; print $ok ? "unexpected success\n" : $@;'
```

The subordinate `.ppif` check reports module `ahb_lite_subordinate` and
support identity `intent.ppif_ahb_lite_subordinate`, `source_kind ppif`,
coverage `ial2_ppif_ahb_lite_subordinate_pipeline_cli`. Its schedule report
keeps schema `fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, generated
`ahb_lite_subordinate.isf` before `ahb_lite_subordinate.fsm`, and the residue:

```text
ahb_subordinate_profile_alias_deferred
ahb_interconnect_generation_deferred
ahb_subordinate_optional_signal_residue
ahb_burst_seq_support_deferred
ahb_verification_output_deferred
```

The requester `.ahb` check still reports support identity
`intent.ahb_profile_alias_requester`, `source_kind ial2_profile_alias`,
coverage `ial2_ahb_profile_alias_requester_pipeline_cli`. Parsing the
subordinate source under an `.ahb` label still fails closed with the current
requester-only `.ahb` diagnostic.

## Selection

The next owner is a public contract selector, not implementation:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.717
```

`.717` must select the exact future AHB subordinate `.ahb` profile-alias
contract before parser/generator/source/support-accounting behavior changes.
It must define:

- the future alias path, expected to mirror
  `ppif/ahb_lite_subordinate.ppif` at a selected `.ahb` path;
- explicit `(profile ahb)` policy and suffix/profile mismatch behavior;
- the exact supported object shape, expected to remain exactly one
  `(ahb-subordinate ahb_lite_subordinate ...)` object;
- generated review artifacts, expected to remain
  `ahb_lite_subordinate.isf` before `ahb_lite_subordinate.fsm`;
- report schema and authored source-path identity expectations;
- support-accounting identity, coverage key, and `source_kind`;
- whether `.717` can route directly to implementation or must first run a
  readiness audit;
- diagnostics for missing profile, non-AHB profile, unsupported `.ahb`
  objects, mixed AHB requester/subordinate objects, duplicate objects, and
  malformed subordinate clauses;
- residue movement for alias-only reports while preserving broader AHB
  residue; and
- focused validation, docs, Knowledge Map, rollback, and VHDL deferral.

The selector favors subordinate `.ahb` alias contract selection because the
subordinate `.ppif` behavior is now shipped, the `.ahb` profile-alias substrate
already exists for requester sources, and `ahb_subordinate_profile_alias_deferred`
is the first explicit subordinate residue in the public report and mdBook
boundary. AHB interconnect/decode, optional signals, burst `SEQ`,
byte-lane/narrow-transfer behavior, legacy two-bit `HRESP`, direct backend
behavior, verification-output generation, backend-language variants, AXI, APB,
and VHDL remain future owners.

## Rejected Alternatives

Immediate subordinate `.ahb` implementation is rejected because the alias path,
support identity, coverage key, manifest wording, residue movement, and
diagnostic policy are not selected yet.

AHB interconnect/decode is rejected as the next owner because the simpler
public alias exposure residue can be closed first without changing AHB
topology, arbitration, decode, or aggregate fabric behavior.

Optional AHB signals, burst `SEQ`, byte-lane/narrow-transfer behavior, and
legacy two-bit `HRESP` compatibility are rejected as the next owner because
they change subordinate protocol behavior. The current selector keeps those
behavioral expansions behind later source-backed contracts.

Direct backend behavior and verification-output generation are rejected
because decisions `0014` and the existing verification-route fact keep IAL2
lowering through generated `.isf` before generated `.fsm` and keep direct
`.ppif`/profile-alias verification-output routes unselected.

AXI, APB, backend-language variants, and VHDL are rejected because the current
frontier is AHB-local and SystemVerilog-backed IAL2 feature completeness still
has a narrow public-surface residue.

## Validation

This selector is validated with:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'local $/ = undef; open my $fh, "<", "ppif/ahb_lite_subordinate.ppif" or die $!; my $src = <$fh>; my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($src, "ahb_lite_subordinate.ahb"); 1 }; print $ok ? "unexpected success\n" : $@;'
```

The final `.716` closeout reruns Knowledge Map, mdBook, docs path, memory,
diff, and doctrine gates.

## Rollback

Rollback of `.716` removes this selector record, its Knowledge Map fact card,
and the README/ROADMAP/mdBook/task-tree/Memory updates. No runtime behavior,
source sample, parser rule, generator, support-accounting entry, test,
generated artifact, public suffix behavior, direct backend behavior, or
backend-language behavior is changed by this selector.
