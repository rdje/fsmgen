#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Plan;
use FSM::Composition::SharedDatapathSupport;

subtest 'shared-datapath plan storage owns augmented candidate metadata' => sub {
    my $plan = FSM::Composition::Plan->new(
        lane => 'C2',
        top_name => 'shared_datapath_storage_audit',
        ports => [],
        instances => [],
    );

    my $candidates = [
        {
            signal_name => 'status_bus',
            aggregate_target_enable_signal => 'status_bus_shared_en',
            multi_value_conflict_signal => 'status_bus_multi_value_conflict',
            multi_value_assertion => {
                kind => 'onehot0',
                input_enable_signals => [],
            },
            aggregate_enable_families => [],
            metadata => {
                contexts => ['candidate_builder'],
            },
        },
    ];

    FSM::Composition::SharedDatapathSupport->augment_plan(
        composition_plan => $plan,
        shared_datapath_candidates => $candidates,
        target_language => 'systemverilog',
    );

    push @{$candidates->[0]{metadata}{contexts}}, 'mutated_after_augment';
    $candidates->[0]{multi_value_assertion}{kind} = 'mutated_assertion';

    is_deeply(
        $plan->shared_datapath_candidates,
        [
            {
                signal_name => 'status_bus',
                aggregate_target_enable_signal => 'status_bus_shared_en',
                multi_value_conflict_signal => 'status_bus_multi_value_conflict',
                multi_value_assertion => {
                    kind => 'onehot0',
                    input_enable_signals => [],
                },
                aggregate_enable_families => [],
                metadata => {
                    contexts => ['candidate_builder'],
                },
            },
        ],
        'mutating caller-owned candidates after augmentation cannot contaminate plan-stored candidate metadata',
    );
};

done_testing();
