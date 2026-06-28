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

subtest 'adapter parses the selected APB completer PPIF shape' => sub {
    ok(-f sample_apb_completer_ppif_path(), 'tracked runnable APB completer PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_ppif_path());

    is($result->{layer}, 'IAL2', 'APB completer adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_completer', 'adapter returns the APB completer kind');
    is($result->{mode}, 'completer', 'APB completer mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.apb_completer.v1', 'APB completer report schema is selected');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-completer', 'APB completer source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'apb_completer', 'APB completer source intent name is preserved');
    is($result->{report}{target_protocol}{profile}, 'apb', 'APB completer report carries the APB profile');
    is($result->{report}{target_protocol}{object}, 'apb-completer', 'APB completer report carries the APB completer object');
    is($result->{report}{target_protocol}{role}, 'completer', 'APB completer report carries the completer role');
    is($result->{report}{target_protocol}{transfer}, 'apb_complete', 'APB completer report carries the transfer name');

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'apb_completer.isf', 'APB completer exposes generated IAL1 artifact');
    like($isf, qr/\A\(actor apb_completer\b/, 'generated IAL1 is .isf text');
    like($isf, qr/\(input PSEL\)/, 'generated IAL1 declares PSEL');
    like($isf, qr/\(input wait_cycles \(width 4\)\)/, 'generated IAL1 declares runtime wait count input');
    like($isf, qr/\(var reg_data_q \(width 32\) \(reset 0\)\)/, 'generated IAL1 declares address-0 storage register');
    like($isf, qr/\(when \(& PSEL \(! PENABLE\)\)/, 'generated IAL1 detects APB setup phase explicitly');
    like($isf, qr/\(sample wait_cycles as wait_n\)/, 'generated IAL1 samples runtime wait cycles');
    like($isf, qr/\(wait wait_n\)/, 'generated IAL1 waits on the sampled runtime count');
    like($isf, qr/\(set reg_data_q wdata_q\)/, 'generated IAL1 updates storage on mapped writes');
    like($isf, qr/\(drive read_hit\)/, 'generated IAL1 has mapped read response drive');
    like($isf, qr/\(drive error_complete\)/, 'generated IAL1 has unmapped-address error drive');
    like($isf, qr/\(complete apb_complete_done_q\)/, 'generated IAL1 uses an internal terminal completion bit');
    unlike($isf, qr/\(output done\)/, 'generated IAL1 does not add a public APB done port');

    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['apb_completer.fsm'],
        'APB completer adapter exposes generated APB IAL0 .fsm file map',
    );
    my $fsm = $result->{generated_ial0}{files}{'apb_completer.fsm'};
    like($fsm, qr/\(\?fsm:apb_completer\b/, 'generated IAL0 names the completer FSM');
    like($fsm, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'generated IAL0 samples address under setup-detect guard');
    like($fsm, qr/\(apb_complete_wait_2_cnt 4\)/, 'generated IAL0 includes the 4-bit runtime wait counter');
    like($fsm, qr/\(reg_data_q 32 \(reset 0\)\)/, 'generated IAL0 preserves register reset metadata');
    like($fsm, qr/\(<- \(reg_data_q wdata_q\)\)/, 'generated IAL0 updates storage on mapped writes');
    like($fsm, qr/\(<- \(PRDATA> reg_data_q\) <read_hit_start\)/, 'generated IAL0 drives read data from storage');
    like($fsm, qr/\(<- \(PSLVERR> 1\) <error_complete_start\)/, 'generated IAL0 drives PSLVERR for unmapped addresses');
    like($fsm, qr/\(<1 \(apb_complete_done_q 1\)\)/, 'generated IAL0 has an internal terminal completion pulse');

    is($result->{report}{bindings}{control}{wait_cycles}{name}, 'wait_cycles', 'report captures wait-cycles control binding');
    is($result->{report}{bindings}{storage}{register}{name}, 'reg0', 'report captures storage register name');
    is($result->{report}{bindings}{storage}{register}{address}{value}, 0, 'report captures mapped address');
    is($result->{report}{bindings}{storage}{register}{data}{name}, 'reg_data_q', 'report captures storage data signal');
    is($result->{report}{transfer}{setup_detect}{select}, 1, 'report captures setup select value');
    is($result->{report}{transfer}{setup_detect}{enable}, 0, 'report captures setup enable value');
    is($result->{report}{transfer}{wait_cycles}, 'wait_cycles', 'report captures transfer wait source');
    is($result->{report}{transfer}{read}, 'register', 'report captures register read policy');
    is($result->{report}{transfer}{write}, 'register', 'report captures register write policy');
    is($result->{report}{transfer}{unmapped_address}, 'error', 'report captures unmapped-address error policy');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'apb_completer.fsm', 'report selects generated completer .fsm as HDL entry');
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'APB completer lowering goes through generated IAL1 before IAL0');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok($residue{apb_interconnect_multi_peripheral_decode_deferred}, 'report keeps multi-peripheral interconnect residue explicit');
    ok($residue{apb_back_to_back_policy_deferred}, 'report keeps back-to-back policy residue explicit');
};

subtest 'adapter parses the selected APB back-to-back completer PPIF shape' => sub {
    ok(-f sample_apb_completer_back_to_back_ppif_path(), 'tracked runnable APB back-to-back completer PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'APB back-to-back completer adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_completer', 'adapter returns the APB completer kind for back-to-back source');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-completer-back-to-back', 'back-to-back completer source object id is preserved');
    is($result->{report}{transfer}{timing_policy}{setup_admission}, 'adjacent', 'back-to-back completer report records adjacent setup admission');

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(when \(& PSEL \(! PENABLE\)\)/, 'back-to-back completer IAL1 admits every selected APB setup cycle');
    unlike($isf, qr/idle-cycle/, 'back-to-back completer IAL1 does not encode an idle-cycle requirement');

    my $fsm = $result->{generated_ial0}{files}{'apb_completer.fsm'};
    like($fsm, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'back-to-back completer FSM samples address under adjacent setup guard');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'back-to-back completer removes broad back-to-back residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'back-to-back completer keeps narrowed future-policy residue');
};

