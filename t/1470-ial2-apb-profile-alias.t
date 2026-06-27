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

    my $unsupported_object_path = File::Spec->catfile($tempdir, 'valid_ready_object.apb');
    my $unsupported_object_source = slurp(sample_valid_ready_handshake_ppif_path());
    $unsupported_object_source =~ s/\(profile valid-ready\)/(profile apb)/;
    write_file($unsupported_object_path, $unsupported_object_source);
    my $unsupported_object_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($unsupported_object_path); 1 };
    ok(!$unsupported_object_ok, '.apb valid-ready object remains outside the first alias slice');
    like(
        $@,
        qr/profile apb requires exactly one \(apb-requester \.\.\.\), one \(apb-completer \.\.\.\), or the explicit one-requester\/one-completer\/one-composition shape in this slice/,
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

sub sample_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer.apb');
}

sub sample_apb_busy_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_busy.apb');
}

sub sample_apb_status_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer_status.apb');
}

sub sample_apb_completer_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer.apb');
}

sub sample_apb_completer_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer.ppif');
}

sub sample_apb_composition_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition.apb');
}

sub sample_apb_composition_busy_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_busy.apb');
}

sub sample_apb_composition_status_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_status.apb');
}

sub sample_apb_composition_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition.ppif');
}

sub sample_apb_composition_busy_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_busy.ppif');
}

sub sample_apb_composition_status_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_composition_status.ppif');
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
