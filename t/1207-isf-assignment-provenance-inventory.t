#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

my $source = <<'ISF';
(actor assignment_provenance
  (clock clk)
  (interface
    (input start)
    (input ready)
    (output done)
    (output valid))
  (drive set_valid
    (valid 1))
  (transaction main
    (on start)
    (drive set_valid)
    (complete done))
  (rule always_ready ready
    (valid 1)
    (trigger main)))
ISF

my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'assignment-provenance.isf');
my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);

ok(ref($ir->{assignment_provenance}) eq 'ARRAY', 'lowered IR exposes assignment provenance records');
ok(@{$ir->{assignment_provenance}} >= 6, 'provenance inventory covers state and DT assignments');

for my $record (@{$ir->{assignment_provenance}}) {
    for my $key (qw(owner owner_kind source_kind target operator rhs domain activation assignment_index)) {
        ok(exists $record->{$key}, "provenance record carries $key");
    }
}

my $drive_start = find_record(
    $ir,
    target      => 'set_valid_start',
    source_kind => 'drive_call_start',
);
is($drive_start->{owner}, 'main', 'drive call start is owned by the transaction state');
is($drive_start->{owner_kind}, 'transaction', 'drive call start owner kind is transaction');
is($drive_start->{operator}, '=', 'drive call start is combinational');
is($drive_start->{domain}, 'request', 'drive call start is classified as request fan-in domain');
is($drive_start->{activation}{container_kind}, 'state', 'drive call start activation points to a state');

my $complete = find_record(
    $ir,
    target      => 'done',
    source_kind => 'complete_pulse',
);
is($complete->{owner}, 'main', 'complete pulse is owned by the transaction');
is($complete->{operator}, '<1', 'complete pulse keeps delayed-pulse operator');
is($complete->{domain}, 'pulse', 'complete pulse is classified as pulse domain');
is($complete->{activation}{state_kind}, 'terminal', 'complete pulse activation records terminal state kind');

my $rule_action = find_record(
    $ir,
    target      => 'valid',
    source_kind => 'rule_action',
);
is($rule_action->{owner}, 'always_ready', 'rule action is owned by the rule');
is($rule_action->{owner_kind}, 'rule', 'rule action owner kind is rule');
is($rule_action->{operator}, '<-', 'rule action keeps flopped assignment operator');
is($rule_action->{domain}, 'data', 'rule action is classified as data domain');
is_deeply($rule_action->{activation}{dte_guard}, { port => 'ready' }, 'rule action activation records rule DTE guard');

my $rule_trigger = find_record(
    $ir,
    target      => 'always_ready_main',
    source_kind => 'rule_trigger_source',
);
is($rule_trigger->{owner}, 'always_ready', 'rule trigger source keeps rule ownership');
is($rule_trigger->{operator}, '<1', 'rule trigger source is a delayed pulse');
is($rule_trigger->{domain}, 'pulse', 'rule trigger source is classified as pulse domain');

my $fanin = find_record(
    $ir,
    target      => 'main_start',
    source_kind => 'rule_trigger_fanin',
);
is($fanin->{owner}, 'main', 'rule trigger fan-in is associated with the target transaction');
is($fanin->{owner_kind}, 'transaction', 'rule trigger fan-in owner kind is transaction');
is($fanin->{operator}, '=', 'rule trigger fan-in remains combinational');
is($fanin->{domain}, 'request', 'rule trigger fan-in is classified as request domain');

my $drive_body = find_record(
    $ir,
    target      => 'valid',
    source_kind => 'drive_body',
);
is($drive_body->{owner}, 'set_valid', 'drive body is owned by the named drive');
is($drive_body->{owner_kind}, 'drive', 'drive body owner kind is drive');
is($drive_body->{domain}, 'data', 'drive body is classified as data domain');
is_deeply($drive_body->{activation}{assignment_guard}, { port => 'set_valid_start' }, 'drive body activation records assignment guard');

my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'assignment_provenance.fsm'};
like($fsm, qr/\(-main_trigger_fanin\s+\(= \(main_start always_ready_main\)\)\s+\)/s, 'scheduled .fsm still emits existing rule trigger fan-in shape');
like($fsm, qr/\(-set_valid\s+\(<- \(valid 1\) <set_valid_start\)\s+\)/s, 'scheduled .fsm still emits existing drive body shape');

done_testing();

sub find_record {
    my ($ir, %want) = @_;
    RECORD:
    for my $record (@{$ir->{assignment_provenance} || []}) {
        for my $key (sort keys %want) {
            next RECORD unless defined($record->{$key}) && $record->{$key} eq $want{$key};
        }
        return $record;
    }
    fail('found provenance record for ' . join(', ', map { "$_=$want{$_}" } sort keys %want));
    return {};
}
