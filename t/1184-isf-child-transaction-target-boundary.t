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
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'child-target-boundary.isf');
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

subtest 'forward child transaction references lower' => sub {
    my $result = lower_source(<<'ISF');
(actor child_forward_refs
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (do child)
    (spawn child as worker)
    (await_all done)
    (complete done))
  (transaction child
    (complete done)))
ISF

    ok($result->{files}{'child_forward_refs.fsm'}, 'parent file is emitted');
    ok($result->{files}{'child.fsm'}, 'spawned child file is emitted');
    like(
        $result->{files}{'child_forward_refs.fsm'},
        qr/\(= \(parent_child_do_0_start> 1\)\)/,
        'blocking do to a generated child asserts its generated instance start',
    );
    like(
        $result->{files}{'child_forward_refs.fsm'},
        qr/<parent_child_do_0_done/,
        'blocking do to a generated child awaits its generated instance done',
    );
    like(
        $result->{files}{'child_forward_refs.fsm'},
        qr/\(= \(worker_start> 1\)\)/,
        'spawn instance target is wired in the parent file',
    );
};

subtest 'unknown child transaction references fail closed' => sub {
    assert_lower_rejected(<<'ISF', 'unknown do target', qr/\ATransaction 'parent': do target 'missing' is not a declared transaction/);
(actor bad_do_target
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (do missing)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'unknown spawn target', qr/\ATransaction 'parent': spawn target 'missing' is not a declared transaction/);
(actor bad_spawn_target
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn missing as worker)
    (await_all done)
    (complete done)))
ISF
};

subtest 'generated child activation instance collisions fail closed' => sub {
    assert_lower_rejected(<<'ISF', 'generated do and spawn instance collision', qr/duplicate generated child instance 'parent_child_do_0'/);
(actor generated_do_instance_conflict
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (do child)
    (spawn child as w0)
    (spawn other as parent_child_do_0)
    (await_all done)
    (complete done))
  (transaction child
    (complete done))
  (transaction other
    (complete done)))
ISF
};

done_testing();
