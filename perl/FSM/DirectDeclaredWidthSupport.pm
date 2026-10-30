package FSM::DirectDeclaredWidthSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed refaddr);
use feature qw(signatures);
no warnings 'experimental::signatures';
use JSON::PP ();
use FSM::ParameterDefaultEnvironmentSupport;
use FSM::DeclaredWidthRangeSupport;
use FSM::DeclaredWidthBindingSupport;
use FSM::IntermediateWidthAllocationSupport;
use FSM::IntermediateWidthGraphPolicySupport;
use FSM::SourceBitwiseTreePolicySupport;
use FSM::Backend::VHDL::ParameterBindingEmitter;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _source_identity {return ref($_[0]) ? sprintf('%x', refaddr($_[0])) : undef}
sub _source_state_fail {confess "Direct source width snapshot $_[0]\n"}
sub _source_signal_state {
    my ($signal) = @_;
    _source_state_fail('requires actual Core source Signals')
        unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    return {identity => _source_identity($signal), map {$_ => scalar($signal->$_())}
        qw(name width type signed state_model declared_type_name declared_type_spec constraints
            declared_width_source declared_width_binding declared_width_requirements
            _intermediate_width_allocation_revision)};
}
sub _capture_source_state ($class, $ctx) {
    my $module = $ctx->{fsm_module};
    my $analysis = $ctx->{assignment_analysis};
    _source_state_fail('requires complete normalized assignment analysis') unless ref($analysis) eq 'HASH';
    my (%signals, %assignments);
    $signals{$_} = _source_signal_state($module->signals->{$_}) for sort keys %{$module->signals};
    for my $name (sort keys %$analysis) {
        my $entry = $analysis->{$name};
        my $lhs = ref($entry) eq 'HASH' ? $entry->{lhs_ast} : undef;
        _source_state_fail('requires normalized assignment LHS objects') unless blessed($lhs);
        my $row = {lhs_identity => _source_identity($lhs), lhs_class => ref($lhs), name => scalar($lhs->name)};
        if (UNIVERSAL::isa($lhs, 'FSM::CoreAST::SignalRef')) {
            $row->{signal} = _source_signal_state($lhs->signal);
        } else {
            $row->{state_next} = $lhs->can('is_fsm_state_next') ? scalar($lhs->is_fsm_state_next) : undef;
            $row->{assignments} = [map {
                my $assignment = $_;
                {map {$_ => $assignment->{$_}} qw(is_state_trans assignment_intent source_provenance operator rhs)}
            } @{$entry->{assignments} // []}];
        }
        $assignments{$name} = $row;
    }
    return JSON::PP->new->canonical->encode({module_identity => _source_identity($module), name => $module->name,
        parameters => $module->parameters, sources => $module->parameter_default_sources,
        bindings => $module->parameter_default_bindings, signals => \%signals, assignments => \%assignments});
}

sub prepare_module ($class, %args) {
    my $module = $args{fsm_module};
    confess "Direct module width preparation requires a Core module\n"
        unless blessed($module) && $module->isa('FSM::CoreAST::FSMModule');
    my %languages = (systemverilog => 'systemverilog', sv => 'systemverilog',
        verilog => 'verilog', v => 'verilog', vhdl => 'vhdl');
    my $language = $args{target_language};
    confess "Direct module width preparation requires a supported target language\n"
        unless defined($language) && !ref($language) && exists($languages{lc($language)});
    $language = $languages{lc($language)};
    my $analysis = $args{assignment_analysis};
    confess "Direct module width preparation requires complete assignment analysis\n"
        unless ref($analysis) eq 'HASH' && ref($module->signals) eq 'HASH';
    my %signals;
    for my $name (sort keys %{$module->signals}) {
        my $signal = $module->signals->{$name};
        _add_signal(\%signals, $signal);
        confess "Direct module width Signal membership does not match '$name'\n"
            unless $name eq $signal->name;
    }
    for my $name (sort keys %$analysis) {
        my $entry = $analysis->{$name};
        my $lhs = ref($entry) eq 'HASH' ? $entry->{lhs_ast} : undef;
        next if _is_state_control_assignment($module, $name, $entry, $lhs, \%signals);
        confess "Direct module width assignment '$name' requires a normalized SignalRef\n"
            unless blessed($lhs) && $lhs->isa('FSM::CoreAST::SignalRef');
        _add_signal(\%signals, $lhs->signal);
    }
    my $json = JSON::PP->new->canonical;
    my $maps = eval {$json->decode($json->encode({parameters => $module->parameters,
        sources => $module->parameter_default_sources, bindings => $module->parameter_default_bindings}))};
    confess "Direct module width preparation requires JSON-safe captured parameter maps: $@" if $@;
    confess "Direct module width preparation requires parameter, source and binding maps\n"
        if grep {ref($maps->{$_}) ne 'HASH'} qw(parameters sources bindings);
    my $environment;
    if (keys(%{$maps->{sources}}) || keys(%{$maps->{bindings}})) {
        $environment = FSM::ParameterDefaultEnvironmentSupport->prove_binding_observations(%$maps)->{environment};
    }
    my $scope = $environment ? $environment->{scope} : undef;
    my (%plans, %seen_parameters, @parameters, $symbolic);
    for my $name (sort keys %signals) {
        my $signal = $signals{$name};
        my $width = $signal->width;
        confess "Direct module width Signal '$name' requires a positive numeric width\n"
            unless defined($width) && !ref($width) && $width =~ /\A[0-9]+\z/ && $width > 0;
        my $binding = $signal->declared_width_binding;
        my $requirements = $signal->declared_width_requirements;
        _join_scope(\$scope, $binding->{scope}, $json) if $binding;
        _join_scope(\$scope, $requirements->{scope}, $json) if $requirements;
        if ($requirements) {
            my $expected = FSM::DeclaredWidthBindingSupport->equivalent_requirement_binding(signal => $signal);
            my $mutable = grep {
                my $capture = $_->{width_capture};
                $capture && grep {$_->{kind} eq 'parameter'} @{$capture->{observations}};
            } @{$requirements->{requirements}};
            confess "Direct module '$name' has a combined mutable width shape pending specialization\n"
                if $mutable && @{$requirements->{requirements}} > 1
                    && !$expected;
            confess "Direct module '$name' has a missing coherent width binding\n" if $mutable && !$binding;
            if ($binding) {
                confess "Direct module '$name' has inconsistent width binding and requirement snapshots\n"
                    unless $expected && $json->encode($binding) eq $json->encode($expected);
            }
        }
        confess "Direct module '$name' has a missing coherent width binding\n"
            if !$binding && defined($signal->declared_width_source);
        my $width_plan;
        if ($binding) {
            confess "Direct module '$name' width requires captured parameter declarations\n"
                if !$environment && keys(%{$maps->{parameters}});
            my $direct_environment = $environment // {scope => $scope, parameters => {}, declaration_order => []};
            $width_plan = FSM::DeclaredWidthRangeSupport->prepare_signal(
                signal => $signal, environment => $direct_environment, target_language => $language);
            $symbolic ||= $width_plan->{profile} eq 'symbolic';
            for my $parameter (@{$width_plan->{parameter_references}}) {
                push @parameters, $parameter unless $seen_parameters{$parameter}++;
            }
        }
        $plans{$name} = {name => $name, width => 0 + $width,
            signed => $signal->signed ? 1 : 0, state_model => $signal->state_model,
            declared_type_name => $signal->declared_type_name,
            declared_type_spec => $signal->declared_type_spec, width_plan => $width_plan};
    }
    return $json->decode($json->encode({profile => $symbolic ? 'symbolic' : 'fixed',
        target_language => $language, source_scope => $scope,
        signal_order => [sort keys %plans], signals => \%plans, parameter_references => \@parameters}));
}

sub _is_state_control_assignment ($module, $name, $entry, $lhs, $signals) {
    return 0 unless blessed($lhs) && $lhs->isa('FSM::AST::SignalRef')
        && $lhs->is_fsm_state_next;
    confess "Direct module width has an invalid compiler state-control reference\n"
        unless $name eq 'next_state' && $lhs->name eq $name && !exists($signals->{$name});
    my %states = map {$_->name => uc($_->name)}
        grep {$_->can('is_regular_state') ? $_->is_regular_state : $_->name !~ /^-/}
        @{$module->states};
    confess "Direct module width state control requires actual transition assignments\n"
        unless keys(%states) && ref($entry->{assignments}) eq 'ARRAY' && @{$entry->{assignments}};
    for my $row (@{$entry->{assignments}}) {
        my $transition = ref($row) eq 'HASH' ? $row->{is_state_trans} : undef;
        my $intent = ref($row) eq 'HASH' ? $row->{assignment_intent} : undef;
        my $origin = ref($row) eq 'HASH' ? $row->{source_provenance} : undef;
        my $target = ref($origin) eq 'HASH' ? $origin->{raw_target_state} : undef;
        confess "Direct module width has an inconsistent compiler state-control family\n"
            unless defined($transition) && !ref($transition) && $transition eq '1'
                && ref($intent) eq 'HASH' && ($intent->{assignment_family} // '') eq 'state_transition'
                && ($intent->{operator_symbol} // '') eq '<-'
                && ($intent->{sequencing} // '') eq 'clocked'
                && ($intent->{register_style} // '') eq 'output_named'
                && ($row->{operator} // '') eq '<-'
                && ref($origin) eq 'HASH' && ($origin->{origin} // '') eq 'state_transition'
                && defined($target) && !ref($target) && exists($states{$target})
                && defined($row->{rhs}) && !ref($row->{rhs}) && $row->{rhs} eq $states{$target};
    }
    return 1;
}

sub _add_signal ($signals, $signal) {
    confess "Direct module width membership requires an actual Core Signal\n"
        unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    my $name = $signal->name;
    confess "Direct module width Signal requires a simple physical name\n"
        unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    confess "Direct module width membership has distinct actual Signals named '$name'\n"
        if exists($signals->{$name}) && refaddr($signals->{$name}) != refaddr($signal);
    $signals->{$name} = $signal;
}

sub prepare_binary_operand_relationship ($class, %args) {
    my $names = $args{source_names};
    confess "Direct binary width relationship requires two actual operand names\n"
        unless ref($names) eq 'ARRAY' && @$names == 2
            && !grep {!FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($_)} @$names;
    return _prepare_operand_relationship($class, $names, 'binary', %args);
}

sub prepare_graph_operand_relationship ($class, %args) {
    my $names = FSM::IntermediateWidthGraphPolicySupport->leaf_names($args{graph_width_allocation});
    return _prepare_operand_relationship($class, $names, 'graph', %args);
}

sub prepare_source_tree_operand_relationship ($class, %args) {
    my $names = FSM::SourceBitwiseTreePolicySupport->leaf_names($args{source_tree_width_allocation});
    return _prepare_operand_relationship($class, $names, 'source tree', %args);
}

sub _prepare_operand_relationship ($class, $names, $family, %args) {
    my $source = $class->prepare_module(%args);
    my $module = $args{fsm_module};
    my @operands;
    for my $name (@$names) {
        my $signal = $module->signals->{$name};
        confess "Direct $family width relationship requires actual plain unsigned module operand '$name'\n"
            unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal')
                && !$signal->signed && !defined($signal->state_model)
                && !defined($signal->declared_type_name) && !defined($signal->declared_type_spec)
                && defined($signal->type) && !ref($signal->type) && $signal->type =~ /\A(?:wire|reg)\z/;
        my $constraints = $signal->constraints;
        confess "Direct $family width relationship excludes constrained operand '$name'\n"
            unless ref($constraints) eq 'ARRAY' && !@$constraints;
        push @operands, $source->{signals}{$name};
    }
    my $json = JSON::PP->new->canonical;
    my @symbolic = map {$_->{width_plan} && $_->{width_plan}{profile} eq 'symbolic' ? 1 : 0} @operands;
    my $result = {profile => 'fixed', target_language => $source->{target_language},
        source_scope => $source->{source_scope}, source_names => $names,
        operand_widths => [map {$_->{width}} @operands], width_plan => undef};
    if (grep {$_} @symbolic) {
        confess "Direct $family width relationship requires identical mutable operand contracts\n"
            if grep {!$_} @symbolic;
        my @relationships = map {
            my %relationship = %{$_->{width_plan}};
            delete $relationship{source_signal};
            \%relationship;
        } @operands;
        my $representative = $json->encode($relationships[0]);
        confess "Direct $family width relationship requires identical mutable operand contracts\n"
            if grep {$json->encode($_) ne $representative} @relationships;
        @{$result}{qw(profile width_plan)} = ('symbolic', $operands[0]{width_plan});
    }
    return $json->decode($json->encode($result));
}

sub prepare_binary_intermediate_range ($class, %args) {
    my $ctx = $args{flattened_dt};
    confess "Direct binary range requires an actual backend context\n"
        unless blessed($ctx) && $ctx->isa('FSM::HDL::FlattenedDT')
            && blessed($ctx->{fsm_module}) && $ctx->{fsm_module}->isa('FSM::CoreAST::FSMModule');
    my $width_owner = $ctx->{backend_sv_intermediate_width_support};
    confess "Direct binary range requires its canonical current width owner\n"
        unless ref($width_owner) eq 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport'
            && $width_owner->{flattened_dt} && $width_owner->{flattened_dt} == $ctx;
    my $language = $args{target_language};
    confess "Direct binary range currently requires a Verilog-family target\n"
        unless defined($language) && !ref($language) && lc($language) =~ /\A(?:systemverilog|sv|verilog|v)\z/;
    my $name = $args{signal_name};
    my $info = $args{signal_info};
    confess "Direct binary range requires its actual selected intermediate metadata\n"
        unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name) && ref($info) eq 'HASH';
    my $json = JSON::PP->new->canonical;
    my $target_inputs = sub {
        return $json->encode({namespace => $args{target_namespace},
            declarations => $args{target_declarations}, intermediates => $args{target_intermediates}});
    };
    my $target_snapshot = eval {$target_inputs->()};
    confess "Direct binary range requires JSON-safe actual target records\n" if $@;
    my $events = $json->decode($target_snapshot)->{intermediates};
    confess "Direct binary range requires actual intermediate events\n" unless ref($events) eq 'HASH';
    my $event = $events->{$name};
    my $origin_key = ref($event) eq 'HASH' && exists($event->{arithmetic_origin})
        ? 'arithmetic_origin' : 'bitwise_origin';
    confess "Direct binary range requires a closed selected allocation event\n"
        unless ref($event) eq 'HASH'
            && join(',', sort keys %$event) eq join(',', sort ($origin_key, 'expression', 'width_allocation'))
            && defined($event->{expression}) && !ref($event->{expression}) && length($event->{expression});
    my $policy = FSM::IntermediateWidthAllocationSupport->copy_record($event->{width_allocation});
    my $recovery = $ctx->{backend_sv_intermediate_recovery_support};
    confess "Direct binary range requires its current backend recovery owner\n"
        unless blessed($recovery)
            && $recovery->isa('FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport')
            && $recovery->{flattened_dt} == $ctx;
    my ($allocation_method, $origin_method) = $origin_key eq 'arithmetic_origin'
        ? ('arithmetic_width_allocation', 'binary_arithmetic_origin')
        : ('binary_width_allocation', 'binary_bitwise_origin');
    my $current = $recovery->$allocation_method($name, $info, $event->{expression});
    my $origin = $recovery->$origin_method($name, $info, $event->{expression});
    confess "Direct binary range has no same current allocation/origin/text proof\n"
        unless $current && $origin && $json->encode($current) eq $json->encode($policy)
            && $json->encode($origin) eq $json->encode($event->{$origin_key});
    my %source_args = (fsm_module => $ctx->{fsm_module}, assignment_analysis => $ctx->{assignment_analysis},
        target_language => $language);
    my %target_args = (%source_args, target_namespace => $args{target_namespace}, target_declarations => $args{target_declarations});
    my $target = $class->prepare_declarations(%target_args);
    confess "Direct binary range requires an actual intermediate signal declaration\n"
        unless ref($args{target_namespace}{signals}) eq 'ARRAY'
            && 1 == grep {defined($_) && !ref($_) && $_ eq $name} @{$args{target_namespace}{signals}};
    my @targets;
    for my $operand (@{$policy->{source_names}}) {
        confess "Direct binary range does not admit computed operand '$operand'\n" if exists($events->{$operand});
        my $mapped = $target->{signal_targets}{$operand};
        confess "Direct binary range operand '$operand' disagrees with actual target membership\n"
            unless defined($mapped) && $mapped eq $operand;
        push @targets, $mapped;
    }
    my $declarations = $args{target_declarations};
    my @rows = map {$declarations->{$_}} ($name, @targets);
    confess "Direct binary range requires actual plain unsigned target declarations\n"
        if grep {ref($_) ne 'HASH' || $_->{signed} || defined($_->{state_model})
            || defined($_->{declared_type_name}) || defined($_->{declared_type_spec})} @rows;
    confess "Direct binary range disagrees with actual selected declaration widths\n"
        unless FSM::IntermediateWidthAllocationSupport->matches_selected_widths($policy, map {$_->{width}} @rows);
    my $role = ($info->{source} // '') eq 'fsmgen_parsing' ? 'source_intermediate'
        : ($info->{source} // '') eq 'ast_factorization' ? 'factorized_intermediate' : undef;
    confess "Direct binary range has an unknown actual allocation role\n" unless $role;
    confess "Direct binary range conflicts with another declaration allocation family\n"
        if exists($rows[0]{width_origin});
    my $relationship = $class->prepare_binary_operand_relationship(%source_args, source_names => $policy->{source_names});
    my $again = $class->prepare_binary_operand_relationship(%source_args, source_names => $policy->{source_names});
    my $target_again = $class->prepare_declarations(%target_args);
    $current = $recovery->$allocation_method($name, $info, $event->{expression});
    confess "Direct binary range proof changed during preparation\n"
        unless $current && $json->encode($current) eq $json->encode($policy)
            && $json->encode($relationship) eq $json->encode($again)
            && $json->encode($target) eq $json->encode($target_again)
            && $target_snapshot eq $target_inputs->();
    return $json->decode($json->encode({profile => $relationship->{profile},
        target_language => $target->{target_language}, source_scope => $relationship->{source_scope},
        module_name => $target->{module_name}, target_name => $name, declaration_kind => 'signal',
        allocation_role => $role, source_names => $policy->{source_names}, operand_targets => \@targets,
        width_allocation => $policy, $origin_key => $origin, expression => $event->{expression},
        width_plan => $relationship->{width_plan}}));
}

sub prepare_arithmetic_graph_intermediate_range ($class, %args) {
    require FSM::DirectArithmeticGraphRangeSupport;
    return FSM::DirectArithmeticGraphRangeSupport->prepare(%args);
}

sub prepare_arithmetic_graph_declaration ($class, %args) {
    require FSM::DirectArithmeticGraphRangeSupport;
    return FSM::DirectArithmeticGraphRangeSupport->prepare_declaration(%args);
}

sub prepare_source_tree_declaration ($class, %args) {
    require FSM::DirectSourceBitwiseTreeRangeSupport;
    return FSM::DirectSourceBitwiseTreeRangeSupport->prepare_declaration(%args);
}

sub prepare_source_tree_intermediate_range ($class, %args) {
    require FSM::DirectSourceBitwiseTreeRangeSupport;
    return FSM::DirectSourceBitwiseTreeRangeSupport->prepare(%args);
}

sub prepare_computed_source_binary_declaration ($class, %args) {
    require FSM::DirectSourceBitwiseTreeRangeSupport;
    return FSM::DirectSourceBitwiseTreeRangeSupport->prepare_binary_declaration(%args);
}

sub prepare_computed_source_binary_intermediate_range ($class, %args) {
    require FSM::DirectSourceBitwiseTreeRangeSupport;
    return FSM::DirectSourceBitwiseTreeRangeSupport->prepare_binary(%args);
}

sub prepare_target_namespace ($class, %args) {
    my $source = $class->prepare_module(%args);
    my $json = JSON::PP->new->canonical->allow_nonref;
    my $target = eval {$json->decode($json->encode({namespace => $args{target_namespace},
        declarations => $args{target_declarations}}))};
    confess "Direct width target preparation requires JSON-safe namespace/declaration records: $@" if $@;
    my ($namespace, $declarations) = @{$target}{qw(namespace declarations)};
    confess "Direct width target preparation requires explicit namespace and declaration maps\n"
        unless ref($namespace) eq 'HASH' && ref($namespace->{identifier_map}) eq 'HASH'
            && ref($declarations) eq 'HASH';
    my $language = $source->{target_language};
    my $mapping = $namespace->{identifier_map};
    my $module_name = _target_identifier($language, $namespace->{module_name});
    my $physical_module = $args{fsm_module}->name;
    confess "Direct width target module mapping does not match the physical module\n"
        unless defined($physical_module) && !ref($physical_module)
            && ($mapping->{$physical_module} // $physical_module) eq $module_name;
    my $key = sub ($name) {return $language eq 'vhdl' ? lc($name) : $name};
    my %reserved = $language eq 'vhdl'
        ? map {$_ => 'generated type'} qw(natural std_logic std_logic_vector signed) : ();
    $reserved{$key->($module_name)} = 'module';
    my %roles;
    for my $bucket (qw(ports signals constants types parameter_names)) {
        confess "Direct width target namespace requires '$bucket' as an array\n"
            unless ref($namespace->{$bucket}) eq 'ARRAY';
        for my $raw (@{$namespace->{$bucket}}) {
            my $name = _target_identifier($language, $raw);
            my $identity = $key->($name);
            confess "Direct width target '$name' collides with $reserved{$identity}\n"
                if exists($reserved{$identity});
            $reserved{$identity} = $bucket;
            $roles{$name} = $bucket if $bucket eq 'ports' || $bucket eq 'signals';
        }
    }
    my %emitted = map {$_ => 1} @{$namespace->{parameter_names}};
    my %parameters;
    for my $name (sort keys %{$args{fsm_module}->parameters}) {
        my $target_name = _target_identifier($language, $mapping->{$name} // $name);
        confess "Direct width target parameter mapping has duplicate membership\n" if $parameters{$target_name}++;
    }
    confess "Direct width target emitted parameter membership does not match source mapping\n"
        unless keys(%parameters) == keys(%emitted) && !grep {!exists($emitted{$_})} keys %parameters;
    for my $name (@{$source->{parameter_references}}) {
        confess "Direct width target parameter '$name' renaming is unsupported\n"
            unless ($mapping->{$name} // $name) eq $name;
    }
    confess "Direct width target declaration membership does not match its namespace\n"
        unless keys(%roles) == keys(%$declarations) && !grep {!exists($declarations->{$_})} keys %roles;
    for my $name (sort keys %roles) {
        my $record = $declarations->{$name};
        confess "Direct width target declaration '$name' requires its actual name, positive width and signed flag\n"
            unless ref($record) eq 'HASH' && defined($record->{name}) && !ref($record->{name})
                && $record->{name} eq $name && defined($record->{width}) && !ref($record->{width})
                && $record->{width} =~ /\A[0-9]+\z/ && $record->{width} > 0
                && defined($record->{signed}) && !ref($record->{signed}) && $record->{signed} =~ /\A[01]\z/;
    }
    my (%signal_targets, %claimed);
    for my $name (@{$source->{signal_order}}) {
        my $target_name = _target_identifier($language, $mapping->{$name} // $name);
        confess "Direct width source Signal '$name' has no actual target declaration\n"
            unless exists($roles{$target_name});
        confess "Direct width target declaration '$target_name' has multiple source Signal owners\n"
            if $claimed{$target_name}++;
        $signal_targets{$name} = $target_name;
    }
    return $json->decode($json->encode({kind => 'direct_target_namespace',
        source_plan => $source, namespace => $namespace, declarations => $declarations,
        roles => \%roles, module_name => $module_name, signal_targets => \%signal_targets}));
}

sub prepare_declarations ($class, %args) {
    my $namespace_plan = $class->prepare_target_namespace(%args);
    my $source = $namespace_plan->{source_plan};
    my $declarations = $namespace_plan->{declarations};
    my $module_name = $namespace_plan->{module_name};
    my %roles = %{$namespace_plan->{roles}};
    my %signal_targets = %{$namespace_plan->{signal_targets}};
    my %claimed = map {$_ => 1} values %signal_targets;
    my $language = $source->{target_language};
    my $json = JSON::PP->new->canonical->allow_nonref;
    my (%ranges, @fixed);
    my @literal_sources;
    for my $name (@{$source->{signal_order}}) {
        my $target_name = $signal_targets{$name};
        my $signal = $source->{signals}{$name};
        my $record = $declarations->{$target_name};
        my $expected_width = $signal->{width};
        my $actual = $args{fsm_module}{signals}{$name};
        if ($language ne 'vhdl' && blessed($actual)
            && exists($actual->{_source_literal_width_allocation})) {
            # Core deliberately leaves unsized source allocation unknown. The
            # target's completed-source observer supplies its own literal rule;
            # neither the target row nor a copied compatibility width is proof.
            require FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;
            my $capture = FSM::SourceLiteralWidthAllocationSupport::_capture($actual, {phase => 'completed'});
            my $literal = FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport
                ->prepare(signal => $actual);
            confess "Direct literal declaration agreement requires current completed source intent\n"
                unless $capture && $literal
                    && FSM::IntermediateWidthAllocationSupport::_width($actual->{_width})
                        eq FSM::IntermediateWidthAllocationSupport::_width($signal->{width});
            $expected_width = $literal->{selected_width};
            push @literal_sources, [$name, $actual, $literal, $capture];
        }
        confess "Direct width target declaration '$target_name' disagrees with observed source width or signedness\n"
            unless $record->{width} == $expected_width && $record->{signed} == $signal->{signed};
        for my $field (qw(declared_type_name declared_type_spec)) {
            confess "Direct width target declaration '$target_name' disagrees with source $field\n"
                unless $json->encode($record->{$field}) eq $json->encode($signal->{$field});
        }
        confess "Direct width target declaration '$target_name' disagrees with source state model\n"
            if exists($record->{state_model})
                && $json->encode($record->{state_model}) ne $json->encode($signal->{state_model});
        my $width_plan = $signal->{width_plan};
        if ($width_plan && $width_plan->{profile} eq 'symbolic') {
            $ranges{$target_name} = {source_name => $name,
                declaration_kind => $roles{$target_name} eq 'ports' ? 'port' : 'signal', width_plan => $width_plan};
        } else {
            push @fixed, $target_name;
        }
    }
    for my $target_name (sort keys %$declarations) {
        my $record = $declarations->{$target_name};
        next unless exists($record->{width_origin});
        my $origin = $record->{width_origin};
        confess "Direct width auxiliary '$target_name' requires a closed signal-helper origin\n"
            unless $roles{$target_name} eq 'signals' && ref($origin) eq 'HASH'
                && join(',', sort keys %$origin) eq 'kind,source_name'
                && defined($origin->{kind}) && !ref($origin->{kind})
                && $origin->{kind} =~ /\A(?:register_next|register_q)\z/
                && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($origin->{source_name});
        confess "Direct width auxiliary '$target_name' conflicts with source Signal ownership\n"
            if $claimed{$target_name};
        my $name = $origin->{source_name};
        my $parent = $source->{signals}{$name};
        my $analysis = $args{assignment_analysis}{$name};
        my $lhs = ref($analysis) eq 'HASH' ? $analysis->{lhs_ast} : undef;
        confess "Direct width auxiliary '$target_name' requires its actual normalized assignment parent '$name'\n"
            unless $parent && blessed($lhs) && $lhs->isa('FSM::CoreAST::SignalRef')
                && $lhs->signal->name eq $name;
        confess "Direct width auxiliary '$target_name' disagrees with parent width or signedness\n"
            unless $record->{width} == $parent->{width} && $record->{signed} == $parent->{signed};
        for my $field (qw(state_model declared_type_name declared_type_spec)) {
            confess "Direct width auxiliary '$target_name' disagrees with parent $field\n"
                unless $json->encode($record->{$field}) eq $json->encode($parent->{$field});
        }
        my $width_plan = $parent->{width_plan};
        next unless $width_plan && $width_plan->{profile} eq 'symbolic';
        $ranges{$target_name} = {source_name => $name, declaration_kind => 'signal',
            width_plan => $width_plan, width_origin => $origin};
    }
    for my $proof (@literal_sources) {
        confess "Direct literal declaration agreement lost its current source observation\n"
            unless FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport
                ->current(signal => $proof->[1], observation => $proof->[2]);
    }
    # No source getters follow this whole-set barrier: a later observation must
    # not revoke an earlier helper after its own recheck.
    for my $proof (@literal_sources) {
        my ($name, $actual, $literal, $capture) = @$proof;
        confess "Direct literal declaration agreement source changed during final proof\n"
            unless (refaddr($args{fsm_module}{signals}{$name}) // 0) == refaddr($actual)
                && FSM::SourceLiteralWidthAllocationSupport::_unchanged($capture->{walk})
                && $json->encode($actual->{_source_literal_width_allocation})
                    eq $json->encode($literal->{source_capsule});
    }
    return $json->decode($json->encode({profile => $source->{profile}, target_language => $language,
        source_scope => $source->{source_scope}, module_name => $module_name,
        parameter_references => $source->{parameter_references}, signal_targets => \%signal_targets,
        fixed_signals => \@fixed, ranges => \%ranges}));
}

sub _target_identifier ($language, $name) {
    return FSM::Backend::VHDL::ParameterBindingEmitter->validate_identifier($name) if $language eq 'vhdl';
    confess "Direct width target requires a simple declaration identifier\n"
        unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
    confess "Direct width target declaration '$name' is reserved in SystemVerilog\n"
        if grep {$_ eq 'SystemVerilog'} @{FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages($name)};
    return $name;
}

sub _join_scope ($current, $candidate, $json) {
    confess "Direct module width captures have conflicting original source scope\n"
        if defined($$current) && $json->encode($$current) ne $json->encode($candidate);
    $$current //= $candidate;
}

1;

=head1 NAME

FSM::DirectDeclaredWidthSupport - Prepare actual direct module source-width plans

=head1 DESCRIPTION

C<prepare_module> consumes an actual Core C<fsm_module>, complete normalized
backend C<assignment_analysis> and C<target_language> (SystemVerilog/sv,
Verilog/v or VHDL). It joins module Signal membership with the actual Signals
held by normalized assignment C<lhs_ast> SignalRefs. One actual object reached
twice deduplicates; distinct objects claiming one physical name refuse.

Copied canonical module parameter maps pass the existing observation proof.
Coherent width bindings pass C<DeclaredWidthRangeSupport> with original lexical
scope, independent of the physical module name. Requirements and bindings must
agree. Combined requirements may share one binding only through complete original
capture equivalence with attested generated edges; every separate requirement
remains retained. Independent combined mutable shapes, missing/stale coherent
captures, foreign scope,
malformed membership and unsupported target profiles refuse instead of freezing
selected defaults. Independent fixed and named-type declarations retain their
numeric/type attributes. Legacy numeric modules gain no invented source scope.

The detached result contains C<profile> (symbolic or fixed), canonical
C<target_language>, optional original C<source_scope>, sorted C<signal_order>,
C<signals> and first-use unique C<parameter_references>. Each signal record
contains physical C<name>, numeric C<width>, C<signed>, C<state_model>,
C<declared_type_name>, C<declared_type_spec> and optional captured C<width_plan>.
The result retains no Core module, Signal or backend analysis graph.

Compiler state-transition LHS nodes retain their existing flagged
C<FSM::AST::SignalRef> control representation. Only the exact C<next_state>
identity with no source Signal collision, a nonempty complete transition family,
matching clocked output-register intent/provenance and an actual fixed state
target encoding is excluded from source data-width membership. Malformed,
foreign, empty or mixed control families refuse; ordinary data LHS nodes still
require canonical Core SignalRef ownership. This is a caller contract, not
attestation of caller-made control objects.

This is source-object preparation. Complete analysis membership is a caller
contract, not attestation of caller-made objects. Actual target names and full
declaration namespaces are checked by C<prepare_declarations>, described below.

C<prepare_binary_operand_relationship> is a source-only private prerequisite.
It takes the same actual module/analysis/language inputs plus exactly two
C<source_names>, re-derives canonical source/range plans and requires actual
plain unsigned wire/reg operands without state, named type or constraints.
Both fixed operands return a fixed profile with separate observed widths and
no range. If either is mutable, both complete symbolic plans must be identical
except for C<source_signal>: original scope, width contract/tree, ordered roots,
observed width, rank and target range spelling all retain. Equal defaults,
independent aliases, static floors and different trees refuse; no algebraic
or numeric ancestry guess is used.

The detached result contains C<profile>, C<target_language>, C<source_scope>,
ordered duplicate-preserving C<source_names>, separate C<operand_widths> and
C<width_plan>. A symbolic result carries the left operand's proved range as a
representative, retaining its source identity and width-one vector rank. This
proves neither allocation nor target membership and activates no helper range,
including VHDL; the actual-context/event join and emission remain separate.
Caller plans cannot replace actual source proof, and caller objects/kinds stay
unchanged.

C<prepare_graph_operand_relationship> takes the same source inputs plus a
C<graph_width_allocation> record. Its shared closed schema selects the original
ordered leaf names, including duplicates; current generated edge names do not
replace those sources. Every leaf must be an actual plain unsigned module
Signal. The same canonical relationship kernel checks the complete leaf vector:
all fixed leaves retain their independent widths, while any mutable leaf
requires every frozen range contract to agree except C<source_signal>.
The result has the same detached source-only fields as the binary helper and
retains the first original leaf's proved representative, including vector rank
at a default width of one. Equal defaults, alias roots, static floors and
different width trees cannot supply a mutable relationship.

The supplied graph record is a schema selector only. This method does not attest
its allocator, selected maximum, actual arithmetic graph or target membership.
It neither accepts caller range plans nor emits graph ranges or broadens VHDL
admission. Actual selected child/event/declaration closure must independently
join this source relationship before a graph range can be used. The binary API
still requires exactly two C<source_names> and retains its result contract.

C<prepare_source_tree_operand_relationship> takes the same source inputs plus
C<source_tree_width_allocation>. The separate closed source-bitwise-tree schema
selects every ordered original leaf slot, including duplicates and mixed
operators. The existing canonical operand-relationship kernel proves every
actual plain unsigned module leaf. Fully fixed leaves retain independent
widths. If any leaf is mutable, all complete frozen range plans must agree
except C<source_signal>, including original scope, expression tree, ordered
parameter roots, observed width and vector rank. Equal defaults, alias roots,
static floors, constraints and stale captures cannot supply that proof.

Its detached result has the same source-only fields as the binary and graph
relationship methods. The supplied tree policy is only a bounded leaf selector:
this method does not attest its allocation, selected maximum, current typed
source-helper edges or target membership. Recursive source intent and complete
target proof must bind those facts independently before live range use. It
accepts no caller range plan, emits no HDL and broadens no VHDL profile.

C<prepare_arithmetic_graph_intermediate_range> delegates the private transitive
join to C<FSM::DirectArithmeticGraphRangeSupport>. It takes the actual backend
context, current root name/metadata, Verilog-family language and complete target
namespace/declaration/intermediate-event records. Every typed computed edge must
join a fresh selected arithmetic child event and current policy; expanding those
edges must exactly reproduce the original bounded tree. All independent source,
child and result constraints and selected widths must agree. The original-leaf
relationship supplies the canonical frozen range, including default-one rank.

The detached result retains the root policy/origin/expression, actual width,
current ordered edges, original tree/leaves and range representative, plus
children-before-parent C<node_order> and per-node plans. Source/target snapshots,
canonical plans and complete current policy recheck at return. This method emits
no HDL, admits no graph VHDL profile and requires the actual weak row view to
remain current. Focused deep-input and weak caller-view controls qualify this
private join. Actual graph declaration emission consumes separate source intent
and final assembly independently invokes this target join; full selected-graph
and feature qualification remain separately owned.

C<prepare_arithmetic_graph_declaration> provides a separate source-only root
intent before target event completion. It requires the actual context/current
root, target language and exact selected C<expression>. Completed graph policy,
fresh origin/text, complete canonical source snapshots and the original-leaf
relationship must remain current. Its detached root fields agree with the
complete graph range plan except the transitive C<nodes>/C<node_order> inventory.
It attests no target membership or emitted range and does not fabricate events.
The actual declaration backend consumes this intent and final assembly compares
every root field with the independently completed target proof.

C<prepare_source_tree_declaration> delegates separate source-only root intent to
C<FSM::DirectSourceBitwiseTreeRangeSupport>. It requires the actual backend
context/current collected source row, Verilog-family language and freshly
selected C<expression>. Current completed source-tree allocation and full typed
origin/text must agree. Every ordered original module leaf must satisfy the
canonical frozen relationship and exact selected maximum. Default-one symbolic
rank and independent fixed widths preserve. Actual whole Core source-helper
references expand recursively through their own current completed source-tree
or binary bitwise attachment. Operators, association and duplicate original
leaves preserve under the shared expanded-tree depth and occurrence limits.

The detached root fields retain source policy/origin/expression, original tree
and duplicate leaves, selected width, source allocation role and representative
range. Complete source snapshots, canonical relationships, selected currentness,
installed owners and weak caller row membership recheck at return. Every child's
selected text, typed edges, current policy and complete metadata also recheck;
a final raw-field fence follows the last source read. The snapshot
implementation is shared here with arithmetic graph preparation; an unchanged
range plan cannot hide unrelated source-width constraint changes. The operation
attests no target membership, emits no HDL and broadens no VHDL profile. Recursive
complete selected-target proof and live range use remain separate.

C<prepare_source_tree_intermediate_range> independently joins the same actual
source-tree root to complete C<target_namespace>, C<target_declarations> and
C<target_intermediates> maps. Each actual typed child requires its own closed
selected tree or binary event, current completed policy, exact expression and
plain unsigned physical declaration. Original leaves require canonical target
membership and their full frozen width relationships. Every occurrence expands;
the detached C<nodes> inventory contains each physical child once in
children-before-parent C<node_order>. The root fields must match separate source
declaration intent. Full source/target inputs, child selections, raw currentness
and weak row membership recheck after preparation, including changes hidden by
equal derived ranges. Preparation emits no HDL; live declarations consume the
separate intent and final assembly independently invokes this target proof.
No VHDL profile is added.

C<prepare_computed_source_binary_declaration> and
C<prepare_computed_source_binary_intermediate_range> provide separate private
entrypoints for a source-owned binary bitwise root containing an actual typed
source-helper edge. They reuse the bounded original-leaf and independent
complete-target kernels above, retaining C<width_allocation>/C<bitwise_origin>
at the binary root and the complete expanded tree/ordered leaves separately.
Current tree or binary child policies, complete canonical relationships,
physical targets and final raw currentness remain required. Direct two-original
binary roots and the tree-only methods keep their existing ownership boundary.
The live backend now consumes this separate intent and independently closes its
source-range ledger. Private preparation itself still emits no HDL.

C<prepare_binary_intermediate_range> joins one selected helper privately for
SystemVerilog/Verilog. It requires an actual FlattenedDT context and its canonical
width owner, the exact C<signal_name>/C<signal_info> row, target language and
backend-owned C<target_namespace>, C<target_declarations> and
C<target_intermediates> records. Target data remains an input contract; actual
current context supplies allocation provenance. Fresh policy/origin/text must
agree, complete canonical target preparation must pass, and both actual operand
targets must match the selected physical names. Result/operand declarations must
be plain unsigned and satisfy the exact intrinsic maximum. Conflicting register
origins and computed intermediate operands remain outside this direct profile.

The selected event is closed to C<expression>, C<width_allocation> and exactly
one of C<bitwise_origin> or C<arithmetic_origin>. The corresponding current
recovery publisher supplies canonical XOR/AND/OR or C<+>, C<->, C<*>, C</>, C<%>
proof; a different family, operator or ordered origin cannot borrow that policy.
The returned record retains that same origin field. Arithmetic currently has
only actual factorizer allocation; this join invents no source-holder policy.

The source-only relationship helper supplies either fixed data without a range
or the identical frozen mutable range, including default-one vector rank.
Source-owned and factorized allocation roles remain distinct. Repeated source,
target and policy checks reject changes during preparation. Complete input
namespace/declaration/event snapshots must also agree at return: an equal derived
target plan cannot hide changes to computed-helper fields absent from that plan.
The detached result
contains C<profile>, canonical language/scope/module, C<target_name>, signal
C<declaration_kind>, C<allocation_role>, ordered source/target operands, allocation
and origin records, selected expression and optional representative C<width_plan>.
Caller plans, numeric equality and copied/stale/foreign metadata cannot supply
current allocation proof. This API emits no HDL and admits no binary VHDL helper.
Live Verilog-family declarations separately consume current allocation/source
proof; final assembly invokes this complete-target proof independently and
requires exact agreement with the detached emitted-plan ledger before success.
That live consumer admits the same bitwise/arithmetic origin families with
identical frozen mutable operand contracts. Fixed helpers retain numeric HDL;
other unary/n-ary/nested relationships remain outside this direct profile.

C<prepare_declarations> takes the same source arguments plus a backend-owned
C<target_namespace> and C<target_declarations> map. The namespace contains the
actual C<module_name>, original-to-target C<identifier_map> and complete target
C<parameter_names>, C<ports>, C<signals>, C<constants> and C<types> name arrays.
The declaration map covers exactly the ports and signals. Each row has its
actual C<name>, positive C<width>, boolean C<signed> and optional declared-type
name/spec and state model. Captured declaration metadata must be supplied from
the backend plan; it cannot be reconstructed by equal numeric widths.

Shared identifier policies check reserved names, namespace collisions and
VHDL case folding. Complete emitted parameter membership must match the actual
source mapping. Selected width roots cannot be renamed. Physical module and
signal mappings remain separate from lexical scope. Every actual source Signal
must match one target declaration with the same observed width, signedness and
declared type; a supplied state model must agree too.

For Verilog-family targets, an actual installed completed literal capsule has a
separate target-width observation. The canonical completed-source observer
independently derives the target literal floor and transitive leaf maximum;
Core's unknown allocation and compatibility width remain unchanged. This width
must match the physical declaration even when its placeholder would numerically
match an incorrect width-one row. Stale installed capsules refuse. Explicit
literal sizes retain their own floors. All signed/type/state and register-helper
checks remain in force; VHDL receives no such width observation. After complete
validation, recheck every literal observation and close all raw source/AST/holder
barriers without further source getters. This proves numeric declaration
agreement only: actual generation must also prove selected targets, expressions,
emitted ranges and whole-generation currentness through the separate ledgers.

The detached target result contains C<profile>, C<target_language>,
C<source_scope>, actual C<module_name>, ordered unique C<parameter_references>,
C<signal_targets>, C<fixed_signals> and C<ranges>. Each symbolic range entry
contains physical C<source_name>, C<declaration_kind> (port or signal) and the
proved C<width_plan>. Independent static/type rows stay on their fixed path.
Caller-made target records remain a contract, not provenance attestation.

Backend-only register-helper rows may carry the collector's optional closed
C<width_origin> (C<register_next> or C<register_q>, plus actual C<source_name>).
The parent must be an actual normalized Core assignment target in the source
plan. Independent source ownership of the helper target refuses. Observed width,
signedness, state model and declared type must match that parent. A symbolic
parent supplies the helper range through its existing canonical plan; the range
row additionally retains C<width_origin>. Fixed parents keep numeric helpers.
Names and numeric equality never select a parent or allocation family. Actual
producer completeness/authorship remains a caller obligation.

The direct Verilog-family post-flattening owner now consumes these checks for
captured declarations before returning HDL. Port and source-owned storage ranges
retain actual selected names and vector rank. Register next/q helpers consume
their recorded parent plans. Complete actual target qualification and comparison
with emitted port/storage plans and separate helper-origin records reject late
same-default ancestry or allocation-family changes. Other computed helper shapes and
complete generated specialization remain separately owned. The direct VHDL
source converter now uses paired plans for its bounded combinational profile.
Full compiler, override and runtime qualification remains pending. Whole backend
release is not claimed: task C<ISF-REDUCTION-DELIVERY.25> owns the independent
context/helper back-reference cycle reproduced without these preparation calls.

=cut

=head1 METHODS

=head2 prepare_target_namespace

C<prepare_target_namespace> takes the same actual source arguments as
C<prepare_module>, plus C<target_namespace> and C<target_declarations>. It exposes
only the canonical structural part of C<prepare_declarations>: actual module and
parameter mappings, reserved names and case-aware collisions, complete role/name/
declaration closure, valid numeric row shapes and unique physical membership for
every source Signal. Captured target records must still come from their producer.

The detached C<direct_target_namespace> record contains C<source_plan>, complete
C<namespace> and C<declarations>, physical C<roles>, C<module_name> and
C<signal_targets>. It retains no caller/module owners and emits no HDL. A valid
namespace does not establish source width, signedness, type, state, helper-origin,
currentness or symbolic-range agreement. Callers must prove those separately.
C<prepare_declarations> reuses this same validator, then retains all its existing
source numeric/type/state and auxiliary-origin checks and complete target result.
This separation supplies no numeric inference. The full validator's separate
completed-source literal observation does not derive authority from namespace
membership or copied numeric rows.

=cut
