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
my $c2_path = File::Spec->catfile($tempdir, 'reexport_internal_carrier_top.fsm');
my $c2_out_path = File::Spec->catfile($tempdir, 'reexport_internal_carrier_top.sv');
my $c3_path = File::Spec->catfile($tempdir, 'reexport_mixed_internal_carrier_top.fsm');
my $c3_out_path = File::Spec->catfile($tempdir, 'reexport_mixed_internal_carrier_top.sv');
my $ambiguous_path = File::Spec->catfile($tempdir, 'ambiguous_reexport_internal_carrier_top.fsm');
my $width_mismatch_path = File::Spec->catfile($tempdir, 'width_mismatch_reexport_internal_carrier_top.fsm');
my $type_mismatch_path = File::Spec->catfile($tempdir, 'type_mismatch_reexport_internal_carrier_top.fsm');

write_file(
    $c2_path,
    <<'FSM'
(?top:reexport_internal_carrier_top
  (?ports:public_io
    go
    payload>8
    result_a>8
    result_b>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer_a consumer_a_src)
  (?fsmc:consumer_b consumer_b_src)
  (?wiring:wiring
    /go/producer.go/
    /go/consumer_a.go/
    /go/consumer_b.go/
    /consumer_a.result_a/result_a/
    /consumer_b.result_b/result_b/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (payload> <= 8'9)
    )
  )
  (+size
    (go 1)
    (payload 8)
  )
)

(?fsm:consumer_a_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (result_a> <= payload)
    )
  )
  (+size
    (go 1)
    (payload 8)
    (result_a 8)
  )
)

(?fsm:consumer_b_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (result_b> <= payload)
    )
  )
  (+size
    (go 1)
    (payload 8)
    (result_b 8)
  )
)
FSM
);

