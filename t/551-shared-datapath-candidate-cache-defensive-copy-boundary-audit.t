#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Plan;
use FSM::Composition::SharedDatapathCandidateBuilder;

sub expected_candidates {
    return [
        {
            signal_name => 'shared_data',
            contributors => [
                {
                    endpoint => 'a.shared_data',
                    output_drive_family => {
                        rhs_enable_families => [
                            {
                                rhs_value => "8'h01",
                                driver_blocks => ['-drive_a'],
                            },
                        ],
                    },
                },
            ],
            aggregate_enable_families => [
                {
                    rhs_value => "8'h01",
                    contributors => [
                        {
                            endpoint => 'a.shared_data',
                            driver_blocks => ['-drive_a'],
                        },
                    ],
                },
            ],
        },
    ];
}

subtest 'freshly built candidates are cached and returned through separate owned containers' => sub {
    my $plan = FSM::Composition::Plan->new(
        lane => 'C3',
        top_name => 'top',
        shared_datapath_candidates => [],
    );

    my $build_count = 0;
    {
        no warnings 'redefine';
        local *FSM::Composition::SharedDatapathCandidateBuilder::build_candidates = sub {
            $build_count++;
            return expected_candidates();
        };

        my $first = FSM::Composition::SharedDatapathCandidateBuilder->candidates_for_plan(
            composition_plan => $plan,
        );

        $first->[0]{contributors}[0]{output_drive_family}{rhs_enable_families}[0]{driver_blocks}[0]
            = 'mutated_return';
        push @{$first->[0]{aggregate_enable_families}[0]{contributors}}, {
            endpoint => 'late.shared_data',
            driver_blocks => ['late'],
        };

        is_deeply(
            $plan->shared_datapath_candidates,
            expected_candidates(),
            'mutating freshly returned candidates cannot contaminate plan cache',
        );

        my $second = FSM::Composition::SharedDatapathCandidateBuilder->candidates_for_plan(
            composition_plan => $plan,
        );
        is($build_count, 1, 'second lookup uses the cached plan candidates');
        is_deeply($second, expected_candidates(), 'cached lookup returns the unmutated candidate payload');

        $second->[0]{contributors}[0]{endpoint} = 'mutated_cached_return';
        is_deeply(
            $plan->shared_datapath_candidates,
            expected_candidates(),
            'mutating cached lookup result cannot contaminate plan cache',
        );
    }
};

done_testing();
