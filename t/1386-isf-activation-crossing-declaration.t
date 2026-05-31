#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Locks ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.2: the new
# `(crossings (activation child (from SRC) (to DEST)))` declaration parses and
# is structurally validated, malformed forms are rejected at parse, and a
# well-formed declaration FAILS CLOSED at lowering ("not yet supported") because
# the CDC routing of the activation start/done handshake ships in `.3`
# (parser-acceptance != support). Existing event crossings are unaffected.

sub parse_only {
    my ($src) = @_;
    return FSM::Adapter::ISF->new()->parse_source($src, 'activation-crossing.isf');
}

sub parse_lower {
    my ($src) = @_;
    my $actor = parse_only($src);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

my $DECLARED = <<'ISF';
(actor declared_activation_crossing
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core)) (output done (domain core)))
  (crossings
    (activation worker (from core) (to aux)))
  (transaction parent
    (domain core)
    (on start)
    (complete done))
  (transaction worker
    (domain aux)
    (complete done)))
ISF

subtest 'a well-formed activation crossing parses + validates and is recorded on the actor' => sub {
    my $actor = eval { parse_only($DECLARED) };
    ok($actor, 'actor with an activation crossing parses') or diag($@);
    my ($act) = grep { ($_->{kind} // '') eq 'activation' } @{$actor->{crossings} || []};
    ok($act, 'an activation crossing record is present');
    is($act->{child}, 'worker', 'records the child');
    is($act->{from}{domain}, 'core', 'records the source domain');
    is($act->{to}{domain}, 'aux', 'records the destination domain');
};

subtest 'a declared-but-unused activation crossing fails closed at lowering' => sub {
    # The $DECLARED actor declares an activation crossing but `parent` never
    # performs `(do worker)`, so the crossing owns no real cross-domain activation;
    # lowering it would emit dead CDC logic. It must fail closed. (The end-to-end
    # lowering of a USED activation crossing is covered in t/1387.)
    my $ok = eval { parse_lower($DECLARED); 1 };
    ok(!$ok, 'lowering an actor with a declared-but-unused activation crossing is rejected');
    like($@, qr/activation crossing for child 'worker'.*declared but no transaction in domain 'core' performs a top-level '\(do worker\)'/s,
        'the diagnostic explains the crossing owns no real cross-domain activation');
};

subtest 'malformed activation crossing declarations are rejected at parse' => sub {
    my %bad = (
        'same source/dest domain' => <<'ISF',
(actor a
  (clock-domains (domain core (clock clk) (reset rst_n) :default) (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface (input start (domain core)) (output done (domain core)))
  (crossings (activation worker (from core) (to core)))
  (transaction parent (domain core) (on start) (complete done))
  (transaction worker (domain aux) (complete done)))
ISF
        'child is not a declared transaction' => <<'ISF',
(actor a
  (clock-domains (domain core (clock clk) (reset rst_n) :default) (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface (input start (domain core)) (output done (domain core)))
  (crossings (activation ghost (from core) (to aux)))
  (transaction parent (domain core) (on start) (complete done))
  (transaction worker (domain aux) (complete done)))
ISF
        'undeclared destination domain' => <<'ISF',
(actor a
  (clock-domains (domain core (clock clk) (reset rst_n) :default) (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface (input start (domain core)) (output done (domain core)))
  (crossings (activation worker (from core) (to nope)))
  (transaction parent (domain core) (on start) (complete done))
  (transaction worker (domain aux) (complete done)))
ISF
        'missing (to domain) subclause' => <<'ISF',
(actor a
  (clock-domains (domain core (clock clk) (reset rst_n) :default) (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface (input start (domain core)) (output done (domain core)))
  (crossings (activation worker (from core)))
  (transaction parent (domain core) (on start) (complete done))
  (transaction worker (domain aux) (complete done)))
ISF
    );
    for my $label (sort keys %bad) {
        my $ok = eval { parse_only($bad{$label}); 1 };
        ok(!$ok, "malformed activation crossing ($label) is rejected at parse");
    }
};

subtest 'existing event crossings are unaffected (still lower)' => sub {
    my $src = <<'ISF';
(actor event_crossing_unaffected
  (clock-domains
    (domain bus (clock bclk) (reset brst) :default)
    (domain core (clock cclk) (reset crst)))
  (interface
    (input go (domain bus)) (output rx (domain core)))
  (crossings
    (event ev (from bus ev_req) (to core ev_pulse) (ready ev_rdy)))
  (transaction tx (domain bus) (on go) (complete ev_req))
  (transaction rxh (domain core) (on ev_pulse) (complete rx)))
ISF
    my $r = eval { parse_lower($src) };
    ok($r, 'an event crossing actor still lowers') or diag($@);
    ok(exists $r->{files}{'event_crossing_unaffected_top.fsm'},
        'the event-crossing _top is still emitted');
};

done_testing();
