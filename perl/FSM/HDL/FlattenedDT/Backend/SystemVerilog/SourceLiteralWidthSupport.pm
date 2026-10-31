package FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);
use FSM::CoreExpressionWidthSupport;
use FSM::SourceLiteralWidthAllocationSupport;
use FSM::IntermediateWidthAllocationSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;
use FSM::DirectDeclaredWidthSupport;
use FSM::ParameterDefaultEnvironmentSupport;
use FSM::Backend::VerilogFamily::WidthExpressionEmitter;

sub _json { return JSON::PP->new->canonical }
sub _identity { return FSM::SourceLiteralWidthAllocationSupport::_identity($_[0]) }
sub _width { return FSM::IntermediateWidthAllocationSupport::_width($_[0]) }
sub _maximum { return FSM::IntermediateWidthAllocationSupport::_maximum($_[0], $_[1]) }

# This is the existing direct SystemVerilog unsized-literal rule. It belongs to
# the target, not Core, and cannot replace an explicit source literal size.
sub _unsized_literal_width { return 32 }

# Reuse the single source capture's bounded child expansion. The Core walk for
# each local AST stops at its actual child references and receives their widths
# explicitly, so no inference walk recursively re-captures another helper.
sub _infer_capture {
    my ($capture, $observation) = @_;
    my $state = _json()->decode($capture->{state});
    my $edges = $state->{children} // [];
    my $proofs = $capture->{walk}{child_captures};
    return unless @$edges == @$proofs;
    my %resolutions;
    for my $index (0 .. $#$edges) {
        my $edge = $edges->[$index];
        return unless $edge->{phase} eq 'completed';
        my $width = _infer_capture($proofs->[$index]{capture}, $observation);
        return unless defined $width;
        $resolutions{$edge->{reference_identity}} = $width;
        push @{$observation->{reference_widths}}, {
            parent_identity => $state->{signal}{identity_token},
            reference_identity => $edge->{reference_identity},
            signal_identity => $edge->{signal_identity}, width => $width};
    }
    my $signal = $capture->{objects}[0];
    my $width = FSM::CoreExpressionWidthSupport->infer_width($signal->driving_ast,
        unsized_literal_width => \&_unsized_literal_width,
        source_reference_width => sub {
            my ($reference) = @_;
            my $identity = _identity($reference);
            return {width => $resolutions{$identity}} if exists $resolutions{$identity};
            # An unproved generated reference must never borrow its nominal
            # Core width. Independently declared leaves retain ordinary reads.
            return {width => undef} if $reference->signal->{attributes}{is_intermediate};
            return undef;
        });
    $width = _width($width);
    return unless defined $width;
    push @{$observation->{helper_widths}}, {signal_identity => $state->{signal}{identity_token},
        name => $state->{signal}{name}, width => $width};
    return $width;
}

sub _contributions {
    my ($capture, $observation) = @_;
    my %sources = map {$_->{identity_token} => $_} @{$capture->{walk}{operands}};
    for my $stamp (@{$capture->{walk}{width_stamps}}) {
        my ($node, $raw, $kind) = @$stamp;
        next unless $kind eq 'node';
        if ($node->isa('FSM::CoreAST::Literal')) {
            my $literal = _json()->decode($raw);
            my $sized = defined $literal->{width};
            my $width = _width($sized ? $literal->{width} : _unsized_literal_width());
            return unless defined $width;
            push @{$observation->{literals}}, {identity => _identity($node), literal => $literal,
                width => $width, sizing => $sized ? 'explicit' : 'target_unsized'};
            $observation->{literal_floor} = defined($observation->{literal_floor})
                ? _maximum($observation->{literal_floor}, $width) : $width;
        } elsif ($node->isa('FSM::CoreAST::SignalRef')) {
            my $reference = _json()->decode($raw);
            my $source = $sources{$reference->{signal}} or return;
            next if $source->{roles}{is_intermediate};
            push @{$observation->{leaves}}, {reference_identity => _identity($node), source => $source};
            $observation->{leaf_floor} = defined($observation->{leaf_floor})
                ? _maximum($observation->{leaf_floor}, $source->{width}) : $source->{width};
        }
    }
    return defined($observation->{literal_floor}) || defined($observation->{leaf_floor});
}

sub prepare {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args) eq 'signal';
    my $signal = $args{signal};
    return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    my $observation = eval {
        my $holder = $signal->{_source_literal_width_allocation};
        return unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state';
        my $raw = _json()->encode($holder);
        my $record = FSM::SourceLiteralWidthAllocationSupport->copy_record($holder->{record});
        my $capture = FSM::SourceLiteralWidthAllocationSupport::_capture($signal, {phase => 'completed'}) or return;
        return unless FSM::SourceLiteralWidthAllocationSupport::_tracked($capture)
            && FSM::SourceLiteralWidthAllocationSupport::_matches($record, $capture)
            && $capture->{state} eq $holder->{state};
        my $state = _json()->decode($capture->{state});
        my $result = {kind => 'systemverilog_source_literal_width',
            source_identity => $state->{signal}{identity_token}, source_capsule => _json()->decode($raw),
            reference_widths => [], helper_widths => [], literals => [], leaves => [],
            literal_floor => undef, leaf_floor => undef};
        my $width = _infer_capture($capture, $result);
        return unless defined($width) && _contributions($capture, $result);
        my $maximum = !defined($result->{literal_floor}) ? $result->{leaf_floor}
            : defined($result->{leaf_floor})
            ? _maximum($result->{literal_floor}, $result->{leaf_floor}) : $result->{literal_floor};
        return unless $width eq $maximum;
        $result->{selected_width} = $width;
        # All source/AST reads precede this raw barrier. Rechecking only the
        # last child would miss a getter that wrote an earlier source or holder.
        return unless FSM::SourceLiteralWidthAllocationSupport::_unchanged($capture->{walk})
            && _json()->encode($signal->{_source_literal_width_allocation}) eq $raw;
        _json()->decode(_json()->encode($result));
    };
    return $@ ? undef : $observation;
}

