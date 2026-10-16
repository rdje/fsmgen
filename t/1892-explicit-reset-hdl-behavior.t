#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Test::HDLBehaviorRuntime qw(ghdl_behavior_provider run_ghdl_analysis run_ghdl_behavior);

my $work = tempdir(CLEANUP => 1);
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my @cases = (
    ['sync_high', 'sreset', 'active_high', 'rst_high'],
    ['sync_low', 'sreset', 'active_low', 'rst_low'],
    ['async_high', 'areset', 'active_high', 'rst_high'],
    ['async_low', 'areset', 'active_low', 'rst_low'],
);
for my $format (qw(fsm isf)) {
    mkdir "$work/$format" or die $!;
    for my $c (@cases) {
        my $text = $format eq 'fsm'
            ? "(?fsm:$c->[0]\n"
                ."  (+system (clock clk) ($c->[1] reset_pin $c->[2]))\n"
                ."  (+size (Q 4 (reset 3)) (DATA 4))\n"
                ."  (idle (<- (Q> DATA))))\n"
            : "(actor $c->[0]\n  (clock clk)\n"
                ."  (reset (reset_pin " . ($c->[1] eq 'areset' ? 'async ' : '') . "$c->[2]))\n"
                ."  (interface (input DATA (width 4)) (output Q (width 4) (reset 3)))\n"
                ."  (rule capture 1 (set Q DATA)))\n";
        write_file("$work/$format/$c->[0].$format", $text);
    }
}

for my $format (qw(fsm isf)) {
    for my $language (qw(systemverilog verilog vhdl)) {
        subtest "$format $language independently honors reset kind and polarity" => sub {
            if ($language ne 'vhdl') {
                plan skip_all => 'Verilator runtime provider unavailable or not qualified'
                    unless can_run('verilator') && darwin_verilator_runtime_qualified();
            }
            my $ghdl;
            if ($language eq 'vhdl') {
                $ghdl = ghdl_behavior_provider('reset_behavior');
                plan skip_all => 'GHDL runtime provider unavailable' unless defined($ghdl) && -x $ghdl;
            }
            my $dir = "$work/$format/$language";
            mkdir $dir or die $!;
            my @hdl;
            for my $c (@cases) {
                my $output = "$dir/$c->[0]." . ($language eq 'vhdl' ? 'vhd' : $language eq 'verilog' ? 'v' : 'sv');
                my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--quiet', '--language', $language,
                    '--output', $output, "$work/$format/$c->[0].$format"], '');
                is($r->{exit_code}, 0, "$c->[0] generates through the real strict CLI") or diag($r->{stderr});
                return if $r->{exit_code};
                push @hdl, $output;
            }
            if ($language eq 'vhdl') {
                my $tb = "$dir/reset_tb.vhd";
                write_file($tb, read_file('t/data/explicit_reset_behavior_tb.vhd'));
                my $compile = run_ghdl_analysis('reset_behavior', $dir, [@hdl, $tb]);
                ok($compile->{ok}, 'GHDL analyzes the generated modules and independent oracle') or diag($compile->{diagnostic},substr($compile->{stderr},0,8192));
                return unless $compile->{ok};
                my $r = run_ghdl_behavior('reset_behavior', $dir);
                ok($r->{ok}, 'GHDL reset behavior passes') or diag($r->{diagnostic},substr($r->{stderr},0,8192),$r->{stdout});
                like($r->{stdout}.$r->{stderr}, qr/RESET_BEHAVIOR_PASS/, 'independent VHDL oracle reaches completion');
            } else {
                my $tb = "$dir/reset_tb.sv";
                write_file($tb, read_file('t/data/explicit_reset_behavior_tb.sv'));
                my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert',
                    '-Wno-fatal', '-j', '1', '--top-module', 'reset_tb', '--Mdir', "$dir/obj", @hdl, $tb]);
                ok($compile->{ok}, 'Verilator builds the generated modules and independent oracle') or diag($compile->{diagnostic},substr($compile->{stderr},0,8192));
                return unless $compile->{ok};
                my $r = run_generated_binary(["$dir/obj/Vreset_tb"]);
                ok($r->{ok}, 'Verilator reset behavior passes') or diag($r->{diagnostic},substr($r->{stderr},0,8192),$r->{stdout});
                like($r->{stdout}, qr/RESET_BEHAVIOR_PASS/, 'independent Verilog-family oracle reaches completion');
            }
        };
    }
}

done_testing();

# The independent fixtures include nonzero reset values and pulses entirely
# between edges, distinguishing timing as well as active level.
sub read_file {
    open my $fh, '<', $_[0] or die $!;
    my $text = do { local $/; <$fh> };
    close $fh or die $!;
    return $text;
}
sub write_file {
    open my $fh, '>', $_[0] or die $!;
    print {$fh} $_[1] or die $!;
    close $fh or die $!;
}
