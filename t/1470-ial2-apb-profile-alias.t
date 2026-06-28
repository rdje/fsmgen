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

subtest 'adapter accepts the selected .apb profile alias and preserves lowering' => sub {
    ok(-f sample_apb_path(), 'tracked runnable .apb profile-alias sample exists');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ppif_path());

    is($alias->{layer}, 'IAL2', '.apb parser result remains IAL2');
    is($alias->{kind}, 'protocol_intent.apb_requester_transfer', '.apb parser result keeps APB requester-transfer kind');
    is($alias->{generated_ial1}{name}, 'apb_requester.isf', '.apb exposes generated IAL1 artifact');
    is(
        $alias->{generated_ial1}{text},
        $ppif->{generated_ial1}{text},
        '.apb mirrors selected .ppif generated IAL1 text',
    );
    is_deeply(
        $alias->{generated_ial0}{files},
        $ppif->{generated_ial0}{files},
        '.apb mirrors selected .ppif generated IAL0 files',
    );
    is($alias->{report}{source_object}{id}, 'fsmgen-apb-requester-transfer', '.apb preserves source object id');
    is($alias->{report}{target_protocol}{profile}, 'apb', '.apb preserves explicit APB profile');
    is($alias->{report}{target_protocol}{object}, 'apb-requester', '.apb preserves APB requester object');
    is($alias->{report}{layering}{direct_ial2_to_ial0}, 0, '.apb keeps direct IAL2-to-IAL0 lowering forbidden');
};

