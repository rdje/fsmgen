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
    return FSM::Adapter::ISF->new()->parse_source($source, 'singleton-actor-clause-boundary.isf');
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

subtest 'single clock reset watchdog interface resources and storage clauses are preserved' => sub {
    my $actor = parse_source(<<'ISF');
(actor singleton_actor_clauses
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 64)
  (interface
    (input start)
    (output done))
  (resources
    (resource shared_bus (arbiter priority)))
  (storage
    (var rd_ptr (width 2)))
  (transaction main
    (on start)
    (complete done)))
ISF

    is($actor->{clock}, 'clk', 'clock shell is preserved');
    is_deeply(
        $actor->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'reset shell is preserved',
    );
    is($actor->{watchdog}, 64, 'watchdog shell is preserved');
    is_deeply(
        $actor->{interface}{outputs},
        [{ name => 'done', width => 1 }],
        'interface shell is preserved',
    );
    is_deeply(
        $actor->{resources},
        [{ name => 'shared_bus', arbiter => 'priority' }],
        'resources shell is preserved',
    );
    is_deeply(
        $actor->{storage},
        [
            {
                kind    => 'var',
                name    => 'rd_ptr',
                width   => 2,
                signals => [{ name => 'rd_ptr', width => 2 }],
            },
        ],
        'storage shell is preserved',
    );
};

subtest 'duplicate singleton actor clauses fail before actor-shell return' => sub {
    assert_parse_rejected(<<'ISF', 'duplicate clock clause', qr/\AError: duplicate actor clause 'clock' in actor 'duplicate_clock'/);
(actor duplicate_clock
  (clock clk)
  (clock clk2)
  (interface (input start) (output done))
  (transaction main (on start) (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate reset clause', qr/\AError: duplicate actor clause 'reset' in actor 'duplicate_reset'/);
(actor duplicate_reset
  (clock clk)
  (reset rst_n)
  (reset rst)
  (interface (input start) (output done))
  (transaction main (on start) (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate watchdog clause', qr/\AError: duplicate actor clause 'watchdog' in actor 'duplicate_watchdog'/);
(actor duplicate_watchdog
  (clock clk)
  (watchdog 64)
  (watchdog 128)
  (interface (input start) (output done))
  (transaction main (on start) (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate interface clause', qr/\AError: duplicate actor clause 'interface' in actor 'duplicate_interface'/);
(actor duplicate_interface
  (clock clk)
  (interface (input start))
  (interface (output done))
  (transaction main (on start) (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate resources clause', qr/\AError: duplicate actor clause 'resources' in actor 'duplicate_resources'/);
(actor duplicate_resources
  (clock clk)
  (interface (input start) (output done))
  (resources
    (resource shared_bus (arbiter priority)))
  (resources
    (resource mem_port (arbiter round_robin)))
  (transaction main (on start) (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate storage clause', qr/\AError: duplicate actor clause 'storage' in actor 'duplicate_storage'/);
(actor duplicate_storage
  (clock clk)
  (interface (input start) (output done))
  (storage
    (var rd_ptr (width 2)))
  (storage
    (var wr_ptr (width 2)))
  (transaction main (on start) (complete done)))
ISF
};

done_testing();
