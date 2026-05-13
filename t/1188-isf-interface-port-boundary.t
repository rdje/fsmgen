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
    return FSM::Adapter::ISF->new()->parse_source($source, 'interface-port-boundary.isf');
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

subtest 'distinct interface port names preserve input and output shells' => sub {
    my $actor = parse_source(<<'ISF');
(actor interface_ports
  (clock clk)
  (interface
    (input start)
    (input data (width 8))
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF

    is_deeply(
        [map { $_->{name} } @{$actor->{interface}{inputs}}],
        ['start', 'data'],
        'input ports remain in author order',
    );
    is_deeply(
        $actor->{interface}{outputs},
        [{ name => 'done', width => 1 }],
        'output port shell is preserved',
    );
};

subtest 'malformed interface port names fail before actor-shell return' => sub {
    assert_parse_rejected(<<'ISF', 'duplicate input port', qr/\AError: duplicate interface port 'start'/);
(actor duplicate_input_port
  (clock clk)
  (interface
    (input start)
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate cross-direction port', qr/\AError: duplicate interface port 'done'/);
(actor duplicate_cross_direction_port
  (clock clk)
  (interface
    (input done)
    (output done))
  (transaction main
    (complete done)))
ISF
};

done_testing();
