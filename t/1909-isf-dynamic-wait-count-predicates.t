#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::ProcessSupervisor qw(supervise_process);
use FSM::Test::SourceQueryRunner;
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Pipeline::HDLGenerator;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use JSON::PP qw(decode_json);

my $work = tempdir(CLEANUP => 1);
for my $case (
    ['entry', '(wait cycles)', 'cycles'],
    ['expression', '(wait (+ cycles bias))', '(+ cycles bias)'],
    ['await', '(await ready) (wait cycles)', 'cycles'],
    ['consecutive', '(wait cycles) (wait tail_count)', 'cycles'],
    ['branch', '(when ready (wait cycles))', 'cycles'],
) {
    my ($name, $body, $count_source) = @$case;
    subtest "$name counts and sampled timing" => sub {
        my $dir = "$work/$name";
        mkdir $dir or die $!;
        my $source = <<"ISF";
(actor count_$name
 (clock clk) (reset (rst_n async active_low))
 (interface (input start) (input ready) (input cycles (width 4))
  (input tail_count (width 4)) (input bias (width 4)) (output done))
 (transaction main (on start) $body (complete done)))
ISF
        my $file = write_file("$dir/source.isf", $source);
        my $actor = FSM::Adapter::ISF->new->parse_source($source, "$name.isf");
        my $report = decode_json(FSM::Scheduler::ISF->new->report($actor));
        is($report->{transaction_waits}[0]{count_source}, $count_source, 'report retains authored count source');
        my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($file)->{hdl_code};
        if ($name eq 'entry') {
            public_parity($file);
            vhdl_runtime($dir, $file);
        }
        my $has_tail = $name eq 'consecutive' ? 1 : 0;
        my $has_bias = $name eq 'expression' ? 1 : 0;
        my $snapshot = $name eq 'entry' ? 1 : 0;
        simulate($dir, $hdl, <<"SV");
module tb;
 logic clk=0, rst_n=1, start=0, ready=1;
 logic [3:0] cycles=0, tail_count=0, bias=0;
 wire done;
 int baseline, latency;
 always #5 clk=~clk;
 count_$name dut(.*);
 task tick; @(posedge clk); #1; endtask
 task activation(input int first, input int second, input int addend,
                 input bit change_after_entry, output int elapsed);
  @(negedge clk);cycles=4'(first);tail_count=4'(second);bias=4'(addend);start=1;
  tick;
  @(negedge clk);start=0;
  if(change_after_entry) cycles=0;
  elapsed=0;
  while(!done && elapsed<50) begin tick;elapsed++;end
  if(!done) \$fatal(1,"positive count stalled: first=%0d second=%0d bias=%0d",first,second,addend);
  repeat(4) tick;
  if(done) \$fatal(1,"completion failed to return to idle");
 endtask
 initial begin
  #2;rst_n=0;#10;rst_n=1;
  activation(0,0,0,0,baseline);
  // Exhaust the full declared scalar range, including every even value.
  for(int n=0;n<16;n++) begin
   activation(n,0,0,0,latency);
   if(latency!=baseline+n) \$fatal(1,"wrong delay for count %0d: got %0d baseline %0d",n,latency,baseline);
   if($has_tail) begin
    foreach_tail: for(int m=0;m<16;m++) begin
     activation(n,m,0,0,latency);
     if(latency!=baseline+n+m) \$fatal(1,"consecutive wait edge mismatch: %0d %0d",n,m);
    end
   end
   if($has_bias && n<15) begin
    activation(n,0,1,0,latency);
    if(latency!=baseline+n+1) \$fatal(1,"expression count mismatch: %0d",n);
   end
  end
  if($snapshot) begin
   activation(4,0,0,1,latency);
   if(latency!=baseline+4) \$fatal(1,"count was re-read after entry");
  end
  \$display("DYNAMIC_COUNT_PASS");\$finish;
 end
 initial begin #200000;\$fatal(1,"test timeout");end
endmodule
SV
    };
}
done_testing();

