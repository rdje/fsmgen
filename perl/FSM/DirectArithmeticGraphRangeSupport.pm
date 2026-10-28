package FSM::DirectArithmeticGraphRangeSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed refaddr weaken);
use FSM::DirectDeclaredWidthSupport;
use FSM::IntermediateWidthAllocationSupport;
use FSM::IntermediateWidthGraphPolicySupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _json {return JSON::PP->new->canonical}
sub _id {return ref($_[0]) ? sprintf('%x', refaddr($_[0])) : undef}
sub _fail {confess "Direct arithmetic graph range $_[0]\n"}
sub _signal_state {
    my ($signal) = @_;
    _fail('requires actual Core source Signals')
        unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    return {identity => _id($signal), map {$_ => scalar($signal->$_())}
        qw(name width type signed state_model declared_type_name declared_type_spec constraints
            declared_width_source declared_width_binding declared_width_requirements
            _intermediate_width_allocation_revision)};
}
sub _source_state {
    my ($ctx) = @_;
    my $module = $ctx->{fsm_module};
    my $analysis = $ctx->{assignment_analysis};
    _fail('requires complete normalized assignment analysis') unless ref($analysis) eq 'HASH';
    my (%signals, %assignments);
    $signals{$_} = _signal_state($module->signals->{$_}) for sort keys %{$module->signals};
    for my $name (sort keys %$analysis) {
        my $entry = $analysis->{$name};
        my $lhs = ref($entry) eq 'HASH' ? $entry->{lhs_ast} : undef;
        _fail('requires normalized assignment LHS objects') unless blessed($lhs);
        my $row = {lhs_identity => _id($lhs), lhs_class => ref($lhs), name => scalar($lhs->name)};
        if (UNIVERSAL::isa($lhs, 'FSM::CoreAST::SignalRef')) {
            $row->{signal} = _signal_state($lhs->signal);
        } else {
            $row->{state_next} = $lhs->can('is_fsm_state_next') ? scalar($lhs->is_fsm_state_next) : undef;
            $row->{assignments} = [map {
                my $assignment = $_;
                {map {$_ => $assignment->{$_}} qw(is_state_trans assignment_intent source_provenance operator rhs)}
            } @{$entry->{assignments} // []}];
        }
        $assignments{$name} = $row;
    }
    return _json()->encode({module_identity => _id($module), name => $module->name,
        parameters => $module->parameters, sources => $module->parameter_default_sources,
        bindings => $module->parameter_default_bindings, signals => \%signals, assignments => \%assignments});
}
sub _plain_declaration {
    my ($state, $name) = @_;
    my $row = $state->{declarations}{$name};
    _fail("requires actual plain unsigned declaration '$name'")
        unless ref($row) eq 'HASH' && !$row->{signed} && !defined($row->{state_model})
            && !defined($row->{declared_type_name}) && !defined($row->{declared_type_spec});
    return $row;
}
sub _visit {
    my ($state, $name, $depth) = @_;
    _fail('exceeds its bounded selected graph')
        unless $depth <= FSM::IntermediateWidthGraphPolicySupport::MAX_BINARY_LEVELS()
            && --$state->{budget} >= 0;
    _fail('contains a cyclic selected graph') if ($state->{active}{$name} // 0);
    return $state->{nodes}{$name} if $state->{nodes}{$name};
    local $state->{active}{$name} = 1;
    my $rows = $state->{rows};
    _fail('has lost its actual graph row view') unless ref($rows) eq 'HASH';
    my $info = $rows->{$name};
    _fail("requires actual factorized row '$name'")
        unless ref($info) eq 'HASH' && ($info->{source} // '') eq 'ast_factorization';
    my $event = $state->{events}{$name};
    my $graph = ref($event) eq 'HASH' && exists($event->{graph_width_allocation});
    my $key = $graph ? 'graph_width_allocation' : 'width_allocation';
    _fail("requires closed selected arithmetic event '$name'")
        unless ref($event) eq 'HASH'
            && join(',', sort keys %$event) eq join(',', sort ('expression', 'arithmetic_origin', $key))
            && defined($event->{expression}) && !ref($event->{expression}) && length($event->{expression});
    my $schema = $graph ? 'FSM::IntermediateWidthGraphPolicySupport' : 'FSM::IntermediateWidthAllocationSupport';
    my $policy = $schema->copy_record($event->{$key});
    my $recovery = $state->{recovery};
    my $method = $graph ? 'arithmetic_graph_width_allocation' : 'arithmetic_width_allocation';
    my $current = $recovery->$method($name, $info, $event->{expression});
    my $owner_method = $graph ? 'factorized_graph_width_allocation' : 'factorized_width_allocation';
    my $allocated = $state->{owner}->$owner_method($name, $info);
    my $origin = $recovery->binary_arithmetic_origin($name, $info, $event->{expression});
    _fail("has no same current selected policy/origin/text for '$name'")
        unless $current && $allocated && $origin && _json()->encode($current) eq _json()->encode($policy)
            && _json()->encode($allocated) eq _json()->encode($policy)
            && _json()->encode($origin) eq _json()->encode($event->{arithmetic_origin});
    _fail("requires actual intermediate target membership for '$name'")
        unless 1 == (grep {$_ eq $name} @{$state->{namespace}{signals}})
            && ($state->{namespace}{identifier_map}{$name} // $name) eq $name
            && !exists($state->{source}{signals}{$name});
    my $declaration = _plain_declaration($state, $name);
    _fail("conflicts with another allocation origin for '$name'") if exists($declaration->{width_origin});
    _fail("disagrees with actual source-selected width for '$name'")
        unless defined(FSM::IntermediateWidthAllocationSupport::_width($info->{width}))
            && FSM::IntermediateWidthAllocationSupport::_width($info->{width})
                eq FSM::IntermediateWidthAllocationSupport::_width($declaration->{width});
    my $ast = $info->{ast};
    my $shape = FSM::IntermediateWidthAllocationSupport->binary_operand_max_shape($ast);
    _fail("requires actual typed arithmetic edges for '$name'")
        unless $shape && _json()->encode($shape) eq _json()->encode({map {$_ => $policy->{$_}} qw(operator source_names)});
    my @operands = ($ast->left, $ast->right);
    my (@trees, @leaves, @widths);
    for my $index (0, 1) {
        my $operand = $policy->{source_names}[$index];
        my $target = _plain_declaration($state, $operand);
        push @widths, $target->{width};
        if (UNIVERSAL::isa($operands[$index], 'FSM::HDL::IntermediateSignalRef')) {
            my $child = _visit($state, $operand, $depth + 1);
            push @trees, $child->{tree};
            push @leaves, @{$child->{leaves}};
        } else {
            _fail("cannot substitute a computed event for original source '$operand'") if exists($state->{events}{$operand});
            _fail("requires canonical original source target '$operand'")
                unless ($state->{target}{signal_targets}{$operand} // '') eq $operand
                    && exists($state->{source}{signals}{$operand});
            push @trees, ['signal', $operand];
            push @leaves, $operand;
        }
    }
    _fail("disagrees with independently selected operand widths for '$name'")
        unless $schema->matches_selected_widths($policy, $declaration->{width}, @widths);
    my $tree = [$policy->{operator}, @trees];
    if ($graph) {
        my $expanded = FSM::IntermediateWidthGraphPolicySupport->copy_record({%$policy, expression_tree => $tree});
        _fail("does not expand to its original tree for '$name'") unless _json()->encode($expanded) eq _json()->encode($policy);
    }
    my $node = {tree => $tree, leaves => \@leaves, plan => {profile => $state->{relationship}{profile},
        target_name => $name, declaration_kind => 'signal', allocation_role => 'factorized_intermediate',
        source_names => $policy->{source_names}, operand_targets => $policy->{source_names}, width => $declaration->{width},
        $key => $policy, arithmetic_origin => $origin, expression => $event->{expression},
        leaf_names => \@leaves, width_plan => $state->{relationship}{profile} eq 'symbolic'
            ? $state->{source}{signals}{$leaves[0]}{width_plan} : undef}};
    $state->{nodes}{$name} = $node;
    push @{$state->{order}}, $name;
    return $node;
}

sub prepare {
    my ($class, %args) = @_;
    my $ctx = $args{flattened_dt};
    _fail('requires an actual backend context') unless blessed($ctx) && $ctx->isa('FSM::HDL::FlattenedDT')
        && blessed($ctx->{fsm_module}) && $ctx->{fsm_module}->isa('FSM::CoreAST::FSMModule');
    my $owner = $ctx->{backend_sv_intermediate_width_support};
    my $recovery = $ctx->{backend_sv_intermediate_recovery_support};
    _fail('requires canonical current width and recovery owners')
        unless ref($owner) eq 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport'
            && $owner->{flattened_dt} == $ctx
            && ref($recovery) eq 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport'
            && $recovery->{flattened_dt} == $ctx;
    my $language = $args{target_language};
    _fail('currently requires a Verilog-family target')
        unless defined($language) && !ref($language) && lc($language) =~ /\A(?:systemverilog|sv|verilog|v)\z/;
    my $name = $args{signal_name};
    my $rows = $owner->_current_graph_inference_rows;
    _fail('requires the actual current graph root row')
        unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
            && ref($rows) eq 'HASH' && ref($args{signal_info}) eq 'HASH'
            && ref($rows->{$name}) eq 'HASH' && $rows->{$name} == $args{signal_info};
    my $target_inputs = sub {_json()->encode({namespace => $args{target_namespace},
        declarations => $args{target_declarations}, events => $args{target_intermediates}})};
    my $snapshot = $target_inputs->();
    my $input = _json()->decode($snapshot);
    _fail('requires actual selected graph root metadata') unless ref($input->{events}) eq 'HASH'
        && ref($input->{events}{$name}) eq 'HASH' && exists($input->{events}{$name}{graph_width_allocation});
    my %source_args = (fsm_module => $ctx->{fsm_module}, assignment_analysis => $ctx->{assignment_analysis}, target_language => $language);
    my %target_args = (%source_args, target_namespace => $input->{namespace}, target_declarations => $input->{declarations});
    my $source_snapshot = _source_state($ctx);
    my $direct = 'FSM::DirectDeclaredWidthSupport';
    my $source = $direct->prepare_module(%source_args);
    my $relationship = $direct->prepare_graph_operand_relationship(%source_args,
        graph_width_allocation => $input->{events}{$name}{graph_width_allocation});
    my $target = $direct->prepare_declarations(%target_args);
    my $state = {rows => $rows, owner => $owner, recovery => $recovery, source => $source, target => $target,
        relationship => $relationship, %$input, nodes => {}, order => [], active => {},
        budget => FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES()};
    weaken($state->{rows});
    undef $rows;
    my $root = _visit($state, $name, 0);
    _fail('does not retain the complete original leaf relationship')
        unless _json()->encode($root->{leaves}) eq _json()->encode($relationship->{source_names});
    my $source_again = $direct->prepare_module(%source_args);
    my $target_again = $direct->prepare_declarations(%target_args);
    my $again = $direct->prepare_graph_operand_relationship(%source_args,
        graph_width_allocation => $input->{events}{$name}{graph_width_allocation});
    my $source_current = _source_state($ctx);
    my $current = $recovery->arithmetic_graph_width_allocation($name, $args{signal_info}, $input->{events}{$name}{expression});
    _fail('changed during preparation') unless $current
        && _json()->encode($current) eq _json()->encode($root->{plan}{graph_width_allocation})
        && _json()->encode($source) eq _json()->encode($source_again)
        && _json()->encode($target) eq _json()->encode($target_again)
        && _json()->encode($relationship) eq _json()->encode($again)
        && $snapshot eq $target_inputs->() && $source_snapshot eq $source_current;
    return _json()->decode(_json()->encode({%{$root->{plan}}, target_language => $target->{target_language},
        module_name => $target->{module_name}, source_scope => $relationship->{source_scope},
        expression_tree => $root->{tree}, node_order => $state->{order},
        nodes => {map {$_ => $state->{nodes}{$_}{plan}} @{$state->{order}}}}));
}

1;

=head1 NAME

FSM::DirectArithmeticGraphRangeSupport - Prepare private canonical arithmetic graph ranges

=head1 DESCRIPTION

C<prepare> joins an actual current FlattenedDT root row to complete selected
target namespace, declaration and intermediate-event inputs. The direct width
facade exposes C<prepare_arithmetic_graph_intermediate_range> with those same
arguments and a Verilog-family C<target_language>.

Every typed computed edge requires its actual selected arithmetic child event,
fresh origin/text and current completed graph or binary allocation policy.
Original module leaves require canonical physical target membership. Each
result and operand declaration must be plain unsigned, retain its independently
selected width and satisfy the exact local maximum. Conflicting allocation
origins, copied/stale/foreign metadata, missing child policies and cycles refuse.
Expanding the selected DAG must reproduce each bounded original graph tree,
including ordered operators and duplicate leaves. Shared schema checks bound
the expanded tree before JSON comparison.

Complete canonical source preparation proves every original leaf's frozen width
relationship. Mutable leaves require identical full range contracts; fixed
leaves retain independent widths. Default-one mutable leaves retain vector rank.
Full source/target inputs, canonical plans and completed policy recheck at return.
The row-view association remains weak; returned JSON retains no mutable owner.

The detached root plan contains its selected policy/origin/expression, width and
ordered current operands, original tree/leaves and canonical range representative.
C<node_order> lists children before parents; C<nodes> contains corresponding
per-child plans with their own first-leaf representative. This private API emits
no HDL and extends no VHDL profile. Focused controls cover deep source/target
changes hidden by unchanged canonical plans, supported dependency writes,
detached return data and expiry of the actual caller's row-map ownership during
preparation. These checks cover the graph row view; whole-backend/Core ownership
cycles and live graph range emission remain separately owned.

=cut
