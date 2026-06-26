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
    ok($residue{apb_profile_alias_completer_deferred}, 'report keeps .apb completer alias residue explicit');
    ok($residue{apb_profile_alias_composition_deferred}, 'report keeps .apb composition alias residue explicit');
    ok($residue{apb_back_to_back_policy_deferred}, 'report keeps back-to-back policy residue explicit');
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

    my @cases = (
        ['apb completer profile mismatch', $profile_mismatch, qr/profile 'axi4' does not match \(apb-completer \.\.\.\); expected apb/],
        ['apb completer missing storage', $missing_storage, qr/is missing required \(storage \.\.\.\) clause/],
        ['apb completer wrong setup select', $bad_setup, qr/transfer\.setup_detect\.select must be 1/],
        ['apb completer wrong wait width', $bad_wait_width, qr/control\.wait_cycles\.width must be 4/],
    );

    for my $case (@cases) {
        my ($label, $source, $pattern) = @$case;
        my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($source, "$label.ppif"); 1 };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
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

subtest '.apb alias remains requester-transfer only' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $alias_path = File::Spec->catfile($tempdir, 'apb_completer.apb');
    write_file($alias_path, sample_apb_completer_ppif());

    my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($alias_path); 1 };
    ok(!$ok, '.apb rejects APB completer content');
    like(
        $@,
        qr/\.apb source '.*apb_completer\.apb' supports only one APB requester-transfer object in this slice/,
        '.apb APB completer rejection keeps the alias boundary targeted',
    );
};

done_testing();

sub sample_apb_completer_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_completer.ppif');
}

sub sample_apb_completer_ppif {
    return slurp(sample_apb_completer_ppif_path());
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
