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

subtest 'adapter parses the bounded requester BUSY-insertion source' => sub {
    ok(-f sample_path(), 'tracked requester BUSY-insertion PPIF sample exists');
    like(sample_source(), qr/\(busy 2'b01\)/, 'sample declares the AHB HTRANS BUSY encoding');
    like(sample_source(), qr/\(busy-before-beat 2\)/, 'sample selects one BUSY beat before beat index two');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    is($result->{layer}, 'IAL2', 'BUSY-insertion adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_requester', 'BUSY insertion remains an AHB requester option');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-requester-busy-insert', 'source object id is selected');
    is($result->{report}{source_object}{intent_name}, 'ahb_requester_busy_insert', 'source intent name is selected');
    is($result->{generated_ial1}{name}, 'amba_requester_busy_insert.isf', 'generated IAL1 artifact is distinct');
    is_deeply(
        [sort keys %{$result->{generated_ial0}{files}}],
        ['amba_requester_busy_insert.fsm'],
        'generated IAL0 artifact is distinct',
    );

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(drive transfer_busy\b.*?\(HADDR addr_q\).*?\(HTRANS 2'b01\).*?\(HWDATA wdata_q\)/s, 'BUSY drive holds the armed request fields and drives HTRANS BUSY');
    like($isf, qr/\(local busy_inserted_q \(width 1\)\)/, 'generated IAL1 declares one bounded insertion flag');
    like($isf, qr/\(when \(& \(== beat_index_q 2\) \(== busy_inserted_q 0\)\)\s+\(drive transfer_busy\)\s+\(set busy_inserted_q 1\)\s+\(continue-when \(== busy_inserted_q 1\)\)\)/s, 'BUSY insertion skips normal transfer and response advancement with a one-bit continue condition');

    is($result->{report}{transfer}{busy}, "2'b01", 'report records the BUSY encoding');
    is($result->{report}{transfer}{busy_before_beat}, 2, 'report records the insertion index');
    is($result->{report}{busy_insertion}{generated_behavior}, 1, 'report marks BUSY insertion as generated behavior');
    is($result->{report}{busy_insertion}{htrans_busy_encoding}, "2'b01", 'report exposes the HTRANS BUSY encoding');
    is($result->{report}{busy_insertion}{before_beat}, 2, 'report exposes the before-beat index');
    is($result->{report}{busy_insertion}{beats}, 'single', 'report bounds insertion to one held beat');

    my %residue = map { $_->{id} => $_->{detail} } @{$result->{report}{unsupported_residue}};
    like($residue{ahb_requester_busy_insert_support}, qr/single held requester HTRANS BUSY insertion/, 'report records the shipped bounded BUSY insertion');
    like($residue{ahb_requester_busy_insert_support}, qr/multi-beat or policy-driven BUSY throttling/, 'report keeps broader BUSY policy deferred');
};

subtest 'malformed requester BUSY-insertion declarations fail closed' => sub {
    my @cases = (
        ['zero insertion index', sub { replace_clause(sample_source(), qr/\(busy-before-beat 2\)/, '(busy-before-beat 0)') }, qr/busy_before_beat must be a literal integer in 1\.\.15/],
        ['index at max-beats', sub { replace_clause(sample_source(), qr/\(busy-before-beat 2\)/, '(busy-before-beat 16)') }, qr/busy_before_beat must be a literal integer in 1\.\.15/],
        ['non-literal insertion index', sub { replace_clause(sample_source(), qr/\(busy-before-beat 2\)/, '(busy-before-beat cmd_index)') }, qr/busy_before_beat must be a literal integer in 1\.\.15/],
        ['missing BUSY encoding', sub { replace_clause(sample_source(), qr/\n      \(busy 2'b01\)/, '') }, qr/busy_before_beat requires transfer\.busy 2'b01/],
        ['wrong BUSY encoding', sub { replace_clause(sample_source(), qr/\(busy 2'b01\)/, "(busy 2'b10)") }, qr/transfer\.busy must be 2'b01/],
        ['duplicate insertion clause', sub { replace_clause(sample_source(), qr/\(busy-before-beat 2\)/, "(busy-before-beat 2)\n      (busy-before-beat 3)") }, qr/duplicate \(busy-before-beat \.\.\.\) clause/],
    );

    for my $case (@cases) {
        my ($label, $build_source, $pattern) = @$case;
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($build_source->(), "$label.ppif");
            1;
        };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI, support accounting, and report surfaces agree' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_path());
    ok($check->{success}, 'strict check succeeds for the BUSY-insertion source');
    is($check->{result}{module_name}, 'amba_requester_busy_insert', 'check JSON reports the selected module');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_ahb_requester_busy_insert', 'check JSON matches the support identity');
    is($check->{support_accounting}{coverage}, 'ial2_ppif_ahb_requester_busy_insert_pipeline_cli', 'check JSON reports the selected coverage key');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_path());
    is($schedule->{busy_insertion}{htrans_busy_encoding}, "2'b01", 'schedule JSON exposes HTRANS BUSY');
    is($schedule->{busy_insertion}{before_beat}, 2, 'schedule JSON exposes the insertion index');
    is($schedule->{busy_insertion}{beats}, 'single', 'schedule JSON exposes the one-beat bound');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester_busy_insert.sv');
    my ($success, undef, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_path()],
    );
    ok($success, 'BUSY-insertion source emits HDL and review artifacts');
    is(join('', @{$stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert.isf'), 'outdir contains generated IAL1');
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert.fsm'), 'outdir contains generated IAL0');
    like(slurp($hdl), qr/\bmodule\s+amba_requester_busy_insert\b/, 'generated HDL contains the selected module');
};

subtest 'generated HDL inserts one held BUSY beat and resumes SEQ' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester_busy_insert.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public BUSY-insertion requester emits generated HDL')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_requester_busy_insert_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the requester BUSY-insertion harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_requester_busy_insert_tb');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated-HDL requester BUSY insertion passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS transfers=5 beats=4 busy=1/,
        'runtime observes NONSEQ, SEQ, BUSY, resumed SEQ, final SEQ and four accepted beats',
    );
};

subtest 'the shipped requester source remains BUSY-insertion free' => sub {
    my $base = FSM::Adapter::IAL2::PPIF->new()->parse_file(base_path());
    ok(!exists($base->{report}{transfer}{busy}), 'base requester transfer report has no BUSY encoding');
    ok(!exists($base->{report}{transfer}{busy_before_beat}), 'base requester report has no insertion index');
    ok(!exists($base->{report}{busy_insertion}), 'base requester has no BUSY-insertion report block');
    unlike($base->{generated_ial1}{text}, qr/transfer_busy|busy_inserted_q/, 'base requester generated IAL1 has no BUSY-insertion machinery');
    my %residue = map { $_->{id} => 1 } @{$base->{report}{unsupported_residue}};
    ok(!$residue{ahb_requester_busy_insert_support}, 'base requester residue is unchanged');
};

done_testing();

sub sample_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester_busy_insert.ppif');
}

sub base_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ppif');
}

sub testbench_path {
    return File::Spec->catfile($FindBin::Bin, 'data', 'ahb_requester_busy_insert_tb.svt');
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
        };
    return $decoded || {};
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
