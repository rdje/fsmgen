#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateClassificationSupport;

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

    sub render_intermediate_signal_expression ($self, $signal_name, $signal_info) {
        return $signal_info->{rendered_expression};
    }

    sub resolve_intermediate_signal_runtime_ast ($self, $signal_name, $signal_info) {
        return $signal_info->{runtime_ast};
    }
}

{
    package Local::FakeAST;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless {}, $class;
    }
}

{
    package Local::FakeFilterPolicySupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless {}, $class;
    }

    sub should_filter_ast_based ($self, $ast, $signal_name, $signal_info) {
        return $signal_info->{should_filter} ? 1 : 0;
    }

    sub should_filter_runtime_ast_miss ($self, $signal_name, $signal_info) {
        return $signal_info->{should_filter} ? 1 : 0;
    }
}

subtest 'consolidated intermediate classification support owns the initial AST-first keep/filter partition' => sub {
    my $fake_backend = {
        backend_sv_intermediate_recovery_support => Local::FakeRecoverySupport->new(),
        backend_sv_intermediate_filter_policy_support => Local::FakeFilterPolicySupport->new(),
    };
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateClassificationSupport->new(
        flattened_dt => $fake_backend,
    );

    my $all_intermediate_signals = {
        kept_parent => {
            rendered_expression => 'rescued_dep & A',
            should_filter => 0,
            source => 'ast_factorization',
            runtime_ast => Local::FakeAST->new(),
        },
        rescued_dep => {
            rendered_expression => 'A | B',
            should_filter => 1,
            source => 'ast_factorization',
            runtime_ast => Local::FakeAST->new(),
        },
        filtered_leaf => {
            rendered_expression => '1',
            should_filter => 1,
            source => 'runtime_ast_miss',
        },
        unrendereable_leaf => {
            rendered_expression => '',
            should_filter => 0,
            source => 'runtime_ast_miss',
        },
    };

    my $classification = $support->classify_consolidated_signals($all_intermediate_signals);

    ok(
        exists $classification->{initially_kept_signals}{kept_parent},
        'classification support keeps the AST-backed signal that survives initial filtering',
    );
    ok(
        exists $classification->{initially_filtered_signals}{rescued_dep},
        'classification support filters the AST-backed signal marked for filtering',
    );
    ok(
        exists $classification->{initially_filtered_signals}{filtered_leaf},
        'classification support filters the runtime-AST-miss signal through the fallback path',
    );
    ok(
        !exists $classification->{initially_kept_signals}{unrendereable_leaf},
        'classification support skips signals that have no renderable expression',
    );
    is(
        $classification->{initially_kept_count},
        1,
        'classification support reports the initial kept count',
    );
    is(
        $classification->{initially_filtered_count},
        2,
        'classification support reports the initial filtered count',
    );
};

done_testing();
