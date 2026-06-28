#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;

subtest 'adapter parses the selected APB requester/completer composition PPIF shape' => sub {
    ok(-f sample_apb_composition_ppif_path(), 'tracked runnable APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_ppif_path());

    is($result->{layer}, 'IAL2', 'APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'adapter returns the APB composition kind');
    is($result->{mode}, 'requester-completer-composition', 'APB composition mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'APB composition report schema is selected');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition', 'APB composition source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'apb_composition', 'APB composition source intent name is preserved');
    is($result->{report}{target_protocol}{profile}, 'apb', 'APB composition report carries the APB profile');
    is($result->{report}{target_protocol}{object}, 'apb-composition', 'APB composition report carries the APB composition object');
    is($result->{report}{target_protocol}{role}, 'composition', 'APB composition report carries the composition role');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(apb_requester.isf apb_completer.isf)],
        'APB composition exposes both generated IAL1 endpoint artifacts',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(apb_completer.fsm apb_requester.fsm apb_tb.fsm)],
        'APB composition exposes requester, completer, and top .fsm artifacts',
    );

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/\A\(\?top:apb_tb\b/, 'generated top starts with the APB composition root');
    like($top, qr/\(\?fsmc:requester apb_requester\)/, 'generated top instantiates the requester child');
    like($top, qr/\(\?fsmc:completer apb_completer\)/, 'generated top instantiates the completer child');
    like($top, qr/\(requester\.PSEL completer\.PSEL\)/, 'generated top wires APB select requester to completer');
    like($top, qr/\(completer\.PREADY requester\.PREADY\)/, 'generated top wires APB ready completer to requester');
    like($top, qr/\(\?fsm:apb_requester\b/, 'generated top carries requester child FSM text for standalone lowering');
    like($top, qr/\(\?fsm:apb_completer\b/, 'generated top carries completer child FSM text for standalone lowering');
    unlike($top, qr/=busy\b/, 'generated top does not expose deferred requester busy status');

    is($result->{report}{composition}{name}, 'apb_tb', 'report captures the composition top name');
    is($result->{report}{composition}{child_instance_count}, 2, 'report captures the two child instances');
    is($result->{report}{children}[0]{role}, 'requester', 'report carries requester child metadata first');
    is($result->{report}{children}[1]{role}, 'completer', 'report carries completer child metadata second');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_tb.fsm', 'report selects generated composition top as HDL entry');
    is_deeply(
        $result->{report}{generated_artifacts}{hdl_entry}{child_artifacts},
        [qw(apb_requester.fsm apb_completer.fsm)],
        'report lists child artifacts under the selected HDL entry',
    );

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok($residue{apb_interconnect_multi_peripheral_decode_deferred}, 'report keeps multi-peripheral interconnect residue explicit');
    ok($residue{apb_requester_busy_status_deferred}, 'report keeps requester busy/status residue explicit');
};

subtest 'adapter parses the busy-capable APB composition PPIF shape' => sub {
    ok(-f sample_apb_composition_busy_ppif_path(), 'tracked runnable busy APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_busy_ppif_path());

    is($result->{layer}, 'IAL2', 'busy APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'busy adapter returns the APB composition kind');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-busy', 'busy APB composition source object id is preserved');
    is($result->{report}{composition}{name}, 'apb_tb', 'busy APB composition report captures top name');

    my $requester_isf = $result->{generated_ial1}{items}[0]{text};
    like($requester_isf, qr/\(output busy\)/, 'busy APB composition requester IAL1 exposes busy output');
    like($requester_isf, qr/\(busy 1\)/, 'busy APB composition requester IAL1 drives busy high during transfer phases');

    my $requester_fsm = $result->{generated_ial0}{files}{'apb_requester.fsm'};
    like($requester_fsm, qr/\(<- \(busy> 0\)\)/, 'busy APB composition requester FSM clears busy in idle');
    like($requester_fsm, qr/\(<- \(busy> 1\) <(?:setup|access)_phase_start\)/, 'busy APB composition requester FSM asserts busy in transfer phases');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=busy>/, 'busy APB composition top exposes requester busy output');
    like($top, qr/\(\?fsm:apb_requester\b/, 'busy APB composition top carries requester child FSM text');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok($residue{apb_interconnect_multi_peripheral_decode_deferred}, 'busy report keeps multi-peripheral interconnect residue explicit');
    ok($residue{apb_requester_status_field_deferred}, 'busy report keeps named requester status-field widening deferred');
    ok(!$residue{apb_requester_busy_status_deferred}, 'busy report removes requester busy/status deferred residue');
};

subtest 'adapter parses the status-capable APB composition PPIF shape' => sub {
    ok(-f sample_apb_composition_status_ppif_path(), 'tracked runnable status APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_status_ppif_path());

    is($result->{layer}, 'IAL2', 'status APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'status adapter returns the APB composition kind');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-status', 'status APB composition source object id is preserved');
    is($result->{report}{composition}{name}, 'apb_tb', 'status APB composition report captures top name');

    my $requester_isf = $result->{generated_ial1}{items}[0]{text};
    like($requester_isf, qr/\(output busy\)/, 'status APB composition requester IAL1 keeps busy output');
    like($requester_isf, qr/\(output status \(width 2\)\)/, 'status APB composition requester IAL1 exposes 2-bit status output');
    like($requester_isf, qr/\(status \(concat 1'b1 slverr\)\)/, 'status APB composition requester IAL1 maps done status from sampled PSLVERR');

    my $requester_fsm = $result->{generated_ial0}{files}{'apb_requester.fsm'};
    like($requester_fsm, qr/\(<- \(status> 0\)\)/, 'status APB composition requester FSM clears status in idle');
    like($requester_fsm, qr/\(<- \(status> 1\) <(?:setup|access)_phase_start\)/, 'status APB composition requester FSM asserts status while busy');
    like($requester_fsm, qr/\(<- \(status> \(concat 1'b1 slverr\)\) <done_phase_start\)/, 'status APB composition requester FSM publishes done_ok/done_error from sampled error');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=busy>/, 'status APB composition top keeps requester busy output');
    like($top, qr/=status>2/, 'status APB composition top exposes requester status output');

    is($result->{report}{requester_status_field}{name}, 'status', 'status APB composition report exposes requester status metadata');
    is($result->{report}{requester_status_field}{width}, 2, 'status APB composition report records requester status width');
    is_deeply(
        [map { $_->{name} } @{$result->{report}{requester_status_field}{encoding}}],
        [qw(idle busy done_ok done_error)],
        'status APB composition report records selected status encoding names',
    );

    my ($status_top_port) = grep { $_->{name} eq 'status' } @{$result->{report}{composition}{top_ports}};
    ok($status_top_port, 'status APB composition report lists status top port');
    is($status_top_port->{width}, 2, 'status APB composition report lists status top port width');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok($residue{apb_interconnect_multi_peripheral_decode_deferred}, 'status report keeps multi-peripheral interconnect residue explicit');
    ok(!$residue{apb_requester_status_field_deferred}, 'status report removes named requester status-field residue');
    ok(!$residue{apb_requester_busy_status_deferred}, 'status report keeps requester busy/status deferred residue absent');
};

subtest 'adapter parses the status back-to-back APB composition PPIF shape' => sub {
    ok(-f sample_apb_composition_status_back_to_back_ppif_path(), 'tracked runnable status back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'status back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'status back-to-back adapter returns the APB composition kind');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-status-back-to-back', 'status back-to-back APB composition source object id is preserved');
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy', 'composition report records endpoint timing-policy propagation');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'composition report records requester queue-depth 1');
    is($result->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'composition report records completer adjacent setup admission');

    my $requester_isf = $result->{generated_ial1}{items}[0]{text};
    like($requester_isf, qr/\(output accepted\)/, 'status back-to-back composition requester IAL1 exposes accepted output');

    my $requester_fsm = $result->{generated_ial0}{files}{'apb_requester.fsm'};
    like($requester_fsm, qr/\(queued_valid 1\)/, 'status back-to-back composition requester FSM declares queued_valid');
    like($requester_fsm, qr/\(<- \(PADDR> queued_addr\)\)/, 'status back-to-back composition requester FSM drives queued setup address');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'status back-to-back APB composition top exposes accepted output');
    like($top, qr/\(queued_valid 1\)/, 'status back-to-back APB composition top embeds requester queued state');
    like($top, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'status back-to-back APB composition top embeds adjacent completer setup detector');

    my ($accepted_top_port) = grep { $_->{name} eq 'accepted' } @{$result->{report}{composition}{top_ports}};
    ok($accepted_top_port, 'status back-to-back composition report lists accepted top port');
    is($accepted_top_port->{width}, 1, 'status back-to-back composition report lists accepted as one bit');
    is($result->{report}{requester_accepted_field}{name}, 'accepted', 'status back-to-back composition report exposes requester accepted metadata');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'status back-to-back composition removes broad back-to-back residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'status back-to-back composition keeps narrowed future-policy residue');
};

subtest 'adapter parses the sideband status back-to-back APB composition PPIF shape' => sub {
    ok(-f sample_apb_composition_sideband_status_back_to_back_ppif_path(), 'tracked runnable sideband status back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_sideband_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband status back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband status back-to-back adapter returns the APB composition kind');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-sideband-status-back-to-back', 'sideband status back-to-back APB composition source object id is preserved');
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy', 'sideband composition report records endpoint timing-policy propagation');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband composition report records requester queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband composition report records accepted response field');
    is($result->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'sideband composition report records completer adjacent setup admission');
    is($result->{report}{composition}{width_policy}{protection_width}, 3, 'sideband composition report records PPROT width 3');
    is($result->{report}{composition}{width_policy}{strobe_width}, 4, 'sideband composition report records PSTRB width 4');

    my $requester_fsm = $result->{generated_ial0}{files}{'apb_requester.fsm'};
    like($requester_fsm, qr/\(queued_prot 3\)/, 'sideband status back-to-back requester FSM declares queued_prot');
    like($requester_fsm, qr/\(queued_wstrb 4\)/, 'sideband status back-to-back requester FSM declares queued_wstrb');
    like($requester_fsm, qr/\(<- \(PPROT> queued_prot\)\)/, 'sideband status back-to-back requester FSM drives queued PPROT');
    like($requester_fsm, qr/\(<- \(PSTRB> \(& queued_wstrb \(concat queued_write queued_write queued_write queued_write\)\)\)/, 'sideband status back-to-back requester FSM drives queued PSTRB masked by queued write');

    my $completer_fsm = $result->{generated_ial0}{files}{'apb_completer.fsm'};
    like($completer_fsm, qr/\(<= \(prot_q PPROT\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband status back-to-back completer FSM samples PPROT under setup-detect guard');
    like($completer_fsm, qr/\(<= \(strb_q PSTRB\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband status back-to-back completer FSM samples PSTRB under setup-detect guard');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=req_prot<3/, 'sideband status back-to-back APB composition top exposes request protection');
    like($top, qr/=req_wstrb<4/, 'sideband status back-to-back APB composition top exposes request strobe');
    like($top, qr/=accepted>/, 'sideband status back-to-back APB composition top exposes accepted output');
    like($top, qr/\(requester\.PPROT completer\.PPROT\)/, 'sideband status back-to-back APB composition top wires PPROT');
    like($top, qr/\(requester\.PSTRB completer\.PSTRB\)/, 'sideband status back-to-back APB composition top wires PSTRB');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'sideband status back-to-back composition removes broad back-to-back residue');
    ok(!$composition_residue{apb_protection_and_strobes_deferred}, 'sideband status back-to-back composition removes broad sideband residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'sideband status back-to-back composition keeps narrowed future-policy residue');
    ok($composition_residue{apb_protection_policy_effects_deferred}, 'sideband status back-to-back composition keeps protection-policy effects deferred');

    ok(-f sample_apb_composition_sideband_status_back_to_back_apb_path(), 'tracked runnable sideband status back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_sideband_status_back_to_back_apb_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband status back-to-back .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $result->{generated_ial1}{items}, 'sideband status back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $result->{generated_ial0}{files}, 'sideband status back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
};

subtest 'adapter parses the status-capable APB multi-register composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_register_ppif_path(), 'tracked runnable multi-register APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_ppif_path());

    is($result->{layer}, 'IAL2', 'multi-register APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'multi-register adapter returns the APB composition kind');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-register', 'multi-register APB composition source object id is preserved');
    is($result->{report}{composition}{name}, 'apb_tb', 'multi-register APB composition report captures top name');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=busy>/, 'multi-register APB composition top keeps requester busy output');
    like($top, qr/=status>2/, 'multi-register APB composition top exposes requester status output');
    like($top, qr/\(reg0_data_q 32 \(reset 0\)\)/, 'multi-register APB composition top embeds first completer register');
    like($top, qr/\(reg1_data_q 32 \(reset 0\)\)/, 'multi-register APB composition top embeds second completer register');
    like($top, qr/\(<- \(reg1_data_q wdata_q\)\)/, 'multi-register APB composition top embeds second-register write behavior');
    like($top, qr/\(<- \(PRDATA> reg1_data_q\) <read_reg1_hit_start\)/, 'multi-register APB composition top embeds second-register read behavior');

    is($result->{report}{requester_status_field}{name}, 'status', 'multi-register APB composition report exposes requester status metadata');
    my $completer_child = $result->{report}{children}[1];
    is($completer_child->{role}, 'completer', 'multi-register report carries completer child second');
    is_deeply(
        [map { $_->{name} } @{$completer_child->{bindings}{storage}{registers}}],
        [qw(reg0 reg1)],
        'multi-register composition child report preserves completer register list',
    );
    is_deeply($completer_child->{transfer}{registers}, [qw(reg0 reg1)], 'multi-register composition child report preserves transfer register list');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_multi_register_decode_deferred}, 'multi-register composition report removes multi-register deferred residue');
    ok(!$composition_residue{apb_requester_status_field_deferred}, 'multi-register composition report keeps status-field residue absent');
    ok(!$composition_residue{apb_requester_busy_status_deferred}, 'multi-register composition report keeps requester busy/status deferred residue absent');

    my %child_residue = map { $_->{id} => 1 } @{$completer_child->{unsupported_residue}};
    ok(!$child_residue{apb_multi_register_decode_deferred}, 'multi-register composition child completer report removes multi-register deferred residue');
    ok($child_residue{apb_interconnect_multi_peripheral_decode_deferred}, 'multi-register composition child completer keeps interconnect residue explicit');
};

subtest 'adapter parses the sideband APB multi-register composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_register_sideband_ppif_path(), 'tracked runnable sideband multi-register APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband multi-register APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband multi-register adapter returns the APB composition kind');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-register-sideband', 'sideband multi-register APB composition source object id is preserved');
    is($result->{report}{composition}{name}, 'apb_tb', 'sideband multi-register APB composition report captures top name');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=req_prot<3/, 'sideband multi-register APB composition top exposes 3-bit request protection input');
    like($top, qr/=req_wstrb<4/, 'sideband multi-register APB composition top exposes 4-bit request strobe input');
    like($top, qr/\(requester\.PPROT completer\.PPROT\)/, 'sideband multi-register APB composition wires requester PPROT to completer PPROT');
    like($top, qr/\(requester\.PSTRB completer\.PSTRB\)/, 'sideband multi-register APB composition wires requester PSTRB to completer PSTRB');
    like($top, qr/\(<= \(prot req_prot\) <start\)/, 'sideband multi-register APB composition embeds requester PPROT sampling');
    like($top, qr/\(<- \(PSTRB> \(& wstrb \(concat is_write is_write is_write is_write\)\)\) <setup_phase_start\)/, 'sideband multi-register APB composition embeds requester write-only PSTRB drive');
    like($top, qr/\(<= \(prot_q PPROT\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband multi-register APB composition embeds completer PPROT sampling');
    like($top, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'sideband multi-register APB composition embeds completer high-byte write mask');

    is($result->{report}{requester_status_field}{name}, 'status', 'sideband multi-register APB composition report exposes requester status metadata');
    is_deeply($result->{report}{children}[1]{transfer}{registers}, [qw(reg0 reg1)], 'sideband multi-register APB composition child report preserves completer register list');
    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_multi_register_decode_deferred}, 'sideband multi-register composition report removes multi-register deferred residue');
    ok(!$composition_residue{apb_protection_and_strobes_deferred}, 'sideband multi-register composition report removes broad sideband/strobe deferred residue');
    ok($composition_residue{apb_protection_policy_effects_deferred}, 'sideband multi-register composition report keeps protection-policy effects deferred');

    my %child_residue = map { $_->{id} => 1 } @{$result->{report}{children}[1]{unsupported_residue}};
    ok(!$child_residue{apb_protection_and_strobes_deferred}, 'sideband multi-register composition child completer removes broad sideband residue');
    ok($child_residue{apb_protection_policy_effects_deferred}, 'sideband multi-register composition child completer keeps protection-policy effects deferred');
};

subtest 'adapter parses the sideband APB multi-register status back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_register_sideband_status_back_to_back_ppif_path(), 'tracked runnable sideband multi-register status back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband multi-register status back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband multi-register status back-to-back adapter returns the APB composition kind');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-register-sideband-status-back-to-back', 'sideband multi-register status back-to-back source object id is preserved');
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy', 'sideband multi-register composition report records endpoint timing-policy propagation');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband multi-register composition report records requester queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband multi-register composition report records accepted response field');
    is($result->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'sideband multi-register composition report records completer adjacent setup admission');
    is_deeply($result->{report}{children}[1]{transfer}{registers}, [qw(reg0 reg1)], 'sideband multi-register status back-to-back child report preserves completer register list');

    my $requester_fsm = $result->{generated_ial0}{files}{'apb_requester.fsm'};
    like($requester_fsm, qr/\(queued_prot 3\)/, 'sideband multi-register status back-to-back requester FSM declares queued_prot');
    like($requester_fsm, qr/\(<- \(PSTRB> \(& queued_wstrb \(concat queued_write queued_write queued_write queued_write\)\)\)/, 'sideband multi-register status back-to-back requester FSM drives queued PSTRB masked by queued write');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'sideband multi-register status back-to-back APB composition top exposes accepted output');
    like($top, qr/\(queued_prot 3\)/, 'sideband multi-register status back-to-back APB composition top embeds queued PPROT state');
    like($top, qr/\(requester\.PPROT completer\.PPROT\)/, 'sideband multi-register status back-to-back APB composition top wires PPROT');
    like($top, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband multi-register status back-to-back APB composition top embeds adjacent setup detector');
    like($top, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'sideband multi-register status back-to-back APB composition top embeds register 1 high-byte write mask');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'sideband multi-register status back-to-back composition removes broad back-to-back residue');
    ok(!$composition_residue{apb_protection_and_strobes_deferred}, 'sideband multi-register status back-to-back composition removes broad sideband residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'sideband multi-register status back-to-back composition keeps narrowed future-policy residue');
    ok($composition_residue{apb_protection_policy_effects_deferred}, 'sideband multi-register status back-to-back composition keeps protection-policy effects deferred');

    ok(-f sample_apb_composition_multi_register_sideband_status_back_to_back_apb_path(), 'tracked runnable sideband multi-register status back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_status_back_to_back_apb_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband multi-register status back-to-back .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $result->{generated_ial1}{items}, 'sideband multi-register status back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $result->{generated_ial0}{files}, 'sideband multi-register status back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
};

subtest 'adapter parses the sideband protection APB multi-register composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_register_sideband_protection_ppif_path(), 'tracked runnable sideband protection multi-register APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_protection_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband protection multi-register APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-register adapter returns the APB composition kind');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-register-sideband-protection', 'sideband protection multi-register APB composition source object id is preserved');
    is($result->{report}{protection_policy}{enforcement_owner}, 'completer', 'fixed composition report assigns policy enforcement to the completer child');
    is($result->{report}{protection_policy}{composition_role}, 'propagate_pprot_pstrb_and_selected_response_only', 'fixed composition report keeps composition role propagation-only');
    is($result->{report}{protection_policy}{child_policy}{predicate_namespace}, 'fsmgen_apb_pprot_v1', 'fixed composition embeds completer protection-policy metadata');
    is($result->{report}{children}[1]{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'fixed composition child report preserves reg1 read policy');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/\(requester\.PPROT completer\.PPROT\)/, 'sideband protection fixed composition wires requester PPROT to completer PPROT');
    like($top, qr/\(requester\.PSTRB completer\.PSTRB\)/, 'sideband protection fixed composition wires requester PSTRB to completer PSTRB');
    like($top, qr/\(\?\(& write_q \(== addr 0\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection fixed composition embeds denied reg0 write branch');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection fixed composition embeds denied reg1 read branch');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_protection_policy_effects_deferred}, 'sideband protection fixed composition removes old policy-effects residue');
    ok($composition_residue{apb_additional_protection_policies_deferred}, 'sideband protection fixed composition keeps additional-policy residue');

    my %child_residue = map { $_->{id} => 1 } @{$result->{report}{children}[1]{unsupported_residue}};
    ok(!$child_residue{apb_protection_policy_effects_deferred}, 'sideband protection fixed composition child removes old policy-effects residue');
    ok($child_residue{apb_additional_protection_policies_deferred}, 'sideband protection fixed composition child keeps additional-policy residue');
};

subtest 'adapter parses the sideband protection APB multi-register status back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif_path(), 'tracked runnable sideband protection multi-register status back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband protection multi-register status back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-register status back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-completer-composition', 'sideband protection multi-register status back-to-back keeps the fixed composition mode');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-register-sideband-protection-status-back-to-back', 'sideband protection multi-register status back-to-back source object id is preserved');
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy', 'sideband protection multi-register status back-to-back report records endpoint timing-policy propagation');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband protection multi-register status back-to-back report records requester queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', 'sideband protection multi-register status back-to-back report records requester overflow reject');
    is($result->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-register status back-to-back report records completer adjacent setup admission');
    is($result->{report}{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register status back-to-back report keeps policy enforcement in the completer');
    is($result->{report}{protection_policy}{composition_role}, 'propagate_pprot_pstrb_and_selected_response_only', 'sideband protection multi-register status back-to-back report keeps composition enforcement-free');
    is($result->{report}{protection_policy}{child_policy}{predicate_namespace}, 'fsmgen_apb_pprot_v1', 'sideband protection multi-register status back-to-back report embeds child protection policy');
    is($result->{report}{children}[1]{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'sideband protection multi-register status back-to-back child report preserves reg1 read policy');
    is_deeply($result->{report}{children}[1]{transfer}{registers}, [qw(reg0 reg1)], 'sideband protection multi-register status back-to-back child report preserves protected register list');

    my $requester_fsm = $result->{generated_ial0}{files}{'apb_requester.fsm'};
    like($requester_fsm, qr/\(queued_prot 3\)/, 'sideband protection multi-register status back-to-back requester FSM declares queued_prot');
    like($requester_fsm, qr/\(<- \(PSTRB> \(& queued_wstrb \(concat queued_write queued_write queued_write queued_write\)\)\)/, 'sideband protection multi-register status back-to-back requester FSM drives queued PSTRB masked by queued write');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'sideband protection multi-register status back-to-back APB composition top exposes accepted output');
    like($top, qr/\(queued_prot 3\)/, 'sideband protection multi-register status back-to-back APB composition top embeds queued PPROT state');
    like($top, qr/\(requester\.PPROT completer\.PPROT\)/, 'sideband protection multi-register status back-to-back APB composition top wires PPROT');
    like($top, qr/\(requester\.PSTRB completer\.PSTRB\)/, 'sideband protection multi-register status back-to-back APB composition top wires PSTRB');
    like($top, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband protection multi-register status back-to-back APB composition top embeds adjacent setup detector');
    like($top, qr/\(\?\(& write_q \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-register status back-to-back APB composition top embeds denied reg1 write branch');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-register status back-to-back APB composition top embeds denied reg1 read branch');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'sideband protection multi-register status back-to-back composition removes broad back-to-back residue');
    ok(!$composition_residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-register status back-to-back composition removes old policy-effects residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'sideband protection multi-register status back-to-back composition keeps narrowed future timing residue');
    ok($composition_residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-register status back-to-back composition keeps additional-policy residue');

    ok(-f sample_apb_composition_multi_register_sideband_protection_status_back_to_back_apb_path(), 'tracked runnable sideband protection multi-register status back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_protection_status_back_to_back_apb_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-register status back-to-back .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $result->{generated_ial1}{items}, 'sideband protection multi-register status back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $result->{generated_ial0}{files}, 'sideband protection multi-register status back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-register status back-to-back .apb APB composition alias preserves completer timing policy');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register status back-to-back .apb APB composition alias preserves policy owner');
};

subtest 'adapter parses the sideband APB multi-register data16 composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_register_sideband_data16_ppif_path(), 'tracked runnable sideband multi-register data16 APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband multi-register data16 APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband multi-register data16 adapter returns the APB composition kind');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-register-sideband-data16', 'sideband multi-register data16 APB composition source object id is preserved');
    is($result->{report}{composition}{width_policy}{data_width}, 16, 'sideband multi-register data16 report records 16-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 2, 'sideband multi-register data16 report records 2-bit PSTRB width');
    is($result->{report}{composition}{width_policy}{address_map_alignment_bytes}, 2, 'sideband multi-register data16 report records 2-byte alignment policy');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=req_wdata<16/, 'sideband multi-register data16 top exposes 16-bit request write data input');
    like($top, qr/=req_wstrb<2/, 'sideband multi-register data16 top exposes 2-bit request strobe input');
    like($top, qr/=last_read_data>16/, 'sideband multi-register data16 top exposes 16-bit read-data output');
    like($top, qr/\(<- \(PSTRB> \(& wstrb \(concat is_write is_write\)\)\) <setup_phase_start\)/, 'sideband multi-register data16 top embeds requester write-only 2-bit PSTRB drive');
    like($top, qr/\(reg1_data_q 16 \(reset 0\)\)/, 'sideband multi-register data16 top embeds 16-bit second completer register');
    like($top, qr/\(== addr 2\)/, 'sideband multi-register data16 top embeds second register decode at address 2');
    like($top, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband multi-register data16 top embeds completer high-byte write mask');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_alternate_widths_deferred}, 'sideband multi-register data16 composition report removes broad alternate-width residue');
    ok($composition_residue{apb_remaining_widths_deferred}, 'sideband multi-register data16 composition report keeps narrowed remaining-width residue');
    ok($composition_residue{apb_protection_policy_effects_deferred}, 'sideband multi-register data16 composition report keeps protection-policy effects deferred');

    my %child_residue = map { $_->{id} => 1 } @{$result->{report}{children}[1]{unsupported_residue}};
    ok($child_residue{apb_remaining_widths_deferred}, 'sideband multi-register data16 child completer keeps narrowed remaining-width residue');
};

subtest 'adapter parses the sideband APB multi-register data16 status back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_register_sideband_data16_status_back_to_back_ppif_path(), 'tracked runnable sideband multi-register data16 status back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband multi-register data16 status back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband multi-register data16 status back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-completer-composition', 'sideband multi-register data16 status back-to-back keeps the fixed composition mode');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-register-sideband-data16-status-back-to-back', 'sideband multi-register data16 status back-to-back source object id is preserved');
    is($result->{report}{composition}{width_policy}{data_width}, 16, 'sideband multi-register data16 status back-to-back report records 16-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 2, 'sideband multi-register data16 status back-to-back report records 2-bit PSTRB width');
    is($result->{report}{composition}{width_policy}{selected_contract}, 'sideband_data16', 'sideband multi-register data16 status back-to-back report records the selected data16 contract');
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy', 'sideband multi-register data16 status back-to-back report records endpoint timing-policy propagation');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband multi-register data16 status back-to-back report records requester queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', 'sideband multi-register data16 status back-to-back report records requester overflow reject');
    is($result->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'sideband multi-register data16 status back-to-back report records completer adjacent setup admission');
    is_deeply($result->{report}{children}[1]{transfer}{registers}, [qw(reg0 reg1)], 'sideband multi-register data16 status back-to-back child report preserves selected two-register list');

    my $requester_fsm = $result->{generated_ial0}{files}{'apb_requester.fsm'};
    like($requester_fsm, qr/\(queued_wdata 16\)/, 'sideband multi-register data16 status back-to-back requester FSM declares queued 16-bit data');
    like($requester_fsm, qr/\(queued_wstrb 2\)/, 'sideband multi-register data16 status back-to-back requester FSM declares queued 2-bit PSTRB');
    like($requester_fsm, qr/\(<- \(PSTRB> \(& queued_wstrb \(concat queued_write queued_write\)\)\)/, 'sideband multi-register data16 status back-to-back requester FSM drives queued 2-bit PSTRB masked by queued write');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'sideband multi-register data16 status back-to-back APB composition top exposes accepted output');
    like($top, qr/=req_wdata<16/, 'sideband multi-register data16 status back-to-back top exposes 16-bit request write data input');
    like($top, qr/=req_wstrb<2/, 'sideband multi-register data16 status back-to-back top exposes 2-bit request strobe input');
    like($top, qr/\(queued_wdata 16\)/, 'sideband multi-register data16 status back-to-back top embeds queued 16-bit requester data');
    like($top, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband multi-register data16 status back-to-back top embeds adjacent completer setup detector');
    like($top, qr/\(reg1_data_q 16 \(reset 0\)\)/, 'sideband multi-register data16 status back-to-back top embeds 16-bit second completer register');
    like($top, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband multi-register data16 status back-to-back top embeds data16 high-byte write mask');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'sideband multi-register data16 status back-to-back composition removes broad back-to-back residue');
    ok(!$composition_residue{apb_alternate_widths_deferred}, 'sideband multi-register data16 status back-to-back composition keeps broad alternate-width residue absent');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'sideband multi-register data16 status back-to-back composition keeps narrowed future-policy residue');
    ok($composition_residue{apb_remaining_widths_deferred}, 'sideband multi-register data16 status back-to-back composition keeps narrowed remaining-width residue');
    ok($composition_residue{apb_protection_policy_effects_deferred}, 'sideband multi-register data16 status back-to-back composition keeps protection-policy effects deferred');

    ok(-f sample_apb_composition_multi_register_sideband_data16_status_back_to_back_apb_path(), 'tracked runnable sideband multi-register data16 status back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_status_back_to_back_apb_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband multi-register data16 status back-to-back .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $result->{generated_ial1}{items}, 'sideband multi-register data16 status back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $result->{generated_ial0}{files}, 'sideband multi-register data16 status back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
};

subtest 'adapter parses the sideband protection APB multi-register data16 composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_register_sideband_data16_protection_ppif_path(), 'tracked runnable sideband protection multi-register data16 APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_protection_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband protection multi-register data16 APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-register data16 adapter returns the APB composition kind');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-register-sideband-data16-protection', 'sideband protection multi-register data16 APB composition source object id is preserved');
    is($result->{report}{composition}{width_policy}{data_width}, 16, 'sideband protection multi-register data16 report records 16-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 2, 'sideband protection multi-register data16 report records 2-bit PSTRB width');
    is($result->{report}{composition}{width_policy}{selected_contract}, 'sideband_data16', 'sideband protection multi-register data16 report records selected data16 contract');
    is($result->{report}{protection_policy}{enforcement_owner}, 'completer', 'fixed data16 protection composition report assigns policy enforcement to the completer child');
    is($result->{report}{protection_policy}{child_policy}{predicate_namespace}, 'fsmgen_apb_pprot_v1', 'fixed data16 protection composition embeds completer protection-policy metadata');
    is($result->{report}{children}[1]{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'fixed data16 protection composition child report preserves reg1 read policy');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=req_wdata<16/, 'sideband protection multi-register data16 top exposes 16-bit request write data input');
    like($top, qr/=req_wstrb<2/, 'sideband protection multi-register data16 top exposes 2-bit request strobe input');
    like($top, qr/\(requester\.PPROT completer\.PPROT\)/, 'sideband protection multi-register data16 top wires requester PPROT to completer PPROT');
    like($top, qr/\(requester\.PSTRB completer\.PSTRB\)/, 'sideband protection multi-register data16 top wires requester PSTRB to completer PSTRB');
    like($top, qr/\(\?\(& write_q \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-register data16 top embeds denied reg1 write branch');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-register data16 top embeds denied reg1 read branch');
    like($top, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband protection multi-register data16 top embeds high-byte write mask');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-register data16 composition report removes old policy-effects residue');
    ok(!$composition_residue{apb_alternate_widths_deferred}, 'sideband protection multi-register data16 composition report keeps broad alternate-width residue absent');
    ok($composition_residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-register data16 composition report keeps additional-policy residue');
    ok($composition_residue{apb_remaining_widths_deferred}, 'sideband protection multi-register data16 composition report keeps narrowed remaining-width residue');

    my %child_residue = map { $_->{id} => 1 } @{$result->{report}{children}[1]{unsupported_residue}};
    ok(!$child_residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-register data16 child removes old policy-effects residue');
    ok($child_residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-register data16 child keeps additional-policy residue');
    ok($child_residue{apb_remaining_widths_deferred}, 'sideband protection multi-register data16 child keeps narrowed remaining-width residue');
};

subtest 'adapter parses the sideband protection APB multi-register data16 status back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif_path(), 'tracked runnable sideband protection multi-register data16 status back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband protection multi-register data16 status back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-register data16 status back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-completer-composition', 'sideband protection multi-register data16 status back-to-back keeps the fixed composition mode');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-register-sideband-data16-protection-status-back-to-back', 'sideband protection multi-register data16 status back-to-back source object id is preserved');
    is($result->{report}{composition}{width_policy}{data_width}, 16, 'sideband protection multi-register data16 status back-to-back report records 16-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 2, 'sideband protection multi-register data16 status back-to-back report records 2-bit PSTRB width');
    is($result->{report}{composition}{width_policy}{selected_contract}, 'sideband_data16', 'sideband protection multi-register data16 status back-to-back report records the selected data16 contract');
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy', 'sideband protection multi-register data16 status back-to-back report records endpoint timing-policy propagation');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband protection multi-register data16 status back-to-back report records requester queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', 'sideband protection multi-register data16 status back-to-back report records requester overflow reject');
    is($result->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-register data16 status back-to-back report records completer adjacent setup admission');
    is($result->{report}{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register data16 status back-to-back report keeps protection enforcement in the completer');
    is($result->{report}{protection_policy}{composition_role}, 'propagate_pprot_pstrb_and_selected_response_only', 'sideband protection multi-register data16 status back-to-back report keeps composition enforcement-free');
    is($result->{report}{protection_policy}{child_policy}{predicate_namespace}, 'fsmgen_apb_pprot_v1', 'sideband protection multi-register data16 status back-to-back report embeds child protection policy');
    is($result->{report}{children}[1]{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'sideband protection multi-register data16 status back-to-back child report preserves reg1 read policy');
    is_deeply($result->{report}{children}[1]{transfer}{registers}, [qw(reg0 reg1)], 'sideband protection multi-register data16 status back-to-back child report preserves protected register list');

    my $requester_fsm = $result->{generated_ial0}{files}{'apb_requester.fsm'};
    like($requester_fsm, qr/\(queued_wdata 16\)/, 'sideband protection multi-register data16 status back-to-back requester FSM declares queued 16-bit data');
    like($requester_fsm, qr/\(queued_wstrb 2\)/, 'sideband protection multi-register data16 status back-to-back requester FSM declares queued 2-bit PSTRB');
    like($requester_fsm, qr/\(queued_prot 3\)/, 'sideband protection multi-register data16 status back-to-back requester FSM declares queued 3-bit PPROT');
    like($requester_fsm, qr/\(<- \(PSTRB> \(& queued_wstrb \(concat queued_write queued_write\)\)\)/, 'sideband protection multi-register data16 status back-to-back requester FSM drives queued 2-bit PSTRB masked by queued write');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'sideband protection multi-register data16 status back-to-back APB composition top exposes accepted output');
    like($top, qr/=req_wdata<16/, 'sideband protection multi-register data16 status back-to-back top exposes 16-bit request write data input');
    like($top, qr/=req_wstrb<2/, 'sideband protection multi-register data16 status back-to-back top exposes 2-bit request strobe input');
    like($top, qr/\(queued_wdata 16\)/, 'sideband protection multi-register data16 status back-to-back top embeds queued 16-bit requester data');
    like($top, qr/\(queued_prot 3\)/, 'sideband protection multi-register data16 status back-to-back top embeds queued PPROT state');
    like($top, qr/\(requester\.PPROT completer\.PPROT\)/, 'sideband protection multi-register data16 status back-to-back top wires PPROT');
    like($top, qr/\(requester\.PSTRB completer\.PSTRB\)/, 'sideband protection multi-register data16 status back-to-back top wires PSTRB');
    like($top, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband protection multi-register data16 status back-to-back top embeds adjacent completer setup detector');
    like($top, qr/\(\?\(& write_q \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-register data16 status back-to-back top embeds denied reg1 write branch');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-register data16 status back-to-back top embeds denied reg1 read branch');
    like($top, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband protection multi-register data16 status back-to-back top embeds data16 high-byte write mask');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'sideband protection multi-register data16 status back-to-back composition removes broad back-to-back residue');
    ok(!$composition_residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-register data16 status back-to-back composition removes old policy-effects residue');
    ok(!$composition_residue{apb_alternate_widths_deferred}, 'sideband protection multi-register data16 status back-to-back composition keeps broad alternate-width residue absent');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'sideband protection multi-register data16 status back-to-back composition keeps narrowed future timing residue');
    ok($composition_residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-register data16 status back-to-back composition keeps additional-policy residue');
    ok($composition_residue{apb_remaining_widths_deferred}, 'sideband protection multi-register data16 status back-to-back composition keeps narrowed remaining-width residue');

    ok(-f sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_apb_path(), 'tracked runnable sideband protection multi-register data16 status back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_apb_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-register data16 status back-to-back .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $result->{generated_ial1}{items}, 'sideband protection multi-register data16 status back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $result->{generated_ial0}{files}, 'sideband protection multi-register data16 status back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-register data16 status back-to-back .apb APB composition alias preserves completer timing policy');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register data16 status back-to-back .apb APB composition alias preserves policy owner');
};

subtest 'adapter parses the selected APB multi-peripheral composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_ppif_path(), 'tracked runnable multi-peripheral APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_ppif_path());

    is($result->{layer}, 'IAL2', 'multi-peripheral APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'multi-peripheral adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'multi-peripheral APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral', 'multi-peripheral APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'multi-peripheral report names the selected topology');
    is($result->{report}{composition}{child_instance_count}, 4, 'multi-peripheral report counts requester, interconnect, and two peripherals');
    is($result->{report}{composition}{endpoint_child_instance_count}, 3, 'multi-peripheral report counts requester plus endpoint peripherals');
    is($result->{report}{composition}{generated_interconnect}{ial1_artifact}, 'apb_interconnect.isf', 'multi-peripheral report names generated interconnect IAL1 artifact');
    is($result->{report}{composition}{generated_interconnect}{ial0_artifact}, 'apb_interconnect.fsm', 'multi-peripheral report names generated interconnect IAL0 artifact');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf)],
        'multi-peripheral APB composition exposes endpoint and generated interconnect IAL1 artifacts',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(apb_control_regs.fsm apb_interconnect.fsm apb_requester.fsm apb_status_regs.fsm apb_tb.fsm)],
        'multi-peripheral APB composition exposes endpoint, interconnect, and top .fsm artifacts',
    );

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/\(\?fsmc:requester apb_requester\)/, 'multi-peripheral top instantiates requester');
    like($top, qr/\(\?fsmc:interconnect apb_interconnect\)/, 'multi-peripheral top instantiates generated interconnect');
    like($top, qr/\(\?fsmc:status_peripheral apb_status_regs\)/, 'multi-peripheral top gives colliding status peripheral a deterministic generated instance name');
    like($top, qr/\(\?fsmc:control apb_control_regs\)/, 'multi-peripheral top preserves non-colliding control peripheral instance name');
    like($top, qr/\(interconnect\.PSEL_STATUS status_peripheral\.PSEL_STATUS\)/, 'multi-peripheral top wires decoded status select to the status peripheral');
    like($top, qr/\(status_peripheral\.PREADY_STATUS interconnect\.PREADY_STATUS\)/, 'multi-peripheral top wires status response back to the interconnect');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(<- \(PSEL_STATUS> PSEL\) <\(& PSEL \(>= PADDR 0\) \(< PADDR 256\)\)\)/, 'interconnect decodes the status window select');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'interconnect subtracts the control window base for local address');
    like($interconnect, qr/\(<- \(PREADY> PREADY_CONTROL\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'interconnect muxes selected control PREADY');
    like($interconnect, qr/\(<- \(PSLVERR> 1\) <\(& PSEL PENABLE \(! \(\| /, 'interconnect returns an unmapped active-access error');

    is($result->{report}{children}[0]{role}, 'requester', 'multi-peripheral report carries requester child first');
    is($result->{report}{children}[1]{role}, 'interconnect', 'multi-peripheral report carries generated interconnect second');
    is($result->{report}{children}[2]{role}, 'peripheral', 'multi-peripheral report carries first peripheral third');
    is($result->{report}{children}[2]{instance_name}, 'status', 'multi-peripheral report preserves authored status peripheral name');
    is($result->{report}{children}[2]{generated_instance_name}, 'status_peripheral', 'multi-peripheral report exposes generated status peripheral instance name');
    is_deeply(
        [map { $_->{name} } @{$result->{report}{composition}{address_map}{windows}}],
        [qw(status control)],
        'multi-peripheral report preserves source-ordered address-map windows',
    );
    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_interconnect_multi_peripheral_decode_deferred}, 'multi-peripheral composition report removes interconnect/decode deferred residue');
    ok($composition_residue{apb_protection_and_strobes_deferred}, 'multi-peripheral composition report keeps APB sideband residue explicit');
};

subtest 'adapter parses the selected APB multi-peripheral status back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_status_back_to_back_ppif_path(), 'tracked runnable multi-peripheral status back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'multi-peripheral status back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'multi-peripheral status back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'multi-peripheral status back-to-back mode remains the multi-peripheral composition mode');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-status-back-to-back', 'multi-peripheral status back-to-back source object id is preserved');
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy_through_interconnect', 'multi-peripheral report records interconnect propagation role');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'multi-peripheral report records requester queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', 'multi-peripheral report records requester overflow reject');
    is($result->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'multi-peripheral report records propagation-only interconnect timing role');
    is($result->{report}{back_to_back_policy}{interconnect}{setup_decode}, 'current_psel_paddr_with_penable_low', 'multi-peripheral report records current setup decode policy');
    is($result->{report}{back_to_back_policy}{interconnect}{unmapped_policy}, 'active_access_only', 'multi-peripheral report records active-access unmapped policy');
    is_deeply(
        [map { $_->{timing_policy}{setup_admission} } @{$result->{report}{back_to_back_policy}{peripherals}}],
        [qw(adjacent adjacent)],
        'multi-peripheral report records adjacent setup admission for every peripheral',
    );

    is($result->{report}{requester_accepted_field}{name}, 'accepted', 'multi-peripheral status back-to-back report exposes requester accepted metadata');
    my ($accepted_top_port) = grep { $_->{name} eq 'accepted' } @{$result->{report}{composition}{top_ports}};
    ok($accepted_top_port, 'multi-peripheral status back-to-back report lists accepted top port');
    is($accepted_top_port->{width}, 1, 'multi-peripheral status back-to-back report lists accepted as one bit');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'multi-peripheral status back-to-back top exposes accepted output');
    like($top, qr/\(queued_valid 1\)/, 'multi-peripheral status back-to-back top embeds requester queued state');
    like($top, qr/\(<- \(PADDR> queued_addr\)\)/, 'multi-peripheral status back-to-back top embeds queued setup address drive');
    like($top, qr/\(<= \(addr PADDR_STATUS\) <\(& PSEL_STATUS \(! PENABLE_STATUS\)\)\)/, 'multi-peripheral status back-to-back top embeds status peripheral adjacent setup detector');
    like($top, qr/\(<= \(addr PADDR_CONTROL\) <\(& PSEL_CONTROL \(! PENABLE_CONTROL\)\)\)/, 'multi-peripheral status back-to-back top embeds control peripheral adjacent setup detector');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(<- \(PENABLE_STATUS> PENABLE\)\)/, 'multi-peripheral status back-to-back interconnect forwards PENABLE to status without insertion');
    like($interconnect, qr/\(<- \(PENABLE_CONTROL> PENABLE\)\)/, 'multi-peripheral status back-to-back interconnect forwards PENABLE to control without insertion');
    like($interconnect, qr/\(<- \(PSEL_STATUS> PSEL\) <\(& PSEL \(>= PADDR 0\) \(< PADDR 256\)\)\)/, 'multi-peripheral status back-to-back interconnect decodes current status setup address');
    like($interconnect, qr/\(<- \(PSEL_CONTROL> PSEL\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'multi-peripheral status back-to-back interconnect decodes current control setup address');
    like($interconnect, qr/\(<- \(PSLVERR> 1\) <\(& PSEL PENABLE \(! \(\| /, 'multi-peripheral status back-to-back interconnect keeps unmapped error active-access gated');

    is($result->{report}{children}[1]{back_to_back_policy}{setup_decode}, 'current_psel_paddr_with_penable_low', 'interconnect child report records setup decode policy');
    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'multi-peripheral status back-to-back composition removes broad back-to-back residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'multi-peripheral status back-to-back composition keeps narrowed future-policy residue');
    my %interconnect_residue = map { $_->{id} => 1 } @{$result->{report}{children}[1]{unsupported_residue}};
    ok(!$interconnect_residue{apb_back_to_back_policy_deferred}, 'multi-peripheral status back-to-back interconnect removes broad back-to-back residue');
    ok($interconnect_residue{apb_additional_back_to_back_policies_deferred}, 'multi-peripheral status back-to-back interconnect keeps narrowed future-policy residue');
};

subtest 'adapter parses the sideband APB multi-peripheral composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_sideband_ppif_path(), 'tracked runnable sideband multi-peripheral APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband multi-peripheral APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband multi-peripheral adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'sideband multi-peripheral APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-sideband', 'sideband multi-peripheral APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'sideband multi-peripheral report names the selected topology');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=req_prot<3/, 'sideband multi-peripheral APB composition top exposes 3-bit request protection input');
    like($top, qr/=req_wstrb<4/, 'sideband multi-peripheral APB composition top exposes 4-bit request strobe input');
    like($top, qr/\(requester\.PPROT interconnect\.PPROT\)/, 'sideband multi-peripheral top wires requester PPROT to interconnect PPROT');
    like($top, qr/\(requester\.PSTRB interconnect\.PSTRB\)/, 'sideband multi-peripheral top wires requester PSTRB to interconnect PSTRB');
    like($top, qr/\(interconnect\.PPROT_STATUS status_peripheral\.PPROT_STATUS\)/, 'sideband multi-peripheral top wires status-window PPROT');
    like($top, qr/\(interconnect\.PSTRB_CONTROL control\.PSTRB_CONTROL\)/, 'sideband multi-peripheral top wires control-window PSTRB');
    like($top, qr/\(<= \(prot_q PPROT_STATUS\) <\(& PSEL_STATUS \(! PENABLE_STATUS\)\)\)/, 'sideband multi-peripheral top embeds status peripheral PPROT sampling');
    like($top, qr/\(<= \(strb_q PSTRB_CONTROL\) <\(& PSEL_CONTROL \(! PENABLE_CONTROL\)\)\)/, 'sideband multi-peripheral top embeds control peripheral PSTRB sampling');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PPROT_STATUS 3\)/, 'sideband interconnect declares status-window PPROT');
    like($interconnect, qr/\(PSTRB_CONTROL 4\)/, 'sideband interconnect declares control-window PSTRB');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband interconnect fans out PPROT to the status window');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband interconnect fans out PSTRB to the control window');
    like($interconnect, qr/\(<- \(PSEL_STATUS> PSEL\) <\(& PSEL \(>= PADDR 0\) \(< PADDR 256\)\)\)/, 'sideband interconnect keeps status select decode gated');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_interconnect_multi_peripheral_decode_deferred}, 'sideband multi-peripheral composition report removes interconnect/decode deferred residue');
    ok(!$composition_residue{apb_protection_and_strobes_deferred}, 'sideband multi-peripheral composition report removes broad sideband/strobe deferred residue');
    ok($composition_residue{apb_protection_policy_effects_deferred}, 'sideband multi-peripheral composition report keeps protection-policy effects deferred');
};

subtest 'adapter parses selected sideband no-policy APB multi-peripheral multi-register back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif_path(), 'tracked runnable sideband no-policy multi-peripheral multi-register back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband no-policy multi-peripheral multi-register back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-multi-register-sideband-status-back-to-back', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'sideband no-policy multi-peripheral multi-register back-to-back report names the selected topology');
    is($result->{report}{composition}{width_policy}{data_width}, 32, 'sideband no-policy multi-peripheral multi-register back-to-back report records 32-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 4, 'sideband no-policy multi-peripheral multi-register back-to-back report records 4-bit PSTRB width');
    is($result->{report}{composition}{address_map}{alignment_bytes}, 4, 'sideband no-policy multi-peripheral multi-register back-to-back report records 4-byte address-map alignment');
    is_deeply(
        [map { $_->{base}{default} } @{$result->{report}{composition}{address_map}{windows}}],
        [0, 256],
        'sideband no-policy multi-peripheral multi-register back-to-back report preserves 4-byte-aligned window bases',
    );
    is($result->{report}{requester_accepted_field}{name}, 'accepted', 'sideband no-policy multi-peripheral multi-register back-to-back report exposes requester accepted metadata');
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy_through_interconnect', 'sideband no-policy multi-peripheral multi-register back-to-back report records aggregate propagation role');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband no-policy multi-peripheral multi-register back-to-back report preserves queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', 'sideband no-policy multi-peripheral multi-register back-to-back report preserves overflow reject');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband no-policy multi-peripheral multi-register back-to-back report preserves accepted response field');
    is($result->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband no-policy multi-peripheral multi-register back-to-back report preserves interconnect timing role');
    is($result->{report}{back_to_back_policy}{interconnect}{unmapped_policy}, 'active_access_only', 'sideband no-policy multi-peripheral multi-register back-to-back report preserves active-access-only unmapped policy');
    is_deeply(
        [map { $_->{timing_policy}{setup_admission} } @{$result->{report}{back_to_back_policy}{peripherals}}],
        [qw(adjacent adjacent)],
        'sideband no-policy multi-peripheral multi-register back-to-back report records adjacent setup admission for both peripherals',
    );
    is_deeply($result->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1)], 'sideband no-policy multi-peripheral multi-register back-to-back status peripheral reports reg0/reg1 storage');
    is_deeply($result->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband no-policy multi-peripheral multi-register back-to-back control peripheral reports reg0/reg1 storage');
    is($result->{report}{children}[2]{bindings}{storage}{registers}[1]{address}{value}, 4, 'sideband no-policy multi-peripheral multi-register back-to-back status reg1 address is 4');
    is($result->{report}{children}[3]{bindings}{storage}{registers}[1]{data}{name}, 'control_reg1_data_q', 'sideband no-policy multi-peripheral multi-register back-to-back control reg1 data signal is preserved');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'sideband no-policy multi-peripheral multi-register back-to-back top exposes accepted output');
    like($top, qr/=req_wstrb<4/, 'sideband no-policy multi-peripheral multi-register back-to-back top exposes 4-bit requester strobe');
    like($top, qr/\(queued_wdata 32\)/, 'sideband no-policy multi-peripheral multi-register back-to-back top embeds 32-bit queued data state');
    like($top, qr/\(queued_prot 3\)/, 'sideband no-policy multi-peripheral multi-register back-to-back top embeds queued PPROT state');
    like($top, qr/\(queued_wstrb 4\)/, 'sideband no-policy multi-peripheral multi-register back-to-back top embeds queued 4-bit PSTRB state');
    like($top, qr/\(status_reg1_data_q 32 \(reset 0\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back top embeds status reg1 storage');
    like($top, qr/\(control_reg1_data_q 32 \(reset 0\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back top embeds control reg1 storage');
    like($top, qr/\(<- \(control_reg1_data_q \(\| \(& control_reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back top embeds control reg1 byte-lane write mask');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PSTRB_CONTROL 4\)/, 'sideband no-policy multi-peripheral multi-register back-to-back interconnect declares control-window PSTRB width 4');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back interconnect fans out PSTRB to control');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back interconnect subtracts the 256-byte control base');
    unlike($interconnect, qr/prot_q/, 'sideband no-policy multi-peripheral multi-register back-to-back interconnect remains enforcement-free');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'sideband no-policy multi-peripheral multi-register back-to-back composition report removes broad back-to-back residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'sideband no-policy multi-peripheral multi-register back-to-back composition report keeps narrowed future timing-policy residue');
    ok($composition_residue{apb_protection_policy_effects_deferred}, 'sideband no-policy multi-peripheral multi-register back-to-back composition report keeps protection-policy effects residue');
    ok($composition_residue{apb_alternate_widths_deferred}, 'sideband no-policy multi-peripheral multi-register back-to-back composition report keeps alternate-width residue');
};

subtest 'adapter parses selected generalized sideband no-policy APB multi-peripheral multi-register back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_ppif_path(), 'tracked runnable generalized sideband no-policy multi-peripheral multi-register back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'generalized sideband no-policy multi-peripheral multi-register back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'generalized sideband no-policy multi-peripheral multi-register back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'generalized sideband no-policy multi-peripheral multi-register back-to-back APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-multi-register-sideband-generalized-status-back-to-back', 'generalized sideband no-policy multi-peripheral multi-register back-to-back APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'generalized sideband no-policy multi-peripheral multi-register back-to-back report names the selected topology');
    is($result->{report}{composition}{width_policy}{data_width}, 32, 'generalized sideband no-policy multi-peripheral multi-register back-to-back report records 32-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 4, 'generalized sideband no-policy multi-peripheral multi-register back-to-back report records 4-bit PSTRB width');
    is($result->{report}{composition}{address_map}{alignment_bytes}, 4, 'generalized sideband no-policy multi-peripheral multi-register back-to-back report records 4-byte address-map alignment');
    is_deeply(
        [map { $_->{base}{default} } @{$result->{report}{composition}{address_map}{windows}}],
        [0, 256],
        'generalized sideband no-policy multi-peripheral multi-register back-to-back report preserves 4-byte-aligned window bases',
    );
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy_through_interconnect', 'generalized sideband no-policy multi-peripheral multi-register back-to-back report records aggregate propagation role');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'generalized sideband no-policy multi-peripheral multi-register back-to-back report preserves queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', 'generalized sideband no-policy multi-peripheral multi-register back-to-back report preserves overflow reject');
    is_deeply(
        [map { $_->{timing_policy}{setup_admission} } @{$result->{report}{back_to_back_policy}{peripherals}}],
        [qw(adjacent adjacent)],
        'generalized sideband no-policy multi-peripheral multi-register back-to-back report records adjacent setup admission for both peripherals',
    );
    is_deeply($result->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband no-policy multi-peripheral multi-register back-to-back status peripheral reports reg0/reg1/reg2 storage');
    is_deeply($result->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband no-policy multi-peripheral multi-register back-to-back control peripheral reports reg0/reg1/reg2 storage');
    is($result->{report}{children}[2]{bindings}{storage}{registers}[2]{address}{value}, 8, 'generalized sideband no-policy multi-peripheral multi-register back-to-back status reg2 address is 8');
    is($result->{report}{children}[3]{bindings}{storage}{registers}[2]{data}{name}, 'control_reg2_data_q', 'generalized sideband no-policy multi-peripheral multi-register back-to-back control reg2 data signal is preserved');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back top exposes accepted output');
    like($top, qr/=req_wstrb<4/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back top exposes 4-bit requester strobe');
    like($top, qr/\(queued_wdata 32\)/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back top embeds 32-bit queued data state');
    like($top, qr/\(queued_prot 3\)/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back top embeds queued PPROT state');
    like($top, qr/\(queued_wstrb 4\)/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back top embeds queued 4-bit PSTRB state');
    like($top, qr/\(status_reg2_data_q 32 \(reset 0\)\)/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back top embeds status reg2 storage');
    like($top, qr/\(control_reg2_data_q 32 \(reset 0\)\)/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back top embeds control reg2 storage');
    like($top, qr/\(<- \(status_reg2_data_q \(\| \(& status_reg2_data_q 32'hffffff00\) \(& wdata_q 32'h000000ff\)\)\)\)/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back top embeds status reg2 byte-lane write mask');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PSTRB_CONTROL 4\)/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back interconnect declares control-window PSTRB width 4');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back interconnect fans out PSTRB to control');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back interconnect subtracts the 256-byte control base');
    unlike($interconnect, qr/prot_q/, 'generalized sideband no-policy multi-peripheral multi-register back-to-back interconnect remains enforcement-free');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'generalized sideband no-policy multi-peripheral multi-register back-to-back composition report removes broad back-to-back residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'generalized sideband no-policy multi-peripheral multi-register back-to-back composition report keeps narrowed future timing-policy residue');
    ok($composition_residue{apb_protection_policy_effects_deferred}, 'generalized sideband no-policy multi-peripheral multi-register back-to-back composition report keeps protection-policy effects residue');
    ok($composition_residue{apb_alternate_widths_deferred}, 'generalized sideband no-policy multi-peripheral multi-register back-to-back composition report keeps alternate-width residue');

    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_apb_path(), 'tracked runnable generalized sideband no-policy multi-peripheral multi-register back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'generalized sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias returns the composition kind');
    is($alias->{mode}, 'requester-multi-peripheral-composition', 'generalized sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves mode');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'generalized sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'generalized sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is_deeply($alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves control reg0/reg1/reg2 storage');
};

subtest 'adapter parses selected sideband protection APB multi-peripheral multi-register back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif_path(), 'tracked runnable sideband protection multi-peripheral multi-register back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband protection multi-peripheral multi-register back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-peripheral multi-register back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'sideband protection multi-peripheral multi-register back-to-back APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-multi-register-sideband-protection-status-back-to-back', 'sideband protection multi-peripheral multi-register back-to-back APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'sideband protection multi-peripheral multi-register back-to-back report names the selected topology');
    is($result->{report}{composition}{width_policy}{data_width}, 32, 'sideband protection multi-peripheral multi-register back-to-back report records 32-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 4, 'sideband protection multi-peripheral multi-register back-to-back report records 4-bit PSTRB width');
    is($result->{report}{composition}{address_map}{alignment_bytes}, 4, 'sideband protection multi-peripheral multi-register back-to-back report records 4-byte address-map alignment');
    is_deeply(
        [map { $_->{base}{default} } @{$result->{report}{composition}{address_map}{windows}}],
        [0, 256],
        'sideband protection multi-peripheral multi-register back-to-back report preserves 4-byte-aligned window bases',
    );
    is($result->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral multi-register back-to-back report assigns enforcement to peripheral completers');
    is($result->{report}{protection_policy}{interconnect_role}, 'propagate_pprot_pstrb_and_mux_selected_response_only', 'sideband protection multi-peripheral multi-register back-to-back report keeps interconnect role propagation-only');
    is($result->{report}{requester_accepted_field}{name}, 'accepted', 'sideband protection multi-peripheral multi-register back-to-back report exposes requester accepted metadata');
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy_through_interconnect', 'sideband protection multi-peripheral multi-register back-to-back report records aggregate propagation role');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband protection multi-peripheral multi-register back-to-back report preserves queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', 'sideband protection multi-peripheral multi-register back-to-back report preserves overflow reject');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband protection multi-peripheral multi-register back-to-back report preserves accepted response field');
    is($result->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband protection multi-peripheral multi-register back-to-back report preserves interconnect timing role');
    is($result->{report}{back_to_back_policy}{interconnect}{unmapped_policy}, 'active_access_only', 'sideband protection multi-peripheral multi-register back-to-back report preserves active-access-only unmapped policy');
    is_deeply(
        [map { $_->{timing_policy}{setup_admission} } @{$result->{report}{back_to_back_policy}{peripherals}}],
        [qw(adjacent adjacent)],
        'sideband protection multi-peripheral multi-register back-to-back report records adjacent setup admission for both peripherals',
    );
    is_deeply($result->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1)], 'sideband protection multi-peripheral multi-register back-to-back status peripheral reports reg0/reg1 storage');
    is_deeply($result->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband protection multi-peripheral multi-register back-to-back control peripheral reports reg0/reg1 storage');
    is($result->{report}{children}[2]{bindings}{storage}{registers}[1]{address}{value}, 4, 'sideband protection multi-peripheral multi-register back-to-back status reg1 address is 4');
    is($result->{report}{children}[3]{bindings}{storage}{registers}[1]{data}{name}, 'control_reg1_data_q', 'sideband protection multi-peripheral multi-register back-to-back control reg1 data signal is preserved');
    is($result->{report}{children}[2]{protection_policy}{registers}[0]{write}{predicate}{value}, 1, 'sideband protection multi-peripheral multi-register back-to-back status reg0 write policy requires privileged PPROT');
    is($result->{report}{children}[2]{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'sideband protection multi-peripheral multi-register back-to-back status reg1 read policy requires privileged PPROT');
    is($result->{report}{children}[3]{protection_policy}{registers}[0]{read}{action}, 'allow', 'sideband protection multi-peripheral multi-register back-to-back control reg0 read policy allows reads');
    is($result->{report}{children}[3]{protection_policy}{registers}[1]{write}{predicate}{value}, 1, 'sideband protection multi-peripheral multi-register back-to-back control reg1 write policy requires privileged PPROT');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'sideband protection multi-peripheral multi-register back-to-back top exposes accepted output');
    like($top, qr/=req_wstrb<4/, 'sideband protection multi-peripheral multi-register back-to-back top exposes 4-bit requester strobe');
    like($top, qr/\(queued_wdata 32\)/, 'sideband protection multi-peripheral multi-register back-to-back top embeds 32-bit queued data state');
    like($top, qr/\(queued_prot 3\)/, 'sideband protection multi-peripheral multi-register back-to-back top embeds queued PPROT state');
    like($top, qr/\(queued_wstrb 4\)/, 'sideband protection multi-peripheral multi-register back-to-back top embeds queued 4-bit PSTRB state');
    like($top, qr/\(status_reg1_data_q 32 \(reset 0\)\)/, 'sideband protection multi-peripheral multi-register back-to-back top embeds status reg1 storage');
    like($top, qr/\(control_reg1_data_q 32 \(reset 0\)\)/, 'sideband protection multi-peripheral multi-register back-to-back top embeds control reg1 storage');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-peripheral multi-register back-to-back top embeds denied protected reg1 read branch');
    like($top, qr/\(<- \(control_reg1_data_q \(\| \(& control_reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'sideband protection multi-peripheral multi-register back-to-back top embeds control reg1 byte-lane write mask');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PSTRB_CONTROL 4\)/, 'sideband protection multi-peripheral multi-register back-to-back interconnect declares control-window PSTRB width 4');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband protection multi-peripheral multi-register back-to-back interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband protection multi-peripheral multi-register back-to-back interconnect fans out PSTRB to control');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'sideband protection multi-peripheral multi-register back-to-back interconnect subtracts the 256-byte control base');
    unlike($interconnect, qr/prot_q/, 'sideband protection multi-peripheral multi-register back-to-back interconnect remains enforcement-free');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'sideband protection multi-peripheral multi-register back-to-back composition report removes broad back-to-back residue');
    ok(!$composition_residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-peripheral multi-register back-to-back composition report removes old policy-effects residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'sideband protection multi-peripheral multi-register back-to-back composition report keeps narrowed future timing-policy residue');
    ok($composition_residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-peripheral multi-register back-to-back composition report keeps additional-policy residue');
    ok($composition_residue{apb_alternate_widths_deferred}, 'sideband protection multi-peripheral multi-register back-to-back composition report keeps broad alternate-width residue');
};

subtest 'adapter parses selected generalized sideband protection APB multi-peripheral multi-register back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif_path(), 'tracked runnable generalized sideband protection multi-peripheral multi-register back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'generalized sideband protection multi-peripheral multi-register back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-multi-register-sideband-protection-generalized-status-back-to-back', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'generalized sideband protection multi-peripheral multi-register back-to-back report names the selected topology');
    is($result->{report}{composition}{width_policy}{data_width}, 32, 'generalized sideband protection multi-peripheral multi-register back-to-back report records 32-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 4, 'generalized sideband protection multi-peripheral multi-register back-to-back report records 4-bit PSTRB width');
    is($result->{report}{composition}{address_map}{alignment_bytes}, 4, 'generalized sideband protection multi-peripheral multi-register back-to-back report records 4-byte address-map alignment');
    is_deeply(
        [map { $_->{base}{default} } @{$result->{report}{composition}{address_map}{windows}}],
        [0, 256],
        'generalized sideband protection multi-peripheral multi-register back-to-back report preserves 4-byte-aligned window bases',
    );
    is($result->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'generalized sideband protection multi-peripheral multi-register back-to-back report assigns enforcement to peripheral completers');
    is($result->{report}{protection_policy}{interconnect_role}, 'propagate_pprot_pstrb_and_mux_selected_response_only', 'generalized sideband protection multi-peripheral multi-register back-to-back report keeps interconnect role propagation-only');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'generalized sideband protection multi-peripheral multi-register back-to-back report preserves queue-depth 1');
    is($result->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'generalized sideband protection multi-peripheral multi-register back-to-back report preserves interconnect timing role');
    is_deeply($result->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband protection multi-peripheral multi-register back-to-back status peripheral reports reg0/reg1/reg2 storage');
    is_deeply($result->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband protection multi-peripheral multi-register back-to-back control peripheral reports reg0/reg1/reg2 storage');
    is($result->{report}{children}[2]{bindings}{storage}{registers}[2]{address}{value}, 8, 'generalized sideband protection multi-peripheral multi-register back-to-back status reg2 address is 8');
    is($result->{report}{children}[3]{bindings}{storage}{registers}[2]{data}{name}, 'control_reg2_data_q', 'generalized sideband protection multi-peripheral multi-register back-to-back control reg2 data signal is preserved');
    is($result->{report}{children}[2]{protection_policy}{registers}[0]{read}{action}, 'allow', 'generalized sideband protection multi-peripheral multi-register back-to-back status reg0 read policy allows reads');
    is($result->{report}{children}[2]{protection_policy}{registers}[0]{write}{predicate}{value}, 1, 'generalized sideband protection multi-peripheral multi-register back-to-back status reg0 write policy requires privileged PPROT');
    is($result->{report}{children}[2]{protection_policy}{registers}[2]{read}{predicate}{value}, 1, 'generalized sideband protection multi-peripheral multi-register back-to-back status reg2 read policy requires privileged PPROT');
    is($result->{report}{children}[3]{protection_policy}{registers}[2]{write}{predicate}{value}, 1, 'generalized sideband protection multi-peripheral multi-register back-to-back control reg2 write policy requires privileged PPROT');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'generalized sideband protection multi-peripheral multi-register back-to-back top exposes accepted output');
    like($top, qr/\(queued_wdata 32\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back top embeds 32-bit queued data state');
    like($top, qr/\(queued_prot 3\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back top embeds queued PPROT state');
    like($top, qr/\(queued_wstrb 4\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back top embeds queued 4-bit PSTRB state');
    like($top, qr/\(status_reg2_data_q 32 \(reset 0\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back top embeds status reg2 storage');
    like($top, qr/\(control_reg2_data_q 32 \(reset 0\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back top embeds control reg2 storage');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 8\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back top embeds denied protected reg2 read branch');
    like($top, qr/\(\?\(& write_q \(== addr 8\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back top embeds denied protected reg2 write branch');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PSTRB_CONTROL 4\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back interconnect declares control-window PSTRB width 4');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back interconnect subtracts the 256-byte control base');
    unlike($interconnect, qr/prot_q/, 'generalized sideband protection multi-peripheral multi-register back-to-back interconnect remains enforcement-free');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'generalized sideband protection multi-peripheral multi-register back-to-back composition report removes broad back-to-back residue');
    ok(!$composition_residue{apb_protection_policy_effects_deferred}, 'generalized sideband protection multi-peripheral multi-register back-to-back composition report removes old policy-effects residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'generalized sideband protection multi-peripheral multi-register back-to-back composition report keeps narrowed future timing-policy residue');
    ok($composition_residue{apb_additional_protection_policies_deferred}, 'generalized sideband protection multi-peripheral multi-register back-to-back composition report keeps additional-policy residue');
    ok($composition_residue{apb_alternate_widths_deferred}, 'generalized sideband protection multi-peripheral multi-register back-to-back composition report keeps broad alternate-width residue');

    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_apb_path(), 'tracked runnable generalized sideband protection multi-peripheral multi-register back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias returns the composition kind');
    is($alias->{mode}, 'requester-multi-peripheral-composition', 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves mode');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is_deeply($alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves control reg0/reg1/reg2 storage');
};

subtest 'adapter parses selected sideband data16 no-policy APB multi-peripheral multi-register back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif_path(), 'tracked runnable sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband data16 no-policy multi-peripheral multi-register back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-multi-register-sideband-data16-status-back-to-back', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'sideband data16 no-policy multi-peripheral multi-register back-to-back report names the selected topology');
    is($result->{report}{composition}{width_policy}{data_width}, 16, 'sideband data16 no-policy multi-peripheral multi-register back-to-back report records 16-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 2, 'sideband data16 no-policy multi-peripheral multi-register back-to-back report records 2-bit PSTRB width');
    is($result->{report}{composition}{address_map}{alignment_bytes}, 2, 'sideband data16 no-policy multi-peripheral multi-register back-to-back report records 2-byte address-map alignment');
    is_deeply(
        [map { $_->{base}{default} } @{$result->{report}{composition}{address_map}{windows}}],
        [0, 258],
        'sideband data16 no-policy multi-peripheral multi-register back-to-back report preserves 2-byte-aligned non-4-byte window bases',
    );
    is($result->{report}{requester_accepted_field}{name}, 'accepted', 'sideband data16 no-policy multi-peripheral multi-register back-to-back report exposes requester accepted metadata');
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy_through_interconnect', 'sideband data16 no-policy multi-peripheral multi-register back-to-back report records aggregate propagation role');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband data16 no-policy multi-peripheral multi-register back-to-back report preserves queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', 'sideband data16 no-policy multi-peripheral multi-register back-to-back report preserves overflow reject');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband data16 no-policy multi-peripheral multi-register back-to-back report preserves accepted response field');
    is($result->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband data16 no-policy multi-peripheral multi-register back-to-back report preserves interconnect timing role');
    is($result->{report}{back_to_back_policy}{interconnect}{unmapped_policy}, 'active_access_only', 'sideband data16 no-policy multi-peripheral multi-register back-to-back report preserves active-access-only unmapped policy');
    is_deeply(
        [map { $_->{timing_policy}{setup_admission} } @{$result->{report}{back_to_back_policy}{peripherals}}],
        [qw(adjacent adjacent)],
        'sideband data16 no-policy multi-peripheral multi-register back-to-back report records adjacent setup admission for both peripherals',
    );
    is_deeply($result->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1)], 'sideband data16 no-policy multi-peripheral multi-register back-to-back status peripheral reports reg0/reg1 storage');
    is_deeply($result->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband data16 no-policy multi-peripheral multi-register back-to-back control peripheral reports reg0/reg1 storage');
    is($result->{report}{children}[2]{bindings}{storage}{registers}[1]{address}{value}, 2, 'sideband data16 no-policy multi-peripheral multi-register back-to-back status reg1 address is 2');
    is($result->{report}{children}[3]{bindings}{storage}{registers}[1]{data}{name}, 'control_reg1_data_q', 'sideband data16 no-policy multi-peripheral multi-register back-to-back control reg1 data signal is preserved');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back top exposes accepted output');
    like($top, qr/=req_wstrb<2/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back top exposes 2-bit requester strobe');
    like($top, qr/\(queued_wdata 16\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back top embeds 16-bit queued data state');
    like($top, qr/\(queued_prot 3\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back top embeds queued PPROT state');
    like($top, qr/\(queued_wstrb 2\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back top embeds queued 2-bit PSTRB state');
    like($top, qr/\(status_reg1_data_q 16 \(reset 0\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back top embeds status reg1 storage');
    like($top, qr/\(control_reg1_data_q 16 \(reset 0\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back top embeds control reg1 storage');
    like($top, qr/\(<- \(control_reg1_data_q \(\| \(& control_reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back top embeds control reg1 byte-lane write mask');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back interconnect declares control-window PSTRB width 2');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back interconnect fans out PSTRB to control');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back interconnect subtracts the 258-byte control base');
    unlike($interconnect, qr/prot_q/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back interconnect remains enforcement-free');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back composition report removes broad back-to-back residue');
    ok(!$composition_residue{apb_alternate_widths_deferred}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back composition report removes broad alternate-width residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back composition report keeps narrowed future timing-policy residue');
    ok($composition_residue{apb_protection_policy_effects_deferred}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back composition report keeps protection-policy effects residue');
    ok($composition_residue{apb_remaining_widths_deferred}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back composition report keeps narrowed remaining-width residue');
};

subtest 'adapter parses selected generalized sideband data16 no-policy APB multi-peripheral multi-register back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif_path(), 'tracked runnable generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-multi-register-sideband-data16-generalized-status-back-to-back', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back report names the selected topology');
    is($result->{report}{composition}{width_policy}{data_width}, 16, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back report records 16-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 2, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back report records 2-bit PSTRB width');
    is($result->{report}{composition}{address_map}{alignment_bytes}, 2, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back report records 2-byte address-map alignment');
    is_deeply(
        [map { $_->{base}{default} } @{$result->{report}{composition}{address_map}{windows}}],
        [0, 258],
        'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back report preserves 2-byte-aligned window bases',
    );
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy_through_interconnect', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back report records aggregate propagation role');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back report preserves queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back report preserves overflow reject');
    is($result->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back report preserves interconnect timing role');
    is_deeply(
        [map { $_->{timing_policy}{setup_admission} } @{$result->{report}{back_to_back_policy}{peripherals}}],
        [qw(adjacent adjacent)],
        'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back report records adjacent setup admission for both peripherals',
    );
    ok(!exists $result->{report}{protection_policy}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back report has no protection-policy owner');
    is_deeply($result->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back status peripheral reports reg0/reg1/reg2 storage');
    is_deeply($result->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back control peripheral reports reg0/reg1/reg2 storage');
    is($result->{report}{children}[2]{bindings}{storage}{registers}[2]{address}{value}, 4, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back status reg2 address is 4');
    is($result->{report}{children}[3]{bindings}{storage}{registers}[2]{data}{name}, 'control_reg2_data_q', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back control reg2 data signal is preserved');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back top exposes accepted output');
    like($top, qr/=req_wstrb<2/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back top exposes 2-bit requester strobe');
    like($top, qr/\(queued_wdata 16\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back top embeds 16-bit queued data state');
    like($top, qr/\(queued_wstrb 2\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back top embeds queued 2-bit PSTRB state');
    like($top, qr/\(status_reg2_data_q 16 \(reset 0\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back top embeds status reg2 storage');
    like($top, qr/\(control_reg2_data_q 16 \(reset 0\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back top embeds control reg2 storage');
    like($top, qr/\(<- \(status_reg2_data_q \(\| \(& status_reg2_data_q 16'hff00\) \(& wdata_q 16'h00ff\)\)\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back top embeds status reg2 byte-lane write mask');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back interconnect declares control-window PSTRB width 2');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back interconnect fans out PSTRB to control');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back interconnect subtracts the 258-byte control base');
    unlike($interconnect, qr/prot_q/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back interconnect remains enforcement-free');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back composition report removes broad back-to-back residue');
    ok(!$composition_residue{apb_alternate_widths_deferred}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back composition report removes broad alternate-width residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back composition report keeps narrowed future timing-policy residue');
    ok($composition_residue{apb_protection_policy_effects_deferred}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back composition report keeps protection-policy effects residue');
    ok($composition_residue{apb_remaining_widths_deferred}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back composition report keeps narrowed remaining-width residue');

    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_apb_path(), 'tracked runnable generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias returns the composition kind');
    is($alias->{mode}, 'requester-multi-peripheral-composition', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves mode');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is_deeply($alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves control reg0/reg1/reg2 storage');
};

subtest 'adapter parses selected sideband data16 protection APB multi-peripheral multi-register back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif_path(), 'tracked runnable sideband data16 protection multi-peripheral multi-register back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband data16 protection multi-peripheral multi-register back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-multi-register-sideband-data16-protection-status-back-to-back', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'sideband data16 protection multi-peripheral multi-register back-to-back report names the selected topology');
    is($result->{report}{composition}{width_policy}{data_width}, 16, 'sideband data16 protection multi-peripheral multi-register back-to-back report records 16-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 2, 'sideband data16 protection multi-peripheral multi-register back-to-back report records 2-bit PSTRB width');
    is($result->{report}{composition}{address_map}{alignment_bytes}, 2, 'sideband data16 protection multi-peripheral multi-register back-to-back report records 2-byte address-map alignment');
    is_deeply(
        [map { $_->{base}{default} } @{$result->{report}{composition}{address_map}{windows}}],
        [0, 258],
        'sideband data16 protection multi-peripheral multi-register back-to-back report preserves 2-byte-aligned non-4-byte window bases',
    );
    is($result->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband data16 protection multi-peripheral multi-register back-to-back report assigns enforcement to peripheral completers');
    is($result->{report}{protection_policy}{interconnect_role}, 'propagate_pprot_pstrb_and_mux_selected_response_only', 'sideband data16 protection multi-peripheral multi-register back-to-back report keeps interconnect role propagation-only');
    is($result->{report}{requester_accepted_field}{name}, 'accepted', 'sideband data16 protection multi-peripheral multi-register back-to-back report exposes requester accepted metadata');
    is($result->{report}{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy_through_interconnect', 'sideband data16 protection multi-peripheral multi-register back-to-back report records aggregate propagation role');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband data16 protection multi-peripheral multi-register back-to-back report preserves queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', 'sideband data16 protection multi-peripheral multi-register back-to-back report preserves overflow reject');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband data16 protection multi-peripheral multi-register back-to-back report preserves accepted response field');
    is($result->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband data16 protection multi-peripheral multi-register back-to-back report preserves interconnect timing role');
    is($result->{report}{back_to_back_policy}{interconnect}{unmapped_policy}, 'active_access_only', 'sideband data16 protection multi-peripheral multi-register back-to-back report preserves active-access-only unmapped policy');
    is_deeply(
        [map { $_->{timing_policy}{setup_admission} } @{$result->{report}{back_to_back_policy}{peripherals}}],
        [qw(adjacent adjacent)],
        'sideband data16 protection multi-peripheral multi-register back-to-back report records adjacent setup admission for both peripherals',
    );
    is_deeply($result->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1)], 'sideband data16 protection multi-peripheral multi-register back-to-back status peripheral reports reg0/reg1 storage');
    is_deeply($result->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband data16 protection multi-peripheral multi-register back-to-back control peripheral reports reg0/reg1 storage');
    is($result->{report}{children}[2]{bindings}{storage}{registers}[1]{address}{value}, 2, 'sideband data16 protection multi-peripheral multi-register back-to-back status reg1 address is 2');
    is($result->{report}{children}[3]{bindings}{storage}{registers}[1]{data}{name}, 'control_reg1_data_q', 'sideband data16 protection multi-peripheral multi-register back-to-back control reg1 data signal is preserved');
    is($result->{report}{children}[2]{protection_policy}{registers}[0]{write}{predicate}{value}, 1, 'sideband data16 protection multi-peripheral multi-register back-to-back status reg0 write policy requires privileged PPROT');
    is($result->{report}{children}[2]{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'sideband data16 protection multi-peripheral multi-register back-to-back status reg1 read policy requires privileged PPROT');
    is($result->{report}{children}[3]{protection_policy}{registers}[0]{read}{action}, 'allow', 'sideband data16 protection multi-peripheral multi-register back-to-back control reg0 read policy allows reads');
    is($result->{report}{children}[3]{protection_policy}{registers}[1]{write}{predicate}{value}, 1, 'sideband data16 protection multi-peripheral multi-register back-to-back control reg1 write policy requires privileged PPROT');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'sideband data16 protection multi-peripheral multi-register back-to-back top exposes accepted output');
    like($top, qr/=req_wstrb<2/, 'sideband data16 protection multi-peripheral multi-register back-to-back top exposes 2-bit requester strobe');
    like($top, qr/\(queued_wdata 16\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back top embeds 16-bit queued data state');
    like($top, qr/\(queued_prot 3\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back top embeds queued PPROT state');
    like($top, qr/\(queued_wstrb 2\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back top embeds queued 2-bit PSTRB state');
    like($top, qr/\(status_reg1_data_q 16 \(reset 0\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back top embeds status reg1 storage');
    like($top, qr/\(control_reg1_data_q 16 \(reset 0\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back top embeds control reg1 storage');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back top embeds denied protected reg1 read branch');
    like($top, qr/\(<- \(control_reg1_data_q \(\| \(& control_reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back top embeds control reg1 byte-lane write mask');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back interconnect declares control-window PSTRB width 2');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back interconnect fans out PSTRB to control');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back interconnect subtracts the 258-byte control base');
    unlike($interconnect, qr/prot_q/, 'sideband data16 protection multi-peripheral multi-register back-to-back interconnect remains enforcement-free');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back composition report removes broad back-to-back residue');
    ok(!$composition_residue{apb_protection_policy_effects_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back composition report removes old policy-effects residue');
    ok(!$composition_residue{apb_alternate_widths_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back composition report keeps broad alternate-width residue absent');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back composition report keeps narrowed future timing-policy residue');
    ok($composition_residue{apb_additional_protection_policies_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back composition report keeps additional-policy residue');
    ok($composition_residue{apb_remaining_widths_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back composition report keeps narrowed remaining-width residue');
};

subtest 'adapter parses the sideband protection APB multi-peripheral composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_sideband_protection_ppif_path(), 'tracked runnable sideband protection multi-peripheral APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_protection_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband protection multi-peripheral APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-peripheral adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'sideband protection multi-peripheral APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-sideband-protection', 'sideband protection multi-peripheral APB composition source object id is preserved');
    is($result->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'multi-peripheral protection report assigns enforcement to peripheral completers');
    is($result->{report}{protection_policy}{interconnect_role}, 'propagate_pprot_pstrb_and_mux_selected_response_only', 'multi-peripheral protection report keeps interconnect role propagation-only');
    is_deeply(
        [map { $_->{object_name} } @{$result->{report}{protection_policy}{peripherals}}],
        [qw(apb_status_regs apb_control_regs)],
        'multi-peripheral protection report lists protected peripherals',
    );
    is($result->{report}{children}[1]{protection_policy}{enforcement_owner}, 'peripheral_completers', 'interconnect child report names completers as enforcement owners');
    is($result->{report}{children}[2]{protection_policy}{registers}[0]{write}{predicate}{value}, 1, 'status peripheral report preserves write policy');
    is($result->{report}{children}[3]{protection_policy}{registers}[0]{read}{predicate}{value}, 1, 'control peripheral report preserves read policy');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/\(interconnect\.PPROT_STATUS status_peripheral\.PPROT_STATUS\)/, 'sideband protection multi-peripheral top wires status PPROT');
    like($top, qr/\(interconnect\.PSTRB_CONTROL control\.PSTRB_CONTROL\)/, 'sideband protection multi-peripheral top wires control PSTRB');
    like($top, qr/\(\?\(& write_q \(== addr 0\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-peripheral top embeds denied status write branch');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 0\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-peripheral top embeds denied control read branch');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband protection interconnect fans out PPROT to status window');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband protection interconnect fans out PSTRB to control window');
    unlike($interconnect, qr/prot_q/, 'sideband protection interconnect does not sample or enforce PPROT itself');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-peripheral composition removes old policy-effects residue');
    ok($composition_residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-peripheral composition keeps additional-policy residue');
};

subtest 'adapter parses selected sideband protection APB multi-peripheral back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif_path(), 'tracked runnable sideband protection multi-peripheral back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband protection multi-peripheral back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-peripheral back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'sideband protection multi-peripheral back-to-back APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-sideband-protection-status-back-to-back', 'sideband protection multi-peripheral back-to-back APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'sideband protection multi-peripheral back-to-back report names the selected topology');
    is($result->{report}{composition}{width_policy}{data_width}, 32, 'sideband protection multi-peripheral back-to-back report records 32-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 4, 'sideband protection multi-peripheral back-to-back report records 4-bit PSTRB width');
    is($result->{report}{composition}{address_map}{alignment_bytes}, 4, 'sideband protection multi-peripheral back-to-back report records 4-byte address-map alignment');
    is_deeply(
        [map { $_->{base}{default} } @{$result->{report}{composition}{address_map}{windows}}],
        [0, 256],
        'sideband protection multi-peripheral back-to-back report preserves 4-byte-aligned window bases',
    );
    is($result->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral back-to-back report assigns enforcement to peripheral completers');
    is($result->{report}{protection_policy}{interconnect_role}, 'propagate_pprot_pstrb_and_mux_selected_response_only', 'sideband protection multi-peripheral back-to-back report keeps interconnect role propagation-only');
    is($result->{report}{requester_accepted_field}{name}, 'accepted', 'sideband protection multi-peripheral back-to-back report exposes requester accepted metadata');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband protection multi-peripheral back-to-back report preserves queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', 'sideband protection multi-peripheral back-to-back report preserves overflow reject');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband protection multi-peripheral back-to-back report preserves accepted response field');
    is($result->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband protection multi-peripheral back-to-back report preserves interconnect timing role');
    is($result->{report}{back_to_back_policy}{interconnect}{unmapped_policy}, 'active_access_only', 'sideband protection multi-peripheral back-to-back report preserves active-access-only unmapped policy');
    is($result->{report}{back_to_back_policy}{peripherals}[0]{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-peripheral back-to-back report preserves status adjacent setup admission');
    is($result->{report}{back_to_back_policy}{peripherals}[1]{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-peripheral back-to-back report preserves control adjacent setup admission');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'sideband protection multi-peripheral back-to-back top exposes accepted output');
    like($top, qr/=req_wstrb<4/, 'sideband protection multi-peripheral back-to-back top exposes 4-bit requester strobe');
    like($top, qr/\(queued_wdata 32\)/, 'sideband protection multi-peripheral back-to-back top embeds 32-bit queued data state');
    like($top, qr/\(queued_prot 3\)/, 'sideband protection multi-peripheral back-to-back top embeds queued PPROT state');
    like($top, qr/\(queued_wstrb 4\)/, 'sideband protection multi-peripheral back-to-back top embeds queued 4-bit PSTRB state');
    like($top, qr/\(<= \(addr PADDR_CONTROL\) <\(& PSEL_CONTROL \(! PENABLE_CONTROL\)\)\)/, 'sideband protection multi-peripheral back-to-back top embeds control adjacent setup detector');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 0\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-peripheral back-to-back top embeds denied control read branch');
    like($top, qr/\(<- \(control_shadow_data_q \(\| \(& control_shadow_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'sideband protection multi-peripheral back-to-back top embeds high-byte control shadow write mask');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PSTRB_CONTROL 4\)/, 'sideband protection multi-peripheral back-to-back interconnect declares control-window PSTRB width 4');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband protection multi-peripheral back-to-back interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'sideband protection multi-peripheral back-to-back interconnect subtracts the 256-byte control base');
    unlike($interconnect, qr/prot_q/, 'sideband protection multi-peripheral back-to-back interconnect remains enforcement-free');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'sideband protection multi-peripheral back-to-back composition report removes broad back-to-back residue');
    ok(!$composition_residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-peripheral back-to-back composition report removes old policy-effects residue');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'sideband protection multi-peripheral back-to-back composition report keeps narrowed future timing-policy residue');
    ok($composition_residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-peripheral back-to-back composition report keeps additional-policy residue');
    ok($composition_residue{apb_alternate_widths_deferred}, 'sideband protection multi-peripheral back-to-back composition report keeps broad alternate-width residue');
};

subtest 'adapter parses the sideband APB multi-peripheral data16 composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_sideband_data16_ppif_path(), 'tracked runnable sideband multi-peripheral data16 APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband multi-peripheral data16 APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband multi-peripheral data16 adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'sideband multi-peripheral data16 APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-sideband-data16', 'sideband multi-peripheral data16 APB composition source object id is preserved');
    is($result->{report}{composition}{width_policy}{data_width}, 16, 'sideband multi-peripheral data16 report records 16-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 2, 'sideband multi-peripheral data16 report records 2-bit PSTRB width');
    is($result->{report}{composition}{address_map}{alignment_bytes}, 2, 'sideband multi-peripheral data16 report records 2-byte address-map alignment');
    is_deeply(
        [map { $_->{base}{default} } @{$result->{report}{composition}{address_map}{windows}}],
        [0, 258],
        'sideband multi-peripheral data16 report preserves 2-byte-aligned non-4-byte window bases',
    );

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=req_wdata<16/, 'sideband multi-peripheral data16 APB composition top exposes 16-bit request write-data input');
    like($top, qr/=req_wstrb<2/, 'sideband multi-peripheral data16 APB composition top exposes 2-bit request strobe input');
    like($top, qr/\(interconnect\.PSTRB_CONTROL control\.PSTRB_CONTROL\)/, 'sideband multi-peripheral data16 top wires control-window PSTRB');
    like($top, qr/\(<= \(strb_q PSTRB_CONTROL\) <\(& PSEL_CONTROL \(! PENABLE_CONTROL\)\)\)/, 'sideband multi-peripheral data16 top embeds control peripheral PSTRB sampling');
    like($top, qr/\(control_data_q 16 \(reset 0\)\)/, 'sideband multi-peripheral data16 top embeds 16-bit control register');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'sideband data16 interconnect declares control-window PSTRB width 2');
    like($interconnect, qr/\(<- \(PSEL_STATUS> PSEL\) <\(& PSEL \(>= PADDR 0\) \(< PADDR 258\)\)\)/, 'sideband data16 interconnect decodes the 258-byte status window');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'sideband data16 interconnect subtracts the 258-byte control base');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_alternate_widths_deferred}, 'sideband multi-peripheral data16 composition report removes broad alternate-width residue');
    ok($composition_residue{apb_remaining_widths_deferred}, 'sideband multi-peripheral data16 composition report keeps narrowed remaining-width residue');
    ok($composition_residue{apb_protection_policy_effects_deferred}, 'sideband multi-peripheral data16 composition report keeps protection-policy effects deferred');
};

subtest 'adapter parses the sideband protection APB multi-peripheral data16 composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_sideband_data16_protection_ppif_path(), 'tracked runnable sideband protection multi-peripheral data16 APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_protection_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband protection multi-peripheral data16 APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-peripheral data16 adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'sideband protection multi-peripheral data16 APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-sideband-data16-protection', 'sideband protection multi-peripheral data16 APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'sideband protection multi-peripheral data16 report names the selected topology');
    is($result->{report}{composition}{width_policy}{data_width}, 16, 'sideband protection multi-peripheral data16 report records 16-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 2, 'sideband protection multi-peripheral data16 report records 2-bit PSTRB width');
    is($result->{report}{composition}{address_map}{alignment_bytes}, 2, 'sideband protection multi-peripheral data16 report records 2-byte address-map alignment');
    is_deeply(
        [map { $_->{base}{default} } @{$result->{report}{composition}{address_map}{windows}}],
        [0, 258],
        'sideband protection multi-peripheral data16 report preserves 2-byte-aligned window bases',
    );
    is($result->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'multi-peripheral data16 protection report assigns enforcement to peripheral completers');
    is($result->{report}{protection_policy}{interconnect_role}, 'propagate_pprot_pstrb_and_mux_selected_response_only', 'multi-peripheral data16 protection report keeps interconnect role propagation-only');
    is($result->{report}{children}[1]{protection_policy}{interconnect_role}, 'propagate_pprot_pstrb_and_mux_selected_response_only', 'multi-peripheral data16 protection interconnect child report remains propagation-only');
    is($result->{report}{children}[2]{protection_policy}{registers}[1]{write}{predicate}{value}, 1, 'status shadow data16 peripheral report preserves write policy');
    is($result->{report}{children}[3]{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'control shadow data16 peripheral report preserves read policy');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=req_wdata<16/, 'sideband protection multi-peripheral data16 top exposes 16-bit request write-data input');
    like($top, qr/=req_wstrb<2/, 'sideband protection multi-peripheral data16 top exposes 2-bit request strobe input');
    like($top, qr/\(interconnect\.PSTRB_CONTROL control\.PSTRB_CONTROL\)/, 'sideband protection multi-peripheral data16 top wires control-window PSTRB');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 0\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-peripheral data16 top embeds denied control read branch');
    like($top, qr/\(<- \(control_shadow_data_q \(\| \(& control_shadow_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband protection multi-peripheral data16 top embeds high-byte control shadow write mask');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'sideband protection data16 interconnect declares control-window PSTRB width 2');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband protection data16 interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'sideband protection data16 interconnect subtracts the 258-byte control base');
    unlike($interconnect, qr/prot_q/, 'sideband protection data16 interconnect remains enforcement-free');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-peripheral data16 composition report removes old policy-effects residue');
    ok(!$composition_residue{apb_alternate_widths_deferred}, 'sideband protection multi-peripheral data16 composition report keeps broad alternate-width residue absent');
    ok($composition_residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-peripheral data16 composition report keeps additional-policy residue');
    ok($composition_residue{apb_remaining_widths_deferred}, 'sideband protection multi-peripheral data16 composition report keeps narrowed remaining-width residue');
};

subtest 'adapter parses selected sideband protection APB multi-peripheral data16 back-to-back composition PPIF shape' => sub {
    ok(-f sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif_path(), 'tracked runnable sideband protection multi-peripheral data16 back-to-back APB composition PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'sideband protection multi-peripheral data16 back-to-back APB composition adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-peripheral data16 back-to-back adapter returns the APB composition kind');
    is($result->{mode}, 'requester-multi-peripheral-composition', 'sideband protection multi-peripheral data16 back-to-back APB composition mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-composition-multi-peripheral-sideband-data16-protection-status-back-to-back', 'sideband protection multi-peripheral data16 back-to-back APB composition source object id is preserved');
    is($result->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'sideband protection multi-peripheral data16 back-to-back report names the selected topology');
    is($result->{report}{composition}{width_policy}{data_width}, 16, 'sideband protection multi-peripheral data16 back-to-back report records 16-bit data width');
    is($result->{report}{composition}{width_policy}{strobe_width}, 2, 'sideband protection multi-peripheral data16 back-to-back report records 2-bit PSTRB width');
    is($result->{report}{composition}{address_map}{alignment_bytes}, 2, 'sideband protection multi-peripheral data16 back-to-back report records 2-byte address-map alignment');
    is_deeply(
        [map { $_->{base}{default} } @{$result->{report}{composition}{address_map}{windows}}],
        [0, 258],
        'sideband protection multi-peripheral data16 back-to-back report preserves 2-byte-aligned window bases',
    );
    is($result->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral data16 back-to-back report assigns enforcement to peripheral completers');
    is($result->{report}{protection_policy}{interconnect_role}, 'propagate_pprot_pstrb_and_mux_selected_response_only', 'sideband protection multi-peripheral data16 back-to-back report keeps interconnect role propagation-only');
    is($result->{report}{requester_accepted_field}{name}, 'accepted', 'sideband protection multi-peripheral data16 back-to-back report exposes requester accepted metadata');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband protection multi-peripheral data16 back-to-back report preserves queue-depth 1');
    is($result->{report}{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband protection multi-peripheral data16 back-to-back report preserves accepted response field');
    is($result->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband protection multi-peripheral data16 back-to-back report preserves interconnect timing role');
    is($result->{report}{back_to_back_policy}{interconnect}{unmapped_policy}, 'active_access_only', 'sideband protection multi-peripheral data16 back-to-back report preserves active-access-only unmapped policy');
    is($result->{report}{back_to_back_policy}{peripherals}[0]{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-peripheral data16 back-to-back report preserves status adjacent setup admission');
    is($result->{report}{back_to_back_policy}{peripherals}[1]{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-peripheral data16 back-to-back report preserves control adjacent setup admission');

    my $top = $result->{generated_ial0}{files}{'apb_tb.fsm'};
    like($top, qr/=accepted>/, 'sideband protection multi-peripheral data16 back-to-back top exposes accepted output');
    like($top, qr/=req_wstrb<2/, 'sideband protection multi-peripheral data16 back-to-back top exposes 2-bit requester strobe');
    like($top, qr/\(queued_wdata 16\)/, 'sideband protection multi-peripheral data16 back-to-back top embeds 16-bit queued data state');
    like($top, qr/\(queued_prot 3\)/, 'sideband protection multi-peripheral data16 back-to-back top embeds queued PPROT state');
    like($top, qr/\(queued_wstrb 2\)/, 'sideband protection multi-peripheral data16 back-to-back top embeds queued 2-bit PSTRB state');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 0\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-peripheral data16 back-to-back top embeds denied control read branch');
    like($top, qr/\(<- \(control_shadow_data_q \(\| \(& control_shadow_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband protection multi-peripheral data16 back-to-back top embeds high-byte control shadow write mask');

    my $interconnect = $result->{generated_ial0}{files}{'apb_interconnect.fsm'};
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'sideband protection multi-peripheral data16 back-to-back interconnect declares control-window PSTRB width 2');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband protection multi-peripheral data16 back-to-back interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'sideband protection multi-peripheral data16 back-to-back interconnect subtracts the 258-byte control base');
    unlike($interconnect, qr/prot_q/, 'sideband protection multi-peripheral data16 back-to-back interconnect remains enforcement-free');

    my %composition_residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_back_to_back_policy_deferred}, 'sideband protection multi-peripheral data16 back-to-back composition report removes broad back-to-back residue');
    ok(!$composition_residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-peripheral data16 back-to-back composition report removes old policy-effects residue');
    ok(!$composition_residue{apb_alternate_widths_deferred}, 'sideband protection multi-peripheral data16 back-to-back composition report keeps broad alternate-width residue absent');
    ok($composition_residue{apb_additional_back_to_back_policies_deferred}, 'sideband protection multi-peripheral data16 back-to-back composition report keeps narrowed future timing-policy residue');
    ok($composition_residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-peripheral data16 back-to-back composition report keeps additional-policy residue');
    ok($composition_residue{apb_remaining_widths_deferred}, 'sideband protection multi-peripheral data16 back-to-back composition report keeps narrowed remaining-width residue');
};

subtest 'adapter rejects malformed APB composition PPIF shapes with targeted diagnostics' => sub {
    my $missing_composition = sample_apb_composition_ppif();
    $missing_composition =~ s/\n  \(apb-composition apb_tb\n    \(role composition\)\n    \(clock clk\)\n    \(reset \(rst_n active_low async\)\)\n    \(children\n      \(requester requester apb_requester\)\n      \(completer completer apb_completer\)\)\n    \(wiring apb_bus\n      \(select PSEL\)\n      \(enable PENABLE\)\n      \(write PWRITE\)\n      \(address PADDR width 32\)\n      \(write-data PWDATA width 32\)\n      \(ready PREADY\)\n      \(read-data PRDATA width 32\)\n      \(error PSLVERR\)\)\)//;

    my $bad_child = sample_apb_composition_ppif();
    $bad_child =~ s/\(requester requester apb_requester\)/(requester requester apb_requester_other)/;

    my $bad_bus = sample_apb_composition_ppif();
    $bad_bus =~ s/\(ready PREADY\)\n      \(read-data PRDATA width 32\)\n      \(error PSLVERR\)\)\)\)\n\z/(ready PREADY_OTHER)\n      (read-data PRDATA width 32)\n      (error PSLVERR))))\n/;

    my $single_peripheral = sample_apb_composition_multi_peripheral_ppif();
    $single_peripheral =~ s/\n      \(peripheral control apb_control_regs\)//;

    my $mixed_child_forms = sample_apb_composition_multi_peripheral_ppif();
    $mixed_child_forms =~ s/\(peripheral control apb_control_regs\)/(completer completer apb_control_regs)/;

    my $overlapping_windows = sample_apb_composition_multi_peripheral_ppif();
    $overlapping_windows =~ s/\(base CONTROL_BASE width 32 default 256\)/(base CONTROL_BASE width 32 default 128)/;

    my $fixed_partial_sideband = sample_apb_composition_multi_register_sideband_ppif();
    $fixed_partial_sideband =~ s/(\(apb-composition apb_tb[\s\S]*?\n      \(protection PPROT width 3\))\n      \(strobe PSTRB width 4\)/$1/;

    my $multi_partial_sideband = sample_apb_composition_multi_peripheral_sideband_ppif();
    $multi_partial_sideband =~ s/\n      \(strobe PSTRB_CONTROL width 4\)//;

    my $bad_data16_window_alignment = sample_apb_composition_multi_peripheral_sideband_data16_ppif();
    $bad_data16_window_alignment =~ s/\(base CONTROL_BASE width 32 default 258\)/(base CONTROL_BASE width 32 default 259)/;

    my $fixed_missing_completer_timing = sample_apb_composition_status_back_to_back_ppif();
    $fixed_missing_completer_timing =~ s/\n      \(timing-policy\n        \(setup-admission adjacent\)\)//;

    my $fixed_data16_back_to_back_wrong_reg1_address = sample_apb_composition_multi_register_sideband_data16_status_back_to_back_ppif();
    $fixed_data16_back_to_back_wrong_reg1_address =~ s/\(address 2 width 32\)/(address 4 width 32)/;

    my $fixed_protection_back_to_back_wrong_reg1_address = sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif();
    $fixed_protection_back_to_back_wrong_reg1_address =~ s/\(address 4 width 32\)/(address 8 width 32)/;

    my $fixed_protection_back_to_back_wrong_policy = sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif();
    $fixed_protection_back_to_back_wrong_policy =~ s/\(read require \(privileged 1\)\)/(read allow)/;

    my $fixed_data16_protection_back_to_back_wrong_reg1_address = sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif();
    $fixed_data16_protection_back_to_back_wrong_reg1_address =~ s/\(address 2 width 32\)/(address 4 width 32)/;

    my $fixed_data16_protection_back_to_back_wrong_policy = sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif();
    $fixed_data16_protection_back_to_back_wrong_policy =~ s/\(read require \(privileged 1\)\)/(read allow)/;

    my $multi_missing_control_timing = sample_apb_composition_multi_peripheral_status_back_to_back_ppif();
    $multi_missing_control_timing =~ s/(\(apb-completer apb_control_regs[\s\S]*?\n      \(unmapped-address error\))\n      \(timing-policy\n        \(setup-admission adjacent\)\)/$1/;

    my $multi_protection_back_to_back_wrong_status_reg1_address = sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif();
    $multi_protection_back_to_back_wrong_status_reg1_address =~ s/\(address 4 width 32\)/(address 8 width 32)/;

    my $multi_protection_back_to_back_wrong_control_policy = sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif();
    $multi_protection_back_to_back_wrong_control_policy =~ s/\(read require \(privileged 1\)\)/(read allow)/;

    my $multi_no_policy_back_to_back_wrong_status_reg1_address = sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif();
    $multi_no_policy_back_to_back_wrong_status_reg1_address =~ s/\(address 4 width 32\)/(address 8 width 32)/;

    my $multi_no_policy_back_to_back_with_status_access_policy = sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif();
    $multi_no_policy_back_to_back_with_status_access_policy =~ s/\(data status_reg0_data_q width 32 reset 0\)\)/(data status_reg0_data_q width 32 reset 0)\n        (access-policy\n          (read allow)\n          (write require (privileged 1))))/;

    my $multi_generalized_no_policy_back_to_back_wrong_status_reg2_address = sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_ppif();
    $multi_generalized_no_policy_back_to_back_wrong_status_reg2_address =~ s/\(address 8 width 32\)/(address 12 width 32)/;

    my $multi_generalized_no_policy_back_to_back_with_status_access_policy = sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_ppif();
    $multi_generalized_no_policy_back_to_back_with_status_access_policy =~ s/\(data status_reg2_data_q width 32 reset 0\)\)/(data status_reg2_data_q width 32 reset 0)\n        (access-policy\n          (read allow)\n          (write require (privileged 1))))/;

    my $multi_protection_mreg_back_to_back_wrong_status_reg1_address = sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif();
    $multi_protection_mreg_back_to_back_wrong_status_reg1_address =~ s/\(address 4 width 32\)/(address 8 width 32)/;

    my $multi_protection_mreg_back_to_back_wrong_control_policy = sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif();
    $multi_protection_mreg_back_to_back_wrong_control_policy =~ s/\(read require \(privileged 1\)\)/(read allow)/;

    my $multi_protection_generalized_back_to_back_wrong_status_reg2_address = sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif();
    $multi_protection_generalized_back_to_back_wrong_status_reg2_address =~ s/\(address 8 width 32\)/(address 12 width 32)/;

    my $multi_protection_generalized_back_to_back_wrong_status_reg2_policy = sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif();
    $multi_protection_generalized_back_to_back_wrong_status_reg2_policy =~ s/\(register reg2\n        \(address 8 width 32\)\n        \(data status_reg2_data_q width 32 reset 0\)\n        \(access-policy\n          \(read require \(privileged 1\)\)/\(register reg2\n        \(address 8 width 32\)\n        \(data status_reg2_data_q width 32 reset 0\)\n        \(access-policy\n          \(read allow\)/;

    my $multi_protection_generalized_back_to_back_mismatched_register_count = sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif();
    $multi_protection_generalized_back_to_back_mismatched_register_count =~ s/\n      \(register reg2\n        \(address 8 width 32\)\n        \(data control_reg2_data_q width 32 reset 0\)\n        \(access-policy\n          \(read require \(privileged 1\)\)\n          \(write require \(privileged 1\)\)\)\)\)/\n    \)/;

    my $multi_data16_no_policy_back_to_back_wrong_status_reg1_address = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif();
    $multi_data16_no_policy_back_to_back_wrong_status_reg1_address =~ s/\(address 2 width 32\)/(address 4 width 32)/;

    my $multi_data16_no_policy_back_to_back_with_status_access_policy = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif();
    $multi_data16_no_policy_back_to_back_with_status_access_policy =~ s/\(data status_reg0_data_q width 16 reset 0\)\)/(data status_reg0_data_q width 16 reset 0)\n        (access-policy\n          (read allow)\n          (write require (privileged 1))))/;

    my $multi_data16_generalized_no_policy_back_to_back_wrong_status_reg2_address = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif();
    $multi_data16_generalized_no_policy_back_to_back_wrong_status_reg2_address =~ s/\(address 4 width 32\)/(address 6 width 32)/;

    my $multi_data16_generalized_no_policy_back_to_back_with_status_access_policy = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif();
    $multi_data16_generalized_no_policy_back_to_back_with_status_access_policy =~ s/\(data status_reg2_data_q width 16 reset 0\)\)/(data status_reg2_data_q width 16 reset 0)\n        (access-policy\n          (read allow)\n          (write require (privileged 1))))/;

    my $multi_data16_generalized_no_policy_back_to_back_mismatched_register_count = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif();
    $multi_data16_generalized_no_policy_back_to_back_mismatched_register_count =~ s/\n      \(register reg2\n        \(address 4 width 32\)\n        \(data control_reg2_data_q width 16 reset 0\)\)//;

    my $multi_data16_protection_mreg_back_to_back_wrong_status_reg1_address = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif();
    $multi_data16_protection_mreg_back_to_back_wrong_status_reg1_address =~ s/\(address 2 width 32\)/(address 4 width 32)/;

    my $multi_data16_protection_mreg_back_to_back_wrong_control_policy = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif();
    $multi_data16_protection_mreg_back_to_back_wrong_control_policy =~ s/\(read require \(privileged 1\)\)/(read allow)/;

    my $multi_data16_protection_back_to_back_wrong_status_reg1_address = sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif();
    $multi_data16_protection_back_to_back_wrong_status_reg1_address =~ s/\(address 2 width 32\)/(address 4 width 32)/;

    my $multi_data16_protection_back_to_back_wrong_control_policy = sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif();
    $multi_data16_protection_back_to_back_wrong_control_policy =~ s/\(read require \(privileged 1\)\)/(read allow)/;

    my $fixed_timing_storage_error = qr/APB fixed composition selected back-to-back timing-policy supports only one-register completer storage, selected 32-bit sideband-aware two-register no-policy completer storage, selected 32-bit sideband-aware two-register protection completer storage, selected sideband-aware data16 two-register no-policy completer storage, or selected sideband-aware data16 two-register protection completer storage in this slice/;
    my $multi_timing_storage_error = qr/APB multi-peripheral selected back-to-back timing-policy supports only one-register peripheral completer storage, the selected two-peripheral sideband no-policy reg0\/reg1 storage shape, the selected bounded two-peripheral sideband generalized no-policy reg0\.\.regN register-set storage shape, the selected bounded two-peripheral sideband protected generalized reg0\.\.regN register-set storage shape, the selected two-peripheral sideband protection reg0\/reg1 storage shape, or the selected two-peripheral sideband protection status\/control storage shape in this slice/;
    my $multi_data16_timing_storage_error = qr/APB multi-peripheral selected back-to-back timing-policy supports only the selected two-peripheral sideband data16 no-policy reg0\/reg1 storage shape, the selected bounded two-peripheral sideband data16 generalized no-policy reg0\.\.regN register-set storage shape, the selected two-peripheral sideband data16 protection reg0\/reg1 storage shape, or the selected two-peripheral sideband data16 protection status\/control storage shape in this slice/;

    my @cases = (
        ['missing apb composition object', $missing_composition, qr/cannot mix \(apb-requester \.\.\.\) with .* \(apb-completer \.\.\.\).*outside the explicit APB composition shape/s],
        ['bad requester child reference', $bad_child, qr/APB composition requester child references .*expected 'apb_requester'/],
        ['bad ready bus wiring', $bad_bus, qr/APB composition IAL2 contract bus\.ready must be scalar signal 'PREADY_OTHER'/],
        ['single multi-peripheral child', $single_peripheral, qr/requires two or more peripheral children/],
        ['mixed fixed and peripheral child forms', $mixed_child_forms, qr/cannot mix fixed \(completer \.\.\.\) with multi-peripheral \(peripheral \.\.\.\) entries/],
        ['overlapping multi-peripheral windows', $overlapping_windows, qr/address-map windows 'status' and 'control' overlap/],
        ['fixed composition partial sideband wiring', $fixed_partial_sideband, qr/APB composition IAL2 contract composition wiring bus must declare protection and strobe together/],
        ['multi-peripheral partial sideband peripheral', $multi_partial_sideband, qr/APB multi-peripheral composition peripheral 'apb_control_regs' bus must declare protection and strobe together/],
        ['multi-peripheral data16 bad window alignment', $bad_data16_window_alignment, qr/address-map base '259' must be 2-byte aligned/],
        ['fixed composition missing completer timing policy', $fixed_missing_completer_timing, qr/requires requester back-to-back queued queue-depth 1 overflow reject and completer setup-admission adjacent/],
        ['fixed composition data16 back-to-back wrong selected register address', $fixed_data16_back_to_back_wrong_reg1_address, $fixed_timing_storage_error],
        ['fixed composition protection back-to-back wrong selected register address', $fixed_protection_back_to_back_wrong_reg1_address, $fixed_timing_storage_error],
        ['fixed composition protection back-to-back wrong policy', $fixed_protection_back_to_back_wrong_policy, $fixed_timing_storage_error],
        ['fixed composition data16 protection back-to-back wrong selected register address', $fixed_data16_protection_back_to_back_wrong_reg1_address, $fixed_timing_storage_error],
        ['fixed composition data16 protection back-to-back wrong policy', $fixed_data16_protection_back_to_back_wrong_policy, $fixed_timing_storage_error],
        ['multi-peripheral composition missing peripheral timing policy', $multi_missing_control_timing, qr/requires requester back-to-back queued queue-depth 1 overflow reject and every peripheral completer setup-admission adjacent/],
        ['multi-peripheral protection back-to-back wrong status register address', $multi_protection_back_to_back_wrong_status_reg1_address, $multi_timing_storage_error],
        ['multi-peripheral protection back-to-back wrong control policy', $multi_protection_back_to_back_wrong_control_policy, $multi_timing_storage_error],
        ['multi-peripheral no-policy multi-register back-to-back wrong status register address', $multi_no_policy_back_to_back_wrong_status_reg1_address, $multi_timing_storage_error],
        ['multi-peripheral no-policy multi-register back-to-back unexpected status access policy', $multi_no_policy_back_to_back_with_status_access_policy, $multi_timing_storage_error],
        ['multi-peripheral generalized no-policy multi-register back-to-back wrong status register address', $multi_generalized_no_policy_back_to_back_wrong_status_reg2_address, $multi_timing_storage_error],
        ['multi-peripheral generalized no-policy multi-register back-to-back unexpected status access policy', $multi_generalized_no_policy_back_to_back_with_status_access_policy, $multi_timing_storage_error],
        ['multi-peripheral protection multi-register back-to-back wrong status register address', $multi_protection_mreg_back_to_back_wrong_status_reg1_address, $multi_timing_storage_error],
        ['multi-peripheral protection multi-register back-to-back wrong control policy', $multi_protection_mreg_back_to_back_wrong_control_policy, $multi_timing_storage_error],
        ['multi-peripheral generalized protection multi-register back-to-back wrong status register address', $multi_protection_generalized_back_to_back_wrong_status_reg2_address, $multi_timing_storage_error],
        ['multi-peripheral generalized protection multi-register back-to-back wrong status policy', $multi_protection_generalized_back_to_back_wrong_status_reg2_policy, $multi_timing_storage_error],
        ['multi-peripheral generalized protection multi-register back-to-back mismatched register count', $multi_protection_generalized_back_to_back_mismatched_register_count, $multi_timing_storage_error],
        ['multi-peripheral data16 no-policy multi-register back-to-back wrong status register address', $multi_data16_no_policy_back_to_back_wrong_status_reg1_address, $multi_data16_timing_storage_error],
        ['multi-peripheral data16 no-policy multi-register back-to-back unexpected status access policy', $multi_data16_no_policy_back_to_back_with_status_access_policy, $multi_data16_timing_storage_error],
        ['multi-peripheral data16 generalized no-policy multi-register back-to-back wrong status register address', $multi_data16_generalized_no_policy_back_to_back_wrong_status_reg2_address, $multi_data16_timing_storage_error],
        ['multi-peripheral data16 generalized no-policy multi-register back-to-back unexpected status access policy', $multi_data16_generalized_no_policy_back_to_back_with_status_access_policy, $multi_data16_timing_storage_error],
        ['multi-peripheral data16 generalized no-policy multi-register back-to-back mismatched register count', $multi_data16_generalized_no_policy_back_to_back_mismatched_register_count, $multi_data16_timing_storage_error],
        ['multi-peripheral data16 protection multi-register back-to-back wrong status register address', $multi_data16_protection_mreg_back_to_back_wrong_status_reg1_address, $multi_data16_timing_storage_error],
        ['multi-peripheral data16 protection multi-register back-to-back wrong control policy', $multi_data16_protection_mreg_back_to_back_wrong_control_policy, $multi_data16_timing_storage_error],
        ['multi-peripheral data16 protection back-to-back wrong status register address', $multi_data16_protection_back_to_back_wrong_status_reg1_address, $multi_data16_timing_storage_error],
        ['multi-peripheral data16 protection back-to-back wrong control policy', $multi_data16_protection_back_to_back_wrong_control_policy, $multi_data16_timing_storage_error],
    );

    for my $case (@cases) {
        my ($label, $source, $pattern) = @$case;
        my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($source, "$label.ppif"); 1 };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI check and semantic JSON support-account multi-register APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_register_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'multi-register APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'multi-register APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'multi-register APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'multi-register APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register', 'multi-register APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'multi-register APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'multi-register APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'multi-register APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'multi-register APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register', 'multi-register APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'multi-register APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'multi-register APB composition semantic JSON records the generated top module');
};

subtest 'CLI check and semantic JSON support-account sideband multi-register APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_register_sideband_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband multi-register APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband multi-register APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband multi-register APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband multi-register APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband', 'sideband multi-register APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband multi-register APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband multi-register APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband multi-register APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband multi-register APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband', 'sideband multi-register APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband multi-register APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband multi-register APB composition semantic JSON records the generated top module');
};

subtest 'CLI check and semantic JSON support-account sideband protection multi-register APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_register_sideband_protection_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband protection multi-register APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband protection multi-register APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband protection multi-register APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband protection multi-register APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_protection', 'sideband protection multi-register APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband protection multi-register APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband protection multi-register APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband protection multi-register APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband protection multi-register APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_protection', 'sideband protection multi-register APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband protection multi-register APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband protection multi-register APB composition semantic JSON records the generated top module');
};

subtest 'CLI check and semantic JSON support-account sideband protection multi-register status back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband protection multi-register status back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband protection multi-register status back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband protection multi-register status back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband protection multi-register status back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_protection_status_back_to_back', 'sideband protection multi-register status back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband protection multi-register status back-to-back APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband protection multi-register status back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband protection multi-register status back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband protection multi-register status back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_protection_status_back_to_back', 'sideband protection multi-register status back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband protection multi-register status back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband protection multi-register status back-to-back APB composition semantic JSON records the generated top module');
};

subtest 'CLI check and semantic JSON support-account sideband multi-register data16 APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_register_sideband_data16_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband multi-register data16 APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband multi-register data16 APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband multi-register data16 APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband multi-register data16 APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_data16', 'sideband multi-register data16 APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband multi-register data16 APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband multi-register data16 APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband multi-register data16 APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband multi-register data16 APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_data16', 'sideband multi-register data16 APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband multi-register data16 APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband multi-register data16 APB composition semantic JSON records the generated top module');
};

subtest 'CLI check and semantic JSON support-account sideband multi-register data16 status back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_register_sideband_data16_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband multi-register data16 status back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband multi-register data16 status back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband multi-register data16 status back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband multi-register data16 status back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_data16_status_back_to_back', 'sideband multi-register data16 status back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband multi-register data16 status back-to-back APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband multi-register data16 status back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband multi-register data16 status back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband multi-register data16 status back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_data16_status_back_to_back', 'sideband multi-register data16 status back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband multi-register data16 status back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband multi-register data16 status back-to-back APB composition semantic JSON records the generated top module');
};

subtest 'CLI check and semantic JSON support-account sideband protection multi-register data16 APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_register_sideband_data16_protection_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband protection multi-register data16 APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband protection multi-register data16 APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband protection multi-register data16 APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband protection multi-register data16 APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_data16_protection', 'sideband protection multi-register data16 APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband protection multi-register data16 APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband protection multi-register data16 APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband protection multi-register data16 APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband protection multi-register data16 APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_data16_protection', 'sideband protection multi-register data16 APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband protection multi-register data16 APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband protection multi-register data16 APB composition semantic JSON records the generated top module');
};

subtest 'CLI check and semantic JSON support-account sideband protection multi-register data16 status back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband protection multi-register data16 status back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband protection multi-register data16 status back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband protection multi-register data16 status back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband protection multi-register data16 status back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_data16_protection_status_back_to_back', 'sideband protection multi-register data16 status back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband protection multi-register data16 status back-to-back APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband protection multi-register data16 status back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband protection multi-register data16 status back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband protection multi-register data16 status back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_register_sideband_data16_protection_status_back_to_back', 'sideband protection multi-register data16 status back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband protection multi-register data16 status back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband protection multi-register data16 status back-to-back APB composition semantic JSON records the generated top module');
};

subtest 'CLI check and semantic JSON support-account multi-peripheral APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'multi-peripheral APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'multi-peripheral APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'multi-peripheral APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'multi-peripheral APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral', 'multi-peripheral APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'multi-peripheral APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'multi-peripheral APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'multi-peripheral APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'multi-peripheral APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'multi-peripheral APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral', 'multi-peripheral APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'multi-peripheral APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'multi-peripheral APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'multi-peripheral APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account multi-peripheral status back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'multi-peripheral status back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'multi-peripheral status back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'multi-peripheral status back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'multi-peripheral status back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_status_back_to_back', 'multi-peripheral status back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'multi-peripheral status back-to-back APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'multi-peripheral status back-to-back APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'multi-peripheral status back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'multi-peripheral status back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'multi-peripheral status back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_status_back_to_back', 'multi-peripheral status back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'multi-peripheral status back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'multi-peripheral status back-to-back APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'multi-peripheral status back-to-back APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account sideband multi-peripheral APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband multi-peripheral APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband multi-peripheral APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband multi-peripheral APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband multi-peripheral APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband', 'sideband multi-peripheral APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband multi-peripheral APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'sideband multi-peripheral APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband multi-peripheral APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband multi-peripheral APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband multi-peripheral APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband', 'sideband multi-peripheral APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband multi-peripheral APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband multi-peripheral APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'sideband multi-peripheral APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account sideband no-policy multi-peripheral multi-register back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband no-policy multi-peripheral multi-register back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account sideband protection multi-peripheral multi-register back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband protection multi-peripheral multi-register back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband protection multi-peripheral multi-register back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband protection multi-peripheral multi-register back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband protection multi-peripheral multi-register back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back', 'sideband protection multi-peripheral multi-register back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband protection multi-peripheral multi-register back-to-back APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'sideband protection multi-peripheral multi-register back-to-back APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband protection multi-peripheral multi-register back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband protection multi-peripheral multi-register back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband protection multi-peripheral multi-register back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back', 'sideband protection multi-peripheral multi-register back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband protection multi-peripheral multi-register back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband protection multi-peripheral multi-register back-to-back APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'sideband protection multi-peripheral multi-register back-to-back APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account generalized sideband protection multi-peripheral multi-register back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account sideband data16 protection multi-peripheral multi-register back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account sideband protection multi-peripheral APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_protection_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband protection multi-peripheral APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband protection multi-peripheral APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband protection multi-peripheral APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband protection multi-peripheral APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband_protection', 'sideband protection multi-peripheral APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband protection multi-peripheral APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'sideband protection multi-peripheral APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband protection multi-peripheral APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband protection multi-peripheral APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband protection multi-peripheral APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband_protection', 'sideband protection multi-peripheral APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband protection multi-peripheral APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband protection multi-peripheral APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'sideband protection multi-peripheral APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account sideband protection multi-peripheral back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband protection multi-peripheral back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband protection multi-peripheral back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband protection multi-peripheral back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband protection multi-peripheral back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband_protection_status_back_to_back', 'sideband protection multi-peripheral back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband protection multi-peripheral back-to-back APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'sideband protection multi-peripheral back-to-back APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband protection multi-peripheral back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband protection multi-peripheral back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband protection multi-peripheral back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband_protection_status_back_to_back', 'sideband protection multi-peripheral back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband protection multi-peripheral back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband protection multi-peripheral back-to-back APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'sideband protection multi-peripheral back-to-back APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account sideband multi-peripheral data16 APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_data16_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband multi-peripheral data16 APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband multi-peripheral data16 APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband multi-peripheral data16 APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband multi-peripheral data16 APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband_data16', 'sideband multi-peripheral data16 APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband multi-peripheral data16 APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'sideband multi-peripheral data16 APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband multi-peripheral data16 APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband multi-peripheral data16 APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband multi-peripheral data16 APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband_data16', 'sideband multi-peripheral data16 APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband multi-peripheral data16 APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband multi-peripheral data16 APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'sideband multi-peripheral data16 APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account sideband protection multi-peripheral data16 APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_data16_protection_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband protection multi-peripheral data16 APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband protection multi-peripheral data16 APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband protection multi-peripheral data16 APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband protection multi-peripheral data16 APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband_data16_protection', 'sideband protection multi-peripheral data16 APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband protection multi-peripheral data16 APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'sideband protection multi-peripheral data16 APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband protection multi-peripheral data16 APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband protection multi-peripheral data16 APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband protection multi-peripheral data16 APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband_data16_protection', 'sideband protection multi-peripheral data16 APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband protection multi-peripheral data16 APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband protection multi-peripheral data16 APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'sideband protection multi-peripheral data16 APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account sideband protection multi-peripheral data16 back-to-back APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'sideband protection multi-peripheral data16 back-to-back APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'sideband protection multi-peripheral data16 back-to-back APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'sideband protection multi-peripheral data16 back-to-back APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'sideband protection multi-peripheral data16 back-to-back APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back', 'sideband protection multi-peripheral data16 back-to-back APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'sideband protection multi-peripheral data16 back-to-back APB composition check JSON records PPIF source kind');
    is($check_report->{result}{composition_child_count}, 4, 'sideband protection multi-peripheral data16 back-to-back APB composition check JSON reports four generated children');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'sideband protection multi-peripheral data16 back-to-back APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'sideband protection multi-peripheral data16 back-to-back APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'sideband protection multi-peripheral data16 back-to-back APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back', 'sideband protection multi-peripheral data16 back-to-back APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'sideband protection multi-peripheral data16 back-to-back APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'sideband protection multi-peripheral data16 back-to-back APB composition semantic JSON records the generated top module');
    is($semantic_report->{semantic}{module}{composition_child_count}, 4, 'sideband protection multi-peripheral data16 back-to-back APB composition semantic JSON records four generated children');
};

subtest 'CLI check and semantic JSON support-account APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition', 'APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition', 'APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'APB composition semantic JSON records the generated top module');
};

subtest 'CLI check and semantic JSON support-account busy APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_busy_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'busy APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'busy APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'busy APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'busy APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_busy', 'busy APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'busy APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'busy APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'busy APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'busy APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_busy', 'busy APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'busy APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'busy APB composition semantic JSON records the generated top module');
};

subtest 'CLI check and semantic JSON support-account status APB composition PPIF identity' => sub {
    my $path = sample_apb_composition_status_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'status APB composition --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'status APB composition --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'status APB composition check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'status APB composition check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_status', 'status APB composition check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'status APB composition check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'status APB composition --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'status APB composition --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'status APB composition semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_composition_status', 'status APB composition semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'status APB composition semantic JSON payload describes the generated composition root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'status APB composition semantic JSON records the generated top module');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose multi-register APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_register_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'multi-register APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'multi-register APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'multi-register APB composition schedule JSON reports schema');
    is($schedule_report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_tb.fsm', 'multi-register APB composition schedule JSON reports the HDL entry');
    is_deeply($schedule_report->{children}[1]{transfer}{registers}, [qw(reg0 reg1)], 'multi-register APB composition schedule JSON reports completer register list');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_multi_register_decode_deferred}, 'multi-register APB composition schedule JSON omits multi-register deferred residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'multi-register APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'multi-register APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "multi-register APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'multi-register APB composition --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\bmodule\s+apb_tb\b/, 'multi-register APB composition HDL contains the generated top module');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+status\b/, 'multi-register APB composition HDL exposes requester status');
    like($sv, qr/\breg \[31:0\] reg1_data_q\b/, 'multi-register APB composition HDL carries second completer register');
    like($sv, qr/PRDATA_next = reg1_data_q;/, 'multi-register APB composition HDL can mux PRDATA from second storage register');

    ok(-f sample_apb_composition_multi_register_apb_path(), 'tracked runnable multi-register APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'multi-register .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'multi-register .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'multi-register .apb APB composition alias mirrors .ppif generated IAL0');
    is_deeply($alias->{report}{children}[1]{transfer}{registers}, [qw(reg0 reg1)], 'multi-register .apb APB composition alias preserves completer register list');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband multi-register APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_register_sideband_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband multi-register APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband multi-register APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband multi-register APB composition schedule JSON reports schema');
    is($schedule_report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_tb.fsm', 'sideband multi-register APB composition schedule JSON reports the HDL entry');
    is_deeply($schedule_report->{children}[1]{transfer}{registers}, [qw(reg0 reg1)], 'sideband multi-register APB composition schedule JSON reports completer register list');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_protection_and_strobes_deferred}, 'sideband multi-register APB composition schedule JSON omits broad sideband residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'sideband multi-register APB composition schedule JSON reports protection-policy residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_sideband.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband multi-register APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband multi-register APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband multi-register APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband multi-register APB composition --output writes generated HDL');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/\(requester\.PPROT completer\.PPROT\)/, 'sideband multi-register outdir top wires PPROT');
    like($top, qr/\(requester\.PSTRB completer\.PSTRB\)/, 'sideband multi-register outdir top wires PSTRB');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+\[2:0\]\s+req_prot\b/, 'sideband multi-register APB composition HDL exposes requester protection input');
    like($sv, qr/\binput\s+\[3:0\]\s+req_wstrb\b/, 'sideband multi-register APB composition HDL exposes requester write-strobe input');
    like($sv, qr/\bwire\s+\[3:0\]\s+comp_link_requester_PSTRB\b/, 'sideband multi-register APB composition HDL declares the PSTRB composition link');

    ok(-f sample_apb_composition_multi_register_sideband_apb_path(), 'tracked runnable sideband multi-register APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband multi-register .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband multi-register .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband multi-register .apb APB composition alias mirrors .ppif generated IAL0');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband protection multi-register APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_register_sideband_protection_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband protection multi-register APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband protection multi-register APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register APB composition schedule JSON reports completer enforcement owner');
    is($schedule_report->{children}[1]{protection_policy}{registers}[1]{write}{predicate}{value}, 1, 'sideband protection multi-register APB composition schedule JSON reports reg1 write predicate');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-register APB composition schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-register APB composition schedule JSON reports additional-policy residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_sideband_protection.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband protection multi-register APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband protection multi-register APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband protection multi-register APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband protection multi-register APB composition --output writes generated HDL');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/\(requester\.PPROT completer\.PPROT\)/, 'sideband protection multi-register outdir top wires PPROT');
    like($top, qr/\(\?\(& write_q \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-register outdir top embeds denied reg1 write branch');
    my $sv = slurp($hdl);
    like($sv, qr/prot_q\s*&\s*3'd1/, 'sideband protection multi-register APB composition HDL preserves PPROT predicate logic');
    like($sv, qr/PSLVERR_next = 1;/, 'sideband protection multi-register APB composition HDL preserves denied-access error drive');

    ok(-f sample_apb_composition_multi_register_sideband_protection_apb_path(), 'tracked runnable sideband protection multi-register APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_protection_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_protection_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-register .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband protection multi-register .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband protection multi-register .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register .apb APB composition alias preserves policy owner');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband protection multi-register status back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband protection multi-register status back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband protection multi-register status back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband protection multi-register status back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{requester_accepted_field}{name}, 'accepted', 'sideband protection multi-register status back-to-back APB composition schedule JSON reports accepted metadata');
    is($schedule_report->{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy', 'sideband protection multi-register status back-to-back APB composition schedule JSON reports aggregate policy');
    is($schedule_report->{children}[1]{transfer}{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-register status back-to-back APB composition schedule JSON reports completer adjacent setup admission');
    is($schedule_report->{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register status back-to-back APB composition schedule JSON reports completer enforcement owner');
    is($schedule_report->{children}[1]{protection_policy}{registers}[1]{write}{predicate}{value}, 1, 'sideband protection multi-register status back-to-back APB composition schedule JSON reports reg1 write predicate');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband protection multi-register status back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok(!$residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-register status back-to-back APB composition schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband protection multi-register status back-to-back APB composition schedule JSON reports narrowed timing residue');
    ok($residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-register status back-to-back APB composition schedule JSON reports additional-policy residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_sideband_protection_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband protection multi-register status back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband protection multi-register status back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband protection multi-register status back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband protection multi-register status back-to-back APB composition --output writes generated HDL');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'sideband protection multi-register status back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_prot 3\)/, 'sideband protection multi-register status back-to-back outdir top embeds queued PPROT state');
    like($top, qr/\(requester\.PPROT completer\.PPROT\)/, 'sideband protection multi-register status back-to-back outdir top wires PPROT');
    like($top, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband protection multi-register status back-to-back outdir top embeds adjacent completer setup detector');
    like($top, qr/\(\?\(& write_q \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-register status back-to-back outdir top embeds denied reg1 write branch');
    like($top, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'sideband protection multi-register status back-to-back outdir top embeds high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\boutput\s+accepted\b/, 'sideband protection multi-register status back-to-back APB composition HDL exposes accepted');
    like($sv, qr/\breg\s+\[2:0\]\s+queued_prot\b/, 'sideband protection multi-register status back-to-back APB composition HDL keeps queued PPROT state');
    like($sv, qr/prot_q\s*&\s*3'd1/, 'sideband protection multi-register status back-to-back APB composition HDL preserves PPROT predicate logic');
    like($sv, qr/PSLVERR_next = 1;/, 'sideband protection multi-register status back-to-back APB composition HDL preserves denied-access error drive');

    ok(-f sample_apb_composition_multi_register_sideband_protection_status_back_to_back_apb_path(), 'tracked runnable sideband protection multi-register status back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_protection_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-register status back-to-back .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband protection multi-register status back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband protection multi-register status back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-register status back-to-back .apb APB composition alias preserves completer timing policy');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register status back-to-back .apb APB composition alias preserves policy owner');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband multi-register data16 APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_register_sideband_data16_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband multi-register data16 APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband multi-register data16 APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband multi-register data16 APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{width_policy}{data_width}, 16, 'sideband multi-register data16 APB composition schedule JSON reports data width 16');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 2, 'sideband multi-register data16 APB composition schedule JSON reports strobe width 2');
    is_deeply($schedule_report->{children}[1]{transfer}{registers}, [qw(reg0 reg1)], 'sideband multi-register data16 APB composition schedule JSON reports completer register list');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_alternate_widths_deferred}, 'sideband multi-register data16 APB composition schedule JSON omits broad alternate-width residue');
    ok($residue{apb_remaining_widths_deferred}, 'sideband multi-register data16 APB composition schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_sideband_data16.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband multi-register data16 APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband multi-register data16 APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband multi-register data16 APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband multi-register data16 APB composition --output writes generated HDL');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/\(<- \(PSTRB> \(& wstrb \(concat is_write is_write\)\)\) <setup_phase_start\)/, 'sideband multi-register data16 outdir top drives 2-bit PSTRB');
    like($top, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband multi-register data16 outdir top embeds high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+\[15:0\]\s+req_wdata\b/, 'sideband multi-register data16 APB composition HDL exposes 16-bit requester write-data input');
    like($sv, qr/\binput\s+\[1:0\]\s+req_wstrb\b/, 'sideband multi-register data16 APB composition HDL exposes 2-bit requester write-strobe input');
    like($sv, qr/\bwire\s+\[1:0\]\s+comp_link_requester_PSTRB\b/, 'sideband multi-register data16 APB composition HDL declares the 2-bit PSTRB composition link');

    ok(-f sample_apb_composition_multi_register_sideband_data16_apb_path(), 'tracked runnable sideband multi-register data16 APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband multi-register data16 .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband multi-register data16 .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband multi-register data16 .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 16, 'sideband multi-register data16 .apb APB composition alias preserves width policy');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband multi-register data16 status back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_register_sideband_data16_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband multi-register data16 status back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband multi-register data16 status back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband multi-register data16 status back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{width_policy}{data_width}, 16, 'sideband multi-register data16 status back-to-back APB composition schedule JSON reports data width 16');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 2, 'sideband multi-register data16 status back-to-back APB composition schedule JSON reports strobe width 2');
    is($schedule_report->{requester_accepted_field}{name}, 'accepted', 'sideband multi-register data16 status back-to-back APB composition schedule JSON reports accepted metadata');
    is($schedule_report->{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy', 'sideband multi-register data16 status back-to-back APB composition schedule JSON reports aggregate policy');
    is($schedule_report->{children}[1]{transfer}{timing_policy}{setup_admission}, 'adjacent', 'sideband multi-register data16 status back-to-back APB composition schedule JSON reports completer adjacent setup admission');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband multi-register data16 status back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband multi-register data16 status back-to-back APB composition schedule JSON reports narrowed back-to-back residue');
    ok($residue{apb_remaining_widths_deferred}, 'sideband multi-register data16 status back-to-back APB composition schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_sideband_data16_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband multi-register data16 status back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband multi-register data16 status back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband multi-register data16 status back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband multi-register data16 status back-to-back APB composition --output writes generated HDL');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'sideband multi-register data16 status back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_wdata 16\)/, 'sideband multi-register data16 status back-to-back outdir top embeds queued 16-bit requester data');
    like($top, qr/\(<- \(PSTRB> \(& queued_wstrb \(concat queued_write queued_write\)\)\)/, 'sideband multi-register data16 status back-to-back outdir top drives queued 2-bit PSTRB');
    like($top, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband multi-register data16 status back-to-back outdir top embeds adjacent completer setup detector');
    like($top, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband multi-register data16 status back-to-back outdir top embeds high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\boutput\s+accepted\b/, 'sideband multi-register data16 status back-to-back APB composition HDL exposes accepted');
    like($sv, qr/\binput\s+(?:wire\s+)?\[15:0\]\s+req_wdata\b/, 'sideband multi-register data16 status back-to-back APB composition HDL exposes 16-bit requester write-data input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+req_wstrb\b/, 'sideband multi-register data16 status back-to-back APB composition HDL exposes 2-bit requester write-strobe input');
    like($sv, qr/\breg\s+\[15:0\]\s+queued_wdata\b/, 'sideband multi-register data16 status back-to-back APB composition HDL keeps 16-bit queued data state');

    ok(-f sample_apb_composition_multi_register_sideband_data16_status_back_to_back_apb_path(), 'tracked runnable sideband multi-register data16 status back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband multi-register data16 status back-to-back .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband multi-register data16 status back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband multi-register data16 status back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 16, 'sideband multi-register data16 status back-to-back .apb APB composition alias preserves width policy');
    is($alias->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'sideband multi-register data16 status back-to-back .apb APB composition alias preserves completer timing policy');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband protection multi-register data16 APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_register_sideband_data16_protection_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband protection multi-register data16 APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband protection multi-register data16 APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband protection multi-register data16 APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{width_policy}{data_width}, 16, 'sideband protection multi-register data16 APB composition schedule JSON reports data width 16');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 2, 'sideband protection multi-register data16 APB composition schedule JSON reports strobe width 2');
    is($schedule_report->{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register data16 APB composition schedule JSON reports completer enforcement owner');
    is($schedule_report->{children}[1]{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'sideband protection multi-register data16 APB composition schedule JSON reports reg1 read predicate');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-register data16 APB composition schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-register data16 APB composition schedule JSON reports additional-policy residue');
    ok($residue{apb_remaining_widths_deferred}, 'sideband protection multi-register data16 APB composition schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_sideband_data16_protection.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband protection multi-register data16 APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband protection multi-register data16 APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband protection multi-register data16 APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband protection multi-register data16 APB composition --output writes generated HDL');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/\(requester\.PPROT completer\.PPROT\)/, 'sideband protection multi-register data16 outdir top wires PPROT');
    like($top, qr/\(requester\.PSTRB completer\.PSTRB\)/, 'sideband protection multi-register data16 outdir top wires PSTRB');
    like($top, qr/\(PSTRB 2\)/, 'sideband protection multi-register data16 outdir top preserves 2-bit PSTRB');
    like($top, qr/\(\?\(& write_q \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-register data16 outdir top embeds denied reg1 write branch');
    like($top, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband protection multi-register data16 outdir top embeds high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[15:0\]\s+req_wdata\b/, 'sideband protection multi-register data16 APB composition HDL exposes 16-bit requester write-data input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+req_wstrb\b/, 'sideband protection multi-register data16 APB composition HDL exposes 2-bit requester write-strobe input');
    like($sv, qr/\bwire\s+\[1:0\]\s+comp_link_requester_PSTRB\b/, 'sideband protection multi-register data16 APB composition HDL declares the 2-bit PSTRB composition link');
    like($sv, qr/prot_q\s*&\s*3'd1/, 'sideband protection multi-register data16 APB composition HDL preserves PPROT predicate logic');
    like($sv, qr/PSLVERR_next = 1;/, 'sideband protection multi-register data16 APB composition HDL preserves denied-access error drive');

    ok(-f sample_apb_composition_multi_register_sideband_data16_protection_apb_path(), 'tracked runnable sideband protection multi-register data16 APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_protection_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_protection_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-register data16 .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband protection multi-register data16 .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband protection multi-register data16 .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 16, 'sideband protection multi-register data16 .apb APB composition alias preserves width policy');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register data16 .apb APB composition alias preserves policy owner');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband protection multi-register data16 status back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband protection multi-register data16 status back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband protection multi-register data16 status back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{width_policy}{data_width}, 16, 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON reports data width 16');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 2, 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON reports strobe width 2');
    is($schedule_report->{requester_accepted_field}{name}, 'accepted', 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON reports accepted metadata');
    is($schedule_report->{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy', 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON reports aggregate policy');
    is($schedule_report->{children}[1]{transfer}{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON reports completer adjacent setup admission');
    is($schedule_report->{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON reports completer enforcement owner');
    is($schedule_report->{children}[1]{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON reports reg1 read predicate');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok(!$residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON reports narrowed timing residue');
    ok($residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON reports additional-policy residue');
    ok($residue{apb_remaining_widths_deferred}, 'sideband protection multi-register data16 status back-to-back APB composition schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_sideband_data16_protection_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband protection multi-register data16 status back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband protection multi-register data16 status back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband protection multi-register data16 status back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband protection multi-register data16 status back-to-back APB composition --output writes generated HDL');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'sideband protection multi-register data16 status back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_wdata 16\)/, 'sideband protection multi-register data16 status back-to-back outdir top embeds queued 16-bit requester data');
    like($top, qr/\(queued_prot 3\)/, 'sideband protection multi-register data16 status back-to-back outdir top embeds queued PPROT');
    like($top, qr/\(<- \(PSTRB> \(& queued_wstrb \(concat queued_write queued_write\)\)\)/, 'sideband protection multi-register data16 status back-to-back outdir top drives queued 2-bit PSTRB');
    like($top, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband protection multi-register data16 status back-to-back outdir top embeds adjacent completer setup detector');
    like($top, qr/\(\?\(& write_q \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-register data16 status back-to-back outdir top embeds denied reg1 write branch');
    like($top, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband protection multi-register data16 status back-to-back outdir top embeds high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\boutput\s+accepted\b/, 'sideband protection multi-register data16 status back-to-back APB composition HDL exposes accepted');
    like($sv, qr/\binput\s+(?:wire\s+)?\[15:0\]\s+req_wdata\b/, 'sideband protection multi-register data16 status back-to-back APB composition HDL exposes 16-bit requester write-data input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+req_wstrb\b/, 'sideband protection multi-register data16 status back-to-back APB composition HDL exposes 2-bit requester write-strobe input');
    like($sv, qr/\breg\s+\[15:0\]\s+queued_wdata\b/, 'sideband protection multi-register data16 status back-to-back APB composition HDL keeps 16-bit queued data state');
    like($sv, qr/prot_q\s*&\s*3'd1/, 'sideband protection multi-register data16 status back-to-back APB composition HDL preserves PPROT predicate logic');
    like($sv, qr/PSLVERR_next = 1;/, 'sideband protection multi-register data16 status back-to-back APB composition HDL preserves denied-access error drive');

    ok(-f sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_apb_path(), 'tracked runnable sideband protection multi-register data16 status back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-register data16 status back-to-back .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband protection multi-register data16 status back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband protection multi-register data16 status back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 16, 'sideband protection multi-register data16 status back-to-back .apb APB composition alias preserves width policy');
    is($alias->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-register data16 status back-to-back .apb APB composition alias preserves completer timing policy');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'completer', 'sideband protection multi-register data16 status back-to-back .apb APB composition alias preserves policy owner');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose multi-peripheral APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'multi-peripheral APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'multi-peripheral APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'multi-peripheral APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'multi-peripheral APB composition schedule JSON reports topology');
    is($schedule_report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_tb.fsm', 'multi-peripheral APB composition schedule JSON reports the HDL entry');
    is($schedule_report->{composition}{peripherals}[0]{generated_instance_name}, 'status_peripheral', 'multi-peripheral APB composition schedule JSON reports generated status instance alias');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_interconnect_multi_peripheral_decode_deferred}, 'multi-peripheral APB composition schedule JSON omits interconnect/decode deferred residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'multi-peripheral APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'multi-peripheral APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "multi-peripheral APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'multi-peripheral APB composition --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\bmodule\s+apb_tb\b/, 'multi-peripheral APB composition HDL contains the generated top module');
    like($sv, qr/\bmodule\s+apb_interconnect\b/, 'multi-peripheral APB composition HDL contains the generated interconnect module');
    like($sv, qr/\bapb_interconnect\s+interconnect\s+\(/, 'multi-peripheral APB composition top instantiates generated interconnect');
    like($sv, qr/\bapb_status_regs\s+status_peripheral\s+\(/, 'multi-peripheral APB composition top instantiates status peripheral with generated alias');
    like($sv, qr/PSLVERR_next = 1;/, 'multi-peripheral APB composition HDL includes unmapped-error PSLVERR drive');
    like($sv, qr/PADDR_CONTROL_next = PADDR - 256;/, 'multi-peripheral APB composition HDL includes control-window local address translation');

    ok(-f sample_apb_composition_multi_peripheral_apb_path(), 'tracked runnable multi-peripheral APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'multi-peripheral .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'multi-peripheral .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'multi-peripheral .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'multi-peripheral .apb APB composition alias preserves topology');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose multi-peripheral status back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'multi-peripheral status back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'multi-peripheral status back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'multi-peripheral status back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'multi-peripheral status back-to-back APB composition schedule JSON reports topology');
    is($schedule_report->{requester_accepted_field}{name}, 'accepted', 'multi-peripheral status back-to-back APB composition schedule JSON reports accepted metadata');
    is($schedule_report->{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy_through_interconnect', 'multi-peripheral status back-to-back APB composition schedule JSON reports aggregate policy');
    is($schedule_report->{children}[1]{back_to_back_policy}{interconnect_role}, 'propagate_queued_setup_without_idle_cycle', 'multi-peripheral status back-to-back APB composition schedule JSON reports interconnect timing role');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'multi-peripheral status back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'multi-peripheral status back-to-back APB composition schedule JSON reports narrowed back-to-back residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'multi-peripheral status back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'multi-peripheral status back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "multi-peripheral status back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'multi-peripheral status back-to-back APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(<- \(PENABLE_STATUS> PENABLE\)\)/, 'multi-peripheral status back-to-back outdir interconnect forwards PENABLE to status');
    like($interconnect, qr/\(<- \(PENABLE_CONTROL> PENABLE\)\)/, 'multi-peripheral status back-to-back outdir interconnect forwards PENABLE to control');
    like($interconnect, qr/\(<- \(PSEL_STATUS> PSEL\) <\(& PSEL \(>= PADDR 0\) \(< PADDR 256\)\)\)/, 'multi-peripheral status back-to-back outdir interconnect decodes status setup from current address');
    like($interconnect, qr/\(<- \(PSEL_CONTROL> PSEL\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'multi-peripheral status back-to-back outdir interconnect decodes control setup from current address');
    like($interconnect, qr/\(<- \(PREADY> 1\) <\(& PSEL PENABLE \(! \(\| /, 'multi-peripheral status back-to-back outdir interconnect keeps unmapped response active-access only');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'multi-peripheral status back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_valid 1\)/, 'multi-peripheral status back-to-back outdir top embeds queued requester state');
    my $sv = slurp($hdl);
    like($sv, qr/\boutput\s+accepted\b/, 'multi-peripheral status back-to-back HDL top exposes accepted');
    like($sv, qr/\breg\s+queued_valid\b/, 'multi-peripheral status back-to-back HDL keeps requester queue state');
    like($sv, qr/PSEL_STATUS_next = PSEL;/, 'multi-peripheral status back-to-back HDL keeps decoded status select propagation');
    like($sv, qr/PSEL_CONTROL_next = PSEL;/, 'multi-peripheral status back-to-back HDL keeps decoded control select propagation');

    ok(-f sample_apb_composition_multi_peripheral_status_back_to_back_apb_path(), 'tracked runnable multi-peripheral status back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'multi-peripheral status back-to-back .apb APB composition alias returns the composition kind');
    is($alias->{mode}, 'requester-multi-peripheral-composition', 'multi-peripheral status back-to-back .apb APB composition alias preserves mode');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'multi-peripheral status back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'multi-peripheral status back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'multi-peripheral status back-to-back .apb APB composition alias preserves interconnect timing role');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband multi-peripheral status back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband multi-peripheral status back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband multi-peripheral status back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband multi-peripheral status back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'sideband multi-peripheral status back-to-back APB composition schedule JSON reports topology');
    is($schedule_report->{requester_accepted_field}{name}, 'accepted', 'sideband multi-peripheral status back-to-back APB composition schedule JSON reports accepted metadata');
    is($schedule_report->{back_to_back_policy}{composition_role}, 'propagate_endpoint_policy_through_interconnect', 'sideband multi-peripheral status back-to-back APB composition schedule JSON reports aggregate policy');
    is($schedule_report->{children}[1]{back_to_back_policy}{interconnect_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband multi-peripheral status back-to-back APB composition schedule JSON reports interconnect timing role');
    is($schedule_report->{children}[0]{bindings}{bus}{protection}{width}, 3, 'sideband multi-peripheral status back-to-back APB composition schedule JSON reports requester PPROT width');
    is($schedule_report->{composition}{wiring}{bus}{strobe}{width}, 4, 'sideband multi-peripheral status back-to-back APB composition schedule JSON reports PSTRB width');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband multi-peripheral status back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband multi-peripheral status back-to-back APB composition schedule JSON reports narrowed back-to-back residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'sideband multi-peripheral status back-to-back APB composition keeps protection-policy effects residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_sideband_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband multi-peripheral status back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband multi-peripheral status back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband multi-peripheral status back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband multi-peripheral status back-to-back APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband multi-peripheral status back-to-back outdir interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband multi-peripheral status back-to-back outdir interconnect fans out PSTRB to control');
    like($interconnect, qr/\(<- \(PENABLE_STATUS> PENABLE\)\)/, 'sideband multi-peripheral status back-to-back outdir interconnect forwards PENABLE to status');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'sideband multi-peripheral status back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_prot 3\)/, 'sideband multi-peripheral status back-to-back outdir top embeds queued PPROT state');
    like($top, qr/\(queued_wstrb 4\)/, 'sideband multi-peripheral status back-to-back outdir top embeds queued PSTRB state');
    my $sv = slurp($hdl);
    like($sv, qr/\boutput\s+accepted\b/, 'sideband multi-peripheral status back-to-back HDL top exposes accepted');
    like($sv, qr/\breg\s+\[2:0\]\s+queued_prot\b/, 'sideband multi-peripheral status back-to-back HDL keeps queued PPROT state');
    like($sv, qr/\bwire\s+\[3:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'sideband multi-peripheral status back-to-back HDL declares control PSTRB link');

    ok(-f sample_apb_composition_multi_peripheral_sideband_status_back_to_back_apb_path(), 'tracked runnable sideband multi-peripheral status back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband multi-peripheral status back-to-back .apb APB composition alias returns the composition kind');
    is($alias->{mode}, 'requester-multi-peripheral-composition', 'sideband multi-peripheral status back-to-back .apb APB composition alias preserves mode');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband multi-peripheral status back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband multi-peripheral status back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband multi-peripheral status back-to-back .apb APB composition alias preserves interconnect timing role');
    is($alias->{report}{composition}{wiring}{bus}{protection}{width}, 3, 'sideband multi-peripheral status back-to-back .apb APB composition alias preserves PPROT width');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband no-policy multi-peripheral multi-register back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports topology');
    is($schedule_report->{composition}{width_policy}{data_width}, 32, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports data width 32');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 4, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports strobe width 4');
    is($schedule_report->{composition}{address_map}{windows}[1]{base}{default}, 256, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports control base 256');
    is($schedule_report->{children}[0]{bindings}{bus}{protection}{width}, 3, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports requester PPROT width');
    is_deeply($schedule_report->{children}[2]{transfer}{registers}, [qw(reg0 reg1)], 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports status reg0/reg1 storage');
    is_deeply($schedule_report->{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports control reg0/reg1 storage');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports queue-depth 1');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports accepted response field');
    is($schedule_report->{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports interconnect timing role');
    is($schedule_report->{back_to_back_policy}{peripherals}[0]{timing_policy}{setup_admission}, 'adjacent', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports status adjacent setup admission');
    is($schedule_report->{back_to_back_policy}{peripherals}[1]{timing_policy}{setup_admission}, 'adjacent', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports control adjacent setup admission');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports narrowed future timing-policy residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON keeps protection-policy effects residue');
    ok($residue{apb_alternate_widths_deferred}, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON keeps alternate-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_multi_register_sideband_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband no-policy multi-peripheral multi-register back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband no-policy multi-peripheral multi-register back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(PSTRB_CONTROL 4\)/, 'sideband no-policy multi-peripheral multi-register back-to-back outdir interconnect preserves 4-bit control PSTRB');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back outdir interconnect fans out PPROT');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back outdir interconnect fans out PSTRB');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back outdir interconnect uses control base 256');
    unlike($interconnect, qr/prot_q/, 'sideband no-policy multi-peripheral multi-register back-to-back outdir interconnect remains enforcement-free');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'sideband no-policy multi-peripheral multi-register back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_wstrb 4\)/, 'sideband no-policy multi-peripheral multi-register back-to-back outdir top embeds queued 4-bit PSTRB');
    like($top, qr/\(status_reg1_data_q 32 \(reset 0\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back outdir top embeds status reg1 storage');
    like($top, qr/\(control_reg1_data_q 32 \(reset 0\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back outdir top embeds control reg1 storage');
    like($top, qr/\(<- \(control_reg1_data_q \(\| \(& control_reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'sideband no-policy multi-peripheral multi-register back-to-back outdir top embeds control reg1 high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\bwire\s+\[3:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition HDL declares 4-bit control PSTRB link');
    like($sv, qr/PADDR_CONTROL_next = PADDR - 256;/, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition HDL includes 256-byte local address translation');
    like($sv, qr/\breg\s+\[31:0\]\s+status_reg1_data_q\b/, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition HDL carries 32-bit status reg1 storage');
    like($sv, qr/\breg\s+\[31:0\]\s+control_reg1_data_q\b/, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition HDL carries 32-bit control reg1 storage');
    like($sv, qr/\breg\s+\[3:0\]\s+queued_wstrb\b/, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition HDL carries 4-bit queued PSTRB');
    unlike($sv, qr/prot_q\s*&\s*3'd1/, 'sideband no-policy multi-peripheral multi-register back-to-back APB composition HDL has no endpoint PPROT predicate logic');

    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_apb_path(), 'tracked runnable sideband no-policy multi-peripheral multi-register back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias returns the composition kind');
    is($alias->{mode}, 'requester-multi-peripheral-composition', 'sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves mode');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 32, 'sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves data width policy');
    is_deeply($alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves control reg0/reg1 storage');
    is($alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves interconnect timing policy');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband protection multi-peripheral multi-register back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband protection multi-peripheral multi-register back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband protection multi-peripheral multi-register back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports topology');
    is($schedule_report->{composition}{width_policy}{data_width}, 32, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports data width 32');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 4, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports strobe width 4');
    is($schedule_report->{composition}{address_map}{alignment_bytes}, 4, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports 4-byte window alignment');
    is($schedule_report->{composition}{address_map}{windows}[1]{base}{default}, 256, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports control base 256');
    is($schedule_report->{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports peripheral enforcement owners');
    is($schedule_report->{children}[0]{bindings}{bus}{protection}{width}, 3, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports requester PPROT width');
    is_deeply($schedule_report->{children}[2]{transfer}{registers}, [qw(reg0 reg1)], 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports status reg0/reg1 storage');
    is_deeply($schedule_report->{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports control reg0/reg1 storage');
    is($schedule_report->{children}[2]{bindings}{storage}{registers}[1]{address}{value}, 4, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports status reg1 address 4');
    is($schedule_report->{children}[2]{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports protected status reg1 read policy');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports queue-depth 1');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports accepted response field');
    is($schedule_report->{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports interconnect timing role');
    is($schedule_report->{back_to_back_policy}{peripherals}[0]{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports status adjacent setup admission');
    is($schedule_report->{back_to_back_policy}{peripherals}[1]{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports control adjacent setup admission');
    my %residue_by_id = map { $_->{id} => $_ } @{$schedule_report->{unsupported_residue}};
    my %residue = map { $_ => 1 } keys %residue_by_id;
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok(!$residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports narrowed future timing-policy residue');
    ok($residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports additional-policy residue');
    ok($residue{apb_alternate_widths_deferred}, 'sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON keeps alternate-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_multi_register_sideband_protection_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband protection multi-peripheral multi-register back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband protection multi-peripheral multi-register back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband protection multi-peripheral multi-register back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband protection multi-peripheral multi-register back-to-back APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(PSTRB_CONTROL 4\)/, 'sideband protection multi-peripheral multi-register back-to-back outdir interconnect preserves 4-bit control PSTRB');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband protection multi-peripheral multi-register back-to-back outdir interconnect fans out PPROT');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband protection multi-peripheral multi-register back-to-back outdir interconnect fans out PSTRB');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'sideband protection multi-peripheral multi-register back-to-back outdir interconnect uses control base 256');
    unlike($interconnect, qr/prot_q/, 'sideband protection multi-peripheral multi-register back-to-back outdir interconnect remains enforcement-free');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'sideband protection multi-peripheral multi-register back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_wdata 32\)/, 'sideband protection multi-peripheral multi-register back-to-back outdir top embeds 32-bit queued data');
    like($top, qr/\(queued_wstrb 4\)/, 'sideband protection multi-peripheral multi-register back-to-back outdir top embeds queued 4-bit PSTRB');
    like($top, qr/\(status_reg1_data_q 32 \(reset 0\)\)/, 'sideband protection multi-peripheral multi-register back-to-back outdir top embeds status reg1 storage');
    like($top, qr/\(control_reg1_data_q 32 \(reset 0\)\)/, 'sideband protection multi-peripheral multi-register back-to-back outdir top embeds control reg1 storage');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-peripheral multi-register back-to-back outdir top embeds denied protected reg1 read branch');
    like($top, qr/\(<- \(control_reg1_data_q \(\| \(& control_reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'sideband protection multi-peripheral multi-register back-to-back outdir top embeds control reg1 high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\bwire\s+\[3:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'sideband protection multi-peripheral multi-register back-to-back APB composition HDL declares 4-bit control PSTRB link');
    like($sv, qr/PADDR_CONTROL_next = PADDR - 256;/, 'sideband protection multi-peripheral multi-register back-to-back APB composition HDL includes 256-byte local address translation');
    like($sv, qr/\breg\s+\[31:0\]\s+status_reg1_data_q\b/, 'sideband protection multi-peripheral multi-register back-to-back APB composition HDL carries 32-bit status reg1 storage');
    like($sv, qr/\breg\s+\[31:0\]\s+control_reg1_data_q\b/, 'sideband protection multi-peripheral multi-register back-to-back APB composition HDL carries 32-bit control reg1 storage');
    like($sv, qr/\breg\s+\[3:0\]\s+queued_wstrb\b/, 'sideband protection multi-peripheral multi-register back-to-back APB composition HDL carries 4-bit queued PSTRB');
    like($sv, qr/prot_q\s*&\s*3'd1/, 'sideband protection multi-peripheral multi-register back-to-back APB composition HDL preserves endpoint PPROT predicate logic');

    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_apb_path(), 'tracked runnable sideband protection multi-peripheral multi-register back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias returns the composition kind');
    is($alias->{mode}, 'requester-multi-peripheral-composition', 'sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves mode');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 32, 'sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves data width policy');
    is($alias->{report}{composition}{width_policy}{strobe_width}, 4, 'sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves strobe width policy');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves policy owner');
    is_deeply($alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves control reg0/reg1 storage');
    is($alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves interconnect timing policy');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose generalized sideband protection multi-peripheral multi-register back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports topology');
    is($schedule_report->{composition}{width_policy}{data_width}, 32, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports data width 32');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 4, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports strobe width 4');
    is($schedule_report->{composition}{address_map}{alignment_bytes}, 4, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports 4-byte window alignment');
    is($schedule_report->{composition}{address_map}{windows}[1]{base}{default}, 256, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports control base 256');
    is($schedule_report->{protection_policy}{enforcement_owner}, 'peripheral_completers', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports peripheral enforcement owners');
    is_deeply($schedule_report->{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports status reg0/reg1/reg2 storage');
    is_deeply($schedule_report->{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports control reg0/reg1/reg2 storage');
    is($schedule_report->{children}[2]{bindings}{storage}{registers}[2]{address}{value}, 8, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports status reg2 address 8');
    is($schedule_report->{children}[2]{protection_policy}{registers}[2]{read}{predicate}{value}, 1, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports protected status reg2 read policy');
    is($schedule_report->{children}[3]{protection_policy}{registers}[2]{write}{predicate}{value}, 1, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports protected control reg2 write policy');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports queue-depth 1');
    is($schedule_report->{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports interconnect timing role');
    is($schedule_report->{back_to_back_policy}{peripherals}[0]{timing_policy}{setup_admission}, 'adjacent', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports status adjacent setup admission');
    is($schedule_report->{back_to_back_policy}{peripherals}[1]{timing_policy}{setup_admission}, 'adjacent', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports control adjacent setup admission');
    my %residue_by_id = map { $_->{id} => $_ } @{$schedule_report->{unsupported_residue}};
    my %residue = map { $_ => 1 } keys %residue_by_id;
    ok(!$residue{apb_back_to_back_policy_deferred}, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok(!$residue{apb_protection_policy_effects_deferred}, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports narrowed future timing-policy residue');
    ok($residue{apb_additional_protection_policies_deferred}, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports additional-policy residue');
    ok($residue{apb_alternate_widths_deferred}, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition schedule JSON keeps alternate-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "generalized sideband protection multi-peripheral multi-register back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(PSTRB_CONTROL 4\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir interconnect preserves 4-bit control PSTRB');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir interconnect fans out PPROT');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir interconnect fans out PSTRB');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir interconnect uses control base 256');
    unlike($interconnect, qr/prot_q/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir interconnect remains enforcement-free');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_wdata 32\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir top embeds 32-bit queued data');
    like($top, qr/\(queued_wstrb 4\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir top embeds queued 4-bit PSTRB');
    like($top, qr/\(status_reg2_data_q 32 \(reset 0\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir top embeds status reg2 storage');
    like($top, qr/\(control_reg2_data_q 32 \(reset 0\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir top embeds control reg2 storage');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 8\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir top embeds denied protected reg2 read branch');
    like($top, qr/\(\?\(& write_q \(== addr 8\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'generalized sideband protection multi-peripheral multi-register back-to-back outdir top embeds denied protected reg2 write branch');
    my $sv = slurp($hdl);
    like($sv, qr/\bwire\s+\[3:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition HDL declares 4-bit control PSTRB link');
    like($sv, qr/PADDR_CONTROL_next = PADDR - 256;/, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition HDL includes 256-byte local address translation');
    like($sv, qr/\breg\s+\[31:0\]\s+status_reg2_data_q\b/, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition HDL carries 32-bit status reg2 storage');
    like($sv, qr/\breg\s+\[31:0\]\s+control_reg2_data_q\b/, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition HDL carries 32-bit control reg2 storage');
    like($sv, qr/\breg\s+\[3:0\]\s+queued_wstrb\b/, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition HDL carries 4-bit queued PSTRB');
    like($sv, qr/prot_q\s*&\s*3'd1/, 'generalized sideband protection multi-peripheral multi-register back-to-back APB composition HDL preserves endpoint PPROT predicate logic');

    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_apb_path(), 'tracked runnable generalized sideband protection multi-peripheral multi-register back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias returns the composition kind');
    is($alias->{mode}, 'requester-multi-peripheral-composition', 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves mode');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 32, 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves data width policy');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves policy owner');
    is_deeply($alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves control reg0/reg1/reg2 storage');
    is($alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'generalized sideband protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves interconnect timing policy');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports topology');
    is($schedule_report->{composition}{width_policy}{data_width}, 16, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports data width 16');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 2, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports strobe width 2');
    is($schedule_report->{composition}{address_map}{alignment_bytes}, 2, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports 2-byte window alignment');
    is($schedule_report->{composition}{address_map}{windows}[1]{base}{default}, 258, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports control base 258');
    is($schedule_report->{children}[0]{bindings}{bus}{protection}{width}, 3, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports requester PPROT width');
    is_deeply($schedule_report->{children}[2]{transfer}{registers}, [qw(reg0 reg1)], 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports status reg0/reg1 storage');
    is_deeply($schedule_report->{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports control reg0/reg1 storage');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports queue-depth 1');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports accepted response field');
    is($schedule_report->{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports interconnect timing role');
    is($schedule_report->{back_to_back_policy}{peripherals}[0]{timing_policy}{setup_admission}, 'adjacent', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports status adjacent setup admission');
    is($schedule_report->{back_to_back_policy}{peripherals}[1]{timing_policy}{setup_admission}, 'adjacent', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports control adjacent setup admission');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok(!$residue{apb_alternate_widths_deferred}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON omits broad alternate-width residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports narrowed future timing-policy residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON keeps protection-policy effects residue');
    ok($residue{apb_remaining_widths_deferred}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_multi_register_sideband_data16_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back outdir interconnect preserves 2-bit control PSTRB');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back outdir interconnect fans out PPROT');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back outdir interconnect fans out PSTRB');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back outdir interconnect uses control base 258');
    unlike($interconnect, qr/prot_q/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back outdir interconnect remains enforcement-free');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_wstrb 2\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back outdir top embeds queued 2-bit PSTRB');
    like($top, qr/\(status_reg1_data_q 16 \(reset 0\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back outdir top embeds status reg1 storage');
    like($top, qr/\(control_reg1_data_q 16 \(reset 0\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back outdir top embeds control reg1 storage');
    like($top, qr/\(<- \(control_reg1_data_q \(\| \(& control_reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back outdir top embeds control reg1 high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\bwire\s+\[1:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL declares 2-bit control PSTRB link');
    like($sv, qr/PADDR_CONTROL_next = PADDR - 258;/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL includes 258-byte local address translation');
    like($sv, qr/\breg\s+\[15:0\]\s+status_reg1_data_q\b/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL carries 16-bit status reg1 storage');
    like($sv, qr/\breg\s+\[15:0\]\s+control_reg1_data_q\b/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL carries 16-bit control reg1 storage');
    like($sv, qr/\breg\s+\[1:0\]\s+queued_wstrb\b/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL carries 2-bit queued PSTRB');
    unlike($sv, qr/prot_q\s*&\s*3'd1/, 'sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL has no endpoint PPROT predicate logic');

    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_apb_path(), 'tracked runnable sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias returns the composition kind');
    is($alias->{mode}, 'requester-multi-peripheral-composition', 'sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves mode');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 16, 'sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves data width policy');
    is($alias->{report}{composition}{width_policy}{strobe_width}, 2, 'sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves strobe width policy');
    is_deeply($alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves control reg0/reg1 storage');
    is($alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves interconnect timing policy');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports topology');
    is($schedule_report->{composition}{width_policy}{data_width}, 16, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports data width 16');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 2, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports strobe width 2');
    is($schedule_report->{composition}{address_map}{alignment_bytes}, 2, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports 2-byte window alignment');
    is($schedule_report->{composition}{address_map}{windows}[1]{base}{default}, 258, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports control base 258');
    is($schedule_report->{children}[0]{bindings}{bus}{protection}{width}, 3, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports requester PPROT width');
    is_deeply($schedule_report->{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports status reg0/reg1/reg2 storage');
    is_deeply($schedule_report->{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports control reg0/reg1/reg2 storage');
    is($schedule_report->{children}[2]{bindings}{storage}{registers}[2]{address}{value}, 4, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports status reg2 address 4');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports queue-depth 1');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports accepted response field');
    is($schedule_report->{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports interconnect timing role');
    is($schedule_report->{back_to_back_policy}{peripherals}[0]{timing_policy}{setup_admission}, 'adjacent', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports status adjacent setup admission');
    is($schedule_report->{back_to_back_policy}{peripherals}[1]{timing_policy}{setup_admission}, 'adjacent', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports control adjacent setup admission');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok(!$residue{apb_alternate_widths_deferred}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON omits broad alternate-width residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports narrowed future timing-policy residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON keeps protection-policy effects residue');
    ok($residue{apb_remaining_widths_deferred}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back outdir interconnect preserves 2-bit control PSTRB');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back outdir interconnect fans out PPROT');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back outdir interconnect fans out PSTRB');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back outdir interconnect uses control base 258');
    unlike($interconnect, qr/prot_q/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back outdir interconnect remains enforcement-free');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_wstrb 2\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back outdir top embeds queued 2-bit PSTRB');
    like($top, qr/\(status_reg2_data_q 16 \(reset 0\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back outdir top embeds status reg2 storage');
    like($top, qr/\(control_reg2_data_q 16 \(reset 0\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back outdir top embeds control reg2 storage');
    like($top, qr/\(<- \(control_reg2_data_q \(\| \(& control_reg2_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back outdir top embeds control reg2 high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\bwire\s+\[1:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL declares 2-bit control PSTRB link');
    like($sv, qr/PADDR_CONTROL_next = PADDR - 258;/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL includes 258-byte local address translation');
    like($sv, qr/\breg\s+\[15:0\]\s+status_reg2_data_q\b/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL carries 16-bit status reg2 storage');
    like($sv, qr/\breg\s+\[15:0\]\s+control_reg2_data_q\b/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL carries 16-bit control reg2 storage');
    like($sv, qr/\breg\s+\[1:0\]\s+queued_wstrb\b/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL carries 2-bit queued PSTRB');
    unlike($sv, qr/prot_q\s*&\s*3'd1/, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition HDL has no endpoint PPROT predicate logic');

    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_apb_path(), 'tracked runnable generalized sideband data16 no-policy multi-peripheral multi-register back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias returns the composition kind');
    is($alias->{mode}, 'requester-multi-peripheral-composition', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves mode');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 16, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves data width policy');
    is($alias->{report}{composition}{width_policy}{strobe_width}, 2, 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves strobe width policy');
    is_deeply($alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves control reg0/reg1/reg2 storage');
    is($alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'generalized sideband data16 no-policy multi-peripheral multi-register back-to-back .apb APB composition alias preserves interconnect timing policy');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband data16 protection multi-peripheral multi-register back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports topology');
    is($schedule_report->{composition}{width_policy}{data_width}, 16, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports data width 16');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 2, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports strobe width 2');
    is($schedule_report->{composition}{address_map}{alignment_bytes}, 2, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports 2-byte window alignment');
    is($schedule_report->{composition}{address_map}{windows}[1]{base}{default}, 258, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports control base 258');
    is($schedule_report->{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports peripheral enforcement owners');
    is($schedule_report->{children}[0]{bindings}{bus}{protection}{width}, 3, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports requester PPROT width');
    is_deeply($schedule_report->{children}[2]{transfer}{registers}, [qw(reg0 reg1)], 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports status reg0/reg1 storage');
    is_deeply($schedule_report->{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports control reg0/reg1 storage');
    is($schedule_report->{children}[2]{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports protected status reg1 read policy');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports queue-depth 1');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports accepted response field');
    is($schedule_report->{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports interconnect timing role');
    is($schedule_report->{back_to_back_policy}{peripherals}[0]{timing_policy}{setup_admission}, 'adjacent', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports status adjacent setup admission');
    is($schedule_report->{back_to_back_policy}{peripherals}[1]{timing_policy}{setup_admission}, 'adjacent', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports control adjacent setup admission');
    my %residue_by_id = map { $_->{id} => $_ } @{$schedule_report->{unsupported_residue}};
    my %residue = map { $_ => 1 } keys %residue_by_id;
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok(!$residue{apb_protection_policy_effects_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON omits old policy-effects residue');
    ok(!$residue{apb_alternate_widths_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON omits broad alternate-width residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports narrowed future timing-policy residue');
    unlike($residue_by_id{apb_additional_back_to_back_policies_deferred}{detail}, qr/status\/control protected storage generalization/, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition residue retires stale status/control protected-storage wording');
    ok($residue{apb_additional_protection_policies_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports additional-policy residue');
    ok($residue{apb_remaining_widths_deferred}, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband data16 protection multi-peripheral multi-register back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back outdir interconnect preserves 2-bit control PSTRB');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back outdir interconnect fans out PPROT');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back outdir interconnect fans out PSTRB');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back outdir interconnect uses control base 258');
    unlike($interconnect, qr/prot_q/, 'sideband data16 protection multi-peripheral multi-register back-to-back outdir interconnect remains enforcement-free');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'sideband data16 protection multi-peripheral multi-register back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_wstrb 2\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back outdir top embeds queued 2-bit PSTRB');
    like($top, qr/\(status_reg1_data_q 16 \(reset 0\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back outdir top embeds status reg1 storage');
    like($top, qr/\(control_reg1_data_q 16 \(reset 0\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back outdir top embeds control reg1 storage');
    like($top, qr/\(<- \(control_reg1_data_q \(\| \(& control_reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband data16 protection multi-peripheral multi-register back-to-back outdir top embeds control reg1 high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\bwire\s+\[1:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition HDL declares 2-bit control PSTRB link');
    like($sv, qr/PADDR_CONTROL_next = PADDR - 258;/, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition HDL includes 258-byte local address translation');
    like($sv, qr/\breg\s+\[15:0\]\s+status_reg1_data_q\b/, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition HDL carries 16-bit status reg1 storage');
    like($sv, qr/\breg\s+\[15:0\]\s+control_reg1_data_q\b/, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition HDL carries 16-bit control reg1 storage');
    like($sv, qr/\breg\s+\[1:0\]\s+queued_wstrb\b/, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition HDL carries 2-bit queued PSTRB');
    like($sv, qr/prot_q\s*&\s*3'd1/, 'sideband data16 protection multi-peripheral multi-register back-to-back APB composition HDL preserves endpoint PPROT predicate logic');

    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_apb_path(), 'tracked runnable sideband data16 protection multi-peripheral multi-register back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband data16 protection multi-peripheral multi-register back-to-back .apb APB composition alias returns the composition kind');
    is($alias->{mode}, 'requester-multi-peripheral-composition', 'sideband data16 protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves mode');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband data16 protection multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband data16 protection multi-peripheral multi-register back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 16, 'sideband data16 protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves data width policy');
    is($alias->{report}{composition}{width_policy}{strobe_width}, 2, 'sideband data16 protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves strobe width policy');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband data16 protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves policy owner');
    is_deeply($alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], 'sideband data16 protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves control reg0/reg1 storage');
    is($alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband data16 protection multi-peripheral multi-register back-to-back .apb APB composition alias preserves interconnect timing policy');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband multi-peripheral APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband multi-peripheral APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband multi-peripheral APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband multi-peripheral APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'sideband multi-peripheral APB composition schedule JSON reports topology');
    is($schedule_report->{composition}{peripherals}[0]{generated_instance_name}, 'status_peripheral', 'sideband multi-peripheral APB composition schedule JSON reports generated status instance alias');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_interconnect_multi_peripheral_decode_deferred}, 'sideband multi-peripheral APB composition schedule JSON omits interconnect/decode deferred residue');
    ok(!$residue{apb_protection_and_strobes_deferred}, 'sideband multi-peripheral APB composition schedule JSON omits broad sideband residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'sideband multi-peripheral APB composition schedule JSON reports protection-policy residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_sideband.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband multi-peripheral APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband multi-peripheral APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband multi-peripheral APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband multi-peripheral APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband multi-peripheral outdir interconnect fans out PPROT to status');
    like($interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, 'sideband multi-peripheral outdir interconnect fans out PSTRB to control');
    my $sv = slurp($hdl);
    like($sv, qr/\bwire\s+\[2:0\]\s+comp_link_interconnect_PPROT_STATUS\b/, 'sideband multi-peripheral APB composition HDL declares status PPROT link');
    like($sv, qr/\bwire\s+\[3:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'sideband multi-peripheral APB composition HDL declares control PSTRB link');

    ok(-f sample_apb_composition_multi_peripheral_sideband_apb_path(), 'tracked runnable sideband multi-peripheral APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband multi-peripheral .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband multi-peripheral .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband multi-peripheral .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{topology}, 'multi_peripheral_interconnect', 'sideband multi-peripheral .apb APB composition alias preserves topology');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband protection multi-peripheral APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_protection_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband protection multi-peripheral APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband protection multi-peripheral APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral APB composition schedule JSON reports peripheral enforcement owners');
    is($schedule_report->{children}[1]{protection_policy}{interconnect_role}, 'propagate_pprot_pstrb_and_mux_selected_response_only', 'sideband protection multi-peripheral APB composition schedule JSON reports interconnect propagation role');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-peripheral APB composition schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-peripheral APB composition schedule JSON reports additional-policy residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_sideband_protection.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband protection multi-peripheral APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband protection multi-peripheral APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband protection multi-peripheral APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband protection multi-peripheral APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband protection multi-peripheral outdir interconnect fans out PPROT');
    unlike($interconnect, qr/prot_q/, 'sideband protection multi-peripheral outdir interconnect remains enforcement-free');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 0\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-peripheral outdir top embeds denied control read branch');
    my $sv = slurp($hdl);
    like($sv, qr/prot_q\s*&\s*3'd1/, 'sideband protection multi-peripheral APB composition HDL preserves endpoint PPROT predicate logic');

    ok(-f sample_apb_composition_multi_peripheral_sideband_protection_apb_path(), 'tracked runnable sideband protection multi-peripheral APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_protection_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_protection_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-peripheral .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband protection multi-peripheral .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband protection multi-peripheral .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral .apb APB composition alias preserves policy owner');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband protection multi-peripheral back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband protection multi-peripheral back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband protection multi-peripheral back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports topology');
    is($schedule_report->{composition}{width_policy}{data_width}, 32, 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports data width 32');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 4, 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports strobe width 4');
    is($schedule_report->{composition}{address_map}{alignment_bytes}, 4, 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports 4-byte window alignment');
    is($schedule_report->{composition}{address_map}{windows}[1]{base}{default}, 256, 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports control base 256');
    is($schedule_report->{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports peripheral enforcement owners');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports queue-depth 1');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports accepted response field');
    is($schedule_report->{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports interconnect timing role');
    is($schedule_report->{back_to_back_policy}{peripherals}[0]{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports status adjacent setup admission');
    is($schedule_report->{back_to_back_policy}{peripherals}[1]{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports control adjacent setup admission');
    my %residue_by_id = map { $_->{id} => $_ } @{$schedule_report->{unsupported_residue}};
    my %residue = map { $_ => 1 } keys %residue_by_id;
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband protection multi-peripheral back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok(!$residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-peripheral back-to-back APB composition schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports narrowed future timing-policy residue');
    unlike($residue_by_id{apb_additional_back_to_back_policies_deferred}{detail}, qr/status\/control protected storage generalization/, 'sideband protection multi-peripheral back-to-back APB composition residue retires stale status/control protected-storage wording');
    ok($residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports additional-policy residue');
    ok($residue{apb_alternate_widths_deferred}, 'sideband protection multi-peripheral back-to-back APB composition schedule JSON reports alternate-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_sideband_protection_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband protection multi-peripheral back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband protection multi-peripheral back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband protection multi-peripheral back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband protection multi-peripheral back-to-back APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(PSTRB_CONTROL 4\)/, 'sideband protection multi-peripheral back-to-back outdir interconnect preserves 4-bit control PSTRB');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband protection multi-peripheral back-to-back outdir interconnect fans out PPROT');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, 'sideband protection multi-peripheral back-to-back outdir interconnect uses control base 256');
    unlike($interconnect, qr/prot_q/, 'sideband protection multi-peripheral back-to-back outdir interconnect remains enforcement-free');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'sideband protection multi-peripheral back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_wstrb 4\)/, 'sideband protection multi-peripheral back-to-back outdir top embeds queued 4-bit PSTRB');
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 0\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-peripheral back-to-back outdir top embeds denied control read branch');
    like($top, qr/\(<- \(control_shadow_data_q \(\| \(& control_shadow_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'sideband protection multi-peripheral back-to-back outdir top embeds high-byte control shadow write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\bwire\s+\[3:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'sideband protection multi-peripheral back-to-back APB composition HDL declares 4-bit control PSTRB link');
    like($sv, qr/PADDR_CONTROL_next = PADDR - 256;/, 'sideband protection multi-peripheral back-to-back APB composition HDL includes 256-byte local address translation');
    like($sv, qr/\breg\s+\[31:0\]\s+control_shadow_data_q\b/, 'sideband protection multi-peripheral back-to-back APB composition HDL carries 32-bit control shadow register');
    like($sv, qr/\breg\s+\[3:0\]\s+queued_wstrb\b/, 'sideband protection multi-peripheral back-to-back APB composition HDL carries 4-bit queued PSTRB');
    like($sv, qr/prot_q\s*&\s*3'd1/, 'sideband protection multi-peripheral back-to-back APB composition HDL preserves endpoint PPROT predicate logic');

    ok(-f sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_apb_path(), 'tracked runnable sideband protection multi-peripheral back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-peripheral back-to-back .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband protection multi-peripheral back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband protection multi-peripheral back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 32, 'sideband protection multi-peripheral back-to-back .apb APB composition alias preserves data width policy');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral back-to-back .apb APB composition alias preserves policy owner');
    is($alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband protection multi-peripheral back-to-back .apb APB composition alias preserves interconnect timing policy');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband multi-peripheral data16 APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_data16_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband multi-peripheral data16 APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband multi-peripheral data16 APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband multi-peripheral data16 APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'sideband multi-peripheral data16 APB composition schedule JSON reports topology');
    is($schedule_report->{composition}{width_policy}{data_width}, 16, 'sideband multi-peripheral data16 APB composition schedule JSON reports data width 16');
    is($schedule_report->{composition}{address_map}{alignment_bytes}, 2, 'sideband multi-peripheral data16 APB composition schedule JSON reports 2-byte window alignment');
    is($schedule_report->{composition}{address_map}{windows}[1]{base}{default}, 258, 'sideband multi-peripheral data16 APB composition schedule JSON reports control base 258');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_alternate_widths_deferred}, 'sideband multi-peripheral data16 APB composition schedule JSON omits broad alternate-width residue');
    ok($residue{apb_remaining_widths_deferred}, 'sideband multi-peripheral data16 APB composition schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_sideband_data16.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband multi-peripheral data16 APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband multi-peripheral data16 APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband multi-peripheral data16 APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband multi-peripheral data16 APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'sideband multi-peripheral data16 outdir interconnect preserves 2-bit control PSTRB');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'sideband multi-peripheral data16 outdir interconnect uses control base 258');
    my $sv = slurp($hdl);
    like($sv, qr/\bwire\s+\[1:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'sideband multi-peripheral data16 APB composition HDL declares 2-bit control PSTRB link');
    like($sv, qr/PADDR_CONTROL_next = PADDR - 258;/, 'sideband multi-peripheral data16 APB composition HDL includes 258-byte local address translation');
    like($sv, qr/\breg\s+\[15:0\]\s+control_data_q\b/, 'sideband multi-peripheral data16 APB composition HDL carries 16-bit control register');

    ok(-f sample_apb_composition_multi_peripheral_sideband_data16_apb_path(), 'tracked runnable sideband multi-peripheral data16 APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband multi-peripheral data16 .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband multi-peripheral data16 .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband multi-peripheral data16 .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{address_map}{alignment_bytes}, 2, 'sideband multi-peripheral data16 .apb APB composition alias preserves 2-byte alignment policy');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband protection multi-peripheral data16 APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_data16_protection_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband protection multi-peripheral data16 APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband protection multi-peripheral data16 APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband protection multi-peripheral data16 APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'sideband protection multi-peripheral data16 APB composition schedule JSON reports topology');
    is($schedule_report->{composition}{width_policy}{data_width}, 16, 'sideband protection multi-peripheral data16 APB composition schedule JSON reports data width 16');
    is($schedule_report->{composition}{address_map}{alignment_bytes}, 2, 'sideband protection multi-peripheral data16 APB composition schedule JSON reports 2-byte window alignment');
    is($schedule_report->{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral data16 APB composition schedule JSON reports peripheral enforcement owners');
    is($schedule_report->{children}[1]{protection_policy}{interconnect_role}, 'propagate_pprot_pstrb_and_mux_selected_response_only', 'sideband protection multi-peripheral data16 APB composition schedule JSON reports interconnect propagation role');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-peripheral data16 APB composition schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-peripheral data16 APB composition schedule JSON reports additional-policy residue');
    ok($residue{apb_remaining_widths_deferred}, 'sideband protection multi-peripheral data16 APB composition schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_sideband_data16_protection.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband protection multi-peripheral data16 APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband protection multi-peripheral data16 APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband protection multi-peripheral data16 APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband protection multi-peripheral data16 APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'sideband protection multi-peripheral data16 outdir interconnect preserves 2-bit control PSTRB');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband protection multi-peripheral data16 outdir interconnect fans out PPROT');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'sideband protection multi-peripheral data16 outdir interconnect uses control base 258');
    unlike($interconnect, qr/prot_q/, 'sideband protection multi-peripheral data16 outdir interconnect remains enforcement-free');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/\(\?\(& \(! write_q\) \(== addr 0\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'sideband protection multi-peripheral data16 outdir top embeds denied control read branch');
    like($top, qr/\(<- \(control_shadow_data_q \(\| \(& control_shadow_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband protection multi-peripheral data16 outdir top embeds high-byte control shadow write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\bwire\s+\[1:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'sideband protection multi-peripheral data16 APB composition HDL declares 2-bit control PSTRB link');
    like($sv, qr/PADDR_CONTROL_next = PADDR - 258;/, 'sideband protection multi-peripheral data16 APB composition HDL includes 258-byte local address translation');
    like($sv, qr/\breg\s+\[15:0\]\s+control_shadow_data_q\b/, 'sideband protection multi-peripheral data16 APB composition HDL carries 16-bit control shadow register');
    like($sv, qr/prot_q\s*&\s*3'd1/, 'sideband protection multi-peripheral data16 APB composition HDL preserves endpoint PPROT predicate logic');

    ok(-f sample_apb_composition_multi_peripheral_sideband_data16_protection_apb_path(), 'tracked runnable sideband protection multi-peripheral data16 APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_protection_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_protection_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-peripheral data16 .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband protection multi-peripheral data16 .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband protection multi-peripheral data16 .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{address_map}{alignment_bytes}, 2, 'sideband protection multi-peripheral data16 .apb APB composition alias preserves 2-byte alignment policy');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral data16 .apb APB composition alias preserves policy owner');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose sideband protection multi-peripheral data16 back-to-back APB composition review artifacts' => sub {
    my $path = sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'sideband protection multi-peripheral data16 back-to-back APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'sideband protection multi-peripheral data16 back-to-back APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports schema');
    is($schedule_report->{composition}{topology}, 'multi_peripheral_interconnect', 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports topology');
    is($schedule_report->{composition}{width_policy}{data_width}, 16, 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports data width 16');
    is($schedule_report->{composition}{width_policy}{strobe_width}, 2, 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports strobe width 2');
    is($schedule_report->{composition}{address_map}{alignment_bytes}, 2, 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports 2-byte window alignment');
    is($schedule_report->{composition}{address_map}{windows}[1]{base}{default}, 258, 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports control base 258');
    is($schedule_report->{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports peripheral enforcement owners');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports queue-depth 1');
    is($schedule_report->{back_to_back_policy}{requester}{timing_policy}{accepted}, 'accepted', 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports accepted response field');
    is($schedule_report->{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports interconnect timing role');
    is($schedule_report->{back_to_back_policy}{peripherals}[0]{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports status adjacent setup admission');
    is($schedule_report->{back_to_back_policy}{peripherals}[1]{timing_policy}{setup_admission}, 'adjacent', 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports control adjacent setup admission');
    my %residue_by_id = map { $_->{id} => $_ } @{$schedule_report->{unsupported_residue}};
    my %residue = map { $_ => 1 } keys %residue_by_id;
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON omits broad back-to-back residue');
    ok(!$residue{apb_protection_policy_effects_deferred}, 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports narrowed future timing-policy residue');
    unlike($residue_by_id{apb_additional_back_to_back_policies_deferred}{detail}, qr/status\/control protected storage generalization/, 'sideband protection multi-peripheral data16 back-to-back APB composition residue retires stale status/control protected-storage wording');
    ok($residue{apb_additional_protection_policies_deferred}, 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports additional-policy residue');
    ok($residue{apb_remaining_widths_deferred}, 'sideband protection multi-peripheral data16 back-to-back APB composition schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_multi_peripheral_sideband_data16_protection_status_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'sideband protection multi-peripheral data16 back-to-back APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'sideband protection multi-peripheral data16 back-to-back APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_status_regs.isf apb_control_regs.isf apb_interconnect.isf apb_requester.fsm apb_status_regs.fsm apb_control_regs.fsm apb_interconnect.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "sideband protection multi-peripheral data16 back-to-back APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'sideband protection multi-peripheral data16 back-to-back APB composition --output writes generated HDL');
    my $interconnect = slurp(File::Spec->catfile($outdir, 'apb_interconnect.fsm'));
    like($interconnect, qr/\(PSTRB_CONTROL 2\)/, 'sideband protection multi-peripheral data16 back-to-back outdir interconnect preserves 2-bit control PSTRB');
    like($interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, 'sideband protection multi-peripheral data16 back-to-back outdir interconnect fans out PPROT');
    like($interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, 'sideband protection multi-peripheral data16 back-to-back outdir interconnect uses control base 258');
    unlike($interconnect, qr/prot_q/, 'sideband protection multi-peripheral data16 back-to-back outdir interconnect remains enforcement-free');
    my $top = slurp(File::Spec->catfile($outdir, 'apb_tb.fsm'));
    like($top, qr/=accepted>/, 'sideband protection multi-peripheral data16 back-to-back outdir top exposes accepted');
    like($top, qr/\(queued_wstrb 2\)/, 'sideband protection multi-peripheral data16 back-to-back outdir top embeds queued 2-bit PSTRB');
    like($top, qr/\(<- \(control_shadow_data_q \(\| \(& control_shadow_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband protection multi-peripheral data16 back-to-back outdir top embeds high-byte control shadow write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\bwire\s+\[1:0\]\s+comp_link_interconnect_PSTRB_CONTROL\b/, 'sideband protection multi-peripheral data16 back-to-back APB composition HDL declares 2-bit control PSTRB link');
    like($sv, qr/PADDR_CONTROL_next = PADDR - 258;/, 'sideband protection multi-peripheral data16 back-to-back APB composition HDL includes 258-byte local address translation');
    like($sv, qr/\breg\s+\[15:0\]\s+control_shadow_data_q\b/, 'sideband protection multi-peripheral data16 back-to-back APB composition HDL carries 16-bit control shadow register');
    like($sv, qr/\breg\s+\[1:0\]\s+queued_wstrb\b/, 'sideband protection multi-peripheral data16 back-to-back APB composition HDL carries 2-bit queued PSTRB');
    like($sv, qr/prot_q\s*&\s*3'd1/, 'sideband protection multi-peripheral data16 back-to-back APB composition HDL preserves endpoint PPROT predicate logic');

    ok(-f sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_apb_path(), 'tracked runnable sideband protection multi-peripheral data16 back-to-back APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'sideband protection multi-peripheral data16 back-to-back .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'sideband protection multi-peripheral data16 back-to-back .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'sideband protection multi-peripheral data16 back-to-back .apb APB composition alias mirrors .ppif generated IAL0');
    is($alias->{report}{composition}{width_policy}{data_width}, 16, 'sideband protection multi-peripheral data16 back-to-back .apb APB composition alias preserves data width policy');
    is($alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', 'sideband protection multi-peripheral data16 back-to-back .apb APB composition alias preserves policy owner');
    is($alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', 'sideband protection multi-peripheral data16 back-to-back .apb APB composition alias preserves interconnect timing policy');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose APB composition review artifacts' => sub {
    my $path = sample_apb_composition_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'APB composition schedule JSON reports schema');
    is($schedule_report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_tb.fsm', 'APB composition schedule JSON reports the HDL entry');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'APB composition --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\bmodule\s+apb_tb\b/, 'APB composition HDL contains the generated top module');
    like($sv, qr/\bmodule\s+apb_requester\b/, 'APB composition HDL contains the requester child module');
    like($sv, qr/\bmodule\s+apb_completer\b/, 'APB composition HDL contains the completer child module');
    unlike($sv, qr/\bbusy\b/, 'APB composition HDL does not expose deferred requester busy status');

    ok(-f sample_apb_composition_apb_path(), 'tracked runnable APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', '.apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, '.apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, '.apb APB composition alias mirrors .ppif generated IAL0');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose busy APB composition review artifacts' => sub {
    my $path = sample_apb_composition_busy_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'busy APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'busy APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'busy APB composition schedule JSON reports schema');
    is($schedule_report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_tb.fsm', 'busy APB composition schedule JSON reports the HDL entry');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok($residue{apb_requester_status_field_deferred}, 'busy APB composition schedule JSON keeps named status-field residue');
    ok(!$residue{apb_requester_busy_status_deferred}, 'busy APB composition schedule JSON omits busy/status deferred residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_busy.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'busy APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'busy APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "busy APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'busy APB composition --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\bmodule\s+apb_tb\b/, 'busy APB composition HDL contains the generated top module');
    like($sv, qr/\bmodule\s+apb_requester\b/, 'busy APB composition HDL contains the requester child module');
    like($sv, qr/\bmodule\s+apb_completer\b/, 'busy APB composition HDL contains the completer child module');
    like($sv, qr/\boutput\s+busy\b/, 'busy APB composition top HDL exposes requester busy');

    ok(-f sample_apb_composition_busy_apb_path(), 'tracked runnable busy APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_busy_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_busy_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'busy .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'busy .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'busy .apb APB composition alias mirrors .ppif generated IAL0');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose status APB composition review artifacts' => sub {
    my $path = sample_apb_composition_status_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'status APB composition --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'status APB composition --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_composition.v1', 'status APB composition schedule JSON reports schema');
    is($schedule_report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_tb.fsm', 'status APB composition schedule JSON reports the HDL entry');
    is($schedule_report->{requester_status_field}{name}, 'status', 'status APB composition schedule JSON exposes requester status metadata');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_requester_status_field_deferred}, 'status APB composition schedule JSON omits named status-field residue');
    ok(!$residue{apb_requester_busy_status_deferred}, 'status APB composition schedule JSON omits busy/status deferred residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_tb_status.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'status APB composition CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'status APB composition generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "status APB composition --outdir writes $artifact");
    }
    ok(-f $hdl, 'status APB composition --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\bmodule\s+apb_tb\b/, 'status APB composition HDL contains the generated top module');
    like($sv, qr/\bmodule\s+apb_requester\b/, 'status APB composition HDL contains the requester child module');
    like($sv, qr/\bmodule\s+apb_completer\b/, 'status APB composition HDL contains the completer child module');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+status\b/, 'status APB composition HDL exposes requester status');

    ok(-f sample_apb_composition_status_apb_path(), 'tracked runnable status APB composition .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_status_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_status_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_composition', 'status .apb APB composition alias returns the composition kind');
    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, 'status .apb APB composition alias mirrors .ppif generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'status .apb APB composition alias mirrors .ppif generated IAL0');
};

done_testing();

sub sample_apb_composition_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition.ppif');
}

sub sample_apb_composition_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition.apb');
}

sub sample_apb_composition_busy_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_busy.ppif');
}

sub sample_apb_composition_busy_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_busy.apb');
}

sub sample_apb_composition_status_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_status.ppif');
}

sub sample_apb_composition_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_status_back_to_back.ppif');
}

sub sample_apb_composition_sideband_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_sideband_status_back_to_back.ppif');
}

sub sample_apb_composition_status_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_status.apb');
}

sub sample_apb_composition_sideband_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_sideband_status_back_to_back.apb');
}

sub sample_apb_composition_multi_register_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register.ppif');
}

sub sample_apb_composition_multi_register_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register.apb');
}

sub sample_apb_composition_multi_register_sideband_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband.ppif');
}

sub sample_apb_composition_multi_register_sideband_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_register_sideband_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_protection.ppif');
}

sub sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_register_sideband_data16_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16.ppif');
}

sub sample_apb_composition_multi_register_sideband_data16_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_register_sideband_data16_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_protection.ppif');
}

sub sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_register_sideband_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband.apb');
}

sub sample_apb_composition_multi_register_sideband_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_status_back_to_back.apb');
}

sub sample_apb_composition_multi_register_sideband_protection_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_protection.apb');
}

sub sample_apb_composition_multi_register_sideband_protection_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_protection_status_back_to_back.apb');
}

sub sample_apb_composition_multi_register_sideband_data16_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16.apb');
}

sub sample_apb_composition_multi_register_sideband_data16_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_status_back_to_back.apb');
}

sub sample_apb_composition_multi_register_sideband_data16_protection_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_protection.apb');
}

sub sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_protection_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral.ppif');
}

sub sample_apb_composition_multi_peripheral_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral.apb');
}

sub sample_apb_composition_multi_peripheral_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_protection.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16_protection.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_protection_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_protection.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_protection_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_protection_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16_protection.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.apb');
}

sub sample_apb_composition_ppif {
    return slurp(sample_apb_composition_ppif_path());
}

sub sample_apb_composition_status_back_to_back_ppif {
    return slurp(sample_apb_composition_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_register_sideband_ppif {
    return slurp(sample_apb_composition_multi_register_sideband_ppif_path());
}

sub sample_apb_composition_multi_register_sideband_protection_ppif {
    return slurp(sample_apb_composition_multi_register_sideband_protection_ppif_path());
}

sub sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_register_sideband_data16_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_register_sideband_data16_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_peripheral_ppif {
    return slurp(sample_apb_composition_multi_peripheral_ppif_path());
}

sub sample_apb_composition_multi_peripheral_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_peripheral_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_peripheral_sideband_ppif {
    return slurp(sample_apb_composition_multi_peripheral_sideband_ppif_path());
}

sub sample_apb_composition_multi_peripheral_sideband_protection_ppif {
    return slurp(sample_apb_composition_multi_peripheral_sideband_protection_ppif_path());
}

sub sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif_path());
}

sub sample_apb_composition_multi_peripheral_sideband_data16_ppif {
    return slurp(sample_apb_composition_multi_peripheral_sideband_data16_ppif_path());
}

sub sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif {
    return slurp(sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif_path());
}

sub sorted {
    my ($values) = @_;
    return [sort @$values];
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $text;
    close $fh or die "close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "close $path: $!";
    return $text;
}
