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
my $c2_path = File::Spec->catfile($tempdir, 'implicit_internal_carrier_top.fsm');
my $c2_out_path = File::Spec->catfile($tempdir, 'implicit_internal_carrier_top.sv');
my $c3_path = File::Spec->catfile($tempdir, 'implicit_mixed_internal_carrier_top.fsm');
my $c3_out_path = File::Spec->catfile($tempdir, 'implicit_mixed_internal_carrier_top.sv');
my $ambiguous_path = File::Spec->catfile($tempdir, 'ambiguous_internal_carrier_top.fsm');

write_file(
    $c2_path,
    <<'FSM'
(?top:implicit_internal_carrier_top
  (?ports:public_io
    go
    result_a>8
    result_b>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer_a consumer_a_src)
  (?fsmc:consumer_b consumer_b_src)
  (?toplink:wiring
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
(?top:implicit_mixed_internal_carrier_top
  (?ports:public_io
    go
    result_data>8
  )
  (?dtc:producer producer_src)
  (?rtl:rtl_sink)
  (?toplink:wiring
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
(?top:ambiguous_internal_carrier_top
  (?ports:public_io
    go
    result_data>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
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

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'explicit-link C2 infers same-name internal carriers with one driver and several sinks' => sub {
    my $result = $pipeline->generate_hdl_from_file($c2_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C2', 'generated-child internal carrier inference stays in C2');
    is(scalar(@{$result->{composition_plan}->nets}), 1, 'one inferred internal carrier net is created');
    is($result->{composition_plan}->nets->[0]->name, 'payload', 'internal same-name carrier uses the shared signal name');
    is($result->{composition_plan}->nets->[0]->width, 8, 'internal same-name carrier preserves width');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{clk}, 'clk is inferred as a top input');
    ok($ports{rstn}, 'rstn is inferred as a top input');
    ok($ports{go}, 'explicit top input remains present');
    ok($ports{result_a}, 'explicit result_a top output remains present');
    ok($ports{result_b}, 'explicit result_b top output remains present');
    ok(!$ports{payload}, 'internal same-name carrier is not re-exported as a top port by default');

    my %instance_bindings;
    for my $instance (@{$result->{composition_plan}->instances}) {
        $instance_bindings{$instance->instance_name} = {
            map { $_->{port_name} => $_->{signal_name} } @{$instance->port_bindings || []}
        };
    }

    is($instance_bindings{producer}{payload}, 'payload', 'producer output binds to the inferred internal carrier');
    is($instance_bindings{consumer_a}{payload}, 'payload', 'first sink binds to the inferred internal carrier');
    is($instance_bindings{consumer_b}{payload}, 'payload', 'second sink binds to the inferred internal carrier');
    is($instance_bindings{consumer_a}{result_a}, 'result_a', 'explicit top output wiring still works for consumer_a');
    is($instance_bindings{consumer_b}{result_b}, 'result_b', 'explicit top output wiring still works for consumer_b');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bwire\s+\[7:0\]\s+payload;/s, 'generated HDL declares the inferred internal same-name carrier');
    like($hdl, qr/\.payload\(payload\)/s, 'generated HDL uses the inferred carrier name on child bindings');
    unlike($hdl, qr/\boutput\s+\[7:0\]\s+payload\b/s, 'generated HDL keeps the inferred carrier internal by default');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $c2_out_path, '--quiet', $c2_path],
    );
    ok($success, 'CLI succeeds for generated-child same-name internal carrier inference');
    ok(-e $c2_out_path, 'CLI writes HDL output for generated-child same-name internal carrier inference');
};

subtest 'explicit-link C3 infers same-name internal carriers across generated and rtl children' => sub {
    my $result = $pipeline->generate_hdl_from_file($c3_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'mixed generated-plus-rtl internal carrier inference stays in C3');
    is(scalar(@{$result->{composition_plan}->nets}), 1, 'one inferred internal carrier net is created in mixed composition');
    is($result->{composition_plan}->nets->[0]->name, 'payload', 'mixed internal carrier uses the shared signal name');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{clk}, 'rtl clock is inferred as a top input');
    ok($ports{rstn}, 'rtl reset is inferred as a top input');
    ok($ports{go}, 'explicit top input remains present');
    ok($ports{result_data}, 'explicit top output remains present');
    ok(!$ports{payload}, 'mixed internal same-name carrier is not re-exported as a top port by default');

    my %producer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($producer_bindings{payload}, 'payload', 'generated producer output binds to the inferred internal carrier');
    is($rtl_bindings{payload}, 'payload', 'rtl input binds to the inferred internal carrier');
    is($rtl_bindings{status_out}, 'result_data', 'explicit rtl top-output wiring still works');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bwire\s+\[7:0\]\s+payload;/s, 'generated HDL declares the inferred mixed internal carrier');
    like($hdl, qr/\.payload\(payload\)/s, 'generated HDL binds the mixed same-name carrier deterministically');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $c3_out_path, '--quiet', $c3_path],
    );
    ok($success, 'CLI succeeds for mixed generated-plus-rtl same-name internal carrier inference');
    ok(-e $c3_out_path, 'CLI writes HDL output for mixed generated-plus-rtl same-name internal carrier inference');
};

subtest 'internal same-name carrier inference rejects several same-name child outputs' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($ambiguous_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits explicit same-name internal wiring for 'payload', .*undeclared internal-carrier inference cannot choose one driving child output because several same-name child outputs remain available.*left\.payload\[output, width=8\].*right\.payload\[output, width=8\]/s,
        'same-name internal carrier inference rejects several same-name child outputs',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