subtest 'adapter accepts APB completer and composition .apb profile aliases' => sub {
    ok(-f sample_apb_completer_alias_path(), 'tracked runnable APB completer .apb sample exists');
    ok(-f sample_apb_composition_alias_path(), 'tracked runnable APB composition .apb sample exists');
    ok(-f sample_apb_completer_multi_register_alias_path(), 'tracked runnable APB multi-register completer .apb sample exists');
    ok(-f sample_apb_composition_multi_register_alias_path(), 'tracked runnable APB multi-register composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_alias_path(), 'tracked runnable APB multi-peripheral composition .apb sample exists');
    ok(-f sample_apb_sideband_path(), 'tracked runnable APB requester sideband .apb sample exists');
    ok(-f sample_apb_completer_multi_register_sideband_alias_path(), 'tracked runnable APB multi-register sideband completer .apb sample exists');
    ok(-f sample_apb_completer_multi_register_sideband_protection_alias_path(), 'tracked runnable APB multi-register sideband protection completer .apb sample exists');
    ok(-f sample_apb_composition_multi_register_sideband_alias_path(), 'tracked runnable APB multi-register sideband composition .apb sample exists');
    ok(-f sample_apb_composition_multi_register_sideband_protection_alias_path(), 'tracked runnable APB multi-register sideband protection composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_sideband_alias_path(), 'tracked runnable APB multi-peripheral sideband composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_sideband_protection_alias_path(), 'tracked runnable APB multi-peripheral sideband protection composition .apb sample exists');
    ok(-f sample_apb_sideband_data16_path(), 'tracked runnable APB requester sideband data16 .apb sample exists');
    ok(-f sample_apb_completer_multi_register_sideband_data16_alias_path(), 'tracked runnable APB multi-register sideband data16 completer .apb sample exists');
    ok(-f sample_apb_completer_multi_register_sideband_data16_protection_alias_path(), 'tracked runnable APB multi-register sideband data16 protection completer .apb sample exists');
    ok(-f sample_apb_composition_multi_register_sideband_data16_alias_path(), 'tracked runnable APB multi-register sideband data16 composition .apb sample exists');
    ok(-f sample_apb_composition_multi_register_sideband_data16_protection_alias_path(), 'tracked runnable APB multi-register sideband data16 protection composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_sideband_data16_alias_path(), 'tracked runnable APB multi-peripheral sideband data16 composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_sideband_data16_protection_alias_path(), 'tracked runnable APB multi-peripheral sideband data16 protection composition .apb sample exists');
    ok(-f sample_apb_status_back_to_back_path(), 'tracked runnable APB requester back-to-back .apb sample exists');
    ok(-f sample_apb_sideband_status_back_to_back_path(), 'tracked runnable APB requester sideband back-to-back .apb sample exists');
    ok(-f sample_apb_sideband_data16_status_back_to_back_path(), 'tracked runnable APB requester sideband data16 back-to-back .apb sample exists');
    ok(-f sample_apb_completer_back_to_back_alias_path(), 'tracked runnable APB completer back-to-back .apb sample exists');
    ok(-f sample_apb_completer_multi_register_sideband_data16_back_to_back_alias_path(), 'tracked runnable APB multi-register sideband data16 back-to-back completer .apb sample exists');
    ok(-f sample_apb_completer_multi_register_sideband_protection_back_to_back_alias_path(), 'tracked runnable APB multi-register sideband protection back-to-back completer .apb sample exists');
    ok(-f sample_apb_completer_multi_register_sideband_data16_protection_back_to_back_alias_path(), 'tracked runnable APB multi-register sideband data16 protection back-to-back completer .apb sample exists');
    ok(-f sample_apb_composition_status_back_to_back_alias_path(), 'tracked runnable APB composition back-to-back .apb sample exists');
    ok(-f sample_apb_composition_multi_register_sideband_data16_status_back_to_back_alias_path(), 'tracked runnable APB multi-register sideband data16 back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_register_sideband_protection_status_back_to_back_alias_path(), 'tracked runnable APB multi-register sideband protection back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_alias_path(), 'tracked runnable APB multi-register sideband data16 protection back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_status_back_to_back_alias_path(), 'tracked runnable APB multi-peripheral status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_alias_path(), 'tracked runnable APB multi-peripheral multi-register sideband no-policy status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_alias_path(), 'tracked runnable APB generalized multi-peripheral multi-register sideband no-policy status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back_alias_path(), 'tracked runnable APB generalized five-register multi-peripheral multi-register sideband no-policy status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back_alias_path(), 'tracked runnable APB generalized six-register multi-peripheral multi-register sideband no-policy status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_alias_path(), 'tracked runnable APB multi-peripheral multi-register sideband protection status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_alias_path(), 'tracked runnable APB generalized multi-peripheral multi-register sideband protection status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back_alias_path(), 'tracked runnable APB generalized five-register multi-peripheral multi-register sideband protection status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_alias_path(), 'tracked runnable APB multi-peripheral multi-register sideband data16 no-policy status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_alias_path(), 'tracked runnable APB generalized multi-peripheral multi-register sideband data16 no-policy status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back_alias_path(), 'tracked runnable APB generalized five-register multi-peripheral multi-register sideband data16 no-policy status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back_alias_path(), 'tracked runnable APB generalized six-register multi-peripheral multi-register sideband data16 no-policy status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_alias_path(), 'tracked runnable APB multi-peripheral multi-register sideband data16 protection status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back_alias_path(), 'tracked runnable APB generalized multi-peripheral multi-register sideband data16 protection status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back_alias_path(), 'tracked runnable APB generalized five-register multi-peripheral multi-register sideband data16 protection status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_alias_path(), 'tracked runnable APB multi-peripheral sideband protection status back-to-back composition .apb sample exists');
    ok(-f sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_alias_path(), 'tracked runnable APB multi-peripheral sideband data16 protection status back-to-back composition .apb sample exists');

    my $completer_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_alias_path());
    my $completer_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_ppif_path());
    is($completer_alias->{kind}, 'protocol_intent.apb_completer', '.apb completer parser result keeps APB completer kind');
    is($completer_alias->{generated_ial1}{text}, $completer_ppif->{generated_ial1}{text}, '.apb completer mirrors .ppif generated IAL1 text');
    is_deeply($completer_alias->{generated_ial0}{files}, $completer_ppif->{generated_ial0}{files}, '.apb completer mirrors .ppif generated IAL0 files');

    my $composition_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_alias_path());
    my $composition_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_ppif_path());
    is($composition_alias->{kind}, 'protocol_intent.apb_composition', '.apb composition parser result keeps APB composition kind');
    is_deeply($composition_alias->{generated_ial1}{items}, $composition_ppif->{generated_ial1}{items}, '.apb composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($composition_alias->{generated_ial0}{files}, $composition_ppif->{generated_ial0}{files}, '.apb composition mirrors .ppif generated IAL0 files');
    is($composition_alias->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_tb.fsm', '.apb composition keeps apb_tb.fsm as HDL entry');

    my $btb_requester_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_status_back_to_back_path());
    my $btb_requester_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ppif_status_back_to_back_path());
    is($btb_requester_alias->{kind}, 'protocol_intent.apb_requester_transfer', '.apb requester back-to-back parser result keeps APB requester-transfer kind');
    is($btb_requester_alias->{generated_ial1}{text}, $btb_requester_ppif->{generated_ial1}{text}, '.apb requester back-to-back mirrors .ppif generated IAL1 text');
    is_deeply($btb_requester_alias->{generated_ial0}{files}, $btb_requester_ppif->{generated_ial0}{files}, '.apb requester back-to-back mirrors .ppif generated IAL0 files');
    is($btb_requester_alias->{report}{transfer}{timing_policy}{queue_depth}, 1, '.apb requester back-to-back preserves queue-depth 1 policy');

    my $btb_sideband_requester_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_sideband_status_back_to_back_path());
    my $btb_sideband_requester_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ppif_sideband_status_back_to_back_path());
    my $btb_sideband_requester_fsm = $btb_sideband_requester_alias->{generated_ial0}{files}{'apb_requester.fsm'};
    is($btb_sideband_requester_alias->{kind}, 'protocol_intent.apb_requester_transfer', '.apb requester sideband back-to-back parser result keeps APB requester-transfer kind');
    is($btb_sideband_requester_alias->{generated_ial1}{text}, $btb_sideband_requester_ppif->{generated_ial1}{text}, '.apb requester sideband back-to-back mirrors .ppif generated IAL1 text');
    is_deeply($btb_sideband_requester_alias->{generated_ial0}{files}, $btb_sideband_requester_ppif->{generated_ial0}{files}, '.apb requester sideband back-to-back mirrors .ppif generated IAL0 files');
    like($btb_sideband_requester_fsm, qr/\(queued_prot 3\)/, '.apb requester sideband back-to-back declares queued_prot');
    like($btb_sideband_requester_fsm, qr/\(queued_wstrb 4\)/, '.apb requester sideband back-to-back declares queued_wstrb');
    like($btb_sideband_requester_fsm, qr/\(<= \(queued_prot req_prot\)\)/, '.apb requester sideband back-to-back captures queued PPROT');
    like($btb_sideband_requester_fsm, qr/\(<= \(queued_wstrb req_wstrb\)\)/, '.apb requester sideband back-to-back captures queued PSTRB');
    like($btb_sideband_requester_fsm, qr/\(<- \(PPROT> queued_prot\)\)/, '.apb requester sideband back-to-back relaunches queued PPROT');
    like($btb_sideband_requester_fsm, qr/\(<- \(PSTRB> \(& queued_wstrb \(concat queued_write queued_write queued_write queued_write\)\)\)/, '.apb requester sideband back-to-back masks queued PSTRB with queued write bit');
    like($btb_sideband_requester_fsm, qr/\(<- \(PSTRB> \(& req_wstrb \(concat req_write req_write req_write req_write\)\)\)/, '.apb requester sideband back-to-back masks directly accepted PSTRB with current write bit');
    is($btb_sideband_requester_alias->{report}{response_accepted_field}{name}, 'accepted', '.apb requester sideband back-to-back report exposes accepted metadata');
    is($btb_sideband_requester_alias->{report}{transfer}{timing_policy}{overflow}, 'reject', '.apb requester sideband back-to-back preserves overflow reject policy');
    my %btb_sideband_requester_residue = map { $_->{id} => 1 } @{$btb_sideband_requester_alias->{report}{unsupported_residue}};
    ok(!$btb_sideband_requester_residue{apb_back_to_back_policy_deferred}, '.apb requester sideband back-to-back removes broad back-to-back residue');
    ok($btb_sideband_requester_residue{apb_additional_back_to_back_policies_deferred}, '.apb requester sideband back-to-back keeps narrowed future-policy residue');

    my $btb_sideband_data16_requester_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_sideband_data16_status_back_to_back_path());
    my $btb_sideband_data16_requester_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ppif_sideband_data16_status_back_to_back_path());
    my $btb_sideband_data16_requester_fsm = $btb_sideband_data16_requester_alias->{generated_ial0}{files}{'apb_requester.fsm'};
    is($btb_sideband_data16_requester_alias->{kind}, 'protocol_intent.apb_requester_transfer', '.apb requester sideband data16 back-to-back parser result keeps APB requester-transfer kind');
    is($btb_sideband_data16_requester_alias->{generated_ial1}{text}, $btb_sideband_data16_requester_ppif->{generated_ial1}{text}, '.apb requester sideband data16 back-to-back mirrors .ppif generated IAL1 text');
    is_deeply($btb_sideband_data16_requester_alias->{generated_ial0}{files}, $btb_sideband_data16_requester_ppif->{generated_ial0}{files}, '.apb requester sideband data16 back-to-back mirrors .ppif generated IAL0 files');
    like($btb_sideband_data16_requester_fsm, qr/\(queued_wdata 16\)/, '.apb requester sideband data16 back-to-back declares 16-bit queued data');
    like($btb_sideband_data16_requester_fsm, qr/\(queued_wstrb 2\)/, '.apb requester sideband data16 back-to-back declares 2-bit queued PSTRB');
    like($btb_sideband_data16_requester_fsm, qr/\(<= \(queued_wdata req_wdata\)\)/, '.apb requester sideband data16 back-to-back captures queued write data');
    like($btb_sideband_data16_requester_fsm, qr/\(<- \(PWDATA> queued_wdata\)\)/, '.apb requester sideband data16 back-to-back relaunches queued write data');
    like($btb_sideband_data16_requester_fsm, qr/\(<- \(PSTRB> \(& queued_wstrb \(concat queued_write queued_write\)\)\)/, '.apb requester sideband data16 back-to-back masks queued 2-bit PSTRB with queued write bit');
    is($btb_sideband_data16_requester_alias->{report}{width_policy}{data_width}, 16, '.apb requester sideband data16 back-to-back preserves data width policy');
    is($btb_sideband_data16_requester_alias->{report}{width_policy}{strobe_width}, 2, '.apb requester sideband data16 back-to-back preserves strobe width policy');
    my %btb_sideband_data16_requester_residue = map { $_->{id} => 1 } @{$btb_sideband_data16_requester_alias->{report}{unsupported_residue}};
    ok(!$btb_sideband_data16_requester_residue{apb_back_to_back_policy_deferred}, '.apb requester sideband data16 back-to-back removes broad back-to-back residue');
    ok($btb_sideband_data16_requester_residue{apb_additional_back_to_back_policies_deferred}, '.apb requester sideband data16 back-to-back keeps narrowed future-policy residue');

    my $btb_completer_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_back_to_back_alias_path());
    my $btb_completer_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_back_to_back_ppif_path());
    is($btb_completer_alias->{kind}, 'protocol_intent.apb_completer', '.apb completer back-to-back parser result keeps APB completer kind');
    is($btb_completer_alias->{generated_ial1}{text}, $btb_completer_ppif->{generated_ial1}{text}, '.apb completer back-to-back mirrors .ppif generated IAL1 text');
    is_deeply($btb_completer_alias->{generated_ial0}{files}, $btb_completer_ppif->{generated_ial0}{files}, '.apb completer back-to-back mirrors .ppif generated IAL0 files');
    is($btb_completer_alias->{report}{transfer}{timing_policy}{setup_admission}, 'adjacent', '.apb completer back-to-back preserves adjacent setup admission policy');

    my $btb_data16_completer_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_back_to_back_alias_path());
    my $btb_data16_completer_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif_path());
    my $btb_data16_completer_fsm = $btb_data16_completer_alias->{generated_ial0}{files}{'apb_completer.fsm'};
    is($btb_data16_completer_alias->{kind}, 'protocol_intent.apb_completer', '.apb sideband data16 back-to-back completer parser result keeps APB completer kind');
    is($btb_data16_completer_alias->{generated_ial1}{text}, $btb_data16_completer_ppif->{generated_ial1}{text}, '.apb sideband data16 back-to-back completer mirrors .ppif generated IAL1 text');
    is_deeply($btb_data16_completer_alias->{generated_ial0}{files}, $btb_data16_completer_ppif->{generated_ial0}{files}, '.apb sideband data16 back-to-back completer mirrors .ppif generated IAL0 files');
    is($btb_data16_completer_alias->{report}{transfer}{timing_policy}{setup_admission}, 'adjacent', '.apb sideband data16 back-to-back completer preserves adjacent setup admission policy');
    is($btb_data16_completer_alias->{report}{width_policy}{data_width}, 16, '.apb sideband data16 back-to-back completer preserves data width policy');
    is_deeply($btb_data16_completer_alias->{report}{transfer}{registers}, [qw(reg0 reg1)], '.apb sideband data16 back-to-back completer preserves selected two-register list');
    like($btb_data16_completer_fsm, qr/\(PSTRB 2\)/, '.apb sideband data16 back-to-back completer preserves 2-bit PSTRB');
    like($btb_data16_completer_fsm, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, '.apb sideband data16 back-to-back completer samples adjacent setup');
    like($btb_data16_completer_fsm, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, '.apb sideband data16 back-to-back completer preserves high-byte write mask');

    my $btb_data16_protection_completer_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_protection_back_to_back_alias_path());
    my $btb_data16_protection_completer_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_protection_back_to_back_ppif_path());
    my $btb_data16_protection_completer_fsm = $btb_data16_protection_completer_alias->{generated_ial0}{files}{'apb_completer.fsm'};
    is($btb_data16_protection_completer_alias->{kind}, 'protocol_intent.apb_completer', '.apb sideband data16 protection back-to-back completer parser result keeps APB completer kind');
    is($btb_data16_protection_completer_alias->{generated_ial1}{text}, $btb_data16_protection_completer_ppif->{generated_ial1}{text}, '.apb sideband data16 protection back-to-back completer mirrors .ppif generated IAL1 text');
    is_deeply($btb_data16_protection_completer_alias->{generated_ial0}{files}, $btb_data16_protection_completer_ppif->{generated_ial0}{files}, '.apb sideband data16 protection back-to-back completer mirrors .ppif generated IAL0 files');
    is($btb_data16_protection_completer_alias->{report}{transfer}{timing_policy}{setup_admission}, 'adjacent', '.apb sideband data16 protection back-to-back completer preserves adjacent setup admission policy');
    is($btb_data16_protection_completer_alias->{report}{width_policy}{data_width}, 16, '.apb sideband data16 protection back-to-back completer preserves data width policy');
    is($btb_data16_protection_completer_alias->{report}{protection_policy}{predicate_namespace}, 'fsmgen_apb_pprot_v1', '.apb sideband data16 protection back-to-back completer preserves protection-policy metadata');
    like($btb_data16_protection_completer_fsm, qr/\(PSTRB 2\)/, '.apb sideband data16 protection back-to-back completer preserves 2-bit PSTRB');
    like($btb_data16_protection_completer_fsm, qr/\(\?\(& write_q \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, '.apb sideband data16 protection back-to-back completer keeps denied reg1 write branch');
    like($btb_data16_protection_completer_fsm, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, '.apb sideband data16 protection back-to-back completer preserves high-byte write mask');

    my $btb_composition_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_status_back_to_back_alias_path());
    my $btb_composition_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_status_back_to_back_ppif_path());
    is($btb_composition_alias->{kind}, 'protocol_intent.apb_composition', '.apb composition back-to-back parser result keeps APB composition kind');
    is_deeply($btb_composition_alias->{generated_ial1}{items}, $btb_composition_ppif->{generated_ial1}{items}, '.apb composition back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_composition_alias->{generated_ial0}{files}, $btb_composition_ppif->{generated_ial0}{files}, '.apb composition back-to-back mirrors .ppif generated IAL0 files');
    is($btb_composition_alias->{report}{back_to_back_policy}{requester}{timing_policy}{overflow}, 'reject', '.apb composition back-to-back preserves aggregate requester policy');

    my $btb_data16_composition_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_status_back_to_back_alias_path());
    my $btb_data16_composition_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_status_back_to_back_ppif_path());
    my $btb_data16_composition_top = $btb_data16_composition_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    is($btb_data16_composition_alias->{kind}, 'protocol_intent.apb_composition', '.apb sideband data16 fixed back-to-back composition parser result keeps APB composition kind');
    is_deeply($btb_data16_composition_alias->{generated_ial1}{items}, $btb_data16_composition_ppif->{generated_ial1}{items}, '.apb sideband data16 fixed back-to-back composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_data16_composition_alias->{generated_ial0}{files}, $btb_data16_composition_ppif->{generated_ial0}{files}, '.apb sideband data16 fixed back-to-back composition mirrors .ppif generated IAL0 files');
    is($btb_data16_composition_alias->{report}{composition}{width_policy}{data_width}, 16, '.apb sideband data16 fixed back-to-back composition preserves data width policy');
    is($btb_data16_composition_alias->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', '.apb sideband data16 fixed back-to-back composition preserves aggregate completer timing policy');
    like($btb_data16_composition_top, qr/=accepted>/, '.apb sideband data16 fixed back-to-back composition top exposes accepted');
    like($btb_data16_composition_top, qr/=req_wstrb<2/, '.apb sideband data16 fixed back-to-back composition top exposes 2-bit requester strobe');
    like($btb_data16_composition_top, qr/\(queued_wdata 16\)/, '.apb sideband data16 fixed back-to-back composition embeds 16-bit queued data state');
    like($btb_data16_composition_top, qr/\(reg1_data_q 16 \(reset 0\)\)/, '.apb sideband data16 fixed back-to-back composition embeds selected data16 completer storage');

    my $btb_data16_protection_composition_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_alias_path());
    my $btb_data16_protection_composition_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif_path());
    my $btb_data16_protection_composition_top = $btb_data16_protection_composition_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    is($btb_data16_protection_composition_alias->{kind}, 'protocol_intent.apb_composition', '.apb sideband data16 protection fixed back-to-back composition parser result keeps APB composition kind');
    is_deeply($btb_data16_protection_composition_alias->{generated_ial1}{items}, $btb_data16_protection_composition_ppif->{generated_ial1}{items}, '.apb sideband data16 protection fixed back-to-back composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_data16_protection_composition_alias->{generated_ial0}{files}, $btb_data16_protection_composition_ppif->{generated_ial0}{files}, '.apb sideband data16 protection fixed back-to-back composition mirrors .ppif generated IAL0 files');
    is($btb_data16_protection_composition_alias->{report}{composition}{width_policy}{data_width}, 16, '.apb sideband data16 protection fixed back-to-back composition preserves data width policy');
    is($btb_data16_protection_composition_alias->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', '.apb sideband data16 protection fixed back-to-back composition preserves aggregate completer timing policy');
    is($btb_data16_protection_composition_alias->{report}{protection_policy}{enforcement_owner}, 'completer', '.apb sideband data16 protection fixed back-to-back composition preserves completer policy owner');
    like($btb_data16_protection_composition_top, qr/=accepted>/, '.apb sideband data16 protection fixed back-to-back composition top exposes accepted');
    like($btb_data16_protection_composition_top, qr/=req_wstrb<2/, '.apb sideband data16 protection fixed back-to-back composition top exposes 2-bit requester strobe');
    like($btb_data16_protection_composition_top, qr/\(queued_prot 3\)/, '.apb sideband data16 protection fixed back-to-back composition embeds queued PPROT state');
    like($btb_data16_protection_composition_top, qr/\(\?\(& write_q \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, '.apb sideband data16 protection fixed back-to-back composition embeds denied reg1 write branch');

    my $btb_multi_peripheral_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_status_back_to_back_alias_path());
    my $btb_multi_peripheral_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_status_back_to_back_ppif_path());
    is($btb_multi_peripheral_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral composition back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral composition back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_alias->{generated_ial1}{items}, $btb_multi_peripheral_ppif->{generated_ial1}{items}, '.apb multi-peripheral composition back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_alias->{generated_ial0}{files}, $btb_multi_peripheral_ppif->{generated_ial0}{files}, '.apb multi-peripheral composition back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb multi-peripheral composition back-to-back preserves aggregate interconnect policy');

    my $btb_multi_peripheral_no_policy_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_alias_path());
    my $btb_multi_peripheral_no_policy_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_no_policy_mreg_interconnect = $btb_multi_peripheral_no_policy_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    is($btb_multi_peripheral_no_policy_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral sideband no-policy multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_no_policy_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral sideband no-policy multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_no_policy_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_no_policy_mreg_ppif->{generated_ial1}{items}, '.apb multi-peripheral sideband no-policy multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_no_policy_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_no_policy_mreg_ppif->{generated_ial0}{files}, '.apb multi-peripheral sideband no-policy multi-register back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_no_policy_mreg_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb multi-peripheral sideband no-policy multi-register back-to-back preserves aggregate interconnect policy');
    is($btb_multi_peripheral_no_policy_mreg_alias->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, '.apb multi-peripheral sideband no-policy multi-register back-to-back preserves queue-depth 1 requester policy');
    is($btb_multi_peripheral_no_policy_mreg_alias->{report}{composition}{width_policy}{data_width}, 32, '.apb multi-peripheral sideband no-policy multi-register back-to-back preserves data width policy');
    is($btb_multi_peripheral_no_policy_mreg_alias->{report}{composition}{width_policy}{strobe_width}, 4, '.apb multi-peripheral sideband no-policy multi-register back-to-back preserves strobe width policy');
    is_deeply($btb_multi_peripheral_no_policy_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1)], '.apb multi-peripheral sideband no-policy multi-register back-to-back preserves status reg0/reg1 storage');
    is_deeply($btb_multi_peripheral_no_policy_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], '.apb multi-peripheral sideband no-policy multi-register back-to-back preserves control reg0/reg1 storage');
    like($btb_multi_peripheral_no_policy_mreg_interconnect, qr/\(PSTRB_CONTROL 4\)/, '.apb multi-peripheral sideband no-policy multi-register back-to-back interconnect keeps 4-bit control PSTRB');
    like($btb_multi_peripheral_no_policy_mreg_interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, '.apb multi-peripheral sideband no-policy multi-register back-to-back interconnect fans out PPROT');
    like($btb_multi_peripheral_no_policy_mreg_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, '.apb multi-peripheral sideband no-policy multi-register back-to-back interconnect uses the 256-byte control window base');
    unlike($btb_multi_peripheral_no_policy_mreg_interconnect, qr/prot_q/, '.apb multi-peripheral sideband no-policy multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_generalized_no_policy_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_alias_path());
    my $btb_multi_peripheral_generalized_no_policy_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_generalized_no_policy_mreg_top = $btb_multi_peripheral_generalized_no_policy_mreg_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    is($btb_multi_peripheral_generalized_no_policy_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb generalized multi-peripheral sideband no-policy multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_generalized_no_policy_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb generalized multi-peripheral sideband no-policy multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_generalized_no_policy_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_generalized_no_policy_mreg_ppif->{generated_ial1}{items}, '.apb generalized multi-peripheral sideband no-policy multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_generalized_no_policy_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_generalized_no_policy_mreg_ppif->{generated_ial0}{files}, '.apb generalized multi-peripheral sideband no-policy multi-register back-to-back mirrors .ppif generated IAL0 files');
    is_deeply($btb_multi_peripheral_generalized_no_policy_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2)], '.apb generalized multi-peripheral sideband no-policy multi-register back-to-back preserves status reg0/reg1/reg2 storage');
    is_deeply($btb_multi_peripheral_generalized_no_policy_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], '.apb generalized multi-peripheral sideband no-policy multi-register back-to-back preserves control reg0/reg1/reg2 storage');
    is($btb_multi_peripheral_generalized_no_policy_mreg_alias->{report}{children}[2]{bindings}{storage}{registers}[2]{address}{value}, 8, '.apb generalized multi-peripheral sideband no-policy multi-register back-to-back preserves status reg2 address');
    is($btb_multi_peripheral_generalized_no_policy_mreg_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb generalized multi-peripheral sideband no-policy multi-register back-to-back preserves aggregate interconnect policy');
    like($btb_multi_peripheral_generalized_no_policy_mreg_top, qr/\(status_reg2_data_q 32 \(reset 0\)\)/, '.apb generalized multi-peripheral sideband no-policy multi-register back-to-back top embeds status reg2 storage');
    like($btb_multi_peripheral_generalized_no_policy_mreg_top, qr/\(control_reg2_data_q 32 \(reset 0\)\)/, '.apb generalized multi-peripheral sideband no-policy multi-register back-to-back top embeds control reg2 storage');

    my $btb_multi_peripheral_generalized_five_register_no_policy_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back_alias_path());
    my $btb_multi_peripheral_generalized_five_register_no_policy_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_generalized_five_register_no_policy_mreg_top = $btb_multi_peripheral_generalized_five_register_no_policy_mreg_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    my $btb_multi_peripheral_generalized_five_register_no_policy_mreg_interconnect = $btb_multi_peripheral_generalized_five_register_no_policy_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    is($btb_multi_peripheral_generalized_five_register_no_policy_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_generalized_five_register_no_policy_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_generalized_five_register_no_policy_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_generalized_five_register_no_policy_mreg_ppif->{generated_ial1}{items}, '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_generalized_five_register_no_policy_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_generalized_five_register_no_policy_mreg_ppif->{generated_ial0}{files}, '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back mirrors .ppif generated IAL0 files');
    is_deeply($btb_multi_peripheral_generalized_five_register_no_policy_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4)], '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back preserves status reg0..reg4 storage');
    is_deeply($btb_multi_peripheral_generalized_five_register_no_policy_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4)], '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back preserves control reg0..reg4 storage');
    is($btb_multi_peripheral_generalized_five_register_no_policy_mreg_alias->{report}{children}[2]{bindings}{storage}{registers}[4]{address}{value}, 16, '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back preserves status reg4 address');
    is($btb_multi_peripheral_generalized_five_register_no_policy_mreg_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back preserves aggregate interconnect policy');
    like($btb_multi_peripheral_generalized_five_register_no_policy_mreg_top, qr/\(status_reg4_data_q 32 \(reset 0\)\)/, '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back top embeds status reg4 storage');
    like($btb_multi_peripheral_generalized_five_register_no_policy_mreg_top, qr/\(control_reg4_data_q 32 \(reset 0\)\)/, '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back top embeds control reg4 storage');
    like($btb_multi_peripheral_generalized_five_register_no_policy_mreg_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back interconnect uses the 256-byte control window base');
    unlike($btb_multi_peripheral_generalized_five_register_no_policy_mreg_interconnect, qr/prot_q/, '.apb generalized five-register multi-peripheral sideband no-policy multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_generalized_six_register_no_policy_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back_alias_path());
    my $btb_multi_peripheral_generalized_six_register_no_policy_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_generalized_six_register_no_policy_mreg_top = $btb_multi_peripheral_generalized_six_register_no_policy_mreg_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    my $btb_multi_peripheral_generalized_six_register_no_policy_mreg_interconnect = $btb_multi_peripheral_generalized_six_register_no_policy_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    is($btb_multi_peripheral_generalized_six_register_no_policy_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_generalized_six_register_no_policy_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_generalized_six_register_no_policy_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_generalized_six_register_no_policy_mreg_ppif->{generated_ial1}{items}, '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_generalized_six_register_no_policy_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_generalized_six_register_no_policy_mreg_ppif->{generated_ial0}{files}, '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back mirrors .ppif generated IAL0 files');
    is_deeply($btb_multi_peripheral_generalized_six_register_no_policy_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4 reg5)], '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back preserves status reg0..reg5 storage');
    is_deeply($btb_multi_peripheral_generalized_six_register_no_policy_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4 reg5)], '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back preserves control reg0..reg5 storage');
    is($btb_multi_peripheral_generalized_six_register_no_policy_mreg_alias->{report}{children}[2]{bindings}{storage}{registers}[5]{address}{value}, 20, '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back preserves status reg5 address');
    is($btb_multi_peripheral_generalized_six_register_no_policy_mreg_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back preserves aggregate interconnect policy');
    like($btb_multi_peripheral_generalized_six_register_no_policy_mreg_top, qr/\(status_reg5_data_q 32 \(reset 0\)\)/, '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back top embeds status reg5 storage');
    like($btb_multi_peripheral_generalized_six_register_no_policy_mreg_top, qr/\(control_reg5_data_q 32 \(reset 0\)\)/, '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back top embeds control reg5 storage');
    like($btb_multi_peripheral_generalized_six_register_no_policy_mreg_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back interconnect uses the 256-byte control window base');
    unlike($btb_multi_peripheral_generalized_six_register_no_policy_mreg_interconnect, qr/prot_q/, '.apb generalized six-register multi-peripheral sideband no-policy multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_protection_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_alias_path());
    my $btb_multi_peripheral_protection_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_protection_mreg_interconnect = $btb_multi_peripheral_protection_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    my $btb_multi_peripheral_protection_mreg_top = $btb_multi_peripheral_protection_mreg_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    is($btb_multi_peripheral_protection_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral sideband protection multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_protection_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral sideband protection multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_protection_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_protection_mreg_ppif->{generated_ial1}{items}, '.apb multi-peripheral sideband protection multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_protection_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_protection_mreg_ppif->{generated_ial0}{files}, '.apb multi-peripheral sideband protection multi-register back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_protection_mreg_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb multi-peripheral sideband protection multi-register back-to-back preserves aggregate interconnect policy');
    is($btb_multi_peripheral_protection_mreg_alias->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, '.apb multi-peripheral sideband protection multi-register back-to-back preserves queue-depth 1 requester policy');
    is($btb_multi_peripheral_protection_mreg_alias->{report}{composition}{width_policy}{data_width}, 32, '.apb multi-peripheral sideband protection multi-register back-to-back preserves data width policy');
    is($btb_multi_peripheral_protection_mreg_alias->{report}{composition}{width_policy}{strobe_width}, 4, '.apb multi-peripheral sideband protection multi-register back-to-back preserves strobe width policy');
    is($btb_multi_peripheral_protection_mreg_alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', '.apb multi-peripheral sideband protection multi-register back-to-back preserves peripheral policy owner');
    is_deeply($btb_multi_peripheral_protection_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1)], '.apb multi-peripheral sideband protection multi-register back-to-back preserves status reg0/reg1 storage');
    is_deeply($btb_multi_peripheral_protection_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], '.apb multi-peripheral sideband protection multi-register back-to-back preserves control reg0/reg1 storage');
    is($btb_multi_peripheral_protection_mreg_alias->{report}{children}[2]{bindings}{storage}{registers}[1]{address}{value}, 4, '.apb multi-peripheral sideband protection multi-register back-to-back preserves status reg1 address');
    is($btb_multi_peripheral_protection_mreg_alias->{report}{children}[3]{protection_policy}{registers}[1]{write}{predicate}{value}, 1, '.apb multi-peripheral sideband protection multi-register back-to-back preserves control reg1 write policy');
    like($btb_multi_peripheral_protection_mreg_top, qr/\(queued_wdata 32\)/, '.apb multi-peripheral sideband protection multi-register back-to-back top embeds 32-bit queued data');
    like($btb_multi_peripheral_protection_mreg_top, qr/\(\?\(& \(! write_q\) \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, '.apb multi-peripheral sideband protection multi-register back-to-back top embeds denied protected reg1 read branch');
    like($btb_multi_peripheral_protection_mreg_interconnect, qr/\(PSTRB_CONTROL 4\)/, '.apb multi-peripheral sideband protection multi-register back-to-back interconnect keeps 4-bit control PSTRB');
    like($btb_multi_peripheral_protection_mreg_interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, '.apb multi-peripheral sideband protection multi-register back-to-back interconnect fans out PPROT');
    like($btb_multi_peripheral_protection_mreg_interconnect, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, '.apb multi-peripheral sideband protection multi-register back-to-back interconnect fans out PSTRB');
    like($btb_multi_peripheral_protection_mreg_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, '.apb multi-peripheral sideband protection multi-register back-to-back interconnect uses the 256-byte control window base');
    unlike($btb_multi_peripheral_protection_mreg_interconnect, qr/prot_q/, '.apb multi-peripheral sideband protection multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_protection_generalized_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_alias_path());
    my $btb_multi_peripheral_protection_generalized_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_protection_generalized_mreg_interconnect = $btb_multi_peripheral_protection_generalized_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    my $btb_multi_peripheral_protection_generalized_mreg_top = $btb_multi_peripheral_protection_generalized_mreg_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    is($btb_multi_peripheral_protection_generalized_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb generalized multi-peripheral sideband protection multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_protection_generalized_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb generalized multi-peripheral sideband protection multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_protection_generalized_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_protection_generalized_mreg_ppif->{generated_ial1}{items}, '.apb generalized multi-peripheral sideband protection multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_protection_generalized_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_protection_generalized_mreg_ppif->{generated_ial0}{files}, '.apb generalized multi-peripheral sideband protection multi-register back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_protection_generalized_mreg_alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', '.apb generalized multi-peripheral sideband protection multi-register back-to-back preserves peripheral policy owner');
    is_deeply($btb_multi_peripheral_protection_generalized_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2)], '.apb generalized multi-peripheral sideband protection multi-register back-to-back preserves status reg0/reg1/reg2 storage');
    is_deeply($btb_multi_peripheral_protection_generalized_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], '.apb generalized multi-peripheral sideband protection multi-register back-to-back preserves control reg0/reg1/reg2 storage');
    is($btb_multi_peripheral_protection_generalized_mreg_alias->{report}{children}[2]{protection_policy}{registers}[2]{read}{predicate}{value}, 1, '.apb generalized multi-peripheral sideband protection multi-register back-to-back preserves status reg2 read policy');
    is($btb_multi_peripheral_protection_generalized_mreg_alias->{report}{children}[3]{protection_policy}{registers}[2]{write}{predicate}{value}, 1, '.apb generalized multi-peripheral sideband protection multi-register back-to-back preserves control reg2 write policy');
    like($btb_multi_peripheral_protection_generalized_mreg_top, qr/\(status_reg2_data_q 32 \(reset 0\)\)/, '.apb generalized multi-peripheral sideband protection multi-register back-to-back top embeds status reg2 storage');
    like($btb_multi_peripheral_protection_generalized_mreg_top, qr/\(\?\(& \(! write_q\) \(== addr 8\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, '.apb generalized multi-peripheral sideband protection multi-register back-to-back top embeds denied protected reg2 read branch');
    like($btb_multi_peripheral_protection_generalized_mreg_interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, '.apb generalized multi-peripheral sideband protection multi-register back-to-back interconnect fans out PPROT');
    unlike($btb_multi_peripheral_protection_generalized_mreg_interconnect, qr/prot_q/, '.apb generalized multi-peripheral sideband protection multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_protection_generalized_five_register_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back_alias_path());
    my $btb_multi_peripheral_protection_generalized_five_register_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_protection_generalized_five_register_mreg_interconnect = $btb_multi_peripheral_protection_generalized_five_register_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    my $btb_multi_peripheral_protection_generalized_five_register_mreg_top = $btb_multi_peripheral_protection_generalized_five_register_mreg_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    is($btb_multi_peripheral_protection_generalized_five_register_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_protection_generalized_five_register_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_protection_generalized_five_register_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_protection_generalized_five_register_mreg_ppif->{generated_ial1}{items}, '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_protection_generalized_five_register_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_protection_generalized_five_register_mreg_ppif->{generated_ial0}{files}, '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_protection_generalized_five_register_mreg_alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back preserves peripheral policy owner');
    is_deeply($btb_multi_peripheral_protection_generalized_five_register_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4)], '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back preserves status reg0..reg4 storage');
    is_deeply($btb_multi_peripheral_protection_generalized_five_register_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4)], '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back preserves control reg0..reg4 storage');
    is($btb_multi_peripheral_protection_generalized_five_register_mreg_alias->{report}{children}[2]{protection_policy}{registers}[4]{read}{predicate}{value}, 1, '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back preserves status reg4 read policy');
    is($btb_multi_peripheral_protection_generalized_five_register_mreg_alias->{report}{children}[3]{protection_policy}{registers}[4]{write}{predicate}{value}, 1, '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back preserves control reg4 write policy');
    like($btb_multi_peripheral_protection_generalized_five_register_mreg_top, qr/\(status_reg4_data_q 32 \(reset 0\)\)/, '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back top embeds status reg4 storage');
    like($btb_multi_peripheral_protection_generalized_five_register_mreg_top, qr/\(\?\(& \(! write_q\) \(== addr 16\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back top embeds denied protected reg4 read branch');
    like($btb_multi_peripheral_protection_generalized_five_register_mreg_interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back interconnect fans out PPROT');
    unlike($btb_multi_peripheral_protection_generalized_five_register_mreg_interconnect, qr/prot_q/, '.apb generalized five-register multi-peripheral sideband protection multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_data16_no_policy_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_alias_path());
    my $btb_multi_peripheral_data16_no_policy_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_data16_no_policy_mreg_interconnect = $btb_multi_peripheral_data16_no_policy_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    is($btb_multi_peripheral_data16_no_policy_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_data16_no_policy_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_data16_no_policy_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_data16_no_policy_mreg_ppif->{generated_ial1}{items}, '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_data16_no_policy_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_data16_no_policy_mreg_ppif->{generated_ial0}{files}, '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_data16_no_policy_mreg_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back preserves aggregate interconnect policy');
    is($btb_multi_peripheral_data16_no_policy_mreg_alias->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back preserves queue-depth 1 requester policy');
    is($btb_multi_peripheral_data16_no_policy_mreg_alias->{report}{composition}{width_policy}{data_width}, 16, '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back preserves data width policy');
    is($btb_multi_peripheral_data16_no_policy_mreg_alias->{report}{composition}{width_policy}{strobe_width}, 2, '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back preserves strobe width policy');
    is_deeply($btb_multi_peripheral_data16_no_policy_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1)], '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back preserves status reg0/reg1 storage');
    is_deeply($btb_multi_peripheral_data16_no_policy_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back preserves control reg0/reg1 storage');
    like($btb_multi_peripheral_data16_no_policy_mreg_interconnect, qr/\(PSTRB_CONTROL 2\)/, '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back interconnect keeps 2-bit control PSTRB');
    like($btb_multi_peripheral_data16_no_policy_mreg_interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back interconnect fans out PPROT');
    like($btb_multi_peripheral_data16_no_policy_mreg_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back interconnect uses the 258-byte control window base');
    unlike($btb_multi_peripheral_data16_no_policy_mreg_interconnect, qr/prot_q/, '.apb multi-peripheral sideband data16 no-policy multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_data16_generalized_no_policy_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_alias_path());
    my $btb_multi_peripheral_data16_generalized_no_policy_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_data16_generalized_no_policy_mreg_top = $btb_multi_peripheral_data16_generalized_no_policy_mreg_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    is($btb_multi_peripheral_data16_generalized_no_policy_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_data16_generalized_no_policy_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_data16_generalized_no_policy_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_data16_generalized_no_policy_mreg_ppif->{generated_ial1}{items}, '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_data16_generalized_no_policy_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_data16_generalized_no_policy_mreg_ppif->{generated_ial0}{files}, '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_data16_generalized_no_policy_mreg_alias->{report}{composition}{width_policy}{data_width}, 16, '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back preserves data width policy');
    is($btb_multi_peripheral_data16_generalized_no_policy_mreg_alias->{report}{composition}{width_policy}{strobe_width}, 2, '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back preserves strobe width policy');
    is_deeply($btb_multi_peripheral_data16_generalized_no_policy_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2)], '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back preserves status reg0/reg1/reg2 storage');
    is_deeply($btb_multi_peripheral_data16_generalized_no_policy_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back preserves control reg0/reg1/reg2 storage');
    is($btb_multi_peripheral_data16_generalized_no_policy_mreg_alias->{report}{children}[2]{bindings}{storage}{registers}[2]{address}{value}, 4, '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back preserves status reg2 address');
    is($btb_multi_peripheral_data16_generalized_no_policy_mreg_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back preserves aggregate interconnect policy');
    like($btb_multi_peripheral_data16_generalized_no_policy_mreg_top, qr/\(status_reg2_data_q 16 \(reset 0\)\)/, '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back top embeds status reg2 storage');
    like($btb_multi_peripheral_data16_generalized_no_policy_mreg_top, qr/\(control_reg2_data_q 16 \(reset 0\)\)/, '.apb generalized multi-peripheral sideband data16 no-policy multi-register back-to-back top embeds control reg2 storage');

    my $btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back_alias_path());
    my $btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_top = $btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    my $btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_interconnect = $btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    is($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_ppif->{generated_ial1}{items}, '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_ppif->{generated_ial0}{files}, '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{report}{composition}{width_policy}{data_width}, 16, '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves data width policy');
    is($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{report}{composition}{width_policy}{strobe_width}, 2, '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves strobe width policy');
    is_deeply($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4)], '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves status reg0..reg4 storage');
    is_deeply($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4)], '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves control reg0..reg4 storage');
    is($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{report}{children}[2]{bindings}{storage}{registers}[4]{address}{value}, 8, '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves status reg4 address');
    is($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves aggregate interconnect policy');
    like($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_top, qr/\(status_reg4_data_q 16 \(reset 0\)\)/, '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back top embeds status reg4 storage');
    like($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_top, qr/\(control_reg4_data_q 16 \(reset 0\)\)/, '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back top embeds control reg4 storage');
    like($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back interconnect uses the 258-byte control window base');
    unlike($btb_multi_peripheral_data16_generalized_five_register_no_policy_mreg_interconnect, qr/prot_q/, '.apb generalized five-register multi-peripheral sideband data16 no-policy multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back_alias_path());
    my $btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_top = $btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    my $btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_interconnect = $btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    is($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_ppif->{generated_ial1}{items}, '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_ppif->{generated_ial0}{files}, '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{report}{composition}{width_policy}{data_width}, 16, '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves data width policy');
    is($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{report}{composition}{width_policy}{strobe_width}, 2, '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves strobe width policy');
    is_deeply($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4 reg5)], '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves status reg0..reg5 storage');
    is_deeply($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4 reg5)], '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves control reg0..reg5 storage');
    is($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{report}{children}[2]{bindings}{storage}{registers}[5]{address}{value}, 10, '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves status reg5 address');
    is($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back preserves aggregate interconnect policy');
    like($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_top, qr/\(status_reg5_data_q 16 \(reset 0\)\)/, '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back top embeds status reg5 storage');
    like($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_top, qr/\(control_reg5_data_q 16 \(reset 0\)\)/, '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back top embeds control reg5 storage');
    like($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back interconnect uses the 258-byte control window base');
    unlike($btb_multi_peripheral_data16_generalized_six_register_no_policy_mreg_interconnect, qr/prot_q/, '.apb generalized six-register multi-peripheral sideband data16 no-policy multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_data16_protection_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_alias_path());
    my $btb_multi_peripheral_data16_protection_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_data16_protection_mreg_interconnect = $btb_multi_peripheral_data16_protection_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    is($btb_multi_peripheral_data16_protection_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral sideband data16 protection multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_data16_protection_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral sideband data16 protection multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_data16_protection_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_data16_protection_mreg_ppif->{generated_ial1}{items}, '.apb multi-peripheral sideband data16 protection multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_data16_protection_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_data16_protection_mreg_ppif->{generated_ial0}{files}, '.apb multi-peripheral sideband data16 protection multi-register back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_data16_protection_mreg_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb multi-peripheral sideband data16 protection multi-register back-to-back preserves aggregate interconnect policy');
    is($btb_multi_peripheral_data16_protection_mreg_alias->{report}{composition}{width_policy}{data_width}, 16, '.apb multi-peripheral sideband data16 protection multi-register back-to-back preserves data width policy');
    is($btb_multi_peripheral_data16_protection_mreg_alias->{report}{composition}{width_policy}{strobe_width}, 2, '.apb multi-peripheral sideband data16 protection multi-register back-to-back preserves strobe width policy');
    is($btb_multi_peripheral_data16_protection_mreg_alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', '.apb multi-peripheral sideband data16 protection multi-register back-to-back preserves peripheral policy owner');
    is_deeply($btb_multi_peripheral_data16_protection_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1)], '.apb multi-peripheral sideband data16 protection multi-register back-to-back preserves status reg0/reg1 storage');
    is_deeply($btb_multi_peripheral_data16_protection_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1)], '.apb multi-peripheral sideband data16 protection multi-register back-to-back preserves control reg0/reg1 storage');
    like($btb_multi_peripheral_data16_protection_mreg_interconnect, qr/\(PSTRB_CONTROL 2\)/, '.apb multi-peripheral sideband data16 protection multi-register back-to-back interconnect keeps 2-bit control PSTRB');
    like($btb_multi_peripheral_data16_protection_mreg_interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, '.apb multi-peripheral sideband data16 protection multi-register back-to-back interconnect fans out PPROT');
    like($btb_multi_peripheral_data16_protection_mreg_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, '.apb multi-peripheral sideband data16 protection multi-register back-to-back interconnect uses the 258-byte control window base');
    unlike($btb_multi_peripheral_data16_protection_mreg_interconnect, qr/prot_q/, '.apb multi-peripheral sideband data16 protection multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_data16_protection_generalized_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back_alias_path());
    my $btb_multi_peripheral_data16_protection_generalized_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_data16_protection_generalized_mreg_top = $btb_multi_peripheral_data16_protection_generalized_mreg_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    my $btb_multi_peripheral_data16_protection_generalized_mreg_interconnect = $btb_multi_peripheral_data16_protection_generalized_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    is($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_data16_protection_generalized_mreg_ppif->{generated_ial1}{items}, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_data16_protection_generalized_mreg_ppif->{generated_ial0}{files}, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{report}{composition}{width_policy}{data_width}, 16, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back preserves data width policy');
    is($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{report}{composition}{width_policy}{strobe_width}, 2, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back preserves strobe width policy');
    is($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back preserves peripheral policy owner');
    is_deeply($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2)], '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back preserves status reg0/reg1/reg2 storage');
    is_deeply($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2)], '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back preserves control reg0/reg1/reg2 storage');
    is($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{report}{children}[2]{bindings}{storage}{registers}[2]{address}{value}, 4, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back preserves status reg2 address');
    is($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{report}{children}[2]{protection_policy}{registers}[2]{read}{predicate}{value}, 1, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back preserves status reg2 read policy');
    is($btb_multi_peripheral_data16_protection_generalized_mreg_alias->{report}{children}[3]{protection_policy}{registers}[2]{write}{predicate}{value}, 1, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back preserves control reg2 write policy');
    like($btb_multi_peripheral_data16_protection_generalized_mreg_top, qr/\(queued_wstrb 2\)/, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back top embeds queued 2-bit PSTRB');
    like($btb_multi_peripheral_data16_protection_generalized_mreg_top, qr/\(status_reg2_data_q 16 \(reset 0\)\)/, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back top embeds status reg2 storage');
    like($btb_multi_peripheral_data16_protection_generalized_mreg_top, qr/\(\?\(& \(! write_q\) \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back top embeds denied protected reg2 read branch');
    like($btb_multi_peripheral_data16_protection_generalized_mreg_interconnect, qr/\(PSTRB_CONTROL 2\)/, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back interconnect keeps 2-bit control PSTRB');
    like($btb_multi_peripheral_data16_protection_generalized_mreg_interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back interconnect fans out PPROT');
    like($btb_multi_peripheral_data16_protection_generalized_mreg_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back interconnect uses the 258-byte control window base');
    unlike($btb_multi_peripheral_data16_protection_generalized_mreg_interconnect, qr/prot_q/, '.apb generalized multi-peripheral sideband data16 protection multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back_alias_path());
    my $btb_multi_peripheral_data16_protection_generalized_five_register_mreg_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_data16_protection_generalized_five_register_mreg_top = $btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{generated_ial0}{files}{'apb_tb.fsm'};
    my $btb_multi_peripheral_data16_protection_generalized_five_register_mreg_interconnect = $btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    is($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{kind}, 'protocol_intent.apb_composition', '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{mode}, 'requester-multi-peripheral-composition', '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{generated_ial1}{items}, $btb_multi_peripheral_data16_protection_generalized_five_register_mreg_ppif->{generated_ial1}{items}, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{generated_ial0}{files}, $btb_multi_peripheral_data16_protection_generalized_five_register_mreg_ppif->{generated_ial0}{files}, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{report}{composition}{width_policy}{data_width}, 16, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back preserves data width policy');
    is($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{report}{composition}{width_policy}{strobe_width}, 2, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back preserves strobe width policy');
    is($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back preserves peripheral policy owner');
    is_deeply($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{report}{children}[2]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4)], '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back preserves status reg0..reg4 storage');
    is_deeply($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{report}{children}[3]{transfer}{registers}, [qw(reg0 reg1 reg2 reg3 reg4)], '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back preserves control reg0..reg4 storage');
    is($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{report}{children}[2]{bindings}{storage}{registers}[4]{address}{value}, 8, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back preserves status reg4 address');
    is($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{report}{children}[2]{protection_policy}{registers}[4]{read}{predicate}{value}, 1, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back preserves status reg4 read policy');
    is($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_alias->{report}{children}[3]{protection_policy}{registers}[4]{write}{predicate}{value}, 1, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back preserves control reg4 write policy');
    like($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_top, qr/\(queued_wstrb 2\)/, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back top embeds queued 2-bit PSTRB');
    like($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_top, qr/\(status_reg4_data_q 16 \(reset 0\)\)/, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back top embeds status reg4 storage');
    like($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_top, qr/\(control_reg4_data_q 16 \(reset 0\)\)/, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back top embeds control reg4 storage');
    like($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_top, qr/\(\?\(& \(! write_q\) \(== addr 8\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back top embeds denied protected reg4 read branch');
    like($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_interconnect, qr/\(PSTRB_CONTROL 2\)/, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back interconnect keeps 2-bit control PSTRB');
    like($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back interconnect fans out PPROT');
    like($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back interconnect uses the 258-byte control window base');
    unlike($btb_multi_peripheral_data16_protection_generalized_five_register_mreg_interconnect, qr/prot_q/, '.apb generalized five-register multi-peripheral sideband data16 protection multi-register back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_protection_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_alias_path());
    my $btb_multi_peripheral_protection_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_protection_interconnect = $btb_multi_peripheral_protection_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    is($btb_multi_peripheral_protection_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral sideband protection back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_protection_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral sideband protection back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_protection_alias->{generated_ial1}{items}, $btb_multi_peripheral_protection_ppif->{generated_ial1}{items}, '.apb multi-peripheral sideband protection back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_protection_alias->{generated_ial0}{files}, $btb_multi_peripheral_protection_ppif->{generated_ial0}{files}, '.apb multi-peripheral sideband protection back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_protection_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb multi-peripheral sideband protection back-to-back preserves aggregate interconnect policy');
    is($btb_multi_peripheral_protection_alias->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, '.apb multi-peripheral sideband protection back-to-back preserves queue-depth 1 requester policy');
    is($btb_multi_peripheral_protection_alias->{report}{composition}{width_policy}{data_width}, 32, '.apb multi-peripheral sideband protection back-to-back preserves data width policy');
    is($btb_multi_peripheral_protection_alias->{report}{composition}{width_policy}{strobe_width}, 4, '.apb multi-peripheral sideband protection back-to-back preserves strobe width policy');
    is($btb_multi_peripheral_protection_alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', '.apb multi-peripheral sideband protection back-to-back preserves peripheral policy owner');
    like($btb_multi_peripheral_protection_interconnect, qr/\(PSTRB_CONTROL 4\)/, '.apb multi-peripheral sideband protection back-to-back interconnect keeps 4-bit control PSTRB');
    like($btb_multi_peripheral_protection_interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, '.apb multi-peripheral sideband protection back-to-back interconnect fans out PPROT');
    like($btb_multi_peripheral_protection_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 256\)\) <\(& PSEL \(>= PADDR 256\) \(< PADDR 512\)\)\)/, '.apb multi-peripheral sideband protection back-to-back interconnect uses the 256-byte control window base');
    unlike($btb_multi_peripheral_protection_interconnect, qr/prot_q/, '.apb multi-peripheral sideband protection back-to-back interconnect remains enforcement-free');

    my $btb_multi_peripheral_data16_protection_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_alias_path());
    my $btb_multi_peripheral_data16_protection_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif_path());
    my $btb_multi_peripheral_data16_protection_interconnect = $btb_multi_peripheral_data16_protection_alias->{generated_ial0}{files}{'apb_interconnect.fsm'};
    is($btb_multi_peripheral_data16_protection_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral sideband data16 protection back-to-back parser result keeps APB composition kind');
    is($btb_multi_peripheral_data16_protection_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral sideband data16 protection back-to-back parser result preserves multi-peripheral mode');
    is_deeply($btb_multi_peripheral_data16_protection_alias->{generated_ial1}{items}, $btb_multi_peripheral_data16_protection_ppif->{generated_ial1}{items}, '.apb multi-peripheral sideband data16 protection back-to-back mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_multi_peripheral_data16_protection_alias->{generated_ial0}{files}, $btb_multi_peripheral_data16_protection_ppif->{generated_ial0}{files}, '.apb multi-peripheral sideband data16 protection back-to-back mirrors .ppif generated IAL0 files');
    is($btb_multi_peripheral_data16_protection_alias->{report}{back_to_back_policy}{interconnect}{timing_role}, 'propagate_queued_setup_without_idle_cycle', '.apb multi-peripheral sideband data16 protection back-to-back preserves aggregate interconnect policy');
    is($btb_multi_peripheral_data16_protection_alias->{report}{back_to_back_policy}{requester}{timing_policy}{queue_depth}, 1, '.apb multi-peripheral sideband data16 protection back-to-back preserves queue-depth 1 requester policy');
    is($btb_multi_peripheral_data16_protection_alias->{report}{composition}{width_policy}{data_width}, 16, '.apb multi-peripheral sideband data16 protection back-to-back preserves data width policy');
    is($btb_multi_peripheral_data16_protection_alias->{report}{composition}{width_policy}{strobe_width}, 2, '.apb multi-peripheral sideband data16 protection back-to-back preserves strobe width policy');
    is($btb_multi_peripheral_data16_protection_alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', '.apb multi-peripheral sideband data16 protection back-to-back preserves peripheral policy owner');
    like($btb_multi_peripheral_data16_protection_interconnect, qr/\(PSTRB_CONTROL 2\)/, '.apb multi-peripheral sideband data16 protection back-to-back interconnect keeps 2-bit control PSTRB');
    like($btb_multi_peripheral_data16_protection_interconnect, qr/\(<- \(PPROT_STATUS> PPROT\)\)/, '.apb multi-peripheral sideband data16 protection back-to-back interconnect fans out PPROT');
    like($btb_multi_peripheral_data16_protection_interconnect, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, '.apb multi-peripheral sideband data16 protection back-to-back interconnect uses the 258-byte control window base');
    unlike($btb_multi_peripheral_data16_protection_interconnect, qr/prot_q/, '.apb multi-peripheral sideband data16 protection back-to-back interconnect remains enforcement-free');

    my $multi_completer_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_alias_path());
    my $multi_completer_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_ppif_path());
    is($multi_completer_alias->{kind}, 'protocol_intent.apb_completer', '.apb multi-register completer parser result keeps APB completer kind');
    is($multi_completer_alias->{generated_ial1}{text}, $multi_completer_ppif->{generated_ial1}{text}, '.apb multi-register completer mirrors .ppif generated IAL1 text');
    is_deeply($multi_completer_alias->{generated_ial0}{files}, $multi_completer_ppif->{generated_ial0}{files}, '.apb multi-register completer mirrors .ppif generated IAL0 files');
    is_deeply($multi_completer_alias->{report}{transfer}{registers}, [qw(reg0 reg1)], '.apb multi-register completer preserves transfer register list');

    my $multi_composition_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_alias_path());
    my $multi_composition_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_ppif_path());
    is($multi_composition_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-register composition parser result keeps APB composition kind');
    is_deeply($multi_composition_alias->{generated_ial1}{items}, $multi_composition_ppif->{generated_ial1}{items}, '.apb multi-register composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($multi_composition_alias->{generated_ial0}{files}, $multi_composition_ppif->{generated_ial0}{files}, '.apb multi-register composition mirrors .ppif generated IAL0 files');
    is_deeply($multi_composition_alias->{report}{children}[1]{transfer}{registers}, [qw(reg0 reg1)], '.apb multi-register composition preserves completer register list');

    my $multi_peripheral_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_alias_path());
    my $multi_peripheral_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_ppif_path());
    is($multi_peripheral_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral composition parser result keeps APB composition kind');
    is($multi_peripheral_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral composition parser result records multi-peripheral mode');
    is_deeply($multi_peripheral_alias->{generated_ial1}{items}, $multi_peripheral_ppif->{generated_ial1}{items}, '.apb multi-peripheral composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($multi_peripheral_alias->{generated_ial0}{files}, $multi_peripheral_ppif->{generated_ial0}{files}, '.apb multi-peripheral composition mirrors .ppif generated IAL0 files');
    is($multi_peripheral_alias->{report}{composition}{topology}, 'multi_peripheral_interconnect', '.apb multi-peripheral composition preserves topology');
    is($multi_peripheral_alias->{report}{composition}{peripherals}[0]{generated_instance_name}, 'status_peripheral', '.apb multi-peripheral composition preserves generated status instance alias');

    my $requester_sideband_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_sideband_path());
    my $requester_sideband_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ppif_sideband_path());
    is($requester_sideband_alias->{kind}, 'protocol_intent.apb_requester_transfer', '.apb requester sideband parser result keeps APB requester-transfer kind');
    is($requester_sideband_alias->{generated_ial1}{text}, $requester_sideband_ppif->{generated_ial1}{text}, '.apb requester sideband mirrors .ppif generated IAL1 text');
    is_deeply($requester_sideband_alias->{generated_ial0}{files}, $requester_sideband_ppif->{generated_ial0}{files}, '.apb requester sideband mirrors .ppif generated IAL0 files');
    like($requester_sideband_alias->{generated_ial0}{files}{'apb_requester.fsm'}, qr/\(<- \(PSTRB> \(& wstrb \(concat is_write is_write is_write is_write\)\)\) <setup_phase_start\)/, '.apb requester sideband masks PSTRB with the sampled write bit');

    my $requester_sideband_data16_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_sideband_data16_path());
    my $requester_sideband_data16_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ppif_sideband_data16_path());
    is($requester_sideband_data16_alias->{kind}, 'protocol_intent.apb_requester_transfer', '.apb requester sideband data16 parser result keeps APB requester-transfer kind');
    is($requester_sideband_data16_alias->{generated_ial1}{text}, $requester_sideband_data16_ppif->{generated_ial1}{text}, '.apb requester sideband data16 mirrors .ppif generated IAL1 text');
    is_deeply($requester_sideband_data16_alias->{generated_ial0}{files}, $requester_sideband_data16_ppif->{generated_ial0}{files}, '.apb requester sideband data16 mirrors .ppif generated IAL0 files');
    like($requester_sideband_data16_alias->{generated_ial0}{files}{'apb_requester.fsm'}, qr/\(<- \(PSTRB> \(& wstrb \(concat is_write is_write\)\)\) <setup_phase_start\)/, '.apb requester sideband data16 masks 2-bit PSTRB with the sampled write bit');
    is($requester_sideband_data16_alias->{report}{width_policy}{data_width}, 16, '.apb requester sideband data16 preserves data width policy');

    my $multi_completer_sideband_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_alias_path());
    my $multi_completer_sideband_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_ppif_path());
    is($multi_completer_sideband_alias->{kind}, 'protocol_intent.apb_completer', '.apb multi-register sideband completer parser result keeps APB completer kind');
    is($multi_completer_sideband_alias->{generated_ial1}{text}, $multi_completer_sideband_ppif->{generated_ial1}{text}, '.apb multi-register sideband completer mirrors .ppif generated IAL1 text');
    is_deeply($multi_completer_sideband_alias->{generated_ial0}{files}, $multi_completer_sideband_ppif->{generated_ial0}{files}, '.apb multi-register sideband completer mirrors .ppif generated IAL0 files');
    like($multi_completer_sideband_alias->{generated_ial0}{files}{'apb_completer.fsm'}, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, '.apb multi-register sideband completer preserves byte-lane write lowering');

    my $multi_completer_sideband_protection_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_protection_alias_path());
    my $multi_completer_sideband_protection_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_protection_ppif_path());
    is($multi_completer_sideband_protection_alias->{kind}, 'protocol_intent.apb_completer', '.apb multi-register sideband protection completer parser result keeps APB completer kind');
    is($multi_completer_sideband_protection_alias->{generated_ial1}{text}, $multi_completer_sideband_protection_ppif->{generated_ial1}{text}, '.apb multi-register sideband protection completer mirrors .ppif generated IAL1 text');
    is_deeply($multi_completer_sideband_protection_alias->{generated_ial0}{files}, $multi_completer_sideband_protection_ppif->{generated_ial0}{files}, '.apb multi-register sideband protection completer mirrors .ppif generated IAL0 files');
    is($multi_completer_sideband_protection_alias->{report}{protection_policy}{predicate_namespace}, 'fsmgen_apb_pprot_v1', '.apb multi-register sideband protection completer preserves policy metadata');

    my $btb_sideband_protection_completer_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_protection_back_to_back_alias_path());
    my $btb_sideband_protection_completer_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_protection_back_to_back_ppif_path());
    is($btb_sideband_protection_completer_alias->{kind}, 'protocol_intent.apb_completer', '.apb sideband protection back-to-back completer parser result keeps APB completer kind');
    is($btb_sideband_protection_completer_alias->{generated_ial1}{text}, $btb_sideband_protection_completer_ppif->{generated_ial1}{text}, '.apb sideband protection back-to-back completer mirrors .ppif generated IAL1 text');
    is_deeply($btb_sideband_protection_completer_alias->{generated_ial0}{files}, $btb_sideband_protection_completer_ppif->{generated_ial0}{files}, '.apb sideband protection back-to-back completer mirrors .ppif generated IAL0 files');
    is($btb_sideband_protection_completer_alias->{report}{transfer}{timing_policy}{setup_admission}, 'adjacent', '.apb sideband protection back-to-back completer preserves adjacent setup admission policy');
    is($btb_sideband_protection_completer_alias->{report}{protection_policy}{predicate_namespace}, 'fsmgen_apb_pprot_v1', '.apb sideband protection back-to-back completer preserves policy metadata');

    my $multi_completer_sideband_data16_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_alias_path());
    my $multi_completer_sideband_data16_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_ppif_path());
    is($multi_completer_sideband_data16_alias->{kind}, 'protocol_intent.apb_completer', '.apb multi-register sideband data16 completer parser result keeps APB completer kind');
    is($multi_completer_sideband_data16_alias->{generated_ial1}{text}, $multi_completer_sideband_data16_ppif->{generated_ial1}{text}, '.apb multi-register sideband data16 completer mirrors .ppif generated IAL1 text');
    is_deeply($multi_completer_sideband_data16_alias->{generated_ial0}{files}, $multi_completer_sideband_data16_ppif->{generated_ial0}{files}, '.apb multi-register sideband data16 completer mirrors .ppif generated IAL0 files');
    like($multi_completer_sideband_data16_alias->{generated_ial0}{files}{'apb_completer.fsm'}, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, '.apb multi-register sideband data16 completer preserves two-lane byte write lowering');
    is($multi_completer_sideband_data16_alias->{report}{width_policy}{strobe_width}, 2, '.apb multi-register sideband data16 completer preserves strobe width policy');

    my $multi_completer_sideband_data16_protection_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_protection_alias_path());
    my $multi_completer_sideband_data16_protection_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_protection_ppif_path());
    is($multi_completer_sideband_data16_protection_alias->{kind}, 'protocol_intent.apb_completer', '.apb multi-register sideband data16 protection completer parser result keeps APB completer kind');
    is($multi_completer_sideband_data16_protection_alias->{generated_ial1}{text}, $multi_completer_sideband_data16_protection_ppif->{generated_ial1}{text}, '.apb multi-register sideband data16 protection completer mirrors .ppif generated IAL1 text');
    is_deeply($multi_completer_sideband_data16_protection_alias->{generated_ial0}{files}, $multi_completer_sideband_data16_protection_ppif->{generated_ial0}{files}, '.apb multi-register sideband data16 protection completer mirrors .ppif generated IAL0 files');
    like($multi_completer_sideband_data16_protection_alias->{generated_ial0}{files}{'apb_completer.fsm'}, qr/\(\?\(& \(! write_q\) \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, '.apb multi-register sideband data16 protection completer preserves denied data16 read branch');
    is($multi_completer_sideband_data16_protection_alias->{report}{protection_policy}{predicate_namespace}, 'fsmgen_apb_pprot_v1', '.apb multi-register sideband data16 protection completer preserves policy metadata');

    my $multi_composition_sideband_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_alias_path());
    my $multi_composition_sideband_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_ppif_path());
    is($multi_composition_sideband_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-register sideband composition parser result keeps APB composition kind');
    is_deeply($multi_composition_sideband_alias->{generated_ial1}{items}, $multi_composition_sideband_ppif->{generated_ial1}{items}, '.apb multi-register sideband composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($multi_composition_sideband_alias->{generated_ial0}{files}, $multi_composition_sideband_ppif->{generated_ial0}{files}, '.apb multi-register sideband composition mirrors .ppif generated IAL0 files');
    like($multi_composition_sideband_alias->{generated_ial0}{files}{'apb_tb.fsm'}, qr/\(requester\.PSTRB completer\.PSTRB\)/, '.apb multi-register sideband composition wires requester PSTRB to completer PSTRB');

    my $multi_composition_sideband_protection_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_protection_alias_path());
    my $multi_composition_sideband_protection_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_protection_ppif_path());
    is($multi_composition_sideband_protection_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-register sideband protection composition parser result keeps APB composition kind');
    is_deeply($multi_composition_sideband_protection_alias->{generated_ial1}{items}, $multi_composition_sideband_protection_ppif->{generated_ial1}{items}, '.apb multi-register sideband protection composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($multi_composition_sideband_protection_alias->{generated_ial0}{files}, $multi_composition_sideband_protection_ppif->{generated_ial0}{files}, '.apb multi-register sideband protection composition mirrors .ppif generated IAL0 files');
    is($multi_composition_sideband_protection_alias->{report}{protection_policy}{enforcement_owner}, 'completer', '.apb multi-register sideband protection composition preserves completer policy owner');

    my $btb_sideband_protection_composition_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_protection_status_back_to_back_alias_path());
    my $btb_sideband_protection_composition_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif_path());
    is($btb_sideband_protection_composition_alias->{kind}, 'protocol_intent.apb_composition', '.apb sideband protection fixed back-to-back composition parser result keeps APB composition kind');
    is_deeply($btb_sideband_protection_composition_alias->{generated_ial1}{items}, $btb_sideband_protection_composition_ppif->{generated_ial1}{items}, '.apb sideband protection fixed back-to-back composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($btb_sideband_protection_composition_alias->{generated_ial0}{files}, $btb_sideband_protection_composition_ppif->{generated_ial0}{files}, '.apb sideband protection fixed back-to-back composition mirrors .ppif generated IAL0 files');
    is($btb_sideband_protection_composition_alias->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', '.apb sideband protection fixed back-to-back composition preserves aggregate completer timing policy');
    is($btb_sideband_protection_composition_alias->{report}{protection_policy}{enforcement_owner}, 'completer', '.apb sideband protection fixed back-to-back composition preserves completer policy owner');

    my $multi_composition_sideband_data16_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_alias_path());
    my $multi_composition_sideband_data16_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_ppif_path());
    is($multi_composition_sideband_data16_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-register sideband data16 composition parser result keeps APB composition kind');
    is_deeply($multi_composition_sideband_data16_alias->{generated_ial1}{items}, $multi_composition_sideband_data16_ppif->{generated_ial1}{items}, '.apb multi-register sideband data16 composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($multi_composition_sideband_data16_alias->{generated_ial0}{files}, $multi_composition_sideband_data16_ppif->{generated_ial0}{files}, '.apb multi-register sideband data16 composition mirrors .ppif generated IAL0 files');
    like($multi_composition_sideband_data16_alias->{generated_ial0}{files}{'apb_tb.fsm'}, qr/=req_wstrb<2/, '.apb multi-register sideband data16 composition exposes 2-bit requester strobe');
    is($multi_composition_sideband_data16_alias->{report}{composition}{width_policy}{data_width}, 16, '.apb multi-register sideband data16 composition preserves data width policy');

    my $multi_composition_sideband_data16_protection_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_protection_alias_path());
    my $multi_composition_sideband_data16_protection_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_register_sideband_data16_protection_ppif_path());
    is($multi_composition_sideband_data16_protection_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-register sideband data16 protection composition parser result keeps APB composition kind');
    is_deeply($multi_composition_sideband_data16_protection_alias->{generated_ial1}{items}, $multi_composition_sideband_data16_protection_ppif->{generated_ial1}{items}, '.apb multi-register sideband data16 protection composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($multi_composition_sideband_data16_protection_alias->{generated_ial0}{files}, $multi_composition_sideband_data16_protection_ppif->{generated_ial0}{files}, '.apb multi-register sideband data16 protection composition mirrors .ppif generated IAL0 files');
    like($multi_composition_sideband_data16_protection_alias->{generated_ial0}{files}{'apb_tb.fsm'}, qr/\(\?\(& write_q \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, '.apb multi-register sideband data16 protection composition embeds denied reg1 write branch');
    is($multi_composition_sideband_data16_protection_alias->{report}{protection_policy}{enforcement_owner}, 'completer', '.apb multi-register sideband data16 protection composition preserves policy owner');

    my $multi_peripheral_sideband_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_alias_path());
    my $multi_peripheral_sideband_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_ppif_path());
    is($multi_peripheral_sideband_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral sideband composition parser result keeps APB composition kind');
    is($multi_peripheral_sideband_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral sideband composition parser result records multi-peripheral mode');
    is_deeply($multi_peripheral_sideband_alias->{generated_ial1}{items}, $multi_peripheral_sideband_ppif->{generated_ial1}{items}, '.apb multi-peripheral sideband composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($multi_peripheral_sideband_alias->{generated_ial0}{files}, $multi_peripheral_sideband_ppif->{generated_ial0}{files}, '.apb multi-peripheral sideband composition mirrors .ppif generated IAL0 files');
    like($multi_peripheral_sideband_alias->{generated_ial0}{files}{'apb_interconnect.fsm'}, qr/\(<- \(PSTRB_CONTROL> PSTRB\)\)/, '.apb multi-peripheral sideband composition interconnect fans out PSTRB to the control window');

    my $multi_peripheral_sideband_protection_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_protection_alias_path());
    my $multi_peripheral_sideband_protection_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_protection_ppif_path());
    is($multi_peripheral_sideband_protection_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral sideband protection composition parser result keeps APB composition kind');
    is($multi_peripheral_sideband_protection_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral sideband protection composition parser result records multi-peripheral mode');
    is_deeply($multi_peripheral_sideband_protection_alias->{generated_ial1}{items}, $multi_peripheral_sideband_protection_ppif->{generated_ial1}{items}, '.apb multi-peripheral sideband protection composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($multi_peripheral_sideband_protection_alias->{generated_ial0}{files}, $multi_peripheral_sideband_protection_ppif->{generated_ial0}{files}, '.apb multi-peripheral sideband protection composition mirrors .ppif generated IAL0 files');
    is($multi_peripheral_sideband_protection_alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', '.apb multi-peripheral sideband protection composition preserves peripheral policy owner');

    my $multi_peripheral_sideband_data16_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_alias_path());
    my $multi_peripheral_sideband_data16_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_ppif_path());
    is($multi_peripheral_sideband_data16_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral sideband data16 composition parser result keeps APB composition kind');
    is($multi_peripheral_sideband_data16_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral sideband data16 composition parser result records multi-peripheral mode');
    is_deeply($multi_peripheral_sideband_data16_alias->{generated_ial1}{items}, $multi_peripheral_sideband_data16_ppif->{generated_ial1}{items}, '.apb multi-peripheral sideband data16 composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($multi_peripheral_sideband_data16_alias->{generated_ial0}{files}, $multi_peripheral_sideband_data16_ppif->{generated_ial0}{files}, '.apb multi-peripheral sideband data16 composition mirrors .ppif generated IAL0 files');
    like($multi_peripheral_sideband_data16_alias->{generated_ial0}{files}{'apb_interconnect.fsm'}, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, '.apb multi-peripheral sideband data16 composition interconnect uses the 258-byte control window base');
    is($multi_peripheral_sideband_data16_alias->{report}{composition}{address_map}{alignment_bytes}, 2, '.apb multi-peripheral sideband data16 composition preserves 2-byte address-map alignment');

    my $multi_peripheral_sideband_data16_protection_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_protection_alias_path());
    my $multi_peripheral_sideband_data16_protection_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_multi_peripheral_sideband_data16_protection_ppif_path());
    is($multi_peripheral_sideband_data16_protection_alias->{kind}, 'protocol_intent.apb_composition', '.apb multi-peripheral sideband data16 protection composition parser result keeps APB composition kind');
    is($multi_peripheral_sideband_data16_protection_alias->{mode}, 'requester-multi-peripheral-composition', '.apb multi-peripheral sideband data16 protection composition parser result records multi-peripheral mode');
    is_deeply($multi_peripheral_sideband_data16_protection_alias->{generated_ial1}{items}, $multi_peripheral_sideband_data16_protection_ppif->{generated_ial1}{items}, '.apb multi-peripheral sideband data16 protection composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($multi_peripheral_sideband_data16_protection_alias->{generated_ial0}{files}, $multi_peripheral_sideband_data16_protection_ppif->{generated_ial0}{files}, '.apb multi-peripheral sideband data16 protection composition mirrors .ppif generated IAL0 files');
    like($multi_peripheral_sideband_data16_protection_alias->{generated_ial0}{files}{'apb_interconnect.fsm'}, qr/\(<- \(PADDR_CONTROL> \(- PADDR 258\)\) <\(& PSEL \(>= PADDR 258\) \(< PADDR 516\)\)\)/, '.apb multi-peripheral sideband data16 protection composition interconnect uses the 258-byte control window base');
    is($multi_peripheral_sideband_data16_protection_alias->{report}{protection_policy}{enforcement_owner}, 'peripheral_completers', '.apb multi-peripheral sideband data16 protection composition preserves peripheral policy owner');
};

subtest 'adapter rejects .apb profile and behavior boundaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $missing_profile_path = File::Spec->catfile($tempdir, 'missing_profile.apb');
    my $missing_profile_source = slurp(sample_ppif_path());
    $missing_profile_source =~ s/^\s*\(profile apb\)\n//m;
    write_file($missing_profile_path, $missing_profile_source);
    my $missing_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_profile_path); 1 };
    ok(!$missing_ok, '.apb without explicit profile is rejected');
    like(
        $@,
        qr/\.apb source '.*missing_profile\.apb' is missing required \(profile \.\.\.\) clause/,
        '.apb missing-profile diagnostic is targeted',
    );

    my $mismatch_path = File::Spec->catfile($tempdir, 'valid_ready_profile.apb');
    write_file($mismatch_path, slurp(sample_valid_ready_handshake_ppif_path()));
    my $mismatch_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mismatch_path); 1 };
    ok(!$mismatch_ok, '.apb with a non-APB profile is rejected');
    like(
        $@,
        qr/profile 'valid-ready' does not match \.apb profile alias; expected apb/,
        '.apb suffix/profile mismatch diagnostic is targeted',
    );

    my $status_path = File::Spec->catfile($tempdir, 'status_response.apb');
    my $status_source = slurp(sample_apb_busy_path());
    $status_source =~ s/\s+\(busy busy\)\n/      (status status width 2)\n/;
    write_file($status_path, $status_source);
    my $status_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($status_path); 1 };
    ok(!$status_ok, '.apb requester response status without busy is rejected');
    like(
        $@,
        qr/status field requires \(busy NAME\) in this slice/,
        '.apb response status diagnostic requires the busy gate',
    );

    my $status_width_path = File::Spec->catfile($tempdir, 'status_width.apb');
    my $status_width_source = slurp(sample_apb_busy_path());
    $status_width_source =~ s/\(busy busy\)/(busy busy)\n      (status status width 3)/;
    write_file($status_width_path, $status_width_source);
    my $status_width_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($status_width_path); 1 };
    ok(!$status_width_ok, '.apb requester response status width other than 2 is rejected');
    like(
        $@,
        qr/status width must be 2 in this slice/,
        '.apb response status diagnostic pins the selected 2-bit width',
    );

    my $accepted_without_policy_path = File::Spec->catfile($tempdir, 'accepted_without_policy.apb');
    my $accepted_without_policy_source = slurp(sample_apb_status_back_to_back_path());
    $accepted_without_policy_source =~ s/\n      \(timing-policy\n        \(back-to-back queued\)\n        \(queue-depth 1\)\n        \(overflow reject\)\)//;
    write_file($accepted_without_policy_path, $accepted_without_policy_source);
    my $accepted_without_policy_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($accepted_without_policy_path); 1 };
    ok(!$accepted_without_policy_ok, '.apb requester accepted without selected timing policy is rejected');
    like(
        $@,
        qr/response\.accepted requires selected transfer\.timing_policy/,
        '.apb accepted-without-policy diagnostic is targeted',
    );

    my $bad_queue_depth_path = File::Spec->catfile($tempdir, 'bad_queue_depth.apb');
    my $bad_queue_depth_source = slurp(sample_apb_status_back_to_back_path());
    $bad_queue_depth_source =~ s/\(queue-depth 1\)/(queue-depth 2)/;
    write_file($bad_queue_depth_path, $bad_queue_depth_source);
    my $bad_queue_depth_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($bad_queue_depth_path); 1 };
    ok(!$bad_queue_depth_ok, '.apb requester queue-depth other than 1 is rejected');
    like(
        $@,
        qr/timing-policy supports only \(queue-depth 1\) in this slice/,
        '.apb queue-depth diagnostic is targeted',
    );

    my $unsupported_object_path = File::Spec->catfile($tempdir, 'valid_ready_object.apb');
    my $unsupported_object_source = slurp(sample_valid_ready_handshake_ppif_path());
    $unsupported_object_source =~ s/\(profile valid-ready\)/(profile apb)/;
    write_file($unsupported_object_path, $unsupported_object_source);
    my $unsupported_object_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($unsupported_object_path); 1 };
    ok(!$unsupported_object_ok, '.apb valid-ready object remains outside the first alias slice');
    like(
        $@,
        qr/profile apb requires exactly one \(apb-requester \.\.\.\), one \(apb-completer \.\.\.\), the explicit one-requester\/one-completer\/one-composition shape, or the selected one-requester\/multi-peripheral APB composition shape in this slice/,
        '.apb unsupported object diagnostic is targeted',
    );
};

subtest 'CLI check and semantic JSON report APB completer .apb public source identity' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', sample_apb_completer_alias_path()],
    );
    ok($success, '--check --json succeeds for APB completer .apb');
    is(join('', @{$stderr_buf || []}), '', '--check --json keeps stderr clean for APB completer .apb');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'APB completer .apb check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs(sample_apb_completer_alias_path()), 'APB completer .apb check JSON reports the public alias source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.apb_profile_alias_completer', 'APB completer .apb check JSON names the profile-alias corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ial2_profile_alias', 'APB completer .apb check JSON records profile-alias source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', sample_apb_completer_alias_path()],
    );
    ok($semantic_success, '--emit-semantic-json succeeds for APB completer .apb');
    is(join('', @{$semantic_stderr || []}), '', '--emit-semantic-json keeps stderr clean for APB completer .apb');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'APB completer .apb semantic JSON reports success');
    is($semantic_report->{source}{resolved_path}, File::Spec->rel2abs(sample_apb_completer_alias_path()), 'APB completer .apb semantic JSON reports the public alias source path');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.apb_profile_alias_completer', 'APB completer .apb semantic JSON names the profile-alias corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'fsm', 'APB completer .apb semantic JSON payload describes the generated .fsm semantic root');
    is($semantic_report->{semantic}{module}{name}, 'apb_completer', 'APB completer .apb semantic JSON records the generated module');
};

subtest 'CLI check and semantic JSON report APB composition .apb public source identity' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', sample_apb_composition_alias_path()],
    );
    ok($success, '--check --json succeeds for APB composition .apb');
    is(join('', @{$stderr_buf || []}), '', '--check --json keeps stderr clean for APB composition .apb');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'APB composition .apb check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs(sample_apb_composition_alias_path()), 'APB composition .apb check JSON reports the public alias source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.apb_profile_alias_composition', 'APB composition .apb check JSON names the profile-alias corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ial2_profile_alias', 'APB composition .apb check JSON records profile-alias source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', sample_apb_composition_alias_path()],
    );
    ok($semantic_success, '--emit-semantic-json succeeds for APB composition .apb');
    is(join('', @{$semantic_stderr || []}), '', '--emit-semantic-json keeps stderr clean for APB composition .apb');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'APB composition .apb semantic JSON reports success');
    is($semantic_report->{source}{resolved_path}, File::Spec->rel2abs(sample_apb_composition_alias_path()), 'APB composition .apb semantic JSON reports the public alias source path');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.apb_profile_alias_composition', 'APB composition .apb semantic JSON names the profile-alias corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'top', 'APB composition .apb semantic JSON payload describes the generated top semantic root');
    is($semantic_report->{semantic}{module}{name}, 'apb_tb', 'APB composition .apb semantic JSON records the generated top module');
};

subtest 'CLI check and semantic JSON report APB multi-register .apb public source identity' => sub {
    my @cases = (
        {
            label => 'APB multi-register completer',
            path => sample_apb_completer_multi_register_alias_path(),
            entry_id => 'intent.apb_profile_alias_completer_multi_register',
            source_root_kind => 'fsm',
            module => 'apb_completer',
        },
        {
            label => 'APB multi-register composition',
            path => sample_apb_composition_multi_register_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_register',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral composition',
            path => sample_apb_composition_multi_peripheral_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB requester sideband',
            path => sample_apb_sideband_path(),
            entry_id => 'intent.apb_profile_alias_requester_transfer_sideband',
            source_root_kind => 'fsm',
            module => 'apb_requester',
        },
        {
            label => 'APB requester sideband status back-to-back',
            path => sample_apb_sideband_status_back_to_back_path(),
            entry_id => 'intent.apb_profile_alias_requester_transfer_sideband_status_back_to_back',
            source_root_kind => 'fsm',
            module => 'apb_requester',
        },
        {
            label => 'APB multi-register sideband completer',
            path => sample_apb_completer_multi_register_sideband_alias_path(),
            entry_id => 'intent.apb_profile_alias_completer_multi_register_sideband',
            source_root_kind => 'fsm',
            module => 'apb_completer',
        },
        {
            label => 'APB multi-register sideband back-to-back completer',
            path => sample_apb_completer_multi_register_sideband_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_completer_multi_register_sideband_back_to_back',
            source_root_kind => 'fsm',
            module => 'apb_completer',
        },
        {
            label => 'APB multi-register sideband protection completer',
            path => sample_apb_completer_multi_register_sideband_protection_alias_path(),
            entry_id => 'intent.apb_profile_alias_completer_multi_register_sideband_protection',
            source_root_kind => 'fsm',
            module => 'apb_completer',
        },
        {
            label => 'APB multi-register sideband protection back-to-back completer',
            path => sample_apb_completer_multi_register_sideband_protection_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_completer_multi_register_sideband_protection_back_to_back',
            source_root_kind => 'fsm',
            module => 'apb_completer',
        },
        {
            label => 'APB multi-register sideband composition',
            path => sample_apb_composition_multi_register_sideband_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_register_sideband',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-register sideband status back-to-back composition',
            path => sample_apb_composition_multi_register_sideband_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_register_sideband_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-register sideband protection composition',
            path => sample_apb_composition_multi_register_sideband_protection_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_register_sideband_protection',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-register sideband protection status back-to-back composition',
            path => sample_apb_composition_multi_register_sideband_protection_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_register_sideband_protection_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral sideband composition',
            path => sample_apb_composition_multi_peripheral_sideband_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_sideband',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral sideband protection composition',
            path => sample_apb_composition_multi_peripheral_sideband_protection_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_sideband_protection',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral sideband protection status back-to-back composition',
            path => sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_sideband_protection_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB requester sideband data16',
            path => sample_apb_sideband_data16_path(),
            entry_id => 'intent.apb_profile_alias_requester_transfer_sideband_data16',
            source_root_kind => 'fsm',
            module => 'apb_requester',
        },
        {
            label => 'APB requester sideband data16 status back-to-back',
            path => sample_apb_sideband_data16_status_back_to_back_path(),
            entry_id => 'intent.apb_profile_alias_requester_transfer_sideband_data16_status_back_to_back',
            source_root_kind => 'fsm',
            module => 'apb_requester',
        },
        {
            label => 'APB requester status back-to-back',
            path => sample_apb_status_back_to_back_path(),
            entry_id => 'intent.apb_profile_alias_requester_transfer_status_back_to_back',
            source_root_kind => 'fsm',
            module => 'apb_requester',
        },
        {
            label => 'APB completer back-to-back',
            path => sample_apb_completer_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_completer_back_to_back',
            source_root_kind => 'fsm',
            module => 'apb_completer',
        },
        {
            label => 'APB sideband back-to-back completer',
            path => sample_apb_completer_sideband_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_completer_sideband_back_to_back',
            source_root_kind => 'fsm',
            module => 'apb_completer',
        },
        {
            label => 'APB composition status back-to-back',
            path => sample_apb_composition_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB sideband status back-to-back composition',
            path => sample_apb_composition_sideband_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_sideband_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral sideband composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_sideband_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_sideband_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral multi-register sideband no-policy composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB generalized multi-peripheral multi-register sideband no-policy composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB generalized five-register multi-peripheral multi-register sideband no-policy composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral multi-register sideband protection composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB generalized multi-peripheral multi-register sideband protection composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB generalized five-register multi-peripheral multi-register sideband protection composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral multi-register sideband data16 no-policy composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB generalized multi-peripheral multi-register sideband data16 no-policy composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB generalized five-register multi-peripheral multi-register sideband data16 no-policy composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB generalized six-register multi-peripheral multi-register sideband data16 no-policy composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral multi-register sideband data16 protection composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB generalized multi-peripheral multi-register sideband data16 protection composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB generalized five-register multi-peripheral multi-register sideband data16 protection composition status back-to-back',
            path => sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-register sideband data16 completer',
            path => sample_apb_completer_multi_register_sideband_data16_alias_path(),
            entry_id => 'intent.apb_profile_alias_completer_multi_register_sideband_data16',
            source_root_kind => 'fsm',
            module => 'apb_completer',
        },
        {
            label => 'APB multi-register sideband data16 back-to-back completer',
            path => sample_apb_completer_multi_register_sideband_data16_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_completer_multi_register_sideband_data16_back_to_back',
            source_root_kind => 'fsm',
            module => 'apb_completer',
        },
        {
            label => 'APB multi-register sideband data16 protection completer',
            path => sample_apb_completer_multi_register_sideband_data16_protection_alias_path(),
            entry_id => 'intent.apb_profile_alias_completer_multi_register_sideband_data16_protection',
            source_root_kind => 'fsm',
            module => 'apb_completer',
        },
        {
            label => 'APB multi-register sideband data16 protection back-to-back completer',
            path => sample_apb_completer_multi_register_sideband_data16_protection_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_completer_multi_register_sideband_data16_protection_back_to_back',
            source_root_kind => 'fsm',
            module => 'apb_completer',
        },
        {
            label => 'APB multi-register sideband data16 composition',
            path => sample_apb_composition_multi_register_sideband_data16_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_register_sideband_data16',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-register sideband data16 status back-to-back composition',
            path => sample_apb_composition_multi_register_sideband_data16_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_register_sideband_data16_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-register sideband data16 protection composition',
            path => sample_apb_composition_multi_register_sideband_data16_protection_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_register_sideband_data16_protection',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-register sideband data16 protection status back-to-back composition',
            path => sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_register_sideband_data16_protection_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral sideband data16 composition',
            path => sample_apb_composition_multi_peripheral_sideband_data16_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_sideband_data16',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral sideband data16 protection composition',
            path => sample_apb_composition_multi_peripheral_sideband_data16_protection_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_sideband_data16_protection',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
        {
            label => 'APB multi-peripheral sideband data16 protection status back-to-back composition',
            path => sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_multi_peripheral_sideband_data16_protection_status_back_to_back',
            source_root_kind => 'top',
            module => 'apb_tb',
        },
    );

    for my $case (@cases) {
        my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--strict', '--check', '--json', $case->{path}],
        );
        ok($success, "$case->{label} .apb --check --json succeeds");
        is(join('', @{$stderr_buf || []}), '', "$case->{label} .apb --check --json keeps stderr clean");
        my $check_report = decode_json(join('', @{$stdout_buf || []}));
        ok($check_report->{success}, "$case->{label} .apb check JSON reports success");
        is($check_report->{source}{resolved_path}, File::Spec->rel2abs($case->{path}), "$case->{label} .apb check JSON reports the public alias source path");
        is($check_report->{support_accounting}{entry_id}, $case->{entry_id}, "$case->{label} .apb check JSON names the profile-alias corpus entry");
        is($check_report->{support_accounting}{source_kind}, 'ial2_profile_alias', "$case->{label} .apb check JSON records profile-alias source kind");

        my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
            command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $case->{path}],
        );
        ok($semantic_success, "$case->{label} .apb --emit-semantic-json succeeds");
        is(join('', @{$semantic_stderr || []}), '', "$case->{label} .apb --emit-semantic-json keeps stderr clean");
        my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
        ok($semantic_report->{success}, "$case->{label} .apb semantic JSON reports success");
        is($semantic_report->{source}{resolved_path}, File::Spec->rel2abs($case->{path}), "$case->{label} .apb semantic JSON reports the public alias source path");
        is($semantic_report->{support_accounting}{entry_id}, $case->{entry_id}, "$case->{label} .apb semantic JSON names the profile-alias corpus entry");
        is($semantic_report->{semantic}{module}{source_root_kind}, $case->{source_root_kind}, "$case->{label} .apb semantic JSON records source root kind");
        is($semantic_report->{semantic}{module}{name}, $case->{module}, "$case->{label} .apb semantic JSON records generated module");
    }
};

subtest 'adapter accepts status back-to-back APB .apb profile aliases' => sub {
    my $requester_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_status_back_to_back_path());
    my $requester_fsm = $requester_alias->{generated_ial0}{files}{'apb_requester.fsm'};
    like($requester_alias->{generated_ial1}{text}, qr/\(output accepted\)/, 'back-to-back requester .apb IAL1 exposes accepted output');
    like($requester_fsm, qr/\(queued_valid 1\)/, 'back-to-back requester FSM declares queued_valid');
    like($requester_fsm, qr/\(\?\(& start \(! queued_valid\)\)/, 'back-to-back requester FSM captures one queued start');
    like($requester_fsm, qr/\(<- \(accepted> 1\)\)/, 'back-to-back requester FSM pulses accepted on admission');
    like($requester_fsm, qr/\(<- \(PADDR> queued_addr\)\)/, 'back-to-back requester FSM drives queued address on adjacent setup');
    like($requester_fsm, qr/\(<- \(PENABLE> 0\)\)/, 'back-to-back requester FSM keeps adjacent setup PENABLE low');
    is($requester_alias->{report}{response_accepted_field}{name}, 'accepted', 'back-to-back requester report exposes accepted metadata');
    is($requester_alias->{report}{transfer}{timing_policy}{overflow}, 'reject', 'back-to-back requester report records overflow reject policy');
    my %requester_residue = map { $_->{id} => 1 } @{$requester_alias->{report}{unsupported_residue}};
    ok(!$requester_residue{apb_back_to_back_policy_deferred}, 'back-to-back requester removes broad back-to-back residue');
    ok($requester_residue{apb_additional_back_to_back_policies_deferred}, 'back-to-back requester keeps narrowed future-policy residue');

    my $composition_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_status_back_to_back_alias_path());
    like($composition_alias->{generated_ial0}{files}{'apb_tb.fsm'}, qr/=accepted>/, 'back-to-back composition top exposes accepted output');
    is($composition_alias->{report}{requester_accepted_field}{name}, 'accepted', 'back-to-back composition report exposes accepted metadata');
    is($composition_alias->{report}{back_to_back_policy}{completer}{timing_policy}{setup_admission}, 'adjacent', 'back-to-back composition report aggregates completer timing policy');
};

subtest 'CLI check and semantic JSON report .apb public source identity' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', sample_apb_path()],
    );
    ok($success, '--check --json succeeds for .apb');
    is(join('', @{$stderr_buf || []}), '', '--check --json keeps stderr clean for .apb');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, '.apb check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_apb_path()),
        '.apb check JSON reports the public alias source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.apb_profile_alias_requester_transfer',
        '.apb check JSON support accounting names the profile-alias corpus entry',
    );
    is(
        $check_report->{support_accounting}{source_kind},
        'ial2_profile_alias',
        '.apb check JSON records profile-alias source kind',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', sample_apb_path()],
    );
    ok($semantic_success, '--emit-semantic-json succeeds for .apb');
    is(join('', @{$semantic_stderr || []}), '', '--emit-semantic-json keeps stderr clean for .apb');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, '.apb semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_apb_path()),
        '.apb semantic JSON reports the public alias source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.apb_profile_alias_requester_transfer',
        '.apb semantic JSON support accounting names the profile-alias corpus entry',
    );
    is(
        $semantic_report->{support_accounting}{source_kind},
        'ial2_profile_alias',
        '.apb semantic JSON records profile-alias source kind',
    );
    is(
        $semantic_report->{semantic}{module}{source_root_kind},
        'fsm',
        '.apb semantic JSON payload describes the generated .fsm semantic root',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'apb_requester',
        '.apb semantic JSON records the generated APB requester module',
    );
};

subtest 'CLI schedule JSON and outdir expose review artifacts for .apb' => sub {
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_apb_path()],
    );
    ok($schedule_success, '--emit-schedule-json succeeds for .apb');
    is(join('', @{$schedule_stderr || []}), '', '--emit-schedule-json keeps stderr clean for .apb');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{target_protocol}{profile}, 'apb', '.apb schedule JSON reports the APB profile');
    is($schedule_report->{target_protocol}{object}, 'apb-requester', '.apb schedule JSON reports the APB requester object');
    is($schedule_report->{layering}{direct_ial2_to_ial0}, 0, '.apb schedule JSON keeps direct IAL2-to-IAL0 forbidden');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_requester_alias.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_apb_path()],
    );

    ok($success, 'CLI generation succeeds for .apb profile alias');
    is(join('', @{$stderr_buf || []}), '', '.apb generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'apb_requester.isf'), '.apb --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'apb_requester.fsm'), '.apb --outdir writes generated .fsm');
    ok(-f $hdl, '.apb --output writes generated HDL');
    my $requester_hdl = slurp($hdl);
    like($requester_hdl, qr/\bmodule\s+apb_requester\b/, '.apb generated HDL contains the requester module');
    unlike($requester_hdl, qr/\bbusy\b/, '.apb no-busy requester alias keeps busy absent from generated HDL');
};

