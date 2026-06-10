#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Pipeline::HDLGenerator;
use FSM::Composition::Plan;
use FSM::Test::CompositionNets qw(assert_only_carrier_and_shared_dp_sink_nets);

my $tempdir = tempdir(CLEANUP => 1);
my $c2_path = File::Spec->catfile($tempdir, 'implicit_ports_generated_top.fsm');
my $c2_out_path = File::Spec->catfile($tempdir, 'implicit_ports_generated_top.sv');
my $c3_path = File::Spec->catfile($tempdir, 'implicit_ports_rtl_top.fsm');
my $c3_out_path = File::Spec->catfile($tempdir, 'implicit_ports_rtl_top.sv');
my $expr_c3_path = File::Spec->catfile($tempdir, 'implicit_ports_top_expr_rtl_top.fsm');
my $expr_c3_out_path = File::Spec->catfile($tempdir, 'implicit_ports_top_expr_rtl_top.sv');
my $concat_infer_c3_path = File::Spec->catfile($tempdir, 'implicit_ports_top_concat_operand_infer_rtl_top.fsm');
my $concat_infer_c3_out_path = File::Spec->catfile($tempdir, 'implicit_ports_top_concat_operand_infer_rtl_top.sv');
my $nested_concat_infer_c3_path = File::Spec->catfile($tempdir, 'implicit_ports_nested_top_concat_operand_infer_rtl_top.fsm');
my $nested_concat_infer_c3_out_path = File::Spec->catfile($tempdir, 'implicit_ports_nested_top_concat_operand_infer_rtl_top.sv');
my $repeat_concat_infer_c3_path = File::Spec->catfile($tempdir, 'implicit_ports_repeat_top_concat_operand_infer_rtl_top.fsm');
my $repeat_concat_infer_c3_out_path = File::Spec->catfile($tempdir, 'implicit_ports_repeat_top_concat_operand_infer_rtl_top.sv');
my $mixed_role_path = File::Spec->catfile($tempdir, 'implicit_ports_mixed_role_top.fsm');
my $width_mismatch_path = File::Spec->catfile($tempdir, 'implicit_ports_width_mismatch_top.fsm');
my $type_mismatch_path = File::Spec->catfile($tempdir, 'implicit_ports_type_mismatch_top.fsm');

write_file(
    $c2_path,
    <<'FSM'
(?top:implicit_ports_generated_top
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?wiring:wiring
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
  (?wiring:wiring
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
  (?wiring:wiring
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
    $expr_c3_path,
    <<'FSM'
(?top:implicit_ports_top_expr_rtl_top
  (?rtl:byte_sink)
  (?wiring:wiring
    /payload_bus[15:8]/byte_sink.data_in/
    /status_bus[0]/byte_sink.enable/
  )
)

(?rtlif:byte_sink
  data_in<8:data
  enable<1:data
)
FSM
);

write_file(
    $concat_infer_c3_path,
    <<'FSM'
(?top:implicit_ports_top_concat_operand_infer_rtl_top
  (?rtl:byte_sink)
  (?wiring:wiring
    /header_bus,status_bus[0],payload_bus[3:0]/byte_sink.data_in/
  )
)

(?rtlif:byte_sink
  data_in<8:data
)
FSM
);

write_file(
    $nested_concat_infer_c3_path,
    <<'FSM'
(?top:implicit_ports_nested_top_concat_operand_infer_rtl_top
  (?rtl:byte_sink)
  (?wiring:wiring
    /{header_bus,{status_bus[0],payload_bus[3:0]}}/byte_sink.data_in/
  )
)

(?rtlif:byte_sink
  data_in<8:data
)
FSM
);

write_file(
    $repeat_concat_infer_c3_path,
    <<'FSM'
(?top:implicit_ports_repeat_top_concat_operand_infer_rtl_top
  (?rtl:byte_sink)
  (?wiring:wiring
    /{2{payload_bus}}/byte_sink.data_in/
  )
)

(?rtlif:byte_sink
  data_in<8:data
)
FSM
);

write_file(
    $width_mismatch_path,
    <<'FSM'
(?top:implicit_ports_width_mismatch_top
  (?ports:public_io)
  (?rtl:typed_width_iface)
  (?wiring:wiring
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
  (?wiring:wiring
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

    assert_only_carrier_and_shared_dp_sink_nets(
        $result->{composition_plan}->nets,
        ['comp_link_producer_payload'],
        'explicit-link C2 without explicit ports',
    );

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

subtest 'explicit-link C3 can infer undeclared top inputs from source-side top expressions' => sub {
    my $result = $pipeline->generate_hdl_from_file($expr_c3_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'rtl-backed top-expression inference stays in C3');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{payload_bus}, 'base top input is inferred from source-side slice evidence');
    ok($ports{status_bus}, 'base top input is inferred from source-side bit-select evidence');
    is($ports{payload_bus}->width, 16, 'slice evidence infers the minimum declared top-input width');
    is($ports{status_bus}->width, 1, 'bit-select evidence infers the minimum declared top-input width');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+\[15:0\]\s+payload_bus\b/s, 'generated HDL exposes the inferred base top input width');
    like($hdl, qr/\binput\s+status_bus\b/s, 'generated HDL exposes the inferred 1-bit top input');
    like($hdl, qr/\.data_in\(payload_bus\[15:8\]\)/s, 'generated HDL keeps the inferred slice binding');
    like($hdl, qr/\.enable\(status_bus\[0\]\)/s, 'generated HDL keeps the inferred bit-select binding');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $expr_c3_out_path, '--quiet', $expr_c3_path],
    );
    ok($success, 'CLI succeeds for explicit-link C3 with inferred top-expression ports');
    ok(-e $expr_c3_out_path, 'CLI writes HDL output for explicit-link C3 with inferred top-expression ports');
};

subtest 'explicit-link C3 can infer one undeclared whole-port concat operand from target width' => sub {
    my $result = $pipeline->generate_hdl_from_file($concat_infer_c3_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'rtl-backed concat operand inference stays in C3');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{header_bus}, 'whole-port concat operand is inferred from target width');
    ok($ports{status_bus}, 'bit-select operand still contributes inferred top input');
    ok($ports{payload_bus}, 'slice operand still contributes inferred top input');
    is($ports{header_bus}->width, 3, 'whole-port concat operand picks up the residual target width');
    is($ports{status_bus}->width, 1, 'bit-select operand keeps its minimum inferred width');
    is($ports{payload_bus}->width, 4, 'slice operand keeps its minimum inferred width');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+\[2:0\]\s+header_bus\b/s, 'generated HDL exposes the residual-width inferred top input');
    like($hdl, qr/\binput\s+status_bus\b/s, 'generated HDL exposes the inferred 1-bit concat operand');
    like($hdl, qr/\binput\s+\[3:0\]\s+payload_bus\b/s, 'generated HDL exposes the inferred slice-base top input');
    like($hdl, qr/\.data_in\(\{header_bus,\s*status_bus\[0\],\s*payload_bus\[3:0\]\}\)/s, 'generated HDL keeps the concat binding with the inferred whole-port operand');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $concat_infer_c3_out_path, '--quiet', $concat_infer_c3_path],
    );
    ok($success, 'CLI succeeds for explicit-link C3 with inferred whole-port concat operands');
    ok(-e $concat_infer_c3_out_path, 'CLI writes HDL output for explicit-link C3 with inferred whole-port concat operands');
};

