#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;
use FSM::ProjectDataLocality qw(configure_project_temp_environment create_project_tempdir);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
configure_project_temp_environment(purpose => 'tests');
my $workspace = create_project_tempdir(purpose => 'tests');
my %width_for = (
    2 => 2,
    4 => 3,
    5 => 3,
    7 => 3,
    8 => 4,
    15 => 4,
    16 => 5,
);
my %candidate_path;
my %candidate_hdl;

subtest 'canonical decimal admission, widths, reports, and residue are exact' => sub {
    my $adapter = FSM::Adapter::IAL2::PPIF->new();

    my $without_count = sample_source();
    replace_once(\$without_count, '(busy-beats 4)', '');
    my $single = $adapter->parse_source($without_count, 'generalized-absence.ppif');
    is($single->{report}{busy_insertion}{beats}, 'single', 'absence remains the exact-one report form');
    unlike($single->{generated_ial1}{text}, qr/ahb_busy_remaining_q|ahb_busy_continue/, 'absence remains counter-free');
    like(
        residue_detail($single->{report}, 'ahb_requester_busy_insert_support'),
        qr/exactly 1 qualified requester HTRANS BUSY event before one literal SEQ beat/,
        'absence residue uses numeric singular grammar',
    );

    for my $count (sort { $a <=> $b } keys %width_for) {
        my $result = $adapter->parse_source(candidate_source($count), "generalized-$count.ppif");
        my $width = $width_for{$count};
        is($result->{report}{transfer}{busy_beats}, $count, "count $count remains numeric in transfer report");
        is($result->{report}{busy_insertion}{beats}, $count, "count $count remains numeric in BUSY report");
        like(
            $result->{generated_ial1}{text},
            qr/\(var ahb_busy_remaining_q \(width $width\) \(reset 0\)\)/,
            "count $count derives minimum width $width",
        );
        like(
            $result->{generated_ial1}{text},
            qr/\(set ahb_busy_remaining_q $count\)/,
            "count $count initializes literally",
        );
        like(
            join(' ', @{$result->{report}{enforced_static_rules}}),
            qr/multiple BUSY insertion is bounded to canonical decimal literal busy-beats values 2\.\.16 in this slice/,
            "count $count reports the canonical bounded rule",
        );
        my $events = $count == 1 ? 'event' : 'events';
        my $residue = residue_detail($result->{report}, 'ahb_requester_busy_insert_support');
        like($residue, qr/exactly $count qualified requester HTRANS BUSY $events/, "count $count residue is numeric");
        like($residue, qr/supported without one catalog source per count/, "count $count residue explains fixture-independent support");
        like($residue, qr/counts above 16/, "count $count residue defers only higher literal counts");
    }
};

subtest 'non-canonical and out-of-range count forms fail closed' => sub {
    my @invalid = (
        ['zero', '0'],
        ['one', '1'],
        ['above bound', '17'],
        ['leading zero', '02'],
        ['explicit plus', '+2'],
        ['negative', '-2'],
        ['base prefix', '0x2'],
        ['fraction', '2.0'],
        ['symbol', 'cmd_count'],
    );

    for my $case (@invalid) {
        my ($label, $value) = @{$case};
        my $source = sample_source();
        replace_once(\$source, '(busy-beats 4)', "(busy-beats $value)");
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($source, "invalid-$label.ppif");
            1;
        };
        ok(!$ok, "$label form is rejected");
        like($@, range_diagnostic(), "$label form uses the exact bounded diagnostic");
    }

    for my $case (['reference', '(ref cmd_count)'], ['expression', '(+ 1 1)']) {
        my ($label, $value) = @{$case};
        my $source = sample_source();
        replace_once(\$source, '(busy-beats 4)', "(busy-beats $value)");
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($source, "invalid-$label.ppif");
            1;
        };
        ok(!$ok, "$label form is rejected");
        like($@, qr/requires exactly one scalar value/, "$label form fails at the earlier PPIF scalar-shape gate");
    }

    my $duplicate = sample_source();
    replace_once(\$duplicate, '(busy-beats 4)', "(busy-beats 4)\n      (busy-beats 5)");
    my $duplicate_ok = eval {
        FSM::Adapter::IAL2::PPIF->new()->parse_source($duplicate, 'duplicate.ppif');
        1;
    };
    ok(!$duplicate_ok, 'duplicate count clause is rejected');
    like($@, qr/duplicate \(busy-beats \.\.\.\) clause/, 'duplicate count keeps the scalar duplicate diagnostic');
};

