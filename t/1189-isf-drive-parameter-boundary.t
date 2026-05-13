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
    return FSM::Adapter::ISF->new()->parse_source($source, 'drive-parameter-boundary.isf');
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

subtest 'distinct drive parameters preserve the actor shell' => sub {
    my $actor = parse_source(<<'ISF');
(actor drive_parameters
  (clock clk)
  (interface
    (input start)
    (output done)
    (output bus))
  (drive (publish addr data)
    (bus data))
  (transaction main
    (on start)
    (drive publish start done)
    (complete done)))
ISF

    is_deeply(
        $actor->{drives}{publish}{params},
        ['addr', 'data'],
        'distinct drive parameters remain in declaration order',
    );
};

subtest 'malformed drive parameters fail before actor-shell return' => sub {
    assert_parse_rejected(<<'ISF', 'duplicate drive parameter', qr/\AError: duplicate drive 'publish' parameter 'data'/);
(actor duplicate_drive_parameter
  (clock clk)
  (interface
    (input start)
    (output done)
    (output bus))
  (drive (publish data data)
    (bus data))
  (transaction main
    (on start)
    (drive publish start done)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'nested drive parameter', qr/\AError: drive 'publish' parameter names must be scalar/);
(actor nested_drive_parameter
  (clock clk)
  (interface
    (input start)
    (output done)
    (output bus))
  (drive (publish (data))
    (bus data))
  (transaction main
    (on start)
    (drive publish start)
    (complete done)))
ISF
};

done_testing();