subtest 'CLI schedule JSON and outdir expose review artifacts for APB completer and composition .apb' => sub {
    my ($completer_schedule_success, undef, undef, $completer_schedule_stdout, $completer_schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_apb_completer_alias_path()],
    );
    ok($completer_schedule_success, '--emit-schedule-json succeeds for APB completer .apb');
    is(join('', @{$completer_schedule_stderr || []}), '', '--emit-schedule-json keeps stderr clean for APB completer .apb');
    my $completer_schedule = decode_json(join('', @{$completer_schedule_stdout || []}));
    is($completer_schedule->{target_protocol}{object}, 'apb-completer', 'APB completer .apb schedule JSON reports the APB completer object');

    my ($composition_schedule_success, undef, undef, $composition_schedule_stdout, $composition_schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_apb_composition_alias_path()],
    );
    ok($composition_schedule_success, '--emit-schedule-json succeeds for APB composition .apb');
    is(join('', @{$composition_schedule_stderr || []}), '', '--emit-schedule-json keeps stderr clean for APB composition .apb');
    my $composition_schedule = decode_json(join('', @{$composition_schedule_stdout || []}));
    is($composition_schedule->{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_tb.fsm', 'APB composition .apb schedule JSON reports the HDL entry');

    my $tempdir = tempdir(CLEANUP => 1);
    my $completer_outdir = File::Spec->catdir($tempdir, 'completer-out');
    my $completer_hdl = File::Spec->catfile($tempdir, 'apb_completer_alias.sv');
    my ($completer_success, undef, undef, undef, $completer_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $completer_outdir, '--output', $completer_hdl, sample_apb_completer_alias_path()],
    );
    ok($completer_success, 'CLI generation succeeds for APB completer .apb');
    is(join('', @{$completer_stderr || []}), '', 'APB completer .apb generation keeps stderr clean');
    ok(-f File::Spec->catfile($completer_outdir, 'apb_completer.isf'), 'APB completer .apb --outdir writes generated .isf');
    ok(-f File::Spec->catfile($completer_outdir, 'apb_completer.fsm'), 'APB completer .apb --outdir writes generated .fsm');
    like(slurp($completer_hdl), qr/\bmodule\s+apb_completer\b/, 'APB completer .apb generated HDL contains the completer module');

    my $composition_outdir = File::Spec->catdir($tempdir, 'composition-out');
    my $composition_hdl = File::Spec->catfile($tempdir, 'apb_tb_alias.sv');
    my ($composition_success, undef, undef, undef, $composition_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $composition_outdir, '--output', $composition_hdl, sample_apb_composition_alias_path()],
    );
    ok($composition_success, 'CLI generation succeeds for APB composition .apb');
    is(join('', @{$composition_stderr || []}), '', 'APB composition .apb generation keeps stderr clean');
    for my $artifact (qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)) {
        ok(-f File::Spec->catfile($composition_outdir, $artifact), "APB composition .apb --outdir writes $artifact");
    }
    my $composition_sv = slurp($composition_hdl);
    like($composition_sv, qr/\bmodule\s+apb_tb\b/, 'APB composition .apb generated HDL contains the top module');
    like($composition_sv, qr/\bmodule\s+apb_requester\b/, 'APB composition .apb generated HDL contains the requester module');
    like($composition_sv, qr/\bmodule\s+apb_completer\b/, 'APB composition .apb generated HDL contains the completer module');
};

