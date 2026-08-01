# IAL2 AHB Interconnect/Decode Generated Substrate Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.722`

Date: 2026-06-29

## Outcome

The generated-IAL1/IAL0/SystemVerilog substrate is ready for the selected
bounded AHB interconnect/decode implementation. No smaller lower-layer repair
is required before implementing `ppif/ahb_interconnect.ppif`.

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.723`, direct bounded
implementation of the `.721` contract:

- generic `.ppif` source only;
- one requester, one subordinate, one generated AHB interconnect, and one
  aggregate top;
- one static address window;
- generated `amba_requester.isf`, `ahb_lite_subordinate.isf`, and
  `ahb_interconnect.isf` before generated `.fsm` artifacts;
- generated aggregate `ahb_tb.fsm` as HDL entry;
- report schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`;
- support identity `intent.ppif_ahb_interconnect`; and
- focused test `t/1478-ial2-ahb-interconnect.t`.

The next slice must still implement parser/generator/source/support-accounting
behavior. This audit only records that the selected behavior does not need
another substrate prerequisite.

## Evidence Read

The audit read the `.721` contract selection, `.720` readiness audit, `.719`
selector, requester/subordinate behavior docs, APB interconnect/decode
precedent, generated AHB requester/subordinate artifacts, the AHB
requester/subordinate generators, RegressionCorpus, LanguageSurfaceSection and
capability-manifest tests, focused AHB tests, README, ROADMAP_V2, mdBook, task
tree, Memory, Knowledge Map, and decisions `0014`, `0015`, `0016`, and `0018`.

Live probes also checked current generated behavior:

```text
ppif/apb_composition_multi_peripheral.ppif
  ial1=apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf
  ial0=apb_control_regs.fsm apb_interconnect.fsm apb_requester.fsm apb_status_regs.fsm apb_tb.fsm
  hdl_entry=apb_tb.fsm
  generated_interconnect=apb_interconnect.isf/apb_interconnect.fsm

ppif/ahb_requester.ppif
  ial1=amba_requester.isf
  ial0=amba_requester.fsm
  hdl_entry=amba_requester.fsm
  support=intent.ppif_ahb_requester

ppif/ahb_lite_subordinate.ppif
  ial1=ahb_lite_subordinate.isf
  ial0=ahb_lite_subordinate.fsm
  hdl_entry=ahb_lite_subordinate.fsm
  support=intent.ppif_ahb_lite_subordinate
```

The APB interconnect generated FSM probe found concrete generated-IAL0 support
for static hit comparison, local address subtraction, decoded select fanout,
response muxing, ready muxing, and unmapped error response.

The AHB subordinate generated probe confirmed generated
`ahb_lite_subordinate.isf` carries `HREADYOUT` reset/default metadata, generated
`ahb_lite_subordinate.fsm` carries reset metadata, and the current generated
FSM includes the two-step ERROR completion state needed as precedent for the
interconnect-owned unmapped ERROR.

Strict CLI checks for `ppif/ahb_requester.ppif` and
`ppif/ahb_lite_subordinate.ppif` passed and matched the expected
support-accounting identities.

## Substrate Findings

The existing substrate can express the selected AHB interconnect contract:

- constant output drive: generated IAL1/IAL0 already emits deterministic
  output defaults and constant output assignments, so `HGRANT=1` has no lower
  substrate blocker;
- static hit detection: APB generated interconnect already emits address-window
  comparisons with `>=` and `<` in generated `.fsm`;
- local address translation: APB generated interconnect already emits
  subtract-window-base local address expressions;
- decoded fanout: APB generated interconnect already emits decoded select and
  local-address fanout to endpoint instances;
- global ready feedback: generated composition tops already wire endpoint and
  interconnect ports through deterministic `?wiring` blocks;
- response muxing and defaults: APB generated interconnect already muxes
  selected ready/read-data/error response and emits inactive/unmapped defaults;
- HRESP widening: generated IAL0 already carries one-bit and two-bit ports and
  sized literals, so mapping subordinate `HRESP[0]` to requester `HRESP[1:0]`
  OKAY/ERROR is an implementation rule, not a substrate repair;
- two-cycle unmapped ERROR: current AHB subordinate generation already proves a
  stateful ERROR completion pattern through generated `.isf` to `.fsm`; and
- generated review artifacts: APB precedent already emits reusable generated
  interconnect `.isf`/`.fsm` plus an aggregate top `.fsm`.

The direct implementation must be AHB-specific. APB behavior is precedent for
artifact shape and generated lowering only; signal names, `HREADY` semantics,
`HRESP` widening, and unmapped two-cycle ERROR remain AHB-owned behavior.

## Selected `.723` Scope

`.723` should implement the exact `.721` contract and no more:

- add public source `ppif/ahb_interconnect.ppif`;
- parse one `ahb-requester`, one `ahb-subordinate`, and one
  `ahb-interconnect` object in the same source;
