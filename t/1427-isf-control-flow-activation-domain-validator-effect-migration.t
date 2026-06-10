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
use FSM::Scheduler::ISF::LoweringIR ();

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

sub proof_for_domain {
    my ($tx, $child, $domain) = @_;
    my ($proof) = grep {
        ($_->{code} // '') eq 'activation_domain_is_explicit'
            && ($_->{child} // '') eq $child
            && ($_->{domain} // '') eq $domain
    } @{$tx->{proofs} || []};
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

sub lower_result_with_legacy_activation_domain_guard {
    my ($actor, $domain) = @_;
    my $original = \&FSM::Scheduler::ISF::LoweringIR::_validate_same_domain_target;
    my ($lowered, $err);
    {
        no warnings 'redefine';
        local *FSM::Scheduler::ISF::LoweringIR::_validate_same_domain_target = sub {
            my ($context, @rest) = @_;
            die "legacy activation-domain validator reached for $context\n"
                if $context =~ / instance domain '\Q$domain\E'/;
            return $original->($context, @rest);
        };
        ($lowered, $err) = lower_result($actor);
    }
    return ($lowered, $err);
}

subtest 'same-domain do metadata is admitted through the effect-checker proof' => sub {
    my $actor = parse_actor(<<'ISF', 'activation-domain-do-validator');
(actor activation_domain_do_validator
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default))
  (interface
    (input start (domain core))
    (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (do worker
      (domain core))
    (complete done))
  (transaction worker
    (domain core)
    (complete done)))
ISF

    my $check = check_actor($actor);
    my $tx = transaction_check($check, 'parent');
    ok(proof_for_domain($tx, 'worker', 'core'),
        'effect checker proves the authored activation domain is explicit and same-domain');

    my ($lowered, $err) = lower_result_with_legacy_activation_domain_guard($actor, 'core');
    ok($lowered, 'public lowering accepts without reaching the legacy activation-domain validator') or diag($err);
};

subtest 'same-domain spawn metadata is admitted through the effect-checker proof' => sub {
    my $actor = parse_actor(<<'ISF', 'activation-domain-spawn-validator');
(actor activation_domain_spawn_validator
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default))
  (interface
    (input start (domain core))
    (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (repeat 1
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
    ok(proof_for_domain($tx, 'worker', 'core'),
        'effect checker proves explicit same-domain spawn metadata');

    my ($lowered, $err) = lower_result_with_legacy_activation_domain_guard($actor, 'core');
    ok($lowered, 'spawn metadata lowers without reaching the legacy activation-domain validator') or diag($err);
};

subtest 'a good metadata proof for the same child does not hide a mismatched domain' => sub {
    my $actor = parse_actor(<<'ISF', 'activation-domain-specific-proof');
(actor activation_domain_specific_proof
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input start (domain core))
    (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (do worker
      (domain core))
    (do worker
      (domain bus))
    (complete done))
  (transaction worker
    (domain core)
    (complete done)))
ISF

    my $check = check_actor($actor);
    my $tx = transaction_check($check, 'parent');
    ok(proof_for_domain($tx, 'worker', 'core'),
        'effect checker records the good same-domain metadata proof');
    ok(violation($tx, 'activation_domain_metadata_must_match_caller'),
        'effect checker also records the mismatched metadata violation');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects the mismatched metadata site');
    like($err, qr/clock-domain violation: transaction 'parent' do instance domain 'bus' references activation in domain 'bus' from domain 'core'/,
        'existing mismatched metadata diagnostic remains stable');
};

done_testing();
