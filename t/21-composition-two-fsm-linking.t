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
use FSM::Composition::Net;

my $tempdir = tempdir(CLEANUP => 1);
my $composition_path = File::Spec->catfile($tempdir, 'two_child_top.fsm');
my $output_path = File::Spec->catfile($tempdir, 'two_child_top.sv');

write_file(
    $composition_path,
    <<'FSM'
(?top:two_child_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
    /consumer.final_data/result_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
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
is($result->{composition_plan}->lane, 'C2', 'two-child explicit-link composition records the C2 lane');
is($result->{composition_plan}->top_name, 'two_child_top', 'typed plan preserves the top name');
is(scalar(@{$result->{composition_plan}->instances}), 2, 'typed plan realizes two child instances');
is($result->{composition_plan}->instances->[0]->instance_name, 'producer', 'top plan preserves declared producer instance order');
is($result->{composition_plan}->instances->[1]->instance_name, 'consumer', 'top plan preserves declared consumer instance order');
is(scalar(@{$result->{composition_plan}->links}), 2, 'typed plan preserves explicit toplink wiring');
is(scalar(@{$result->{composition_plan}->nets}), 1, 'typed plan materializes one deterministic internal net for child-to-child wiring');
isa_ok($result->{composition_plan}->nets->[0], 'FSM::Composition::Net');
is($result->{composition_plan}->nets->[0]->name, 'comp_link_producer_output_data', 'internal net name is deterministic from the explicit link source');
is($result->{composition_plan}->nets->[0]->width, 8, 'internal net width follows the source child port width');

my %producer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
my %consumer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

is($producer_bindings{clk}, 'clk', 'producer clock is auto-wired from the top system input');
is($producer_bindings{rstn}, 'rstn', 'producer reset is auto-wired from the top system input');
is($producer_bindings{output_data}, 'comp_link_producer_output_data', 'producer output drives the deterministic internal net');
is($consumer_bindings{clk}, 'clk', 'consumer clock is auto-wired from the top system input');
is($consumer_bindings{rstn}, 'rstn', 'consumer reset is auto-wired from the top system input');
is($consumer_bindings{input_data}, 'comp_link_producer_output_data', 'consumer input is fed from the deterministic internal net');
is($consumer_bindings{final_data}, 'result_data', 'consumer final output is wired directly to the explicit top output');

is($result->{module_info}{module_name}, 'two_child_top', 'composition result reports the generated top module name');
is($result->{module_info}{composition_child_count}, 2, 'composition module info reports two realized children');
is($result->{module_info}{composition_net_count}, 1, 'composition module info reports one internal composition net');
is($result->{statistics}{composition_child_count}, 2, 'composition statistics report two realized children');
is($result->{statistics}{composition_top_port_count}, 3, 'composition statistics report top-port count');
is($result->{statistics}{composition_net_count}, 1, 'composition statistics report internal composition nets');

my $hdl = $result->{hdl_code};

like($hdl, qr/\bmodule\s+producer_src\b/s, 'generated HDL includes the realized producer FSM module');
like($hdl, qr/\bmodule\s+consumer_src\b/s, 'generated HDL includes the realized consumer FSM module');
like($hdl, qr/\bmodule\s+two_child_top\s*\(/s, 'generated HDL includes the generated two-child top module');
like($hdl, qr/\bwire\s+\[7:0\]\s+comp_link_producer_output_data;/s, 'generated top module declares the deterministic internal link net');
like($hdl, qr/\bproducer_src\s+producer\s*\(/s, 'generated top module instantiates the producer child');
like($hdl, qr/\bconsumer_src\s+consumer\s*\(/s, 'generated top module instantiates the consumer child');
like($hdl, qr/\.output_data\(comp_link_producer_output_data\)/s, 'producer output is wired to the deterministic internal link net');
like($hdl, qr/\.input_data\(comp_link_producer_output_data\)/s, 'consumer input is wired from the deterministic internal link net');
like($hdl, qr/\.final_data\(result_data\)/s, 'consumer output is wired directly to the explicit top output');

my $producer_pos = index($hdl, 'producer_src producer');
my $consumer_pos = index($hdl, 'consumer_src consumer');
ok($producer_pos >= 0 && $consumer_pos >= 0 && $producer_pos < $consumer_pos, 'top emission preserves deterministic instance order');

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
);

ok($success, 'CLI succeeds for the active two-child explicit-link composition lane');
ok(-e $output_path, 'CLI writes HDL output for the active two-child explicit-link composition lane');

my $cli_hdl = slurp($output_path);
like($cli_hdl, qr/\bmodule\s+two_child_top\b/s, 'CLI output includes the generated two-child top module');
like($cli_hdl, qr/\bwire\s+\[7:0\]\s+comp_link_producer_output_data;/s, 'CLI output includes the deterministic internal link net');

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
