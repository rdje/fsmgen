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
use FSM::Pipeline::HDLGenerator;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $json = JSON::PP->new->canonical;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my @cases = (
    {name => 'spawn'},
    {name => 'do', do => 1},
    {name => 'reused', reused => 1},
    {name => 'simultaneous', simultaneous => 1},
    {name => 'shared', shared => 1},
    {name => 'typed', typed => 1},
    {name => 'local', local => 1},
    {name => 'local_shadow', local_shadow => 1},
    {name => 'collisions', collisions => 1, shared => 1},
);
for my $case (@cases) {
    subtest $case->{name} => sub {
        my $dir = "$work/$case->{name}"; mkdir $dir or die $!;
        my $output = $case->{typed} ? '(output notice (type Pulse))' : '(output notice)';
        my $types = $case->{typed} ? '(types (type Pulse bit))' : '';
        my $ports = $case->{local} ? '(ports (output local_notice))'
            : $case->{local_shadow} ? '(ports (output notice))' : '';
        my $target = $case->{local} ? 'local_notice' : 'notice';
        my $binding = $case->{local} ? '(bind (output local_notice notice))'
            : $case->{local_shadow} ? '(bind (output notice mirrored))' : '';
        my $mirror = $case->{local_shadow} ? '(output mirrored)' : '';
        my $activation = $case->{do}
            ? '(do worker (params (WIDTH 16)))'
            : "(spawn worker as w0 $binding)" . ($case->{reused} ? '(spawn worker as w1)' : $case->{simultaneous} ? '(spawn fast as w1)' : '') . '(await_all done)';
        my $parent_target = $case->{shared} ? 'notice' : 'done';
        my $collision = $case->{collisions} ? '(input isf_child_completion_w0_notice) (input isf_local_completion_notice) (input w0_notice)' : '';
        my $fast = $case->{simultaneous} ? '(transaction fast (wait 1) (complete notice))' : '';
        my $source = write_file("$dir/source.isf", "(actor named_completion (clock clk) (reset (rst_n async active_low)) $types
 (interface (input start) $collision $output $mirror (output done))
 (transaction worker (params (WIDTH 8)) $ports (wait 2) (complete $target))
 $fast
 (transaction parent (on start) $activation (complete $parent_target)))\n");
        my $actor = FSM::Adapter::ISF->new->parse_file($source);
        my $files = FSM::Scheduler::ISF->new->lower($actor)->{files};
        write_file("$dir/$_", $files->{$_}) for sort keys %$files;
        for my $file (sort keys %$files) {
            my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$dir/$file"], '');
            is($check->{exit_code}, 0, "$file strict public replay") or diag($check->{stdout}, $check->{stderr});
        }
        my $relative = File::Spec->abs2rel($source, $root);
        for my $query (['check', [qw(--strict --check --json)], 'fsmgen_check'],
                       ['semantic', [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
                       ['schedule', ['--emit-schedule-json'], 'fsmgen_schedule_preview']) {
            my ($kind, $flags, $tool) = @$query;
            my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
            is($native->{exit_code}, 0, "native $kind accepted") or diag($native->{stdout}, $native->{stderr});
            my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tool, arguments => {source_id => $relative}}};
            my $response = $api->handle_jsonrpc_request($request);
            is_deeply($response->{result}{structuredContent}{report}, $report, "complete native/API $kind parity");
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is_deeply($json->decode($wire->{stdout}), $response, "complete newline/API $kind parity");
            if ($kind eq 'semantic') {
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{inputs}}],
                    [sort qw(clk rst_n start), ($case->{collisions} ? qw(isf_child_completion_w0_notice isf_local_completion_notice w0_notice) : ())],
                    'private completion channels do not escape as public inputs');
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{outputs}}],
                    [sort qw(done notice), ($case->{local_shadow} ? 'mirrored' : ())], 'exact public output names');
                my @children = @{$report->{semantic}{forward_ir}{intent_hir}{composition_children}};
                my ($worker) = grep { $_->{source_name} eq 'worker' } @children;
                my %drives = map { $_->{signal_name} => $_ }
                    @{$worker->{lowered_rtl_ir}{output_drive_families}};
                is($drives{done}{pulse_delay_cycles}, 1, 'canonical handshake retains delayed-event semantics');
                is($drives{$target}{pulse_delay_cycles}, 1, 'authored completion retains the same pulse delay');
                my $candidates = $report->{semantic}{forward_ir}{lowered_rtl_ir}{composition_shared_datapath_candidates} || [];
                ok(!grep({ $_->{signal_name} eq 'done' || $_->{signal_name} eq $target } @$candidates),
                    'independent event channels are not inferred as shared datapaths');
            }
        }
        my $notice_cycles = ($case->{local_shadow} ? '0' : 'cycle == 5') . ($case->{reused} ? ' || cycle == 6' : '') . ($case->{shared} ? ' || cycle == 8' : '');
        my $done_cycles = $case->{shared} ? '0' : $case->{reused} ? 'cycle == 9' : 'cycle == 8';
        my $pins = $case->{collisions} ? 'logic isf_child_completion_w0_notice=0, isf_local_completion_notice=0,w0_notice=0;' : '';
        $pins .= 'wire mirrored;' if $case->{local_shadow};
        my $mirror_check = $case->{local_shadow}
            ? 'if(mirrored!==(cycle==5)) $fatal(1,"explicit local shadow output binding lost");' : '';
        my $tb = <<"SV";
