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
    return FSM::Adapter::ISF->new()->parse_source($source, 'rule-priority-target-boundary.isf');
}

subtest 'rule priority target may be declared after the rule' => sub {
    my $actor = parse_source(<<'ISF');
(actor rule_priority_target
  (clock clk)
  (interface
    (input a)
    (input b)
    (input start)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (rule high a
    (priority over low)
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    is_deeply(
        $actor->{rules}[0]{actions}[0],
        ['priority', 'over', 'low'],
        'valid forward priority target is preserved in rule action metadata',
    );
};

subtest 'unknown rule priority target fails before actor-shell return' => sub {
    my $ok = eval {
        parse_source(<<'ISF');
(actor bad_rule_priority_target
  (clock clk)
  (interface
    (input a)
    (input start)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (rule high a
    (priority over missing)
    (valid 1)))
ISF
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, 'unknown priority target is rejected by the parser');
    ok(!ref($diagnostic), 'unknown priority target diagnostic is scalar');
    like(
        $diagnostic,
        qr/\AError: rule 'high' priority targets unknown rule 'missing' in actor 'bad_rule_priority_target'/,
        'unknown priority target diagnostic identifies the rule, target, and actor',
    );
};

done_testing();
