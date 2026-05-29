#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Locks the actor-local (types) <-> (enums) relationship documented for
# SPECFORGE (2026-05-29 clarity request). These assertions make the
# documented contract executable:
#
#   1. An enum name is NOT automatically a scalar type alias: using
#      (type NAME) when only (enums (NAME ...)) is declared fails closed.
#   2. Co-declaring (type NAME (bits k)) AND (enums (NAME ...)) for the
#      same NAME is accepted (not a redeclaration conflict) and is the
#      supported way to use an enum name as a width-bearing type.
#   3. Unreferenced actor-local (types)/(enums)/(constants) are
#      contract-valid.

sub parse_lower {
    my ($src) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($src, 'enum-type-relationship.isf');
    return FSM::Scheduler::ISF->new()->lower($actor);
}

subtest 'enum name alone is not a usable (type NAME)' => sub {
    my $src = <<'ISF';
(actor enum_not_a_type
  (clock clk)
  (reset rst_n)
  (enums (mode (IDLE 0) (BUSY 1)))
  (interface
    (input start)
    (output state_out (type mode))
    (output done))
  (transaction tx (on start) (complete done)))
ISF
    my $ok = eval { parse_lower($src); 1 };
    ok(!$ok, 'using an enum name as (type NAME) without a backing (type) fails closed');
    like($@, qr/references unknown type 'mode'/,
        'rejection names the enum name as an unknown type');
};

subtest 'co-declaring (type NAME) and (enums NAME) for the same name is accepted' => sub {
    my $src = <<'ISF';
(actor enum_with_type
  (clock clk)
  (reset rst_n)
  (types (type mode (bits 1)))
  (enums (mode (IDLE 0) (BUSY 1)))
  (interface
    (input start)
    (output state_out (type mode))
    (output done))
  (transaction tx (on start) (complete done)))
ISF
    my $result = eval { parse_lower($src) };
    ok($result, 'co-declared (type NAME)+(enums NAME) lowers cleanly (no redeclaration conflict)')
        or diag($@);
    my $fsm = $result->{files}{'enum_with_type.fsm'};
    like($fsm, qr/\(state_out\b/, 'the enum-typed port reaches the scheduled .fsm');
};

subtest 'unreferenced actor-local declarations are contract-valid' => sub {
    my $src = <<'ISF';
(actor unreferenced_decls
  (clock clk)
  (reset rst_n)
  (types (type byte (bits 8)))
  (enums (mode (IDLE 0) (BUSY 1)))
  (constants (UNUSED 7))
  (interface (input start) (output done))
  (transaction tx (on start) (complete done)))
ISF
    my $result = eval { parse_lower($src) };
    ok($result, 'unreferenced (types)/(enums)/(constants) lower cleanly')
        or diag($@);
};

done_testing();
