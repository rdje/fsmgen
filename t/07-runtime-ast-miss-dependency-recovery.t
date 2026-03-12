#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;

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
    expression => '@@@',
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
    'opaque legacy signal names still fall through to the final identifier scan when no signal-name AST can be built',
);
is(
    $opaque_legacy_signal_info{dependency_fallback_source},
    'runtime_ast_miss_identifier_scan',
    'opaque legacy signal names continue to report identifier-scan fallback',
);
done_testing();