module tb;
 logic clk=0,rst_n=1,start=0;
 wire notice,done;
 $pins
 always #5 clk=~clk;
 named_completion_top dut(.*);
 initial begin
  #2;rst_n=0;#1;
  if(notice!==0 || done!==0) \$fatal(1,"reset did not clear pulses");
  #13;rst_n=1;
  repeat(2) begin
   @(negedge clk);start=1;
   for(integer cycle=0;cycle<14;cycle=cycle+1) begin
    @(posedge clk);#1;
    if(notice!==($notice_cycles)) \$fatal(1,"notice edge cycle=%d notice=%d",cycle,notice);
    if(done!==($done_cycles)) \$fatal(1,"done edge cycle=%d done=%d",cycle,done);
    $mirror_check
    @(negedge clk);start=0;
   end
  end
  \$display("NAMED_COMPLETION_PASS");\$finish;
 end
 initial begin #3000;\$fatal(1,"completion timeout");end
endmodule
SV
        my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($source)->{hdl_code};
        simulate($dir, $hdl, $tb);
    };
}
subtest 'mixed writer is refused precisely' => sub {
    my $source = write_file("$work/mixed.isf", <<'ISF');
(actor mixed_completion (clock clk) (reset (rst_n async active_low))
 (interface (input start) (output notice) (output done))
 (transaction worker (wait 2) (complete notice))
 (transaction parent (on start) (set notice 0) (spawn worker as w0) (await_all done) (complete done)))
ISF
    my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $source], '');
    isnt($check->{exit_code}, 0, 'mixed writer cannot gain an invented priority');
    like($check->{stdout}.$check->{stderr}, qr/Actor completion output 'notice' mixes generated child completion with a non-completion writer/,
        'explicit diagnostic identifies unsupported writer ownership');
};
done_testing();
sub simulate {
    my ($dir, $hdl, $tb) = @_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable', 3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $sv = write_file("$dir/dut.sv", $hdl); my $test = write_file("$dir/tb.sv", $tb); my $obj = "$dir/obj";
        my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '--top-module', 'tb', '--Mdir', $obj, $sv, $test]);
        ok($compile->{ok}, 'independent named-completion HDL compile') or diag($compile->{diagnostic}, $compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed'); fail('runtime observation absent'); }
        else {
            my $run = run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok}, 'named pulse timing and repeated activation pass') or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
            like($run->{stdout}, qr/NAMED_COMPLETION_PASS/, 'independent named-completion observations complete');
        }
    }
}
sub write_file { my ($path,$text)=@_;open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;return $path; }
