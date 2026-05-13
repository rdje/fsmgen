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
    return FSM::Adapter::ISF->new()->parse_source($source, 'rule-trigger-target-boundary.isf');
}

subtest 'rule trigger target may be declared after the rule' => sub {
    my $actor = parse_source(<<'ISF');
(actor trigger_forward_reference
  (clock clk)
  (interface
    (input ready)
    (input start)
    (output done))
  (rule start_when_ready ready
    (trigger main))
  (transaction main
    (on start)
    (complete done)))
ISF

    is(scalar(@{$actor->{rules}}), 1, 'actor has one rule');
    is_deeply(
        $actor->{rules}[0]{actions},
        [['trigger', 'main']],
        'valid trigger target is preserved in the rule action array',
    );
};

subtest 'unknown rule trigger target fails before actor-shell return' => sub {
    my $ok = eval {
        parse_source(<<'ISF');
(actor bad_trigger_target
  (clock clk)
  (interface
    (input ready)
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done))
  (rule start_when_ready ready
    (trigger missing)))
ISF
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, 'unknown trigger target is rejected by the parser');
    ok(!ref($diagnostic), 'unknown trigger target diagnostic is scalar');
    like(
        $diagnostic,
        qr/\AError: rule 'start_when_ready' triggers unknown transaction 'missing' in actor 'bad_trigger_target'/,
        'unknown trigger target diagnostic identifies the rule, target, and actor',
    );
};

done_testing();
