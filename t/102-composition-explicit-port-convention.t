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

subtest 'verbose top ports normalize before generated-child C1 emission' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'verbose_ports_generated_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'verbose_ports_generated_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:verbose_ports_generated_top
  (?ports:public_io
    (input payload_in (width 8))
    (output result_data (width 8))
  )
  (?dtc:router router_src)
)

(?dt:router_src
  (-route
    (result_data> = payload_in)
  )
  (+size
    (payload_in 8)
    (result_data 8)
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
    is($result->{composition_plan}->lane, 'C1', 'verbose explicit ports stay on the generated-child passthrough lane');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    is($ports{payload_in}->direction, 'input', 'verbose input reaches the composition plan as an input');
    is($ports{payload_in}->width, 8, 'verbose input reaches the composition plan with the declared width');
    is($ports{result_data}->direction, 'output', 'verbose output reaches the composition plan as an output');
    is($ports{result_data}->width, 8, 'verbose output reaches the composition plan with the declared width');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+\[7:0\]\s+payload_in\b/s, 'generated HDL exposes the verbose input');
    like($hdl, qr/\boutput\s+\[7:0\]\s+result_data\b/s, 'generated HDL exposes the verbose output');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for verbose explicit top ports');
    ok(-e $output_path, 'CLI writes HDL for verbose explicit top ports');
};

subtest 'explicit plain top ports can adopt same-name convention in generated-child C2' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'explicit_plain_ports_generated_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'explicit_plain_ports_generated_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:explicit_plain_ports_generated_top
  (?ports:public_io
    payload_in<8
    result_data>8
  )
  (?dtc:producer producer_src)
  (?dtc:consumer consumer_src)
  (?toplink:wiring
    /producer.mid/consumer.mid/
  )
)

(?dt:producer_src
  (-route
    (mid> = payload_in)
  )
  (+size
    (payload_in 8)
    (mid 8)
  )
)