subtest 'adapter accepts busy-capable APB .apb profile aliases' => sub {
    ok(-f sample_apb_busy_path(), 'tracked runnable busy APB requester .apb sample exists');
    ok(-f sample_apb_composition_busy_alias_path(), 'tracked runnable busy APB composition .apb sample exists');

    my $requester_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_busy_path());
    my $requester_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ppif_busy_path());
    is($requester_alias->{kind}, 'protocol_intent.apb_requester_transfer', 'busy .apb requester keeps APB requester-transfer kind');
    is($requester_alias->{generated_ial1}{text}, $requester_ppif->{generated_ial1}{text}, 'busy .apb requester mirrors .ppif generated IAL1');
    is_deeply($requester_alias->{generated_ial0}{files}, $requester_ppif->{generated_ial0}{files}, 'busy .apb requester mirrors .ppif generated IAL0');
    like($requester_alias->{generated_ial1}{text}, qr/\(output busy\)/, 'busy .apb requester IAL1 exposes busy output');
    like($requester_alias->{generated_ial0}{files}{'apb_requester.fsm'}, qr/\(<- \(busy> 0\)\)/, 'busy .apb requester FSM clears busy in idle');
    like($requester_alias->{generated_ial0}{files}{'apb_requester.fsm'}, qr/\(<- \(busy> 1\) <(?:setup|access)_phase_start\)/, 'busy .apb requester FSM asserts busy during transfer phases');
    my %requester_residue = map { $_->{id} => 1 } @{$requester_alias->{report}{unsupported_residue}};
    ok($requester_residue{apb_requester_status_field_deferred}, 'busy .apb requester keeps only named status-field widening deferred');
    ok(!$requester_residue{apb_requester_busy_status_deferred}, 'busy .apb requester removes busy/status deferred residue');

    my $composition_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_busy_alias_path());
    my $composition_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_busy_ppif_path());
    is($composition_alias->{kind}, 'protocol_intent.apb_composition', 'busy .apb composition keeps APB composition kind');
    is_deeply($composition_alias->{generated_ial1}{items}, $composition_ppif->{generated_ial1}{items}, 'busy .apb composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($composition_alias->{generated_ial0}{files}, $composition_ppif->{generated_ial0}{files}, 'busy .apb composition mirrors .ppif generated IAL0 files');
    like($composition_alias->{generated_ial0}{files}{'apb_tb.fsm'}, qr/=busy>/, 'busy .apb composition top exposes busy output');
    my %composition_residue = map { $_->{id} => 1 } @{$composition_alias->{report}{unsupported_residue}};
    ok($composition_residue{apb_requester_status_field_deferred}, 'busy .apb composition keeps named requester status-field widening deferred');
    ok(!$composition_residue{apb_requester_busy_status_deferred}, 'busy .apb composition removes requester busy/status deferred residue');
};