subtest 'explicit-link C3 can infer one undeclared whole-port operand through nested concat groups' => sub {
    my $result = $pipeline->generate_hdl_from_file($nested_concat_infer_c3_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'rtl-backed nested concat operand inference stays in C3');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{header_bus}, 'nested whole-port concat operand is inferred from target width');
    ok($ports{status_bus}, 'nested bit-select operand still contributes inferred top input');
    ok($ports{payload_bus}, 'nested slice operand still contributes inferred top input');
    is($ports{header_bus}->width, 3, 'nested whole-port concat operand picks up the residual target width');
    is($ports{status_bus}->width, 1, 'nested bit-select operand keeps its minimum inferred width');
    is($ports{payload_bus}->width, 4, 'nested slice operand keeps its minimum inferred width');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+\[2:0\]\s+header_bus\b/s, 'generated HDL exposes the residual-width inferred nested top input');
    like($hdl, qr/\binput\s+status_bus\b/s, 'generated HDL exposes the nested inferred 1-bit concat operand');
    like($hdl, qr/\binput\s+\[3:0\]\s+payload_bus\b/s, 'generated HDL exposes the nested inferred slice-base top input');
    like($hdl, qr/\.data_in\(\{\s*header_bus,\s*\{status_bus\[0\],\s*payload_bus\[3:0\]\}\s*\}\)/s, 'generated HDL keeps the nested concat binding with the inferred whole-port operand');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $nested_concat_infer_c3_out_path, '--quiet', $nested_concat_infer_c3_path],
    );
    ok($success, 'CLI succeeds for explicit-link C3 with inferred nested whole-port concat operands');
    ok(-e $nested_concat_infer_c3_out_path, 'CLI writes HDL output for explicit-link C3 with inferred nested whole-port concat operands');
};

subtest 'explicit-link C3 can infer one undeclared repeated whole-port operand from target width' => sub {
    my $result = $pipeline->generate_hdl_from_file($repeat_concat_infer_c3_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'rtl-backed repeat operand inference stays in C3');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{payload_bus}, 'repeated whole-port operand is inferred from target width');
    is($ports{payload_bus}->width, 4, 'repeated whole-port operand picks up the exact per-copy width');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+\[3:0\]\s+payload_bus\b/s, 'generated HDL exposes the repeated inferred whole-port top input');
    like($hdl, qr/\.data_in\(\{2\{payload_bus\}\}\)/s, 'generated HDL keeps the repeated concat binding with the inferred whole-port operand');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $repeat_concat_infer_c3_out_path, '--quiet', $repeat_concat_infer_c3_path],
    );
    ok($success, 'CLI succeeds for explicit-link C3 with inferred repeated whole-port concat operands');
    ok(-e $repeat_concat_infer_c3_out_path, 'CLI writes HDL output for explicit-link C3 with inferred repeated whole-port concat operands');
};

subtest 'explicit wiring port inference rejects one undeclared top endpoint used as both input and output' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($mixed_role_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits top port 'shared', .*explicit wiring port inference is blocked because that same top endpoint is used as both an input and an output across explicit links/s,
        'mixed-role undeclared top endpoints now say explicit wiring inference is blocked',
    );
};

subtest 'explicit wiring port inference says width disagreement blocks undeclared top-port inference' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($width_mismatch_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits top port 'shared', .*explicit wiring port inference is blocked because the linked child endpoints disagree on width \(8 vs 4\).*typed_width_iface\.data_in.*typed_width_iface\.short_in/s,
        'width-mismatched undeclared top endpoints now say explicit wiring inference is blocked',
    );
};

subtest 'explicit wiring port inference says type disagreement blocks undeclared top-port inference' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($type_mismatch_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits top port 'shared', .*explicit wiring port inference is blocked because the linked child endpoints disagree on interface type \('data' vs 'reset'\).*typed_type_iface\.data_in.*typed_type_iface\.reset_like/s,
        'type-mismatched undeclared top endpoints now say explicit wiring inference is blocked',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
