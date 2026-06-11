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

sub lower_result_with_legacy_expression_guard {
    my ($actor) = @_;
    my $original = \&FSM::Scheduler::ISF::LoweringIR::_validate_domain_expr_reads;
    my ($lowered, $err);
    {
        no warnings 'redefine';
        local *FSM::Scheduler::ISF::LoweringIR::_validate_domain_expr_reads = sub {
            my (@args) = @_;
            my $context = $args[-1] // '';
            die "legacy input binding expression validator reached for $context\n"
                if $context =~ / input binding '/;
            return $original->(@args);
        };
        ($lowered, $err) = lower_result($actor);
    }
    return ($lowered, $err);
}

subtest 'same-domain input binding expression endpoints are proven by effects' => sub {
    my $actor = parse_actor(<<'ISF', 'binding-expression-endpoints');
(actor binding_expression_endpoints
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default))
  (interface
    (input start (domain core))
    (input req_hi (width 8) (domain core))
    (input req_lo (width 8) (domain core))
    (output done (domain core))
    (output result (width 16) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (do worker
      (params (W 16))
      (bind (input addr (concat req_hi req_lo)) (output data_out result)))
    (complete done))
  (transaction worker
    (domain core)
    (params (W 16))
    (ports (input addr (width W)) (output data_out (width W)))
    (on start)
    (update data_out addr)
    (complete done)))
ISF

    my $check = check_actor($actor);
    my $tx = transaction_check($check, 'parent');
    my $expr_proofs = proofs($tx, 'binding_expression_endpoints_are_same_domain');
    is(scalar(@$expr_proofs), 1, 'effect checker proves expression endpoints are same-domain');
    is_deeply(
        [sort map { $_->{expr} } @{$expr_proofs->[0]{endpoints} || []}],
        [qw(req_hi req_lo)],
        'proof records both expression signal endpoints',
    );

    my ($lowered, $err) = lower_result_with_legacy_expression_guard($actor);
    ok($lowered, 'public lowering accepts without reaching the legacy expression read validator') or diag($err);
};

subtest 'cross-domain input binding expression endpoint keeps the existing diagnostic' => sub {
    my $actor = parse_actor(<<'ISF', 'binding-expression-endpoint-mismatch');
(actor binding_expression_endpoint_mismatch
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (interface
    (input start (domain core))
    (input req_hi (width 8) (domain core))
    (input req_lo (width 8) (domain bus))
    (output done (domain core))
    (output result (width 16) (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (do worker
      (params (W 16))
      (bind (input addr (concat req_hi req_lo)) (output data_out result)))
    (complete done))
  (transaction worker
    (domain core)
    (params (W 16))
    (ports (input addr (width W)) (output data_out (width W)))
    (on start)
    (update data_out addr)
    (complete done)))
ISF

    my $check = check_actor($actor);
    my $tx = transaction_check($check, 'parent');
    my $violations = violations($tx, 'binding_expression_endpoint_domain_mismatch');
    is(scalar(@$violations), 1, 'effect checker records the mismatched expression endpoint');
    is($violations->[0]{endpoint}, 'req_lo', 'violation identifies the cross-domain signal');

    my ($lowered, $err) = lower_result($actor);
    ok(!$lowered, 'public lowering still rejects the mixed-domain expression binding');
    like($err, qr/clock-domain violation: transaction 'parent' do input binding 'addr' read signal 'req_lo' owned by domain 'bus' from domain 'core'/,
        'existing expression binding diagnostic remains stable');
};

done_testing();
