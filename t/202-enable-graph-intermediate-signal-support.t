#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed);
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::FlattenedDT;

{
    package Local::IntermediateSignalExprParser;

    use strict;
    use warnings;

    sub new {
        return bless {}, shift;
    }

    sub parse_expression {
        my ($self, $expression) = @_;

        return FSM::AST::SignalRef->new('mid') if defined($expression) && $expression eq 'mid';
        die "unexpected test expression '$expression'\n";
    }
}

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0);
my $support = $hdl->{enable_graph_intermediate_support};

$hdl->{expr_namer} = Local::IntermediateSignalExprParser->new;
$hdl->{intermediate_signals}{mid} = 'mid';
$hdl->{intermediate_signals}{mid_and_aux_legacy} = {
    name => 'mid_and_aux_legacy',
    source => 'legacy_string_registry',
};
$hdl->{intermediate_signals}{not_mid_and_aux_legacy} = {
    name => 'not_mid_and_aux_legacy',
    source => 'legacy_string_registry',
};

my $mid_ast = $support->get_intermediate_signal_ast('mid');
ok(
    blessed($mid_ast),
    'intermediate-signal support resolves compatibility expressions back to AST',
);
is(
    $mid_ast->to_systemverilog,
    'mid',
    'compatibility-expression AST recovery preserves the rendered signal reference',
);

my $cached_mid_ast = $support->_get_native_intermediate_signal_ast('mid');
ok(
    blessed($cached_mid_ast),
    'intermediate-signal support caches parsed compatibility expressions in the normalized registry',
);

is(
    $support->get_intermediate_signal_expression('mid'),
    'mid',
    'intermediate-signal support renders the recovered defining AST back to expression text',
);

my $dependency_ast = $support->build_dependency_recovery_ast_from_signal_name('not_mid_and_aux_legacy');
ok(
    blessed($dependency_ast),
    'intermediate-signal support rebuilds dependency ASTs from legacy systematic signal names',
);
is_deeply(
    [$hdl->{enable_graph}->extract_intermediate_signals_from_ast($dependency_ast)],
    ['mid_and_aux_legacy'],
    'dependency recovery preserves the direct intermediate dependency instead of expanding transitively',
);

$support->track_ast_intermediate_signals($dependency_ast);
ok(
    exists $hdl->{referenced_intermediate_signals}{mid_and_aux_legacy},
    'intermediate-signal support records referenced intermediate dependencies that still need declarations',
);
ok(
    $hdl->{referenced_intermediate_signals}{mid_and_aux_legacy}{needs_declaration},
    'tracked intermediate dependencies are marked as needing declaration',
);

done_testing();
