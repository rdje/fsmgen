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

    assert_lower_rejected(<<'ISF', 'noninteger latency value', qr/\ATransaction 'main': latency options must be '\(min N\)' or '\(max N\)'/);
(actor noninteger_latency
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete done)
    (latency (min fast) (max 8))))
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
