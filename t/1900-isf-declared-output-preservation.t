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
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $audit = $json->decode(read_file('docs/audits/specforge-feature-intake-20260926.json'));
my ($ticket) = grep { $_->{ticket} eq 'sf-isf-optional-signal' } @{$audit->{tickets}};
my ($baseline) = grep { $_->{source}{path} =~ /\/baseline-good\.isf\z/ } @{$ticket->{cases}};
my $single = $baseline->{source}{text};
my $literal = $single;
$literal =~ s/\(width MECID_WIDTH\)/(width 16)/;
$literal =~ s/\(interface/(interface (output spare_flag)/;
my $driven = $single;
$driven =~ s/\(complete done\)/(update AWMECID 7) (complete done)/;
my $named = $single;
$named =~ s/\(clock clk\)\s*\(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low))))/;
my $multi = read_file('isf/clock_domain_event_crossing.isf');
$multi =~ s/\(interface/(interface (output spare_bus (width 9) (domain core))/;

for my $case (
    {name => 'caller', text => $single, outputs => {AWMECID => 16, done => 1}, spare => 'AWMECID'},
    {name => 'literal', text => $literal, outputs => {AWMECID => 16, done => 1, spare_flag => 1}, spare => 'AWMECID'},
    {name => 'driven', text => $driven, outputs => {AWMECID => 16, done => 1}},
    {name => 'named', text => $named, outputs => {AWMECID => 16, done => 1}, spare => 'AWMECID'},
    {name => 'domains', text => $multi, outputs => {spare_bus => 9, core_seen => 1}, spare => 'spare_bus',
        domains => {source => {byte_ready_req => 1}, core => {core_seen => 1, spare_bus => 9}}},
) {
    subtest "$case->{name} preserves declared outputs without invented values" => sub {
        my $path = "$work/$case->{name}.isf";
        write_file($path, $case->{text});
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $lowered = FSM::Scheduler::ISF->new->lower($actor);
        my $dir = "$work/$case->{name}";
        mkdir $dir or die $!;
        my $emit = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', '--outdir', $dir, $path], '');
        is($emit->{exit_code}, 0, 'actual FSM materialization succeeds') or diag($emit->{stdout}, $emit->{stderr});
        for my $file (sort keys %{$lowered->{files}}) {
            ok(-f "$dir/$file", "$file is materialized");
            next unless -f "$dir/$file";
            is(read_file("$dir/$file"), $lowered->{files}{$file}, "$file exactly matches public lowering");
        }
        my $relative = File::Spec->abs2rel($path, $root);
        my %reports;
        for my $kind (qw(check semantic schedule)) {
            my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
            my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
            my $run = $capture->([$^X, 'bin/fsmgen', @{$flags{$kind}}, $relative], '');
            is($run->{exit_code}, 0, "$kind native query succeeds") or diag($run->{stdout}, $run->{stderr});
            next if $run->{exit_code};
            $reports{$kind} = $normalize->($json->decode($run->{stdout}), $root);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tools{$kind}, arguments => {source_id => $relative}}};
            my $response = $api->handle_jsonrpc_request($request);
            ok(!$response->{error} && !$response->{result}{isError}, "$kind API succeeds");
            is_deeply($response->{result}{structuredContent}{report}, $reports{$kind}, "$kind native/API reports agree in full");
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, "$kind newline transport succeeds");
            is_deeply($json->decode($wire->{stdout}), $response, "$kind complete newline/API responses agree");
        }
        is_deeply(output_widths($reports{semantic}{semantic}{signal_analysis}), $case->{outputs}, 'realized semantic outputs exactly match authored roles and widths');
        is($reports{schedule}{outputs}, scalar keys %{$case->{outputs}}, 'schedule and realized output inventories agree');
        if ($case->{domains}) {
            my %children = map { $_->{module_name} => $_ } @{$reports{semantic}{semantic}{forward_ir}{intent_hir}{composition_children} || []};
            for my $domain (@{$reports{schedule}{clock_domains}}) {
                (my $module = $domain->{scheduled_fsm}) =~ s/\.fsm\z//;
                is_deeply(output_widths($children{$module}{intent_hir}{signal_analysis}), $case->{domains}{$domain->{name}},
                    "$domain->{name} retains exactly its owned and crossing outputs");
            }
        }
        my @languages = (qw(systemverilog verilog), ($case->{name} eq 'caller' ? 'vhdl' : ()));
        for my $language (@languages) {
            my $hdl = "$dir/$language." . ($language eq 'vhdl' ? 'vhd' : 'sv');
            my $run = $capture->([$^X, 'bin/fsmgen', '--quiet', '--strict', '--language', $language, '--output', $hdl, $path], '');
            is($run->{exit_code}, 0, "$language generation succeeds") or diag($run->{stdout}, $run->{stderr});
            next if $run->{exit_code};
            my $text = read_file($hdl);
            if ($language eq 'vhdl') {
                like($text, qr/AWMECID\s*:\s*out\s+std_logic_vector\(15 downto 0\)/, 'VHDL preserves the undriven output width');
                unlike($text, qr/AWMECID\s*<=/, 'VHDL invents no output assignment');
                subtest 'independent VHDL analysis' => sub {
                    my $ghdl = $ENV{FSMGEN_RESET_GHDL} // 'ghdl';
                    $ghdl = $ghdl =~ m{/} ? abs_path($ghdl) : can_run($ghdl);
                    plan skip_all => 'GHDL unavailable' unless defined($ghdl) && -x $ghdl;
                    my $check = $capture->([$ghdl, '-a', '--std=08', "--workdir=$dir", $hdl], '');
                    is($check->{exit_code}, 0, 'GHDL accepts the undriven output declaration') or diag($check->{stderr});
                };
                next;
            }
            for my $name (sort keys %{$case->{outputs}}) {
                my $width = $case->{outputs}{$name};
                my $range = $width == 1 ? '' : '\\[' . ($width - 1) . ':0\\]\\s+';
                like($text, qr/\boutput\s+(?:wire|reg|logic)\s+$range\Q$name\E\b/, "$language exports $name at its declared width");
            }
            if (my $spare = $case->{spare}) {
                unlike($text, qr/\b\Q$spare\E\s*(?:<=|=)/, "$language invents no value assignment for $spare");
            }
            if ($case->{name} eq 'caller') {
                subtest "$language independent port admission and wrong-width control" => sub {
                    plan skip_all => 'Verilator unavailable' unless can_run('verilator');
                    for my $width (16, 15) {
                        my $tb = "$dir/port_probe.sv";
                        write_file($tb, 'module port_probe; wire ['.($width-1).":0] observed;\n"
                            ."mecid_demo dut(.clk(1'b0), .rst_n(1'b1), .start(1'b0), .AWMECID(observed)); endmodule\n");
                        my $lint = $capture->(['verilator', '--lint-only', '-Wno-fatal', '--top-module', 'port_probe',
                            '--Mdir', "$dir/obj", $hdl, $tb], '');
                        is($lint->{exit_code}, 0, "external named port admission width=$width succeeds") or diag($lint->{stderr});
                        if ($width == 16) {
                            unlike($lint->{stderr}, qr/%Warning-WIDTH/, 'external compiler resolves the declared width');
                        } else {
                            like($lint->{stderr}, qr/%Warning-WIDTH/, 'independent wrong-width binding control is detected');
                        }
                    }
                };
            }
        }
    };
}

subtest 'transaction children do not acquire unrelated parent outputs' => sub {
    my $text = read_file('isf/spawn_parent.isf');
    $text =~ s/\(interface/(interface (output parent_only_spare (width 9))/;
    my $actor = FSM::Adapter::ISF->new->parse_source($text, 'parent_output_boundary.isf');
    my $files = FSM::Scheduler::ISF->new->lower($actor)->{files};
    like($files->{'spawn_parent.fsm'}, qr/\(output parent_only_spare\)/, 'parent preserves its own output');
    unlike($files->{'child_worker.fsm'}, qr/parent_only_spare/, 'child has no unrelated parent port');
};
done_testing();

sub output_widths {
    my ($analysis) = @_;
    return {map { $_->{name} => $_->{width} } @{$analysis->{outputs} || []}};
}
sub read_file { open my $fh, '<', $_[0] or die $!; local $/; return <$fh>; }
sub write_file { open my $fh, '>', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!; }
