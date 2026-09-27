#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Copy qw(copy);
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
my $dual = <<'ISF';
(actor domain_children
 (clock-domains
  (domain core (clock clk) (reset (rst_n async active_low)) :default)
  (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))
 (interface (input start) (input data (width 8)) (input core__w0)
  (output observed (width 8)) (output again (width 8)) (output core_done)
  (input aux_start (domain aux)) (input aux_data (width 8) (domain aux))
  (output aux_observed (width 8) (domain aux)) (output aux_done (domain aux)))
 (transaction worker (params (WIDTH 8)) (ports (output result (width 8)))
  (wait 2) (set result data) (complete done))
 (transaction parent (on start)
  (spawn worker as w0 (bind (output result observed)))
  (spawn worker as w1 (params (WIDTH 16)) (bind (output result again)))
  (await_all core_done) (complete core_done))
 (transaction aux_worker (domain aux) (params (WIDTH 8))
  (ports (input data (width 8)) (output result (width 8)))
  (wait 3) (set result data) (complete done))
 (transaction aux_parent (domain aux) (on aux_start)
  (do aux_worker (params (WIDTH 32)) (bind (input data aux_data) (output result aux_observed)))
  (complete aux_done)))
ISF
my $named_completion = $dual;
$named_completion =~ s/\(wait 3\) \(set result data\) \(complete done\)/(wait 3) (set result data) (complete aux_done)/;
my $cdc_await = <<'ISF';
(actor domain_cdc_child
 (clock-domains
  (domain source (clock bus_clk) (reset (bus_rst_n async active_low)) :default)
  (domain core (clock core_clk) (reset (core_rst_n async active_low))))
 (crossings (event ready_event (from source event_req) (to core event_pulse) (ready event_ready)))
 (interface (input bus_start) (input core_start (domain core)) (output core_seen (domain core)))
 (transaction produce (on bus_start) (await event_ready) (complete event_req))
 (transaction worker (domain core) (await event_pulse) (complete done))
 (transaction parent (domain core) (on core_start) (spawn worker as w0)
  (await_all core_seen) (complete core_seen)))
ISF
my $dual_tb = <<'SV';
module tb;
 logic clk=0, aux_clk=0, run_core=0, rst_n=1, aux_rst_n=1;
 logic start=0, aux_start=0, core__w0=0;
 logic [7:0] data=91, aux_data=166;
 wire [7:0] observed, again, aux_observed; wire core_done, aux_done;
 integer aux_samples=0;
 always @(posedge aux_clk) if(aux_observed!=0) begin
  if(aux_observed!==aux_data) $fatal(1,"wrong do-completion payload");
  aux_samples=aux_samples+1;
 end
 always #5 if(run_core) clk=~clk;
 always #7 aux_clk=~aux_clk;
 domain_children_top dut(.*);
 initial begin
  #2;rst_n=0;aux_rst_n=0;#14;rst_n=1;aux_rst_n=1;
  @(negedge aux_clk);aux_start=1;@(negedge aux_clk);aux_start=0;
  wait(aux_done);#1;
  if(aux_samples!=1 || core_done!==0) $fatal(1,"aux completion sample absent or wrong owning clock");
  run_core=1;
  @(negedge clk);start=1;@(negedge clk);start=0;
  wait(core_done);#1;
  if(observed!==91 || again!==91) $fatal(1,"reused core children or staggered completion lost");
  repeat(6) @(negedge clk);
  rst_n=0;#2;
  if(aux_done!==0) $fatal(1,"core reset created an aux completion");
  #12;rst_n=1;data=7;aux_data=3;
  fork
   begin @(negedge clk);start=1;@(negedge clk);start=0;wait(core_done);#1;
    if(observed!==7 || again!==7) $fatal(1,"core reactivation failed");end
   begin @(negedge aux_clk);aux_start=1;@(negedge aux_clk);aux_start=0;wait(aux_done);#1;
    if(aux_samples!=2) $fatal(1,"aux reactivation samples=%d expected=2",aux_samples);end
  join
  $display("DOMAIN_CHILD_PASS");$finish;
 end
 initial begin #5000;$fatal(1,"domain child timeout");end
