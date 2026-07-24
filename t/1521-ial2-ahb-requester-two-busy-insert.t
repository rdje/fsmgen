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

subtest 'adapter parses the exact-two requester BUSY-insertion source' => sub {
    ok(-f sample_path(), 'tracked exact-two requester PPIF sample exists');
    like(sample_source(), qr/\(busy-before-beat 2\)/, 'sample selects insertion before beat index two');
    like(sample_source(), qr/\(busy-beats 2\)/, 'sample selects exactly two qualified BUSY events');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    is($result->{layer}, 'IAL2', 'adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_requester', 'exact-two insertion remains an AHB requester option');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-requester-busy-insert-two', 'source object id is selected');
    is($result->{report}{source_object}{intent_name}, 'ahb_requester_busy_insert_two', 'source intent name is selected');
    is($result->{generated_ial1}{name}, 'amba_requester_busy_insert_two.isf', 'generated IAL1 artifact is distinct');
    is_deeply(
        [sort keys %{$result->{generated_ial0}{files}}],
        ['amba_requester_busy_insert_two.fsm'],
        'generated IAL0 artifact is distinct',
    );

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(var ahb_busy_remaining_q \(width 2\) \(reset 0\)\)/, 'actor-owned width-two remaining counter is declared');
    unlike($isf, qr/\(local ahb_busy_remaining_q\b/, 'remaining counter is not transaction-local');
    like($isf, qr/\(priority ahb_busy_accept over ahb_request\)/, 'final BUSY acceptance outranks requester output selection');
    like($isf, qr/\(priority ahb_busy_continue over ahb_request\)/, 'intermediate BUSY acceptance outranks requester output selection');
    like($isf, qr/\(priority ahb_busy_accept over ahb_busy_continue\)/, 'the rule checker receives the explicit accept/continue priority edge');
    like(
        $isf,
        qr/\(rule ahb_busy_continue \(& HGRANT HREADY \(== HTRANS 2'b01\) \(> ahb_busy_remaining_q 1\)\)\s+\(set ahb_busy_remaining_q \(- ahb_busy_remaining_q 1\)\)\)/s,
        'an intermediate qualified BUSY event decrements the counter without resuming SEQ',
    );
    like(
        $isf,
        qr/\(rule ahb_busy_accept \(& HGRANT HREADY \(== HTRANS 2'b01\) \(== ahb_busy_remaining_q 1\)\)\s+\(set ahb_busy_remaining_q 0\)\s+\(set ahb_address_pending_q 1\)\s+\(set HTRANS 2'b11\)\)/s,
        'the second qualified BUSY event clears the counter and resumes the same SEQ transfer',
    );
    like(
        $isf,
        qr/\(when \(& \(== beat_index_q 2\) \(== busy_inserted_q 0\)\)\s+\(set ahb_busy_remaining_q 2\)\s+\(drive transfer_busy\)\s+\(set busy_inserted_q 1\)/s,
        'insertion initializes the count before driving BUSY',
    );
    like($isf, qr/\(continue-when \(== HTRANS 2'b01\)\)/, 'the requester transaction remains held for the complete BUSY episode');

    is($result->{report}{transfer}{busy}, "2'b01", 'report records the BUSY encoding');
    is($result->{report}{transfer}{busy_before_beat}, 2, 'report records the insertion index');
    is($result->{report}{transfer}{busy_beats}, 2, 'report records the exact event count');
    is($result->{report}{busy_insertion}{beats}, 2, 'report exposes exact-two as a numeric count');
    my %residue = map { $_->{id} => $_->{detail} } @{$result->{report}{unsupported_residue}};
    like($residue{ahb_requester_busy_insert_support}, qr/exact-two qualified requester HTRANS BUSY events/, 'report states the shipped exact-two behavior');
    like($residue{ahb_requester_busy_insert_support}, qr/counts beyond two/, 'report keeps broader counts deferred');
};

subtest 'malformed exact-two declarations fail closed' => sub {
    my @cases = (
        ['missing insertion point', sub { replace_clause(sample_source(), qr/\n      \(busy-before-beat 2\)/, '') }, qr/busy_beats requires transfer\.busy_before_beat/],
        ['zero event count', sub { replace_clause(sample_source(), qr/\(busy-beats 2\)/, '(busy-beats 0)') }, qr/busy_beats must be the literal integer 2 in this slice/],
        ['single event count', sub { replace_clause(sample_source(), qr/\(busy-beats 2\)/, '(busy-beats 1)') }, qr/busy_beats must be the literal integer 2 in this slice/],
        ['larger event count', sub { replace_clause(sample_source(), qr/\(busy-beats 2\)/, '(busy-beats 3)') }, qr/busy_beats must be the literal integer 2 in this slice/],
        ['symbolic event count', sub { replace_clause(sample_source(), qr/\(busy-beats 2\)/, '(busy-beats cmd_count)') }, qr/busy_beats must be the literal integer 2 in this slice/],
        ['duplicate event count', sub { replace_clause(sample_source(), qr/\(busy-beats 2\)/, "(busy-beats 2)\n      (busy-beats 2)") }, qr/duplicate \(busy-beats \.\.\.\) clause/],
    );

    for my $case (@cases) {
        my ($label, $build_source, $pattern) = @{$case};
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($build_source->(), "$label.ppif");
            1;
        };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI, semantic, schedule, review, and verify surfaces agree' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_path());
    ok($check->{success}, 'strict check succeeds for exact-two source');
    is($check->{result}{module_name}, 'amba_requester_busy_insert_two', 'check JSON reports the selected module');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_ahb_requester_busy_insert_two', 'check JSON matches support identity');
    is($check->{support_accounting}{coverage}, 'ial2_ppif_ahb_requester_busy_insert_two_pipeline_cli', 'check JSON reports the selected coverage key');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_path());
    ok($semantic->{success}, 'semantic JSON succeeds');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'amba_requester_busy_insert_two', 'semantic JSON reports the selected module');
    is($semantic->{semantic}{module}{source_root_kind}, 'fsm', 'semantic JSON reports the generated FSM root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_ahb_requester_busy_insert_two', 'semantic JSON matches support identity');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_path());
    is($schedule->{busy_insertion}{htrans_busy_encoding}, "2'b01", 'schedule JSON exposes HTRANS BUSY');
    is($schedule->{busy_insertion}{before_beat}, 2, 'schedule JSON exposes the insertion index');
    is($schedule->{busy_insertion}{beats}, 2, 'schedule JSON exposes numeric exact-two');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester_busy_insert_two.sv');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'exact-two source emits HDL and review artifacts')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    is(join('', @{$generate_stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert_two.isf'), 'outdir contains generated IAL1');
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert_two.fsm'), 'outdir contains generated IAL0');
    like(slurp($hdl), qr/\bmodule\s+amba_requester_busy_insert_two\b/, 'generated HDL contains the selected module');

    my ($verify_ok, undef, undef, $verify_stdout, $verify_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--verify-hdl', sample_path()],
    );
    ok($verify_ok, 'public verify-hdl accepts the exact-two source')
        or diag(join('', @{$verify_stdout || []}), join('', @{$verify_stderr || []}));
};

subtest 'generated HDL retires exactly two qualified BUSY events and resumes SEQ' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester_busy_insert_two.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public exact-two requester emits generated HDL')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_requester_two_busy_insert_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the exact-two requester harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_requester_two_busy_insert_tb');
    my @scenarios = (
        ['continuously qualified', 0, 0],
        ['32-clock ready-low hold', 1, 32],
        ['32-clock grant-low hold', 2, 32],
    );
    for my $scenario (@scenarios) {
        my ($label, $mode, $stall_clocks) = @{$scenario};
        my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(
            command => [$binary, "+STALL_MODE=$mode"],
        );
        ok($run_ok, "$label exact-two generated-HDL insertion passes")
            or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
        like(
            join('', @{$run_stdout || []}),
            qr/PASS transfers=5 beats=4 busy=1 qualified_busy=2 stall_mode=$mode stall_clocks=$stall_clocks/,
            "$label retires exactly two qualified BUSY events and completes four data beats",
        );
    }
};

subtest 'existing exact-one and base requester behavior remain distinct' => sub {
    my $single = FSM::Adapter::IAL2::PPIF->new()->parse_file(single_path());
    is($single->{report}{busy_insertion}{beats}, 'single', 'existing source keeps the exact-one report token');
    unlike($single->{generated_ial1}{text}, qr/ahb_busy_remaining_q|ahb_busy_continue/, 'existing exact-one IAL1 has no exact-two counter or rule');
    like($single->{generated_ial1}{text}, qr/\(continue-when \(& \(! HREADY\) \(== HTRANS 2'b01\)\)\)/, 'existing exact-one ready-low hold remains byte-shaped');

    my $base = FSM::Adapter::IAL2::PPIF->new()->parse_file(base_path());
    ok(!exists($base->{report}{busy_insertion}), 'base requester remains BUSY-insertion free');
    unlike($base->{generated_ial1}{text}, qr/transfer_busy|busy_inserted_q|ahb_busy_remaining_q|ahb_busy_accept/, 'base requester has no BUSY machinery');
};

done_testing();

sub sample_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester_busy_insert_two.ppif');
}

sub single_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester_busy_insert.ppif');
}

sub base_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ppif');
}

sub testbench_path {
    return File::Spec->catfile($FindBin::Bin, 'data', 'ahb_requester_two_busy_insert_tb.svt');
}

sub sample_source {
    return slurp(sample_path());
}

sub replace_clause {
    my ($source, $pattern, $replacement) = @_;
    $source =~ s/$pattern/$replacement/ or die "test fixture replacement failed: $pattern";
    return $source;
}

sub run_json_command {
    my @command = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => \@command);
    my $json = join('', @{$stdout || []});
    my $decoded = eval { decode_json($json) };
    ok($decoded, join(' ', @command) . ' emits decodable JSON')
        or do {
            diag($json);
            diag(join('', @{$stderr || []}));
            diag('command failed') unless $success;
        };
    return $decoded || {};
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
