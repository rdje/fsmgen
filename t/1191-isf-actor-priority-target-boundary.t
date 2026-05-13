#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'actor-priority-target-boundary.isf');
}

sub assert_parse_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        parse_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected by the parser");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'actor priority targets may be declared after the priority' => sub {
    my $actor = parse_source(<<'ISF');
(actor actor_priority_target
  (clock clk)
  (interface
    (input start)
    (output done)
    (output valid))
  (priority main over fallback)
  (transaction main
    (on start)
    (complete done))
  (rule fallback start
    (valid 0)))
ISF

    is_deeply(
        $actor->{priorities},
        [['main', 'over', 'fallback']],
        'valid forward priority targets are preserved',
    );
};

subtest 'unknown actor priority targets fail before actor-shell return' => sub {
    assert_parse_rejected(<<'ISF', 'unknown lhs priority target', qr/\AError: priority target 'missing' is not a declared transaction or rule in actor 'bad_actor_priority_lhs'/);
(actor bad_actor_priority_lhs
  (clock clk)
  (interface
    (input start)
    (output done))
  (priority missing over main)
  (transaction main
    (on start)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'unknown rhs priority target', qr/\AError: priority target 'missing' is not a declared transaction or rule in actor 'bad_actor_priority_rhs'/);
(actor bad_actor_priority_rhs
  (clock clk)
  (interface
    (input start)
    (output done))
  (priority main over missing)
  (transaction main
    (on start)
    (complete done)))
ISF
};

done_testing();
