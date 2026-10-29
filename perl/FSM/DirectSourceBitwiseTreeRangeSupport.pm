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
        my $binary = $name eq $state->{root} ? $state->{root_binary}
            : !$state->{owner}->source_bitwise_tree_width_allocation($name, $info);
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
    my ($ctx, $owner, $recovery, $rows, $args, $root_binary) = @_;
    my $state = {ctx => $ctx, owner => $owner, recovery => $recovery, rows => $rows,
        root => $args->{signal_name}, root_binary => $root_binary, expression => $args->{expression},
        signals => {}, infos => {}, asts => {},
        leaves => [], selections => {}, active_ast => {}, active_helper => {},
        budget => FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES()};
    weaken($state->{rows});
    # No strong local row-map reference may survive into reads that can release it.
    undef $rows;
    my $tree = _visit($state, $state->{root}, 0);
    my $root = $state->{selections}{$state->{root}}{policy};
    _fail('computed binary root requires an actual typed source-helper child')
        if $root_binary && keys(%{$state->{selections}}) < 2;
    $state->{expanded} = FSM::SourceBitwiseTreePolicySupport->copy_record({
        kind => 'source_bitwise_tree_operand_max', operator => $root->{operator}, selected_width => $root->{selected_width},
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
    return $class->_prepare_declaration(0, %args);
}

sub prepare_binary_declaration {
    my ($class, %args) = @_;
    return $class->_prepare_declaration(1, %args);
}

sub _prepare_declaration {
    my ($class, $root_binary, %args) = @_;
    my ($ctx, $owner, $recovery, $rows) = _scope(\%args);
    # The caller's prepared block owns this map. Proof must not keep an expired
    # row view alive, and returned plans contain no source/backend references.
    weaken($rows);
    my $direct = 'FSM::DirectDeclaredWidthSupport';
    my $before = $direct->_capture_source_state($ctx);
    my $state = _expanded($ctx, $owner, $recovery, $rows, \%args, $root_binary);
    my $fence = _fence($state);
    my ($policy, $origin) = @{$state->{selections}{$args{signal_name}}}{qw(policy origin)};
    my %source_args = (fsm_module => $ctx->{fsm_module}, assignment_analysis => $ctx->{assignment_analysis},
        target_language => $args{target_language}, source_tree_width_allocation => $state->{expanded});
    my $relationship = $direct->prepare_source_tree_operand_relationship(%source_args);
    _fail('disagrees with the independently selected original-leaf maximum')
        unless FSM::SourceBitwiseTreePolicySupport->matches_selected_widths(
            $state->{expanded}, $args{signal_info}{width}, @{$relationship->{operand_widths}});
    my $again = $direct->prepare_source_tree_operand_relationship(%source_args);
    my ($policy_key, $origin_key) = $root_binary ? qw(width_allocation bitwise_origin)
        : qw(source_tree_width_allocation source_tree_origin);
    my $plan = _json()->decode(_json()->encode({profile => $relationship->{profile},
        target_language => $relationship->{target_language}, source_scope => $relationship->{source_scope},
        module_name => $ctx->{fsm_module}->name, target_name => $args{signal_name}, declaration_kind => 'signal',
        allocation_role => 'source_intermediate', source_names => $policy->{source_names},
        operand_targets => $policy->{source_names}, width => $args{signal_info}{width},
        $policy_key => $policy, $origin_key => $origin, expression => $args{expression},
        expression_tree => $state->{expanded}{expression_tree}, leaf_names => $relationship->{source_names},
        width_plan => $relationship->{width_plan}}));
    my $current = _expanded($ctx, $owner, $recovery, $rows, \%args, $root_binary);
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

sub _target_declaration {
    my ($state, $name) = @_;
    my $row = $state->{declarations}{$name};
    _fail("requires an actual plain unsigned selected declaration '$name'")
        unless ref($row) eq 'HASH' && !$row->{signed} && !defined($row->{state_model})
            && !defined($row->{declared_type_name}) && !defined($row->{declared_type_spec})
            && ($state->{target}{signal_targets}{$name} // '') eq $name;
    return $row;
}

sub _target_walk {
    my ($state, $ast, $depth, $names, $widths) = @_;
    _fail('exceeds its bounded selected source tree')
        unless blessed($ast) && $depth <= FSM::IntermediateWidthGraphPolicySupport::MAX_BINARY_LEVELS();
    my $identity = refaddr($ast);
    _fail('contains a cyclic selected typed tree') if $state->{active_ast}{$identity};
    local $state->{active_ast}{$identity} = 1;
    _remember($state->{asts}, $identity, $ast);
    if ($ast->isa('FSM::CoreAST::SignalRef')) {
        my $name = FSM::IntermediateWidthAllocationSupport->whole_signal_name($ast);
        my $signal = $ast->signal;
        _fail('requires actual whole Core edges to selected source targets')
            unless defined($name) && !defined($ast->{slice}) && blessed($signal)
                && $signal->isa('FSM::CoreAST::Signal')
                && ($state->{ctx}{fsm_module}->signals->{$name} // 0) == $signal;
        _remember($state->{signals}, $name, $signal);
        push @$names, $name;
        push @$widths, _target_declaration($state, $name)->{width};
        if ($signal->get_attribute('is_intermediate')) {
            return _target_visit($state, $name, $depth)->{tree};
        }
        _fail("cannot substitute a selected helper event for original leaf '$name'")
            if exists($state->{events}{$name});
        _fail('exceeds its bounded selected source tree') unless --$state->{budget} >= 0;
        return ['signal', $name];
    }
    _fail('requires actual typed bitwise edges in selected source targets')
        unless $ast->isa('FSM::CoreAST::BinaryOp') && ref($ast->{operands}) eq 'ARRAY'
            && @{$ast->{operands}} == 2 && defined($ast->operator)
            && !ref($ast->operator) && $ast->operator =~ /\A[&|^]\z/;
    _fail('exceeds its bounded selected source tree') unless --$state->{budget} >= 0;
    my $left = _target_walk($state, $ast->left, $depth + 1, $names, $widths);
    my $right = _target_walk($state, $ast->right, $depth + 1, $names, $widths);
    return [$ast->operator, $left, $right];
}

sub _target_visit {
    my ($state, $name, $depth) = @_;
    _fail('contains a cyclic selected source-helper graph') if $state->{active_helper}{$name};
    local $state->{active_helper}{$name} = 1;
    my $signal = $state->{ctx}{fsm_module}->signals->{$name};
    my $info = $state->{rows} && $state->{rows}{$name};
    _fail("requires actual current selected source-helper '$name'")
        unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal')
            && $signal->get_attribute('is_intermediate') && ref($info) eq 'HASH'
            && ($info->{source} // '') eq 'fsmgen_parsing';
    _remember($state->{signals}, $name, $signal);
    _remember($state->{infos}, $name, $info);
    my $event = $state->{events}{$name};
    my $binary = ref($event) eq 'HASH' && !exists($event->{source_tree_width_allocation});
    my ($policy_key, $origin_key) = $binary ? qw(width_allocation bitwise_origin)
        : qw(source_tree_width_allocation source_tree_origin);
    _fail("requires a closed selected source-helper event '$name'")
        unless ref($event) eq 'HASH'
            && join(',', sort keys %$event) eq join(',', sort ('expression', $policy_key, $origin_key));
    _fail('requires the selected root allocation family')
        if $name eq $state->{root} && $binary != $state->{root_binary};
    my ($policy, $origin) = _selection({signal_name => $name, signal_info => $info,
        expression => $event->{expression}}, $state->{owner}, $state->{recovery}, $binary);
    _fail("disagrees with the complete current selected event for '$name'")
        unless _equal($event, {expression => $event->{expression}, $policy_key => $policy, $origin_key => $origin});
    $state->{selections}{$name} = {policy => $policy, origin => $origin,
        expression => $event->{expression}, binary => $binary ? 1 : 0};
    my $declaration = _target_declaration($state, $name);
    _fail("requires unrenamed intermediate signal membership for '$name'")
        unless 1 == (grep {$_ eq $name} @{$state->{namespace}{signals}})
            && !exists($declaration->{width_origin});
    my (@names, @widths);
    # Traverse each occurrence, even when a child already has an inventory row:
    # sharing cannot evade the expanded depth/occurrence bounds.
    my $tree = _target_walk($state, $signal->driving_ast, $depth, \@names, \@widths);
    my $schema = $binary ? 'FSM::IntermediateWidthAllocationSupport' : 'FSM::SourceBitwiseTreePolicySupport';
    _fail("disagrees with actual selected operand slots or maximum for '$name'")
        unless _equal(\@names, $policy->{source_names})
            && $schema->matches_selected_widths($policy, $declaration->{width}, @widths)
            && defined(FSM::IntermediateWidthAllocationSupport::_width($info->{width}))
            && FSM::IntermediateWidthAllocationSupport::_width($info->{width})
                eq FSM::IntermediateWidthAllocationSupport::_width($declaration->{width});
    my $leaves = _tree_leaves($tree);
    my $node = {tree => $tree, plan => {profile => $state->{relationship}{profile},
        target_language => $state->{target}{target_language}, source_scope => $state->{relationship}{source_scope},
        module_name => $state->{target}{module_name}, target_name => $name, declaration_kind => 'signal',
        allocation_role => 'source_intermediate', source_names => $policy->{source_names},
        operand_targets => $policy->{source_names}, width => $declaration->{width},
        $policy_key => $policy, $origin_key => $origin, expression => $event->{expression},
        expression_tree => $tree, leaf_names => $leaves,
        width_plan => $state->{relationship}{profile} eq 'symbolic'
            ? $state->{source}{signals}{$leaves->[0]}{width_plan} : undef}};
    if (exists($state->{nodes}{$name})) {
        _fail("changed a shared selected source-helper '$name'") unless _equal($node, $state->{nodes}{$name});
    } else {
        $state->{nodes}{$name} = $node;
        push @{$state->{order}}, $name;
    }
    return $node;
}

sub _tree_leaves {
    my ($tree) = @_;
    return [$tree->[1]] if $tree->[0] eq 'signal';
    return [@{_tree_leaves($tree->[1])}, @{_tree_leaves($tree->[2])}];
}

sub _selected_targets {
    my ($ctx, $owner, $recovery, $rows, $input, $source, $target, $relationship, $name, $root_binary) = @_;
    my $state = {ctx => $ctx, owner => $owner, recovery => $recovery, rows => $rows, %$input,
        source => $source, target => $target, relationship => $relationship, root => $name, root_binary => $root_binary,
        signals => {}, infos => {}, asts => {}, selections => {}, nodes => {}, order => [],
        active_ast => {}, active_helper => {}, budget => FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES()};
    weaken($state->{rows});
    undef $rows;
    _target_visit($state, $name, 0);
    return $state;
}

sub prepare {
    my ($class, %args) = @_;
    return $class->_prepare(0, %args);
}

sub prepare_binary {
    my ($class, %args) = @_;
    return $class->_prepare(1, %args);
}

sub _prepare {
    my ($class, $root_binary, %args) = @_;
    my $target_inputs = sub {_json()->encode({namespace => $args{target_namespace},
        declarations => $args{target_declarations}, events => $args{target_intermediates}})};
    my $snapshot = eval {$target_inputs->()};
    _fail("requires JSON-safe complete selected target records: $@") if $@;
    my $input = _json()->decode($snapshot);
    my $name = $args{signal_name};
    _fail('requires complete selected source-tree target maps')
        unless ref($input->{namespace}) eq 'HASH' && ref($input->{declarations}) eq 'HASH'
            && ref($input->{events}) eq 'HASH' && defined($name) && !ref($name)
            && ref($input->{events}{$name}) eq 'HASH';
    $args{expression} = $input->{events}{$name}{expression};
    my ($ctx, $owner, $recovery, $rows) = _scope(\%args);
    weaken($rows);
    my $direct = 'FSM::DirectDeclaredWidthSupport';
    my $before = $direct->_capture_source_state($ctx);
    my %source_args = (fsm_module => $ctx->{fsm_module}, assignment_analysis => $ctx->{assignment_analysis},
        target_language => $args{target_language});
    my %target_args = (%source_args, target_namespace => $input->{namespace}, target_declarations => $input->{declarations});
    my $source = $direct->prepare_module(%source_args);
    my $target = $direct->prepare_declarations(%target_args);
    my $intent = $class->_prepare_declaration($root_binary, %args);
    my $expanded = {kind => 'source_bitwise_tree_operand_max',
        operator => $intent->{expression_tree}[0], selected_width => $intent->{width},
        expression_tree => $intent->{expression_tree}, source_names => $intent->{leaf_names}};
    my $relationship = $direct->prepare_source_tree_operand_relationship(%source_args,
        source_tree_width_allocation => $expanded);
    my $state = _selected_targets($ctx, $owner, $recovery, $rows, $input, $source, $target, $relationship, $name, $root_binary);
    my $fence = _fence($state);
    _fail('complete target root disagrees with independent source declaration intent')
        unless _equal($state->{nodes}{$name}{plan}, $intent);
    my $source_again = $direct->prepare_module(%source_args);
    my $target_again = $direct->prepare_declarations(%target_args);
    my $again = $direct->prepare_source_tree_operand_relationship(%source_args,
        source_tree_width_allocation => $expanded);
    my $current_intent = $class->_prepare_declaration($root_binary, %args);
    my $current = _selected_targets($ctx, $owner, $recovery, $rows, $input, $source_again, $target_again, $again, $name, $root_binary);
    my $after = $direct->_capture_source_state($ctx);
    _fail('complete selected inputs or current source proof changed during target preparation')
        unless $snapshot eq $target_inputs->() && $before eq $after
            && _equal($source, $source_again) && _equal($target, $target_again)
            && _equal($relationship, $again) && _equal($intent, $current_intent)
            && _equal($state->{nodes}, $current->{nodes}) && _equal($state->{order}, $current->{order})
            && $fence eq _fence($state) && $fence eq _fence($current);
    my ($final_ctx, $final_owner, $final_recovery, $final_rows) = _scope(\%args);
    _fail('source ownership changed during selected target preparation')
        unless $final_ctx == $ctx && $final_owner == $owner && $final_recovery == $recovery
            && $rows && $rows == $final_rows;
    return _json()->decode(_json()->encode({%{$state->{nodes}{$name}{plan}}, node_order => $state->{order},
        nodes => {map {$_ => $state->{nodes}{$_}{plan}} @{$state->{order}}}}));
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
selected-target proof is provided separately by C<prepare>.

C<prepare> takes the same actual context, root row and target language plus
complete C<target_namespace>, C<target_declarations> and C<target_intermediates>
maps. It selects the root expression from those events. A separate traversal
joins actual whole Core edges to every selected tree or binary child event,
current completed policy and exact typed expression. Every result and operand
needs a plain unsigned canonical physical declaration and independently selected
maximum. Renamed helper targets, missing child events, foreign or copied rows,
conflicting allocation origins and substituted original-leaf events refuse.

The canonical source and declaration kernels reprepare the full input scope.
The independently traversed target root must agree with separate current source
intent, including expanded operators, association and ordered duplicate leaves.
Shared helper occurrences each consume depth/node budget, but each physical
helper appears only once in children-before-parent C<node_order>. C<nodes> holds
detached per-helper plans. Tree and binary children keep their own distinct
policy/origin fields. Every plan has its own original first-leaf range
representative when symbolic; fixed independent widths invent no relationship.

All selected target inputs retain their complete JSON identity at return, even
when a change leaves prepared range text equal. Canonical plans and all child
selections replay; the final raw-field fence follows the last complete source
snapshot and checks Core, row, attachment, module scope, owner and epoch state.
Proof retains no caller row view. Failure returns no partial plan, and held
detached plans cannot revive expired current membership. This independent proof
still emits no HDL and activates no source-tree range or VHDL support.

C<prepare_binary_declaration> and C<prepare_binary> select a separate computed
source binary root for source intent and independent complete-target proof.
An actual typed source-helper child is mandatory; direct two-original binary
roots stay with the original binary owner. A tree root cannot borrow this
entrypoint, and the tree-only methods cannot accept a binary root. The direct
width facade names these C<prepare_computed_source_binary_declaration> and
C<prepare_computed_source_binary_intermediate_range>.

These methods keep the binary root's own C<width_allocation>/C<bitwise_origin>
fields. Its expanded tree and original leaves still include every typed source
tree or binary child, with separate current policies and selected events.
Canonical original-leaf contracts, maxima, physical membership, detached plans,
weak row ownership and final complete source/target/raw-state fences are shared
with tree roots. This private prerequisite does not enable live symbolic binary
declarations; producer-only fixtures with that consumer held out of scope do not
qualify native generation or external HDL behavior.

=cut
