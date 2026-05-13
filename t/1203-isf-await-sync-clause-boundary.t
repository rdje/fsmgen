#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'await-sync-clause-boundary.isf');
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'valid await_all and await_any clauses lower sync states' => sub {
    my $result = lower_source(<<'ISF');
(actor await_sync_boundary
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction child
    (on start)
    (complete done))
  (transaction parent_all
    (on start)
    (spawn child as w0)
    (await_all done)
    (complete done))
  (transaction parent_any
    (on start)
    (spawn child as w1)
    (await_any done)
    (complete done)))
ISF

    my $fsm = $result->{files}{'await_sync_boundary.fsm'};
    like($fsm, qr/parent_all_await_all_2/, 'await_all sync state is emitted');
    like($fsm, qr/parent_any_await_any_2/, 'await_any sync state is emitted');
};

subtest 'malformed await sync clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'missing await_all done port', qr/\ATransaction 'parent': await_all requires '\(await_all done_port\)' in transaction body/);
(actor await_all_missing_port
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (await_all)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested await_any done port', qr/\ATransaction 'parent': await_any requires '\(await_any done_port\)' in transaction body/);
(actor await_any_nested_port
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (await_any (done))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extra await_all operand', qr/\ATransaction 'parent': await_all requires '\(await_all done_port\)' in transaction body/);
(actor await_all_extra_operand
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (await_all done extra)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extra await_any operand', qr/\ATransaction 'parent': await_any requires '\(await_any done_port\)' in transaction body/);
(actor await_any_extra_operand
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (await_any done extra)
    (complete done)))
ISF
};

done_testing();
