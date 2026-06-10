#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::ControlFlowEffects;

sub parse_actor {
    my ($source, $name) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$name.isf");
}

sub check_actor {
    my ($actor) = @_;
    return FSM::Scheduler::ISF::ControlFlowEffects->new()->check_actor($actor);
}

sub transaction_check {
    my ($check, $name) = @_;
    my ($tx) = grep { $_->{name} eq $name } @{$check->{transactions} || []};
    return $tx;
}

sub proof {
    my ($tx, $code) = @_;
    my ($proof) = grep { ($_->{code} // '') eq $code } @{$tx->{proofs} || []};
    return $proof;
}

sub violation {
    my ($tx, $code) = @_;
    my ($violation) = grep { ($_->{code} // '') eq $code } @{$tx->{violations} || []};
    return $violation;
}

sub lower_result {
    my ($actor) = @_;
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    return ($lowered, $@);
}

subtest 'covered cross-domain do is admitted through the effect-checker crossing proof' => sub {
    my $actor = parse_actor(<<'ISF', 'validator-covered-cross-domain');
(actor validator_covered_cross_domain
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (crossings
    (activation worker (from core) (to bus)))
  (interface
    (input start (domain core))
    (output done (domain core))
    (input din (width 8) (domain bus))
    (output result (width 8) (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (do worker)
    (complete done))
  (transaction worker
    (domain bus)
    (sample din as snap)
    (update result snap)
    (complete result)))
ISF

    my $check = check_actor($actor);
    my $tx = transaction_check($check, 'parent');
    my $crossing = proof($tx, 'activation_crossing_covers_child_start');
    ok($crossing, 'effect checker proves the activation crossing covers the child start');
    is($crossing->{caller_domain}, 'core', 'proof records caller domain');
    is($crossing->{child_domain}, 'bus', 'proof records child domain');

    my ($lowered, $err) = lower_result($actor);
    ok($lowered, 'public lowering still accepts the covered cross-domain activation') or diag($err);
};

subtest 'uncovered cross-domain do still fails closed with the existing diagnostic' => sub {
    my $actor = parse_actor(<<'ISF', 'validator-uncovered-cross-domain');
(actor validator_uncovered_cross_domain
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input start (domain core))
    (output done (domain core))
    (output worker_done (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (do worker)
    (complete done))
  (transaction worker
    (domain bus)
    (complete worker_done)))
ISF

    my $check = check_actor($actor);
    my $tx = transaction_check($check, 'parent');
    ok(violation($tx, 'cross_domain_activation_requires_activation_crossing'),
        'effect checker records the missing activation crossing');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects the uncovered cross-domain activation');
    like($err, qr/clock-domain violation.*do target 'worker'.*domain 'bus'.*domain 'core'/s,
        'existing public clock-domain diagnostic is stable');
};

subtest 'deeper covered-looking cross-domain do remains stopped by the existing placement gate' => sub {
    my $actor = parse_actor(<<'ISF', 'validator-deeper-cross-domain');
(actor validator_deeper_cross_domain
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (crossings
    (activation worker (from core) (to bus)))
  (interface
    (input start (domain core))
    (input cond (domain core))
    (input n (width 3) (domain core))
    (output done (domain core))
    (output worker_done (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (repeat n
      (when cond
        (do worker)))
    (complete done))
  (transaction worker
    (domain bus)
    (complete worker_done)))
ISF

    my $check = check_actor($actor);
    my $tx = transaction_check($check, 'parent');
    ok(proof($tx, 'activation_crossing_covers_child_start'),
        'effect checker can see the declared crossing contract');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects the deeper unsupported placement');
    like(
        $err,
        qr/used by a nested '\(do worker\)' \(inside a when body\)[\s\S]*nested cross-domain activation remains deferred/,
        'existing nested-placement diagnostic remains stable',
    );
};

subtest 'cross-domain spawn is not inferred as an activation crossing' => sub {
    my $actor = parse_actor(<<'ISF', 'validator-cross-domain-spawn');
(actor validator_cross_domain_spawn
  (clock-domains
    (domain core (clock clk) :default)
    (domain bus (clock bus_clk)))
  (interface
    (input start (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core))
    (output worker_done (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (repeat loops
      (spawn worker as w0
        (domain bus))
      (await_all done))
    (complete done))
  (transaction worker
    (domain bus)
    (complete worker_done)))
ISF

    my $check = check_actor($actor);
    my $tx = transaction_check($check, 'parent');
    ok(violation($tx, 'cross_domain_spawn_requires_future_cdc_contract'),
        'effect checker keeps cross-domain spawn fail-closed');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects cross-domain spawn');
    like($err, qr/clock-domain violation: transaction 'parent' spawn target 'worker' references transaction in domain 'bus' from domain 'core'/,
        'existing public cross-domain spawn diagnostic is stable');
};

done_testing();
