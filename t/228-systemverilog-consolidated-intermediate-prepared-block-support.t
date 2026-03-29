#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport;

subtest 'prepared block support owns prepared consolidated block projection and summary contract' => sub {
    my $fake_backend = {};
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport->new(
        flattened_dt => $fake_backend,
    );

    my $all_intermediate_signals = {
        shared_term => {
            rendered_expression => 'A | B',
        },
        dependent_term => {
            rendered_expression => 'shared_term & C',
        },
    };
    my $plan = {
        signal_dependencies => {
            dependent_term => ['shared_term'],
        },
        filtered_signals => {
            shared_term => $all_intermediate_signals->{shared_term},
            dependent_term => $all_intermediate_signals->{dependent_term},
        },
        finally_filtered_signals => {},
        rescued_signals => {},
        sorted_signals => ['shared_term', 'dependent_term'],
        total_kept_count => 2,
        filtered_count => 0,
        rescued_count => 0,
    };

    my $prepared_block = $support->build_prepared_consolidated_intermediate_block(
        $all_intermediate_signals,
        $plan,
    );

    is_deeply(
        $prepared_block,
        {
            all_intermediate_signals => $all_intermediate_signals,
            %{$plan},
        },
        'prepared block support projects the full prepared block contract from explicit collection and plan inputs',
    );
};

done_testing();
