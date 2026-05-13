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
    return FSM::Adapter::ISF->new()->parse_source($source, 'rule-name-boundary.isf');
}

subtest 'distinct rule names preserve actor-shell order' => sub {
    my $actor = parse_source(<<'ISF');
(actor rule_names
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
  (rule first a
    (valid 1))
  (rule second b
    (trigger main)))
ISF

    is_deeply(
        [map { $_->{name} } @{$actor->{rules}}],
        ['first', 'second'],
        'distinct rule names remain in author order',
    );
};

subtest 'duplicate rule names fail before actor-shell return' => sub {
    my $ok = eval {
        parse_source(<<'ISF');
(actor duplicate_rules
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
  (rule choose a
    (valid 1))
  (rule choose b
    (trigger main)))
ISF
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, 'duplicate rule name is rejected by the parser');
    ok(!ref($diagnostic), 'duplicate rule diagnostic is scalar');
    like(
        $diagnostic,
        qr/\AError: duplicate rule 'choose' in actor 'duplicate_rules'/,
        'duplicate rule diagnostic identifies the name and actor',
    );
};

done_testing();
