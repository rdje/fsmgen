package FSM::DirectSourceBitwiseTreeRangeSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed weaken refaddr);
use FSM::DirectDeclaredWidthSupport;
use FSM::SourceBitwiseTreePolicySupport;
use FSM::IntermediateWidthAllocationSupport;
use FSM::IntermediateWidthGraphPolicySupport ();
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _json {return JSON::PP->new->canonical}
sub _fail {confess "Direct source bitwise tree range $_[0]\n"}
sub _equal {return _json()->encode($_[0]) eq _json()->encode($_[1])}

sub _scope {
    my ($args) = @_;
    my $ctx = $args->{flattened_dt};
    _fail('requires an actual backend context')
        unless blessed($ctx) && $ctx->isa('FSM::HDL::FlattenedDT')
            && blessed($ctx->{fsm_module}) && $ctx->{fsm_module}->isa('FSM::CoreAST::FSMModule');
    my $owner = $ctx->{backend_sv_intermediate_width_support};
    my $recovery = $ctx->{backend_sv_intermediate_recovery_support};
    _fail('requires canonical installed width and recovery owners')
        unless ref($owner) eq 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport'
            && $owner->{flattened_dt} && $owner->{flattened_dt} == $ctx
            && ref($recovery) eq 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport'
            && $recovery->{flattened_dt} && $recovery->{flattened_dt} == $ctx;
    my $language = $args->{target_language};
    _fail('currently requires a Verilog-family target')
        unless defined($language) && !ref($language) && lc($language) =~ /\A(?:systemverilog|sv|verilog|v)\z/;
    my ($name, $info) = @{$args}{qw(signal_name signal_info)};
    my $rows = $owner->_current_graph_inference_rows;
    _fail('requires actual current collected source-row membership')
        unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
            && ref($info) eq 'HASH' && ref($rows) eq 'HASH'
            && ref($rows->{$name}) eq 'HASH' && $rows->{$name} == $info
            && ($info->{source} // '') eq 'fsmgen_parsing';
    return ($ctx, $owner, $recovery, $rows);
}

sub _selection {
    my ($args, $owner, $recovery, $binary) = @_;
    my ($name, $info, $expression) = @{$args}{qw(signal_name signal_info expression)};
    my $allocation_method = $binary ? 'intermediate_width_allocation' : 'source_bitwise_tree_width_allocation';
    my $policy_method = $binary ? 'binary_width_allocation' : 'source_bitwise_tree_width_allocation';
    my $origin_method = $binary ? 'binary_bitwise_origin' : 'source_bitwise_tree_origin';
    my $allocated = $owner->$allocation_method($name, $info);
    my $policy = $recovery->$policy_method($name, $info, $expression);
    my $origin = $recovery->$origin_method($name, $info, $expression);
    _fail('requires actual current completed source allocation and selected typed origin/text')
        unless $allocated && $policy && $origin && _equal($allocated, $policy)
            && ($binary ? _equal({map {$_ => $policy->{$_}} qw(operator source_names)},
                {map {$_ => $origin->{$_}} qw(operator source_names)})
                : FSM::SourceBitwiseTreePolicySupport->matches_origin($policy, $origin));
    return ($policy, $origin);
}

sub _remember {
    my ($map, $key, $object) = @_;
    _fail('lost a typed source object during traversal') unless ref($object);
    _fail('changed a typed source object during traversal')
        if exists($map->{$key}) && (!$map->{$key} || $map->{$key} != $object);
    $map->{$key} = $object;
    weaken($map->{$key});
}

sub _walk {
    my ($state, $node, $depth, $names, $widths) = @_;
    _fail('exceeds its bounded expanded source tree')
        unless blessed($node) && $depth <= FSM::IntermediateWidthGraphPolicySupport::MAX_BINARY_LEVELS();
    my $identity = refaddr($node);
    _fail('contains a cyclic typed source tree') if $state->{active_ast}{$identity};
    local $state->{active_ast}{$identity} = 1;
    _remember($state->{asts}, $identity, $node);
    if ($node->isa('FSM::CoreAST::SignalRef')) {
        my $name = FSM::IntermediateWidthAllocationSupport->whole_signal_name($node);
        my $signal = $node->signal;
        _fail('requires canonical whole Core source references')
            unless defined($name) && !defined($node->{slice}) && blessed($signal)
                && $signal->isa('FSM::CoreAST::Signal')
                && ($state->{ctx}{fsm_module}->signals->{$name} // 0) == $signal;
        _remember($state->{signals}, $name, $signal);
        push @$names, $name;
        push @$widths, $signal->width;
        if ($signal->get_attribute('is_intermediate')) {
            return _visit($state, $name, $depth);
        }
        _fail('exceeds its bounded expanded source tree') unless --$state->{budget} >= 0;
        push @{$state->{leaves}}, $name;
        return ['signal', $name];
    }
    _fail('requires typed binary bitwise source nodes')
        unless $node->isa('FSM::CoreAST::BinaryOp') && ref($node->{operands}) eq 'ARRAY'
            && @{$node->{operands}} == 2 && defined($node->operator)
            && !ref($node->operator) && $node->operator =~ /\A[&|^]\z/;
    _fail('exceeds its bounded expanded source tree') unless --$state->{budget} >= 0;
    my $left = _walk($state, $node->left, $depth + 1, $names, $widths);
    my $right = _walk($state, $node->right, $depth + 1, $names, $widths);
    return [$node->operator, $left, $right];
}

sub _visit {
    my ($state, $name, $depth) = @_;
    _fail('contains a cyclic source-helper graph') if $state->{active_helper}{$name};
    local $state->{active_helper}{$name} = 1;
    my $signal = $state->{ctx}{fsm_module}->signals->{$name};
    my $info = $state->{rows} && $state->{rows}{$name};
    _fail("requires actual current source-helper row '$name'")
        unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal')
            && ref($info) eq 'HASH' && ($info->{source} // '') eq 'fsmgen_parsing';
    _remember($state->{signals}, $name, $signal);
    _remember($state->{infos}, $name, $info);
    my $selection = $state->{selections}{$name};
    unless ($selection) {
        my $expression = $name eq $state->{root} ? $state->{expression}
            : $state->{recovery}->render_intermediate_signal_expression($name, $info);
        my $binary = $name ne $state->{root}
            && !$state->{owner}->source_bitwise_tree_width_allocation($name, $info);
        my ($policy, $origin) = _selection({signal_name => $name, signal_info => $info,
            expression => $expression}, $state->{owner}, $state->{recovery}, $binary);
        $selection = {policy => $policy, origin => $origin, expression => $expression, binary => $binary ? 1 : 0};
    }
    my $policy = $selection->{policy};
    my (@names, @widths);
    my $tree = _walk($state, $signal->driving_ast, $depth, \@names, \@widths);
    my $schema = $selection->{binary} ? 'FSM::IntermediateWidthAllocationSupport' : 'FSM::SourceBitwiseTreePolicySupport';
    _fail("disagrees with independently selected source-helper edges/maximum for '$name'")
        unless _equal(\@names, $policy->{source_names})
            && $schema->matches_selected_widths($policy, $info->{width}, @widths);
    $state->{selections}{$name} = $selection;
    return $tree;
}

sub _expanded {
    my ($ctx, $owner, $recovery, $rows, $args) = @_;
    my $state = {ctx => $ctx, owner => $owner, recovery => $recovery, rows => $rows,
        root => $args->{signal_name}, expression => $args->{expression}, signals => {}, infos => {}, asts => {},
        leaves => [], selections => {}, active_ast => {}, active_helper => {},
        budget => FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES()};
    weaken($state->{rows});
    # No strong local row-map reference may survive into reads that can release it.
    undef $rows;
    my $tree = _visit($state, $state->{root}, 0);
    my $root = $state->{selections}{$state->{root}}{policy};
    $state->{expanded} = FSM::SourceBitwiseTreePolicySupport->copy_record({%$root,
        expression_tree => $tree, source_names => $state->{leaves}});
    return $state;
}

sub _raw_signal {
    my ($signal) = @_;
    _fail('lost a canonical source Signal')
        unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    return {identity => refaddr($signal), ast => refaddr($signal->{driving_ast}),
        roles => {map {$_ => $signal->{attributes}{$_}}
            qw(is_intermediate is_output is_aux_output width_declared signal_role)},
        map {$_ => $signal->{$_}} qw(name _width type signed state_model declared_type_name declared_type_spec
            constraints _declared_width_source _declared_width_binding _declared_width_requirements
            _intermediate_width_allocation_revision _intermediate_width_allocation
            _source_bitwise_tree_width_allocation)};
}

sub _fence {
    my ($state) = @_;
    # This last fence uses raw captured fields, without invoking source getters or
    # renderers that could change an earlier child's already-read policy.
    my $ctx = $state->{ctx};
    my (%signals, %assignments, %asts, %rows);
    for my $name (sort keys %{$state->{signals}}) {
        my $signal = $state->{signals}{$name};
        _fail('lost canonical source membership') unless $signal
            && ($ctx->{fsm_module}{signals}{$name} // 0) == $signal;
    }
    # Canonical relationships depend on the complete module and assignment-source
    # scope, including declarations that are not operands of this expression.
    $signals{$_} = _raw_signal($ctx->{fsm_module}{signals}{$_})
        for sort keys %{$ctx->{fsm_module}{signals}};
    for my $name (sort keys %{$ctx->{assignment_analysis}}) {
        my $entry = $ctx->{assignment_analysis}{$name};
        my $lhs = $entry->{lhs_ast};
        _fail('lost a normalized assignment source') unless blessed($lhs);
        $assignments{$name} = {lhs_identity => refaddr($lhs), lhs_class => ref($lhs), name => $lhs->{name}};
        if (UNIVERSAL::isa($lhs, 'FSM::CoreAST::SignalRef')) {
            $assignments{$name}{signal} = _raw_signal($lhs->{signal});
        } else {
            $assignments{$name}{assignments} = [map {
                my $row = $_;
                +{map {$_ => $row->{$_}} qw(is_state_trans assignment_intent source_provenance operator rhs)}
            } @{$entry->{assignments} // []}];
        }
    }
    for my $identity (sort keys %{$state->{asts}}) {
        my $node = $state->{asts}{$identity} or _fail('lost a selected typed source node');
        $asts{$identity} = $node->isa('FSM::CoreAST::SignalRef')
            ? {signal => refaddr($node->{signal}), slice => $node->{slice}}
            : {operator => $node->{operator}, operands => [map {refaddr($_)} @{$node->{operands}}]};
    }
    for my $name (sort keys %{$state->{infos}}) {
        my $info = $state->{infos}{$name};
        _fail('lost current collected source-helper membership') unless $info && $state->{rows}
            && ($state->{rows}{$name} // 0) == $info;
        my $ast = $state->{signals}{$name}{driving_ast};
        my $registered = $ctx->{intermediate_signals}{$name};
        my $row = FSM::IntermediateWidthAllocationSupport::_factorized_metadata_state($info, $ast);
        my $registration = FSM::IntermediateWidthAllocationSupport::_factorized_metadata_state($registered, $ast);
        _fail('changed complete source-helper metadata') unless $row && $registration;
        $rows{$name} = {row => $row, registration => $registration,
            tree_attachment => $state->{owner}{_source_bitwise_tree_allocation_events}{$name},
            binary_attachment => $state->{owner}{_source_width_allocation_events}{$name},
            selected_text => [map {$info->{$_}} qw(expression rendered_expression rendered_expression_source)]};
    }
    return _json()->encode({signals => \%signals, assignments => \%assignments, asts => \%asts, rows => \%rows,
        scope => {map {$_ => $ctx->{fsm_module}{$_}}
            qw(name parameters _parameter_default_sources _parameter_default_bindings)},
        module => refaddr($ctx->{fsm_module}), signal_map => refaddr($ctx->{fsm_module}{signals}),
        registry => refaddr($ctx->{intermediate_signals}), row_map => refaddr($state->{rows}),
        owner => refaddr($ctx->{backend_sv_intermediate_width_support}),
        recovery => refaddr($ctx->{backend_sv_intermediate_recovery_support}),
        epochs => [map {$state->{owner}{$_}} qw(_width_inference_epoch _width_inference_complete
            _graph_inference_rows_epoch _graph_inference_rows_revision)]});
}

sub prepare_declaration {
    my ($class, %args) = @_;
    my ($ctx, $owner, $recovery, $rows) = _scope(\%args);
    # The caller's prepared block owns this map. Proof must not keep an expired
    # row view alive, and returned plans contain no source/backend references.
    weaken($rows);
    my $direct = 'FSM::DirectDeclaredWidthSupport';
    my $before = $direct->_capture_source_state($ctx);
    my $state = _expanded($ctx, $owner, $recovery, $rows, \%args);
    my $fence = _fence($state);
    my ($policy, $origin) = @{$state->{selections}{$args{signal_name}}}{qw(policy origin)};
    my %source_args = (fsm_module => $ctx->{fsm_module}, assignment_analysis => $ctx->{assignment_analysis},
        target_language => $args{target_language}, source_tree_width_allocation => $state->{expanded});
    my $relationship = $direct->prepare_source_tree_operand_relationship(%source_args);
    _fail('disagrees with the independently selected original-leaf maximum')
        unless FSM::SourceBitwiseTreePolicySupport->matches_selected_widths(
            $state->{expanded}, $args{signal_info}{width}, @{$relationship->{operand_widths}});
    my $again = $direct->prepare_source_tree_operand_relationship(%source_args);
    my $plan = _json()->decode(_json()->encode({profile => $relationship->{profile},
        target_language => $relationship->{target_language}, source_scope => $relationship->{source_scope},
        module_name => $ctx->{fsm_module}->name, target_name => $args{signal_name}, declaration_kind => 'signal',
        allocation_role => 'source_intermediate', source_names => $policy->{source_names},
        operand_targets => $policy->{source_names}, width => $args{signal_info}{width},
        source_tree_width_allocation => $policy, source_tree_origin => $origin, expression => $args{expression},
        expression_tree => $state->{expanded}{expression_tree}, leaf_names => $relationship->{source_names},
        width_plan => $relationship->{width_plan}}));
    my $current = _expanded($ctx, $owner, $recovery, $rows, \%args);
    my $after = $direct->_capture_source_state($ctx);
    _fail('complete source or current selected intent changed during declaration preparation')
        unless $before eq $after && _equal($state->{expanded}, $current->{expanded})
            && _equal($state->{selections}, $current->{selections}) && _equal($relationship, $again)
            && $fence eq _fence($state) && $fence eq _fence($current);
    my ($final_ctx, $final_owner, $final_recovery, $final_rows) = _scope(\%args);
    _fail('source ownership changed during declaration preparation')
        unless $final_ctx == $ctx && $final_owner == $owner && $final_recovery == $recovery
            && $rows && $final_rows == $rows;
    return $plan;
}

1;

=head1 NAME

FSM::DirectSourceBitwiseTreeRangeSupport - Prepare private actual source bitwise tree intent

=head1 DESCRIPTION

C<prepare_declaration> takes the actual C<flattened_dt> context, current
C<signal_name>/C<signal_info>, Verilog-family C<target_language> and fresh
selected C<expression>. The direct-width facade exposes the same arguments as
C<prepare_source_tree_declaration>. Only installed canonical owners and the
actual current weak collected-row view may supply completed source-tree
allocation and matching typed origin/text. A copied row, displaced owner,
foreign context, stale policy or independent floor cannot supply intent.

Every ordered original module leaf, including duplicate slots, must satisfy the
canonical plain unsigned frozen width relationship. Fixed leaves retain their
independent selected widths; mutable leaves require identical complete contracts
and preserve vector rank at default one. Exact selected maxima remain separate
from that relationship. Actual whole Core SignalRef helper edges expand through
their own installed completed source-tree or binary bitwise attachment and fresh
selected origin/text. Every original operator, association and repeated leaf
occurrence survives. Helper names and equal numeric widths establish no edge.
Foreign objects, missing or stale child rows/policies, cycles and expanded trees
above the shared depth or visited-occurrence limit refuse. Shared helper slots
count separately toward expansion, while each distinct child's current selection
is read once per traversal.

The canonical direct-width owner supplies the same complete source snapshot used
by arithmetic graph preparation. Every source declaration, captured parameter
map and normalized assignment source must remain current, even when the derived
range text is unchanged. Complete canonical relationships, current selection,
installed owners and weak row-view identity recheck at return. A second bounded
actual traversal rechecks all child selections. A final raw-field fence checks
every touched Core node, complete canonical Signal/assignment/parameter scope,
collected and registered row, attachment and epoch identity after the last source snapshot, without another source
getter or renderer. Weak temporary object associations cannot retain a released
caller row container.

The detached root plan contains profile/language/scope/module/target identity,
source allocation role, current ordered source names and operand targets,
selected width, separate source-tree policy and origin, exact selected expression,
expanded original expression tree/leaf names and canonical range representative.
The root policy/origin and source names still describe its selected local tree;
expanded leaves do not overwrite those distinct current edges. It retains
no caller objects and asserts no selected-target membership or child inventory.
This private prerequisite emits no HDL, changes no live range and broadens no
VHDL, public semantic API, MCP or corpus profile. Independently completed
selected-target proof remains a separate prerequisite.

=cut
