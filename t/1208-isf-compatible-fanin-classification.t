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
(actor compatible_fanin
  (clock clk)
  (interface
    (input start)
    (input kick)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction work
    (on start)
    (complete done))
  (transaction parent
    (on kick)
    (do work)
    (complete done))
  (rule r0 a
    (valid 1)
    (pulse done)
    (trigger work))
  (rule r1 b
    (valid 1)
    (pulse done)
    (trigger work)))
ISF

my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'compatible-fanin.isf');
my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);

ok(ref($ir->{compatible_fanin_groups}) eq 'ARRAY', 'lowered IR exposes compatible fan-in groups');

my $same_valid = find_group(
    $ir,
    kind   => 'same_target_value',
    target => 'valid',
);
is($same_valid->{domain}, 'data', 'same target/value group keeps data domain');
is($same_valid->{operator}, '<-', 'same target/value group keeps assignment operator');
is($same_valid->{rhs}, '1', 'same target/value group keeps canonical RHS');
is_deeply(
    sorted_sources($same_valid),
    ['r0:rule_action:valid', 'r1:rule_action:valid'],
    'same target/value group contains both rule actions',
);

my $request_work = find_group(
    $ir,
    kind   => 'request',
    target => 'work_start',
);
is_deeply(
    sorted_sources($request_work),
    ['parent:do_start:work_start', 'work:rule_trigger_fanin:work_start'],
    'request fan-in group joins direct do start and generated rule trigger fan-in',
);

my $pulse_done = find_group(
    $ir,
    kind   => 'pulse',
    target => 'done',
);
is($pulse_done->{operator}, '<1', 'pulse fan-in group keeps pulse operator');
is($pulse_done->{rhs}, '1', 'pulse fan-in group keeps pulse value');
is_deeply(
    sorted_sources($pulse_done),
    ['parent:complete_pulse:done', 'r0:rule_pulse_action:done', 'r1:rule_pulse_action:done', 'work:complete_pulse:done'],
    'pulse fan-in group contains completion pulses and rule pulse actions',
);

my $trigger_work = find_group(
    $ir,
    kind               => 'rule_trigger_fanin',
    target_transaction => 'work',
);
is($trigger_work->{fanin_target}, 'work_start', 'rule trigger fan-in group names generated start target');
is_deeply(
    sorted_sources($trigger_work),
    ['r0:rule_trigger_source:r0_work', 'r1:rule_trigger_source:r1_work'],
    'rule trigger fan-in group preserves per-rule trigger sources',
);

ok(
    !scalar(grep { ($_->{kind} // '') eq 'same_target_value' && ($_->{target} // '') eq 'can_accept' }
        @{$ir->{compatible_fanin_groups}}),
    'helper can_accept assignments are not classified as compatible same-value fan-in',
);

my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'compatible_fanin.fsm'};
like($fsm, qr/\(-work_trigger_fanin\s+\(= \(work_start \(\| r0_work r1_work\)\)\)\s+\)/s, 'scheduled .fsm keeps existing generated trigger fan-in');

done_testing();

sub find_group {
    my ($ir, %want) = @_;
    GROUP:
    for my $group (@{$ir->{compatible_fanin_groups} || []}) {
        for my $key (sort keys %want) {
            next GROUP unless defined($group->{$key}) && $group->{$key} eq $want{$key};
        }
        return $group;
    }
    fail('found compatible fan-in group for ' . join(', ', map { "$_=$want{$_}" } sort keys %want));
    return {};
}

sub sorted_sources {
    my ($group) = @_;
    return [
        sort
        map { join(':', $_->{owner}, $_->{source_kind}, $_->{target}) }
        @{$group->{sources} || []}
    ];
}
