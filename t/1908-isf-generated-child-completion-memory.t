#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Pipeline::HDLGenerator;

my $work = tempdir(CLEANUP => 1);
for my $case (
    ['all', '', '(await_all done)', ''],
    ['early_any_all', '(wait 8)', '(await_any done) (await_all done)', ''],
    ['dynamic', '', '(await_all done)', '(wait cycles)'],
) {
    my ($name, $before, $join, $after) = @$case;
    subtest "$name completion lifetime" => sub {
        my $source = <<"ISF";
(actor completion_$name
 (clock clk) (reset (rst_n async active_low))
 (interface (input start) (input cycles (width 4))
  (input isf_completion_w0_seen) (input ISF_COMPLETION_W1_READY)
  (output done))
 (transaction worker (wait 3) (complete done))
 (transaction main (on start)
  (spawn worker as w0) (spawn worker as w1)
  $before $join $after (complete done)))
ISF
        my $actor = FSM::Adapter::ISF->new->parse_source($source, "$name.isf");
        my $ir = FSM::Scheduler::ISF::LoweringIR->new->build_module($actor);
        my @joins = grep { ($_->{kind} // '') =~ /^sync_/ } @{$ir->{states}};
        for my $state (@joins) {
            is_deeply($state->{done_ports}, [qw(w0_done w1_done)], 'raw handoff metadata is preserved');
            isnt($state->{completion_ports}[0], 'w0_done', 'join uses retained completion');
        }
        is($ir->{storage_roles}{isf_completion_w0_seen_completion}, 'child_completion_seen',
            'completion storage avoids an authored identifier collision');
        is($ir->{storage_roles}{isf_completion_w1_ready_completion}, 'child_completion_view',
            'completion view avoids a case-folded identifier collision');
        my $lowered = FSM::Scheduler::ISF->new->lower($actor);
        my $top = $lowered->{files}{"completion_${name}_top.fsm"};
        my ($top_declaration) = split /\n\(\?fsm:/, $top;
        unlike($top_declaration, qr/isf_completion_w0_seen_completion|isf_completion_w1_ready_completion/,
            'private completion storage does not leak into top wiring or ports');
        my $dir = "$work/$name";
        mkdir $dir or die $!;
        my $parent = write_file("$dir/parent.fsm", $lowered->{files}{"completion_$name.fsm"});
        my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($parent)->{hdl_code};
        my $dynamic = $name eq 'dynamic' ? 1 : 0;
        # Exercise the generated parent's public handoff interface with an
        # independent child model. Pulses need not line up or wait for the join.
        simulate($dir, $hdl, <<"SV");
module tb;
 logic clk=0, rst_n=1, start=0, w0_done=0, w1_done=0;
 logic [3:0] cycles=0;
 logic isf_completion_w0_seen=0, ISF_COMPLETION_W1_READY=0;
 wire done, w0_start, w1_start;
 int base_latency, repeated_latency, simultaneous_latency, delayed_latency;
 always #5 clk=~clk;
 completion_$name dut(.*);
 task tick; @(posedge clk); #1; endtask
 task launch;
  @(negedge clk); start=1;
  @(negedge clk); start=0;
  wait(w1_start); tick;
 endtask
 task run_activation(input bit simultaneous, input int count, output int latency);
  cycles=4'(count); launch;
  // The first pulse may arrive before the parent reaches its sync state.
  @(negedge clk); w0_done=1; w1_done=simultaneous;
  tick;
  @(negedge clk); w0_done=0; w1_done=0;
  if (!simultaneous) begin
   repeat(12) begin tick; if(done) \$fatal(1,"join reused stale or partial completion"); end
   @(negedge clk); w1_done=1;
   tick;
   @(negedge clk); w1_done=0;
  end
  latency=0;
  while(!done && latency<25) begin tick; latency++; end
  if(!done) \$fatal(1,"lost non-overlapping completion pulse");
  repeat(5) tick;
  if(done) \$fatal(1,"parent done stopped being a pulse");
 endtask
 initial begin
  #2;rst_n=0;#10;rst_n=1;
  run_activation(0,0,base_latency);
  if(base_latency!=2) \$fatal(1,"last live completion added a capture cycle: %0d",base_latency);
  run_activation(0,0,repeated_latency);
  if(repeated_latency!=base_latency) \$fatal(1,"reactivation timing changed");
  run_activation(1,0,simultaneous_latency);
  run_activation(0,4,delayed_latency);
  if($dynamic && delayed_latency!=base_latency+4) \$fatal(1,"dynamic join count not sampled on completion edge");
  // Reset between an early completion and its partner; the old completion
  // must not satisfy the next activation's join.
  launch;
  @(negedge clk);w0_done=1;tick;
  @(negedge clk);w0_done=0;rst_n=0;tick;
  @(negedge clk);rst_n=1;
  run_activation(0,0,repeated_latency);
  \$display("COMPLETION_LIFETIME_PASS");\$finish;
 end
 initial begin #10000;\$fatal(1,"test timeout");end
endmodule
SV
    };
}

subtest 'observe versus drain is consistent in each admitted region' => sub {
    my $multi = '(spawn worker as w0) (spawn worker as w1) (await_any done) (await_all done)';
    for my $body ($multi, "(when start $multi)", "(switch start (1 $multi))",
                  "(while start $multi)", "(until start $multi)", "(repeat 2 $multi)") {
        my $source = "(actor region_probe (clock clk) (reset rst_n) "
            . "(interface (input start) (output done)) "
            . "(transaction worker (complete done)) "
            . "(transaction main (on start) $body (complete done)))";
        my $actor = FSM::Adapter::ISF->new->parse_source($source, 'region-probe.isf');
        my $ir = FSM::Scheduler::ISF::LoweringIR->new->build_module($actor);
        my @joins = grep { ($_->{kind} // '') =~ /^sync_/ } @{$ir->{states}};
        is(scalar(@joins), 2, "both sync states retained: $body");
        is_deeply($_->{done_ports}, [qw(w0_done w1_done)], 'any observes; all still drains both children') for @joins;
    }
};

done_testing();

sub simulate {
    my ($dir, $hdl, $tb) = @_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable', 3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $sv = write_file("$dir/dut.sv", $hdl);
        my $test = write_file("$dir/tb.sv", $tb);
        my $obj = "$dir/obj";
        my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '--top-module', 'tb', '--Mdir', $obj, $sv, $test]);
        ok($compile->{ok}, 'independent HDL compiler accepts parent') or diag($compile->{diagnostic}, $compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed'); fail('runtime observation absent'); }
        else {
            my $run = run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok}, 'independent completion lifetime model passes') or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
            like($run->{stdout}, qr/COMPLETION_LIFETIME_PASS/, 'all activation/reset observations completed');
        }
    }
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!"; print {$fh} $text; close $fh or die "close $path: $!"; return $path;
}
