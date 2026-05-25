#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'latency-clause-boundary.isf');
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'valid latency metadata lowers to counter support' => sub {
    my $result = lower_source(<<'ISF');
(actor latency_boundary
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min 1) (max 8))))
ISF

    my $fsm = $result->{files}{'latency_boundary.fsm'};
    like($fsm, qr/\(main_cc \d+\)/, 'latency counter storage is emitted');
    like($fsm, qr/\(-main_cc_inc/, 'latency counter DT is emitted');
    like($fsm, qr/<main_cc<1/, 'minimum latency guard is emitted');
};

subtest 'actor constants can name latency bounds' => sub {
    my $result = lower_source(<<'ISF');
(actor latency_constant_boundary
  (clock clk)
  (constants
    (MIN_LAT 2)
    (MAX_LAT 8))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min MIN_LAT) (max MAX_LAT))))
ISF

    my $fsm = $result->{files}{'latency_constant_boundary.fsm'};
    like($fsm, qr/<main_cc<2/, 'constant minimum latency resolves before guard emission');
    like($fsm, qr/\(=8 \(-> main_timeout\)\)/, 'constant maximum latency resolves before timeout emission');
};

subtest 'actor scalar parameters can name latency bounds' => sub {
    my $result = lower_source(<<'ISF');
(actor latency_param_boundary
  (clock clk)
  (params
    (MIN_LAT 2)
    (MAX_LAT 4'd8))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min MIN_LAT) (max MAX_LAT))))
ISF

    my $fsm = $result->{files}{'latency_param_boundary.fsm'};
    like($fsm, qr/<main_cc<2/, 'parameter minimum latency resolves before guard emission');
    like($fsm, qr/\(=8 \(-> main_timeout\)\)/, 'parameter maximum latency resolves before timeout emission');
    like($fsm, qr/\(\+params[\s\S]*\(MIN_LAT 2\)[\s\S]*\(MAX_LAT 4'd8\)/, 'authored actor parameters remain visible');
};

subtest 'malformed latency metadata fails before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'empty latency clause', qr/\ATransaction 'main': latency requires '\(latency \(min N\) \(max M\)\)'/);
(actor empty_latency
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete done)
    (latency)))
ISF

    assert_lower_rejected(<<'ISF', 'unknown latency option', qr/\ATransaction 'main': latency options must be '\(min N\)' or '\(max N\)'/);
(actor unknown_latency_option
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (avg 4))))
ISF

    assert_lower_rejected(<<'ISF', 'unknown symbolic latency value', qr/\ATransaction 'main': latency min token 'fast' is not a declared actor constant, actor scalar parameter, or qualified package scalar constant in transaction body/);
(actor noninteger_latency
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min fast) (max 8))))
ISF

    assert_lower_rejected(<<'ISF', 'zero-valued latency constant', qr/\ATransaction 'main': latency min constant 'MIN_LAT' must resolve to a positive cycle count in transaction body/);
(actor zero_latency_constant
  (clock clk)
  (constants
    (MIN_LAT 0))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min MIN_LAT) (max 8))))
ISF

    assert_lower_rejected(<<'ISF', 'zero-valued actor parameter latency bound', qr/\ATransaction 'main': latency min parameter 'MIN_LAT' must resolve to a positive cycle count in transaction body/);
(actor zero_parameter_latency_bound
  (clock clk)
  (params
    (MIN_LAT 0))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min MIN_LAT) (max 8))))
ISF

    assert_lower_rejected(<<'ISF', 'non-scalar actor parameter latency bound', qr/\ATransaction 'main': latency min parameter 'MIN_LAT' must resolve to a positive cycle count in transaction body/);
(actor nonscalar_parameter_latency_bound
  (clock clk)
  (params
    (MIN_LAT (2 3)))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min MIN_LAT) (max 8))))
ISF

    assert_lower_rejected(<<'ISF', 'transaction parameter latency bound', qr/\ATransaction 'child': latency min token 'MIN_LAT' is a transaction parameter; latency bounds accept positive integer literals, actor constants, actor scalar parameters, or qualified package scalar constants only in transaction body/);
(actor transaction_parameter_latency_bound
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done))
  (transaction child
    (params
      (MIN_LAT 2))
    (complete done)
    (latency (min MIN_LAT) (max 8))))
ISF

    assert_lower_rejected(<<'ISF', 'transaction parameter latency bound shadows actor parameter', qr/\ATransaction 'child': latency min token 'MIN_LAT' is a transaction parameter; latency bounds accept positive integer literals, actor constants, actor scalar parameters, or qualified package scalar constants only in transaction body/);
(actor transaction_parameter_latency_shadow
  (clock clk)
  (params
    (MIN_LAT 2))
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done))
  (transaction child
    (params
      (MIN_LAT 3))
    (complete done)
    (latency (min MIN_LAT) (max 8))))
ISF

    assert_lower_rejected(<<'ISF', 'runtime interface latency bound', qr/\ATransaction 'main': latency min token 'delay' is a runtime interface signal; latency bounds accept positive integer literals, actor constants, actor scalar parameters, or qualified package scalar constants only in transaction body/);
(actor runtime_latency_bound
  (clock clk)
  (interface (input start) (input delay) (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min delay) (max 8))))
ISF

    assert_lower_rejected(<<'ISF', 'duplicate latency min', qr/\ATransaction 'main': duplicate latency 'min' option/);
(actor duplicate_latency_min
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min 1) (min 2) (max 8))))
ISF

    assert_lower_rejected(<<'ISF', 'latency min greater than max', qr/\ATransaction 'main': latency min must be less than or equal to max/);
(actor latency_min_gt_max
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min 9) (max 8))))
ISF
};

done_testing();
