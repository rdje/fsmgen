# IAL2 AHB Interconnect/Decode Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.720`

Date: 2026-06-29

## Outcome

AHB interconnect/decode is ready for public contract selection, not direct
implementation.

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.721`, a no-behavior public AHB
interconnect/decode contract-selection leaf. `.721` must choose the exact
source vocabulary, generated review artifacts, report/support-accounting
contract, diagnostics, validation, residue migration, rollback, and next exact
implementation or prerequisite owner before any parser, generator, source,
support-accounting, manifest, test, generated-artifact, schedule/check/semantic
JSON, HDL/runtime, direct-backend, verification-output, backend-language, AXI,
APB, broader AHB, or VHDL behavior changes.

## Evidence Read

The audit read the `.719` selector, `.718` subordinate `.ahb` behavior, `.715`
subordinate `.ppif` behavior, `.700` requester `.ahb` behavior, `.697`
requester `.ppif` behavior, `.707` source-fact inventory, APB
interconnect/decode precedent, current AHB reports and residue, the AHB
requester/subordinate generators, direct AHB requester/subordinate `.fsm`
seeds, RegressionCorpus, LanguageSurfaceSection/capability-manifest surfaces,
focused AHB tests, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge
Map, and decisions `0014`, `0015`, `0016`, and `0018`.

Live probes confirmed the current public AHB endpoint surface:

```text
ppif/ahb_requester.ppif
  schema=fsmgen.ial2.protocol_intent.ahb_requester.v1
  target=ahb-requester
  entry=intent.ppif_ahb_requester
  source_kind=ppif
  coverage=ial2_ppif_ahb_requester_pipeline_cli
  module=amba_requester
  residue=ahb_profile_alias_deferred ahb_completer_subordinate_deferred ahb_interconnect_decode_deferred ahb_full_manager_deferred ahb_verification_output_deferred

ppif/ahb_requester.ahb
  schema=fsmgen.ial2.protocol_intent.ahb_requester.v1
  target=ahb-requester
  entry=intent.ahb_profile_alias_requester
  source_kind=ial2_profile_alias
  coverage=ial2_ahb_profile_alias_requester_pipeline_cli
  module=amba_requester
  residue=ahb_completer_subordinate_deferred ahb_interconnect_decode_deferred ahb_full_manager_deferred ahb_verification_output_deferred

ppif/ahb_lite_subordinate.ppif
  schema=fsmgen.ial2.protocol_intent.ahb_subordinate.v1
  target=ahb-subordinate
  entry=intent.ppif_ahb_lite_subordinate
  source_kind=ppif
  coverage=ial2_ppif_ahb_lite_subordinate_pipeline_cli
  module=ahb_lite_subordinate
  residue=ahb_subordinate_profile_alias_deferred ahb_interconnect_generation_deferred ahb_subordinate_optional_signal_residue ahb_burst_seq_support_deferred ahb_verification_output_deferred

ppif/ahb_lite_subordinate.ahb
  schema=fsmgen.ial2.protocol_intent.ahb_subordinate.v1
  target=ahb-subordinate
  entry=intent.ahb_profile_alias_subordinate
  source_kind=ial2_profile_alias
  coverage=ial2_ahb_profile_alias_subordinate_pipeline_cli
  module=ahb_lite_subordinate
  residue=ahb_interconnect_generation_deferred ahb_subordinate_optional_signal_residue ahb_burst_seq_support_deferred ahb_verification_output_deferred