- generate `ahb_interconnect.isf`, `ahb_interconnect.fsm`, and aggregate
  `ahb_tb.fsm`;
- wire requester, interconnect, and subordinate child instances;
- emit `HGRANT=1`;
- decode active transfers against the one static window;
- drive `HSEL_REGS` and local subordinate `HADDR`;
- feed global `HREADY` to requester and subordinate;
- mux `HREADYOUT_REGS`, `HRDATA_REGS`, and widened `HRESP_REGS`;
- emit the selected two-cycle unmapped active-transfer ERROR;
- report the selected schema, generated artifact list, support accounting,
  address map, response policy, residue, diagnostics, and source identity; and
- add focused coverage in `t/1478-ial2-ahb-interconnect.t`.

`.723` must not add aggregate `.ahb` alias behavior, multi-subordinate fabric,
multiple managers, bus matrices, optional/property-gated AHB signals, burst
`SEQ` continuation, byte-lane or narrow-transfer behavior, legacy two-bit
subordinate `HRESP`, direct backend behavior, verification-output generation,
backend-language variants, AXI, APB behavior, or VHDL behavior.

## Validation

Read-only and temporary probes used during the audit:

```bash
perl -Iperl -MJSON::PP=encode_json -MFSM::Adapter::IAL2::PPIF -e '
for my $path (@ARGV) {
    my $parsed = FSM::Adapter::IAL2::PPIF->new()->parse_file($path);
    my $report = $parsed->{report};
    my @ial1 = ref($parsed->{generated_ial1}{items}) eq q{ARRAY}
        ? map { $_->{name} } @{$parsed->{generated_ial1}{items}}
        : ($parsed->{generated_ial1}{name});
    my @ial0 = sort keys %{$parsed->{generated_ial0}{files} || {}};
    my @residue = map { $_->{id} } @{$report->{unsupported_residue} || []};
    print "$path\n";
    print "  kind=$parsed->{kind} mode=$parsed->{mode}\n";
    print "  schema=$report->{schema}\n";
    print "  ial1=@ial1\n";
    print "  ial0=@ial0\n";
    if ($report->{generated_artifacts}{hdl_entry}{entry_artifact}) {
        print "  hdl_entry=$report->{generated_artifacts}{hdl_entry}{entry_artifact}\n";
    }
    print "  residue=@residue\n";
    if ($report->{composition}{generated_interconnect}) {
        print "  generated_interconnect="
            . "$report->{composition}{generated_interconnect}{ial1_artifact}/"
            . "$report->{composition}{generated_interconnect}{ial0_artifact}\n";
    }
    if ($report->{composition}{response_mux}) {
        print "  response_mux="
            . encode_json($report->{composition}{response_mux}) . "\n";
    }
}
' \
  ppif/apb_composition_multi_peripheral.ppif \
  ppif/ahb_requester.ppif \
  ppif/ahb_lite_subordinate.ppif
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'my $r=FSM::Adapter::IAL2::PPIF->new()->parse_file(q{ppif/apb_composition_multi_peripheral.ppif}); my $fsm=$r->{generated_ial0}{files}{q{apb_interconnect.fsm}}; for my $probe ([q{hit_compare}, qr/>= PADDR/], [q{local_address_subtract}, qr/\(- PADDR /], [q{decoded_select}, qr/PSEL_/], [q{response_mux}, qr/-response_mux/], [q{unmapped_error}, qr/PSLVERR> 1/], [q{ready_mux}, qr/PREADY>/]) { print "$probe->[0]\n" if $fsm =~ $probe->[1]; }'
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'my $r=FSM::Adapter::IAL2::PPIF->new()->parse_file(q{ppif/ahb_lite_subordinate.ppif}); my $isf=$r->{generated_ial1}{text}; my $fsm=$r->{generated_ial0}{files}{q{ahb_lite_subordinate.fsm}}; for my $probe ([q{isf_output_reset_default}, qr/output HREADYOUT \(reset 1\) \(default 1\)/], [q{fsm_two_cycle_error_state}, qr/error_complete/], [q{fsm_hresp_error_drive}, qr/HRESP> 1/]) { my ($name,$re)=@$probe; print "$name\n" if (($name =~ /^isf/ ? $isf : $fsm) =~ $re); }'
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif
```

Closeout must run Knowledge Map generation/check, mdBook build, docs path
audit, memory-architecture check, diff hygiene, and the doctrine driver.

## Non-Changes

`.722` is a generated-substrate audit only. It does not change parser,
generator, source sample, support-accounting catalog, capability manifest
behavior, focused test behavior, schedule/check/semantic JSON behavior,
generated artifact, HDL/runtime behavior, direct-backend behavior,
verification-output generation, backend-language variant, AXI, APB, broader AHB
behavior, or VHDL behavior.