subtest 'adapter accepts status-capable APB .apb profile aliases' => sub {
    ok(-f sample_apb_status_path(), 'tracked runnable status APB requester .apb sample exists');
    ok(-f sample_apb_composition_status_alias_path(), 'tracked runnable status APB composition .apb sample exists');

    my $requester_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_status_path());
    my $requester_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ppif_status_path());
    is($requester_alias->{kind}, 'protocol_intent.apb_requester_transfer', 'status .apb requester keeps APB requester-transfer kind');
    is($requester_alias->{generated_ial1}{text}, $requester_ppif->{generated_ial1}{text}, 'status .apb requester mirrors .ppif generated IAL1');
    is_deeply($requester_alias->{generated_ial0}{files}, $requester_ppif->{generated_ial0}{files}, 'status .apb requester mirrors .ppif generated IAL0');
    like($requester_alias->{generated_ial1}{text}, qr/\(output status \(width 2\)\)/, 'status .apb requester IAL1 exposes 2-bit status output');
    like($requester_alias->{generated_ial1}{text}, qr/\(status \(concat 1'b1 slverr\)\)/, 'status .apb requester IAL1 maps done status from sampled PSLVERR');
    my $requester_fsm = $requester_alias->{generated_ial0}{files}{'apb_requester.fsm'};
    like($requester_fsm, qr/\(<- \(status> 0\)\)/, 'status .apb requester FSM clears status in idle');
    like($requester_fsm, qr/\(<- \(status> 1\) <(?:setup|access)_phase_start\)/, 'status .apb requester FSM asserts busy status during transfer phases');
    like($requester_fsm, qr/\(<- \(status> \(concat 1'b1 slverr\)\) <done_phase_start\)/, 'status .apb requester FSM publishes done_ok/done_error from sampled error');
    is($requester_alias->{report}{bindings}{response}{status}{name}, 'status', 'status .apb requester report preserves response status name');
    is($requester_alias->{report}{bindings}{response}{status}{width}, 2, 'status .apb requester report preserves response status width');
    is_deeply(
        [map { $_->{name} } @{$requester_alias->{report}{response_status_field}{encoding}}],
        [qw(idle busy done_ok done_error)],
        'status .apb requester report preserves selected status encoding names',
    );
    my %requester_residue = map { $_->{id} => 1 } @{$requester_alias->{report}{unsupported_residue}};
    ok(!$requester_residue{apb_requester_status_field_deferred}, 'status .apb requester removes named status-field deferred residue');
    ok(!$requester_residue{apb_requester_busy_status_deferred}, 'status .apb requester keeps busy/status deferred residue absent');

    my $composition_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_status_alias_path());
    my $composition_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_composition_status_ppif_path());
    is($composition_alias->{kind}, 'protocol_intent.apb_composition', 'status .apb composition keeps APB composition kind');
    is_deeply($composition_alias->{generated_ial1}{items}, $composition_ppif->{generated_ial1}{items}, 'status .apb composition mirrors .ppif generated IAL1 artifacts');
    is_deeply($composition_alias->{generated_ial0}{files}, $composition_ppif->{generated_ial0}{files}, 'status .apb composition mirrors .ppif generated IAL0 files');
    like($composition_alias->{generated_ial0}{files}{'apb_tb.fsm'}, qr/=status>2/, 'status .apb composition top exposes 2-bit status output');
    is($composition_alias->{report}{requester_status_field}{name}, 'status', 'status .apb composition report exposes requester status metadata');
    my ($status_top_port) = grep { $_->{name} eq 'status' } @{$composition_alias->{report}{composition}{top_ports}};
    ok($status_top_port, 'status .apb composition report lists status top port');
    is($status_top_port->{width}, 2, 'status .apb composition report lists a 2-bit status top port');
    my %composition_residue = map { $_->{id} => 1 } @{$composition_alias->{report}{unsupported_residue}};
    ok(!$composition_residue{apb_requester_status_field_deferred}, 'status .apb composition removes named requester status-field residue');
    ok(!$composition_residue{apb_requester_busy_status_deferred}, 'status .apb composition keeps requester busy/status deferred residue absent');
};

subtest 'CLI check, semantic JSON, and outdir report busy/status APB .apb public source identity' => sub {
    my @cases = (
        {
            label => 'busy APB requester',
            path => sample_apb_busy_path(),
            entry_id => 'intent.apb_profile_alias_requester_transfer_busy',
            source_root_kind => 'fsm',
            module => 'apb_requester',
            hdl => 'apb_requester_busy_alias.sv',
            out_artifacts => [qw(apb_requester.isf apb_requester.fsm)],
            status_output => 0,
        },
        {
            label => 'busy APB composition',
            path => sample_apb_composition_busy_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_busy',
            source_root_kind => 'top',
            module => 'apb_tb',
            hdl => 'apb_tb_busy_alias.sv',
            out_artifacts => [qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)],
            status_output => 0,
        },
        {
            label => 'status APB requester',
            path => sample_apb_status_path(),
            entry_id => 'intent.apb_profile_alias_requester_transfer_status',
            source_root_kind => 'fsm',
            module => 'apb_requester',
            hdl => 'apb_requester_status_alias.sv',
            out_artifacts => [qw(apb_requester.isf apb_requester.fsm)],
            status_output => 1,
        },
        {
            label => 'status APB composition',
            path => sample_apb_composition_status_alias_path(),
            entry_id => 'intent.apb_profile_alias_composition_status',
            source_root_kind => 'top',
            module => 'apb_tb',
            hdl => 'apb_tb_status_alias.sv',
            out_artifacts => [qw(apb_requester.isf apb_completer.isf apb_requester.fsm apb_completer.fsm apb_tb.fsm)],
            status_output => 1,
        },
    );

    my $tempdir = tempdir(CLEANUP => 1);
    for my $case (@cases) {
        my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
            command => ['./bin/fsmgen', '--strict', '--check', '--json', $case->{path}],
        );
        ok($check_success, "$case->{label} .apb --check --json succeeds");
        is(join('', @{$check_stderr || []}), '', "$case->{label} .apb --check --json keeps stderr clean");
        my $check_report = decode_json(join('', @{$check_stdout || []}));
        ok($check_report->{success}, "$case->{label} .apb check JSON reports success");
        is($check_report->{source}{resolved_path}, File::Spec->rel2abs($case->{path}), "$case->{label} .apb check JSON reports source path");
        is($check_report->{support_accounting}{entry_id}, $case->{entry_id}, "$case->{label} .apb check JSON names corpus entry");
        is($check_report->{support_accounting}{source_kind}, 'ial2_profile_alias', "$case->{label} .apb check JSON records profile-alias source kind");

        my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
            command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $case->{path}],
        );
        ok($semantic_success, "$case->{label} .apb --emit-semantic-json succeeds");
        is(join('', @{$semantic_stderr || []}), '', "$case->{label} .apb --emit-semantic-json keeps stderr clean");
        my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
        is($semantic_report->{support_accounting}{entry_id}, $case->{entry_id}, "$case->{label} .apb semantic JSON names corpus entry");
        is($semantic_report->{semantic}{module}{source_root_kind}, $case->{source_root_kind}, "$case->{label} .apb semantic JSON records source root kind");
        is($semantic_report->{semantic}{module}{name}, $case->{module}, "$case->{label} .apb semantic JSON records generated module");

        my $outdir = File::Spec->catdir($tempdir, $case->{entry_id});
        my $hdl = File::Spec->catfile($tempdir, $case->{hdl});
        my ($gen_success, undef, undef, undef, $gen_stderr) = run(
            command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $case->{path}],
        );
        ok($gen_success, "$case->{label} .apb generation succeeds");
        is(join('', @{$gen_stderr || []}), '', "$case->{label} .apb generation keeps stderr clean");
        for my $artifact (@{$case->{out_artifacts}}) {
            ok(-f File::Spec->catfile($outdir, $artifact), "$case->{label} .apb --outdir writes $artifact");
        }
        my $sv = slurp($hdl);
        like($sv, qr/\bmodule\s+$case->{module}\b/, "$case->{label} .apb generated HDL contains selected module");
        like($sv, qr/\boutput(?:\s+reg)?\s+busy\b/, "$case->{label} .apb generated HDL exposes busy output");
        if ($case->{status_output}) {
            like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+status\b/, "$case->{label} .apb generated HDL exposes 2-bit status output");
            my $requester_fsm = slurp(File::Spec->catfile($outdir, 'apb_requester.fsm'));
            like($requester_fsm, qr/\(<- \(status> \(concat 1'b1 slverr\)\) <done_phase_start\)/, "$case->{label} .apb outdir requester FSM records the selected status encoding");
        }
    }
};

subtest 'CLI distinguishes unsupported known aliases and unknown suffixes after .apb ships' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $chi_path = File::Spec->catfile($tempdir, 'sample.chi');
    write_file($chi_path, slurp(sample_ppif_path()));
    my ($chi_success, undef, undef, $chi_stdout, undef) = run(
        command => ['./bin/fsmgen', '--check', '--json', $chi_path],
    );
    ok(!$chi_success, '.chi remains unsupported');
    my $chi_report = decode_json(join('', @{$chi_stdout || []}));
    ok(!$chi_report->{success}, '.chi check JSON reports failure');
    like(
        $chi_report->{diagnostics}[0]{message},
        qr/known IAL2 alias candidate but is not supported in this slice/,
        '.chi failure is reported as unsupported known alias',
    );

    my $unknown_path = File::Spec->catfile($tempdir, 'sample.foo');
    write_file($unknown_path, slurp(sample_ppif_path()));
    my ($unknown_success, undef, undef, $unknown_stdout, undef) = run(
        command => ['./bin/fsmgen', '--check', '--json', $unknown_path],
    );
    ok(!$unknown_success, '.foo remains an unknown suffix');
    my $unknown_report = decode_json(join('', @{$unknown_stdout || []}));
    ok(!$unknown_report->{success}, '.foo check JSON reports failure');
    like(
        $unknown_report->{diagnostics}[0]{message},
        qr/source suffix '\.foo' is not a known FSMGen source suffix/,
        '.foo failure is reported as unknown suffix',
    );
};

done_testing();

sub sample_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer.ppif');
}

