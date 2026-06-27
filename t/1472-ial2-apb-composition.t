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

subtest 'adapter rejects malformed APB composition PPIF shapes with targeted diagnostics' => sub {
    my $missing_composition = sample_apb_composition_ppif();
    $missing_composition =~ s/\n  \(apb-composition apb_tb\n    \(role composition\)\n    \(clock clk\)\n    \(reset \(rst_n active_low async\)\)\n    \(children\n      \(requester requester apb_requester\)\n      \(completer completer apb_completer\)\)\n    \(wiring apb_bus\n      \(select PSEL\)\n      \(enable PENABLE\)\n      \(write PWRITE\)\n      \(address PADDR width 32\)\n      \(write-data PWDATA width 32\)\n      \(ready PREADY\)\n      \(read-data PRDATA width 32\)\n      \(error PSLVERR\)\)\)//;

    my $bad_child = sample_apb_composition_ppif();
    $bad_child =~ s/\(requester requester apb_requester\)/(requester requester apb_requester_other)/;

    my $bad_bus = sample_apb_composition_ppif();
    $bad_bus =~ s/\(ready PREADY\)\n      \(read-data PRDATA width 32\)\n      \(error PSLVERR\)\)\)\)\n\z/(ready PREADY_OTHER)\n      (read-data PRDATA width 32)\n      (error PSLVERR))))\n/;

    my @cases = (
        ['missing apb composition object', $missing_composition, qr/cannot mix \(apb-requester \.\.\.\) with .* \(apb-completer \.\.\.\).*outside the explicit APB composition shape/s],
        ['bad requester child reference', $bad_child, qr/APB composition requester child references .*expected 'apb_requester'/],
        ['bad ready bus wiring', $bad_bus, qr/APB composition IAL2 contract bus\.ready must be scalar signal 'PREADY_OTHER'/],
    );

    for my $case (@cases) {
        my ($label, $source, $pattern) = @$case;
        my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($source, "$label.ppif"); 1 };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
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

sub sample_apb_composition_ppif {
    return slurp(sample_apb_composition_ppif_path());
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
