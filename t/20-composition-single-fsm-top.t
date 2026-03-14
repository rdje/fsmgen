#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Composition::Plan;
use FSM::Composition::Port;

my $tempdir = tempdir(CLEANUP => 1);
my $composition_path = File::Spec->catfile($tempdir, 'single_child_top.fsm');
my $output_path = File::Spec->catfile($tempdir, 'single_child_top.sv');

write_file(
    $composition_path,
    <<'FSM'
(?top:single_child_top
  (?ports:public_io
    clk
    rstn
    output_data>8
  )
  (?fsmc:child_ctrl child_ctrl_src)
)

(?fsm:child_ctrl_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

my $result = $pipeline->generate_hdl_from_file($composition_path);

isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
is($result->{source_info}{kind}, 'composition', 'pipeline preserves composition source classification');
is($result->{composition_plan}->lane, 'C1', 'first active composition generation lane is recorded in the typed plan');
is($result->{composition_plan}->top_name, 'single_child_top', 'typed plan preserves top module name');
is(scalar(@{$result->{composition_plan}->ports}), 3, 'typed plan preserves explicit top ports');
is(scalar(@{$result->{composition_plan}->instances}), 1, 'typed plan realizes one child instance');
is($result->{composition_plan}->instances->[0]->module_name, 'child_ctrl_src', 'child realization preserves child module name');
is($result->{composition_plan}->instances->[0]->instance_name, 'child_ctrl', 'child realization preserves declared instance name');
is(scalar(@{$result->{composition_plan}->instances->[0]->interface_ports}), 3, 'realized child interface is captured as typed ports for C1 planning');
isa_ok($result->{composition_plan}->instances->[0]->interface_ports->[0], 'FSM::Composition::Port');
is($result->{composition_plan}->instances->[0]->interface_ports->[0]->name, 'clk', 'realized child interface includes implicit clock port');
is($result->{composition_plan}->instances->[0]->interface_ports->[1]->name, 'rstn', 'realized child interface includes implicit reset port');
is($result->{composition_plan}->instances->[0]->interface_ports->[2]->name, 'output_data', 'realized child interface includes analyzed user port');
is($result->{module_info}{module_name}, 'single_child_top', 'composition result reports the generated top module name');
is($result->{module_info}{composition_child_count}, 1, 'composition module info reports one realized child');
is($result->{module_info}{signal_count}, 3, 'composition module info reports explicit top ports as signals');
is($result->{statistics}{composition_child_count}, 1, 'composition statistics report one realized child');
is($result->{statistics}{composition_top_port_count}, 3, 'composition statistics report explicit top-port count');

my $hdl = $result->{hdl_code};

like($hdl, qr/\bmodule\s+child_ctrl_src\b/s, 'generated HDL includes the realized child FSM module');
like($hdl, qr/\bmodule\s+single_child_top\s*\(/s, 'generated HDL includes the generated top module');
like($hdl, qr/\binput\s+clk\b/s, 'generated top module declares clk as an input');
like($hdl, qr/\binput\s+rstn\b/s, 'generated top module declares rstn as an input');
like($hdl, qr/\boutput\s+\[7:0\]\s+output_data\b/s, 'generated top module declares output_data with explicit width');
like($hdl, qr/\bchild_ctrl_src\s+child_ctrl\s*\(/s, 'generated top module instantiates the realized child module');
like($hdl, qr/\.clk\(clk\)/s, 'generated top module wires clk deterministically by name');
like($hdl, qr/\.rstn\(rstn\)/s, 'generated top module wires rstn deterministically by name');
like($hdl, qr/\.output_data\(output_data\)/s, 'generated top module wires output_data deterministically by name');

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
);

ok($success, 'CLI succeeds for the first active single-child composition lane');
ok(-e $output_path, 'CLI writes HDL output for the first active single-child composition lane');

my $cli_hdl = slurp($output_path);
like($cli_hdl, qr/\bmodule\s+single_child_top\b/s, 'CLI output includes the generated top module');
like($cli_hdl, qr/\bchild_ctrl_src\s+child_ctrl\b/s, 'CLI output includes the realized child instance');

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path: $!";
    local $/ = undef;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}