sub sample_ppif_busy_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_busy.ppif');
}

sub sample_ppif_status_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_status.ppif');
}

sub sample_ppif_status_back_to_back_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_status_back_to_back.ppif');
}

sub sample_ppif_sideband_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_sideband.ppif');
}

sub sample_ppif_sideband_status_back_to_back_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_sideband_status_back_to_back.ppif');
}

sub sample_ppif_sideband_data16_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_sideband_data16.ppif');
}

sub sample_ppif_sideband_data16_status_back_to_back_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_sideband_data16_status_back_to_back.ppif');
}

sub sample_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer.apb');
}

sub sample_apb_busy_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_busy.apb');
}

sub sample_apb_status_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_status.apb');
}

sub sample_apb_status_back_to_back_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_status_back_to_back.apb');
}

sub sample_apb_sideband_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_sideband.apb');
}

sub sample_apb_sideband_status_back_to_back_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_sideband_status_back_to_back.apb');
}

sub sample_apb_sideband_data16_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_sideband_data16.apb');
}

sub sample_apb_sideband_data16_status_back_to_back_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_sideband_data16_status_back_to_back.apb');
}

sub sample_apb_completer_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer.apb');
}

sub sample_apb_completer_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer.ppif');
}

sub sample_apb_completer_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_back_to_back.apb');
}

