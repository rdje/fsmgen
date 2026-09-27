#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Storable qw(dclone);
use IPC::Cmd qw(can_run);
use JSON::PP;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::ChildStorageOwnership qw(connect_child_storage_reads);
use FSM::Pipeline::HDLGenerator;

my $work = tempdir(CLEANUP => 1);
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die $!;
    print {$fh} $text; close $fh or die $!;
    return $path;
}
subtest 'allocation reserves both block namespaces without changing shared views' => sub {
    for my $field (qw(states dt_blocks)) {
        for my $name (qw(isf_storage_read_value_reg ISF_STORAGE_READ_VALUE_REG ordinary_block)) {
            my $parent = { ports => [], states => [], dt_blocks => [],
                spawn_instances => [{instance => 'a', child => 'worker'}, {instance => 'b', child => 'worker'}] };
            my $block = { name => $name, assignments => [{lhs => 'flag', rhs => 1, op => '<-'}] };
            push @{$parent->{$field}}, $block;
            my $before = dclone($block);
            my $children = {worker => {actor_storage_reads => [{name => 'value_reg', width => 4, type => 'value_t'}]}};
            my $children_before = dclone($children);
            is(connect_child_storage_reads($parent, $children), 1, 'one live owner view for both readers');
            is_deeply($block, $before, "$field authored block unchanged");
            is_deeply($children, $children_before, 'child contracts unchanged');
            my $port = $parent->{ports}[0];
            if ($name eq 'ordinary_block') {
                is($port->{name}, 'isf_storage_read_value_reg', 'ordinary allocation stays stable');
            } else {
                isnt(lc($port->{name}), lc($name), "$field portable block collision avoided");
            }
            is_deeply($port, {name => $port->{name}, direction => 'output', width => 4, isf_handoff => 1}, 'exact live view port');
            is($parent->{signal_type_refs}{$port->{name}}, 'value_t', 'type alias retained');
            for my $spawn (@{$parent->{spawn_instances}}) {
                is_deeply($spawn->{actor_storage_reads}, [{parent_port => $port->{name}, child_port => 'value_reg'}], 'explicit shared consumer link');
            }
            my @handoffs = grep {($_->{kind}//'') eq 'actor_storage_read_handoff'} @{$parent->{dt_blocks}};
            is_deeply(\@handoffs, [{name => $port->{name}, kind => 'actor_storage_read_handoff', assignments => [
                {lhs => $port->{name}, rhs => 'value_reg', op => '=', source_kind => 'actor_storage_read_handoff'}]}], 'read remains a combinational view');
        }
    }
};

subtest 'public authored rule guard survives lowering and independent execution' => sub {
    my $source = <<'ISF';
(actor read_block_collision (clock clk) (reset rst_n)
 (interface (input fire) (output done) (output observed (width 4)) (output flag))
 (storage (var value_reg (width 4) (reset 3)))
 (rule isf_storage_read_value_reg fire (flag 1))
 (transaction worker (ports (output data (width 4))) (set data value_reg) (complete done))
 (transaction main (on fire)
  (spawn worker as job (bind (output data observed))) (await_all done) (complete done)))
ISF
    my $path = write_file("$work/collision.isf", $source);
    my $actor = FSM::Adapter::ISF->new->parse_source($source, $path);
    my $ir = FSM::Scheduler::ISF->new->{ir}->build_module($actor);
    my @rules = grep {$_->{name} eq 'isf_storage_read_value_reg'} @{$ir->{dt_blocks}};
    is(scalar @rules, 1, 'authored rule identity is unique');
    my ($read) = grep {($_->{kind}//'') eq 'actor_storage_read_handoff'} @{$ir->{dt_blocks}};
    isnt($read->{name}, $rules[0]{name}, 'generated handoff has a distinct identity');
    for my $flags (['--strict','--check','--json'], ['--emit-schedule-json']) {
        my $r = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', @$flags, $path], '');
        is($r->{exit_code}, 0, "public @$flags succeeds") or diag($r->{stdout}, $r->{stderr});
        my $report = eval {JSON::PP->new->decode($r->{stdout})};
        ok(ref($report) eq 'HASH', 'public structured report remains available') or diag($@);
    }
    SKIP: {
        skip 'qualified Verilator runtime unavailable', 3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($path)->{hdl_code};
        my $sv = write_file("$work/dut.sv", $hdl);
        my $tb = write_file("$work/tb.sv", <<'SV');
module tb;
 logic clk=0, rst_n=0, fire=0;
 wire done, flag;
 wire [3:0] observed;
 always #5 clk=~clk;
 read_block_collision_top dut(.*);
 initial begin
  repeat(2) @(negedge clk); rst_n=1;
  repeat(3) begin
   @(negedge clk);
   if(flag!==0) $fatal(1,"READ_HANDOFF_LOST_RULE_GUARD fire=0 flag=%b",flag);
  end
  fire=1; @(negedge clk); fire=0;
  if(flag!==1) $fatal(1,"authored rule did not fire");
  repeat(12) @(negedge clk);
  if(observed!==4'd3) $fatal(1,"live owner read missing observed=%d",observed);
  rst_n=0; @(negedge clk); rst_n=1;
  repeat(3) @(negedge clk);
  if(flag!==0) $fatal(1,"rule guard lost after reset");
  $display("READ_HANDOFF_BLOCK_COLLISION_PASS"); $finish;
 end
 initial begin #1000; $fatal(1,"timeout"); end
endmodule
SV
        my $compile = run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal',
            '--top-module','tb','--Mdir',"$work/obj",$sv,$tb]);
        ok($compile->{ok}, 'independent HDL compilation succeeds') or diag($compile->{diagnostic},$compile->{stderr});
        if (!$compile->{ok}) {fail('runtime compilation failed');fail('runtime observation absent')}
        else {
            my $run = run_generated_binary(["$work/obj/Vtb"]);
            ok($run->{ok}, 'guard, live read and reset behavior pass') or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
            like($run->{stdout}, qr/READ_HANDOFF_BLOCK_COLLISION_PASS/, 'independent oracle completed');
        }
    }
};
done_testing;
