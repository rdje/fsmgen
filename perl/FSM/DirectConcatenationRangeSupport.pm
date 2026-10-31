package FSM::DirectConcatenationRangeSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use FSM::CoreExpressionWidthSupport;
use FSM::ConcatenationInferenceSupport;
use FSM::ParameterDefaultEnvironmentSupport;
use FSM::ConcatenationSourceWidthSupport;
use FSM::WidthExpressionSupport;
use FSM::Backend::VerilogFamily::WidthExpressionEmitter;

sub _fail { confess "Direct concatenation declaration $_[0]\n" }
sub _same { FSM::ConcatenationInferenceSupport::_same(@_) }
sub _copy { FSM::ConcatenationInferenceSupport::_copy($_[0]) }

# Take this only after the canonical completed-sum accessor has validated the
# bounded original holders. Keep actual identities local, never in the plan.
sub _checkpoint {
    my (%args) = @_;
    my $owner = $args{width_support};
    my $rows = $owner->_current_graph_inference_rows or return;
    my $events = $owner->{_concatenation_inference_events};
    my $sources = $owner->{_concatenation_source_frames};
    my $name = $args{signal_name};
    return unless ref($events) eq 'HASH' && ref($sources) eq 'HASH'
        && ref($events->{$name}) eq 'HASH' && ref($sources->{$name}) eq 'HASH';
    return {rows => $rows, events => $events, sources => $sources,
        event => $events->{$name}, source => $sources->{$name},
        epoch => $owner->{_width_inference_epoch},
        original_event => _copy($events->{$name}), original_source => _copy($sources->{$name})};
}

