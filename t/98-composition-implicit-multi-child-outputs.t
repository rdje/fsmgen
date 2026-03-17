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

my $tempdir = tempdir(CLEANUP => 1);
my $c2_path = File::Spec->catfile($tempdir, 'implicit_multi_child_outputs_top.fsm');
my $c2_out_path = File::Spec->catfile($tempdir, 'implicit_multi_child_outputs_top.sv');
my $c3_path = File::Spec->catfile($tempdir, 'implicit_single_rtl_output_top.fsm');
my $c3_out_path = File::Spec->catfile($tempdir, 'implicit_single_rtl_output_top.sv');
my $ambiguous_path = File::Spec->catfile($tempdir, 'ambiguous_implicit_outputs_top.fsm');

write_file(
    $c2_path,
    <<'FSM'
(?top:implicit_multi_child_outputs_top
  (?ports:public_io
    shared_in
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /shared_in/producer.shared_in/
    /producer.output_data/consumer.input_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<shared_in
      (output_data> <= 8'5)
    )
  )
  (+size
    (shared_in 1)
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

write_file(
    $c3_path,
    <<'FSM'
(?top:implicit_single_rtl_output_top
  (?ports:public_io
    payload_in<8
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /payload_in/uart_tx.data_in/
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  txd>:data
)
FSM
);

write_file(
    $ambiguous_path,
    <<'FSM'
(?top:ambiguous_implicit_outputs_top
  (?ports:public_io
    go
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?toplink:wiring
    /go/left.go/
    /go/right.go/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (status_out> <= 1)
    )
  )
  (+size
    (go 1)
    (status_out 1)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (status_out> <= 0)
    )
  )
  (+size
    (go 1)
    (status_out 1)
  )
)
FSM
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'explicit-link C2 infers undeclared unique top outputs that remain top-facing' => sub {
    my $result = $pipeline->generate_hdl_from_file($c2_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C2', 'generated-child unique-output inference stays in C2');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{clk}, 'clk is inferred as a top input');
    ok($ports{rstn}, 'rstn is inferred as a top input');
    ok($ports{shared_in}, 'explicit top input remains present');
    ok($ports{final_data}, 'unique top-facing child output is inferred as a top output');
    ok(!$ports{output_data}, 'child output already consumed by explicit child-to-child wiring is not inferred as a top output');
    is($ports{final_data}->direction, 'output', 'inferred top-facing output keeps output direction');
    is($ports{final_data}->width, 8, 'inferred top-facing output keeps width');

    my %instance_bindings;
    for my $instance (@{$result->{composition_plan}->instances}) {
        $instance_bindings{$instance->instance_name} = {
            map { $_->{port_name} => $_->{signal_name} } @{$instance->port_bindings || []}
        };
    }

    is($instance_bindings{producer}{shared_in}, 'shared_in', 'explicit top input still binds directly');
    is($instance_bindings{producer}{output_data}, 'comp_link_producer_output_data', 'producer output still feeds the explicit child-to-child carrier');
    is($instance_bindings{consumer}{input_data}, 'comp_link_producer_output_data', 'consumer input still binds from the explicit child-to-child carrier');
    is($instance_bindings{consumer}{final_data}, 'final_data', 'unique top-facing child output binds directly to the inferred top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\boutput\s+\[7:0\]\s+final_data\b/s, 'generated HDL exposes the inferred top output');
    like($hdl, qr/\.final_data\(final_data\)/s, 'generated HDL binds the consumer output to the inferred top output');
    unlike($hdl, qr/\boutput\s+\[7:0\]\s+output_data\b/s, 'generated HDL does not re-export the child output that is already consumed internally');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $c2_out_path, '--quiet', $c2_path],
    );
    ok($success, 'CLI succeeds for explicit-link C2 with inferred undeclared unique top outputs');
    ok(-e $c2_out_path, 'CLI writes HDL output for explicit-link C2 with inferred unique top outputs');
};

subtest 'explicit-link C3 infers undeclared unique rtl-backed top outputs that remain top-facing' => sub {
    my $result = $pipeline->generate_hdl_from_file($c3_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'single rtl explicit-link unique-output inference stays in C3');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{core_clk}, 'typed RTL clock is inferred as a top input');
    ok($ports{rst_async_n}, 'typed RTL reset is inferred as a top input');
    ok($ports{payload_in}, 'explicit renamed top input remains present');
    ok($ports{txd}, 'unique top-facing rtl output is inferred as a top output');
    is($ports{txd}->direction, 'output', 'inferred rtl-backed top output keeps output direction');
    is($ports{txd}->width, 1, 'inferred rtl-backed top output keeps width');

    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is($rtl_bindings{core_clk}, 'core_clk', 'typed RTL clock still auto-wires');
    is($rtl_bindings{rst_async_n}, 'rst_async_n', 'typed RTL reset still auto-wires');
    is($rtl_bindings{data_in}, 'payload_in', 'explicit renamed top input still binds deterministically');
    is($rtl_bindings{txd}, 'txd', 'unique top-facing rtl output binds directly to the inferred top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\boutput\s+txd\b/s, 'generated HDL exposes the inferred rtl-backed top output');
    like($hdl, qr/\.txd\(txd\)/s, 'generated HDL binds the rtl output to the inferred top output');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $c3_out_path, '--quiet', $c3_path],
    );
    ok($success, 'CLI succeeds for explicit-link C3 with inferred undeclared unique top outputs');
    ok(-e $c3_out_path, 'CLI writes HDL output for explicit-link C3 with inferred unique top outputs');
};

subtest 'undeclared top-output inference rejects several same-name top-facing child outputs' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($ambiguous_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits top port 'status_out', .*undeclared top-output inference cannot choose one top-facing child output because several same-name child outputs remain unconsumed by explicit links.*left\.status_out\[output, width=1\].*right\.status_out\[output, width=1\]/s,
        'undeclared top-output inference rejects several same-name top-facing child outputs',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
