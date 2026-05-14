#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'deprecated handshake metadata is validated then ignored' => sub {
    my $source = <<'ISF';
(actor legacy_handshake
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input req_valid)
    (output can_accept)
    (output done))
  (handshake request (valid req_valid) (ready can_accept))
  (transaction main
    (on start)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'legacy-handshake.isf');
    ok(ref($actor) eq 'HASH', 'parser returns an actor shell');
    is_deeply($actor->{handshakes}, {}, 'deprecated handshake metadata remains ignored after validation');

    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    like($result->{files}{'legacy_handshake.fsm'}, qr/\bmain_idle_0\b/, 'validated legacy handshake actor still lowers');
};

subtest 'malformed deprecated handshake metadata fails before actor-shell return' => sub {
    my @cases = (
        [
            'nested name',
            <<'ISF',
(actor bad_handshake
  (clock clk)
  (interface (input start) (output done))
  (handshake (request) (valid req)))
ISF
            qr/\AError: \(handshake \.\.\.\) requires a scalar name/,
        ],
        [
            'missing property',
            <<'ISF',
(actor bad_handshake
  (clock clk)
  (interface (input start) (output done))
  (handshake request))
ISF
            qr/\AError: \(handshake \.\.\.\) requires '\(handshake name \(valid signal\) \(ready signal\)\)'/,
        ],
        [
            'missing ready property',
            <<'ISF',
(actor bad_handshake
  (clock clk)
  (interface (input start) (output done))
  (handshake request (valid req)))
ISF
            qr/\AError: handshake 'request' requires exactly one '\(valid signal\)' and one '\(ready signal\)' property; legacy handshakes are ignored compatibility input, use '\(on \.\.\.\)' activation or transaction '\(stage \.\.\.\)' for ready\/valid behavior/,
        ],
        [
            'unsupported property',
            <<'ISF',
(actor bad_handshake
  (clock clk)
  (interface (input start) (output done))
  (handshake request (grant gnt)))
ISF
            qr/\AError: handshake 'request' properties must be '\(valid signal\)' or '\(ready signal\)'/,
        ],
        [
            'duplicate valid property',
            <<'ISF',
(actor bad_handshake
  (clock clk)
  (interface (input start) (output done))
  (handshake request (valid req) (valid req2)))
ISF
            qr/\AError: duplicate handshake 'request' property 'valid'/,
        ],
        [
            'nested signal',
            <<'ISF',
(actor bad_handshake
  (clock clk)
  (interface (input start) (output done))
  (handshake request (ready (can_accept))))
ISF
            qr/\AError: handshake 'request' properties must be '\(valid signal\)' or '\(ready signal\)'/,
        ],
        [
            'duplicate handshake name',
            <<'ISF',
(actor bad_handshake
  (clock clk)
  (interface (input start) (output done))
  (handshake request (valid req) (ready can_accept))
  (handshake request (valid req2) (ready can_accept2)))
ISF
            qr/\AError: duplicate handshake 'request' in actor 'bad_handshake'; legacy handshakes are ignored compatibility input/,
        ],
    );

    for my $case (@cases) {
        my ($label, $source, $pattern) = @$case;
        my $ok = eval { FSM::Adapter::ISF->new()->parse_source($source, "$label.isf"); 1 };
        my $diagnostic = $@;

        ok(!$ok, "$label is rejected");
        ok(!ref($diagnostic), "$label diagnostic is scalar");
        like($diagnostic, $pattern, "$label diagnostic is bounded");
    }
};

done_testing();
