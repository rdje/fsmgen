#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $scheduler = FSM::Scheduler::ISF->new;
my $single = <<'ISF';
(actor input_boundary
  (clock clk) (reset rst_n)
  (interface (input start) (input spare_flag)
    (input spare_bus (width 9)) (output done))
  (transaction work (on start) (complete done)))
ISF
my $named = $single;
$named =~ s/\(clock clk\) \(reset rst_n\)/(clock-domains (domain core (clock clk) (reset rst_n)))/;
my $symbolic = $single;
$symbolic =~ s/\(interface/(params (BUS_W 9)) (constants (FLAG_W 3))\n  (interface/;
$symbolic =~ s/\(input spare_flag\)/(input spare_flag (width FLAG_W))/;
$symbolic =~ s/\(width 9\)/(width BUS_W)/;
my $multi = read_file('isf/clock_domain_event_crossing.isf');
$multi =~ s/\(interface/(interface\n    (input spare_flag)\n    (input spare_bus (width 9) (domain core))/;
my $collision = $multi;
$collision =~ s/\(domain source(?=[ )])/(domain bus/g;
$collision =~ s/\(from source /\(from bus /g;
$collision =~ s/spare_flag/bus_instance/g;
$collision =~ s/\(interface/(interface (input bus_instance_2)/;

for my $case (
    { name => 'ordinary', text => $single, inputs => {start => 1, spare_flag => 1, spare_bus => 9} },
    { name => 'named_single', text => $named, inputs => {start => 1, spare_flag => 1, spare_bus => 9} },
    { name => 'symbolic_widths', text => $symbolic, inputs => {start => 1, spare_flag => 3, spare_bus => 9} },
    { name => 'domains', text => $multi, inputs => {bus_start => 1, spare_flag => 1, spare_bus => 9},
      domain_inputs => {source => {bus_start => 1, spare_flag => 1, byte_ready_ready => 1},
                        core => {spare_bus => 9, byte_ready_pulse => 1}} },
    { name => 'allocated_domain', text => $collision,
      inputs => {bus_start => 1, bus_instance => 1, bus_instance_2 => 1, spare_bus => 9},
      domain_inputs => {bus => {bus_start => 1, bus_instance => 1, bus_instance_2 => 1, byte_ready_ready => 1},
                        core => {spare_bus => 9, byte_ready_pulse => 1}} },
) {
    subtest "$case->{name} preserves the declared input interface" => sub {
        my $path = "$work/$case->{name}.isf";
        write_file($path, $case->{text});
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $lowered = $scheduler->lower($actor);
        is_deeply($scheduler->lower($actor), $lowered, 'public lowering is deterministic and does not mutate its actor');
        my $dir = "$work/$case->{name}";
        mkdir $dir or die $!;
        my $emit = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', '--outdir', $dir, $path], '');
        is($emit->{exit_code}, 0, 'actual CLI materialization succeeds') or diag($emit->{stdout}, $emit->{stderr});
        opendir my $dh, $dir or die $!;
        my @files = sort grep { /\.fsm\z/ } readdir $dh;
        closedir $dh;
        is_deeply(\@files, [sort keys %{$lowered->{files}}], 'every lowering artifact is materialized');
        for my $file (@files) {
            is(read_file("$dir/$file"), $lowered->{files}{$file}, "$file has exactly the public lowering contents");
            my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$dir/$file"], '');
            is($check->{exit_code}, 0, "$file independently passes strict admission") or diag($check->{stdout}, $check->{stderr});
        }

        my $relative = File::Spec->abs2rel($path, $root);
        my %reports;
        for my $kind (qw(check semantic schedule)) {
            my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
            my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
            my $run = $capture->([$^X, 'bin/fsmgen', @{$flags{$kind}}, $relative], '');
            is($run->{exit_code}, 0, "$kind native query succeeds") or diag($run->{stdout}, $run->{stderr});
            $reports{$kind} = $normalize->($json->decode($run->{stdout}), $root);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tools{$kind}, arguments => {source_id => $relative}}};
            my $response = $api->handle_jsonrpc_request($request);
            ok(!$response->{result}{isError}, "$kind API succeeds");
            is_deeply($response->{result}{structuredContent}{report}, $reports{$kind}, "$kind entire native/API reports agree");
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, "$kind newline MCP transport succeeds");
            is_deeply($json->decode($wire->{stdout}), $response, "$kind complete newline/API responses agree");
        }
        my %public_inputs = %{$case->{inputs}};
        # The established multi-domain report scope includes top system pins;
        # ordinary FSM signal_analysis keeps system metadata separate.
        @public_inputs{qw(bus_clk bus_rst_n core_clk core_rst_n)} = (1, 1, 1, 1)
            if $case->{domain_inputs};
        is_deeply(input_widths($reports{semantic}{semantic}{signal_analysis}), \%public_inputs,
            'semantic public inputs have exactly the authored names, roles and widths');
        is($reports{schedule}{inputs}, scalar(keys %public_inputs), 'schedule input count agrees with actual public inputs');

        if ($case->{domain_inputs}) {
            my $children = $reports{semantic}{semantic}{forward_ir}{intent_hir}{composition_children};
            my %by_module = map { $_->{module_name} => $_ } @$children;
            for my $domain (@{$reports{schedule}{clock_domains}}) {
                (my $module = $domain->{scheduled_fsm}) =~ s/\.fsm\z//;
                is_deeply(input_widths($by_module{$module}{intent_hir}{signal_analysis}),
                    $case->{domain_inputs}{$domain->{name}},
                    "$domain->{name} keeps only its owned public/crossing inputs");
            }
        }
        for my $language (qw(systemverilog verilog)) {
            my $hdl = "$dir/$language.sv";
            my $run = $capture->([$^X, 'bin/fsmgen', '--strict', '--quiet', '--language', $language, '--output', $hdl, $path], '');
            is($run->{exit_code}, 0, "$language generation succeeds") or diag($run->{stderr});
            next if $run->{exit_code};
            my $text = read_file($hdl);
            for my $name (sort keys %{$case->{inputs}}) {
                my $width = $case->{inputs}{$name};
                my $range = $width == 1 ? '' : '\\[' . ($width - 1) . ':0\\]\\s+';
                like($text, qr/\binput\s+wire\s+$range\Q$name\E\b/, "$language declares $name at the authored width");
            }
        }
        if ($case->{name} eq 'domains') {
            subtest 'unused pins do not change public event behavior' => sub {
                plan skip_all => 'Verilator runtime provider unavailable or not qualified'
                    unless can_run('verilator') && darwin_verilator_runtime_qualified();
                for my $language (qw(systemverilog verilog)) {
                    my $build = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal', '-j', '1',
                        '-DUNUSED_DOMAIN_INPUTS', '--top-module', 'reset_event_tb', '--Mdir', "$dir/obj_$language",
                        "$dir/$language.sv", 't/data/isf_reset_event_tb.sv']);
                    ok($build->{ok}, "$language independent event oracle builds") or diag($build->{diagnostic}, $build->{stderr});
                    next unless $build->{ok};
                    my $run = run_generated_binary(["$dir/obj_$language/Vreset_event_tb"]);
                    ok($run->{ok}, "$language event behavior survives changing unused pins") or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
                    like($run->{stdout}, qr/ISF_RESET_EVENT_PASS/, "$language repeated/reset controls complete");
                }
            };
        }
    };
}
subtest 'generated transaction children retain their own input boundary' => sub {
    my $text = read_file('isf/spawn_parent.isf');
    $text =~ s/\(interface/(interface (input parent_only_spare (width 9))/;
    my $actor = FSM::Adapter::ISF->new->parse_source($text, 'parent_input_boundary.isf');
    my $files = $scheduler->lower($actor)->{files};
    like($files->{'spawn_parent.fsm'}, qr/\(input parent_only_spare\)/,
        'actor parent preserves its unused public input');
    my $child = $files->{'child_worker.fsm'};
    ok(defined $child, 'public lowering exposes the generated transaction child');
    my $path = "$work/child_worker.fsm";
    write_file($path, $child);
    my $run = $capture->([$^X, 'bin/fsmgen', '--strict', '--emit-semantic-json', $path], '');
    is($run->{exit_code}, 0, 'the actual child independently reaches strict semantic analysis')
        or diag($run->{stdout}, $run->{stderr});
    my $report = $json->decode($run->{stdout});
    ok(!exists input_widths($report->{semantic}{signal_analysis})->{parent_only_spare},
        'the child does not acquire an unrelated parent-only input');
};
done_testing();

sub input_widths {
    my ($analysis) = @_;
    return {map { $_->{name} => $_->{width} } @{$analysis->{inputs}}};
}
sub read_file {
    open my $fh, '<', $_[0] or die $!; local $/; return <$fh>;
}
sub write_file {
    open my $fh, '>', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!;
}