sub sample_apb_completer_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_back_to_back.ppif');
}

sub sample_apb_completer_sideband_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_sideband_back_to_back.apb');
}

sub sample_apb_completer_sideband_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_sideband_back_to_back.ppif');
}

sub sample_apb_completer_multi_register_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register.apb');
}

sub sample_apb_completer_multi_register_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register.ppif');
}

sub sample_apb_completer_multi_register_sideband_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband.apb');
}

sub sample_apb_completer_multi_register_sideband_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_back_to_back.apb');
}

sub sample_apb_completer_multi_register_sideband_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband.ppif');
}

sub sample_apb_completer_multi_register_sideband_protection_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_protection.apb');
}

sub sample_apb_completer_multi_register_sideband_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_protection.ppif');
}

sub sample_apb_completer_multi_register_sideband_protection_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_protection_back_to_back.apb');
}

sub sample_apb_completer_multi_register_sideband_protection_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_protection_back_to_back.ppif');
}

sub sample_apb_completer_multi_register_sideband_data16_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16.apb');
}

sub sample_apb_completer_multi_register_sideband_data16_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16_back_to_back.apb');
}

sub sample_apb_completer_multi_register_sideband_data16_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16.ppif');
}

sub sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16_back_to_back.ppif');
}

sub sample_apb_completer_multi_register_sideband_data16_protection_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16_protection.apb');
}

