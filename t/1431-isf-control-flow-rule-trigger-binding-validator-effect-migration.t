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

sub proofs {
    my ($rule, $code) = @_;
    return [grep { ($_->{code} // '') eq $code } @{$rule->{proofs} || []}];
}

sub violations {
    my ($rule, $code) = @_;
    return [grep { ($_->{code} // '') eq $code } @{$rule->{violations} || []}];
}

sub lower_result {
    my ($actor) = @_;
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    return ($lowered, $@);
}

sub lower_result_with_legacy_rule_binding_guard {
    my ($actor) = @_;
    my $original_expr = \&FSM::Scheduler::ISF::LoweringIR::_validate_domain_expr_reads;
    my $original_signal = \&FSM::Scheduler::ISF::LoweringIR::_validate_domain_signal_access;
    my ($lowered, $err);
    {
        no warnings 'redefine';
        local *FSM::Scheduler::ISF::LoweringIR::_validate_domain_expr_reads = sub {
            my (@args) = @_;
            my $context = $args[-1] // '';
            die "legacy rule-trigger binding expression validator reached for $context\n"
                if $context =~ /rule 'launch' trigger input binding '/;
            return $original_expr->(@args);
        };
        local *FSM::Scheduler::ISF::LoweringIR::_validate_domain_signal_access = sub {
            my (@args) = @_;
            my $context = $args[-1] // '';
            die "legacy rule-trigger binding signal validator reached for $context\n"
                if $context =~ /rule 'launch' trigger output binding '/;
            return $original_signal->(@args);
        };
        ($lowered, $err) = lower_result($actor);
    }
    return ($lowered, $err);
}

subtest 'same-domain rule trigger bindings are admitted through effect proofs' => sub {
    my $actor = parse_actor(<<'ISF', 'rule-trigger-binding-validator');
(actor rule_trigger_binding_validator
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default))
  (interface
    (input fire (domain core))
    (input req_hi (width 4) (domain core))
    (input req_lo (width 4) (domain core))
    (output done (domain core))
    (output result (width 8) (domain core)))
  (storage
    (var scratch (width 8) (domain core)))
  (rule launch
    (domain core)
    fire
    (trigger worker
      (params (W 8))
      (bind
        (input addr (concat req_hi req_lo))
        (output data result))))
  (transaction worker
    (domain core)
    (params (W 8))
    (ports
      (input addr (width W))
      (output data (width W)))
    (update scratch addr)
    (update data scratch)
    (complete done)))
ISF

    my $check = check_actor($actor);
    ok($check->{ok}, 'effect checker accepts same-domain rule-trigger bindings');
    my $rule = rule_check($check, 'launch');
    is(scalar(@{proofs($rule, 'binding_expression_endpoints_are_same_domain')}), 1,
        'effect checker proves the input expression endpoints are same-domain');
    is(scalar(@{proofs($rule, 'binding_endpoint_is_same_domain')}), 1,
        'effect checker proves the output binding endpoint is same-domain');

    my ($lowered, $err) = lower_result_with_legacy_rule_binding_guard($actor);
    ok($lowered, 'public lowering accepts without reaching legacy rule-trigger binding domain validators') or diag($err);
};

subtest 'cross-domain rule trigger input expression keeps existing diagnostic' => sub {
    my $actor = parse_actor(<<'ISF', 'rule-trigger-input-binding-domain-mismatch');
(actor rule_trigger_input_binding_domain_mismatch
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input fire (domain core))
    (input req_hi (width 4) (domain core))
    (input req_lo (width 4) (domain bus))
    (output done (domain core)))
  (storage
    (var scratch (width 8) (domain core)))
  (rule launch
    (domain core)
    fire
    (trigger worker
      (bind
        (input addr (concat req_hi req_lo)))))
  (transaction worker
    (domain core)
    (ports
      (input addr (width 8)))
    (update scratch addr)
    (complete done)))
ISF

    my $check = check_actor($actor);
    my $rule = rule_check($check, 'launch');
    my $mismatches = violations($rule, 'binding_expression_endpoint_domain_mismatch');
    is(scalar(@$mismatches), 1, 'effect checker records the cross-domain input expression endpoint');
    is($mismatches->[0]{endpoint}, 'req_lo', 'violation identifies the cross-domain expression signal');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects the cross-domain rule-trigger input binding');
    like($err, qr/clock-domain violation: rule 'launch' trigger input binding 'addr' read signal 'req_lo' owned by domain 'bus' from domain 'core'/,
        'existing rule-trigger input binding diagnostic remains stable');
};

subtest 'cross-domain generated rule trigger output binding keeps existing diagnostic' => sub {
    my $actor = parse_actor(<<'ISF', 'rule-trigger-output-binding-domain-mismatch');
(actor rule_trigger_output_binding_domain_mismatch
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input fire (domain core))
    (output done (domain core))
    (output result (width 8) (domain bus)))
  (storage
    (var scratch (width 8) (domain core)))
  (rule launch
    (domain core)
    fire
    (trigger worker
      (params (W 8))
      (bind
        (output data result))))
  (transaction worker
    (domain core)
    (params (W 8))
    (ports
      (output data (width W)))
    (update data scratch)
    (complete done)))
ISF

    my $check = check_actor($actor);
    my $rule = rule_check($check, 'launch');
    is(scalar(@{violations($rule, 'binding_endpoint_domain_mismatch')}), 1,
        'effect checker records the cross-domain generated output binding endpoint');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects the cross-domain generated rule-trigger output binding');
    like($err, qr/clock-domain violation: rule 'launch' trigger output binding 'data' write signal 'result' owned by domain 'bus' from domain 'core'/,
        'existing rule-trigger output binding diagnostic remains stable');
};

done_testing();
