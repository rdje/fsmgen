#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDependencySupport;

{
    package Local::FakeRecoverySupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless {}, $class;
    }

    sub resolve_intermediate_signal_dependencies ($self, $signal_name, $signal_info) {
        return @{ $signal_info->{dependency_signal_names} || [] };
    }
}

subtest 'consolidated intermediate dependency support owns dependency-map construction and dependency-safe ordering' => sub {
    my $fake_backend = {
        backend_sv_intermediate_recovery_support => Local::FakeRecoverySupport->new(),
    };
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDependencySupport->new(
        flattened_dt => $fake_backend,
    );

    my $all_intermediate_signals = {
        kept_parent => {
            dependency_signal_names => ['rescued_dep'],
        },
        rescued_dep => {
            dependency_signal_names => [],
        },
        cycle_a => {
            dependency_signal_names => ['cycle_b'],
        },
        cycle_b => {
            dependency_signal_names => ['cycle_a'],
        },
    };

    my $signal_dependencies = $support->build_signal_dependencies($all_intermediate_signals);

    is_deeply(
        $signal_dependencies,
        {
            kept_parent => ['rescued_dep'],
            cycle_a => ['cycle_b'],
            cycle_b => ['cycle_a'],
        },
        'dependency support builds the dependency map from normalized metadata via recovery support',
    );

    my @sorted_signals = $support->topologically_sort_signals(
        {
            rescued_dep => $all_intermediate_signals->{rescued_dep},
            kept_parent => $all_intermediate_signals->{kept_parent},
            cycle_a => $all_intermediate_signals->{cycle_a},
            cycle_b => $all_intermediate_signals->{cycle_b},
        },
        $signal_dependencies,
    );

    is_deeply(
        \@sorted_signals,
        ['rescued_dep', 'kept_parent', 'cycle_a', 'cycle_b'],
        'dependency support keeps dependency-safe ordering where possible and appends alphabetical cycle fallback afterward',
    );
};

done_testing();