endmodule
SV
my $named_tb = <<'SV';
module tb;
 logic clk=0,aux_clk=0,rst_n=1,aux_rst_n=1,start=0,aux_start=0,core__w0=0;
 logic [7:0] data=91,aux_data=166;
 wire [7:0] observed,again,aux_observed;wire core_done,aux_done;
 always #7 aux_clk=~aux_clk;
 domain_children_top dut(.*);
 initial begin
  #2;rst_n=0;aux_rst_n=0;#14;rst_n=1;aux_rst_n=1;
  repeat(2) begin
   @(negedge aux_clk);aux_start=1;
   for(integer cycle=0;cycle<15;cycle=cycle+1) begin
    @(posedge aux_clk);#1;
    if(aux_done!==(cycle==7 || cycle==10)) $fatal(1,"named domain pulse cycle=%d done=%d",cycle,aux_done);
    if(aux_observed!==((cycle==7) ? aux_data : 0)) $fatal(1,"domain payload edge cycle=%d",cycle);
    if(core_done!==0) $fatal(1,"completion escaped its domain");
    @(negedge aux_clk);aux_start=0;
   end
   aux_data=3;
  end
  $display("DOMAIN_CHILD_PASS");$finish;
 end
 initial begin #5000;$fatal(1,"named domain timeout");end
endmodule
SV
my $cdc_await_tb = <<'SV';
module tb;
 logic bus_clk=0,core_clk=0,bus_rst_n=1,core_rst_n=1,bus_start=0,core_start=0;
 wire core_seen;
 always #7 bus_clk=~bus_clk;
 always #5 core_clk=~core_clk;
 domain_cdc_child_top dut(.*);
 initial begin
  #2;bus_rst_n=0;core_rst_n=0;#14;bus_rst_n=1;core_rst_n=1;
  repeat(2) begin
   @(negedge core_clk);core_start=1;@(negedge core_clk);core_start=0;
   repeat(8) @(negedge core_clk);
   if(core_seen!==0) $fatal(1,"child completed without CDC event");
   @(negedge bus_clk);bus_start=1;@(negedge bus_clk);bus_start=0;
   wait(core_seen);repeat(20) @(negedge core_clk);
  end
  $display("DOMAIN_CHILD_PASS");$finish;
 end
 initial begin #5000;$fatal(1,"CDC child timeout");end
endmodule
SV
my $cdc = <<'ISF';
(actor domain_cdc_child
 (clock-domains
  (domain source (clock bus_clk) (reset (bus_rst_n async active_low)) :default)
  (domain core (clock core_clk) (reset (core_rst_n async active_low))))
 (crossings (event ready_event (from source event_req) (to core event_pulse) (ready event_ready)))
 (interface (input bus_start) (output ready_seen) (output core_seen (domain core)))
 (transaction worker (ports (output result)) (wait 4) (set result event_ready) (complete done))
 (transaction parent (on bus_start) (spawn worker as w0 (bind (output result ready_seen)))
  (await_all event_req) (complete event_req))
 (transaction receive (domain core) (on event_pulse) (complete core_seen)))
ISF
my $cdc_tb = <<'SV';
module tb;
 logic bus_clk=0,core_clk=0,bus_rst_n=1,core_rst_n=1,bus_start=0;
 wire core_seen,ready_seen;
 always #7 bus_clk=~bus_clk;
 always #5 core_clk=~core_clk;
 domain_cdc_child_top dut(.*);
 initial begin
  #2;bus_rst_n=0;core_rst_n=0;#14;bus_rst_n=1;core_rst_n=1;
  repeat(2) begin
   repeat(8) @(negedge bus_clk);
   bus_start=1;@(negedge bus_clk);bus_start=0;
   wait(core_seen);#1;
   if(ready_seen!==1) $fatal(1,"child failed to read internal CDC ready");
   repeat(20) @(negedge core_clk);
  end
  $display("DOMAIN_CHILD_PASS");$finish;
 end
 initial begin #5000;$fatal(1,"CDC child timeout");end
