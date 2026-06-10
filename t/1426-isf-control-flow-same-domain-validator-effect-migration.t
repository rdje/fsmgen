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

subtest 'same-domain local do target is proven by the effect checker and still lowers' => sub {
    my $actor = parse_actor(<<'ISF', 'same-domain-local-do-validator');
(actor same_domain_local_do_validator
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default))
  (interface
    (input start (domain core))
    (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (do worker)
    (complete done))
  (transaction worker
    (domain core)
    (complete done)))
ISF

    my $check = check_actor($actor);
    my $tx = transaction_check($check, 'parent');
    my $same = proof($tx, 'activation_target_is_same_domain');
    ok($same, 'effect checker proves the local do target is same-domain');
    is($same->{caller_domain}, 'core', 'proof records caller domain');
    is($same->{child_domain}, 'core', 'proof records child domain');

    my ($lowered, $err) = lower_result($actor);
    ok($lowered, 'public lowering still accepts same-domain local do') or diag($err);
};

subtest 'same-domain spawn target is proven and still lowers with an explicit drain' => sub {
    my $actor = parse_actor(<<'ISF', 'same-domain-spawn-validator');
(actor same_domain_spawn_validator
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default))
  (interface
    (input start (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (repeat loops
      (spawn worker as w0
        (domain core))
      (await_all done))
    (complete done))
  (transaction worker
    (domain core)
    (complete done)))
ISF

    my $check = check_actor($actor);
    my $tx = transaction_check($check, 'parent');
    ok(proof($tx, 'activation_target_is_same_domain'),
        'effect checker proves the spawn target is same-domain');
    ok(proof($tx, 'activation_domain_is_explicit'),
        'effect checker separately proves same-domain activation metadata');

    my ($lowered, $err) = lower_result($actor);
    ok($lowered, 'public lowering still accepts same-domain drained spawn') or diag($err);
};

subtest 'same-domain target proof does not hide mismatched activation-domain metadata' => sub {
    my $actor = parse_actor(<<'ISF', 'same-domain-target-mismatched-activation-domain');
(actor same_domain_target_mismatched_activation_domain
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input start (domain core))
    (input din (width 8) (domain core))
    (output done (domain core))
    (output result (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (do worker
      (params (W 8))
      (bind (input data din) (output data_out result))
      (domain bus))
    (complete done))
  (transaction worker
    (domain core)
    (params (W 8))
    (ports (input data (width W)) (output data_out (width W)))
    (on start)
    (update data_out data)
    (complete done)))
ISF

    my $check = check_actor($actor);
    my $tx = transaction_check($check, 'parent');
    ok(proof($tx, 'activation_target_is_same_domain'),
        'target proof exists because the child transaction is in the caller domain');
    ok(violation($tx, 'activation_domain_metadata_must_match_caller'),
        'effect checker records the mismatched activation-domain metadata');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects mismatched activation-domain metadata');
    like($err, qr/clock-domain violation: transaction 'parent' do instance domain 'bus' references activation in domain 'bus' from domain 'core'/,
        'existing activation-domain diagnostic remains stable');
};

subtest 'cross-domain do without a crossing still falls back to the existing target diagnostic' => sub {
    my $actor = parse_actor(<<'ISF', 'same-domain-validator-cross-domain-miss');
(actor same_domain_validator_cross_domain_miss
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
    ok(!proof($tx, 'activation_target_is_same_domain'),
        'effect checker does not prove same-domain for a cross-domain target');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects cross-domain do without crossing');
    like($err, qr/clock-domain violation.*do target 'worker'.*domain 'bus'.*domain 'core'/s,
        'existing target-domain diagnostic remains stable');
};

done_testing();
