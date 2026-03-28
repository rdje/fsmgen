#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport;

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

    sub render_intermediate_signal_expression ($self, $signal_name, $signal_info) {
        return $signal_info->{rendered_expression};
    }
}

{
    package Local::FakeFilterSupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless {}, $class;
    }

    sub should_filter_consolidated_signal ($self, $expression, $signal_name, $signal_info) {
        return $signal_info->{should_filter} ? 1 : 0;
    }
}

subtest 'consolidated intermediate planning support rebuilds dependency-aware rescue and ordering from normalized metadata' => sub {
    my $fake_backend = {
        backend_sv_intermediate_recovery_support => Local::FakeRecoverySupport->new(),
        backend_sv_intermediate_support => Local::FakeFilterSupport->new(),
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
