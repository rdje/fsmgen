#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSelectionSupport;

{
    package Local::FakeClassificationSupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless {}, $class;
    }

    sub classify_consolidated_signals ($self, $all_intermediate_signals) {
        return {
            initially_kept_signals => {
                kept_parent => $all_intermediate_signals->{kept_parent},
            },
            initially_filtered_signals => {
                rescued_dep => $all_intermediate_signals->{rescued_dep},
                filtered_leaf => $all_intermediate_signals->{filtered_leaf},
            },
            initially_kept_count => 1,
            initially_filtered_count => 2,
        };
    }
}

subtest 'consolidated intermediate selection support owns dependency-aware rescue and final kept/filtered selection' => sub {
    my $fake_backend = {
        backend_sv_consolidated_intermediate_classification_support => Local::FakeClassificationSupport->new(),
    };
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSelectionSupport->new(
        flattened_dt => $fake_backend,
    );

    my $all_intermediate_signals = {
        kept_parent => {
            rendered_expression => 'rescued_dep & A',
            dependency_signal_names => ['rescued_dep'],
            source => 'ast_factorization',
        },
        rescued_dep => {
            rendered_expression => 'A | B',
            dependency_signal_names => [],
            source => 'ast_factorization',
        },
        filtered_leaf => {
            rendered_expression => '1',
            dependency_signal_names => [],
            source => 'runtime_ast_miss',
        },
    };

    my $selection = $support->filter_consolidated_signals(
        $all_intermediate_signals,
        { kept_parent => ['rescued_dep'] },
    );

    ok(
        exists $selection->{filtered_signals}{kept_parent},
        'selection support keeps the parent signal that survived initial filtering',
    );
    ok(
        exists $selection->{filtered_signals}{rescued_dep},
        'selection support rescues a filtered dependency needed by a kept parent signal',
    );
    ok(
        !exists $selection->{filtered_signals}{filtered_leaf},
        'selection support leaves unrelated filtered signals out of the final kept set',
    );
    ok(
        exists $selection->{rescued_signals}{rescued_dep},
        'selection support records the rescued dependency explicitly',
    );
    ok(
        exists $selection->{finally_filtered_signals}{filtered_leaf},
        'selection support records the still-filtered leaf explicitly',
    );
    is(
        $selection->{rescued_count},
        1,
        'selection support reports the rescued dependency count',
    );
    is(
        $selection->{filtered_count},
        1,
        'selection support reports the final filtered count after rescue propagation',
    );
};

done_testing();