subtest 'strict, artifact, semantic, MCP, and verifier surfaces agree for 5, 8, and 16' => sub {
    for my $count (5, 8, 16) {
        my $module = module_name($count);
        my $path = File::Spec->catfile($workspace, "ahb_requester_busy_insert_count_$count.ppif");
        write_file($path, candidate_source($count));
        $candidate_path{$count} = $path;

        my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', $path);
        ok($check->{success}, "count $count strict check succeeds");
        is($check->{result}{module_name}, $module, "count $count check reports the candidate module");
        ok(!$check->{support_accounting}{matched}, "count $count verification candidate is explicitly unmatched");

        my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', $path);
        is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', "count $count schedule keeps requester schema");
        is($schedule->{busy_insertion}{before_beat}, 2, "count $count schedule keeps insertion index two");
        is($schedule->{busy_insertion}{beats}, $count, "count $count schedule reports its numeric BUSY count");
        is($schedule->{generated_artifacts}{ial1}{name}, "$module.isf", "count $count schedule names its IAL1 artifact");
        is_deeply($schedule->{generated_artifacts}{ial0}{files}, ["$module.fsm"], "count $count schedule names its IAL0 artifact");

        my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', $path);
        assert_semantic_payload($semantic, $count, 'semantic JSON');

        my $relative = File::Spec->abs2rel($path, $repo_root);
        my $mcp_adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
            repo_root => $repo_root,
            workspace_root => $repo_root,
        );
        my $mcp = decode_json(
            $mcp_adapter->call_tool(
                'fsmgen_semantic_introspect',
                { source_path => $relative },
            )->{content}[0]{text},
        );
        is($mcp->{query_kind}, 'semantic', "count $count MCP dispatches through semantic introspection");
        is($mcp->{source_id}, $relative, "count $count MCP keeps a repo-relative candidate identity");
        ok($mcp->{adapter_provenance}{read_only}, "count $count MCP remains read-only");
        ok(!$mcp->{adapter_provenance}{shell_access}, "count $count MCP keeps shell access disabled");
        assert_semantic_payload($mcp->{report}, $count, 'MCP semantic report');

        my $outdir = File::Spec->catdir($workspace, "review-$count");
        my $hdl = File::Spec->catfile($workspace, "$module.sv");
        run_command_ok(
            ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, $path],
            "count $count emits HDL and review artifacts",
        );
        ok(-f File::Spec->catfile($outdir, "$module.isf"), "count $count outdir contains IAL1");
        ok(-f File::Spec->catfile($outdir, "$module.fsm"), "count $count outdir contains IAL0");
        like(slurp($hdl), qr/\bmodule\s+$module\b/, "count $count generated HDL has the candidate module");
        $candidate_hdl{$count} = $hdl;

        run_command_ok(
            ['./bin/fsmgen', '--quiet', '--strict', '--verify-hdl', $path],
            "count $count passes the public HDL verifier",
        );
    }
};