sub current {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args) eq 'observation,signal' && ref($args{observation}) eq 'HASH';
    my $observation = $class->prepare(signal => $args{signal}) or return;
    my $matches = eval {_json()->encode($observation) eq _json()->encode($args{observation})};
    return $matches ? $observation : undef;
}

# A numeric observation is deliberately short-lived. Re-derive it at each
# inference read; it is not a completed allocation or an emitted-range policy.
sub _inference_frame {
    my ($args, $observation) = @_;
    my $owner = $args->{width_support};
    return unless blessed($owner)
        && $owner->isa('FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport');
    my $context = $owner->{flattened_dt};
    return unless blessed($context) && $context->isa('FSM::HDL::FlattenedDT')
        && (refaddr($context->{backend_sv_intermediate_width_support}) // 0) == refaddr($owner);
    my $rows = $owner->_current_graph_inference_rows or return;
    my $name = $args->{signal_name};
    return unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
        && ref($args->{signal_registry}) eq 'HASH'
        && ref($args->{signal_info}) eq 'HASH'
        && (refaddr($rows->{$name}) // 0) == refaddr($args->{signal_info})
        && (refaddr($args->{signal_registry}{$name}) // 0) == refaddr($args->{signal_info});
    my $module = $context->{fsm_module};
    return unless blessed($module) && $module->isa('FSM::CoreAST::FSMModule');
    my $signals = $module->{signals};
    my $registry = $context->{intermediate_signals};
    return unless ref($signals) eq 'HASH' && ref($registry) eq 'HASH';
    my $signal = $signals->{$name};
    return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    my $source = _json()->decode($observation->{source_capsule}{state});
    my @members = ($source->{signal}, @{$source->{operands}});
    my @assignment_sources;
    for my $member (@members) {
        my $actual = $signals->{$member->{name}};
        if (!defined($actual)) {
            # Input-named register storage can be owned by the normalized LHS
            # instead of the module port/helper map. Join its actual object,
            # never a same-named numeric declaration or cached width.
            my $analysis = $context->{assignment_analysis};
            return unless ref($analysis) eq 'HASH';
            my $entry = $analysis->{$member->{name}};
            return unless ref($entry) eq 'HASH';
            my $lhs = $entry->{lhs_ast};
            return unless blessed($lhs) && $lhs->isa('FSM::CoreAST::SignalRef')
                && !defined($lhs->{slice});
            $actual = $lhs->{signal};
            push @assignment_sources, {name => $member->{name}, analysis => _identity($analysis),
                entry => _identity($entry), lhs => _identity($lhs)};
        }
        return unless blessed($actual) && _identity($actual) eq $member->{identity_token};
    }
    return unless _identity($signal) eq $observation->{source_identity};
    my $ast = $signal->{driving_ast};
    my @states;
    for my $row ($args->{signal_info}, $registry->{$name}) {
        return unless ref($row) eq 'HASH' && !defined($row->{state_model})
            && defined($row->{source}) && !ref($row->{source}) && $row->{source} eq 'fsmgen_parsing';
        for my $key (qw(ast driving_ast)) {
            return unless blessed($row->{$key}) && refaddr($row->{$key}) == refaddr($ast);
        }
        my $state = FSM::IntermediateWidthAllocationSupport::_factorized_metadata_state($row, $ast) or return;
        my $width = _width($row->{width});
        return unless defined $width;
        # Before normalization these rows carry the original Core compatibility
        # width. Only this branch's own numeric publication can be read again.
        if (defined $row->{width_source}) {
            return unless $row->{width_source} eq 'source_literal_intent'
                && $width eq $observation->{selected_width};
        } else {
            return unless $width eq _width($source->{signal}{width});
        }
        push @states, $state;
    }
    return {kind => 'systemverilog_source_literal_numeric', observation => $observation,
        owner_identity => _identity($owner), context_identity => _identity($context),
        module_identity => _identity($module), signals_identity => _identity($signals),
        registry_identity => _identity($registry), rows_identity => _identity($rows),
        epoch => $owner->{_width_inference_epoch}, rows_revision => $owner->{_graph_inference_rows_revision},
        (@assignment_sources ? (assignment_sources => \@assignment_sources) : ()),
        signal_name => $name, signal_info => $states[0], registered => $states[1]};
}

sub prepare_inference {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args) eq 'signal_info,signal_name,signal_registry,width_support';
    my $result = eval {
        my $owner = $args{width_support};
        return unless blessed($owner)
            && $owner->isa('FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport')
            && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($args{signal_name});
        my $context = $owner->{flattened_dt};
        return unless blessed($context) && $context->isa('FSM::HDL::FlattenedDT');
        my $module = $context->{fsm_module};
        return unless blessed($module) && $module->isa('FSM::CoreAST::FSMModule')
            && ref($module->{signals}) eq 'HASH';
        my $signal = $module->{signals}{$args{signal_name}};
        my $observation = $class->prepare(signal => $signal) or return;
        my $frame = _inference_frame(\%args, $observation) or return;
        # Source getters can mutate an earlier row or module membership. Read
        # all source state again, then close the join using raw target reads.
        return unless $class->current(signal => $signal, observation => $observation);
        my $after = _inference_frame(\%args, $observation) or return;
        return unless _json()->encode($frame) eq _json()->encode($after);
        _json()->decode(_json()->encode($frame));
    };
    return $@ ? undef : $result;
}

sub current_inference {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args) eq 'observation,signal_info,signal_name,signal_registry,width_support';
    my $saved = delete $args{observation};
    return unless ref($saved) eq 'HASH';
    my $current = $class->prepare_inference(%args) or return;
    my $matches = eval {_json()->encode($current) eq _json()->encode($saved)};
    return $matches ? $current : undef;
}

# Module width preparation reads more than the literal operands: parameter
# bindings and normalized assignment membership are canonical source inputs too.
# This fence uses raw fields only, so the last comparison cannot invoke another
# source getter that changes an earlier captured parameter or declaration.
sub _range_source_frame {
    my ($context) = @_;
    my $module = $context->{fsm_module};
    return unless blessed($module) && $module->isa('FSM::CoreAST::FSMModule')
        && ref($module->{signals}) eq 'HASH' && ref($context->{assignment_analysis}) eq 'HASH';
    my (%signals, %assignments, %maps);
    for my $name (sort keys %{$module->{signals}}) {
        my $signal = $module->{signals}{$name};
        return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
        $signals{$name} = {identity => _identity($signal),
            raw => FSM::SourceLiteralWidthAllocationSupport::_raw_signal($signal),
            literal => $signal->{_source_literal_width_allocation}};
    }
    for my $key (qw(parameters _parameter_default_sources _parameter_default_bindings)) {
        return unless ref($module->{$key}) eq 'HASH';
        $maps{$key} = {identity => _identity($module->{$key}), value => $module->{$key}};
    }
    for my $name (sort keys %{$context->{assignment_analysis}}) {
        my $entry = $context->{assignment_analysis}{$name};
        return unless ref($entry) eq 'HASH' && blessed($entry->{lhs_ast});
        my $lhs = $entry->{lhs_ast};
        $assignments{$name} = {identity => _identity($entry), lhs => _identity($lhs),
            lhs_class => ref($lhs), lhs_name => $lhs->{name},
            signal => blessed($lhs->{signal}) ? _identity($lhs->{signal}) : undef,
            assignments => [map {my $row = $_;
                +{map {$_ => $row->{$_}} qw(is_state_trans assignment_intent source_provenance operator rhs)}
            } @{$entry->{assignments} // []}]};
    }
    return _json()->encode({module => _identity($module), name => $module->{name},
        signal_map => _identity($module->{signals}), signals => \%signals, maps => \%maps,
        analysis => _identity($context->{assignment_analysis}), assignments => \%assignments});
}

sub prepare_range {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args) eq 'signal_info,signal_name,signal_registry,target_language,width_support';
    my $language = $args{target_language};
    return unless defined($language) && !ref($language) && $language =~ /\A(?:systemverilog|sv|verilog|v)\z/;
    my $result = eval {
        my %numeric_args = %args;
        delete $numeric_args{target_language};
        my $numeric = $class->prepare_inference(%numeric_args) or return;
        my $context = $args{width_support}{flattened_dt};
        my $before = _range_source_frame($context);
        return unless defined $before;
        my $module = $context->{fsm_module};
        my $source = FSM::DirectDeclaredWidthSupport->prepare_module(fsm_module => $module,
            assignment_analysis => $context->{assignment_analysis}, target_language => $language);
        my $environment = FSM::ParameterDefaultEnvironmentSupport->prove_binding_observations(
            parameters => $module->parameters, sources => $module->parameter_default_sources,
            bindings => $module->parameter_default_bindings)->{environment};
        return unless $environment && $source->{profile} eq 'symbolic';
        my @operands;
        my $mutable = 0;
        for my $leaf (@{$numeric->{observation}{leaves}}) {
            my $original = $leaf->{source};
            my $plan = $source->{signals}{$original->{name}} or return;
            return unless _width($plan->{width}) eq _width($original->{width});
            my $width_plan = $plan->{width_plan};
            my $contract = $width_plan && $width_plan->{profile} eq 'symbolic'
                ? $width_plan->{width_contract} : undef;
            $mutable ||= defined $contract;
            push @operands, {width => $original->{width}, width_contract => $contract};
        }
        return unless $mutable;
        push @operands, {width => $numeric->{observation}{literal_floor}}
            if defined($numeric->{observation}{literal_floor});
        my $range = FSM::Backend::VerilogFamily::WidthExpressionEmitter->lower_maximum_range(
            operands => \@operands, environment => $environment, target_language => $language,
            required_scope_kind => 'direct_module');
        my $plan = {kind => 'systemverilog_source_literal_range', numeric => $numeric,
            source_plan => $source, environment => $environment, operands => \@operands,
            source_state_digest => FSM::SourceLiteralWidthAllocationSupport::_capsule_digest($before),
            profile => 'symbolic', target_language => $source->{target_language},
            width => $numeric->{observation}{selected_width}, is_vector => 1, range_text => $range};
        return unless $class->current_inference(%numeric_args, observation => $numeric);
        my $after = _range_source_frame($context);
        return unless defined($after) && $before eq $after;
        _json()->decode(_json()->encode($plan));
    };
    return $@ ? undef : $result;
}

sub current_range {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args) eq 'observation,signal_info,signal_name,signal_registry,target_language,width_support';
    my $saved = delete $args{observation};
    return unless ref($saved) eq 'HASH';
    my $current = $class->prepare_range(%args) or return;
    my $matches = eval {_json()->encode($current) eq _json()->encode($saved)};
    return $matches ? $current : undef;
}

# Selection is a separate join from numeric inference: cached compatibility
# text cannot prove which actual typed AST is going to be emitted.
sub _selection_owners {
    my ($context) = @_;
    my $recovery = $context->{backend_sv_intermediate_recovery_support};
    my $renderer = $context->{enable_graph_ast_support};
    return unless blessed($recovery)
        && $recovery->isa('FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport')
        && blessed($renderer) && $renderer->isa('FSM::Synthesis::EnableGraph::ASTSupport')
        && (refaddr($recovery->{flattened_dt}) // 0) == refaddr($context)
        && (refaddr($renderer->{flattened_dt}) // 0) == refaddr($context);
    return {recovery_identity => _identity($recovery), renderer_identity => _identity($renderer)};
}

sub _selection_row_state {
    my ($row, $ast) = @_;
    my $numeric = FSM::IntermediateWidthAllocationSupport::_factorized_metadata_state($row, $ast) or return;
    my %text;
    for my $key (qw(expression rendered_expression rendered_expression_source
        runtime_ast_source runtime_ast_resolution_state runtime_ast_miss_reason)) {
        next unless exists $row->{$key};
        return if defined($row->{$key}) && ref($row->{$key});
        $text{$key} = $row->{$key};
    }
    return {numeric => $numeric, text => \%text};
}

sub _selection_target_frame {
    my ($args, $nodes) = @_;
    my $owner = $args->{width_support};
    my $context = $owner->{flattened_dt};
    my $owners = _selection_owners($context) or return;
    my %selected;
    for my $name (sort keys %$nodes) {
        my $numeric = $nodes->{$name}{numeric};
        my %input = (width_support => $owner, signal_name => $name,
            signal_info => $args->{signal_registry}{$name}, signal_registry => $args->{signal_registry});
        my $frame = _inference_frame(\%input, $numeric->{observation}) or return;
        return unless _json()->encode($frame) eq _json()->encode($numeric);
        my $ast = $context->{fsm_module}{signals}{$name}{driving_ast};
        my $row = _selection_row_state($input{signal_info}, $ast) or return;
        my $registered = _selection_row_state($context->{intermediate_signals}{$name}, $ast) or return;
        $selected{$name} = {row => $row, registered => $registered};
    }
    return {owners => $owners, selected => \%selected};
}

sub prepare_selection {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args)
        eq 'expression,signal_info,signal_name,signal_registry,target_language,width_support';
    return unless defined($args{expression}) && !ref($args{expression}) && length($args{expression});
    return unless defined($args{target_language}) && !ref($args{target_language})
        && $args{target_language} =~ /\A(?:systemverilog|sv|verilog|v)\z/;
    my $result = eval {
        my %input = %args;
        delete @input{qw(expression target_language)};
        my $initial = $class->prepare_inference(%input) or return;
        my $owner = $args{width_support};
        my $context = $owner->{flattened_dt};
        my $owners = _selection_owners($context) or return;
        my $before = _range_source_frame($context);
        return unless defined $before;
        my $signal = $context->{fsm_module}{signals}{$args{signal_name}};
        my $capture = FSM::SourceLiteralWidthAllocationSupport::_capture($signal, {phase => 'completed'}) or return;
        my $source = FSM::DirectDeclaredWidthSupport->prepare_module(
            fsm_module => $context->{fsm_module}, assignment_analysis => $context->{assignment_analysis},
            target_language => $args{target_language});
        my $mutable = 0;
        for my $leaf (@{$initial->{observation}{leaves}}) {
            my $plan = $source->{signals}{$leaf->{source}{name}} or return;
            $mutable ||= $plan->{width_plan} && $plan->{width_plan}{profile} eq 'symbolic';
        }
        my (%nodes, @order, %selected);
        for my $helper (@{$initial->{observation}{helper_widths}}) {
            my $name = $helper->{name};
            next if exists $nodes{$name}; # repeated typed edges remain in the original capsule
            my $actual = $context->{fsm_module}{signals}{$name};
            return unless blessed($actual) && _identity($actual) eq $helper->{signal_identity};
            my $row = $args{signal_registry}{$name};
            return unless ref($row) eq 'HASH';
            my $recovery = $context->{backend_sv_intermediate_recovery_support};
            my $expression = $recovery->render_intermediate_signal_expression($name, $row);
            return unless defined($expression) && !ref($expression) && length($expression);
            my $runtime = $recovery->resolve_intermediate_signal_runtime_ast($name, $row);
            my $defining = $recovery->resolve_intermediate_signal_defining_ast($name, $row);
            my $ast = $actual->{driving_ast};
            return unless blessed($runtime) && blessed($defining) && blessed($ast)
                && refaddr($runtime) == refaddr($ast) && refaddr($defining) == refaddr($ast);
            my $fresh = $context->{enable_graph_ast_support}->ast_to_systemverilog($runtime);
            return unless defined($fresh) && !ref($fresh) && $fresh eq $expression
                && ($name ne $args{signal_name} || $expression eq $args{expression});
            my $row_state = _selection_row_state($row, $ast) or return;
            my $registered = _selection_row_state($context->{intermediate_signals}{$name}, $ast) or return;
            my $numeric = $class->prepare_inference(width_support => $owner,
                signal_name => $name, signal_info => $row, signal_registry => $args{signal_registry}) or return;
            return unless $numeric->{observation}{source_identity} eq $helper->{signal_identity}
                && $numeric->{observation}{selected_width} eq $helper->{width};
            $nodes{$name} = {expression => $expression, numeric => $numeric};
            $selected{$name} = {row => $row_state, registered => $registered};
            push @order, $name;
        }
        return unless @order && $order[-1] eq $args{signal_name}
            && _json()->encode($nodes{$args{signal_name}}{numeric}{observation})
                eq _json()->encode($initial->{observation});
        my $range;
        if ($mutable) {
            $range = $class->prepare_range(%input, target_language => $args{target_language}) or return;
            return unless _json()->encode($range->{numeric})
                eq _json()->encode($nodes{$args{signal_name}}{numeric});
        }
        # Re-observe after all renderer reads, then finish with raw reads only.
        # A late getter must not hide a changed earlier child cache or source.
        for my $name (@order) {
            return unless $class->current_inference(width_support => $owner,
                signal_name => $name, signal_info => $args{signal_registry}{$name},
                signal_registry => $args{signal_registry}, observation => $nodes{$name}{numeric});
        }
        my $expected = {owners => $owners, selected => \%selected};
        my $target = _selection_target_frame(\%args, \%nodes) or return;
        return unless _json()->encode($expected) eq _json()->encode($target)
            && FSM::SourceLiteralWidthAllocationSupport::_unchanged($capture->{walk})
            && $before eq (_range_source_frame($context) // '');
        _json()->decode(_json()->encode({kind => 'systemverilog_source_literal_selection',
            target_language => $source->{target_language}, source_plan => $source,
            source_state_digest => FSM::SourceLiteralWidthAllocationSupport::_capsule_digest($before),
            numeric => $nodes{$args{signal_name}}{numeric}, range => $range,
            expression => $args{expression}, node_order => \@order, nodes => \%nodes, target_state => $target}));
    };
    return $@ ? undef : $result;
}

sub current_selection {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args)
        eq 'expression,observation,signal_info,signal_name,signal_registry,target_language,width_support';
    my $saved = delete $args{observation};
    return unless ref($saved) eq 'HASH';
    my $current = $class->prepare_selection(%args) or return;
    my $matches = eval {_json()->encode($current) eq _json()->encode($saved)};
    return $matches ? $current : undef;
}

# Captured records are data, not provenance. Rebuild source/selection authority
# first, then join every reachable helper and original leaf to physical records.
# The final Core/source declaration validator remains a separate obligation.
sub _target_inputs {
    my ($args) = @_;
    return _json()->encode({map {$_ => $args->{$_}}
        qw(target_namespace target_declarations target_intermediates)});
}

sub _plain_target {
    my ($namespace, $name, $width, $helper) = @_;
    return unless exists($namespace->{signal_targets}{$name})
        && $namespace->{signal_targets}{$name} eq $name
        && (!$helper || $namespace->{roles}{$name} eq 'signals');
    my $row = $namespace->{declarations}{$name};
    return unless ref($row) eq 'HASH' && defined(_width($row->{width}))
        && _width($row->{width}) eq $width && !$row->{signed}
        && !grep {defined($row->{$_})} qw(state_model declared_type_name declared_type_spec);
    return if grep {$_ ne 'name' && $_ ne 'width' && $_ ne 'signed'
        && $_ ne 'state_model' && $_ ne 'declared_type_name' && $_ ne 'declared_type_spec'} keys %$row;
    return $row;
}

sub prepare_targets {
    my ($class, %args) = @_;
    return unless join(',', sort keys %args) eq 'expression,signal_info,signal_name,signal_registry,'
        .'target_declarations,target_intermediates,target_language,target_namespace,width_support';
    my $result = eval {
        my $raw_targets = _target_inputs(\%args);
        return unless ref($args{target_intermediates}) eq 'HASH';
        my %input = %args;
        delete @input{qw(target_namespace target_declarations target_intermediates)};
        my $selection = $class->prepare_selection(%input) or return;
        my $context = $args{width_support}{flattened_dt};
        my $before = _range_source_frame($context);
        return unless defined $before;
        my $signal = $context->{fsm_module}{signals}{$args{signal_name}};
        my $capture = FSM::SourceLiteralWidthAllocationSupport::_capture($signal, {phase => 'completed'}) or return;
        my $namespace = FSM::DirectDeclaredWidthSupport->prepare_target_namespace(
            fsm_module => $context->{fsm_module}, assignment_analysis => $context->{assignment_analysis},
            target_language => $args{target_language},
            target_namespace => $args{target_namespace}, target_declarations => $args{target_declarations});
        return unless _json()->encode($namespace->{source_plan}) eq _json()->encode($selection->{source_plan});
        # Even unrelated event names must be actual internal declarations.
        # Their semantic families remain the responsibility of their own proof.
        for my $name (keys %{$args{target_intermediates}}) {
            return unless ($namespace->{roles}{$name} // '') eq 'signals';
            return if exists($namespace->{source_plan}{signals}{$name})
                && !$context->{fsm_module}{signals}{$name}{attributes}{is_intermediate};
        }
        my (%nodes, @leaves);
        for my $name (@{$selection->{node_order}}) {
            my $selected = $selection->{nodes}{$name};
            my $numeric = $selected->{numeric};
            my $observation = $numeric->{observation};
            my $width = $observation->{selected_width};
            my $declaration = _plain_target($namespace, $name, $width, 1) or return;
            my $ast = $context->{fsm_module}{signals}{$name}{driving_ast};
            my $shape = FSM::IntermediateWidthAllocationSupport->binary_whole_signal_shape($ast);
            my $expected = {expression => $selected->{expression},
                ($shape ? (bitwise_origin => {kind => 'binary_bitwise', %$shape}) : ())};
            if ($shape) {
                my $policy = $context->{backend_sv_intermediate_recovery_support}->binary_width_allocation(
                    $name, $args{signal_registry}{$name}, $selected->{expression});
                $expected->{width_allocation} = $policy if $policy;
            }
            my $event = $args{target_intermediates}{$name};
            return unless ref($event) eq 'HASH' && _json()->encode($event) eq _json()->encode($expected);
            # The original typed capsule retains ordered/repeated child edges;
            # the selection inventory deduplicates physical helper membership.
            my $state = _json()->decode($observation->{source_capsule}{state});
            my @children;
            for my $edge (@{$state->{children} // []}) {
                my @matches = grep {$selection->{nodes}{$_}{numeric}{observation}{source_identity}
                    eq $edge->{signal_identity}} @{$selection->{node_order}};
                return unless @matches == 1 && exists($nodes{$matches[0]});
                push @children, {target_name => $matches[0], %$edge};
            }
            my $maximum = $observation->{literal_floor};
            for my $leaf (@{$observation->{leaves}}) {
                my $source = $leaf->{source};
                my $row = _plain_target($namespace, $source->{name}, $source->{width}, 0) or return;
                return if exists($args{target_intermediates}{$source->{name}});
                $maximum = defined($maximum) ? _maximum($maximum, _width($row->{width}))
                    : _width($row->{width});
            }
            return unless $maximum eq $width;
            $nodes{$name} = {target_name => $name, declaration_kind => 'signal',
                declaration => $declaration, event => $event, children => \@children,
                numeric => $numeric};
        }
        for my $leaf (@{$selection->{numeric}{observation}{leaves}}) {
            my $source = $leaf->{source};
            push @leaves, {reference_identity => $leaf->{reference_identity}, target_name => $source->{name},
                declaration => $namespace->{declarations}{$source->{name}}};
        }
        # Reprepare the complete selected source, including original generic
        # operands/floors, after every target read. Only raw barriers follow.
        return unless $class->current_selection(%input, observation => $selection);
        my $target = _selection_target_frame(\%input, $selection->{nodes}) or return;
        return unless _json()->encode($target) eq _json()->encode($selection->{target_state})
            && FSM::SourceLiteralWidthAllocationSupport::_unchanged($capture->{walk})
            && $before eq (_range_source_frame($context) // '')
            && $raw_targets eq _target_inputs(\%args);
        _json()->decode(_json()->encode({kind => 'systemverilog_source_literal_targets',
            target_language => $selection->{target_language}, target_name => $args{signal_name},
            width => $selection->{numeric}{observation}{selected_width},
            selection => $selection, namespace => $namespace, nodes => \%nodes,
            node_order => $selection->{node_order}, leaf_targets => \@leaves}));
    };
    return $@ ? undef : $result;
}

sub current_targets {
    my ($class, %args) = @_;
    return unless exists($args{observation}) && ref($args{observation}) eq 'HASH';
    my $saved = delete $args{observation};
    my $current = $class->prepare_targets(%args) or return;
    my $matches = eval {_json()->encode($current) eq _json()->encode($saved)};
    return $matches ? $current : undef;
}

# A requirement selector, never an allocation proof. In particular, removing a
# completed holder must not turn a typed literal expression into numeric fallback.
sub requires_emission {
    my ($class, $signal, $rows) = @_;
    return 0 unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    return 1 if exists $signal->{_source_literal_width_allocation};
    return 0 unless $signal->{attributes}{is_intermediate}
        || (ref($rows) eq 'HASH' && ref($rows->{$signal->{name}}) eq 'HASH'
            && ($rows->{$signal->{name}}{source} // '') eq 'fsmgen_parsing');
    my $ast = $signal->{driving_ast};
    return 0 unless blessed($ast) && $ast->isa('FSM::CoreAST::BinaryOp')
        && ($ast->{operator} // '') =~ /\A[&|^]\z/
        && ref($ast->{operands}) eq 'ARRAY' && @{$ast->{operands}} >= 2;
    my $remaining = FSM::CoreExpressionWidthSupport::MAX_NODES();
    return _contains_literal($ast, {}, \$remaining, 0, $rows);
}

sub _contains_literal {
    my ($node, $active, $remaining, $depth, $rows) = @_;
    return 0 unless blessed($node);
    confess "Direct literal emission selector exceeds its bounded tree\n"
        if $depth > FSM::CoreExpressionWidthSupport::MAX_DEPTH() || --$$remaining < 0;
    my $identity = refaddr($node);
    confess "Direct literal emission selector contains a cycle\n" if $active->{$identity};
    local $active->{$identity} = 1;
    return 1 if $node->isa('FSM::CoreAST::Literal');
    if ($node->isa('FSM::CoreAST::SignalRef')) {
        my $signal = $node->{signal};
        return blessed($signal) && ($signal->{attributes}{is_intermediate}
            || (ref($rows) eq 'HASH' && ref($rows->{$signal->{name}}) eq 'HASH'
                && ($rows->{$signal->{name}}{source} // '') eq 'fsmgen_parsing'))
            ? _contains_literal($signal->{driving_ast}, $active, $remaining, $depth + 1, $rows) : 0;
    }
    for my $operand (@{ref($node->{operands}) eq 'ARRAY' ? $node->{operands} : []}) {
        return 1 if _contains_literal($operand, $active, $remaining, $depth + 1, $rows);
    }
    return 0;
}

sub _required_names {
    my ($class, $context, $rows) = @_;
    return [grep {$class->requires_emission($context->{fsm_module}{signals}{$_}, $rows)} sort keys %$rows];
}

sub _emission_record {
    my ($selection) = @_;
    my $width = $selection->{numeric}{observation}{selected_width};
    my $range = $selection->{range};
    return _json()->decode(_json()->encode({selection => $selection,
        width => $width, expression => $selection->{expression},
        profile => $range ? 'symbolic' : 'fixed',
        range_text => $range ? $range->{range_text} : $width > 1 ? '['.($width - 1).':0] ' : ''}));
}

sub prepare_emission {
    my ($class, %args) = @_;
    my $selection = $class->prepare_selection(%args) or return;
    return _emission_record($selection);
}

# This frame invokes no Core or renderer getters. Capture all participating AST
# stamps separately; raw Signal fields alone include only each root AST identity.
sub _generation_frame {
    my ($context, $rows) = @_;
    my $owner = $context->{backend_sv_intermediate_width_support};
    my %selected;
    for my $name (sort keys %$rows) {
        my $signal = $context->{fsm_module}{signals}{$name};
        next unless blessed($signal) && $signal->{attributes}{is_intermediate};
        my $ast = $signal->{driving_ast};
        my $row = _selection_row_state($rows->{$name}, $ast);
        my $registered = _selection_row_state($context->{intermediate_signals}{$name}, $ast);
        $selected{$name} = {row => $row, registered => $registered};
    }
    return _json()->encode({source => _range_source_frame($context),
        rows => _identity($rows), row_names => [sort keys %$rows], selected => \%selected,
        graph_rows => _identity($owner->{_graph_inference_rows}),
        epoch => $owner->{_width_inference_epoch}, rows_epoch => $owner->{_graph_inference_rows_epoch},
        rows_revision => $owner->{_graph_inference_rows_revision},
        owners => {map {$_ => _identity($context->{$_})} qw(backend_sv_intermediate_width_support
            backend_sv_intermediate_recovery_support enable_graph_ast_support
            backend_sv_consolidated_intermediate_declaration_support
            backend_sv_consolidated_intermediate_assignment_support)}});
}

sub capture_generation_fence {
    my ($class, %args) = @_;
    my ($context, $rows) = @args{qw(flattened_dt signal_registry)};
    my $names = $class->_required_names($context, $rows);
    return unless @$names;
    my @captures;
    for my $name (@$names) {
        my $signal = $context->{fsm_module}{signals}{$name};
        my $capture = FSM::SourceLiteralWidthAllocationSupport::_capture($signal, {phase => 'completed'});
        confess "Direct literal emission requires current completed source intent\n"
            unless $capture && $class->prepare(signal => $signal);
        push @captures, $capture;
    }
    # A later root's capture may mutate an earlier root. Close all walks before
    # establishing the generation boundary and again after the last final proof.
    confess "Direct literal emission source changed during generation capture\n"
        if grep {!FSM::SourceLiteralWidthAllocationSupport::_unchanged($_->{walk})} @captures;
    my $before = _generation_frame($context, $rows);
    return sub {
        confess "Direct literal emission source changed during generation\n"
            unless $before eq _generation_frame($context, $rows)
                && !grep {!FSM::SourceLiteralWidthAllocationSupport::_unchanged($_->{walk})} @captures;
        return 1;
    };
}

sub validate_emission {
    my ($class, %args) = @_;
    my ($context, $rows) = @args{qw(flattened_dt signal_registry)};
    my %targets = map {$_ => $args{$_}} qw(target_namespace target_declarations target_intermediates);
    my $before = _target_inputs(\%targets);
    my (%declarations, %assignments);
    # Required coverage comes from the selected rows and actual typed sources,
    # independently of either emitted ledger or the presence of assignment events.
    for my $name (@{$class->_required_names($context, $rows)}) {
        my $expression = $context->{backend_sv_intermediate_recovery_support}
            ->render_intermediate_signal_expression($name, $rows->{$name});
        my $plan = $class->prepare_targets(width_support => $context->{backend_sv_intermediate_width_support},
            signal_name => $name, signal_info => $rows->{$name}, signal_registry => $rows,
            expression => $expression, target_language => 'systemverilog', %targets);
        confess "Direct literal emission requires complete current selected targets\n" unless $plan;
        $declarations{$name} = _emission_record($plan->{selection});
        $assignments{$name} = $plan->{nodes}{$name}{event}{expression};
    }
    confess "Direct literal emitted declarations disagree with complete selected targets\n"
        unless _json()->encode(\%declarations)
            eq _json()->encode($context->{direct_declared_width_emitted_literal_ranges});
    confess "Direct literal emitted assignments disagree with complete selected targets\n"
        unless _json()->encode(\%assignments)
            eq _json()->encode($context->{direct_declared_width_emitted_literal_assignments});
    confess "Direct literal captured targets changed during emission proof\n"
        unless $before eq _target_inputs(\%targets);
    return 1;
}

1;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport - Target-only widths over completed literal source intent

=head1 METHODS

=head2 requires_emission

Internal requirement selector taking the actual Core Signal as its positional
argument and optionally the actual selected row registry. A completed holder
or selected source row still requires proof after loss of its intermediate role.
A bounded typed bitwise expression
containing a literal requires proof, including through generated child references.
This selector grants no width or ancestry authority. Removing a holder does not
authorize numeric fallback; malformed required intent fails its subsequent proof.

=head2 prepare_emission

Take the exact C<prepare_selection> arguments and return detached C<selection>,
C<width>, C<expression>, C<profile> and C<range_text>. Fixed sources retain numeric
ranges; mutable sources retain the complete independently prepared maximum. The
declaration emitter records precisely this result in its generation-local ledger
and uses its range text. The assignment emitter separately records its agreeing
selected expression. This is emission intent, not complete physical target proof.

=head2 capture_generation_fence

Internal assembly boundary taking C<flattened_dt> and the actual selected
C<signal_registry>. Return a closure, or undef when no selected literal helper
requires proof. Capture every participating completed source walk before emission;
missing intent throws. The returned closure compares raw source/AST/capsule,
selected row, namespace, installed owner and inference-epoch state after all final
proofs. It invokes no Core or renderer getters and throws on change. Assembly
invalidates capture for any generation exception and localizes both ledgers, so
fresh same-backend reuse cannot inherit failed emission intent.

=head2 validate_emission

Internal final assembly check taking C<flattened_dt>, C<signal_registry> and the
complete C<target_namespace>, C<target_declarations>, C<target_intermediates>
snapshot. Independently enumerate required selected typed sources, reprepare
each complete physical target proof and compare exact declaration records and
assignment expressions with both emitted ledgers. Missing events, extra ledger
members, changed ranges, expressions or source authority throw; success returns
one. Complete target inputs and the whole-generation raw fence must still agree
after subsequent proofs. Final declaration agreement independently consumes the
completed-source literal observation while leaving unknown Core widths intact.
Bounded fixed/mutable sized and unsized generation can now complete. External HDL execution and
full feature qualification remain separate.

=head2 prepare_targets

Takes the C<prepare_selection> arguments and complete actual C<target_namespace>,
C<target_declarations> and C<target_intermediates> snapshots. Canonical namespace
closure is shared with C<DirectDeclaredWidthSupport>. Every selected helper and
original leaf must have its unrenamed plain unsigned declaration, independently
matching its selected maximum or original leaf width. Helpers require internal
signal roles. Each complete assignment event must match fresh typed selection,
including the existing ordered binary origin/allocation when independently
proved; missing, conflicting or foreign families withhold.

The detached C<systemverilog_source_literal_targets> result retains complete
C<selection> (including original generic operands and fixed floors), canonical
C<namespace>, C<node_order>, C<nodes>, duplicate-preserving C<leaf_targets> and
root C<width>. Nodes include actual declarations/events, numeric observations and
ordered typed child edges; physical helpers deduplicate in postorder. Complete
selection re-observation and raw source/row/owner/target barriers close the join.
Target snapshots are data inputs, not collector provenance or proof of emitted
range text. Other event families retain their own semantic qualification.

This private proof does not install live ranges or bypass final Core/source
width agreement. The mutable regression observes actual numeric emitter events
through explicit test-only source/binary symbolic-selector seams; it does not
qualify normal generic generation. Live emission now has separate ledgers and
complete-target comparison; final Core/source-width agreement stays independent.

Fixed inline logical shifts inside literal-containing bitwise trees retain the
left data width. Amount branches contribute neither literal nor leaf floors;
the complete original amount remains in source/currentness fences. A tree whose
only literals are amounts can therefore have no literal floor. Data literals
keep independent explicit sizes or the existing target unsized floor.
Input-named storage joins its actual normalized assignment LHS when absent from
the module Signal map; saved numeric frames bind analysis, row and LHS identities.
Mutable inline-shift dependencies and standalone shift policies are not added.

=head2 current_targets

Also takes C<observation>. Reprepares the entire physical proof and compares the
complete saved record with raw scalar kinds intact. Edited detached output,
stale rows/epochs/owners or changed source/target records supply no saved authority.

=head2 prepare_selection

C<prepare_selection> takes the C<prepare_range> arguments plus the actual root
C<expression> selected for emission. It joins fixed or mutable literal intent
to the installed recovery and AST-rendering owners. Every physical helper in the
bounded original capture must have its actual current collected/registered row,
normalization epoch and completed source capsule. Runtime, defining and cached
ASTs must be the actual source AST; freshly rendering it must equal the selected
text. Cached text, equal numeric widths and matching foreign ASTs supply no proof.

The detached C<systemverilog_source_literal_selection> record carries canonical
C<target_language>, complete C<source_plan>, C<source_state_digest>, root C<numeric>,
C<expression> and nullable C<range>, children-before-parent C<node_order>, C<nodes>
and exact raw C<target_state>. Each node retains its selected expression and own
numeric frame. Distinct helpers appear once; ordered repeated typed edges remain
in the original numeric source capsules. Actual mutable leaves require the
complete generic range proof; fixed leaves invent no mutable relationship.

All numeric frames recheck after the last rendering read. Final raw row/text,
owner, source AST/capsule and complete module/parameter/assignment barriers reject
changes to earlier helpers during later reads. Returned data retains no owners
or row containers. Missing, stale, foreign, constrained or inconsistent joins
withhold atomically. This proves selected expression intent, not actual emitted
declaration/event membership or a completed ledger. Live emission and final
source/target agreement remain separate consumers.

=head2 current_selection

C<current_selection> additionally takes a saved C<observation> and returns fresh
detached data only when the entire selection rederives exactly. Changed source
namespaces, rows, epochs, owners, text, ASTs or original kinds cannot reuse it.

=head2 prepare_range

C<prepare_range> takes the C<prepare_inference> inputs plus a Verilog-family
C<target_language>. It joins the actual numeric frame to canonical direct module
width preparation and the original proved parameter environment. Each original
leaf contributes its own prepared mutable width contract or independent fixed
width; the target literal floor is appended separately. The shared bounded
C<WidthExpressionEmitter::lower_maximum_range> renders these operands without
merging equal defaults or promoting helper placeholders to independent floors.

The detached C<systemverilog_source_literal_range> record contains C<numeric>,
C<source_plan>, C<environment>, ordered C<operands>, C<source_state_digest>, symbolic C<profile>, canonical
C<target_language>, selected C<width>, packed C<is_vector> and C<range_text>.
At least one actual mutable leaf is required; fixed-only sources withhold this
generic preparation. Foreign targets, missing/stale rows, invalid canonical
bindings or over-bound range inputs withhold too. A final numeric re-observation
and raw module/namespace/assignment-source barrier reject late changes, including
parameter changes made after numeric source rechecking. This method installs no
declaration policy and proves no selected expression, emitted ledger or final
source/target declaration agreement.
The source-state digest uses the existing strict UTF-8 digest kernel and binds
the complete raw capture and actual namespace identities into saved-plan
currentness; replacing a namespace with matching data cannot reuse an old plan.

=head2 current_range

C<current_range> takes the same inputs plus C<observation> and returns a fresh
detached plan only if the complete saved record still matches. Editing escaped
range data grants no source authority. These are optional preparation methods;
live generic literal declaration integration remains separately owned.

=head2 prepare

C<< prepare(signal => $actual_core_signal) >> returns a detached JSON observation,
which can be absent. It requires the actual current completed
C<source_literal_width_allocation> capsule and all actual typed child
relationships. One globally bounded source capture authenticates the complete
nested graph. Shared Core inference then resolves each local AST using explicit
child reference widths and this target's existing 32-bit unsized-literal rule.
Explicit literal sizes and independent declared leaf widths remain separate.
Core widths, raw literal value/radix/size, source JSON kinds, declarations and
mutable parameter metadata are never changed.

The observation keeps the complete original C<source_capsule>, root lifetime
C<source_identity>, ordered C<helper_widths> and typed C<reference_widths>, and
ordered original C<leaves> and C<literals>, including repeated occurrences.
C<selected_width>, nullable C<literal_floor> and nullable C<leaf_floor> are canonical
positive decimal strings. Leaf source descriptors retain their original raw
metadata and independent width contracts. Literal entries retain raw source
records, target width and C<explicit> or C<target_unsized> sizing. A generated
child's compatibility width is never an independent leaf floor.

Missing, revoked, foreign, unsupported, cyclic, over-bound or independently
constrained source intent withholds. A final complete raw barrier rejects source
or holder changes during inference, including matching writes. Exceptions during
source observation also withhold. No source owners, callbacks or registries are
retained by the returned data.

This is source observation only: it supplies no backend row, normalization epoch,
inference branch attestation, generic range, signedness legality, emitted target
identity or final source/target agreement. Live numeric and declaration consumers
remain separate. Scalar wrappers retain the shared Core walk's own scalar rule;
wrappers cannot themselves impersonate a completed literal helper capsule.

=head2 current

C<< current(signal => $actual_core_signal, observation => $saved_observation) >>
re-derives the complete observation and returns fresh detached data only on exact
JSON equality. Changed kinds, floors, identities, source metadata and extra fields
withhold. It does not upgrade the observation to target eligibility.

=head2 prepare_inference

C<< prepare_inference(width_support => $installed_owner, signal_name => $name,
signal_info => $actual_row, signal_registry => $consumer_rows) >> returns a
detached numeric observation for the current normalization epoch. The actual
row must belong to the owner's current weak canonical row view and the supplied
consumer map. The installed context/module/registry, root and every original
source member, driving AST and independent row constraints must agree. Both
collected and registered rows must carry either the original Core compatibility
width or this branch's own C<source_literal_intent> width publication. Foreign
width branches, signed/typed/constrained rows and missing or revoked source
intent withhold. Source re-observation followed by a raw target-frame comparison
rejects target changes made during source reads.

The direct width resolver consumes this fresh observation before native/cached
compatibility metadata. Its whole-reference resolver also uses the qualified
target width before a Core helper's nominal width. This repairs fixed nested
literal truncation without writing Core widths or reconstructing dependencies
from numeric equality. Existing unsupported profiles retain their compatibility
path and acquire no literal authority. Independent floors, generic ranges,
selected text, final declaration/source agreement and emitted ledgers still
require their separate consumers. This frame supplies no completed allocation
or range eligibility and is re-derived at each numeric read.

=head2 current_inference

Accept the same arguments plus C<observation>. Re-derive the entire numeric
frame and return detached data only on exact JSON agreement, including epoch,
row and registry identities and raw source kinds. A copied or changed saved
frame cannot authorize a later row or epoch. The frame contains no live owners.

=cut
