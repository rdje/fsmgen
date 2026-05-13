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
    return FSM::Adapter::ISF->new()->parse_source($source, 'transaction-name-boundary.isf');
}

subtest 'distinct transaction names preserve actor-shell order' => sub {
    my $actor = parse_source(<<'ISF');
(actor transaction_names
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction first
    (on start)
    (complete done))
  (transaction second
    (complete done)))
ISF

    is_deeply(
        [map { $_->{name} } @{$actor->{transactions}}],
        ['first', 'second'],
        'distinct transaction names remain in author order',
    );
};

subtest 'duplicate transaction names fail before actor-shell return' => sub {
    my $ok = eval {
        parse_source(<<'ISF');
(actor duplicate_transactions
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done))
  (transaction main
    (complete done)))
ISF
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, 'duplicate transaction name is rejected by the parser');
    ok(!ref($diagnostic), 'duplicate transaction diagnostic is scalar');
    like(
        $diagnostic,
        qr/\AError: duplicate transaction 'main' in actor 'duplicate_transactions'/,
        'duplicate transaction diagnostic identifies the name and actor',
    );
};

done_testing();