subtest 'generated HDL retires exact 5, 8, and 16 qualified BUSY events with assertions enabled' => sub {
    my %scenarios = (
        5 => [0, 1, 2],
        8 => [0],
        16 => [0, 1, 2],
    );

    for my $count (5, 8, 16) {
        my $width = $width_for{$count};
        my $module = module_name($count);
        my $objdir = File::Spec->catdir($workspace, "obj-$count");
        my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
            command => [
                'verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
                '-j', '1', '--top-module', 'ahb_requester_generalized_busy_count_tb',
                '--Mdir', $objdir,
                "-DDUT_MODULE=$module", "-DBUSY_COUNT=$count", "-DBUSY_WIDTH=$width",
                $candidate_hdl{$count}, testbench_path(),
            ],
        );
        my $compile_output = join('', @{$compile_stdout || []}, @{$compile_stderr || []});
        ok($compile_ok, "count $count Verilator build succeeds with assertions enabled")
            or diag($compile_output);
        unlike($compile_output, qr/%Warning-/, "count $count Verilator build needs no warning-specific suppression");
        next unless $compile_ok;

        my $binary = File::Spec->catfile($objdir, 'Vahb_requester_generalized_busy_count_tb');
        for my $stall_mode (@{$scenarios{$count}}) {
            my $stall_clocks = $stall_mode == 0 ? 0 : 32;
            my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(
                command => [$binary, "+STALL_MODE=$stall_mode"],
            );
            my $run_output = join('', @{$run_stdout || []}, @{$run_stderr || []});
            ok($run_ok, "count $count stall mode $stall_mode runtime passes")
                or diag($run_output);
            like(
                $run_output,
                qr/PASS transfers=5 beats=4 busy=1 qualified_busy=$count expected_busy=$count width=$width stall_mode=$stall_mode stall_clocks=$stall_clocks busy_remaining=0/,
                "count $count stall mode $stall_mode observes exact retirement and completion",
            );
        }
    }
};

done_testing();

sub candidate_source {
    my ($count) = @_;
    my $source = sample_source();
    my $module = module_name($count);
    replace_once(\$source, 'ahb_requester_busy_insert_four', "ahb_requester_busy_insert_count_$count");
    replace_once(\$source, 'fsmgen-ahb-requester-busy-insert-four', "fsmgen-ahb-requester-busy-insert-count-$count");
    replace_once(\$source, 'bounded-requester-four-busy-insertion', "generalized-requester-busy-insertion-count-$count");
    replace_once(\$source, 'amba_requester_busy_insert_four', $module);
    replace_once(\$source, '(busy-beats 4)', "(busy-beats $count)");
    return $source;
}

sub assert_semantic_payload {
    my ($semantic, $count, $label) = @_;
    ok($semantic->{success}, "count $count $label succeeds");
    is($semantic->{generation_result_snapshot}{summary}{module_name}, module_name($count), "count $count $label reports module");
    is($semantic->{semantic}{module}{source_root_kind}, 'fsm', "count $count $label reports generated FSM root");
    ok(!$semantic->{support_accounting}{matched}, "count $count $label remains unmatched");
}

sub residue_detail {
    my ($report, $id) = @_;
    my ($item) = grep { $_->{id} eq $id } @{$report->{unsupported_residue} || []};
    return $item ? $item->{detail} : '';
}

sub range_diagnostic {
    return qr/AHB requester transfer\.busy_beats must be a canonical decimal literal integer in 2\.\.16 in this slice/;
}

sub module_name {
    my ($count) = @_;
    return "amba_requester_busy_insert_count_$count";
}

sub sample_path {
    return File::Spec->catfile($repo_root, 'ppif', 'ahb_requester_busy_insert_four.ppif');
}

sub sample_source {
    return slurp(sample_path());
}

sub testbench_path {
    return File::Spec->catfile($repo_root, 't', 'data', 'ahb_requester_generalized_busy_count_tb.svt');
}

sub replace_once {
    my ($text_ref, $from, $to) = @_;
    my $offset = index($$text_ref, $from);
    die "fixture fragment not found: $from" if $offset < 0;
    die "fixture fragment repeated: $from" if index($$text_ref, $from, $offset + length($from)) >= 0;
    substr($$text_ref, $offset, length($from), $to);
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

sub write_file {
    my ($path, $content) = @_;
    my (undef, $directory) = File::Spec->splitpath($path);
    make_path($directory) unless -d $directory;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