# No semantic getter may run after this fence. In particular, a final sum read
# cannot replace either original holder with a freshly equal observation.
sub _current_raw {
    my ($checkpoint, %args) = @_;
    my ($owner, $name) = @args{qw(width_support signal_name)};
    return unless $owner->{_width_inference_complete}
        && $owner->{_width_inference_complete} == $checkpoint->{epoch}
        && $owner->{_width_inference_epoch} == $checkpoint->{epoch}
        && ($owner->_current_graph_inference_rows // 0) == $checkpoint->{rows}
        && ($owner->{_concatenation_inference_events} // 0) == $checkpoint->{events}
        && ($owner->{_concatenation_source_frames} // 0) == $checkpoint->{sources}
        && ($checkpoint->{events}{$name} // 0) == $checkpoint->{event}
        && ($checkpoint->{sources}{$name} // 0) == $checkpoint->{source}
        && _same($checkpoint->{event}, $checkpoint->{original_event})
        && _same($checkpoint->{source}, $checkpoint->{original_source});
    return FSM::ConcatenationInferenceSupport->live_usage_current_raw(
        %args, signal_registry => $checkpoint->{rows}, holder => $checkpoint->{original_event});
}

sub prepare_declaration {
    my ($class, %args) = @_;
    my $ctx = $args{flattened_dt};
    _fail('requires the actual direct backend context')
        unless ref($ctx) eq 'FSM::HDL::FlattenedDT';
    my $owner = $ctx->{backend_sv_intermediate_width_support};
    _fail('requires the canonical installed width owner')
        unless ref($owner) eq 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport'
            && ($owner->{flattened_dt} // 0) == $ctx;
    my %languages = (systemverilog => 'systemverilog', sv => 'systemverilog',
        verilog => 'verilog', v => 'verilog');
    my $language = $args{target_language};
    _fail('requires an explicit Verilog-family target language')
        unless defined($language) && !ref($language) && exists($languages{lc($language)});
    $language = $languages{lc($language)};
    my $renderer = $ctx->{enable_graph_ast_support};
    _fail('requires the installed original typed renderer')
        unless ref($renderer) eq 'FSM::Synthesis::EnableGraph::ASTSupport'
            && ($renderer->{flattened_dt} // 0) == $ctx;
    my ($name, $row, $expression) = @args{qw(signal_name signal_info expression)};
    my %current_args = (width_support => $owner, signal_name => $name, signal_info => $row);
    my $joined = $owner->factorized_concatenation_sum($name, $row)
        // _fail('requires an original current completed source sum');
    my $checkpoint = _checkpoint(%current_args)
        // _fail('requires the original installed source and event holders');
    # Current proof binds the original runtime AST, but cache fields may have
    # existed before capture. Re-render the actual original typed AST directly;
    # the ordinary cached recovery accessor cannot prove this comparison.
    _fail('requires the exact selected typed-render expression')
        unless defined($expression) && !ref($expression) && length($expression)
            && length($expression) <= FSM::CoreExpressionWidthSupport::MAX_NODES()
            && ($row->{rendered_expression_source} // '') eq 'substituted_ast'
            && _same($expression, $row->{rendered_expression});
    my $rendered = $renderer->ast_to_systemverilog($row->{runtime_ast});
    _fail('selected expression disagrees with fresh original typed rendering')
        unless _same($expression, $rendered);
    my $sum = $joined->{sum};
    my $range;
    if ($sum->{profile} eq 'symbolic') {
        my $module = $ctx->{fsm_module};
        my $environment = FSM::ParameterDefaultEnvironmentSupport->prove_binding_observations(
            parameters => $module->parameters, sources => $module->parameter_default_sources,
            bindings => $module->parameter_default_bindings)->{environment};
        _fail('requires the original matching parameter environment')
            unless $environment && _same($environment->{scope}, $sum->{source_scope});
        $range = FSM::Backend::VerilogFamily::WidthExpressionEmitter->lower_sum_range(
            target_language => $language, environment => $environment,
            required_scope_kind => 'direct_module', context => "Concatenation '$name' declaration",
            operands => [map {{width => $_->{width},
                width_contract => $_->{width_plan} ? $_->{width_plan}{width_contract} : undef}} @{$sum->{terms}}]);
    }
    my $plan = {kind => 'concatenation_source_declaration', profile => $sum->{profile},
        target_language => $language, source_profile => $sum->{target_language},
        source_scope => $sum->{source_scope}, module_name => $ctx->{fsm_module}{name},
        target_name => $name, declaration_kind => 'signal', allocation_role => 'factorized_intermediate',
        source_names => $joined->{allocation}{source_contract}{source_names},
        allocation => $joined->{allocation}, sum => $sum, width => $sum->{width},
        is_vector => $sum->{is_vector}, range_text => $range, expression => $expression};
    my $again = $owner->factorized_concatenation_sum($name, $row);
    _fail('source sum changed during preparation') unless $again && _same($joined, $again);
    _fail('original source or completed event changed during preparation')
        unless _current_raw($checkpoint, %current_args);
    _fail('installed original typed renderer changed during preparation')
        unless ($ctx->{enable_graph_ast_support} // 0) == $renderer
            && ($renderer->{flattened_dt} // 0) == $ctx;
    return _copy($plan);
}

# Freeze every original target container before invoking source getters. The
# bounded raw walker rejects tied/blessed/cyclic records without calling them.
# Equal-valued replacements are changes too; plans contain only detached data.
sub _target_snapshot {
    my (%args) = @_;
    my $walk = {remaining => FSM::CoreExpressionWidthSupport::MAX_NODES(), active => {}, containers => []};
    my %data;
    for my $field (qw(target_namespace target_declarations)) {
        $data{$field} = FSM::ConcatenationSourceObservationSupport::_plain($args{$field}, $walk, 0);
        _fail('requires complete target namespace and declaration maps') unless ref($data{$field}) eq 'HASH';
    }
    return {data => \%data, containers => $walk->{containers}};
}

sub _plain_declaration {
    my ($declarations, $name) = @_;
    my $row = $declarations->{$name};
    _fail("requires a plain unsigned target declaration '$name'")
        unless ref($row) eq 'HASH' && !$row->{signed} && !defined($row->{state_model})
            && !defined($row->{declared_type_name}) && !defined($row->{declared_type_spec})
            && !exists($row->{width_origin});
    return $row;
}

sub _target_root {
    my ($intent, $namespace, $ctx) = @_;
    my $name = $intent->{target_name};
    _fail('requires unrenamed physical module and intermediate signal membership')
        unless $namespace->{module_name} eq $intent->{module_name}
            && ($namespace->{namespace}{identifier_map}{$name} // $name) eq $name
            && ($namespace->{roles}{$name} // '') eq 'signals'
            && !exists($namespace->{signal_targets}{$name});
    my $declarations = $namespace->{declarations};
    my $result = _plain_declaration($declarations, $name);
    # Independent declarations retain the shared source profile in their
    # source-sum records. Render the actual target separately below; do not
    # compare a Verilog-labelled operand plan with a SystemVerilog source plan.
    my $source = FSM::DirectDeclaredWidthSupport->prepare_module(
        fsm_module => $ctx->{fsm_module}, assignment_analysis => $ctx->{assignment_analysis},
        target_language => $intent->{source_profile});
    _fail('target declarations disagree with the original source scope')
        unless _same($source->{source_scope}, $intent->{source_scope});
    my @operands;
    for my $operand (@{$intent->{source_names}}) {
        _fail("requires original unrenamed operand mapping '$operand'")
            unless ($namespace->{signal_targets}{$operand} // '') eq $operand;
        my $row = _plain_declaration($declarations, $operand);
        my $signal = $source->{signals}{$operand};
        _fail("target operand '$operand' disagrees with its independent declaration")
            unless $row->{width} == $signal->{width} && !$signal->{signed}
                && !defined($signal->{state_model}) && !defined($signal->{declared_type_name})
                && !defined($signal->{declared_type_spec});
        my $plan = $signal->{width_plan};
        push @operands, {name => $operand, width => $signal->{width}, width_plan => $plan,
            is_vector => $plan ? $plan->{is_vector} : ($signal->{width} > 1 ? 1 : 0)};
    }
    my (@terms, $cursor);
    $cursor = 0;
    FSM::ConcatenationSourceWidthSupport::_sum_terms(
        $intent->{allocation}{source_contract}{expression_tree}, \@operands, \@terms, \$cursor);
    _fail('target operand slots disagree with original ordered source contracts')
        unless $cursor == @operands && _same(\@terms, $intent->{sum}{terms});
    my $evaluator = FSM::WidthExpressionSupport->new;
    my @widths = map {$evaluator->evaluate_constant_integer_scalar($_->{width}, 'Concatenation target sum')} @terms;
    my $width = sprintf('%s', $evaluator->apply_constant_width_operator('+', \@widths, 'Concatenation target sum')->bstr);
    _fail('target result disagrees with the independent ordered operand sum')
        unless FSM::IntermediateWidthAllocationSupport::_width($result->{width}) eq $width
            && _same($width, $intent->{width});
    my $range;
    if ($intent->{profile} eq 'symbolic') {
        my $module = $ctx->{fsm_module};
        my $environment = FSM::ParameterDefaultEnvironmentSupport->prove_binding_observations(
            parameters => $module->parameters, sources => $module->parameter_default_sources,
            bindings => $module->parameter_default_bindings)->{environment};
        _fail('target sum requires the matching original parameter environment')
            unless $environment && _same($environment->{scope}, $intent->{source_scope});
        $range = FSM::Backend::VerilogFamily::WidthExpressionEmitter->lower_sum_range(
            target_language => $intent->{target_language}, environment => $environment,
            required_scope_kind => 'direct_module', context => "Concatenation '$name' physical target",
            operands => [map {{width => $_->{width},
                width_contract => $_->{width_plan} ? $_->{width_plan}{width_contract} : undef}} @terms]);
    }
    my $root = {%$intent, width => $width, range_text => $range};
    _fail('complete target root disagrees with independent source declaration intent') unless _same($root, $intent);
    return $root;
}

sub prepare_range {
    my ($class, %args) = @_;
    my $snapshot = _target_snapshot(%args);
    my $intent = $class->prepare_declaration(%args);
    my $ctx = $args{flattened_dt};
    my $owner = $ctx->{backend_sv_intermediate_width_support};
    my $renderer = $ctx->{enable_graph_ast_support};
    my %current_args = (width_support => $owner, signal_name => $args{signal_name}, signal_info => $args{signal_info});
    my $checkpoint = _checkpoint(%current_args)
        // _fail('requires the original installed source and event holders');
    my %target_args = (fsm_module => $ctx->{fsm_module}, assignment_analysis => $ctx->{assignment_analysis},
        target_language => $intent->{target_language}, %{$snapshot->{data}});
    my $direct = 'FSM::DirectDeclaredWidthSupport';
    my $namespace = $direct->prepare_target_namespace(%target_args);
    $direct->prepare_declarations(%target_args);
    my $root = _target_root($intent, $namespace, $ctx);
    my $again = $class->prepare_declaration(%args);
    my $namespace_again = $direct->prepare_target_namespace(%target_args);
    $direct->prepare_declarations(%target_args);
    my $root_again = _target_root($again, $namespace_again, $ctx);
    _fail('source intent or complete target plan changed during preparation')
        unless _same($intent, $again) && _same($namespace, $namespace_again) && _same($root, $root_again);
    # No semantic callbacks follow: even equal plans must retain the original
    # physical input containers, completed holders and installed renderer.
    _fail('complete original target inputs changed during preparation')
        unless _same($snapshot, _target_snapshot(%args));
    _fail('original source or completed event changed during target preparation')
        unless _current_raw($checkpoint, %current_args);
    _fail('installed original typed renderer changed during target preparation')
        unless ($ctx->{enable_graph_ast_support} // 0) == $renderer
            && ($renderer->{flattened_dt} // 0) == $ctx;
    return _copy({%$root, operand_targets => $intent->{source_names},
        target_namespace => $namespace->{namespace}, target_declarations => $namespace->{declarations}});
}

1;

=head1 NAME

FSM::DirectConcatenationRangeSupport - Private current concatenation source declaration intent

=head1 METHODS

=head2 prepare_declaration

Take the actual C<flattened_dt>, C<signal_name>, C<signal_info>, selected
C<expression> and explicit Verilog-family C<target_language>. The installed
canonical width owner must supply an original current completed concatenation
sum. The selected expression and its installed cache must agree with a fresh
direct rendering of the original current typed AST. Current row proof alone
does not attest that a cache predating capture came through the typed renderer.
Unproved cache text, copied rows and missing/stale events refuse.

The detached C<concatenation_source_declaration> contains the original
C<allocation> and C<sum>, original ordered duplicate-preserving C<source_names>,
selected C<expression>, decimal-string C<width>, packed C<is_vector>, optional
symbolic C<range_text>, scope, module/helper names and declaration/allocation
roles. C<source_profile> preserves the shared source language independently of
the canonical actual C<target_language>. Symbolic ranges use every original
signal/literal term and the matching canonical parameter environment; fixed
sums retain numeric declaration intent without a symbolic range.

Original source/event/map/row identities and the completed epoch must survive
all semantic reads. A final getter-free fence rejects late changes and equal
holder substitutions. No observations refresh, no cache installs and returned
data retains no backend, row view, AST or Core Signal owner. Missing, foreign,
combined, signed, type, opaque and unknown literal contracts retain the completed
source sum's refusals. Failure/reset/reuse retain their existing revocation rules.

This is source-only intent. Names and roles grant no physical namespace,
declaration agreement or emission authority. Complete target proof, actual
declaration/expression consumers, final ledgers, VHDL and external execution
remain separate obligations.

=head2 prepare_range

Take the same current source arguments as C<prepare_declaration>, plus complete
plain C<target_namespace> and C<target_declarations> maps. The canonical direct
namespace and declaration validators must establish complete physical
membership, parameter mapping, identifier/collision rules and source declaration
agreement. The selected result must be an unrenamed intermediate signal with
no competing C<width_origin>. Module and operand renaming currently refuse.
Every selected operand and result must be plain unsigned, without declared type
or state model. The result width must equal the independently recomputed ordered
sum, including repeated signal slots and explicit literal widths.

Independent current declaration plans must match every original source-sum
term, including width-one vector rank and captured parameter contracts. Their
shared source profile remains separate from the actual Verilog-family target;
the latter selects fresh canonical sum-range rendering. The complete target
root must exactly match the separately prepared current source intent.

The detached result extends C<concatenation_source_declaration> with ordered
C<operand_targets>, complete C<target_namespace> and C<target_declarations>.
These data records retain no source or caller container ownership. A raw target
snapshot precedes all semantic reads, and final getter-free fences require
unchanged complete target values and container identities, original source and
completed-event holders, row/map/epoch and installed renderer. Equal-valued
replacement containers refuse. Raw target traversal shares the Core expression
depth/occurrence and scalar/key bounds, rejects tied, blessed and cyclic input,
and invokes no serialization hooks.

This private preparation does not attest the records' producer origin or prove
that a writer emitted them. Actual declaration/expression consumers, final
ledgers, unknown literal sizing, VHDL, public API/MCP/corpus capability expansion
and full compiler/override/runtime/publication qualification remain separate.

=cut