```

## Endpoint Compatibility

The requester endpoint drives AHB address/control/write data and expects bus
response inputs:

```text
outputs: HBUSREQ HLOCK HADDR HTRANS HWRITE HSIZE HBURST HPROT HWDATA
inputs:  HGRANT HREADY HRESP[1:0] HRDATA[31:0]
```

The subordinate endpoint consumes local decode plus address/control/write data
and returns the selected AHB-Lite/common-AHB response:

```text
inputs:  HSEL HADDR HTRANS HWRITE HSIZE HREADY HWDATA wait_cycles
outputs: HREADYOUT HRESP[0] HRDATA[31:0]
```

The source facts support an interconnect/decode contract: each subordinate has
its own `HSELx`; selected subordinates monitor global `HREADY`; subordinates
cannot extend the address phase; and `HREADYOUT` contributes to the overall
`HREADY` stall behavior through the interconnect.

The two endpoint contracts are compatible enough for contract selection, but
not for direct implementation without another selector. The contract must
settle at least these details:

- requester `HRESP[1:0]` versus subordinate `HRESP[0]` widening;
- single-requester `HGRANT` policy;
- `HREADY` aggregation and default/unmapped response behavior;
- `HSEL` decode and local address translation;
- `HREADYOUT`, `HRESP`, and `HRDATA` mux/default behavior;
- generated interconnect review artifacts and aggregate-top naming; and
- residue-key migration between requester and subordinate reports.

## Selected First Boundary

`.721` should select a conservative first public contract:

- generic `.ppif` source first;
- one AHB requester endpoint;
- one AHB-Lite/common-AHB subordinate endpoint;
- one static address window that generates the subordinate `HSEL` and local
  address translation;
- no two-or-more-subordinate fabric in the first behavior slice;
- no multiple managers, bus matrix, arbitration fabric, or scoreboard;
- no optional AHB5/property-gated signals;
- no burst `SEQ` continuation beyond the current subordinate ERROR behavior;
- no byte-lane/narrow-transfer behavior; and
- no legacy two-bit `HRESP` subordinate compatibility beyond selected
  requester-side widening.

The generated review-artifact direction should be AHB-specific, mirroring the
APB precedent: source-level IAL2 intent lowers into generated IAL1 before
generated IAL0. `.721` should select exact names, with
`ahb_interconnect.isf` and `ahb_interconnect.fsm` as the preferred fabric
artifact pair unless the contract justifies a narrower name. An aggregate top,
if selected, must still be generated after reviewable endpoint/fabric artifacts
and must not bypass the IAL2 -> IAL1 -> IAL0 chain.

The canonical future interconnect residue key should converge on
`ahb_interconnect_decode_deferred`. The existing subordinate
`ahb_interconnect_generation_deferred` key is a historical endpoint residue and
must not be silently removed until `.721` selects a migration/report policy and
a later behavior slice implements it.

## Readiness Finding

AHB interconnect/decode is ready for contract selection because:

- public requester `.ppif` and `.ahb` entrypoints are support-accounted and
  strict-supported;
- public subordinate `.ppif` and `.ahb` entrypoints are support-accounted and
  strict-supported;
- source-backed HSEL/HREADY/HREADYOUT facts exist;
- generated IAL1 output reset/default substrate exists for subordinate
  outputs;
- APB precedent shows the correct sequencing: endpoint behavior, readiness
  audit, public contract selection, then implementation; and
- the remaining work is now contract choice, not missing source evidence.

Direct implementation is not ready because no public source shape, generated
fabric artifact shape, aggregate top name, support identity, diagnostics, or
report/residue migration contract has been selected.

## Rejected Next Owners

Direct interconnect/decode implementation is rejected until `.721` selects the
contract.

Two-or-more-subordinate AHB fabric is rejected as the first contract boundary.
It is likely the next topology after the fixed one-subordinate decode contract,
but it would mix first aggregate top behavior with mux fanout cardinality and
multi-window diagnostics.

Optional signals, burst `SEQ`, byte-lane/narrow transfers, and legacy two-bit
`HRESP` subordinate compatibility are rejected because they widen endpoint
protocol behavior before the aggregate contract is selected.

`.ahb` aggregate profile-alias exposure is rejected as the first source
surface. The generic `.ppif` interconnect/decode contract should ship first;
profile-alias exposure can follow once the aggregate contract is proven.

Direct backend behavior and verification-output generation are rejected by the
current IAL2 layered-lowering and verification-route decisions.

AXI, APB, backend-language variants, and VHDL are rejected because the active
frontier is AHB-local.

## Selected `.721` Scope

`.721` should select the public AHB interconnect/decode contract before any
behavior change. It must record:

- exact source vocabulary and object/cardinality rules;
- exact address-window syntax and local-address translation policy;
- decode priority, overlap policy, and unmapped response policy;
- requester `HGRANT` policy and `HREADY` aggregation;
- `HRESP` width conversion and unsupported RETRY/SPLIT policy;
- generated `.isf`, generated `.fsm`, aggregate top, and HDL expectations;
- report schema, support-accounting identity, source kind, coverage key, and
  focused test names;
- diagnostics for malformed topology, duplicate endpoint names, missing roles,
  overlapping windows, unsupported multiple managers, unsupported
  multi-subordinate fabric, optional signals, burst `SEQ`, byte lanes, direct
  backend, verification-output, backend-language variants, AXI, APB, and VHDL;
- residue-key convergence and preservation probes for the four existing public
  AHB entrypoints; and
- rollback boundaries.

`.721` must not change behavior.

## Validation

The audit used read-only probes:

```bash
perl -MJSON::PP=decode_json -MIPC::Cmd=run -e '
for my $path (@ARGV) {
    my ($schedule_ok, undef, undef, $schedule_out, $schedule_err) = run(
        command => ["./bin/fsmgen", "--quiet", "--emit-schedule-json", $path],
    );
    die "schedule failed $path: @{ $schedule_err || [] }\n" unless $schedule_ok;
    my $schedule = decode_json(join("", @{ $schedule_out || [] }));
    my ($check_ok, undef, undef, $check_out, $check_err) = run(
        command => ["./bin/fsmgen", "--quiet", "--strict", "--check", "--json", $path],
    );
    die "check failed $path: @{ $check_err || [] }\n" unless $check_ok;
    my $check = decode_json(join("", @{ $check_out || [] }));
    my @residue_ids = map { $_->{id} } @{$schedule->{unsupported_residue} || []};
    my $support = $check->{support_accounting} || {};
    print "$path\n";
    print "  schema=$schedule->{schema}\n";
    print "  target=$schedule->{target_protocol}{object}\n";
    print "  entry=$support->{entry_id} source_kind=$support->{source_kind} "
        . "coverage=$support->{coverage}\n";
    print "  module=$check->{result}{module_name}\n";
    print "  residue=@residue_ids\n";
}
' \
  ppif/ahb_requester.ppif \
  ppif/ahb_requester.ahb \
  ppif/ahb_lite_subordinate.ppif \
  ppif/ahb_lite_subordinate.ahb
```

Closeout must also run Knowledge Map generation/check, mdBook build, docs path
audit, memory-architecture check, diff hygiene, and the doctrine driver.

## Non-Changes

`.720` is a readiness audit only. It does not change parser, generator, source
sample, support-accounting catalog, capability manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact, HDL/runtime
behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI, APB, broader AHB behavior, or VHDL behavior.