endmodule
SV
my $library = do {
    open my $fh, '<', 'isf/fifo_library_use.isf' or die $!;
    local $/; <$fh>;
};
$library =~ s/\(clock clk\)\s*\(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default) (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))/;
$library =~ s/\(interface/(interface (input aux_start (domain aux)) (output aux_done (domain aux))/;
$library =~ s/\)\s*\z/ (transaction aux_tx (domain aux) (on aux_start) (complete aux_done)))/;
my $module_collision = $dual;
$module_collision =~ s/\bdomain aux\b/domain core__child_worker/g;
for my $case (
    ['named', $named_completion, $named_tb, [qw(aux_clk aux_data aux_rst_n aux_start clk core__w0 data rst_n start)],
        [qw(again aux_done aux_observed core_done observed)]],
    ['dual', $dual, $dual_tb, [qw(aux_clk aux_data aux_rst_n aux_start clk core__w0 data rst_n start)],
        [qw(again aux_done aux_observed core_done observed)]],
    ['module_collision', $module_collision, $dual_tb, [qw(aux_clk aux_data aux_rst_n aux_start clk core__w0 data rst_n start)],
        [qw(again aux_done aux_observed core_done observed)]],
    ['cdc', $cdc, $cdc_tb, [qw(bus_clk bus_rst_n bus_start core_clk core_rst_n)], [qw(core_seen ready_seen)]],
) {
    my ($name, $text, $tb, $inputs, $outputs) = @$case;
    subtest $name => sub {
        my $dir = "$work/$name"; mkdir $dir or die $!;
        my $source = write_file("$dir/source.isf", $text);
        my $actor = FSM::Adapter::ISF->new->parse_file($source);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $files = $scheduler->lower($actor)->{files};
        write_file("$dir/$_", $files->{$_}) for sort keys %$files;
        my $schedule = $json->decode($scheduler->report($actor));
        my %file_names;
        for my $file (sort keys %$files) {
            ok(!$file_names{lc($file)}++, 'artifact names are unique ignoring case');
            my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$dir/$file"], '');
            is($check->{exit_code}, 0, "$file strict public replay") or diag($check->{stdout}, $check->{stderr});
        }
        my $top = $files->{$schedule->{scheduled_fsm}};
        my %domain_files = map { $_->{scheduled_fsm} => 1 } @{$schedule->{clock_domains}};
        my @child_files = grep { /__child_/ && !$domain_files{$_} } keys %$files;
        is(scalar @child_files, $name eq 'cdc' ? 1 : 2, 'every generated child definition has an artifact');
        for my $file (@child_files) {
            (my $module = $file) =~ s/\.fsm\z//;
            like($top, qr/\(\?fsmc:[\w]+ \Q$module\E(?:\s|\))/, 'child module is instantiated in the top');
        }
        like($top, qr/\?fsmc:core__w0_child /, 'public pin collision receives a distinct child instance') if $name ne 'cdc';
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
                my %children = map { $_->{instance_name} => $_ }
                    @{$report->{semantic}{forward_ir}{intent_hir}{composition_children}};
                while ($top =~ /\(\?fsmc:(\w+) (\w+)/g) {
                    my ($instance, $module) = ($1, $2);
                    is($children{$instance}{source_name}, $module,
                        'semantic child source identity joins to the emitted artifact');
                }
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{inputs}}], $inputs, 'exact authored and system inputs');
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{outputs}}], $outputs, 'exact authored outputs');
            }
        }
        my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($source)->{hdl_code};
        simulate($dir, $hdl, $tb);
    };
}
subtest 'no-reset domain children preserve reset absence' => sub {
    my $text = $dual;
    $text =~ s/\s*\(reset \(\w+ async active_low\)\)//g;
    my $source = write_file("$work/no-reset.isf", $text);
    my $actor = FSM::Adapter::ISF->new->parse_file($source);
    my $files = FSM::Scheduler::ISF->new->lower($actor)->{files};
    for my $file (grep { /__child_/ } keys %$files) {
        unlike($files->{$file}, qr/\((?:a|s)reset\s/, 'child has no invented reset system clause');
    }
    my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $source], '');
    is($check->{exit_code}, 0, 'clock-only domain-child composition passes strict admission')
        or diag($check->{stdout}, $check->{stderr});
};
subtest 'child await watchdog remains owned by .32.1.3.3.3' => sub {
    my $dir = "$work/cdc_await"; mkdir $dir or die $!;
    my $source = write_file("$dir/source.isf", $cdc_await);
    my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($source)->{hdl_code};
    local $TODO = 'child entry watchdog initialization is owned by .32.1.3.3.3';
    simulate($dir, $hdl, $cdc_await_tb);
};
subtest 'library parent interfaces remain owned by .47' => sub {
    mkdir "$work/common" or die $!;
    copy('isf/common/fifo.isf', "$work/common/fifo.isf") or die $!;
    my $source = write_file("$work/library.isf", $library);
    my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $source], '');
    isnt($check->{exit_code}, 0, 'unqualified library interfaces are not called successful');
    like($check->{stdout}, qr/leaves child port 'core\.data_in' unconnected/,
        'retain the domain form of the unchanged T1238 interface failure');
};
done_testing();
sub simulate {
    my ($dir, $hdl, $tb) = @_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable', 3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $sv = write_file("$dir/dut.sv", $hdl); my $test = write_file("$dir/tb.sv", $tb); my $obj = "$dir/obj";
        my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '--top-module', 'tb', '--Mdir', $obj, $sv, $test]);
        ok($compile->{ok}, 'independent domain-child HDL compile') or diag($compile->{diagnostic}, $compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed'); fail('runtime observation absent'); }
        else {
            my $run = run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok}, 'domain clocks, resets and repeated completion pass') or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
            like($run->{stdout}, qr/DOMAIN_CHILD_PASS/, 'independent domain-child observations complete');
        }
    }
}
sub write_file { my ($path,$text)=@_;open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;return $path; }
