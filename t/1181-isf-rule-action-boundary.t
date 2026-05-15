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
    return FSM::Adapter::ISF->new()->parse_source($source, 'rule-action-boundary.isf');
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

subtest 'valid rule actions preserve the public rule shell' => sub {
    my $actor = parse_source(<<'ISF');
(actor rule_actions
  (clock clk)
  (interface
    (input start)
    (input ready)
    (input error_seen)
    (output valid)
    (output status)
    (output done))
  (transaction main
    (on start)
    (complete done))
  (rule always_ready ready
    (valid 1)
    (status (| ready error_seen))
    (trigger main)
    (priority over fallback))
  (rule fallback start
    (valid 0)))
ISF

    is(scalar(@{$actor->{rules}}), 2, 'actor has two rules including priority target');
    is_deeply(
        $actor->{rules}[0]{actions},
        [
            ['valid',   '1'],
            ['status', ['|', 'ready', 'error_seen']],
            ['trigger', 'main'],
            ['priority', 'over', 'fallback'],
        ],
        'valid rule actions remain in the rule action array',
    );
};

subtest 'malformed rule actions fail before actor-shell return' => sub {
    assert_parse_rejected(<<'ISF', 'scalar action', qr/\AError: rule 'bad' actions must be list forms/);
(actor bad_rule_action
  (clock clk)
  (interface (input start) (input ready) (output done))
  (transaction main (on start) (complete done))
  (rule bad ready
    valid))
ISF

    assert_parse_rejected(<<'ISF', 'nested action head', qr/\AError: rule 'bad' action heads must be scalar/);
(actor bad_rule_action
  (clock clk)
  (interface (input start) (input ready) (output done))
  (transaction main (on start) (complete done))
  (rule bad ready
    ((valid) 1)))
ISF

    assert_parse_rejected(<<'ISF', 'missing trigger target', qr/\AError: rule 'bad' trigger requires '\(trigger transaction \[\(bind \.\.\.\)\]\)'/);
(actor bad_rule_action
  (clock clk)
  (interface (input start) (input ready) (output done))
  (transaction main (on start) (complete done))
  (rule bad ready
    (trigger)))
ISF

    assert_parse_rejected(<<'ISF', 'extra trigger operand', qr/\AError: rule 'bad' trigger 'main' bind requires '\(bind \(input port signal\) \.\.\.\)'/);
(actor bad_rule_action
  (clock clk)
  (interface (input start) (input ready) (output done))
  (transaction main (on start) (complete done))
  (rule bad ready
    (trigger main other)))
ISF

    assert_parse_rejected(<<'ISF', 'missing assignment value', qr/\AError: rule 'bad' assignment actions require '\(port expr\)'/);
(actor bad_rule_action
  (clock clk)
  (interface (input start) (input ready) (output done))
  (transaction main (on start) (complete done))
  (rule bad ready
    (done)))
ISF

    assert_parse_rejected(<<'ISF', 'extra assignment operand', qr/\AError: rule 'bad' assignment actions require '\(port expr\)'/);
(actor bad_rule_action
  (clock clk)
  (interface (input start) (input ready) (output done))
  (transaction main (on start) (complete done))
  (rule bad ready
    (done 1 extra)))
ISF

    assert_parse_rejected(<<'ISF', 'empty assignment expression', qr/\AError: rule 'bad' assignment actions require '\(port expr\)'/);
(actor bad_rule_action
  (clock clk)
  (interface (input start) (input ready) (output done))
  (transaction main (on start) (complete done))
  (rule bad ready
    (done ())))
ISF

    assert_parse_rejected(<<'ISF', 'nested assignment expression head', qr/\AError: rule 'bad' assignment expression heads must be scalar/);
(actor bad_rule_action
  (clock clk)
  (interface (input start) (input ready) (output done))
  (transaction main (on start) (complete done))
  (rule bad ready
    (done ((|) ready start))))
ISF

    assert_parse_rejected(<<'ISF', 'control-flow expression head', qr/\AError: rule 'bad' assignment RHS cannot use control-flow form 'when'/);
(actor bad_rule_action
  (clock clk)
  (interface (input start) (input ready) (output done))
  (transaction main (on start) (complete done))
  (rule bad ready
    (done (when ready 1))))
ISF
};

done_testing();