write_file(
    $c3_path,
    <<'FSM'
(?top:reexport_mixed_internal_carrier_top
  (?ports:public_io
    go
    payload>8
    result_data>8
  )
  (?dtc:producer producer_src)
  (?rtl:rtl_sink)
  (?wiring:wiring
    /go/producer.go/
    /rtl_sink.status_out/result_data/
  )
)

(?dt:producer_src
  (-produce
    (<go
      (payload> = 8'12)
    )
  )
  (+size
    (go 1)
    (payload 8)
  )
)

(?rtlif:rtl_sink
  clk:clock
  rstn:reset
  payload<8:data
  status_out>8:data
)
FSM
);

write_file(
    $ambiguous_path,
    <<'FSM'
(?top:ambiguous_reexport_internal_carrier_top
  (?ports:public_io
    go
    payload>8
    result_data>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:consumer consumer_src)
  (?wiring:wiring
    /go/left.go/
    /go/right.go/
    /go/consumer.go/
    /consumer.result_data/result_data/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (payload> <= 8'1)
    )
  )
  (+size
    (go 1)
    (payload 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (payload> <= 8'2)
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
    $width_mismatch_path,
    <<'FSM'
(?top:width_mismatch_reexport_internal_carrier_top
  (?ports:public_io
    go
    payload>4
    result_data>8
  )
  (?dtc:producer producer_src)
  (?rtl:rtl_sink)
  (?wiring:wiring
    /go/producer.go/
    /rtl_sink.status_out/result_data/
  )
)

(?dt:producer_src
  (-produce
    (<go
      (payload> = 8'12)
    )
  )
  (+size
    (go 1)
    (payload 8)
  )
)

(?rtlif:rtl_sink
  clk:clock
  rstn:reset
  payload<8:data
  status_out>8:data
)
FSM
);

write_file(
    $type_mismatch_path,
    <<'FSM'
(?top:type_mismatch_reexport_internal_carrier_top
  (?ports:public_io
    go
    payload>8:reset
    result_data>8
  )
  (?dtc:producer producer_src)
  (?rtl:rtl_sink)
  (?wiring:wiring
    /go/producer.go/
    /rtl_sink.status_out/result_data/
  )
)

(?dt:producer_src
  (-produce
    (<go
      (payload> = 8'12)
    )
  )
  (+size
    (go 1)
    (payload 8)
  )
)

(?rtlif:rtl_sink
  clk:clock
  rstn:reset
  payload<8:data
  status_out>8:data
)
FSM
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'explicit-link C2 can re-export an inferred same-name internal carrier through an explicit top output' => sub {
    my $result = $pipeline->generate_hdl_from_file($c2_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C2', 'generated-child internal-carrier re-export stays in C2');
    assert_only_carrier_and_shared_dp_sink_nets(
        $result->{composition_plan}->nets,
        [],
        're-exported internal carrier top',
    );

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{clk}, 'clk is inferred as a top input');
    ok($ports{rstn}, 'rstn is inferred as a top input');
    ok($ports{go}, 'explicit top input remains present');
    ok($ports{payload}, 'explicit top output re-exports the inferred carrier');
    ok($ports{result_a}, 'explicit result_a top output remains present');
    ok($ports{result_b}, 'explicit result_b top output remains present');
    is($ports{payload}->direction, 'output', 're-exported carrier keeps output direction');
    is($ports{payload}->width, 8, 're-exported carrier keeps output width');

    my %instance_bindings;
    for my $instance (@{$result->{composition_plan}->instances}) {
        $instance_bindings{$instance->instance_name} = {
            map { $_->{port_name} => $_->{signal_name} } @{$instance->port_bindings || []}
        };
    }

    is($instance_bindings{producer}{payload}, 'payload', 'producer output binds directly to the re-exported carrier');
    is($instance_bindings{consumer_a}{payload}, 'payload', 'first sink binds directly to the re-exported carrier');
    is($instance_bindings{consumer_b}{payload}, 'payload', 'second sink binds directly to the re-exported carrier');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\boutput\s+\[7:0\]\s+payload\b/s, 'generated HDL exposes the re-exported carrier as a top output');
    like($hdl, qr/\.payload\(payload\)/s, 'generated HDL binds the shared carrier name on child ports');
    unlike($hdl, qr/\bwire\s+\[7:0\]\s+payload;/s, 'generated HDL does not emit a redundant internal net for the re-exported carrier');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $c2_out_path, '--quiet', $c2_path],
    );
    ok($success, 'CLI succeeds for generated-child internal-carrier re-export');
    ok(-e $c2_out_path, 'CLI writes HDL output for generated-child internal-carrier re-export');
};

subtest 'explicit-link C3 can re-export an inferred same-name internal carrier across generated and rtl children' => sub {
    my $result = $pipeline->generate_hdl_from_file($c3_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'mixed internal-carrier re-export stays in C3');
    assert_only_carrier_and_shared_dp_sink_nets(
        $result->{composition_plan}->nets,
        [],
        'mixed re-exported internal carrier top',
    );

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{clk}, 'rtl clock is inferred as a top input');
    ok($ports{rstn}, 'rtl reset is inferred as a top input');
    ok($ports{go}, 'explicit top input remains present');
    ok($ports{payload}, 'explicit top output re-exports the mixed carrier');
    ok($ports{result_data}, 'explicit result_data top output remains present');

    my %producer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($producer_bindings{payload}, 'payload', 'generated producer output binds directly to the re-exported mixed carrier');
    is($rtl_bindings{payload}, 'payload', 'rtl input binds directly to the re-exported mixed carrier');
    is($rtl_bindings{status_out}, 'result_data', 'explicit mixed top-output wiring still works');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\boutput\s+\[7:0\]\s+payload\b/s, 'generated HDL exposes the mixed re-exported carrier');
    unlike($hdl, qr/\bwire\s+\[7:0\]\s+payload;/s, 'generated HDL does not emit a redundant mixed carrier net');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $c3_out_path, '--quiet', $c3_path],
    );
    ok($success, 'CLI succeeds for mixed internal-carrier re-export');
    ok(-e $c3_out_path, 'CLI writes HDL output for mixed internal-carrier re-export');
};

subtest 'same-name internal-carrier re-export still rejects several same-name child outputs' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($ambiguous_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits explicit same-name internal wiring for 'payload', .*undeclared internal-carrier inference is blocked because several same-name child outputs remain available for same-name child inputs.*left\.payload\[output, width=8\].*right\.payload\[output, width=8\]/s,
        're-export request still says the convention is blocked when several same-name child outputs remain',
    );
};

subtest 'same-name internal-carrier re-export requires exact top-output width agreement' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($width_mismatch_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares top output 'payload' with width 4, .*explicit top-output re-export is blocked because the same-name internal-carrier family resolves to width 8/s,
        'width-mismatched top-output re-export says the convention is blocked explicitly',
    );
};

subtest 'same-name internal-carrier re-export requires exact top-output type agreement' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($type_mismatch_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares top output 'payload' with interface type 'reset', .*explicit top-output re-export is blocked because the same-name internal-carrier family resolves to interface type 'data'/s,
        'type-mismatched top-output re-export says the convention is blocked explicitly',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