subtest 'adapter parses the selected APB sideband back-to-back completer PPIF shape' => sub {
    ok(-f sample_apb_completer_sideband_back_to_back_ppif_path(), 'tracked runnable APB sideband back-to-back completer PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_sideband_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'APB sideband back-to-back completer adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_completer', 'adapter returns the APB completer kind for sideband back-to-back source');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-completer-sideband-back-to-back', 'sideband back-to-back source object id is preserved');
    is($result->{report}{transfer}{timing_policy}{setup_admission}, 'adjacent', 'sideband back-to-back completer report records adjacent setup admission');
    is($result->{report}{bindings}{bus}{protection}{width}, 3, 'sideband back-to-back report records PPROT width 3');
    is($result->{report}{bindings}{bus}{strobe}{width}, 4, 'sideband back-to-back report records PSTRB width 4');

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(sample PPROT as prot_q\)/, 'sideband back-to-back IAL1 samples PPROT during APB setup');
    like($isf, qr/\(sample PSTRB as strb_q\)/, 'sideband back-to-back IAL1 samples PSTRB during APB setup');
    like($isf, qr/\(when-bit strb_q 0\s+\(set reg_data_q \(\| \(& reg_data_q 32'hffffff00\) \(& wdata_q 32'h000000ff\)\)\)\)/s, 'sideband back-to-back IAL1 byte-enables low byte');
    like($isf, qr/\(when-bit strb_q 3\s+\(set reg_data_q \(\| \(& reg_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/s, 'sideband back-to-back IAL1 byte-enables high byte');

    my $fsm = $result->{generated_ial0}{files}{'apb_completer.fsm'};
    like($fsm, qr/\(<= \(prot_q PPROT\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband back-to-back FSM samples PPROT under setup-detect guard');
    like($fsm, qr/\(<= \(strb_q PSTRB\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband back-to-back FSM samples PSTRB under setup-detect guard');
    like($fsm, qr/\(\?\(!= \(& strb_q 4'd8\) 4'd0\)/, 'sideband back-to-back FSM guards byte 3 writes with PSTRB bit 3');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband back-to-back completer removes broad back-to-back residue');
    ok(!$residue{apb_protection_and_strobes_deferred}, 'sideband back-to-back completer removes broad sideband residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband back-to-back completer keeps narrowed future-policy residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'sideband back-to-back completer keeps protection-policy effects deferred');
};

subtest 'adapter parses the selected APB multi-register completer PPIF shape' => sub {
    ok(-f sample_apb_completer_multi_register_ppif_path(), 'tracked runnable APB multi-register completer PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_ppif_path());

    is($result->{layer}, 'IAL2', 'APB multi-register completer adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_completer', 'adapter returns the APB completer kind for multi-register source');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-completer-multi-register', 'multi-register source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'apb_completer_multi_register', 'multi-register intent name is preserved');
    ok(!exists $result->{report}{bindings}{storage}{register}, 'multi-register report omits singular storage.register');
    is_deeply(
        [map { $_->{name} } @{$result->{report}{bindings}{storage}{registers}}],
        [qw(reg0 reg1)],
        'multi-register report preserves source-order register names',
    );
    is_deeply(
        [map { $_->{address}{value} } @{$result->{report}{bindings}{storage}{registers}}],
        [0, 4],
        'multi-register report preserves source-order decoded addresses',
    );
    is_deeply(
        [map { $_->{data}{name} } @{$result->{report}{bindings}{storage}{registers}}],
        [qw(reg0_data_q reg1_data_q)],
        'multi-register report preserves source-order storage data signals',
    );
    ok(!exists $result->{report}{transfer}{register}, 'multi-register report omits singular transfer.register');
    is_deeply($result->{report}{transfer}{registers}, [qw(reg0 reg1)], 'multi-register report records transfer register list');

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(var reg0_data_q \(width 32\) \(reset 0\)\)/, 'generated IAL1 declares first storage register');
    like($isf, qr/\(var reg1_data_q \(width 32\) \(reset 0\)\)/, 'generated IAL1 declares second storage register');
    like($isf, qr/\(when \(& write_q \(== addr 4\)\)\n      \(set reg1_data_q wdata_q\)\n      \(drive write_hit\)\)/, 'generated IAL1 updates the selected second register on mapped writes');
    like($isf, qr/\(when \(& write_q \(! \(\| \(== addr 0\) \(== addr 4\)\)\)\)/, 'generated IAL1 errors writes outside the decoded register set');
    like($isf, qr/\(drive read_reg1_hit\)/, 'generated IAL1 drives a second-register read response');
    like($isf, qr/\(when \(& \(! write_q\) \(! \(\| \(== addr 0\) \(== addr 4\)\)\)\)/, 'generated IAL1 errors reads outside the decoded register set');

    my $fsm = $result->{generated_ial0}{files}{'apb_completer.fsm'};
    like($fsm, qr/\(reg0_data_q 32 \(reset 0\)\)/, 'generated IAL0 preserves first register reset metadata');
    like($fsm, qr/\(reg1_data_q 32 \(reset 0\)\)/, 'generated IAL0 preserves second register reset metadata');
    like($fsm, qr/\(<- \(reg1_data_q wdata_q\)\)/, 'generated IAL0 updates second storage register on mapped writes');
    like($fsm, qr/\(<- \(PRDATA> reg1_data_q\) <read_reg1_hit_start\)/, 'generated IAL0 reads second storage register through PRDATA');
    like($fsm, qr/\(\?\(& write_q \(! \(\| \(== addr 0\) \(== addr 4\)\)\)\)/, 'generated IAL0 keeps unmapped write decode explicit');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$residue{apb_multi_register_decode_deferred}, 'multi-register completer report removes multi-register deferred residue');
    ok($residue{apb_interconnect_multi_peripheral_decode_deferred}, 'multi-register completer report keeps multi-peripheral interconnect residue explicit');
    ok($residue{apb_protection_and_strobes_deferred}, 'multi-register completer report keeps sideband residue explicit');
};

subtest 'adapter parses the selected APB multi-register sideband completer PPIF shape' => sub {
    ok(-f sample_apb_completer_multi_register_sideband_ppif_path(), 'tracked runnable APB multi-register sideband completer PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_ppif_path());

    is($result->{layer}, 'IAL2', 'APB multi-register sideband completer adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_completer', 'adapter returns the APB completer kind for sideband source');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-completer-multi-register-sideband', 'sideband source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'apb_completer_multi_register_sideband', 'sideband intent name is preserved');
    is_deeply($result->{report}{transfer}{registers}, [qw(reg0 reg1)], 'sideband report preserves the multi-register list');

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(input PPROT \(width 3\)\)/, 'generated IAL1 declares 3-bit PPROT input');
    like($isf, qr/\(input PSTRB \(width 4\)\)/, 'generated IAL1 declares 4-bit PSTRB input');
    like($isf, qr/\(sample PPROT as prot_q\)/, 'generated IAL1 samples PPROT during APB setup');
    like($isf, qr/\(sample PSTRB as strb_q\)/, 'generated IAL1 samples PSTRB during APB setup');
    like($isf, qr/\(local prot_q \(width 3\)\)/, 'generated IAL1 declares sampled PPROT local');
    like($isf, qr/\(local strb_q \(width 4\)\)/, 'generated IAL1 declares sampled PSTRB local');
    like($isf, qr/\(when-bit strb_q 0\s+\(set reg0_data_q \(\| \(& reg0_data_q 32'hffffff00\) \(& wdata_q 32'h000000ff\)\)\)\)/s, 'generated IAL1 byte-enables register 0 low byte');
    like($isf, qr/\(when-bit strb_q 3\s+\(set reg1_data_q \(\| \(& reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/s, 'generated IAL1 byte-enables register 1 high byte');

    my $fsm = $result->{generated_ial0}{files}{'apb_completer.fsm'};
    like($fsm, qr/\(PPROT 3\)/, 'generated IAL0 preserves PPROT width');
    like($fsm, qr/\(PSTRB 4\)/, 'generated IAL0 preserves PSTRB width');
    like($fsm, qr/\(<= \(prot_q PPROT\) <\(& PSEL \(! PENABLE\)\)\)/, 'generated IAL0 samples PPROT under setup-detect guard');
    like($fsm, qr/\(<= \(strb_q PSTRB\) <\(& PSEL \(! PENABLE\)\)\)/, 'generated IAL0 samples PSTRB under setup-detect guard');
    like($fsm, qr/\(\?\(!= \(& strb_q 4'd1\) 4'd0\)/, 'generated IAL0 guards byte 0 writes with PSTRB bit 0');
    like($fsm, qr/\(\?\(!= \(& strb_q 4'd8\) 4'd0\)/, 'generated IAL0 guards byte 3 writes with PSTRB bit 3');
    like($fsm, qr/\(<- \(reg0_data_q \(\| \(& reg0_data_q 32'hffffff00\) \(& wdata_q 32'h000000ff\)\)\)\)/, 'generated IAL0 masks register 0 low-byte writes');
    like($fsm, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'generated IAL0 masks register 1 high-byte writes');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$residue{apb_multi_register_decode_deferred}, 'sideband completer report keeps multi-register deferred residue absent');
    ok(!$residue{apb_protection_and_strobes_deferred}, 'sideband completer report removes broad sideband/strobe deferred residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'sideband completer report keeps protection-policy effects deferred');
};

subtest 'adapter parses the selected APB multi-register sideband back-to-back completer PPIF shape' => sub {
    ok(-f sample_apb_completer_multi_register_sideband_back_to_back_ppif_path(), 'tracked runnable APB multi-register sideband back-to-back completer PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'APB multi-register sideband back-to-back completer adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_completer', 'adapter returns the APB completer kind for sideband multi-register back-to-back source');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-completer-multi-register-sideband-back-to-back', 'sideband multi-register back-to-back source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'apb_completer_multi_register_sideband_back_to_back', 'sideband multi-register back-to-back intent name is preserved');
    is($result->{report}{transfer}{timing_policy}{setup_admission}, 'adjacent', 'sideband multi-register back-to-back report records adjacent setup admission');
    is_deeply($result->{report}{transfer}{registers}, [qw(reg0 reg1)], 'sideband multi-register back-to-back report preserves the register list');
    is($result->{report}{bindings}{bus}{protection}{width}, 3, 'sideband multi-register back-to-back report records PPROT width 3');
    is($result->{report}{bindings}{bus}{strobe}{width}, 4, 'sideband multi-register back-to-back report records PSTRB width 4');

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(when \(& PSEL \(! PENABLE\)\)/, 'sideband multi-register back-to-back IAL1 admits adjacent setup cycles');
    like($isf, qr/\(sample PPROT as prot_q\)/, 'sideband multi-register back-to-back IAL1 samples PPROT');
    like($isf, qr/\(when \(& write_q \(== addr 4\)\)/, 'sideband multi-register back-to-back IAL1 decodes the second register write');
    like($isf, qr/\(when-bit strb_q 3\s+\(set reg1_data_q \(\| \(& reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/s, 'sideband multi-register back-to-back IAL1 byte-enables register 1 high byte');

    my $fsm = $result->{generated_ial0}{files}{'apb_completer.fsm'};
    like($fsm, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband multi-register back-to-back FSM samples address under adjacent setup guard');
    like($fsm, qr/\(<= \(prot_q PPROT\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband multi-register back-to-back FSM samples PPROT under setup guard');
    like($fsm, qr/\(<= \(strb_q PSTRB\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband multi-register back-to-back FSM samples PSTRB under setup guard');
    like($fsm, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'sideband multi-register back-to-back FSM masks register 1 high-byte writes');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband multi-register back-to-back completer removes broad back-to-back residue');
    ok(!$residue{apb_protection_and_strobes_deferred}, 'sideband multi-register back-to-back completer removes broad sideband residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband multi-register back-to-back completer keeps narrowed future-policy residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'sideband multi-register back-to-back completer keeps protection-policy effects deferred');
};

subtest 'adapter parses the selected APB multi-register sideband protection completer PPIF shape' => sub {
    ok(-f sample_apb_completer_multi_register_sideband_protection_ppif_path(), 'tracked runnable APB multi-register sideband protection completer PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_protection_ppif_path());

    is($result->{layer}, 'IAL2', 'APB multi-register sideband protection completer adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_completer', 'adapter returns the APB completer kind for sideband protection source');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-completer-multi-register-sideband-protection', 'protection source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'apb_completer_multi_register_sideband_protection', 'protection intent name is preserved');

    my $policy = $result->{report}{protection_policy};
    is($policy->{scope}, 'register', 'protection policy report is register-scoped');
    is($policy->{predicate_namespace}, 'fsmgen_apb_pprot_v1', 'protection policy report names the predicate namespace');
    is($policy->{predicate_source}{bus_signal}, 'PPROT', 'protection policy report names bus-side PPROT');
    is($policy->{predicate_source}{sampled_signal}, 'prot_q', 'protection policy report names sampled PPROT local');
    is($policy->{predicate_source}{bit}, 0, 'protection policy report binds privileged predicate to PPROT bit 0');
    is($policy->{denied_read_behavior}{read_data}, 0, 'denied reads report zero read-data behavior');
    is($policy->{denied_read_behavior}{error}, 1, 'denied reads report PSLVERR behavior');
    is($policy->{denied_write_behavior}{storage_update}, 'side_effect_free', 'denied writes report side-effect-free storage behavior');
    is($policy->{zero_strobe_write_policy}{allowed}, 'successful_no_byte_write', 'allowed zero-strobe writes remain successful no-byte writes');
    is($policy->{zero_strobe_write_policy}{denied}, 'error_side_effect_free', 'denied zero-strobe writes report error without storage update');
    is($policy->{registers}[0]{read}{action}, 'allow', 'reg0 read is explicitly allowed');
    is($policy->{registers}[0]{write}{predicate}{value}, 1, 'reg0 write requires privileged PPROT');
    is($policy->{registers}[1]{read}{predicate}{value}, 1, 'reg1 read requires privileged PPROT');
    is($policy->{registers}[1]{write}{predicate}{value}, 1, 'reg1 write requires privileged PPROT');

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(when \(& write_q \(== addr 0\) \(!= \(& prot_q 3'd1\) 3'd0\)\)/, 'generated IAL1 gates reg0 writes by privileged PPROT');
    like($isf, qr/\(when \(& write_q \(== addr 0\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)\n      \(drive error_complete\)\)/, 'generated IAL1 turns denied reg0 writes into errors');
    like($isf, qr/\(when \(& \(! write_q\) \(== addr 0\)\)\n      \(drive read_reg0_hit\)\)/, 'generated IAL1 leaves reg0 reads allowed');
    like($isf, qr/\(when \(& \(! write_q\) \(== addr 4\) \(!= \(& prot_q 3'd1\) 3'd0\)\)/, 'generated IAL1 gates reg1 reads by privileged PPROT');
    like($isf, qr/\(when \(& \(! write_q\) \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)\n      \(drive error_complete\)\)/, 'generated IAL1 turns denied reg1 reads into errors');

    my $fsm = $result->{generated_ial0}{files}{'apb_completer.fsm'};
    like($fsm, qr/\(\?\(& write_q \(== addr 0\) \(!= \(& prot_q 3'd1\) 3'd0\)\)/, 'generated IAL0 keeps privileged write allow branch explicit');
    like($fsm, qr/\(\?\(& write_q \(== addr 0\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'generated IAL0 keeps denied write branch explicit');
    like($fsm, qr/\(\?\(& \(! write_q\) \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'generated IAL0 keeps denied read branch explicit');
    like($fsm, qr/\(= \(error_complete_start 1\)\)/, 'generated IAL0 denied branches share the error-complete drive');
    like($fsm, qr/\(<- \(PRDATA> 0\) <error_complete_start\)/, 'generated IAL0 denied access drives zero PRDATA through error_complete');
    like($fsm, qr/\(<- \(PSLVERR> 1\) <error_complete_start\)/, 'generated IAL0 denied access drives PSLVERR through error_complete');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$residue{apb_protection_policy_effects_deferred}, 'protection completer report removes old protection-policy-effects residue');
    ok($residue{apb_additional_protection_policies_deferred}, 'protection completer report keeps additional protection-policy families deferred');
};

subtest 'adapter parses the selected APB multi-register sideband data16 completer PPIF shape' => sub {
    ok(-f sample_apb_completer_multi_register_sideband_data16_ppif_path(), 'tracked runnable APB multi-register sideband data16 completer PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_ppif_path());

    is($result->{layer}, 'IAL2', 'APB multi-register sideband data16 completer adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_completer', 'adapter returns the APB completer kind for sideband data16 source');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-completer-multi-register-sideband-data16', 'sideband data16 source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'apb_completer_multi_register_sideband_data16', 'sideband data16 intent name is preserved');
    is($result->{report}{width_policy}{data_width}, 16, 'sideband data16 report records 16-bit data width');
    is($result->{report}{width_policy}{strobe_width}, 2, 'sideband data16 report records 2-bit strobe width');
    is($result->{report}{width_policy}{register_alignment_bytes}, 2, 'sideband data16 report records 2-byte register alignment');
    is_deeply(
        [map { $_->{data_range} } @{$result->{report}{width_policy}{byte_lanes}}],
        ['[7:0]', '[15:8]'],
        'sideband data16 report records two byte lanes',
    );
    is_deeply(
        [map { $_->{address}{value} } @{$result->{report}{bindings}{storage}{registers}}],
        [0, 2],
        'sideband data16 report preserves 2-byte decoded addresses',
    );

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(input PWDATA \(width 16\)\)/, 'generated IAL1 declares 16-bit PWDATA input');
    like($isf, qr/\(input PSTRB \(width 2\)\)/, 'generated IAL1 declares 2-bit PSTRB input');
    like($isf, qr/\(output PRDATA \(width 16\)\)/, 'generated IAL1 declares 16-bit PRDATA output');
    like($isf, qr/\(var reg1_data_q \(width 16\) \(reset 0\)\)/, 'generated IAL1 declares 16-bit second storage register');
    like($isf, qr/\(local strb_q \(width 2\)\)/, 'generated IAL1 declares sampled 2-bit PSTRB local');
    like($isf, qr/\(when \(& write_q \(== addr 2\)\)/, 'generated IAL1 decodes the second register at byte address 2');
    like($isf, qr/\(when-bit strb_q 0\s+\(set reg0_data_q \(\| \(& reg0_data_q 16'hff00\) \(& wdata_q 16'h00ff\)\)\)\)/s, 'generated IAL1 byte-enables register 0 low byte with 16-bit masks');
    like($isf, qr/\(when-bit strb_q 1\s+\(set reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/s, 'generated IAL1 byte-enables register 1 high byte with 16-bit masks');

    my $fsm = $result->{generated_ial0}{files}{'apb_completer.fsm'};
    like($fsm, qr/\(PWDATA 16\)/, 'generated IAL0 preserves PWDATA width 16');
    like($fsm, qr/\(PSTRB 2\)/, 'generated IAL0 preserves PSTRB width 2');
    like($fsm, qr/\(reg1_data_q 16 \(reset 0\)\)/, 'generated IAL0 preserves 16-bit second register metadata');
    like($fsm, qr/\(\?\(!= \(& strb_q 2'd2\) 2'd0\)/, 'generated IAL0 guards byte 1 writes with PSTRB bit 1');
    like($fsm, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'generated IAL0 masks register 1 high-byte writes with 16-bit masks');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$residue{apb_alternate_widths_deferred}, 'sideband data16 completer report removes broad alternate-width residue');
    ok($residue{apb_remaining_widths_deferred}, 'sideband data16 completer report keeps narrowed remaining-width residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'sideband data16 completer report keeps protection-policy effects deferred');
};

subtest 'adapter parses the selected APB multi-register sideband data16 back-to-back completer PPIF shape' => sub {
    ok(-f sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif_path(), 'tracked runnable APB multi-register sideband data16 back-to-back completer PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif_path());

    is($result->{layer}, 'IAL2', 'APB multi-register sideband data16 back-to-back completer adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_completer', 'adapter returns the APB completer kind for sideband data16 back-to-back source');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-completer-multi-register-sideband-data16-back-to-back', 'sideband data16 back-to-back source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'apb_completer_multi_register_sideband_data16_back_to_back', 'sideband data16 back-to-back intent name is preserved');
    is($result->{report}{transfer}{timing_policy}{setup_admission}, 'adjacent', 'sideband data16 back-to-back report records adjacent setup admission');
    is($result->{report}{width_policy}{data_width}, 16, 'sideband data16 back-to-back report records 16-bit data width');
    is($result->{report}{width_policy}{strobe_width}, 2, 'sideband data16 back-to-back report records 2-bit PSTRB width');
    is_deeply($result->{report}{transfer}{registers}, [qw(reg0 reg1)], 'sideband data16 back-to-back report preserves selected two-register list');
    is_deeply(
        [map { $_->{address}{value} } @{$result->{report}{bindings}{storage}{registers}}],
        [0, 2],
        'sideband data16 back-to-back report preserves selected 2-byte register addresses',
    );

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(input PWDATA \(width 16\)\)/, 'sideband data16 back-to-back IAL1 declares 16-bit PWDATA input');
    like($isf, qr/\(input PSTRB \(width 2\)\)/, 'sideband data16 back-to-back IAL1 declares 2-bit PSTRB input');
    like($isf, qr/\(when \(& PSEL \(! PENABLE\)\)/, 'sideband data16 back-to-back IAL1 admits adjacent setup cycles');
    like($isf, qr/\(when \(& write_q \(== addr 2\)\)/, 'sideband data16 back-to-back IAL1 decodes the selected second register');

    my $fsm = $result->{generated_ial0}{files}{'apb_completer.fsm'};
    like($fsm, qr/\(PWDATA 16\)/, 'sideband data16 back-to-back FSM preserves 16-bit PWDATA');
    like($fsm, qr/\(PSTRB 2\)/, 'sideband data16 back-to-back FSM preserves 2-bit PSTRB');
    like($fsm, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'sideband data16 back-to-back FSM samples address under adjacent setup guard');
    like($fsm, qr/\(reg1_data_q 16 \(reset 0\)\)/, 'sideband data16 back-to-back FSM preserves 16-bit second register metadata');
    like($fsm, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'sideband data16 back-to-back FSM masks register 1 high-byte writes with 16-bit masks');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'sideband data16 back-to-back completer removes broad back-to-back residue');
    ok(!$residue{apb_alternate_widths_deferred}, 'sideband data16 back-to-back completer keeps broad alternate-width residue absent');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'sideband data16 back-to-back completer keeps narrowed future-policy residue');
    ok($residue{apb_remaining_widths_deferred}, 'sideband data16 back-to-back completer keeps narrowed remaining-width residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'sideband data16 back-to-back completer keeps protection-policy effects deferred');
};

subtest 'adapter parses the selected APB multi-register sideband data16 protection completer PPIF shape' => sub {
    ok(-f sample_apb_completer_multi_register_sideband_data16_protection_ppif_path(), 'tracked runnable APB multi-register sideband data16 protection completer PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_protection_ppif_path());

    is($result->{layer}, 'IAL2', 'APB multi-register sideband data16 protection completer adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.apb_completer', 'adapter returns the APB completer kind for sideband data16 protection source');
    is($result->{report}{source_object}{id}, 'fsmgen-apb-completer-multi-register-sideband-data16-protection', 'sideband data16 protection source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'apb_completer_multi_register_sideband_data16_protection', 'sideband data16 protection intent name is preserved');
    is($result->{report}{width_policy}{data_width}, 16, 'sideband data16 protection report records 16-bit data width');
    is($result->{report}{width_policy}{strobe_width}, 2, 'sideband data16 protection report records 2-bit strobe width');
    is($result->{report}{width_policy}{selected_contract}, 'sideband_data16', 'sideband data16 protection report keeps the selected data16 contract');
    is_deeply(
        [map { $_->{address}{value} } @{$result->{report}{bindings}{storage}{registers}}],
        [0, 2],
        'sideband data16 protection report preserves 2-byte decoded addresses',
    );

    my $policy = $result->{report}{protection_policy};
    is($policy->{scope}, 'register', 'sideband data16 protection policy report is register-scoped');
    is($policy->{predicate_namespace}, 'fsmgen_apb_pprot_v1', 'sideband data16 protection policy report names the predicate namespace');
    is($policy->{predicate_source}{bus_signal}, 'PPROT', 'sideband data16 protection policy report names bus-side PPROT');
    is($policy->{predicate_source}{sampled_signal}, 'prot_q', 'sideband data16 protection policy report names sampled PPROT local');
    is($policy->{registers}[0]{write}{predicate}{value}, 1, 'sideband data16 reg0 write requires privileged PPROT');
    is($policy->{registers}[1]{read}{predicate}{value}, 1, 'sideband data16 reg1 read requires privileged PPROT');
    is($policy->{registers}[1]{write}{predicate}{value}, 1, 'sideband data16 reg1 write requires privileged PPROT');

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(input PWDATA \(width 16\)\)/, 'generated IAL1 declares 16-bit PWDATA input for data16 protection');
    like($isf, qr/\(input PSTRB \(width 2\)\)/, 'generated IAL1 declares 2-bit PSTRB input for data16 protection');
    like($isf, qr/\(sample PPROT as prot_q\)/, 'generated IAL1 samples PPROT for data16 protection');
    like($isf, qr/\(when \(& write_q \(== addr 2\) \(!= \(& prot_q 3'd1\) 3'd0\)\)/, 'generated IAL1 gates reg1 writes by PPROT at data16 address 2');
    like($isf, qr/\(when \(& \(! write_q\) \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)\n      \(drive error_complete\)\)/, 'generated IAL1 errors denied reg1 data16 reads');
    like($isf, qr/\(when-bit strb_q 1\s+\(set reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/s, 'generated IAL1 preserves data16 high-byte write mask under PSTRB bit 1');

    my $fsm = $result->{generated_ial0}{files}{'apb_completer.fsm'};
    like($fsm, qr/\(PSTRB 2\)/, 'generated IAL0 preserves PSTRB width 2 for data16 protection');
    like($fsm, qr/\(PRDATA 16\)/, 'generated IAL0 preserves PRDATA width 16 for data16 protection');
    like($fsm, qr/\(reg1_data_q 16 \(reset 0\)\)/, 'generated IAL0 preserves 16-bit protected second register metadata');
    like($fsm, qr/\(<= \(prot_q PPROT\) <\(& PSEL \(! PENABLE\)\)\)/, 'generated IAL0 samples PPROT under setup-detect guard for data16 protection');
    like($fsm, qr/\(\?\(& write_q \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'generated IAL0 keeps denied data16 reg1 write branch');
    like($fsm, qr/\(\?\(& \(! write_q\) \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'generated IAL0 keeps denied data16 reg1 read branch');
    like($fsm, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'generated IAL0 preserves data16 high-byte write mask under policy gate');
    like($fsm, qr/\(<- \(PRDATA> 0\) <error_complete_start\)/, 'generated IAL0 denied data16 reads drive zero PRDATA');
    like($fsm, qr/\(<- \(PSLVERR> 1\) <error_complete_start\)/, 'generated IAL0 denied data16 accesses drive PSLVERR');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok(!$residue{apb_protection_policy_effects_deferred}, 'sideband data16 protection completer report removes old protection-policy-effects residue');
    ok(!$residue{apb_alternate_widths_deferred}, 'sideband data16 protection completer report keeps broad alternate-width residue absent');
    ok($residue{apb_additional_protection_policies_deferred}, 'sideband data16 protection completer report keeps additional protection-policy families deferred');
    ok($residue{apb_remaining_widths_deferred}, 'sideband data16 protection completer report keeps narrowed remaining-width residue');
};

subtest 'adapter rejects malformed APB completer PPIF shapes with targeted diagnostics' => sub {
    my $profile_mismatch = sample_apb_completer_ppif();
    $profile_mismatch =~ s/\(profile apb\)/(profile axi4)/;

    my $missing_storage = sample_apb_completer_ppif();
    $missing_storage =~ s/\n    \(storage\n      \(register reg0\n        \(address 0 width 32\)\n        \(data reg_data_q width 32 reset 0\)\)\)//;

    my $bad_setup = sample_apb_completer_ppif();
    $bad_setup =~ s/\(setup-detect \(select 1\) \(enable 0\)\)/(setup-detect (select 0) (enable 0))/;

    my $bad_wait_width = sample_apb_completer_ppif();
    $bad_wait_width =~ s/\(wait-cycles wait_cycles width 4\)/(wait-cycles wait_cycles width 8)/;

    my $empty_storage = sample_apb_completer_ppif();
    $empty_storage =~ s/\n      \(register reg0\n        \(address 0 width 32\)\n        \(data reg_data_q width 32 reset 0\)\)//;

    my $duplicate_register_name = sample_apb_completer_multi_register_ppif();
    $duplicate_register_name =~ s/\(register reg1/(register reg0/;

    my $duplicate_data_signal = sample_apb_completer_multi_register_ppif();
    $duplicate_data_signal =~ s/\(data reg1_data_q width 32 reset 0\)/(data reg0_data_q width 32 reset 0)/;

    my $duplicate_address = sample_apb_completer_multi_register_ppif();
    $duplicate_address =~ s/\(address 4 width 32\)/(address 0 width 32)/;

    my $unaligned_address = sample_apb_completer_multi_register_ppif();
    $unaligned_address =~ s/\(address 4 width 32\)/(address 2 width 32)/;

    my $negative_address = sample_apb_completer_multi_register_ppif();
    $negative_address =~ s/\(address 4 width 32\)/(address -4 width 32)/;

    my $bad_address_width = sample_apb_completer_multi_register_ppif();
    $bad_address_width =~ s/\(address 4 width 32\)/(address 4 width 16)/;

    my $bad_data_width = sample_apb_completer_multi_register_ppif();
    $bad_data_width =~ s/\(data reg1_data_q width 32 reset 0\)/(data reg1_data_q width 16 reset 0)/;

    my $bad_data_reset = sample_apb_completer_multi_register_ppif();
    $bad_data_reset =~ s/\(data reg1_data_q width 32 reset 0\)/(data reg1_data_q width 32 reset 1)/;

    my $partial_sideband = sample_apb_completer_multi_register_sideband_ppif();
    $partial_sideband =~ s/\n      \(strobe PSTRB width 4\)//;

    my $bad_strobe_width = sample_apb_completer_multi_register_sideband_ppif();
    $bad_strobe_width =~ s/\(strobe PSTRB width 4\)/(strobe PSTRB width 8)/;

    my $bad_data16_strobe_width = sample_apb_completer_multi_register_sideband_data16_ppif();
    $bad_data16_strobe_width =~ s/\(strobe PSTRB width 2\)/(strobe PSTRB width 4)/;

    my $bad_data16_back_to_back_reg1_address = sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif();
    $bad_data16_back_to_back_reg1_address =~ s/\(address 2 width 32\)/(address 4 width 32)/;

    my $bad_data16_back_to_back_access_policy = sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif();
    $bad_data16_back_to_back_access_policy =~ s/\(data reg1_data_q width 16 reset 0\)/(data reg1_data_q width 16 reset 0)\n        (access-policy\n          (read allow)\n          (write require (privileged 1)))/;

    my $policy_without_sidebands = sample_apb_completer_multi_register_sideband_protection_ppif();
    $policy_without_sidebands =~ s/\n      \(protection PPROT width 3\)//;
    $policy_without_sidebands =~ s/\n      \(strobe PSTRB width 4\)//;

    my $single_register_policy = sample_apb_completer_ppif();
    $single_register_policy =~ s/\(data reg_data_q width 32 reset 0\)/(data reg_data_q width 32 reset 0)\n        (access-policy\n          (read allow)\n          (write require (privileged 1)))/;
    $single_register_policy =~ s/\n      \(read-data PRDATA width 32\)/\n      (protection PPROT width 3)\n      (strobe PSTRB width 4)\n      (read-data PRDATA width 32)/;

    my $duplicate_access_policy = sample_apb_completer_multi_register_sideband_protection_ppif();
    $duplicate_access_policy =~ s/(\(access-policy\n          \(read allow\)\n          \(write require \(privileged 1\)\)\))/$1\n        $1/;

    my $missing_policy_read = sample_apb_completer_multi_register_sideband_protection_ppif();
    $missing_policy_read =~ s/\n          \(read allow\)//;

    my $unsupported_policy_action = sample_apb_completer_multi_register_sideband_protection_ppif();
    $unsupported_policy_action =~ s/\(read allow\)/(read deny)/;

    my $require_without_predicate = sample_apb_completer_multi_register_sideband_protection_ppif();
    $require_without_predicate =~ s/\(write require \(privileged 1\)\)/(write require)/;

    my $unsupported_policy_predicate = sample_apb_completer_multi_register_sideband_protection_ppif();
    $unsupported_policy_predicate =~ s/\(write require \(privileged 1\)\)/(write require (secure 1))/;

    my $bad_policy_predicate_value = sample_apb_completer_multi_register_sideband_protection_ppif();
    $bad_policy_predicate_value =~ s/\(write require \(privileged 1\)\)/(write require (privileged 2))/;

    my $allow_with_predicate = sample_apb_completer_multi_register_sideband_protection_ppif();
    $allow_with_predicate =~ s/\(read allow\)/(read allow (privileged 1))/;

    my $bad_setup_admission = slurp(sample_apb_completer_back_to_back_ppif_path());
    $bad_setup_admission =~ s/\(setup-admission adjacent\)/(setup-admission idle-gap)/;

    my @cases = (
        ['apb completer profile mismatch', $profile_mismatch, qr/profile 'axi4' does not match \(apb-completer \.\.\.\); expected apb/],
        ['apb completer missing storage', $missing_storage, qr/is missing required \(storage \.\.\.\) clause/],
        ['apb completer wrong setup select', $bad_setup, qr/transfer\.setup_detect\.select must be 1/],
        ['apb completer wrong wait width', $bad_wait_width, qr/control\.wait_cycles\.width must be 4/],
        ['apb completer empty storage', $empty_storage, qr/requires at least one \(register \.\.\.\) clause/],
        ['apb completer duplicate register name', $duplicate_register_name, qr/duplicate storage register name 'reg0'/],
        ['apb completer duplicate data signal', $duplicate_data_signal, qr/duplicate storage register data signal 'reg0_data_q'/],
        ['apb completer duplicate address', $duplicate_address, qr/duplicate storage register address '0'/],
        ['apb completer unaligned address', $unaligned_address, qr/storage\.registers\[1\]\.address\.value must be 4-byte aligned/],
        ['apb completer negative address', $negative_address, qr/field 'storage\.registers\[1\]\.address\.value' must be an integer/],
        ['apb completer bad address width', $bad_address_width, qr/storage\.registers\[1\]\.address\.width must be 32/],
        ['apb completer bad data width', $bad_data_width, qr/storage\.registers\[1\]\.data\.width must be 32/],
        ['apb completer bad data reset', $bad_data_reset, qr/storage\.registers\[1\]\.data\.reset must be 0/],
        ['apb completer partial sideband bundle', $partial_sideband, qr/requires bus\.protection and bus\.strobe together/],
        ['apb completer bad strobe width', $bad_strobe_width, qr/bus\.strobe\.width must be one of 2, 4/],
        ['apb completer bad data16 strobe width', $bad_data16_strobe_width, qr/bus\.strobe\.width must be 2 for selected APB data width 16/],
        ['apb completer data16 back-to-back wrong selected register address', $bad_data16_back_to_back_reg1_address, qr/selected setup-admission adjacent policy supports only the selected 32-bit no-sideband one-register, selected 32-bit sideband-aware one-register, selected 32-bit sideband-aware two-register no-policy, or selected sideband-aware data16 two-register no-policy completer families in this slice/],
        ['apb completer data16 back-to-back access-policy', $bad_data16_back_to_back_access_policy, qr/selected setup-admission adjacent policy supports only the selected 32-bit no-sideband one-register, selected 32-bit sideband-aware one-register, selected 32-bit sideband-aware two-register no-policy, or selected sideband-aware data16 two-register no-policy completer families in this slice/],
        ['apb completer access-policy without sidebands', $policy_without_sidebands, qr/access-policy requires bus\.protection and bus\.strobe sideband bindings/],
        ['apb completer access-policy single register', $single_register_policy, qr/access-policy requires multi-register storage/],
        ['apb completer duplicate access-policy', $duplicate_access_policy, qr/has duplicate \(access-policy \.\.\.\) clause/],
        ['apb completer access-policy missing read', $missing_policy_read, qr/is missing required \(read \.\.\.\) clause/],
        ['apb completer access-policy unsupported action', $unsupported_policy_action, qr/supports only action allow or require/],
        ['apb completer access-policy require without predicate', $require_without_predicate, qr/require \.\.\.\) requires exactly one predicate clause/],
        ['apb completer access-policy unsupported predicate', $unsupported_policy_predicate, qr/supports only \(privileged 0\) or \(privileged 1\)/],
        ['apb completer access-policy bad predicate value', $bad_policy_predicate_value, qr/requires exactly one scalar value 0 or 1/],
        ['apb completer access-policy allow with predicate', $allow_with_predicate, qr/allow \.\.\.\) does not accept predicates/],
        ['apb completer unsupported setup admission', $bad_setup_admission, qr/timing-policy supports only \(setup-admission adjacent\) in this slice/],
    );

    for my $case (@cases) {
        my ($label, $source, $pattern) = @$case;
        my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($source, "$label.ppif"); 1 };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI check and semantic JSON support-account APB multi-register completer PPIF identity' => sub {
    my $path = sample_apb_completer_multi_register_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'APB multi-register completer --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'APB multi-register completer --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'APB multi-register completer check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'APB multi-register completer check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register', 'APB multi-register completer check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'APB multi-register completer check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'APB multi-register completer --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'APB multi-register completer --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'APB multi-register completer semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register', 'APB multi-register completer semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'fsm', 'APB multi-register completer semantic JSON payload describes the generated .fsm semantic root');
    is($semantic_report->{semantic}{module}{name}, 'apb_completer', 'APB multi-register completer semantic JSON records the generated module');
};

subtest 'CLI check and semantic JSON support-account APB multi-register sideband completer PPIF identity' => sub {
    my $path = sample_apb_completer_multi_register_sideband_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'APB multi-register sideband completer --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'APB multi-register sideband completer --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'APB multi-register sideband completer check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'APB multi-register sideband completer check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register_sideband', 'APB multi-register sideband completer check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'APB multi-register sideband completer check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'APB multi-register sideband completer --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'APB multi-register sideband completer --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'APB multi-register sideband completer semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register_sideband', 'APB multi-register sideband completer semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'fsm', 'APB multi-register sideband completer semantic JSON payload describes the generated .fsm semantic root');
    is($semantic_report->{semantic}{module}{name}, 'apb_completer', 'APB multi-register sideband completer semantic JSON records the generated module');
};

subtest 'CLI check and semantic JSON support-account APB multi-register sideband protection completer PPIF identity' => sub {
    my $path = sample_apb_completer_multi_register_sideband_protection_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'APB multi-register sideband protection completer --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'APB multi-register sideband protection completer --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'APB multi-register sideband protection completer check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'APB multi-register sideband protection completer check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register_sideband_protection', 'APB multi-register sideband protection completer check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'APB multi-register sideband protection completer check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'APB multi-register sideband protection completer --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'APB multi-register sideband protection completer --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'APB multi-register sideband protection completer semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register_sideband_protection', 'APB multi-register sideband protection completer semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'fsm', 'APB multi-register sideband protection completer semantic JSON payload describes the generated .fsm semantic root');
    is($semantic_report->{semantic}{module}{name}, 'apb_completer', 'APB multi-register sideband protection completer semantic JSON records the generated module');
};

subtest 'CLI check and semantic JSON support-account APB multi-register sideband data16 completer PPIF identity' => sub {
    my $path = sample_apb_completer_multi_register_sideband_data16_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'APB multi-register sideband data16 completer --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'APB multi-register sideband data16 completer --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'APB multi-register sideband data16 completer check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'APB multi-register sideband data16 completer check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register_sideband_data16', 'APB multi-register sideband data16 completer check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'APB multi-register sideband data16 completer check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'APB multi-register sideband data16 completer --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'APB multi-register sideband data16 completer --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'APB multi-register sideband data16 completer semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register_sideband_data16', 'APB multi-register sideband data16 completer semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'fsm', 'APB multi-register sideband data16 completer semantic JSON payload describes the generated .fsm semantic root');
    is($semantic_report->{semantic}{module}{name}, 'apb_completer', 'APB multi-register sideband data16 completer semantic JSON records the generated module');
};

subtest 'CLI check and semantic JSON support-account APB multi-register sideband data16 back-to-back completer PPIF identity' => sub {
    my $path = sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'APB multi-register sideband data16 back-to-back completer --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'APB multi-register sideband data16 back-to-back completer --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'APB multi-register sideband data16 back-to-back completer check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'APB multi-register sideband data16 back-to-back completer check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register_sideband_data16_back_to_back', 'APB multi-register sideband data16 back-to-back completer check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'APB multi-register sideband data16 back-to-back completer check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'APB multi-register sideband data16 back-to-back completer --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'APB multi-register sideband data16 back-to-back completer --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'APB multi-register sideband data16 back-to-back completer semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register_sideband_data16_back_to_back', 'APB multi-register sideband data16 back-to-back completer semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'fsm', 'APB multi-register sideband data16 back-to-back completer semantic JSON payload describes the generated .fsm semantic root');
    is($semantic_report->{semantic}{module}{name}, 'apb_completer', 'APB multi-register sideband data16 back-to-back completer semantic JSON records the generated module');
};

subtest 'CLI check and semantic JSON support-account APB multi-register sideband data16 protection completer PPIF identity' => sub {
    my $path = sample_apb_completer_multi_register_sideband_data16_protection_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'APB multi-register sideband data16 protection completer --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'APB multi-register sideband data16 protection completer --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'APB multi-register sideband data16 protection completer check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'APB multi-register sideband data16 protection completer check JSON reports the public .ppif source path');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register_sideband_data16_protection', 'APB multi-register sideband data16 protection completer check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'APB multi-register sideband data16 protection completer check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'APB multi-register sideband data16 protection completer --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'APB multi-register sideband data16 protection completer --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'APB multi-register sideband data16 protection completer semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer_multi_register_sideband_data16_protection', 'APB multi-register sideband data16 protection completer semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'fsm', 'APB multi-register sideband data16 protection completer semantic JSON payload describes the generated .fsm semantic root');
    is($semantic_report->{semantic}{module}{name}, 'apb_completer', 'APB multi-register sideband data16 protection completer semantic JSON records the generated module');
};

subtest 'CLI check and semantic JSON support-account APB completer PPIF identity' => sub {
    my $path = sample_apb_completer_ppif_path();
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $path],
    );
    ok($check_success, 'APB completer --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'APB completer --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'APB completer check JSON reports success');
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'APB completer check JSON reports the public .ppif source path');
    ok($check_report->{support_accounting}{matched}, 'APB completer check JSON support accounting matches the PPIF sample');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer', 'APB completer check JSON names the corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'APB completer check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );
    ok($semantic_success, 'APB completer --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'APB completer --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'APB completer semantic JSON reports success');
    is($semantic_report->{source}{resolved_path}, File::Spec->rel2abs($path), 'APB completer semantic JSON reports the public .ppif source path');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_apb_completer', 'APB completer semantic JSON names the corpus entry');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'fsm', 'APB completer semantic JSON payload describes the generated .fsm semantic root');
    is($semantic_report->{semantic}{module}{name}, 'apb_completer', 'APB completer semantic JSON records the generated module');
};

subtest 'CLI schedule JSON and outdir expose APB multi-register completer review artifacts and HDL' => sub {
    my $path = sample_apb_completer_multi_register_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'APB multi-register completer --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'APB multi-register completer --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is_deeply($schedule_report->{transfer}{registers}, [qw(reg0 reg1)], 'APB multi-register completer schedule JSON reports register list');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_multi_register_decode_deferred}, 'APB multi-register completer schedule JSON removes multi-register deferred residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_completer_multi.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'APB multi-register completer CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'APB multi-register completer generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.isf'), 'APB multi-register completer --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.fsm'), 'APB multi-register completer --outdir writes generated .fsm');
    ok(-f $hdl, 'APB multi-register completer --output writes generated HDL');
    like(slurp(File::Spec->catfile($outdir, 'apb_completer.fsm')), qr/\(<- \(PRDATA> reg1_data_q\) <read_reg1_hit_start\)/, 'APB multi-register outdir .fsm reads second register');
    my $sv = slurp($hdl);
    like($sv, qr/\breg \[31:0\] reg0_data_q\b/, 'APB multi-register HDL carries first storage register');
    like($sv, qr/\breg \[31:0\] reg1_data_q\b/, 'APB multi-register HDL carries second storage register');
    like($sv, qr/PRDATA_next = reg1_data_q;/, 'APB multi-register HDL can mux PRDATA from second storage register');
};

subtest 'CLI schedule JSON and outdir expose APB multi-register sideband completer review artifacts and HDL' => sub {
    my $path = sample_apb_completer_multi_register_sideband_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'APB multi-register sideband completer --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'APB multi-register sideband completer --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is_deeply($schedule_report->{transfer}{registers}, [qw(reg0 reg1)], 'APB multi-register sideband completer schedule JSON reports register list');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_protection_and_strobes_deferred}, 'APB multi-register sideband completer schedule JSON omits broad sideband residue');
    ok($residue{apb_protection_policy_effects_deferred}, 'APB multi-register sideband completer schedule JSON reports protection-policy residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_completer_multi_sideband.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'APB multi-register sideband completer CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'APB multi-register sideband completer generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.isf'), 'APB multi-register sideband completer --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.fsm'), 'APB multi-register sideband completer --outdir writes generated .fsm');
    ok(-f $hdl, 'APB multi-register sideband completer --output writes generated HDL');
    my $fsm = slurp(File::Spec->catfile($outdir, 'apb_completer.fsm'));
    like($fsm, qr/\(<= \(prot_q PPROT\) <\(& PSEL \(! PENABLE\)\)\)/, 'APB multi-register sideband outdir .fsm samples PPROT');
    like($fsm, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 32'h00ffffff\) \(& wdata_q 32'hff000000\)\)\)\)/, 'APB multi-register sideband outdir .fsm applies high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+wire\s+\[2:0\]\s+PPROT\b/, 'APB multi-register sideband HDL exposes PPROT');
    like($sv, qr/\binput\s+wire\s+\[3:0\]\s+PSTRB\b/, 'APB multi-register sideband HDL exposes PSTRB');
    like($sv, qr/strb_q\s*&\s*4'd8/, 'APB multi-register sideband HDL preserves PSTRB bit 3 gating');
};

subtest 'CLI schedule JSON and outdir expose APB multi-register sideband protection completer review artifacts and HDL' => sub {
    my $path = sample_apb_completer_multi_register_sideband_protection_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'APB multi-register sideband protection completer --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'APB multi-register sideband protection completer --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{protection_policy}{scope}, 'register', 'APB multi-register sideband protection schedule JSON reports register policy scope');
    is($schedule_report->{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'APB multi-register sideband protection schedule JSON reports reg1 read predicate');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_protection_policy_effects_deferred}, 'APB multi-register sideband protection schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_protection_policies_deferred}, 'APB multi-register sideband protection schedule JSON reports additional-policy residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_completer_multi_sideband_protection.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'APB multi-register sideband protection completer CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'APB multi-register sideband protection completer generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.isf'), 'APB multi-register sideband protection completer --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.fsm'), 'APB multi-register sideband protection completer --outdir writes generated .fsm');
    ok(-f $hdl, 'APB multi-register sideband protection completer --output writes generated HDL');
    my $isf = slurp(File::Spec->catfile($outdir, 'apb_completer.isf'));
    like($isf, qr/\(when \(& write_q \(== addr 4\) \(!= \(& prot_q 3'd1\) 3'd0\)\)/, 'APB protection outdir .isf gates reg1 writes by PPROT');
    like($isf, qr/\(when \(& write_q \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)\n      \(drive error_complete\)\)/, 'APB protection outdir .isf errors denied reg1 writes');
    my $fsm = slurp(File::Spec->catfile($outdir, 'apb_completer.fsm'));
    like($fsm, qr/\(\?\(& write_q \(== addr 4\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'APB protection outdir .fsm keeps denied reg1 write branch');
    my $sv = slurp($hdl);
    like($sv, qr/prot_q\s*&\s*3'd1/, 'APB protection HDL preserves PPROT bit 0 predicate logic');
    like($sv, qr/PSLVERR_next = 1;/, 'APB protection HDL preserves denied-access PSLVERR drive');
    like($sv, qr/PRDATA_next = 0;/, 'APB protection HDL preserves denied-read zero PRDATA drive');
};

subtest 'CLI schedule JSON and outdir expose APB multi-register sideband data16 completer review artifacts and HDL' => sub {
    my $path = sample_apb_completer_multi_register_sideband_data16_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'APB multi-register sideband data16 completer --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'APB multi-register sideband data16 completer --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{width_policy}{data_width}, 16, 'APB multi-register sideband data16 schedule JSON reports data width 16');
    is($schedule_report->{width_policy}{strobe_width}, 2, 'APB multi-register sideband data16 schedule JSON reports PSTRB width 2');
    is($schedule_report->{width_policy}{register_alignment_bytes}, 2, 'APB multi-register sideband data16 schedule JSON reports 2-byte alignment');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_alternate_widths_deferred}, 'APB multi-register sideband data16 schedule JSON omits broad alternate-width residue');
    ok($residue{apb_remaining_widths_deferred}, 'APB multi-register sideband data16 schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_completer_multi_sideband_data16.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'APB multi-register sideband data16 completer CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'APB multi-register sideband data16 completer generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.isf'), 'APB multi-register sideband data16 completer --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.fsm'), 'APB multi-register sideband data16 completer --outdir writes generated .fsm');
    ok(-f $hdl, 'APB multi-register sideband data16 completer --output writes generated HDL');
    my $fsm = slurp(File::Spec->catfile($outdir, 'apb_completer.fsm'));
    like($fsm, qr/\(PSTRB 2\)/, 'APB multi-register sideband data16 outdir .fsm preserves PSTRB width 2');
    like($fsm, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'APB multi-register sideband data16 outdir .fsm applies high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+wire\s+\[15:0\]\s+PWDATA\b/, 'APB multi-register sideband data16 HDL exposes 16-bit PWDATA');
    like($sv, qr/\binput\s+wire\s+\[1:0\]\s+PSTRB\b/, 'APB multi-register sideband data16 HDL exposes 2-bit PSTRB');
    like($sv, qr/\breg\s+\[15:0\]\s+reg1_data_q\b/, 'APB multi-register sideband data16 HDL carries 16-bit second register');
    like($sv, qr/strb_q\s*&\s*2'd2/, 'APB multi-register sideband data16 HDL preserves PSTRB bit 1 gating');
};

subtest 'CLI schedule JSON, outdir, and .apb alias expose APB multi-register sideband data16 back-to-back completer review artifacts and HDL' => sub {
    my $path = sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'APB multi-register sideband data16 back-to-back completer --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'APB multi-register sideband data16 back-to-back completer --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{width_policy}{data_width}, 16, 'APB multi-register sideband data16 back-to-back schedule JSON reports data width 16');
    is($schedule_report->{width_policy}{strobe_width}, 2, 'APB multi-register sideband data16 back-to-back schedule JSON reports PSTRB width 2');
    is($schedule_report->{transfer}{timing_policy}{setup_admission}, 'adjacent', 'APB multi-register sideband data16 back-to-back schedule JSON reports adjacent setup admission');
    is_deeply($schedule_report->{transfer}{registers}, [qw(reg0 reg1)], 'APB multi-register sideband data16 back-to-back schedule JSON reports selected register list');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_back_to_back_policy_deferred}, 'APB multi-register sideband data16 back-to-back schedule JSON omits broad back-to-back residue');
    ok($residue{apb_additional_back_to_back_policies_deferred}, 'APB multi-register sideband data16 back-to-back schedule JSON reports narrowed back-to-back residue');
    ok($residue{apb_remaining_widths_deferred}, 'APB multi-register sideband data16 back-to-back schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_completer_multi_sideband_data16_back_to_back.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'APB multi-register sideband data16 back-to-back completer CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'APB multi-register sideband data16 back-to-back completer generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.isf'), 'APB multi-register sideband data16 back-to-back completer --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.fsm'), 'APB multi-register sideband data16 back-to-back completer --outdir writes generated .fsm');
    ok(-f $hdl, 'APB multi-register sideband data16 back-to-back completer --output writes generated HDL');
    my $fsm = slurp(File::Spec->catfile($outdir, 'apb_completer.fsm'));
    like($fsm, qr/\(<= \(addr PADDR\) <\(& PSEL \(! PENABLE\)\)\)/, 'APB multi-register sideband data16 back-to-back outdir .fsm samples adjacent setup');
    like($fsm, qr/\(PSTRB 2\)/, 'APB multi-register sideband data16 back-to-back outdir .fsm preserves PSTRB width 2');
    like($fsm, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'APB multi-register sideband data16 back-to-back outdir .fsm applies high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+wire\s+\[15:0\]\s+PWDATA\b/, 'APB multi-register sideband data16 back-to-back HDL exposes 16-bit PWDATA');
    like($sv, qr/\binput\s+wire\s+\[1:0\]\s+PSTRB\b/, 'APB multi-register sideband data16 back-to-back HDL exposes 2-bit PSTRB');
    like($sv, qr/\breg\s+\[15:0\]\s+reg1_data_q\b/, 'APB multi-register sideband data16 back-to-back HDL carries 16-bit second register');

    ok(-f sample_apb_completer_multi_register_sideband_data16_back_to_back_apb_path(), 'tracked runnable APB multi-register sideband data16 back-to-back completer .apb sample exists');
    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_back_to_back_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_completer', '.apb APB multi-register sideband data16 back-to-back completer alias returns the completer kind');
    is($alias->{generated_ial1}{text}, $ppif->{generated_ial1}{text}, '.apb APB multi-register sideband data16 back-to-back completer alias mirrors .ppif generated IAL1');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, '.apb APB multi-register sideband data16 back-to-back completer alias mirrors .ppif generated IAL0');
    is($alias->{report}{transfer}{timing_policy}{setup_admission}, 'adjacent', '.apb APB multi-register sideband data16 back-to-back completer alias preserves adjacent timing policy');
};

subtest 'CLI schedule JSON and outdir expose APB multi-register sideband data16 protection completer review artifacts and HDL' => sub {
    my $path = sample_apb_completer_multi_register_sideband_data16_protection_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'APB multi-register sideband data16 protection completer --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'APB multi-register sideband data16 protection completer --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{width_policy}{data_width}, 16, 'APB multi-register sideband data16 protection schedule JSON reports data width 16');
    is($schedule_report->{width_policy}{strobe_width}, 2, 'APB multi-register sideband data16 protection schedule JSON reports PSTRB width 2');
    is($schedule_report->{protection_policy}{scope}, 'register', 'APB multi-register sideband data16 protection schedule JSON reports register policy scope');
    is($schedule_report->{protection_policy}{registers}[1]{read}{predicate}{value}, 1, 'APB multi-register sideband data16 protection schedule JSON reports reg1 read predicate');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{apb_protection_policy_effects_deferred}, 'APB multi-register sideband data16 protection schedule JSON omits old policy-effects residue');
    ok($residue{apb_additional_protection_policies_deferred}, 'APB multi-register sideband data16 protection schedule JSON reports additional-policy residue');
    ok($residue{apb_remaining_widths_deferred}, 'APB multi-register sideband data16 protection schedule JSON reports narrowed remaining-width residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_completer_multi_sideband_data16_protection.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'APB multi-register sideband data16 protection completer CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'APB multi-register sideband data16 protection completer generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.isf'), 'APB multi-register sideband data16 protection completer --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.fsm'), 'APB multi-register sideband data16 protection completer --outdir writes generated .fsm');
    ok(-f $hdl, 'APB multi-register sideband data16 protection completer --output writes generated HDL');
    my $fsm = slurp(File::Spec->catfile($outdir, 'apb_completer.fsm'));
    like($fsm, qr/\(PSTRB 2\)/, 'APB multi-register sideband data16 protection outdir .fsm preserves PSTRB width 2');
    like($fsm, qr/\(\?\(& write_q \(== addr 2\) \(! \(!= \(& prot_q 3'd1\) 3'd0\)\)\)/, 'APB multi-register sideband data16 protection outdir .fsm keeps denied reg1 write branch');
    like($fsm, qr/\(<- \(reg1_data_q \(\| \(& reg1_data_q 16'h00ff\) \(& wdata_q 16'hff00\)\)\)\)/, 'APB multi-register sideband data16 protection outdir .fsm applies high-byte write mask');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+wire\s+\[15:0\]\s+PWDATA\b/, 'APB multi-register sideband data16 protection HDL exposes 16-bit PWDATA');
    like($sv, qr/\binput\s+wire\s+\[1:0\]\s+PSTRB\b/, 'APB multi-register sideband data16 protection HDL exposes 2-bit PSTRB');
    like($sv, qr/\breg\s+\[15:0\]\s+reg1_data_q\b/, 'APB multi-register sideband data16 protection HDL carries 16-bit second register');
    like($sv, qr/prot_q\s*&\s*3'd1/, 'APB multi-register sideband data16 protection HDL preserves PPROT bit 0 predicate logic');
    like($sv, qr/PSLVERR_next = 1;/, 'APB multi-register sideband data16 protection HDL preserves denied-access PSLVERR drive');
    like($sv, qr/PRDATA(?:_next)?\s*(?:<=|=)\s*(?:16'h0000|0);/, 'APB multi-register sideband data16 protection HDL preserves denied-read zero PRDATA drive');
};

subtest 'CLI schedule JSON and outdir expose APB completer review artifacts and HDL' => sub {
    my $path = sample_apb_completer_ppif_path();
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );
    ok($schedule_success, 'APB completer --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'APB completer --emit-schedule-json keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.apb_completer.v1', 'APB completer schedule JSON reports schema');
    is($schedule_report->{target_protocol}{profile}, 'apb', 'APB completer schedule JSON reports the APB profile');
    is($schedule_report->{target_protocol}{object}, 'apb-completer', 'APB completer schedule JSON reports the APB completer object');
    is($schedule_report->{layering}{direct_ial2_to_ial0}, 0, 'APB completer schedule JSON keeps direct IAL2-to-IAL0 forbidden');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_completer.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $path],
    );

    ok($success, 'APB completer CLI generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'APB completer generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.isf'), 'APB completer --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'apb_completer.fsm'), 'APB completer --outdir writes generated .fsm');
    ok(-f $hdl, 'APB completer --output writes generated HDL');
    like(slurp(File::Spec->catfile($outdir, 'apb_completer.isf')), qr/\(actor apb_completer\b/, 'APB completer generated .isf is inspectable text');
    like(slurp(File::Spec->catfile($outdir, 'apb_completer.fsm')), qr/\(\?fsm:apb_completer\b/, 'APB completer generated .fsm is inspectable text');
    my $sv = slurp($hdl);
    like($sv, qr/\bmodule\s+apb_completer\b/, 'APB completer HDL contains the generated module');
    like($sv, qr/\breg_data_q\b/, 'APB completer HDL carries the storage register');
    like($sv, qr/\bPREADY\b/, 'APB completer HDL carries PREADY');
    like($sv, qr/\bPRDATA\b/, 'APB completer HDL carries PRDATA');
    like($sv, qr/\bPSLVERR\b/, 'APB completer HDL carries PSLVERR');
};

subtest '.apb alias accepts APB completer content' => sub {
    ok(-f sample_apb_completer_apb_path(), 'tracked runnable APB completer .apb sample exists');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_ppif_path());
    is($alias->{kind}, 'protocol_intent.apb_completer', '.apb APB completer alias returns the completer kind');
    is($alias->{generated_ial1}{text}, $ppif->{generated_ial1}{text}, '.apb APB completer alias mirrors .ppif generated IAL1');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, '.apb APB completer alias mirrors .ppif generated IAL0');

    ok(-f sample_apb_completer_sideband_back_to_back_apb_path(), 'tracked runnable APB sideband back-to-back completer .apb sample exists');
    my $sideband_btb_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_sideband_back_to_back_apb_path());
    my $sideband_btb_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_sideband_back_to_back_ppif_path());
    is($sideband_btb_alias->{kind}, 'protocol_intent.apb_completer', '.apb APB sideband back-to-back completer alias returns the completer kind');
    is($sideband_btb_alias->{generated_ial1}{text}, $sideband_btb_ppif->{generated_ial1}{text}, '.apb APB sideband back-to-back completer alias mirrors .ppif generated IAL1');
    is_deeply($sideband_btb_alias->{generated_ial0}{files}, $sideband_btb_ppif->{generated_ial0}{files}, '.apb APB sideband back-to-back completer alias mirrors .ppif generated IAL0');
    is($sideband_btb_alias->{report}{transfer}{timing_policy}{setup_admission}, 'adjacent', '.apb APB sideband back-to-back completer alias preserves adjacent timing policy');

    ok(-f sample_apb_completer_multi_register_apb_path(), 'tracked runnable APB multi-register completer .apb sample exists');
    my $multi_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_apb_path());
    my $multi_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_ppif_path());
    is($multi_alias->{kind}, 'protocol_intent.apb_completer', '.apb APB multi-register completer alias returns the completer kind');
    is($multi_alias->{generated_ial1}{text}, $multi_ppif->{generated_ial1}{text}, '.apb APB multi-register completer alias mirrors .ppif generated IAL1');
    is_deeply($multi_alias->{generated_ial0}{files}, $multi_ppif->{generated_ial0}{files}, '.apb APB multi-register completer alias mirrors .ppif generated IAL0');
    is_deeply($multi_alias->{report}{transfer}{registers}, [qw(reg0 reg1)], '.apb APB multi-register completer alias preserves transfer register list');

    ok(-f sample_apb_completer_multi_register_sideband_apb_path(), 'tracked runnable APB multi-register sideband completer .apb sample exists');
    my $sideband_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_apb_path());
    my $sideband_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_ppif_path());
    is($sideband_alias->{kind}, 'protocol_intent.apb_completer', '.apb APB multi-register sideband completer alias returns the completer kind');
    is($sideband_alias->{generated_ial1}{text}, $sideband_ppif->{generated_ial1}{text}, '.apb APB multi-register sideband completer alias mirrors .ppif generated IAL1');
    is_deeply($sideband_alias->{generated_ial0}{files}, $sideband_ppif->{generated_ial0}{files}, '.apb APB multi-register sideband completer alias mirrors .ppif generated IAL0');
    my %sideband_residue = map { $_->{id} => 1 } @{$sideband_alias->{report}{unsupported_residue}};
    ok(!$sideband_residue{apb_protection_and_strobes_deferred}, '.apb APB multi-register sideband completer alias removes broad sideband residue');

    ok(-f sample_apb_completer_multi_register_sideband_back_to_back_apb_path(), 'tracked runnable APB multi-register sideband back-to-back completer .apb sample exists');
    my $sideband_btb_multi_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_back_to_back_apb_path());
    my $sideband_btb_multi_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_back_to_back_ppif_path());
    is($sideband_btb_multi_alias->{kind}, 'protocol_intent.apb_completer', '.apb APB multi-register sideband back-to-back completer alias returns the completer kind');
    is($sideband_btb_multi_alias->{generated_ial1}{text}, $sideband_btb_multi_ppif->{generated_ial1}{text}, '.apb APB multi-register sideband back-to-back completer alias mirrors .ppif generated IAL1');
    is_deeply($sideband_btb_multi_alias->{generated_ial0}{files}, $sideband_btb_multi_ppif->{generated_ial0}{files}, '.apb APB multi-register sideband back-to-back completer alias mirrors .ppif generated IAL0');
    is($sideband_btb_multi_alias->{report}{transfer}{timing_policy}{setup_admission}, 'adjacent', '.apb APB multi-register sideband back-to-back completer alias preserves adjacent timing policy');

    ok(-f sample_apb_completer_multi_register_sideband_protection_apb_path(), 'tracked runnable APB multi-register sideband protection completer .apb sample exists');
    my $protection_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_protection_apb_path());
    my $protection_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_protection_ppif_path());
    is($protection_alias->{kind}, 'protocol_intent.apb_completer', '.apb APB multi-register sideband protection completer alias returns the completer kind');
    is($protection_alias->{generated_ial1}{text}, $protection_ppif->{generated_ial1}{text}, '.apb APB multi-register sideband protection completer alias mirrors .ppif generated IAL1');
    is_deeply($protection_alias->{generated_ial0}{files}, $protection_ppif->{generated_ial0}{files}, '.apb APB multi-register sideband protection completer alias mirrors .ppif generated IAL0');
    is($protection_alias->{report}{protection_policy}{predicate_namespace}, 'fsmgen_apb_pprot_v1', '.apb APB multi-register sideband protection completer alias preserves protection-policy metadata');

    ok(-f sample_apb_completer_multi_register_sideband_data16_apb_path(), 'tracked runnable APB multi-register sideband data16 completer .apb sample exists');
    my $data16_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_apb_path());
    my $data16_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_ppif_path());
    is($data16_alias->{kind}, 'protocol_intent.apb_completer', '.apb APB multi-register sideband data16 completer alias returns the completer kind');
    is($data16_alias->{generated_ial1}{text}, $data16_ppif->{generated_ial1}{text}, '.apb APB multi-register sideband data16 completer alias mirrors .ppif generated IAL1');
    is_deeply($data16_alias->{generated_ial0}{files}, $data16_ppif->{generated_ial0}{files}, '.apb APB multi-register sideband data16 completer alias mirrors .ppif generated IAL0');
    is($data16_alias->{report}{width_policy}{data_width}, 16, '.apb APB multi-register sideband data16 completer alias preserves data width policy');

    ok(-f sample_apb_completer_multi_register_sideband_data16_protection_apb_path(), 'tracked runnable APB multi-register sideband data16 protection completer .apb sample exists');
    my $data16_protection_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_protection_apb_path());
    my $data16_protection_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_completer_multi_register_sideband_data16_protection_ppif_path());
    is($data16_protection_alias->{kind}, 'protocol_intent.apb_completer', '.apb APB multi-register sideband data16 protection completer alias returns the completer kind');
    is($data16_protection_alias->{generated_ial1}{text}, $data16_protection_ppif->{generated_ial1}{text}, '.apb APB multi-register sideband data16 protection completer alias mirrors .ppif generated IAL1');
    is_deeply($data16_protection_alias->{generated_ial0}{files}, $data16_protection_ppif->{generated_ial0}{files}, '.apb APB multi-register sideband data16 protection completer alias mirrors .ppif generated IAL0');
    is($data16_protection_alias->{report}{width_policy}{data_width}, 16, '.apb APB multi-register sideband data16 protection completer alias preserves data width policy');
    is($data16_protection_alias->{report}{protection_policy}{predicate_namespace}, 'fsmgen_apb_pprot_v1', '.apb APB multi-register sideband data16 protection completer alias preserves protection-policy metadata');
};

done_testing();

sub sample_apb_completer_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer.ppif');
}

sub sample_apb_completer_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_back_to_back.ppif');
}

sub sample_apb_completer_sideband_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_sideband_back_to_back.ppif');
}

sub sample_apb_completer_multi_register_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register.ppif');
}

sub sample_apb_completer_multi_register_sideband_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband.ppif');
}

sub sample_apb_completer_multi_register_sideband_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_back_to_back.ppif');
}

sub sample_apb_completer_multi_register_sideband_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_protection.ppif');
}

sub sample_apb_completer_multi_register_sideband_data16_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16.ppif');
}

sub sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16_back_to_back.ppif');
}

sub sample_apb_completer_multi_register_sideband_data16_protection_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16_protection.ppif');
}

sub sample_apb_completer_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer.apb');
}

sub sample_apb_completer_sideband_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_sideband_back_to_back.apb');
}

sub sample_apb_completer_multi_register_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register.apb');
}

sub sample_apb_completer_multi_register_sideband_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband.apb');
}

sub sample_apb_completer_multi_register_sideband_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_back_to_back.apb');
}

sub sample_apb_completer_multi_register_sideband_protection_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_protection.apb');
}

sub sample_apb_completer_multi_register_sideband_data16_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16.apb');
}

sub sample_apb_completer_multi_register_sideband_data16_back_to_back_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16_back_to_back.apb');
}

sub sample_apb_completer_multi_register_sideband_data16_protection_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer_multi_register_sideband_data16_protection.apb');
}

sub sample_apb_completer_ppif {
    return slurp(sample_apb_completer_ppif_path());
}

sub sample_apb_completer_multi_register_ppif {
    return slurp(sample_apb_completer_multi_register_ppif_path());
}

sub sample_apb_completer_multi_register_sideband_ppif {
    return slurp(sample_apb_completer_multi_register_sideband_ppif_path());
}

sub sample_apb_completer_multi_register_sideband_protection_ppif {
    return slurp(sample_apb_completer_multi_register_sideband_protection_ppif_path());
}

sub sample_apb_completer_multi_register_sideband_data16_ppif {
    return slurp(sample_apb_completer_multi_register_sideband_data16_ppif_path());
}

sub sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif {
    return slurp(sample_apb_completer_multi_register_sideband_data16_back_to_back_ppif_path());
}

sub sample_apb_completer_multi_register_sideband_data16_protection_ppif {
    return slurp(sample_apb_completer_multi_register_sideband_data16_protection_ppif_path());
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
