#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));

subtest 'adapter parses and lowers the exact-three requester source' => sub {
    ok(-f sample_path(), 'tracked exact-three requester PPIF sample exists');
    like(sample_source(), qr/\(section bounded-requester-three-busy-insertion\)/, 'sample keeps its selected source anchor');
    like(sample_source(), qr/\(busy-before-beat 2\)/, 'sample selects insertion before beat index two');
    like(sample_source(), qr/\(busy-beats 3\)/, 'sample selects exactly three qualified BUSY events');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    is($result->{layer}, 'IAL2', 'adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_requester', 'exact-three insertion is an AHB requester option');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-requester-busy-insert-three', 'source object id is selected');
    is($result->{report}{source_object}{intent_name}, 'ahb_requester_busy_insert_three', 'source intent name is selected');
    is($result->{generated_ial1}{name}, 'amba_requester_busy_insert_three.isf', 'generated IAL1 artifact is distinct');
    is_deeply(
        [sort keys %{$result->{generated_ial0}{files}}],
        ['amba_requester_busy_insert_three.fsm'],
        'generated IAL0 artifact is distinct',
    );

    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(var ahb_busy_remaining_q \(width 2\) \(reset 0\)\)/, 'actor-owned width-two remaining counter is unchanged');
    unlike($isf, qr/\(local ahb_busy_remaining_q\b/, 'remaining counter is not transaction-local');
    like($isf, qr/\(priority ahb_busy_accept over ahb_request\)/, 'final BUSY acceptance outranks requester output selection');
    like($isf, qr/\(priority ahb_busy_continue over ahb_request\)/, 'intermediate BUSY acceptance outranks requester output selection');
    like($isf, qr/\(priority ahb_busy_accept over ahb_busy_continue\)/, 'final BUSY acceptance outranks continuation');
    like(
        $isf,
        qr/\(rule ahb_busy_continue \(& HGRANT HREADY \(== HTRANS 2'b01\) \(> ahb_busy_remaining_q 1\)\)\s+\(set ahb_busy_remaining_q \(- ahb_busy_remaining_q 1\)\)\)/s,
        'each non-final qualified BUSY event decrements without resuming SEQ',
    );
    like(
        $isf,
        qr/\(rule ahb_busy_accept \(& HGRANT HREADY \(== HTRANS 2'b01\) \(== ahb_busy_remaining_q 1\)\)\s+\(set ahb_busy_remaining_q 0\)\s+\(set ahb_address_pending_q 1\)\s+\(set HTRANS 2'b11\)\)/s,
        'the final qualified BUSY event clears and resumes the same SEQ transfer',
    );
    like(
        $isf,
        qr/\(when \(& \(== beat_index_q 2\) \(== busy_inserted_q 0\)\)\s+\(set ahb_busy_remaining_q 3\)\s+\(drive transfer_busy\)\s+\(set busy_inserted_q 1\)/s,
        'insertion initializes literal three before driving BUSY',
    );
    like($isf, qr/\(continue-when \(== HTRANS 2'b01\)\)/, 'the requester transaction remains held for the complete BUSY episode');

    is($result->{report}{transfer}{busy_beats}, 3, 'report records exact event count three');
    is($result->{report}{busy_insertion}{beats}, 3, 'report exposes exact-three as a numeric count');
    like(join(' ', @{$result->{report}{enforced_static_rules}}), qr/literal busy-beats values 2\.\.3/, 'static rule reports the bounded public count range');
    my %residue = map { $_->{id} => $_->{detail} } @{$result->{report}{unsupported_residue}};
    like($residue{ahb_requester_busy_insert_support}, qr/exact-three qualified requester HTRANS BUSY events/, 'report states the shipped exact-three behavior');
    like($residue{ahb_requester_busy_insert_support}, qr/counts beyond three/, 'report keeps only larger counts deferred');
};

subtest 'malformed bounded-count declarations fail closed' => sub {
    my @cases = (
        ['missing insertion point', sub { replace_clause(sample_source(), qr/\n      \(busy-before-beat 2\)/, '') }, qr/busy_beats requires transfer\.busy_before_beat/],
        ['zero event count', sub { replace_clause(sample_source(), qr/\(busy-beats 3\)/, '(busy-beats 0)') }, range_diagnostic()],
        ['single event count', sub { replace_clause(sample_source(), qr/\(busy-beats 3\)/, '(busy-beats 1)') }, range_diagnostic()],
        ['larger event count', sub { replace_clause(sample_source(), qr/\(busy-beats 3\)/, '(busy-beats 4)') }, range_diagnostic()],
        ['symbolic event count', sub { replace_clause(sample_source(), qr/\(busy-beats 3\)/, '(busy-beats cmd_count)') }, range_diagnostic()],
        ['duplicate event count', sub { replace_clause(sample_source(), qr/\(busy-beats 3\)/, "(busy-beats 3)\n      (busy-beats 3)") }, qr/duplicate \(busy-beats \.\.\.\) clause/],
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

subtest 'CLI, semantic, MCP, schedule, review, and verify surfaces agree' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_path());
    ok($check->{success}, 'strict check succeeds for exact-three source');
    is($check->{result}{module_name}, module_name(), 'check JSON reports the selected module');
    is($check->{support_accounting}{entry_id}, support_id(), 'check JSON matches support identity');
    is($check->{support_accounting}{coverage}, coverage_key(), 'check JSON reports the selected coverage key');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_path());
    assert_semantic_payload($semantic, 'semantic JSON');

    my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $repo_root,
        workspace_root => $repo_root,
    );
    my $mcp = decode_json(
        $adapter->call_tool(
            'fsmgen_semantic_introspect',
            { source_path => sample_relpath() },
        )->{content}[0]{text},
    );
    is($mcp->{query_kind}, 'semantic', 'MCP dispatches through the bounded semantic query');
    is($mcp->{source_id}, sample_relpath(), 'MCP keeps the repo-relative source identity');
    ok($mcp->{adapter_provenance}{read_only}, 'MCP provenance remains read-only');
    ok(!$mcp->{adapter_provenance}{shell_access}, 'MCP provenance keeps shell access disabled');
    assert_semantic_payload($mcp->{report}, 'MCP semantic report');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', 'schedule JSON keeps requester schema');
    is($schedule->{busy_insertion}{before_beat}, 2, 'schedule JSON exposes the insertion index');
    is($schedule->{busy_insertion}{beats}, 3, 'schedule JSON exposes numeric exact-three');
    is($schedule->{generated_artifacts}{ial1}{name}, 'amba_requester_busy_insert_three.isf', 'schedule JSON names exact IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['amba_requester_busy_insert_three.fsm'], 'schedule JSON names exact IAL0 artifact');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester_busy_insert_three.sv');
    run_command_ok(
        ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, sample_path()],
        'exact-three source emits HDL and review artifacts',
    );
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert_three.isf'), 'outdir contains exact-three IAL1');
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert_three.fsm'), 'outdir contains exact-three IAL0');
    like(slurp($hdl), qr/\bmodule\s+amba_requester_busy_insert_three\b/, 'generated HDL contains the selected module');
    run_command_ok(
        ['./bin/fsmgen', '--quiet', '--strict', '--verify-hdl', sample_path()],
        'public verifier accepts the exact-three source',
    );
};

subtest 'generated HDL retires exactly three qualified BUSY events and resumes SEQ' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester_busy_insert_three.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    run_command_ok(
        ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
        'public exact-three requester emits generated HDL',
    );
    return unless -f $hdl;

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_requester_three_busy_insert_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the exact-three requester harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_requester_three_busy_insert_tb');
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
        ok($run_ok, "$label exact-three generated-HDL insertion passes")
            or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
        like(
            join('', @{$run_stdout || []}),
            qr/PASS transfers=5 beats=4 busy=1 qualified_busy=3 stall_mode=$mode stall_clocks=$stall_clocks busy_remaining=0/,
            "$label directly observes 3-to-2-to-1-to-0 retirement and completes four data beats",
        );
    }
};

subtest 'exact-one, exact-two, and base requester behavior remain distinct' => sub {
    my $two = FSM::Adapter::IAL2::PPIF->new()->parse_file(exact_two_path());
    is($two->{report}{busy_insertion}{beats}, 2, 'exact-two source keeps numeric report value two');
    like($two->{generated_ial1}{text}, qr/\(set ahb_busy_remaining_q 2\)/, 'exact-two source keeps literal-two initialization');
    my %two_residue = map { $_->{id} => $_->{detail} } @{$two->{report}{unsupported_residue}};
    like($two_residue{ahb_requester_busy_insert_support}, qr/additive exact-three behavior is supported/, 'exact-two residue acknowledges exact-three support');

    my $single = FSM::Adapter::IAL2::PPIF->new()->parse_file(single_path());
    is($single->{report}{busy_insertion}{beats}, 'single', 'existing source keeps the exact-one report token');
    unlike($single->{generated_ial1}{text}, qr/ahb_busy_remaining_q|ahb_busy_continue/, 'exact-one IAL1 has no multiple-event counter or rule');
    my %single_residue = map { $_->{id} => $_->{detail} } @{$single->{report}{unsupported_residue}};
    like($single_residue{ahb_requester_busy_insert_support}, qr/exact-two and exact-three behavior is supported/, 'exact-one residue names both additive bounded-count sources');

    my $base = FSM::Adapter::IAL2::PPIF->new()->parse_file(base_path());
    ok(!exists($base->{report}{busy_insertion}), 'base requester remains BUSY-insertion free');
    unlike($base->{generated_ial1}{text}, qr/transfer_busy|busy_inserted_q|ahb_busy_remaining_q|ahb_busy_accept/, 'base requester has no BUSY machinery');
};

done_testing();

sub assert_semantic_payload {
    my ($semantic, $label) = @_;
    ok($semantic->{success}, "$label succeeds");
    is($semantic->{generation_result_snapshot}{summary}{module_name}, module_name(), "$label reports exact-three module");
    is($semantic->{semantic}{module}{source_root_kind}, 'fsm', "$label reports generated FSM root");
    is($semantic->{support_accounting}{entry_id}, support_id(), "$label reports exact-three support identity");
    is($semantic->{support_accounting}{source_kind}, 'ppif', "$label reports PPIF source kind");
}

sub sample_relpath { return 'ppif/ahb_requester_busy_insert_three.ppif' }
sub sample_path { return File::Spec->catfile($repo_root, split m{/}, sample_relpath()) }
sub exact_two_path { return File::Spec->catfile($repo_root, 'ppif', 'ahb_requester_busy_insert_two.ppif') }
sub single_path { return File::Spec->catfile($repo_root, 'ppif', 'ahb_requester_busy_insert.ppif') }
sub base_path { return File::Spec->catfile($repo_root, 'ppif', 'ahb_requester.ppif') }
sub testbench_path { return File::Spec->catfile($repo_root, 't', 'data', 'ahb_requester_three_busy_insert_tb.svt') }
sub sample_source { return slurp(sample_path()) }
sub module_name { return 'amba_requester_busy_insert_three' }
sub support_id { return 'intent.ppif_ahb_requester_busy_insert_three' }
sub coverage_key { return 'ial2_ppif_ahb_requester_busy_insert_three_pipeline_cli' }
sub range_diagnostic { return qr/busy_beats must be a literal integer in 2\.\.3 in this slice/ }

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
            return {};
        };
    return $decoded;
}

sub run_command_ok {
    my ($command, $label) = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => $command);
    ok($success, $label)
        or diag(join('', @{$stdout || []}), join('', @{$stderr || []}));
    is(join('', @{$stderr || []}), '', "$label keeps stderr clean") if $success;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
