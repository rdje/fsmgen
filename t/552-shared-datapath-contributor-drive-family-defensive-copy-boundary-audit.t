#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::SharedDatapathCandidateBuilder;

sub output_drive_family {
    return {
        multiplexer_type => 'flop',
        reset_value => "8'h00",
        rhs_enable_families => [
            {
                rhs_value => "8'h01",
                family_enable_signal => 'shared_data_eq_01',
                driver_blocks => ['-drive_a'],
                driver_enable_signals => ['drive_a_en'],
            },
        ],
    };
}

subtest 'contributor_output_drive_family returns caller-owned output-drive metadata' => sub {
    my $contributor = {
        endpoint => 'a.shared_data',
        output_drive_family => output_drive_family(),
    };

    my $family = FSM::Composition::SharedDatapathCandidateBuilder->contributor_output_drive_family(
        $contributor,
    );
    $family->{rhs_enable_families}[0]{driver_blocks}[0] = 'mutated_block';
    push @{$family->{rhs_enable_families}}, {
        rhs_value => "8'hff",
        family_enable_signal => 'late',
    };

    is_deeply(
        $contributor->{output_drive_family},
        output_drive_family(),
        'output-drive family result mutation cannot contaminate contributor metadata',
    );
};

subtest 'contributor_output_drive_family fallback drive_intent is also cloned' => sub {
    my $contributor = {
        endpoint => 'legacy.shared_data',
        drive_intent => output_drive_family(),
    };

    my $family = FSM::Composition::SharedDatapathCandidateBuilder->contributor_output_drive_family(
        $contributor,
    );
    $family->{rhs_enable_families}[0]{driver_enable_signals}[0] = 'mutated_enable';

    is_deeply(
        $contributor->{drive_intent},
        output_drive_family(),
        'drive-intent fallback mutation cannot contaminate contributor metadata',
    );
};

subtest 'drive_intent_from_output_drive_family remains a caller-owned projection' => sub {
    my $source = output_drive_family();
    my $intent = FSM::Composition::SharedDatapathCandidateBuilder->drive_intent_from_output_drive_family(
        $source,
    );

    $intent->{rhs_enable_families}[0]{driver_blocks}[0] = 'mutated_projection';
    is_deeply(
        $source,
        output_drive_family(),
        'drive-intent projection mutation cannot contaminate source drive family',
    );
};

done_testing();
