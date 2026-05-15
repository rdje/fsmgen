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
use FSM::Composition::Net;
use FSM::Composition::Plan;
use FSM::Composition::Port;

my $tempdir = tempdir(CLEANUP => 1);
my $composition_path = File::Spec->catfile($tempdir, 'fsm_plus_rtl_top.fsm');
my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
my $output_path = File::Spec->catfile($tempdir, 'fsm_plus_rtl_top.sv');

write_file(
    $composition_path,
    <<'FSM'
(?top:fsm_plus_rtl_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?wiring:wiring
    /producer.output_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'3)
  )
  (+size
    (output_data 8)
  )
)
FSM
);

write_file(
    $metadata_path,
    <<'RTLIF'
(?rtlif:uart_tx
  clk
  rstn
  data_in<8
  txd>
)
RTLIF
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

my $result = $pipeline->generate_hdl_from_file($composition_path);

isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
is($result->{composition_plan}->lane, 'C3', 'mixed FSM plus external RTL composition records the C3 lane');
is($result->{composition_plan}->top_name, 'fsm_plus_rtl_top', 'typed plan preserves the mixed top name');
is(scalar(@{$result->{composition_plan}->instances}), 2, 'typed plan realizes one FSM child and one external RTL child');
is($result->{composition_plan}->instances->[0]->kind, 'fsmc', 'first realized child remains the embedded FSM child');
is($result->{composition_plan}->instances->[1]->kind, 'rtl', 'second realized child is the external RTL child');
is($result->{composition_plan}->instances->[1]->module_name, 'uart_tx', 'external RTL realization preserves the module name');
is($result->{composition_plan}->instances->[1]->instance_name, 'uart_tx', 'first C3 lane uses the RTL module name as the instance name');
is($result->{composition_plan}->instances->[1]->module_info->{metadata_path}, $metadata_path, 'external RTL realization records the loaded metadata path');
is(scalar(@{$result->{composition_plan}->instances->[1]->interface_ports}), 4, 'external RTL realization preserves typed interface ports from metadata');
isa_ok($result->{composition_plan}->instances->[1]->interface_ports->[0], 'FSM::Composition::Port');
is($result->{composition_plan}->instances->[1]->interface_ports->[2]->name, 'data_in', 'external RTL realization preserves typed input ports');
is($result->{composition_plan}->instances->[1]->interface_ports->[3]->name, 'txd', 'external RTL realization preserves typed output ports');
is(scalar(@{$result->{composition_plan}->nets}), 1, 'mixed plan materializes one deterministic internal net');
isa_ok($result->{composition_plan}->nets->[0], 'FSM::Composition::Net');
is($result->{composition_plan}->nets->[0]->name, 'comp_link_producer_output_data', 'mixed plan reuses deterministic internal net naming');

my %producer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

is($producer_bindings{output_data}, 'comp_link_producer_output_data', 'FSM child output drives the deterministic mixed-lane net');
is($rtl_bindings{clk}, 'clk', 'external RTL child clock is auto-wired from the shared top system input');
is($rtl_bindings{rstn}, 'rstn', 'external RTL child reset is auto-wired from the shared top system input');
is($rtl_bindings{data_in}, 'comp_link_producer_output_data', 'external RTL child input is driven from the deterministic mixed-lane net');
is($rtl_bindings{txd}, 'serial_out', 'external RTL child output is wired directly to the explicit top output');

is($result->{module_info}{module_name}, 'fsm_plus_rtl_top', 'composition result reports the generated mixed top module name');
is($result->{module_info}{composition_child_count}, 2, 'composition module info reports both realized children');
is($result->{module_info}{composition_net_count}, 1, 'composition module info reports one deterministic composition net');
is($result->{statistics}{composition_child_count}, 2, 'composition statistics report both realized children');
is($result->{statistics}{composition_net_count}, 1, 'composition statistics report the deterministic composition net');
is($result->{statistics}{composition_lane}, 'C3', 'composition statistics preserve the mixed-lane label');

my $hdl = $result->{hdl_code};

like($hdl, qr/\bmodule\s+producer_src\b/s, 'generated HDL includes the realized FSM child module');
like($hdl, qr/\bmodule\s+fsm_plus_rtl_top\s*\(/s, 'generated HDL includes the generated mixed top module');
like($hdl, qr/\buart_tx\s+uart_tx\s*\(/s, 'generated top module instantiates the external RTL child');
like($hdl, qr/\.data_in\(comp_link_producer_output_data\)/s, 'generated top module wires the external RTL input from the deterministic net');
like($hdl, qr/\.txd\(serial_out\)/s, 'generated top module wires the external RTL output to the explicit top output');
unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated HDL does not try to regenerate the external RTL child internals');

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
);

ok($success, 'CLI succeeds for the first mixed FSM plus external RTL composition lane');
ok(-e $output_path, 'CLI writes HDL output for the mixed composition lane');

my $cli_hdl = slurp($output_path);
like($cli_hdl, qr/\bmodule\s+fsm_plus_rtl_top\b/s, 'CLI output includes the generated mixed top module');
like($cli_hdl, qr/\buart_tx\s+uart_tx\s*\(/s, 'CLI output includes the external RTL instance');
unlike($cli_hdl, qr/\bmodule\s+uart_tx\b/s, 'CLI output does not emit the external RTL child internals');

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
