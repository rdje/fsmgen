#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::FlattenedDT;

{
    package Local::CleanableRuntimeExprParser;

    use strict;
    use warnings;

    sub new {
        return bless {}, shift;
    }

    sub parse_expression {
        my ($self, $expression) = @_;

        die "intentional test parse failure for raw compatibility expression\n"
            if !defined($expression) || $expression eq '' || $expression eq ' mid ';

        return FSM::AST::SignalRef->new('mid') if $expression eq 'mid';

        die "unexpected test expression '$expression'\n";
    }
}

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0);
my $backend = $hdl->{backend_sv};

$hdl->{intermediate_signals}{mid} = {
    name => 'mid',
    source => 'legacy_string_registry',
};
$hdl->{intermediate_signals}{aux} = {
    name => 'aux',
    source => 'legacy_string_registry',
};
$hdl->{intermediate_signals}{mid_and_aux} = {
    name => 'mid_and_aux',
    source => 'ast_signal_name',
};
$hdl->{intermediate_signals}{not_mid_and_aux} = {
    name => 'not_mid_and_aux',
    source => 'ast_signal_name',
};

my %ast_named_signal_info = (
    expression => '@@@',
    runtime_ast_miss_reason => 'expression_parse_failed',
);

my @ast_named_dependencies = $backend->extract_intermediate_signals_from_runtime_ast_miss(
    'not_mid_and_aux',
    \%ast_named_signal_info,
    $ast_named_signal_info{expression},
);

is_deeply(
    \@ast_named_dependencies,
    ['mid_and_aux'],
    'AST-named dependency recovery preserves the direct intermediate dependency instead of expanding transitively',
);
is(
    $ast_named_signal_info{dependency_fallback_source},
    'runtime_ast_miss_signal_name_ast',
    'runtime-AST-miss dependency recovery records the signal-name AST fallback source',
);
ok(
    !exists $ast_named_signal_info{runtime_ast},
    'signal-name dependency recovery does not rewrite runtime_ast metadata',
);

$hdl->{intermediate_signals}{mid_and_aux_legacy} = {
    name => 'mid_and_aux_legacy',
    source => 'legacy_string_registry',
};
$hdl->{intermediate_signals}{not_mid_and_aux_legacy} = {
    name => 'not_mid_and_aux_legacy',
    source => 'legacy_string_registry',
};

my %legacy_signal_info = (
    expression => '@@@',
    runtime_ast_miss_reason => 'expression_parse_failed',
);

my @legacy_dependencies = $backend->extract_intermediate_signals_from_runtime_ast_miss(
    'not_mid_and_aux_legacy',
    \%legacy_signal_info,
    $legacy_signal_info{expression},
);

is_deeply(
    \@legacy_dependencies,
    ['mid_and_aux_legacy'],
    'legacy systematic signal names now recover direct dependencies through the signal-name AST path',
);
is(
    $legacy_signal_info{dependency_fallback_source},
    'runtime_ast_miss_signal_name_ast',
    'legacy systematic signal names now record the signal-name AST fallback source',
);
ok(
    !exists $legacy_signal_info{runtime_ast},
    'legacy signal-name AST recovery remains dependency-local and does not rewrite runtime_ast metadata',
);

$hdl->{intermediate_signals}{opaque_legacy_expr} = {
    name => 'opaque_legacy_expr',
    source => 'legacy_string_registry',
};

my %opaque_legacy_signal_info = (
    expression => 'mid @@ aux',
    runtime_ast_miss_reason => 'expression_parse_failed',
);

my @opaque_legacy_dependencies = $backend->extract_intermediate_signals_from_runtime_ast_miss(
    'opaque_legacy_expr',
    \%opaque_legacy_signal_info,
    $opaque_legacy_signal_info{expression},
);

is_deeply(
    \@opaque_legacy_dependencies,
    [],
    'opaque legacy signal names now stay unresolved when no AST-backed dependency recovery can be built',
);
is(
    $opaque_legacy_signal_info{dependency_fallback_source},
    'runtime_ast_miss_unresolved',
    'opaque legacy signal names now record unresolved dependency recovery instead of identifier-scan fallback',
);

$hdl->{expr_namer} = Local::CleanableRuntimeExprParser->new;

my %direct_runtime_parse_signal_info = (
    expression => 'mid',
);

my $direct_runtime_parse_ast = $backend->resolve_intermediate_signal_runtime_ast(
    'direct_runtime_parse_expr',
    \%direct_runtime_parse_signal_info,
);

ok(
    !defined $direct_runtime_parse_ast,
    'runtime-AST resolution no longer parses stored expressions directly without an AST-backed source',
);
is(
    $direct_runtime_parse_signal_info{runtime_ast_resolution_state},
    'missing',
    'stored-expression-only runtime-AST resolution records a missing state',
);
is(
    $direct_runtime_parse_signal_info{runtime_ast_miss_reason},
    'no_ast_source',
    'stored-expression-only runtime-AST resolution now records no_ast_source rather than compatibility parse failure',
);
ok(
    !exists $direct_runtime_parse_signal_info{runtime_ast},
    'stored-expression-only runtime-AST resolution does not synthesize runtime_ast metadata',
);

$hdl->{intermediate_signals}{cleanable_runtime_expr} = ' mid ';

my %cleanable_runtime_signal_info;
my $rendered_cleanable_expression = $backend->render_intermediate_signal_expression(
    'cleanable_runtime_expr',
    \%cleanable_runtime_signal_info,
);

is(
    $rendered_cleanable_expression,
    ' mid ',
    'render-time expression fallback preserves the stored compatibility expression instead of late-promoting runtime_ast',
);
is(
    $cleanable_runtime_signal_info{rendered_expression_source},
    'enable_graph_expression',
    'render-time expression fallback records EnableGraph as the expression source',
);
is(
    $cleanable_runtime_signal_info{runtime_ast_resolution_state},
    'missing',
    'render-time expression fallback keeps the original runtime-AST miss state',
);
is(
    $cleanable_runtime_signal_info{runtime_ast_miss_reason},
    'no_ast_source',
    'render-time expression fallback keeps the original runtime-AST miss reason',
);
ok(
    !exists $cleanable_runtime_signal_info{runtime_ast},
    'render-time expression fallback does not silently hydrate runtime_ast',
);

my @cleanable_runtime_dependencies = $backend->resolve_intermediate_signal_dependencies(
    'cleanable_runtime_expr',
    \%cleanable_runtime_signal_info,
);

is_deeply(
    \@cleanable_runtime_dependencies,
    ['mid'],
    'explicit runtime-AST-miss dependency recovery still recovers dependencies from the cleaned compatibility expression',
);
is(
    $cleanable_runtime_signal_info{dependency_source},
    'dependency_cleaned_rendered_expression_ast',
    'dependency recovery records the cleaned rendered-expression AST source explicitly',
);
is(
    $cleanable_runtime_signal_info{runtime_ast_source},
    'dependency_cleaned_rendered_expression_ast',
    'dependency recovery only promotes runtime_ast through the explicit dependency-recovery path',
);
is(
    $cleanable_runtime_signal_info{rendered_expression_source},
    'enable_graph_expression',
    'dependency recovery preserves the original rendered expression source after cleaned AST recovery',
);
done_testing();
