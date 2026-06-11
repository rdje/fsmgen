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

sub rule_check {
    my ($check, $name) = @_;
    my ($rule) = grep { $_->{name} eq $name } @{$check->{rules} || []};
    return $rule;
}

sub proof {
    my ($rule, $code) = @_;
    my ($proof) = grep { ($_->{code} // '') eq $code } @{$rule->{proofs} || []};
    return $proof;
}

sub violation {
    my ($rule, $code) = @_;
    my ($violation) = grep { ($_->{code} // '') eq $code } @{$rule->{violations} || []};
    return $violation;
}

sub lower_result {
    my ($actor) = @_;
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    return ($lowered, $@);
}

sub lower_result_with_legacy_rule_target_guard {
    my ($actor) = @_;
    my $original = \&FSM::Scheduler::ISF::LoweringIR::_validate_same_domain_target;
    my ($lowered, $err);
    {
        no warnings 'redefine';
        local *FSM::Scheduler::ISF::LoweringIR::_validate_same_domain_target = sub {
            my ($context, @rest) = @_;
            die "legacy rule trigger target validator reached for $context\n"
                if ($context // '') eq "rule 'launch' trigger target 'work'";
            return $original->($context, @rest);
        };
        ($lowered, $err) = lower_result($actor);
    }
    return ($lowered, $err);
}

subtest 'same-domain rule trigger target is admitted through effect proof' => sub {
    my $actor = parse_actor(<<'ISF', 'rule-trigger-target-validator');
(actor rule_trigger_target_validator
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default))
  (interface
    (input fire (domain core))
    (output done (domain core)))
  (rule launch
    (domain core)
    fire
    (trigger work))
  (transaction work
    (domain core)
    (complete done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker accepts same-domain rule trigger target');
    my $rule = rule_check($check, 'launch');
    my $same = proof($rule, 'rule_trigger_target_is_same_domain');
    ok($same, 'effect checker proves the rule trigger target is same-domain');
    is($same->{rule_domain}, 'core', 'proof records rule domain');
    is($same->{target_domain}, 'core', 'proof records target transaction domain');

    my ($lowered, $err) = lower_result_with_legacy_rule_target_guard($actor);
    ok($lowered, 'public lowering accepts without reaching the legacy rule-trigger target validator') or diag($err);
};

subtest 'cross-domain rule trigger target keeps existing diagnostic' => sub {
    my $actor = parse_actor(<<'ISF', 'rule-trigger-target-mismatch');
(actor rule_trigger_target_mismatch
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input fire (domain core))
    (output done (domain bus)))
  (rule launch
    (domain core)
    fire
    (trigger work))
  (transaction work
    (domain bus)
    (complete done)))
ISF

    my $check = check_actor($actor);
    ok(!$check->{ok}, 'effect checker records the cross-domain rule trigger target');
    my $rule = rule_check($check, 'launch');
    my $mismatch = violation($rule, 'rule_trigger_target_domain_mismatch');
    ok($mismatch, 'effect checker emits the rule-trigger target domain violation');
    is($mismatch->{rule_domain}, 'core', 'violation records rule domain');
    is($mismatch->{target_domain}, 'bus', 'violation records target transaction domain');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects the cross-domain rule trigger target');
    like(
        $err,
        qr/clock-domain violation: rule 'launch' trigger target 'work' references transaction in domain 'bus' from domain 'core'/,
        'existing rule-trigger target diagnostic remains stable',
    );
};

done_testing();
