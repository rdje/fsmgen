#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Plan;

sub make_plan_args {
    return (
        lane => 'C3',
        top_name => 'top',
        ports => [
            { name => 'clk', direction => 'input' },
        ],
        links => [
            { source => 'a.out', target => 'b.in' },
        ],
        resolved_links => [
            {
                source => { raw => 'a.out' },
                target => { raw => 'b.in' },
            },
        ],
        nets => [
            { name => 'carrier', targets => ['b.in'] },
        ],
        instances => [
            { instance_name => 'a', port_bindings => [{ port_name => 'out' }] },
        ],
        auxiliary_assignments => [
            'assign b_in = carrier;',
        ],
        shared_datapath_candidates => [
            { result_signal => 'shared_q', contributors => [{ instance_name => 'a' }] },
        ],
        raw_spec => [
            '?top:top',
            ['?ports:io', 'clk'],
        ],
    );
}

sub expected_snapshot {
    return {
        ports => [{ name => 'clk', direction => 'input' }],
        links => [{ source => 'a.out', target => 'b.in' }],
        resolved_links => [{
            source => { raw => 'a.out' },
            target => { raw => 'b.in' },
        }],
        nets => [{ name => 'carrier', targets => ['b.in'] }],
        instances => [{ instance_name => 'a', port_bindings => [{ port_name => 'out' }] }],
        auxiliary_assignments => ['assign b_in = carrier;'],
        shared_datapath_candidates => [
            { result_signal => 'shared_q', contributors => [{ instance_name => 'a' }] },
        ],
        raw_spec => [
            '?top:top',
            ['?ports:io', 'clk'],
        ],
    };
}

sub plan_snapshot {
    my ($plan) = @_;
    return {
        ports => $plan->ports,
        links => $plan->links,
        resolved_links => $plan->resolved_links,
        nets => $plan->nets,
        instances => $plan->instances,
        auxiliary_assignments => $plan->auxiliary_assignments,
        shared_datapath_candidates => $plan->shared_datapath_candidates,
        raw_spec => $plan->raw_spec,
    };
}

subtest 'constructor copies mutable composition plan containers' => sub {
    my %args = make_plan_args();
    my $plan = FSM::Composition::Plan->new(%args);

    $args{ports}[0]{name} = 'mutated';
    push @{$args{links}}, { source => 'late.out', target => 'late.in' };
    $args{resolved_links}[0]{source}{raw} = 'mutated.out';
    push @{$args{nets}[0]{targets}}, 'mutated.in';
    $args{instances}[0]{port_bindings}[0]{port_name} = 'mutated';
    $args{auxiliary_assignments}[0] = 'assign mutated = 1;';
    $args{shared_datapath_candidates}[0]{contributors}[0]{instance_name} = 'mutated';
    $args{raw_spec}[1][1] = 'mutated';

    is_deeply(plan_snapshot($plan), expected_snapshot(), 'plan state is isolated from constructor input mutation');
};

subtest 'accessors return caller-owned composition plan containers' => sub {
    my $plan = FSM::Composition::Plan->new(make_plan_args());

    my $ports = $plan->ports;
    $ports->[0]{name} = 'mutated';
    push @$ports, { name => 'late' };

    my $links = $plan->links;
    $links->[0]{source} = 'mutated.out';

    my $resolved_links = $plan->resolved_links;
    $resolved_links->[0]{source}{raw} = 'mutated.out';

    my $nets = $plan->nets;
    push @{$nets->[0]{targets}}, 'mutated.in';

    my $instances = $plan->instances;
    $instances->[0]{port_bindings}[0]{port_name} = 'mutated';

    my $auxiliary_assignments = $plan->auxiliary_assignments;
    $auxiliary_assignments->[0] = 'assign mutated = 1;';

    my $shared_datapath_candidates = $plan->shared_datapath_candidates;
    $shared_datapath_candidates->[0]{contributors}[0]{instance_name} = 'mutated';

    my $raw_spec = $plan->raw_spec;
    $raw_spec->[1][1] = 'mutated';

    is_deeply(plan_snapshot($plan), expected_snapshot(), 'plan state is isolated from accessor return mutation');
};

done_testing;
