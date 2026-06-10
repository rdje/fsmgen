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

sub proofs {
    my ($tx, $code) = @_;
    return [grep { ($_->{code} // '') eq $code } @{$tx->{proofs} || []}];
}

sub violations {
    my ($tx, $code) = @_;
    return [grep { ($_->{code} // '') eq $code } @{$tx->{violations} || []}];
}

sub lower_result {
    my ($actor) = @_;
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    return ($lowered, $@);
}

sub lower_result_with_legacy_binding_guard {
    my ($actor) = @_;
    my $original_expr = \&FSM::Scheduler::ISF::LoweringIR::_validate_domain_expr_reads;
    my $original_signal = \&FSM::Scheduler::ISF::LoweringIR::_validate_domain_signal_access;
    my ($lowered, $err);
    {
        no warnings 'redefine';
        local *FSM::Scheduler::ISF::LoweringIR::_validate_domain_expr_reads = sub {
            my (@args) = @_;
            my $context = $args[-1] // '';
            die "legacy binding expression validator reached for $context\n"
                if $context =~ / binding '/;
            return $original_expr->(@args);
        };
        local *FSM::Scheduler::ISF::LoweringIR::_validate_domain_signal_access = sub {
            my (@args) = @_;
            my $context = $args[-1] // '';
            die "legacy binding signal validator reached for $context\n"
                if $context =~ / binding '/;
            return $original_signal->(@args);
        };
        ($lowered, $err) = lower_result($actor);
    }
    return ($lowered, $err);
}

subtest 'same-domain activation bindings are admitted through endpoint proofs' => sub {
    my $actor = parse_actor(<<'ISF', 'binding-endpoint-validator');
(actor binding_endpoint_validator
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default))
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
      (bind (input data din) (output data_out result)))
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
    my $binding_proofs = proofs($tx, 'binding_endpoint_is_same_domain');
    is(scalar(@$binding_proofs), 2, 'effect checker proves both binding endpoints are same-domain');

    my ($lowered, $err) = lower_result_with_legacy_binding_guard($actor);
    ok($lowered, 'public lowering accepts without reaching legacy binding domain validators') or diag($err);
};

subtest 'cross-domain input binding keeps the existing read diagnostic' => sub {
    my $actor = parse_actor(<<'ISF', 'binding-endpoint-input-mismatch');
(actor binding_endpoint_input_mismatch
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input start (domain core))
    (input din (width 8) (domain bus))
    (output done (domain core))
    (output result (width 8) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (do worker
      (params (W 8))
      (bind (input data din) (output data_out result)))
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
    is(scalar(@{violations($tx, 'binding_endpoint_domain_mismatch')}), 1,
        'effect checker records the cross-domain input binding endpoint');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects the cross-domain input binding');
    like($err, qr/clock-domain violation: transaction 'parent' do input binding 'data' read signal 'din' owned by domain 'bus' from domain 'core'/,
        'existing input binding diagnostic remains stable');
};

subtest 'cross-domain output binding keeps the existing write diagnostic' => sub {
    my $actor = parse_actor(<<'ISF', 'binding-endpoint-output-mismatch');
(actor binding_endpoint_output_mismatch
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input start (domain core))
    (input din (width 8) (domain core))
    (output done (domain core))
    (output result (width 8) (domain bus)))
  (transaction parent
    (domain core)
    (on start)
    (do worker
      (params (W 8))
      (bind (input data din) (output data_out result)))
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
    is(scalar(@{violations($tx, 'binding_endpoint_domain_mismatch')}), 1,
        'effect checker records the cross-domain output binding endpoint');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects the cross-domain output binding');
    like($err, qr/clock-domain violation: transaction 'parent' do output binding 'data_out' write signal 'result' owned by domain 'bus' from domain 'core'/,
        'existing output binding diagnostic remains stable');
};

done_testing();