sub public_parity {
    my ($source) = @_;
    my $root = abs_path('.');
    my $relative = File::Spec->abs2rel($source, $root);
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    my $json = JSON::PP->new->canonical;
    for my $query (['check', [qw(--strict --check --json)], 'fsmgen_check'],
                   ['semantic', [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
                   ['schedule', ['--emit-schedule-json'], 'fsmgen_schedule_preview']) {
        my ($kind, $flags, $tool) = @$query;
        my $native = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', @$flags, $relative], '');
        is($native->{exit_code}, 0, "native $kind accepted");
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tool, arguments => {source_id => $relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
        is_deeply($response->{result}{structuredContent}{report}, $report, "complete native/API $kind parity");
        my $wire = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
        is_deeply($json->decode($wire->{stdout}), $response, "complete newline/API $kind parity");
    }
}

sub vhdl_runtime {
    my ($dir, $source) = @_;
    subtest 'VHDL scalar count timing' => sub {
        my $ghdl = $ENV{FSMGEN_RESET_GHDL} // 'ghdl';
        $ghdl = $ghdl =~ m{/} ? abs_path($ghdl) : can_run($ghdl);
        plan skip_all => 'GHDL provider unavailable' unless $ghdl && -x $ghdl;
        my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1, target_language => 'vhdl')->generate_hdl_from_file($source)->{hdl_code};
        my $dut = write_file("$dir/dut.vhd", $hdl);
        my $tb = write_file("$dir/count_tb.vhd", <<'VHDL');
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity count_tb is end;
architecture behavior of count_tb is
 signal clk: std_logic := '0'; signal rst_n: std_logic := '1'; signal start: std_logic := '0';
 signal ready: std_logic := '1'; signal cycles, tail_count, bias: std_logic_vector(3 downto 0) := (others=>'0');
 signal done: std_logic;
begin
 clk <= not clk after 5 ns;
 dut: entity work.count_entry port map(clk=>clk,rst_n=>rst_n,start=>start,ready=>ready,
  cycles=>cycles,tail_count=>tail_count,bias=>bias,done=>done);
 process
  variable baseline, elapsed: integer := 0;
  procedure tick is begin wait until rising_edge(clk);wait for 1 ns;end;
 begin
  wait for 2 ns;rst_n<='0';wait for 10 ns;rst_n<='1';
  for n in 0 to 15 loop
   wait until falling_edge(clk);cycles<=std_logic_vector(to_unsigned(n,4));start<='1';tick;
   wait until falling_edge(clk);start<='0';cycles<=(others=>'0');
   elapsed:=0;
   while done/='1' and elapsed<25 loop tick;elapsed:=elapsed+1;end loop;
   assert done='1' report "positive count stalled" severity failure;
   if n=0 then baseline:=elapsed;end if;
   assert elapsed=baseline+n report "count delay or sampling mismatch" severity failure;
   for i in 1 to 4 loop tick;end loop;
  end loop;
  report "DYNAMIC_COUNT_PASS" severity note;std.env.stop;wait;
 end process;
end;
VHDL
        my $run = sub { supervise_process(schema => 'fsmgen.test.dynamic_count.v1', stage => 'ghdl',
            bounds => {timeout_seconds => 60, capture_limit_bytes => 1_048_576},
            containment => 'test_runtime_process_group', cwd => $dir, argv => $_[0]) };
        my $compile = $run->([$ghdl, '-a', '--std=08', '--workdir='.$dir, $dut, $tb]);
        ok($compile->{ok}, 'GHDL analysis') or diag($compile->{diagnostic}, $compile->{stderr});
        return unless $compile->{ok};
        my $result = $run->([$ghdl, '--elab-run', '--std=08', '--workdir='.$dir, 'count_tb', '--assert-level=error', '--stop-time=10000ns']);
        ok($result->{ok}, 'VHDL independent count and sampling oracle passes') or diag($result->{diagnostic}, $result->{stdout}, $result->{stderr});
        like($result->{stdout}.$result->{stderr}, qr/DYNAMIC_COUNT_PASS/, 'VHDL bounded range completed');
    };
}

sub simulate {
    my ($dir, $hdl, $tb) = @_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable', 3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $sv = write_file("$dir/dut.sv", $hdl);
        my $test = write_file("$dir/tb.sv", $tb);
        my $obj = "$dir/obj";
        my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '--top-module', 'tb', '--Mdir', $obj, $sv, $test]);
        ok($compile->{ok}, 'independent HDL compiler accepts runtime waits') or diag($compile->{diagnostic}, $compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed'); fail('runtime observation absent'); }
        else {
            my $run = run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok}, 'independent elapsed-cycle oracle passes') or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
            like($run->{stdout}, qr/DYNAMIC_COUNT_PASS/, 'all bounded count observations completed');
        }
    }
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!"; print {$fh} $text; close $fh or die "close $path: $!"; return $path;
}
