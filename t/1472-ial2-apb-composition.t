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

    my @cases = (
        ['missing apb composition object', $missing_composition, qr/cannot mix \(apb-requester \.\.\.\) with .* \(apb-completer \.\.\.\).*outside the explicit APB composition shape/s],
        ['bad requester child reference', $bad_child, qr/APB composition requester child references .*expected 'apb_requester'/],
        ['bad ready bus wiring', $bad_bus, qr/APB composition IAL2 contract bus\.ready must be scalar signal 'PREADY_OTHER'/],
        ['single multi-peripheral child', $single_peripheral, qr/requires two or more peripheral children/],
        ['mixed fixed and peripheral child forms', $mixed_child_forms, qr/cannot mix fixed \(completer \.\.\.\) with multi-peripheral \(peripheral \.\.\.\) entries/],
        ['overlapping multi-peripheral windows', $overlapping_windows, qr/address-map windows 'status' and 'control' overlap/],
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

sub sample_apb_composition_status_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_status.apb');
}

sub sample_apb_composition_multi_register_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register.ppif');
}

sub sample_apb_composition_multi_register_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_register.apb');
}

sub sample_apb_composition_multi_peripheral_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral.ppif');
}

sub sample_apb_composition_multi_peripheral_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_multi_peripheral.apb');
}

sub sample_apb_composition_ppif {
    return slurp(sample_apb_composition_ppif_path());
}

sub sample_apb_composition_multi_peripheral_ppif {
    return slurp(sample_apb_composition_multi_peripheral_ppif_path());
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
