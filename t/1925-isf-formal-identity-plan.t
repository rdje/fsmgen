#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalIdentityPlan;

my $planner = 'FSM::Scheduler::ISF::FormalIdentityPlan';
my $actor = FSM::Adapter::ISF->new->parse_source(<<'ISF', 'formal_plan.isf');
(actor formal_plan
 (clock clk) (reset (rst_n async active_low))
 (types (type owner_t (signed (bits 8))) (type local_t (signed (bits 4))))
 (interface (input start) (input isf_port_first_status) (output done))
 (storage (var status (type owner_t) (reset 19)))
 (transaction first (ports (input status (type local_t))) (on start) (complete done))
 (transaction second (ports (output status (width 4))) (on start) (set status 5) (complete done))
 (transaction child (ports (input status (width 2))) (on start) (complete done))
 (transaction empty (on start) (complete done)))
ISF
my $reserved = {ISF_PORT_FIRST_STATUS_FORMAL => 1, isf_port_second_status => 1};
my $generated = {child => 1};
my $before = dclone($actor);
my $plan = $planner->build($actor, generated_children => $generated, reserved_names => $reserved);
is_deeply($actor, $before, 'planning preserves source actor and every declaration');
is_deeply($reserved, {ISF_PORT_FIRST_STATUS_FORMAL => 1, isf_port_second_status => 1}, 'caller reservation set is unchanged');
is_deeply($generated, {child => 1}, 'generated placement set is unchanged');

my $first = $planner->lookup($plan, 'first', 'status');
my $second = $planner->lookup($plan, 'second', 'status');
my $child = $planner->lookup($plan, 'child', 'status');
is_deeply($first->{identity}, ['transaction_port', 'formal_plan', 'first', 'status'], 'formal identity includes its scope');
isnt($first->{physical_name}, $second->{physical_name}, 'sibling formals get different private identities');
isnt($first->{physical_name}, 'status', 'actor storage name is preserved separately');
isnt(lc($first->{physical_name}), 'isf_port_first_status_formal', 'case-folded reserved generated name avoided');
isnt($first->{physical_name}, 'isf_port_first_status', 'authored generated-looking input avoided');
isnt($second->{physical_name}, 'isf_port_second_status', 'additional physical reservation avoided');
is($first->{declaration}{width}, 4, 'formal resolved width retained');
is($first->{declaration}{type}, 'local_t', 'formal type retained independently of actor type');
ok(!exists $first->{declaration}{reset_value}, 'actor reset does not enter the formal declaration');
is_deeply($first->{declaration}, $actor->{transactions}[0]{ports}{inputs}[0], 'complete formal declaration preserved');
is($first->{direction}, 'input', 'input role preserved');
is($second->{direction}, 'output', 'output role preserved');
is($child->{placement}, 'generated_child_interface', 'generated child placement remains explicit');
is($child->{physical_name}, 'status', 'generated child public port is not renamed');
is_deeply($plan->{formals}{empty}, {}, 'transaction without formals has an empty scope');
ok(!defined $planner->lookup($plan, 'empty', 'status'), 'lookup never borrows a sibling formal');
ok(!defined $planner->lookup($plan, 'first', 'start'), 'actor signal is not falsely classified as a formal');

my $reordered = dclone($actor);
@{$reordered->{transactions}} = reverse @{$reordered->{transactions}};
is_deeply($planner->build($reordered, generated_children => $generated, reserved_names => $reserved),
    $plan, 'declaration permutation does not alter private-name allocation');
$first->{declaration}{width} = 99;
is($planner->lookup($plan, 'first', 'status')->{declaration}{width}, 4, 'lookup returns a detached value');
$plan->{formals}{first}{status}{declaration}{type_spec}{kind} = 'changed';
is_deeply($actor, $before, 'nested plan metadata cannot mutate source declarations');

subtest 'ambiguous concatenated spellings retain distinct structured identities' => sub {
    my $source = {actor_name => 'm', transactions => [
        {name => 'a_b', ports => {inputs => [{name => 'c', width => 1}]}},
        {name => 'a', ports => {inputs => [{name => 'b_c', width => 1}]}},
    ]};
    my $p = $planner->build($source, generated_children => {}, reserved_names => {});
    isnt($p->{formals}{a_b}{c}{physical_name}, $p->{formals}{a}{b_c}{physical_name}, 'allocator resolves concatenation collision');
    is_deeply($p->{formals}{a_b}{c}{identity}, ['transaction_port', 'm', 'a_b', 'c'], 'tuple does not depend on physical spelling');
};

for my $case (
    ['duplicate owner', sub {push @{$_[0]{transactions}}, dclone($_[0]{transactions}[0])}, qr/duplicate transaction/],
    ['invalid owner', sub {$_[0]{transactions}[0]{name} = []}, qr/without a scalar identifier/],
    ['duplicate formal', sub {push @{$_[0]{transactions}[0]{ports}{outputs}}, dclone($_[0]{transactions}[0]{ports}{inputs}[0])}, qr/duplicate formal/],
    ['invalid formal', sub {$_[0]{transactions}[0]{ports}{inputs}[0]{name} = 'x.y'}, qr/without a scalar identifier/],
    ['unknown direction', sub {$_[0]{transactions}[0]{ports}{inout} = []}, qr/malformed formal declarations/],
    ['invalid declaration list', sub {$_[0]{transactions}[0]{ports}{inputs} = {}}, qr/malformed inputs declarations/],
    ['unsupported metadata reference', sub {$_[0]{transactions}[0]{ports}{inputs}[0]{type_spec} = sub {}}, qr/unsupported reference/],
) {
    my $bad = dclone($actor);
    $case->[1]->($bad);
    eval {$planner->build($bad, generated_children => $generated, reserved_names => $reserved)};
    like($@, $case->[2], "$case->[0] rejected");
}
for my $case (
    [{generated_children => {}}, qr/explicit reserved_names/],
    [{generated_children => {unknown => 1}, reserved_names => {}}, qr/unknown generated transaction/],
    [{generated_children => {}, reserved_names => {'bad.name' => 1}}, qr/non-identifier/],
    [{generated_children => {}, reserved_names => {}, typo => 1}, qr/unknown option/],
) {
    eval {$planner->build($actor, %{$case->[0]})};
    like($@, $case->[1], 'malformed planner context rejected');
}
eval {$planner->lookup($plan, 'absent', 'status')};
like($@, qr/unknown transaction/, 'unknown lookup owner rejected');

# Production now applies the qualified planner/resolver before merging storage.
my $production = FSM::Scheduler::ISF->new->lower($actor);
my ($carrier) = values %{$production->{files}};
like($carrier, qr/\(isf_port_\w+_status\w* 4(?:\s|\))/, 'production emits a distinct private formal');
done_testing;
