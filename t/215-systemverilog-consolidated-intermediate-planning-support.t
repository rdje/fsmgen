#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport;

{
    package Local::FakeSelectionSupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless {}, $class;
    }

    sub filter_consolidated_signals ($self, $all_intermediate_signals, $signal_dependencies) {
        return {
            filtered_signals => {
                rescued_dep => $all_intermediate_signals->{rescued_dep},
                kept_parent => $all_intermediate_signals->{kept_parent},
            },
            initially_kept_signals => {
                kept_parent => $all_intermediate_signals->{kept_parent},
            },
            initially_filtered_signals => {
                rescued_dep => $all_intermediate_signals->{rescued_dep},
                filtered_leaf => $all_intermediate_signals->{filtered_leaf},
            },
            rescued_signals => {
                rescued_dep => $all_intermediate_signals->{rescued_dep},
            },
            finally_filtered_signals => {
                filtered_leaf => $all_intermediate_signals->{filtered_leaf},
            },
            initially_kept_count => 1,
            rescued_count => 1,
            filtered_count => 1,
            total_kept_count => 2,
        };
    }
}

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

subtest 'consolidated intermediate planning support rebuilds dependency-aware ordering from normalized metadata and delegated selection' => sub {
    my $fake_backend = {
        backend_sv_intermediate_recovery_support => Local::FakeRecoverySupport->new(),
        backend_sv_consolidated_intermediate_selection_support => Local::FakeSelectionSupport->new(),
    };
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport->new(
        flattened_dt => $fake_backend,
    );

    my $all_intermediate_signals = {
        kept_parent => {
            rendered_expression => 'rescued_dep & A',
            dependency_signal_names => ['rescued_dep'],
            should_filter => 0,
            source => 'ast_factorization',
        },
        rescued_dep => {
            rendered_expression => 'A | B',
            dependency_signal_names => [],
            should_filter => 1,
            source => 'ast_factorization',
        },
        filtered_leaf => {
            rendered_expression => '1',
            dependency_signal_names => [],
            should_filter => 1,
            source => 'runtime_ast_miss',
        },
    };

    my $plan = $support->plan_consolidated_intermediate_signals($all_intermediate_signals);

    is_deeply(
        $plan->{signal_dependencies},
        { kept_parent => ['rescued_dep'] },
        'planning support builds the dependency map from normalized metadata',
    );
    ok(
        exists $plan->{filtered_signals}{kept_parent},
        'planning support keeps the parent signal that survived initial filtering',
    );
    ok(
        exists $plan->{filtered_signals}{rescued_dep},
        'planning support rescues a filtered dependency needed by a kept parent signal',
    );
    ok(
        !exists $plan->{filtered_signals}{filtered_leaf},
        'planning support leaves unrelated filtered signals out of the final kept set',
    );
    ok(
        exists $plan->{rescued_signals}{rescued_dep},
        'planning support records the rescued dependency explicitly',
    );
    ok(
        exists $plan->{finally_filtered_signals}{filtered_leaf},
        'planning support records the still-filtered leaf explicitly',
    );
    is(
        $plan->{rescued_count},
        1,
        'planning support reports the rescued dependency count',
    );
    is(
        $plan->{filtered_count},
        1,
        'planning support reports the final filtered count after rescue propagation',
    );
    is_deeply(
        $plan->{sorted_signals},
        ['rescued_dep', 'kept_parent'],
        'planning support orders rescued dependencies ahead of dependent kept signals',
    );
};

done_testing();