sub sample_apb_completer_multi_register_sideband_data16_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16_protection.ppif');
}

sub sample_apb_completer_multi_register_sideband_data16_protection_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16_protection_back_to_back.apb');
}

sub sample_apb_completer_multi_register_sideband_data16_protection_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16_protection_back_to_back.ppif');
}

sub sample_apb_composition_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition.apb');
}

sub sample_apb_composition_multi_register_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register.apb');
}

sub sample_apb_composition_multi_register_sideband_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband.apb');
}

sub sample_apb_composition_multi_register_sideband_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_status_back_to_back.apb');
}

sub sample_apb_composition_multi_register_sideband_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband.ppif');
}

sub sample_apb_composition_multi_register_sideband_protection_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_protection.apb');
}

sub sample_apb_composition_multi_register_sideband_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_protection.ppif');
}

sub sample_apb_composition_multi_register_sideband_protection_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_protection_status_back_to_back.apb');
}

sub sample_apb_composition_multi_register_sideband_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_register_sideband_data16_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16.apb');
}

sub sample_apb_composition_multi_register_sideband_data16_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_status_back_to_back.apb');
}

sub sample_apb_composition_multi_register_sideband_data16_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16.ppif');
}

sub sample_apb_composition_multi_register_sideband_data16_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_register_sideband_data16_protection_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_protection.apb');
}

sub sample_apb_composition_multi_register_sideband_data16_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_protection.ppif');
}

sub sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_protection_status_back_to_back.apb');
}

sub sample_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral.apb');
}

sub sample_apb_composition_multi_peripheral_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_protection_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_protection.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_protection.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_protection_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_protection_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16_protection.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16_protection.ppif');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.apb');
}

sub sample_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif');
}

sub sample_apb_composition_busy_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_busy.apb');
}

sub sample_apb_composition_status_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_status.apb');
}

sub sample_apb_composition_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_status_back_to_back.apb');
}

sub sample_apb_composition_sideband_status_back_to_back_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_sideband_status_back_to_back.apb');
}

sub sample_apb_composition_sideband_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_sideband_status_back_to_back.ppif');
}

sub sample_apb_composition_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition.ppif');
}

sub sample_apb_composition_multi_register_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register.ppif');
}

sub sample_apb_composition_multi_peripheral_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral.ppif');
}

sub sample_apb_composition_busy_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_busy.ppif');
}

sub sample_apb_composition_status_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_status.ppif');
}

sub sample_apb_composition_status_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_status_back_to_back.ppif');
}

sub sample_valid_ready_handshake_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'valid_ready_handshake.ppif');
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
