#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport;

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

    sub resolve_intermediate_signal_runtime_ast ($self, $signal_name, $signal_info) {
        $signal_info->{runtime_ast} = bless({}, 'Local::FakeRuntimeAST');
        $signal_info->{runtime_ast_source} = 'fake_runtime_ast';
        return $signal_info->{runtime_ast};
    }

    sub resolve_intermediate_signal_dependencies ($self, $signal_name, $signal_info) {
        $signal_info->{dependency_signal_names} = [@{ $signal_info->{expected_dependencies} || [] }];
        $signal_info->{dependency_source} = 'fake_dependency_scan';
        return @{ $signal_info->{dependency_signal_names} };
    }

    sub render_intermediate_signal_expression ($self, $signal_name, $signal_info) {
        $signal_info->{rendered_expression} = $signal_info->{expected_expression};
        $signal_info->{rendered_expression_source} = 'fake_render';
        return $signal_info->{rendered_expression};
    }
}

{
    package Local::FakeWidthSupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless {}, $class;
    }

    sub resolve_intermediate_signal_width ($self, $signal_name, $signal_info, $signal_registry = undef) {
        $signal_info->{width} = $signal_info->{expected_width};
        $signal_info->{width_source} = 'fake_width';
        return $signal_info->{width};
    }
}

{
    package Local::FakeFactorizationSupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless { prime_count => 0 }, $class;
    }

    sub prime_intermediate_signal_live_usage ($self, $signals) {
        $self->{prime_count}++;
        return {
            signal_count => scalar(keys %{$signals || {}}),
            referenced_in_substitutions => 1,
            used_in_final_expressions => 1,
        };
    }

    sub resolve_intermediate_signal_live_usage ($self, $signal_name, $signal_info) {
        die 'normalization resolved live usage before bulk preparation'
            unless $self->{prime_count};
        $signal_info->{referenced_in_substitutions} = $signal_info->{expected_referenced_in_substitutions} ? 1 : 0;
        $signal_info->{used_in_final_expressions} = $signal_info->{expected_used_in_final_expressions} ? 1 : 0;
        $signal_info->{live_usage_evidence_state} = $signal_info->{expected_live_usage_state};
        $signal_info->{live_usage_source} = 'fake_live_usage';
        return {
            referenced_in_substitutions => $signal_info->{referenced_in_substitutions},
            used_in_final_expressions => $signal_info->{used_in_final_expressions},
            evidence_state => $signal_info->{live_usage_evidence_state},
            source => $signal_info->{live_usage_source},
        };
    }
}

subtest 'consolidated intermediate normalization support owns runtime metadata normalization over a merged signal set' => sub {
    my $fake_backend = {
        backend_sv_intermediate_recovery_support => Local::FakeRecoverySupport->new(),
        backend_sv_intermediate_width_support => Local::FakeWidthSupport->new(),
        enable_graph_factorization_support => Local::FakeFactorizationSupport->new(),
        intermediate_signals => {
            shared_term => { width => undef, width_source => 'unresolved_factorization_ast' },
            dep_term => { width => undef, width_source => 'unresolved_factorization_ast' },
        },
        ast_factorizer => {
            intermediate_signals => {
                shared_term => { width => undef, width_source => 'unresolved_factorization_ast' },
                dep_term => { width => undef, width_source => 'unresolved_factorization_ast' },
            },
        },
    };
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport->new(
        flattened_dt => $fake_backend,
    );

    my $signals = {
        shared_term => {
            expected_width => 4,
            expected_dependencies => ['dep_term'],
            expected_expression => 'dep_term & DATA',
            expected_referenced_in_substitutions => 1,
            expected_used_in_final_expressions => 0,
            expected_live_usage_state => 'substitutions',
        },
        dep_term => {
            expected_width => 1,
            expected_dependencies => [],
            expected_expression => 'A | B',
            expected_referenced_in_substitutions => 0,
            expected_used_in_final_expressions => 1,
            expected_live_usage_state => 'final_expressions',
        },
    };

    $support->normalize_consolidated_intermediate_metadata($signals);

    is(
        $signals->{shared_term}{runtime_ast_source},
        'fake_runtime_ast',
        'normalization support records the resolved runtime AST source',
    );
    is(
        $signals->{shared_term}{width},
        4,
        'normalization support records the normalized width',
    );
    is(
        $fake_backend->{intermediate_signals}{shared_term}{width},
        4,
        'normalization publishes width to the live backend registry before downstream rendering',
    );
    is(
        $fake_backend->{ast_factorizer}{intermediate_signals}{shared_term}{width_source},
        'fake_width',
        'normalization publishes authoritative width provenance to the factorizer registry',
    );
    is_deeply(
        $signals->{shared_term}{dependency_signal_names},
        ['dep_term'],
        'normalization support records the normalized dependency list',
    );
    is(
        $signals->{shared_term}{rendered_expression},
        'dep_term & DATA',
        'normalization support records the normalized rendered expression',
    );
    is(
        $signals->{shared_term}{live_usage_evidence_state},
        'substitutions',
        'normalization support records the normalized live-usage evidence state',
    );
    is(
        $signals->{shared_term}{live_usage_source},
        'fake_live_usage',
        'normalization support records the normalized live-usage source',
    );
    is(
        $signals->{dep_term}{used_in_final_expressions},
        1,
        'normalization support preserves final-expression live-usage evidence for sibling signals',
    );
    is(
        $fake_backend->{enable_graph_factorization_support}{prime_count},
        1,
        'normalization primes live-usage metadata once before per-signal consumers',
    );
};

done_testing();
