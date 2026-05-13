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
    return FSM::Adapter::ISF->new()->parse_source($source, 'drive-name-boundary.isf');
}

subtest 'distinct drive names preserve drive map entries' => sub {
    my $actor = parse_source(<<'ISF');
(actor drive_names
  (clock clk)
  (interface
    (input start)
    (output done)
    (output psel)
    (output penable))
  (drive select
    (psel 1))
  (drive enable
    (penable 1))
  (transaction main
    (on start)
    (drive select)
    (drive enable)
    (complete done)))
ISF

    is_deeply(
        [sort keys %{$actor->{drives}}],
        ['enable', 'select'],
        'distinct drive names remain in the drive map',
    );
};

subtest 'duplicate drive names fail before actor-shell return' => sub {
    my $ok = eval {
        parse_source(<<'ISF');
(actor duplicate_drives
  (clock clk)
  (interface
    (input start)
    (output done)
    (output psel))
  (drive select
    (psel 1))
  (drive select
    (psel 0))
  (transaction main
    (on start)
    (drive select)
    (complete done)))
ISF
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, 'duplicate drive name is rejected by the parser');
    ok(!ref($diagnostic), 'duplicate drive diagnostic is scalar');
    like(
        $diagnostic,
        qr/\AError: duplicate drive 'select'/,
        'duplicate drive diagnostic identifies the name',
    );
};

done_testing();
