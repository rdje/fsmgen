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
my $mixed_role_path = File::Spec->catfile($tempdir, 'implicit_ports_mixed_role_top.fsm');
my $width_mismatch_path = File::Spec->catfile($tempdir, 'implicit_ports_width_mismatch_top.fsm');
my $type_mismatch_path = File::Spec->catfile($tempdir, 'implicit_ports_type_mismatch_top.fsm');

write_file(
    $c2_path,
    <<'FSM'
(?top:implicit_ports_generated_top
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /start/producer.go/
    /start/consumer.go/
    /producer.payload/consumer.payload/
    /consumer.result_data/status/
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
    /payload_in/uart_tx.data_in/
    /uart_tx.txd/serial_out/
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
    $mixed_role_path,
    <<'FSM'
(?top:implicit_ports_mixed_role_top
  (?ports:public_io)
  (?rtl:uart_tx)
  (?toplink:wiring
    /shared/uart_tx.data_in/
    /uart_tx.txd/shared/
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
    $width_mismatch_path,
    <<'FSM'
(?top:implicit_ports_width_mismatch_top
  (?ports:public_io)
  (?rtl:typed_width_iface)
  (?toplink:wiring
    /shared/typed_width_iface.data_in/
    /shared/typed_width_iface.short_in/
  )
)

(?rtlif:typed_width_iface
  data_in<8:data
  short_in<4:data
)
FSM
);

write_file(
    $type_mismatch_path,
    <<'FSM'
(?top:implicit_ports_type_mismatch_top
  (?ports:public_io)
  (?rtl:typed_type_iface)
  (?toplink:wiring
    /shared/typed_type_iface.data_in/
    /shared/typed_type_iface.reset_like/
  )
)

(?rtlif:typed_type_iface
  data_in<1:data
  reset_like<1:reset
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
    ok($ports{start}, 'renamed top input is inferred from explicit top links without ?ports');
    ok($ports{status}, 'renamed top output is inferred from explicit top links without ?ports');
    ok(!$ports{go}, 'child-local input name is not surfaced when the explicit top link renames it');
    ok(!$ports{result_data}, 'child-local output name is not surfaced when the explicit top link renames it');
    ok(!$ports{payload}, 'explicit child-to-child carrier stays internal without ?ports');

    is(scalar(@{$result->{composition_plan}->nets}), 1, 'one internal carrier net is still inferred');
    is($result->{composition_plan}->nets->[0]->name, 'comp_link_producer_payload', 'explicit child-to-child carrier still uses the deterministic generated net');

    my %instance_bindings;
    for my $instance (@{$result->{composition_plan}->instances}) {
        $instance_bindings{$instance->instance_name} = {
            map { $_->{port_name} => $_->{signal_name} } @{$instance->port_bindings || []}
        };
    }

    is($instance_bindings{producer}{go}, 'start', 'producer input binds from the renamed inferred top input');
    is($instance_bindings{consumer}{go}, 'start', 'consumer input binds from the renamed inferred top input');
    is($instance_bindings{producer}{payload}, 'comp_link_producer_payload', 'producer output binds to the explicit child-to-child carrier');
    is($instance_bindings{consumer}{payload}, 'comp_link_producer_payload', 'consumer input binds to the explicit child-to-child carrier');
    is($instance_bindings{consumer}{result_data}, 'status', 'consumer output binds to the renamed inferred top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+start\b/s, 'generated HDL exposes the renamed inferred top input');
    like($hdl, qr/\boutput\s+\[7:0\]\s+status\b/s, 'generated HDL exposes the renamed inferred top output');
    like($hdl, qr/\bwire\s+\[7:0\]\s+comp_link_producer_payload;/s, 'generated HDL still emits the explicit child-to-child carrier');

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
    ok($ports{payload_in}, 'renamed top input is inferred from explicit top links');
    ok($ports{serial_out}, 'renamed top output is inferred from explicit top links');
    ok(!$ports{data_in}, 'child-local rtl input name is not surfaced when the explicit top link renames it');
    ok(!$ports{txd}, 'child-local rtl output name is not surfaced when the explicit top link renames it');

    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is($rtl_bindings{core_clk}, 'core_clk', 'typed RTL clock still auto-wires');
    is($rtl_bindings{rst_async_n}, 'rst_async_n', 'typed RTL reset still auto-wires');
    is($rtl_bindings{data_in}, 'payload_in', 'renamed rtl input binds from the inferred top input');
    is($rtl_bindings{txd}, 'serial_out', 'renamed rtl output binds to the inferred top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+\[7:0\]\s+payload_in\b/s, 'generated HDL exposes the renamed rtl-backed top input');
    like($hdl, qr/\boutput\s+serial_out\b/s, 'generated HDL exposes the renamed rtl-backed top output');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $c3_out_path, '--quiet', $c3_path],
    );
    ok($success, 'CLI succeeds for explicit-link C3 with empty ?ports');
    ok(-e $c3_out_path, 'CLI writes HDL output for explicit-link C3 with empty ?ports');
};

subtest 'explicit top-link port inference rejects one undeclared top endpoint used as both input and output' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($mixed_role_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits top port 'shared', .*explicit top-link port inference is blocked because that same top endpoint is used as both an input and an output across explicit links/s,
        'mixed-role undeclared top endpoints now say explicit top-link inference is blocked',
    );
};

subtest 'explicit top-link port inference says width disagreement blocks undeclared top-port inference' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($width_mismatch_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits top port 'shared', .*explicit top-link port inference is blocked because the linked child endpoints disagree on width \(8 vs 4\).*typed_width_iface\.data_in.*typed_width_iface\.short_in/s,
        'width-mismatched undeclared top endpoints now say explicit top-link inference is blocked',
    );
};

subtest 'explicit top-link port inference says type disagreement blocks undeclared top-port inference' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($type_mismatch_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits top port 'shared', .*explicit top-link port inference is blocked because the linked child endpoints disagree on interface type \('data' vs 'reset'\).*typed_type_iface\.data_in.*typed_type_iface\.reset_like/s,
        'type-mismatched undeclared top endpoints now say explicit top-link inference is blocked',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
