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
my $c2_path = File::Spec->catfile($tempdir, 'implicit_ports_generated_top.fsm');
my $c2_out_path = File::Spec->catfile($tempdir, 'implicit_ports_generated_top.sv');
my $c3_path = File::Spec->catfile($tempdir, 'implicit_ports_rtl_top.fsm');
my $c3_out_path = File::Spec->catfile($tempdir, 'implicit_ports_rtl_top.sv');
my $renamed_path = File::Spec->catfile($tempdir, 'implicit_ports_renamed_top.fsm');

write_file(
    $c2_path,
    <<'FSM'
(?top:implicit_ports_generated_top
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /go/producer.go/
    /go/consumer.go/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (payload> <= 8'5)
    )
  )
  (+size
    (go 1)
    (payload 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (result_data> <= payload)
    )
  )
  (+size
    (go 1)
    (payload 8)
    (result_data 8)
  )
)
FSM
);

write_file(
    $c3_path,
    <<'FSM'
(?top:implicit_ports_rtl_top
  (?ports:public_io)
  (?rtl:uart_tx)
  (?toplink:wiring
    /data_in/uart_tx.data_in/
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
    $renamed_path,
    <<'FSM'
(?top:implicit_ports_renamed_top
  (?ports:public_io)
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

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'explicit-link C2 can omit ?ports entirely when the top boundary is inferable' => sub {
    my $result = $pipeline->generate_hdl_from_file($c2_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C2', 'generated-child explicit-link inference stays in C2');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{clk}, 'clk is inferred without ?ports');
    ok($ports{rstn}, 'rstn is inferred without ?ports');
    ok($ports{go}, 'shared top input is inferred without ?ports');
    ok($ports{result_data}, 'top-facing child output is inferred without ?ports');
    ok(!$ports{payload}, 'internal carrier stays internal without ?ports');

    is(scalar(@{$result->{composition_plan}->nets}), 1, 'one internal carrier net is still inferred');
    is($result->{composition_plan}->nets->[0]->name, 'payload', 'the inferred internal carrier keeps the shared name');

    my %instance_bindings;
    for my $instance (@{$result->{composition_plan}->instances}) {
        $instance_bindings{$instance->instance_name} = {
            map { $_->{port_name} => $_->{signal_name} } @{$instance->port_bindings || []}
        };
    }

    is($instance_bindings{producer}{go}, 'go', 'producer input binds from the inferred top input');
    is($instance_bindings{consumer}{go}, 'go', 'consumer input binds from the inferred top input');
    is($instance_bindings{producer}{payload}, 'payload', 'producer output binds to the inferred internal carrier');
    is($instance_bindings{consumer}{payload}, 'payload', 'consumer input binds to the inferred internal carrier');
    is($instance_bindings{consumer}{result_data}, 'result_data', 'consumer output binds to the inferred top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+go\b/s, 'generated HDL exposes the inferred top input');
    like($hdl, qr/\boutput\s+\[7:0\]\s+result_data\b/s, 'generated HDL exposes the inferred top output');
    like($hdl, qr/\bwire\s+\[7:0\]\s+payload;/s, 'generated HDL still emits the inferred internal carrier');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $c2_out_path, '--quiet', $c2_path],
    );
    ok($success, 'CLI succeeds for explicit-link C2 with omitted ?ports');
    ok(-e $c2_out_path, 'CLI writes HDL output for explicit-link C2 with omitted ?ports');
};

subtest 'explicit-link C3 can use an empty ?ports block when the top boundary is inferable' => sub {
    my $result = $pipeline->generate_hdl_from_file($c3_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'rtl-backed explicit-link inference stays in C3');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{core_clk}, 'typed RTL clock is inferred from an empty ?ports block');
    ok($ports{rst_async_n}, 'typed RTL reset is inferred from an empty ?ports block');
    ok($ports{data_in}, 'same-name top input is inferred from an empty ?ports block');
    ok($ports{txd}, 'top-facing rtl output is inferred from an empty ?ports block');

    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is($rtl_bindings{core_clk}, 'core_clk', 'typed RTL clock still auto-wires');
    is($rtl_bindings{rst_async_n}, 'rst_async_n', 'typed RTL reset still auto-wires');
    is($rtl_bindings{data_in}, 'data_in', 'same-name input binds from the inferred top input');
    is($rtl_bindings{txd}, 'txd', 'top-facing output binds to the inferred top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+\[7:0\]\s+data_in\b/s, 'generated HDL exposes the inferred rtl-backed top input');
    like($hdl, qr/\boutput\s+txd\b/s, 'generated HDL exposes the inferred rtl-backed top output');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $c3_out_path, '--quiet', $c3_path],
    );
    ok($success, 'CLI succeeds for explicit-link C3 with empty ?ports');
    ok(-e $c3_out_path, 'CLI writes HDL output for explicit-link C3 with empty ?ports');
};

subtest 'implicit explicit-link top-port inference still rejects renamed top endpoints without ?ports' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($renamed_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/references top-level endpoint 'payload_in', .*'\?ports' declares no top port with that name/s,
        'renamed top endpoints still need an explicit top-port declaration',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