(?dt:consumer_src
  (-route
    (result_data> = (+ mid payload_in))
  )
  (+size
    (payload_in 8)
    (mid 8)
    (result_data 8)
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
    is($result->{composition_plan}->lane, 'C2', 'generated-child convention-first explicit ports stay in C2');
    is(scalar(@{$result->{composition_plan}->links}), 1, 'plan still records the original explicit toplink set in C2');
    is(scalar(@{$result->{composition_plan}->nets}), 1, 'explicit child-to-child link still uses one deterministic carrier net');
    is($result->{composition_plan}->nets->[0]->name, 'comp_link_producer_mid', 'carrier net keeps the deterministic generated name');

    my %producer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %consumer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($producer_bindings{payload_in}, 'payload_in', 'plain explicit top input binds to the first same-name child input');
    is($consumer_bindings{payload_in}, 'payload_in', 'plain explicit top input also fans out to the second same-name child input');
    is($producer_bindings{mid}, 'comp_link_producer_mid', 'explicit child-to-child link still binds the producer output through the carrier net');
    is($consumer_bindings{mid}, 'comp_link_producer_mid', 'explicit child-to-child link still binds the consumer input through the carrier net');
    is($consumer_bindings{result_data}, 'result_data', 'plain explicit top output binds to the unique same-name child output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+\[7:0\]\s+payload_in\b/s, 'generated HDL exposes the plain explicit top input');
    like($hdl, qr/\boutput\s+\[7:0\]\s+result_data\b/s, 'generated HDL exposes the plain explicit top output');
    like($hdl, qr/\.payload_in\(payload_in\)/s, 'generated HDL fans the plain explicit top input out by convention');
    like($hdl, qr/\.result_data\(result_data\)/s, 'generated HDL binds the plain explicit top output by convention');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for generated-child convention-first explicit ports');
    ok(-e $output_path, 'CLI writes HDL for generated-child convention-first explicit ports');
};

subtest 'explicit plain top ports can adopt same-name convention in mixed C3' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'explicit_plain_ports_mixed_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'explicit_plain_ports_mixed_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:explicit_plain_ports_mixed_top
  (?ports:public_io
    trigger
    txd>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.serial_payload/uart_tx.data_in/
  )
)

(?dt:producer_src
  (-route
    (<trigger
      (serial_payload> = 8'1)
    )
    (<!trigger
      (serial_payload> = 8'0)
    )
  )
  (+size
    (trigger 1)
    (serial_payload 8)
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

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'mixed convention-first explicit ports stay in C3');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{core_clk}, 'typed rtl clock is still inferred');
    ok($ports{rst_async_n}, 'typed rtl reset is still inferred');
    ok($ports{trigger}, 'plain explicit top input stays present');
    ok($ports{txd}, 'plain explicit top output stays present');

    my %producer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($producer_bindings{trigger}, 'trigger', 'plain explicit top input binds to the same-name generated-child input');
    is($producer_bindings{serial_payload}, 'comp_link_producer_serial_payload', 'explicit child-to-rtl link still uses the deterministic carrier');
    is($rtl_bindings{core_clk}, 'core_clk', 'rtl clock auto-wires normally');
    is($rtl_bindings{rst_async_n}, 'rst_async_n', 'rtl reset auto-wires normally');
    is($rtl_bindings{data_in}, 'comp_link_producer_serial_payload', 'explicit child-to-rtl link still binds the rtl input');
    is($rtl_bindings{txd}, 'txd', 'plain explicit top output binds to the same-name rtl output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+trigger\b/s, 'generated HDL exposes the plain explicit trigger input');
    like($hdl, qr/\boutput\s+txd\b/s, 'generated HDL exposes the plain explicit txd output');
    like($hdl, qr/\.trigger\(trigger\)/s, 'generated HDL binds the generated-child input by convention');
    like($hdl, qr/\.txd\(txd\)/s, 'generated HDL binds the rtl output by convention');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for mixed convention-first explicit ports');
    ok(-e $output_path, 'CLI writes HDL for mixed convention-first explicit ports');
};

subtest 'plain explicit top inputs reject mixed-direction same-name families' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'plain_input_mixed_direction_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:plain_input_mixed_direction_top
  (?ports:public_io
    foo<8
  )
  (?dtc:producer producer_src)
  (?dtc:consumer consumer_src)
  (?toplink:wiring
    /producer.bridge/consumer.bridge/
  )
)

(?dt:producer_src
  (-route
    (foo> = 8'3)
    (bridge> = 8'1)
  )
  (+size
    (foo 8)
    (bridge 8)
  )
)

(?dt:consumer_src
  (-route
    (sink> = (+ foo bridge))
  )
  (+size
    (foo 8)
    (bridge 8)
    (sink 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares top input 'foo'.*same-name child endpoints include incompatible directions/s,
        'plain explicit top-input convention rejects mixed-direction same-name families',
    );
    like(
        $exception,
        qr/producer\.foo\[output, width=8\], consumer\.foo\[input, width=8\]/s,
        'mixed-direction diagnostics list the conflicting same-name endpoints',
    );
};

subtest 'plain explicit top outputs reject ambiguous same-name top-facing producers' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'plain_output_ambiguous_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:plain_output_ambiguous_top
  (?ports:public_io
    go
    shared_status>8
  )
  (?dtc:left left_src)
  (?dtc:right right_src)
  (?toplink:wiring
    /go/left.go/
    /go/right.go/
  )
)

(?dt:left_src
  (-route
    (<go
      (shared_status> = 8'1)
    )
  )
  (+size
    (go 1)
    (shared_status 8)
  )
)

(?dt:right_src
  (-route
    (<go
      (shared_status> = 8'2)
    )
  )
  (+size
    (go 1)
    (shared_status 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares top output 'shared_status'.*several same-name child outputs remain top-facing/s,
        'plain explicit top-output convention rejects several same-name top-facing producers',
    );
    like(
        $exception,
        qr/left\.shared_status\[output, width=8\], right\.shared_status\[output, width=8\]/s,
        'ambiguous-output diagnostics list the competing same-name child outputs',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
