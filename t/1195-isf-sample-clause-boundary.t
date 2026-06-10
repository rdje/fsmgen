#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $direct_on_params_diagnostic =
    "Transaction 'main': on body does not accept '(params ...)'; "
    . "direct '(on ...)' activation is an entry guard, not a generated activation-site parameter override";

sub lower_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'sample-clause-boundary.isf');
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

subtest 'valid on-body and standalone samples lower explicitly' => sub {
    my $result = lower_source(<<'ISF');
(actor sample_boundary
  (clock clk)
  (interface
    (input start)
    (input req)
    (output done))
  (drive pulse
    (done 1))
  (transaction main
    (on start
      (sample req as captured_req))
    (sample start as saw_start)
    (drive pulse)
    (complete done)))
ISF

    my $fsm = $result->{files}{'sample_boundary.fsm'};
    like($fsm, qr/\(<= \(captured_req req\) <start\)/, 'on-body sample lowers with the activation guard');
    like($fsm, qr/\(<= \(saw_start start\)\)/, 'standalone sample piggybacks onto the next drive state');
};

subtest 'malformed standalone samples fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'sample without as keyword', qr/\ATransaction 'main': sample requires '\(sample port as name\)' in transaction body/);
(actor sample_without_as
  (clock clk)
  (interface (input start) (input req) (output done))
  (transaction main
    (on start)
    (sample req captured)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested sample source', qr/\ATransaction 'main': sample requires '\(sample port as name\)' in transaction body/);
(actor nested_sample_source
  (clock clk)
  (interface (input start) (input req) (output done))
  (transaction main
    (on start)
    (sample (req) as captured)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested sample target', qr/\ATransaction 'main': sample requires '\(sample port as name\)' in transaction body/);
(actor nested_sample_target
  (clock clk)
  (interface (input start) (input req) (output done))
  (transaction main
    (on start)
    (sample req as (captured))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extra sample operand', qr/\ATransaction 'main': sample requires '\(sample port as name\)' in transaction body/);
(actor extra_sample_operand
  (clock clk)
  (interface (input start) (input req) (output done))
  (transaction main
    (on start)
    (sample req as captured now)
    (complete done)))
ISF
};

subtest 'malformed on activation samples fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'nested on guard', qr/\ATransaction 'main': on requires '\(on port \[sample\.\.\.\]\)' in transaction body/);
(actor nested_on_guard
  (clock clk)
  (interface (input start) (input req) (output done))
  (transaction main
    (on (start)
      (sample req as captured))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'unsupported on body clause', qr/\ATransaction 'main': on body supports only '\(sample port as name\)' clauses/);
(actor unsupported_on_body
  (clock clk)
  (interface (input start) (input req) (output done))
  (drive pulse
    (done 1))
  (transaction main
    (on start
      (drive pulse))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'direct on params block', qr/\A\Q$direct_on_params_diagnostic\E/);
(actor direct_on_params
  (clock clk)
  (interface (input start) (input req) (output done))
  (transaction main
    (on start
      (params
        (WIDTH 16)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'labeled direct on params block', qr/\A\Q$direct_on_params_diagnostic\E/);
(actor labeled_direct_on_params
  (clock clk)
  (interface (input start) (input req) (output done))
  (transaction main
    (on start as accepting
      (params
        (WIDTH 16)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'malformed on body sample', qr/\ATransaction 'main': sample requires '\(sample port as name\)' in on body/);
(actor malformed_on_body_sample
  (clock clk)
  (interface (input start) (input req) (output done))
  (transaction main
    (on start
      (sample req captured))
    (complete done)))
ISF
};

done_testing();
