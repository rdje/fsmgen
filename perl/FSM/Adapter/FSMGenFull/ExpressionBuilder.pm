package FSM::Adapter::FSMGenFull::ExpressionBuilder;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Data::Dumper;
use Scalar::Util qw(blessed refaddr);
use JSON::PP ();
use FSM::CoreAST;
use FSM::CoreExpressionWidthSupport;
use FSM::IntermediateWidthAllocationSupport;
use FSM::SourceBitwiseTreeWidthSupport;
use FSM::SourceLiteralWidthAllocationSupport;
use FSM::Debug;
use FSM::Package::AggregatePathSupport;
use FSM::Package::ExpressionOperatorSupport qw(is_reduction_operator);
use FSM::Package::IntegerLiteralSupport;
use FSM::Package::PayloadLiteralSupport;
use FSM::Package::PayloadTypeSupport;
use FSM::Support::DocumentationHints qw(supported_boundary_hint);

sub new($class, %args) {
    # Requires a signal_manager
    Carp::confess "ExpressionBuilder requires a signal_manager" unless $args{signal_manager};
    
    return bless {
        debug => $args{debug} // 0,
        signal_manager => $args{signal_manager},
        intermediate_counter => 0,
        state_active_references => [],
    }, $class;
}

sub state_active_references($self) {
    return [ @{$self->{state_active_references} || []} ];
}

sub clear_state_active_references($self) {
    $self->{state_active_references} = [];
    return 1;
}

sub _capture_intermediate_width_allocations($self, $callback) {
    confess "Intermediate allocation capture requires a callback\n" unless ref($callback) eq 'CODE';
    confess "Intermediate allocation capture is already active\n"
        if exists $self->{_intermediate_width_allocation_capture};
    local $self->{_intermediate_width_allocation_capture} = [];
    local $self->{_source_bitwise_tree_width_allocation_capture} = [];
    local $self->{_source_literal_width_allocation_capture} = [];
    my $value = $callback->();
    my $packet = {value => $value, events => $self->{_intermediate_width_allocation_capture}};
    $packet->{source_tree_events} = $self->{_source_bitwise_tree_width_allocation_capture}
        if @{$self->{_source_bitwise_tree_width_allocation_capture}};
    $packet->{source_literal_events} = $self->{_source_literal_width_allocation_capture}
        if @{$self->{_source_literal_width_allocation_capture}};
    return $packet;
}

sub _stage_source_literal_width_allocation($self, $signal) {
    my $events = $self->{_source_literal_width_allocation_capture} or return;
    my $children = $self->_source_literal_birth_children;
    my $capture = $self->_source_literal_allocation_registry_matches($signal, $children) or return;
    my $holder = eval {FSM::SourceLiteralWidthAllocationSupport->prepare_core(
        signal => $signal, record => $capture->{record}, track => 1, children => $children)} or return;
    return unless FSM::SourceLiteralWidthAllocationSupport->current_core(
        signal => $signal, holder => $holder, children => $children);
    # Fence the exact actual registry after potentially mutating source reads.
    # These raw membership checks invoke no user-facing getters.
    return unless $self->_literal_registry_contains($capture->{objects});
    push @$events, {signal_name => $signal->{name}, holder => $holder};
}

sub _source_literal_birth_children($self, $events = undef) {
    $events //= $self->{_source_literal_width_allocation_capture} // [];
    return {phase => 'birth', lookup => sub {
        my ($reference) = @_;
        my $signal = $reference->signal;
        my $registry = $self->{signal_manager}{signal_registry};
        return unless ref($registry) eq 'HASH'
            && refaddr($registry->{$signal->{name}} // {}) == refaddr($signal);
        my ($event) = grep {$_->{signal_name} eq $signal->{name}}
            @$events;
        return $event ? $event->{holder} : undef;
    }};
}

sub _source_literal_allocation_registry_matches($self, $signal, $children = undef) {
    my $capture = eval {FSM::SourceLiteralWidthAllocationSupport::_capture($signal, $children)} or return;
    return unless $self->_literal_registry_contains($capture->{objects});
    return $capture;
}

sub _literal_registry_contains($self, $objects) {
    my $registry = $self->{signal_manager}{signal_registry};
    return unless ref($registry) eq 'HASH';
    for my $object (@$objects) {
        return unless refaddr($registry->{$object->{name}} // {}) == refaddr($object);
    }
    return 1;
}

sub _stage_intermediate_width_allocation($self, $signal, $operator, $operands, $width) {
    my $events = $self->{_intermediate_width_allocation_capture} or return;
    return unless defined($width) && $width > 0 && @$operands == 2;
    return if grep {!blessed($_) || !$_->isa('FSM::CoreAST::SignalRef') || defined($_->slice)} @$operands;
    my $record = {kind => 'binary_operand_max', operator => $operator,
        source_names => [map {$_->signal->name} @$operands], selected_width => $width};
    # Unsupported signed/named/context shapes retain their ordinary numeric
    # allocation. Withholding a private event must not change source admission.
    my $holder = eval {FSM::IntermediateWidthAllocationSupport->prepare_core(
        signal => $signal, record => $record, track => 1)};
    return unless $holder;
    push @$events, {signal_name => $signal->name, holder => $holder};
}

sub _stage_source_tree_width_allocation($self, $signal, $operator, $operands, $width) {
    my $events = $self->{_source_bitwise_tree_width_allocation_capture} or return;
    return unless @$operands > 2 && defined(FSM::IntermediateWidthAllocationSupport::_width($width));
    return if grep {!blessed($_) || !$_->isa('FSM::CoreAST::SignalRef') || defined($_->slice)} @$operands;
    my @names = map {$_->signal->name} @$operands;
    my $tree = ['signal', $names[0]];
    $tree = [$operator, $tree, ['signal', $names[$_]]] for 1 .. $#names;
    my $record = {kind => 'source_bitwise_tree_operand_max', operator => $operator,
        source_names => \@names, expression_tree => $tree, selected_width => $width};
    return unless $self->_source_tree_allocation_registry_matches($signal);
    # Only this fresh allocator supplies intent. The Core adapter independently
    # checks that the supplied original tree agrees with the actual held AST.
    my $holder = eval {FSM::SourceBitwiseTreeWidthSupport->prepare_core(
        signal => $signal, record => $record, track => 1)};
    return unless $holder;
    push @$events, {signal_name => $signal->name, holder => $holder};
}

sub _source_tree_allocation_registry_matches($self, $signal) {
    return unless blessed($signal);
    # The adapter's bounded shape capture exposes actual objects only for this
    # transient join. No object is stored in the detached journal.
    my $capture = eval {FSM::SourceBitwiseTreeWidthSupport::_capture($signal)} or return;
    for my $object (@{$capture->{objects}}) {
        return unless refaddr($self->{signal_manager}->get_signal($object->name) // {}) == refaddr($object);
    }
    return 1;
}

sub _allocation_registry_matches($self, $signal) {
    return unless $signal && refaddr($self->{signal_manager}->get_signal($signal->name) // {}) == refaddr($signal);
    my $ast = $signal->driving_ast;
    return unless blessed($ast) && $ast->isa('FSM::CoreAST::BinaryOp');
    for my $operand ($ast->left, $ast->right) {
        return unless blessed($operand) && $operand->isa('FSM::CoreAST::SignalRef');
        my $source = $operand->signal;
        return unless $source && refaddr($self->{signal_manager}->get_signal($source->name) // {}) == refaddr($source);
    }
    return 1;
}

sub _allocation_transition($self, $signal, $attribute, $value, $write, $metadata = undef) {
    return $self->_literal_allocation_transition($signal, $attribute, $value, sub {
        $self->_source_tree_allocation_transition($signal, $attribute, $value, sub {
            $self->_binary_allocation_transition($signal, $attribute, $value, $write);
        });
    }, $metadata);
}

sub _literal_allocation_transition($self, $signal, $attribute, $value, $write, $metadata) {
    my $events = $self->{_source_literal_width_allocation_capture};
    return $write->() unless $events && @$events && $signal;
    my $children = $self->_source_literal_birth_children;
    my @current;
    for my $event (@$events) {
        my $result = $self->{signal_manager}->get_signal($event->{signal_name});
        my $capture = $self->_source_literal_allocation_registry_matches($result, $children) or next;
        next unless grep {refaddr($_) == refaddr($signal)} @{$capture->{objects}};
        next unless FSM::SourceLiteralWidthAllocationSupport->current_core(
            signal => $result, holder => $event->{holder}, children => $children);
        next unless $self->_literal_registry_contains($capture->{objects});
        push @current, [$event, $result, $capture->{objects}];
    }
    return $write->() unless @current;
    my $transition = eval {FSM::SourceLiteralWidthAllocationSupport->copy_transition(
        defined($attribute) ? {kind => 'role', attribute => $attribute, value => $value} : $metadata)};
    my $revision = $signal->_intermediate_width_allocation_revision;
    my $returned = $write->();
    return $returned unless $transition && $signal->_intermediate_width_allocation_revision == $revision + 1;
    for my $candidate (@current) {
        my ($event, $result, $objects) = @$candidate;
        next unless $self->_literal_registry_contains($objects);
        my $holder = FSM::SourceLiteralWidthAllocationSupport->advance_core(signal => $result,
            holder => $event->{holder}, changed_signal => $signal, revision => $revision,
            transition => $transition, children => $children);
        next unless $holder && $self->_literal_registry_contains($objects);
        $event->{holder} = $holder;
    }
    return $returned;
}

sub _source_tree_allocation_transition($self, $signal, $attribute, $value, $write) {
    my $events = $self->{_source_bitwise_tree_width_allocation_capture};
    return $write->() unless $events && @$events && $signal;
    my $json = JSON::PP->new->canonical;
    my $identity = sprintf('%x', refaddr($signal));
    my @current;
    for my $event (@$events) {
        my $result = $self->{signal_manager}->get_signal($event->{signal_name});
        next unless $self->_source_tree_allocation_registry_matches($result);
        my $record = FSM::SourceBitwiseTreeWidthSupport->current_core(signal => $result, holder => $event->{holder});
        next unless $record;
        my $state = $json->decode($event->{holder}{state});
        next unless grep {$_->{object_identity} eq $identity} ($state->{signal}, @{$state->{operands}});
        push @current, [$event, $result, $record, $state];
    }
    my $revision = $signal->_intermediate_width_allocation_revision;
    my $returned = $write->();
    return $returned unless @current && $signal->_intermediate_width_allocation_revision == $revision + 1;
    for my $candidate (@current) {
        my ($event, $result, $record, $state) = @$candidate;
        next unless $self->_source_tree_allocation_registry_matches($result);
        my $after = eval {FSM::SourceBitwiseTreeWidthSupport->prepare_core(signal => $result, record => $record)};
        next unless $after;
        my @changed = grep {$_->{object_identity} eq $identity} ($state->{signal}, @{$state->{operands}});
        next if grep {$_->{revision} != $revision} @changed;
        for my $descriptor (@changed) {
            ++$descriptor->{revision};
            $descriptor->{roles}{$attribute} = $value if defined $attribute;
        }
        if ($state->{signal}{object_identity} eq $identity) {
            ++$state->{revision};
            $state->{roles}{$attribute} = $value if defined $attribute;
        }
        # All repeated slots must agree; no other source, role, width or tree
        # delta can hide inside the one sanctioned operation.
        next unless $json->encode($state) eq $after->{state};
        $event->{holder} = $after;
    }
    return $returned;
}

sub _binary_allocation_transition($self, $signal, $attribute, $value, $write) {
    my $events = $self->{_intermediate_width_allocation_capture};
    return $write->() unless $events && $signal;
    my $json = JSON::PP->new->canonical;
    my $identity = sprintf('%x', refaddr($signal));
    my @current;
    for my $event (@$events) {
        my $result = $self->{signal_manager}->get_signal($event->{signal_name});
        next unless $self->_allocation_registry_matches($result);
        my $record = FSM::IntermediateWidthAllocationSupport->current_core(signal => $result, holder => $event->{holder});
        next unless $record;
        my $state = $json->decode($event->{holder}{state});
        next unless grep {$_->{object_identity} eq $identity} ($state->{signal}, @{$state->{operands}});
        push @current, [$event, $result, $record, $state];
    }
    my $revision = $signal->_intermediate_width_allocation_revision;
    my $returned = $write->();
    return $returned unless $signal->_intermediate_width_allocation_revision == $revision + 1;
    for my $candidate (@current) {
        my ($event, $result, $record, $state) = @$candidate;
        next unless $self->_allocation_registry_matches($result);
        my $after = eval {FSM::IntermediateWidthAllocationSupport->prepare_core(signal => $result, record => $record)};
        next unless $after;
        my @changed = grep {$_->{object_identity} eq $identity} ($state->{signal}, @{$state->{operands}});
        next if grep {$_->{revision} != $revision} @changed;
        ++$_->{revision} for @changed;
        if ($state->{signal}{object_identity} eq $identity) {
            ++$state->{revision};
            $state->{roles}{$attribute} = $value if defined $attribute;
        }
        # The known operation may change only its exact revision and declared
        # role attribute. Width/type/constraint/AST/other-source deltas refuse.
        next unless $json->encode($state) eq $after->{state};
        $event->{holder} = $after;
    }
    return $returned;
}

sub _register_unannotated_reference($self, $name) {
    return $self->_allocation_transition($self->{signal_manager}->get_signal($name), 'is_output', '', sub {
        $self->{signal_manager}->register_signal($name, width => undef, is_output => '');
    });
}

sub _set_analyzed_signal_role($self, $signal, $role) {
    return $self->_allocation_transition($signal, 'signal_role', $role, sub {
        $signal->set_attribute('signal_role', $role);
    });
}

sub _set_published_width_metadata($self, $signal, $kind, $record) {
    my $setter = {requirements => 'set_declared_width_requirements', binding => 'set_declared_width_binding'}->{$kind};
    confess "Unknown published width metadata kind\n" unless $setter;
    return $self->_allocation_transition($signal, undef, undef, sub {$signal->$setter($record)},
        {kind => $kind, record => $record});
}

sub _publish_intermediate_width_allocations($self, $events, $source_tree_events = undef, $source_literal_events = undef) {
    for my $event (@$events) {
        my $signal = $self->{signal_manager}->get_signal($event->{signal_name});
        next unless $self->_allocation_registry_matches($signal);
        $signal->_publish_staged_intermediate_width_allocation($event->{holder});
    }
    for my $event (@{$source_tree_events // []}) {
        my $signal = $self->{signal_manager}->get_signal($event->{signal_name});
        next unless $self->_source_tree_allocation_registry_matches($signal);
        $signal->_publish_staged_source_bitwise_tree_width_allocation($event->{holder});
    }
    my $children = $self->_source_literal_birth_children($source_literal_events // []);
    for my $event (@{$source_literal_events // []}) {
        my $signal = $self->{signal_manager}->get_signal($event->{signal_name});
        my $capture = $self->_source_literal_allocation_registry_matches($signal, $children) or next;
        $signal->_publish_staged_source_literal_width_allocation($event->{holder}, sub {
            $self->_literal_registry_contains($capture->{objects});
        }, $children);
    }
}

sub parse_condition($self, $condition) {
    if (!defined $condition) {
        return undef;
    }
    
    fsm_debug("        PARSE_CONDITION: Evaluating condition " . (ref($condition) ? "complex" : "'$condition'"), 3);
    
    # NEW FORMAT: condition is fully parsed as a complex expression
    if (ref($condition)) {
        fsm_debug("          Parsing complex condition expression", 3);
        return $self->parse_expression($condition);
    }
    
    # OLD FORMAT: string condition like '<signal_name', '<!signal_name', '<signal=value'
    if ($condition =~ /^<!(.+)$/) {
        # Negative condition: <!signal or <!signal=value
        my $condition_spec = $1;
        fsm_debug("          Parsing negative condition: !$condition_spec", 3);
        if (!$self->condition_spec_has_explicit_operator($condition_spec)) {
            return $self->parse_legacy_condition_spec(
                $condition_spec,
                bare_signal_operator => '=='
            );
        }

        my $condition_expr = $self->parse_legacy_condition_spec($condition_spec);
        return FSM::CoreAST::UnaryOp->new(
            operator => '!',
            operand => $condition_expr
        );
    } elsif ($condition =~ /^<(.+)$/) {
        # Positive condition: <signal or <signal=value
        my $condition_spec = $1;
        fsm_debug("          Parsing positive condition: $condition_spec", 3);
        return $self->parse_legacy_condition_spec(
            $condition_spec,
            bare_signal_operator => '!='
        );
    } else {
        # informational note: a bare condition string (e.g. 'signal_name') is the routine
        # "if signal" form — treated as a positive signal reference.
        fsm_debug("bare condition string '$condition' treated as a positive signal reference", 3);
        return $self->parse_signal_reference($condition);
    }
}

sub condition_spec_has_explicit_operator($self, $condition_spec) {
    return 0 unless defined $condition_spec;
    return $condition_spec =~ /^.+?(?:==|!=|<=|>=|=|<|>).+$/ ? 1 : 0;
}

sub malformed_guard_condition_error($self, $condition_spec) {
    Carp::confess
        "Malformed guard condition payload '$condition_spec'. ".
        "Guard shorthand must use a valid signal/expression comparison such as '<foo', '<!foo', '<foo=3', or '<foo<=3'. ".
        supported_boundary_hint();
}

sub malformed_inline_comparison_error($self, $scalar) {
    Carp::confess
        "Malformed inline comparison expression '$scalar'. ".
        "Inline comparison tokens must use valid operands on both sides of the comparison operator. ".
        supported_boundary_hint();
}

sub ambiguous_bare_integer_literal_error($self, $scalar) {
    my ($binary_example, $decimal_example, $exact_width_example) =
        FSM::Package::IntegerLiteralSupport->explicit_examples_for_obviously_binary_like_bare_value_literal($scalar);

    Carp::confess
        "Ambiguous bare integer literal '$scalar'. ".
        "FSMGen does not guess obviously bitstring-like bare 0/1 tokens in value or expression position. ".
        "Use '$binary_example' for intrinsic-width binary, '$exact_width_example' for exact-width binary, or '$decimal_example' if decimal was intended. ".
        supported_boundary_hint();
}

sub parse_legacy_condition_spec($self, $condition_spec, %options) {
    # Parse legacy condition payload found after < or <! prefixes.
    # Supports:
    #   signal          -> BinaryOp('!=', SignalRef(signal), 0) when a bare-signal
    #                      operator is provided by the caller
    #   signal=value    -> BinaryOp('==', SignalRef(signal), parse_expression(value))
    #   signal==value   -> BinaryOp('==', SignalRef(signal), parse_expression(value))
    #   signal!=value   -> BinaryOp('!=', SignalRef(signal), parse_expression(value))
    #   signal<value    -> BinaryOp('<',  SignalRef(signal), parse_expression(value))
    $condition_spec =~ s/^\s+|\s+$//g;

    if ($condition_spec =~ /^(.+?)(==|!=|<=|>=|=|<|>)(.+)$/) {
        my ($lhs_spec, $operator, $rhs_expr) = ($1, $2, $3);
        $lhs_spec =~ s/^\s+|\s+$//g;
        $rhs_expr =~ s/^\s+|\s+$//g;
        $operator = '==' if $operator eq '=';

        my $lhs = eval { $self->parse_signal_reference($lhs_spec) };
        my $lhs_error = $@;
        my $rhs = eval { $self->parse_expression($rhs_expr) };
        my $rhs_error = $@;

        $self->malformed_guard_condition_error($condition_spec)
            if $lhs_error || $rhs_error || !$lhs || !$rhs;

        $self->align_comparison_operand_widths($lhs, $rhs);

        fsm_debug("          Legacy condition parsed as comparison: $lhs_spec $operator $rhs_expr", 3);
        return FSM::CoreAST::BinaryOp->new($operator, $lhs, $rhs);
    }

    if (defined $options{bare_signal_operator}) {
        my $lhs = eval { $self->parse_signal_reference($condition_spec) };
        my $lhs_error = $@;
        my $rhs = FSM::CoreAST::Literal->new('0');

        $self->malformed_guard_condition_error($condition_spec)
            if $lhs_error || !$lhs;

        fsm_debug(
            "          Legacy condition parsed as bare-signal truthiness: $condition_spec $options{bare_signal_operator} 0",
            3
        );
        return FSM::CoreAST::BinaryOp->new($options{bare_signal_operator}, $lhs, $rhs);
    }

    # Fallback bare condition for non-prefixed internal callers.
    return $self->parse_signal_reference($condition_spec);
}

sub is_recursive_expression($self, $expr) {
    return 0 unless ref($expr) eq 'ARRAY' && @$expr >= 1 && !ref($expr->[0]);
    return 1 if $expr->[0] eq 'state_active';

    my ($normalized_op) = $self->normalize_expression_operator($expr->[0]);
    return defined($normalized_op) ? 1 : 0;
}

sub normalize_expression_operator($self, $operator) {
    return undef unless defined $operator;

    my %operator_aliases = (
        and => '&',
        nand => '!&',
        or  => '|',
        nor => '!|',
        xor => '^',
        xnor => '!^',
        add => '+',
        sub => '-',
        mul => '*',
        div => '/',
        mod => '%',
        eq  => '==',
        ne  => '!=',
        lt  => '<',
        le  => '<=',
        gt  => '>',
        ge  => '>=',
        not => '!',
        cat => 'concat',
        shl => '<<',
        shr => '>>',
        sal => '<<<',
        sar => '>>>',
    );

    my $normalized = $operator_aliases{$operator} // $operator;
    my %supported = map { $_ => 1 } qw(! !& !| !^ == != < <= > >= & | ^ + - * / % << >> <<< >>> concat);
    return $supported{$normalized} ? $normalized : undef;
}

sub operator_family_for($self, $normalized_operator) {
    return 'unary' if defined $normalized_operator && $normalized_operator eq '!';
    return 'negated_nary'
        if defined $normalized_operator && $normalized_operator =~ /^(?:!&|!\||!\^)$/;
    return 'comparison'
        if defined $normalized_operator && $normalized_operator =~ /^(?:==|!=|<|<=|>|>=)$/;
    return 'concat' if defined $normalized_operator && $normalized_operator eq 'concat';
    return 'binary'
        if defined $normalized_operator && $normalized_operator =~ /^(?:<<|>>|<<<|>>>)$/;
    return 'nary'
        if defined $normalized_operator && $normalized_operator =~ /^(?:&|\||\^|\+|-|\*|\/|%)$/;
    return undef;
}

sub base_operator_for_negated_nary($self, $normalized_operator) {
    my %base_operator = (
        '!&' => '&',
        '!|' => '|',
        '!^' => '^',
    );
    return $base_operator{$normalized_operator};
}

sub finalize_nary_expression($self, $operator, $parsed_operands) {
    my %logical_ops = map { $_ => 1 } qw(& | ^);
    my $ast_tree = $self->create_binary_operator_tree($operator, $parsed_operands);

    if (@$parsed_operands > 1 && $logical_ops{$operator}) {
        fsm_debug("          FACTORIZATION: Extracting complex $operator expression to intermediate signal", 3);

        my $intermediate_name = $self->generate_intermediate_signal($operator, $parsed_operands);
        my $fresh_allocation = !$self->{signal_manager}->has_symbol_name($intermediate_name);
        my $width = $self->infer_exact_expression_width($ast_tree);
        my %attributes = (type => 'wire', is_intermediate => 1);
        $attributes{width} = $width if defined($width) && $width > 0;
        my $signal = $self->{signal_manager}->register_signal(
            $intermediate_name,
            %attributes,
        );

        $signal->set_driving_ast($ast_tree);
        $self->_stage_intermediate_width_allocation($signal, $operator, $parsed_operands, $width);
        $self->_stage_source_tree_width_allocation($signal, $operator, $parsed_operands, $width);
        if ($fresh_allocation) {
            $self->_stage_source_literal_width_allocation($signal);
        }
        fsm_debug("            Attached driving AST to intermediate signal $intermediate_name", 3);

        return FSM::CoreAST::SignalRef->new($signal);
    }

    return $ast_tree;
}

sub literal_zero_divisor_text($self, $expr) {
    return undef
        unless blessed($expr) && $expr->isa('FSM::CoreAST::Literal');

    my $integer = FSM::Package::IntegerLiteralSupport->integer_from_literal_like($expr);
    return undef unless defined($integer) && $integer->bcmp(0) == 0;

    return $expr->to_systemverilog;
}

sub reject_literal_zero_divisor_operands($self, $display_operator, $normalized_operator, $parsed_operands) {
    return 1 unless defined($normalized_operator) && ($normalized_operator eq '/' || $normalized_operator eq '%');
    return 1 unless ref($parsed_operands) eq 'ARRAY' && @$parsed_operands >= 2;

    my $operation = $normalized_operator eq '/' ? 'division' : 'modulo';

    for my $index (1 .. $#$parsed_operands) {
        my $literal_text = $self->literal_zero_divisor_text($parsed_operands->[$index]);
        next unless defined $literal_text;

        Carp::confess
            "Malformed expression operator '$display_operator' uses literal zero divisor '$literal_text' in $operation. ".
            "Direct runtime division/modulo expressions reject numeric and exact-width literal-zero divisors before HDL emission; nonzero literal and dynamic signal divisors remain accepted. ".
            supported_boundary_hint();
    }

    return 1;
}

sub build_chained_relational_expression($self, $operator, $parsed_operands) {
    my @comparisons;
    for my $i (0 .. ($#$parsed_operands - 1)) {
        $self->align_comparison_operand_widths($parsed_operands->[$i], $parsed_operands->[$i + 1]);
        push @comparisons, FSM::CoreAST::BinaryOp->new(
            $operator,
            $parsed_operands->[$i],
            $parsed_operands->[$i + 1],
        );
    }

    return $comparisons[0] if @comparisons == 1;
    return $self->finalize_nary_expression('&', \@comparisons);
}

sub parse_recursive_expression($self, $expr, %options) {
    my ($operator, @operands) = @$expr;
    
    # Lispish often packs n-ary operands in a single array:
    #   ['&', ['a', 'b', 'c']]
    # Normalize to a flat list.
    if (@operands == 1 && ref($operands[0]) eq 'ARRAY') {
        @operands = @{$operands[0]};
    }

    return $self->parse_state_active_expression($operator, \@operands)
        if defined($operator) && !ref($operator) && $operator eq 'state_active';
    
    my $normalized_operator = $self->normalize_expression_operator($operator);
    my $operator_family = $self->operator_family_for($normalized_operator);

    Carp::confess
        "Unsupported expression operator '$operator'. ".
        "Active expression operators currently include '!', '!&', '!|', '!^', '==', '!=', '<', '<=', '>', '>=', '+', '-', '*', '/', '%', '<<', '>>', '<<<', '>>>', '&', '|', '^', 'concat', bounded 'state_active', and their documented aliases. ".
        supported_boundary_hint()
        unless $operator_family;

    fsm_debug("          Recursive expr: $operator with " . scalar(@operands) . " operands", 3);

    return $self->parse_unary_reduction($operator, $normalized_operator, $operands[0], %options)
        if @operands == 1 && is_reduction_operator($normalized_operator);

    my @parsed_operands;
    for my $operand (@operands) {
        my $parsed = $self->parse_expression($operand, %options);
        push @parsed_operands, $parsed if $parsed;
    }

    if ($operator_family eq 'unary') {
        Carp::confess
            "Malformed expression operator '$operator' with " . scalar(@parsed_operands) . " operand(s). ".
            "This active form requires exactly 1 operand. ".
            supported_boundary_hint()
            unless @parsed_operands == 1;

        return FSM::CoreAST::UnaryOp->new(
            operator => $normalized_operator,
            operand  => $parsed_operands[0],
        );
    }

    Carp::confess
        "Malformed expression operator '$operator' with " . scalar(@parsed_operands) . " operand(s). ".
        "This active form requires at least 2 operands. ".
        supported_boundary_hint()
        unless @parsed_operands >= 2;

    return $self->build_chained_relational_expression($normalized_operator, \@parsed_operands)
        if $operator_family eq 'comparison';

    $self->reject_literal_zero_divisor_operands($operator, $normalized_operator, \@parsed_operands);

    if ($operator_family eq 'concat') {
        my $concat = FSM::CoreAST::Concatenation->new(@parsed_operands);
        my $concat_width = $self->infer_exact_expression_width($concat);

        Carp::confess
            "Malformed concat expression with " . scalar(@parsed_operands) . " operand(s). ".
            "Direct RHS concat operands must have exact widths from declared signal widths, bit/slice or aggregate leaf access, or explicitly sized literal constants before generation. ".
            supported_boundary_hint()
            unless defined($concat_width) && $concat_width > 0;

        return $concat;
    }

    if ($operator_family eq 'binary') {
        Carp::confess
            "Malformed expression operator '$operator' with " . scalar(@parsed_operands) . " operand(s). ".
            "This active form requires exactly 2 operands. ".
            supported_boundary_hint()
            unless @parsed_operands == 2;

        return FSM::CoreAST::BinaryOp->new(
            $normalized_operator,
            $parsed_operands[0],
            $parsed_operands[1],
        );
    }

    if ($operator_family eq 'negated_nary') {
        my $base_operator = $self->base_operator_for_negated_nary($normalized_operator);
        my $base_expr = $self->finalize_nary_expression($base_operator, \@parsed_operands);

        return FSM::CoreAST::UnaryOp->new(
            operator => '!',
            operand  => $base_expr,
        );
    }

    return $self->finalize_nary_expression($normalized_operator, \@parsed_operands);
}

sub parse_unary_reduction($self, $display_operator, $operator, $operand, %options) {
    my $display = defined($operand) && !ref($operand) ? $operand : '<expression>';
    my $invalid = sub {
        Carp::confess "Reduction '$display_operator' operand '$display' requires a declared positive-width packed scalar signal, static slice or bit selection. "
            . supported_boundary_hint();
    };
    $invalid->() unless defined($operand) && !ref($operand)
        && $operand =~ /\A([A-Za-z_]\w*)(?:(?:\.[A-Za-z_]\w*)|(?:\[\d+(?::\d+)?\]))*\z/;
    my $signal = $self->{signal_manager}->get_signal($1);
    $invalid->() unless $signal && ($signal->get_attribute('width_declared')
        || $signal->get_attribute('explicit_port_role')
        || $signal->type eq 'clock' || $signal->type eq 'reset');
    my $parsed = $self->parse_expression($operand, %options);
    $invalid->() unless blessed($parsed) && ($parsed->isa('FSM::CoreAST::SignalRef')
        || $parsed->isa('FSM::CoreAST::IndexedRef') || $parsed->isa('FSM::CoreAST::AggregateRef'));
    if ($parsed->isa('FSM::CoreAST::AggregateRef')) {
        my $spec = $parsed->type_spec;
        $invalid->() unless ref($spec) eq 'HASH' && ($spec->{kind} eq 'bit' || $spec->{kind} eq 'bits');
    }
    my $width = $self->infer_exact_expression_width($parsed);
    $invalid->() unless defined($width) && $width > 0;
    return FSM::CoreAST::UnaryOp->new(operator => $operator, operand => $parsed);
}

sub parse_state_active_expression($self, $operator, $operands) {
    Carp::confess
        "Malformed expression operator '$operator' with " . scalar(@$operands) . " operand(s). ".
        "The bounded state-active guard form requires exactly one FSM state name: '(state_active state_name)'. ".
        supported_boundary_hint()
        unless @$operands == 1 && defined($operands->[0]) && !ref($operands->[0]);

    my $state_name = $operands->[0];
    Carp::confess
        "Malformed state-active guard state name '$state_name'. ".
        "State-active guards require an HDL-identifier-compatible FSM state name. ".
        supported_boundary_hint()
        unless $state_name =~ /\A[A-Za-z_]\w*\z/;

    push @{$self->{state_active_references}}, $state_name;

    my $current_state_signal = $self->{signal_manager}->register_signal(
        'current_state',
        type => 'wire',
        is_intermediate => 1,
    );

    return FSM::CoreAST::BinaryOp->new(
        '==',
        FSM::CoreAST::SignalRef->new($current_state_signal),
        FSM::CoreAST::Literal->new(uc($state_name)),
    );
}

sub generate_intermediate_signal($self, $operator, $operands) {
    # Extract names from operands if they are signal references
    my @names;
    for my $op (@$operands) {
        if ($op->isa('FSM::CoreAST::SignalRef') && $op->signal) {
            push @names, $op->signal->name;
        } elsif ($op->isa('FSM::CoreAST::UnaryOp') && $op->operator eq '!' && 
                 $op->operand->isa('FSM::CoreAST::SignalRef')) {
            push @names, "not_" . $op->operand->signal->name;
        }
    }
    
    my $op_name = $operator;
    # Normalize common operators for better naming
    $op_name = 'and' if $operator eq '&';
    $op_name = 'or'  if $operator eq '|';
    $op_name = 'xor' if $operator eq '^';
    $op_name = 'add' if $operator eq '+';
    
    # Create a descriptive name of format: op_name_operand1_operand2...
    my $base_name = join("_", $op_name, @names);
    
    # Truncate if too long
    if (length($base_name) > 40) {
        $base_name = substr($base_name, 0, 40) . "_etc";
    }
    
    # If we couldn't extract names, fall back to simple counter
    if (@names == 0) {
        $base_name = "complex_expr";
    }
    
    # register_signal deliberately refines an existing object. A generated
    # helper must instead own a fresh name before it reaches registration.
    my $name;
    do {
        $name = "intermediate_${base_name}_" . ++$self->{intermediate_counter};
    } while ($self->{signal_manager}->has_symbol_name($name));
    return $name;
}

sub create_binary_operator_tree($self, $operator, $operands) {
    return undef unless @$operands;
    
    if (@$operands == 1) {
        return $operands->[0];
    }
    
    my %op_map = (
        'and' => '&', 'or' => '|', 'xor' => '^',
        'add' => '+', 'sub' => '-', 'mul' => '*', 'div' => '/', 'mod' => '%'
    );
    my $normalized_op = $op_map{$operator} || $operator;
    
    my $result = $operands->[0];
    for my $i (1 .. $#{$operands}) {
        $result = FSM::CoreAST::BinaryOp->new(
            $normalized_op, $result, $operands->[$i]
        );
    }
    
    return $result;
}

sub parse_expression($self, $expr, %options) {
    if (!ref($expr)) {
        return $self->parse_scalar_expression($expr, %options);
    } elsif (ref($expr) eq 'ARRAY') {
        Carp::confess
            "Malformed expression list '()'. ".
            "Expressions must use a literal, signal reference, or supported operator form. ".
            supported_boundary_hint()
            unless @$expr;

        if ($options{property_value_context}
            && defined($expr->[0]) && !ref($expr->[0]) && $expr->[0] eq 'past') {
            return $self->parse_property_past_expression($expr, %options);
        }

        if ($self->is_recursive_expression($expr)) {
            fsm_debug("          Detected recursive expression - processing with new framework", 3);
            return $self->parse_recursive_expression($expr, %options);
        } else {
            return $self->parse_sexpr_expression($expr);
        }
    } else {
        Carp::confess
            "Unsupported expression payload type '" . ref($expr) . "'. ".
            "Expressions must use a literal, signal reference, or supported operator form. ".
            supported_boundary_hint();
    }
}

sub parse_scalar_expression($self, $scalar, %options) {
    fsm_debug("        PARSE_SCALAR: Processing scalar '$scalar'", 3);

    if ($scalar =~ /^\[[^\]]+\](?:.*)?$/) {
        Carp::confess
            "Unsupported generic/template placeholder token '$scalar'. ".
            "The active contract does not support legacy placeholder-expansion forms like '[NAME]' or '[?size: ...]'. ".
            "Expand the template before parsing or keep it in legacy-only sources. ".
            supported_boundary_hint();
    }

    my $resolved_symbol = $self->{signal_manager}->resolve_symbol($scalar);
    if ($resolved_symbol) {
        fsm_debug("          SYMBOL RESOLVED: '$scalar' -> semantic symbol", 3);
        return $resolved_symbol;
    }

    my $aggregate_payload = $self->{signal_manager}->resolve_aggregate_symbol_payload($scalar);
    if (defined $aggregate_payload) {
        my ($bits, $width, $reason) = FSM::Package::PayloadLiteralSupport->payload_to_bits_and_width($aggregate_payload);
        if (defined $bits) {
            fsm_debug("          AGGREGATE ROOT RESOLVED: '$scalar' -> ${width}'b$bits", 3);
            return FSM::CoreAST::Literal->new($bits, width => $width, radix => 'binary');
        }
        Carp::confess
            "Unsupported aggregate-valued symbol '$scalar'. ".
            "The active scalar-expression lane currently requires whole aggregate roots to lower to one packed literal with scalar literal leaves. ".
            "This aggregate could not be lowered because '$reason' is outside that bounded contract. ".
            supported_boundary_hint();
    }

    my $aggregate_prefix = $self->{signal_manager}->aggregate_symbol_prefix_for($scalar);
    if (defined $aggregate_prefix) {
        Carp::confess
            "Unsupported aggregate-valued symbol '$scalar'. ".
            "The active scalar-expression lane currently requires member/index access all the way to a scalar leaf, for example '$aggregate_prefix.member' or '$aggregate_prefix\[0\]'. ".
            supported_boundary_hint();
    }

    my $typed_aggregate_ref = $self->parse_typed_aggregate_signal_reference($scalar);
    return $typed_aggregate_ref if $typed_aggregate_ref;

    $self->ambiguous_bare_integer_literal_error($scalar)
        if FSM::Package::IntegerLiteralSupport->obviously_binary_like_bare_value_literal($scalar);
    
    my $integer_literal = $self->parse_common_integer_literal($scalar);
    return $integer_literal if $integer_literal;

    if ($scalar =~ /^(\d+)'([0-9a-fA-F_]+)$/) {
        my ($width, $value) = ($1, $2);
        $value =~ s/_//g;
        return FSM::CoreAST::Literal->new($value, width => $width, radix => 'decimal');
    } elsif ($scalar =~ /^const_(\d+)b([01xXzZ_]+)$/) {
        # Common FSMGen constant encoding, e.g. const_8b0 / const_16b0000_1111
        my ($width, $value) = ($1, $2);
        $value =~ s/_//g;
        fsm_debug("          CONST LITERAL: '$scalar' -> ${width}'b$value", 3);
        return FSM::CoreAST::Literal->new($value, width => $width, radix => 'binary');
    } elsif ($scalar =~ /^(.+?)(==|!=|<=|>=|=|<|>)(.+)$/) {
        my ($lhs_spec, $operator, $rhs_spec) = ($1, $2, $3);
        $lhs_spec =~ s/^\s+|\s+$//g;
        $rhs_spec =~ s/^\s+|\s+$//g;
        $operator = '==' if $operator eq '=';

        my $lhs = $self->parse_expression($lhs_spec, %options);
        my $rhs = $self->parse_expression($rhs_spec, %options);

        $self->malformed_inline_comparison_error($scalar)
            unless $lhs && $rhs;

        $self->align_comparison_operand_widths($lhs, $rhs);

        return FSM::CoreAST::BinaryOp->new($operator, $lhs, $rhs);
    } elsif ($scalar =~ /^!([a-zA-Z_]\w*(?:\[[\d:]+\])?)$/) {
        # Legacy compact negation token, e.g. !wren
        my $operand = $self->parse_signal_reference($1);
        return FSM::CoreAST::UnaryOp->new(
            operator => '!',
            operand => $operand
        );
    } elsif ($scalar =~ /^([a-zA-Z_]\w*(?:\.[a-zA-Z_]\w*){2,})$/) {
        Carp::confess
            "Unsupported expression token '$scalar'. ".
            "Active dotted package-qualified symbols must resolve to imported named scalar or enum values before expression parsing. ".
            supported_boundary_hint();
    } elsif ($scalar =~ /^([a-zA-Z_]\w*)(\.[a-zA-Z_]\w*)?(\[[\d:]+\])?('(\d+))?(\>)?$/) {
        my ($base_name, $member_name, $slice, $width_annotation, $width, $output_marker) = ($1, $2, $3, $4, $5, $6);
        my $full_name = $member_name ? "$base_name$member_name" : $base_name;
        
        my $signal_name = $base_name;
        my $signal = !$member_name && !$slice && !$width_annotation
            ? $self->_allocation_transition($self->{signal_manager}->get_signal($signal_name),
                'is_output', defined($output_marker), sub {
                    $self->{signal_manager}->register_signal($signal_name,
                        width => undef, is_output => defined($output_marker));
                })
            : $self->{signal_manager}->register_signal($signal_name,
                width => $width, is_output => defined($output_marker));
        
        if ($slice) {
            if ($slice =~ /\[(\d+):(\d+)\]/) {
                my ($high, $low) = ($1, $2);
                $self->refine_signal_width_from_static_access($signal, (($high > $low) ? $high : $low) + 1);
                return FSM::CoreAST::SignalRef->new($signal, slice => [$high, $low]);
            } elsif ($slice =~ /\[(\d+)\]/) {
                my $index = $1;
                $self->refine_signal_width_from_static_access($signal, $index + 1);
                return FSM::CoreAST::IndexedRef->new($signal, FSM::CoreAST::Literal->new($index));
            }
        }
        
        return FSM::CoreAST::SignalRef->new($signal);
    } elsif (
        $scalar =~ /^.+?(?:==|!=|<=|>=|=|<|>)$/ ||
        $scalar =~ /^(?:==|!=|<=|>=|=|>).+$/ ||
        $scalar =~ /^<(?![A-Za-z_!]).+$/
    ) {
        $self->malformed_inline_comparison_error($scalar);
    } else {
        Carp::confess
            "Unsupported expression token '$scalar'. ".
            "Active expressions must use a literal, a valid signal reference, or a supported operator form. ".
            "Guard-prefixed tokens belong in condition position, not inside ordinary expressions. ".
            supported_boundary_hint();
    }
}

sub parse_property_past_expression($self, $expr, %options) {
    my (undef, @operands) = @$expr;

    if (@operands == 1 && ref($operands[0]) eq 'ARRAY') {
        @operands = @{$operands[0]};
    }

    Carp::confess
        "'(past SIG [N])' sampled-value expression requires one signal operand and an optional literal depth"
        unless (@operands == 1 || @operands == 2) && defined($operands[0]);

    my $sampled = $self->parse_expression($operands[0], %options);
    Carp::confess
        "'(past SIG [N])' sampled-value expression requires a signal, bit/slice, or aggregate leaf operand"
        unless $sampled
            && (
                $sampled->isa('FSM::CoreAST::SignalRef')
                || $sampled->isa('FSM::CoreAST::IndexedRef')
                || $sampled->isa('FSM::CoreAST::AggregateRef')
            );

    my @arguments = ($sampled);
    if (@operands == 2) {
        my $depth = $operands[1];
        Carp::confess
            "'(past SIG N)' sampled-value depth must be a literal integer >= 1"
            unless defined($depth) && !ref($depth) && $depth =~ /^\d+$/ && $depth + 0 >= 1;
        push @arguments, FSM::CoreAST::Literal->new($depth + 0);
    }

    return FSM::CoreAST::FunctionCall->new('$past', @arguments);
}

sub parse_common_integer_literal($self, $scalar) {
    return undef unless defined($scalar) && !ref($scalar);

    my $parts = FSM::Package::IntegerLiteralSupport->literal_parts_from_scalar($scalar);
    return undef unless $parts;

    my $width = $parts->{width};
    if (!defined $width && $parts->{value}->bcmp(0) >= 0) {
        $width = $self->intrinsic_width_for_integer_literal_token($scalar, $parts);
    }
    $parts->{width} = $width if defined $width;

    my $literal_payload = FSM::Package::IntegerLiteralSupport->core_literal_payload_from_parts(%$parts);
    return undef unless $literal_payload;

    my %args = (
        radix => $literal_payload->{radix} // 'decimal',
    );
    $args{width} = $literal_payload->{width} if defined $literal_payload->{width};

    return FSM::CoreAST::Literal->new($literal_payload->{value}, %args);

    return undef;
}

sub refine_signal_width_from_static_access($self, $signal, $required_width) {
    return unless $signal && $signal->can('name');
    return unless defined($required_width) && $required_width > 0;

    $self->{signal_manager}->register_signal(
        $signal->name,
        width => $required_width,
    );
}

sub align_comparison_operand_widths($self, $left, $right) {
    my ($left_width, $left_explicit) = $self->infer_expression_width_contract($left);
    my ($right_width, $right_explicit) = $self->infer_expression_width_contract($right);

    if ($left_explicit && !$right_explicit && defined($left_width) && $left_width > 0) {
        $self->propagate_width_to_expression($right, $left_width);
        return;
    }

    if ($right_explicit && !$left_explicit && defined($right_width) && $right_width > 0) {
        $self->propagate_width_to_expression($left, $right_width);
        return;
    }
}

sub infer_expression_width_contract($self, $expr) {
    return (undef, 0) unless $expr && blessed($expr);

    if ($expr->isa('FSM::CoreAST::Literal')) {
        my $width = $expr->width;
        return (defined($width) && $width > 0) ? ($width, 1) : (undef, 0);
    }

    if ($expr->isa('FSM::CoreAST::ParameterRef')) {
        my $width = $expr->width;
        return (defined($width) && $width > 0) ? ($width, 1) : (undef, 0);
    }

    if ($expr->isa('FSM::CoreAST::SignalRef')) {
        if ($expr->slice) {
            my ($high, $low) = @{$expr->slice};
            return (abs($high - $low) + 1, 1);
        }

        my $signal = $expr->signal;
        return (undef, 0) unless $signal && $signal->can('width');
        my $width = $signal->width;
        my $explicit = defined($width)
            && $width > 0
            && (
                $width > 1
                || ($signal->can('get_attribute') && $signal->get_attribute('width_declared'))
            );
        return ($width, $explicit ? 1 : 0);
    }

    if ($expr->isa('FSM::CoreAST::IndexedRef')) {
        return (1, 1);
    }

    if ($expr->isa('FSM::CoreAST::AggregateRef')) {
        my $width = $expr->width;
        return (defined($width) && $width > 0) ? ($width, 1) : (undef, 0);
    }

    if ($expr->isa('FSM::CoreAST::Concatenation')) {
        my $width = $self->infer_exact_expression_width($expr);
        return (defined($width) && $width > 0) ? ($width, 1) : (undef, 0);
    }

    return (undef, 0);
}

sub intrinsic_width_for_integer_literal_token($self, $scalar, $parts) {
    my $text = $scalar;
    $text =~ s/_//g;
    $text =~ s/\A[+]//;

    return length($1) if $text =~ /\A0b([01]+)\z/i;
    return length($1) * 3 if $text =~ /\A0o([0-7]+)\z/i;
    return length($1) * 4 if $text =~ /\A0x([0-9a-fA-F]+)\z/i;

    if ($text =~ /\A'(?:s?)([bBoOhHxX])([0-9a-fA-F]+)\z/) {
        return $self->intrinsic_based_literal_width($1, $2);
    }

    return undef;
}

sub literal_radix_name($self, $radix_char) {
    my %radix_map = (
        b => 'binary',
        d => 'decimal',
        o => 'octal',
        h => 'hex',
        x => 'hex',
    );

    return $radix_map{lc($radix_char // 'd')} // 'decimal';
}

sub intrinsic_based_literal_width($self, $radix_char, $digits) {
    my $digit_count = length($digits // '');
    return $digit_count if lc($radix_char // '') eq 'b';
    return $digit_count * 3 if lc($radix_char // '') eq 'o';
    return $digit_count * 4 if lc($radix_char // '') eq 'h' || lc($radix_char // '') eq 'x';
    return undef;
}

sub parse_typed_aggregate_signal_reference($self, $scalar) {
    return undef unless defined($scalar) && $scalar =~ /\A([a-zA-Z_]\w*)((?:\.[a-zA-Z_]\w*|\[\d+(?::\d+)?\])+)(?:'(\d+))?(\>)?\z/;

    my ($base_name, $path_text, $width_annotation, $output_marker) = ($1, $2, $3, $4);
    my $signal = $self->{signal_manager}->get_signal($base_name);
    return undef unless $signal;

    my $type_spec = eval { $signal->declared_type_spec };
    if (ref($type_spec) ne 'HASH') {
        Carp::confess
            "Malformed typed aggregate signal access '$scalar'. ".
            "Signal '$base_name' has no declared aggregate type, so member access is not available. ".
            "Declare an aggregate `+types` alias and use it from `+size` before accessing fields.\n"
            if $path_text =~ /^\./;
        return undef;
    }

    my $root_kind = $type_spec->{kind} || '';
    if ($root_kind ne 'list' && $root_kind ne 'record') {
        Carp::confess
            "Malformed typed aggregate signal access '$scalar'. ".
            "Signal '$base_name' has scalar type '".
            FSM::Package::PayloadTypeSupport->type_spec_label($type_spec).
            "', so record member access is not available.\n"
            if $path_text =~ /^\./;
        return undef;
    }

    my ($path, $resolved_type_spec, $resolved_width) = $self->resolve_typed_aggregate_signal_path(
        $base_name,
        $path_text,
        $type_spec,
        $scalar,
    );

    if (defined($width_annotation) && $width_annotation != $resolved_width) {
        my $type_label = FSM::Package::PayloadTypeSupport->type_spec_label($resolved_type_spec);
        Carp::confess
            "Malformed typed aggregate signal access '$scalar'. ".
            "Width annotation '$width_annotation' does not match resolved path width '$resolved_width' ($type_label). ".
            "Remove the annotation or declare a matching aggregate member type before generation.\n";
    }

    if (defined($output_marker)) {
        $signal = $self->{signal_manager}->register_signal(
            $base_name,
            is_output => 1,
        );
    }

    return FSM::CoreAST::AggregateRef->new(
        $signal,
        $path,
        type_spec => $resolved_type_spec,
        width => $resolved_width,
    );
}

sub resolve_typed_aggregate_signal_path($self, $base_name, $path_text, $root_type_spec, $raw_scalar) {
    my $result = FSM::Package::AggregatePathSupport->resolve(
        root_type_spec => $root_type_spec,
        path_text => $path_text,
    );

    $self->confess_typed_aggregate_signal_path_error($result, $base_name, $raw_scalar)
        unless $result->{ok};

    return (
        FSM::Package::AggregatePathSupport->clone_structured_value($result->{path_segments}),
        FSM::Package::AggregatePathSupport->clone_structured_value($result->{type_spec}),
        $result->{width},
    );
}

sub confess_typed_aggregate_signal_path_error($self, $error, $base_name, $raw_scalar) {
    my $code = $error->{code} || 'unknown';

    if ($code eq 'missing_declared_type') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Signal '$base_name' has no declared aggregate type, so member access is not available. ".
            "Declare an aggregate `+types` alias and use it from `+size` before accessing fields.\n";
    }

    if ($code eq 'scalar_root') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Signal '$base_name' has scalar type '".($error->{current_type_label} || 'unknown').
            "', so record member access is not available.\n";
    }

    if ($code eq 'empty_path') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Could not parse an empty aggregate path. ".
            "Use record member access like '.field' and list/scalar constant indexes like '[0]'.\n";
    }

    if ($code eq 'member_on_non_record') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Member access '.".$error->{member_name}."' is only valid on record-typed values; current path type is '".
            ($error->{current_type_label} || 'unknown')."'. ".
            "Use '[N]' for list items or declare a record member before generation.\n";
    }

    if ($code eq 'unknown_member') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Record type for '$base_name' has no member '".$error->{member_name}."'. ".
            "Known members: " . join(', ', @{ $error->{known_members} || [] }) . ".\n";
    }

    if ($code eq 'list_range_not_supported') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "List item access currently accepts one constant index, not a range. ".
            "Select one list element with '[N]' before generation.\n";
    }

    if ($code eq 'list_index_out_of_range') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "List index '".$error->{index}."' is outside the declared item range 0..".
            ($error->{max_index} // -1).".\n";
    }

    if ($code eq 'scalar_slice_out_of_range') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Scalar slice [".$error->{high}.":".$error->{low}."] exceeds resolved scalar width '".$error->{scalar_width}."'.\n";
    }

    if ($code eq 'scalar_index_out_of_range') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Scalar index '".$error->{index}."' exceeds resolved scalar width '".$error->{scalar_width}."'.\n";
    }

    if ($code eq 'index_on_non_indexable') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Index access is valid on list and scalar bit-vector values; current path type is '".
            ($error->{current_type_label} || 'unknown')."'.\n";
    }

    if ($code eq 'parse_error') {
        Carp::confess
            "Malformed typed aggregate signal access '$raw_scalar'. ".
            "Could not parse remaining path '".($error->{remaining} || '')."'. ".
            "Use record member access like '.field' and list/scalar constant indexes like '[0]'.\n";
    }

    if ($code eq 'missing_leaf_width') {
        Carp::confess
            "Unsupported typed aggregate signal access '$raw_scalar'. ".
            "The resolved aggregate leaf has no positive packed width. ".
            supported_boundary_hint();
    }

    Carp::confess
        "Malformed typed aggregate signal access '$raw_scalar'. ".
        "Aggregate path resolution failed unexpectedly. ".
        supported_boundary_hint();
}

sub parse_sexpr_expression($self, $sexpr) {
    my ($operator, @operands) = @$sexpr;

    if (@operands == 1 && ref($operands[0]) eq 'ARRAY') {
        @operands = @{$operands[0]};
    }

    fsm_debug("          S-expression: $operator with " . scalar(@operands) . " operands", 3);
    
    Carp::confess
        "Unsupported expression operator '$operator'. ".
        "Active expression operators currently include '!', '==', '!=', '<', '<=', '>', '>=', '+', '-', '*', '/', '%', '<<', '>>', '<<<', '>>>', '&', '|', '^', 'concat', bounded 'state_active', and their documented aliases. ".
        supported_boundary_hint();
}

sub infer_exact_expression_width($self, $expr) {
    return FSM::CoreExpressionWidthSupport->infer_width($expr)
        unless exists $self->{_source_literal_width_allocation_capture};
    my $children = $self->_source_literal_birth_children;
    return FSM::CoreExpressionWidthSupport->infer_width($expr, source_reference_width => sub {
        my ($reference) = @_;
        my $signal = $reference->signal;
        return undef unless $signal->{attributes}{is_intermediate};
        my $holder = $children->{lookup}->($reference);
        if ($holder) {
            my $capture = $self->_source_literal_allocation_registry_matches($signal, $children);
            my $record = $capture && FSM::SourceLiteralWidthAllocationSupport->current_core(
                signal => $signal, holder => $holder, children => $children);
            return {width => $record && $self->_literal_registry_contains($capture->{objects})
                ? $record->{selected_width} : undef};
        }
        # A generated reference needs a current capture-local allocation proof.
        # Preserve the existing nonliteral families without treating an absent
        # or revoked literal birth's compatibility width as exact.
        for my $family (
            ['_intermediate_width_allocation_capture', 'FSM::IntermediateWidthAllocationSupport', '_allocation_registry_matches'],
            ['_source_bitwise_tree_width_allocation_capture', 'FSM::SourceBitwiseTreeWidthSupport', '_source_tree_allocation_registry_matches'],
        ) {
            my ($bucket, $class, $registry_check) = @$family;
            my ($event) = grep {$_->{signal_name} eq $signal->{name}} @{$self->{$bucket} // []};
            next unless $event && $self->$registry_check($signal);
            my $record = $class->current_core(signal => $signal, holder => $event->{holder});
            return {width => $record->{selected_width}} if $record && $self->$registry_check($signal);
        }
        return {width => undef};
    });
}

sub parse_signal_reference($self, $signal_spec) {
    if (!ref($signal_spec)) {
        return $self->parse_scalar_expression($signal_spec);
    } else {
        return $self->parse_expression($signal_spec);
    }
}

sub handle_width_mismatch($self, $lhs_width, $rhs_width, $signal_name, $value_expr, $source_expr_ref) {
    if ($lhs_width > $rhs_width) {
        my $expand_bits = $lhs_width - $rhs_width;
        fsm_debug("          WIDTH EXPANSION: LHS($lhs_width) > RHS($rhs_width) - expanding RHS with $expand_bits zero bits", 3);
        my $zero_literal = FSM::CoreAST::Literal->new('0', width => $expand_bits, radix => 'binary');
        my $expanded_rhs = FSM::CoreAST::Concatenation->new($zero_literal, $$source_expr_ref);
        $$source_expr_ref = $expanded_rhs;
    } elsif ($lhs_width < $rhs_width) {
        my $truncate_bits = $rhs_width - $lhs_width;
        fsm_debug("          WIDTH TRUNCATION: LHS($lhs_width) < RHS($rhs_width) - truncating RHS by $truncate_bits bits", 3);
        my $high_bit = $lhs_width - 1;
        my $truncated_rhs;
        
        if (ref($$source_expr_ref) eq 'FSM::CoreAST::SignalRef') {
            my $signal = $$source_expr_ref->signal;
            $truncated_rhs = FSM::CoreAST::SignalRef->new($signal, slice => [$high_bit, 0]);
        } else {
            fsm_warn("Cannot truncate complex expression - leaving as-is");
            $truncated_rhs = $$source_expr_ref;
        }
        $$source_expr_ref = $truncated_rhs;
    }
}

sub _has_unresolved_inline_shift_birth($self, $signal) {
    my ($event) = grep {$_->{signal_name} eq $signal->{name}}
        @{$self->{_source_literal_width_allocation_capture} // []};
    return unless $event;
    my $children = $self->_source_literal_birth_children;
    my $holder = $event->{holder};
    my $capture = $self->_source_literal_allocation_registry_matches($signal, $children) or return;
    return $capture->{walk}{shifts} && !defined($capture->{record}{selected_width})
        && FSM::SourceLiteralWidthAllocationSupport->current_core(
            signal => $signal, holder => $holder, children => $children)
        && $self->_literal_registry_contains($capture->{objects});
}

sub propagate_width_to_expression($self, $expr, $width) {
    return unless $expr && $width;
    
    fsm_debug("          Propagating width $width to expression: " . ref($expr), 3);
    
    if (ref($expr) eq 'FSM::CoreAST::SignalRef') {
        my $signal = $expr->signal;
        if ($signal && (!$signal->width || $signal->width == 1) && $width > 1) {
            # A destination width cannot resolve a source tree containing an
            # unsized literal. Preserve this original inline-shift birth until
            # target-owned literal sizing supplies the actual helper width.
            return if $self->_has_unresolved_inline_shift_birth($signal);
            my $updated_signal = $self->{signal_manager}->register_signal($signal->name, 
                width => $width,
                type => $signal->type,
                is_output => $signal->get_attribute('is_output')
            );
            $expr->{signal} = $updated_signal;
        }
    } elsif (ref($expr) eq 'FSM::CoreAST::BinaryOp') {
        $self->propagate_width_to_expression($expr->left, $width) if $expr->left;
        $self->propagate_width_to_expression($expr->right, $width) if $expr->right;
    } elsif (ref($expr) eq 'FSM::CoreAST::UnaryOp') {
        # A reduction consumes its operand at the operand's own width. A wider
        # destination or sibling expression cannot resize that input vector.
        return if is_reduction_operator($expr->operator);
        $self->propagate_width_to_expression($expr->operand, $width) if $expr->operand;
    }
}

1;

=head1 NAME

FSM::Adapter::FSMGenFull::ExpressionBuilder - Build direct source expressions and parser-owned intermediates

=head1 INTERNAL WIDTH ALLOCATION

C<finalize_nary_expression> builds the actual n-ary AST and hoists multi-operand
bitwise AND/OR/XOR into a fresh owned intermediate. Before registration, its
existing C<infer_exact_expression_width> kernel supplies a positive known result
width. Core metadata, native declarations and guard truthiness therefore agree;
a wide intermediate is tested as a whole nonzero value rather than through its
low bit. Unary reductions remain scalar, and literal widths remain independent
max constraints. This sizing does not resize operand Signals.

C<infer_exact_expression_width> delegates to the bounded shared
C<FSM::CoreExpressionWidthSupport> walk without a target literal resolver.
Unsized literals and unknown expression classes remain unknown. The separate
shared API accepts an explicit target-owned unsized-literal resolver; the parser
never supplies a backend default. This preparatory boundary does not repair final
target/source agreement or establish symbolic literal floors.

Internal C<_capture_intermediate_width_allocations(callback)> runs one scalar
callback with source-local journals and returns C<{value, events}>. Its original
C<events> bucket retains binary whole-reference allocations. A separate optional
C<source_tree_events> bucket captures fresh source n-ary bitwise allocations with
their actual original tree and every ordered whole-reference slot. It is absent
when no eligible tree birth occurs. Both families stage explicit intrinsic-max
contracts. Events contain plain detached state and scalar identity fingerprints,
not Core owner references; they publish no Signal policy. Validated result and
operand revision counters revoke events on supported matching-state mutations.
Nesting refuses; success or exception restores the builder's prior state.
Unsupported shapes retain ordinary allocation without events. The exact bare
unannotated reference registration, final Parser width requirement/binding
publication and Analyzer role operations can refresh a still-current event.
Before each operation, actual registry identities and the whole event must match;
afterward, only its exact revision and authorized role delta may differ. External,
annotated, late, extra-source or stale writes cannot borrow that refresh. Ordinary
uncaptured builder paths use the same legacy writes. Source-tree refresh also
binds every repeated leaf slot and role, and checks actual registry membership
for the whole held tree. Scoped capture publishes no Core policy.
Completed direct Parser calls own capture and publication for these families;
an enclosing facade transaction defers
publication through actual role and interface completion. Failures and parse
reuse clear previous/partial policy. Publication installs only the already current
tracked birth, without a new semantic revision that would invalidate dependent
helpers. Direct Parser retains its existing registry/AST boundary and does not
gain facade interface membership. Factorizer provenance, target event joins and
generic range consumers remain separate successors.

A separate optional C<source_literal_events> bucket now journals actual fresh
direct bitwise literal helper births through
L<FSM::SourceLiteralWidthAllocationSupport>. Fresh name ownership and actual
registry membership of the helper and each independent source are required.
Raw parsed Core literal kinds and nullable exact widths preserve; the caller's
token spelling is not substituted for the parsed literal payload. Old binary
and source-tree buckets retain their shapes. Only exact bare-reference, role and
final width-requirement/binding operations can transport a current literal
holder. The complete old/new state must differ only by its named record/role
and one tracked revision, including every duplicate slot. Independent fields,
extra writes and stale/foreign membership withhold; final registry checks invoke
no source getters. Direct Parser completion now forwards this separate bucket;
the facade defers it until role and interface analysis also succeeds. Only a
still-current staged epoch and final raw registry join can publish detached
Core C<source_literal_width_allocation>. Failed validation/publication and reuse
clear old or partial policy. Publication preserves tracked semantic revisions;
matching writes during its final preparation cannot rebase the original birth.
Within a capture, exact inference now resolves actual generated references from
current local literal births before parent registration. Unknown or revoked
child intent withholds exact width rather than borrowing a compatibility width;
current nonliteral binary/tree proofs retain their own selected maxima. Ordinary
independent references and scalar-result wrappers retain their rules. Every fresh
supported nested literal allocation has its own detached birth. Named transport
validates all affected holders first, then refreshes children before parents.
Raw complete-source and registry barriers still apply at every step. After normal
Parser/facade validation, publication uses the original birth lookup and installs
children before parents. C<complete_core> requires each actual completed child
capsule to match its original birth's exact phase/digest projection. Independently
current replacements, stale epochs, changed record kinds and missing policy
withhold. Original birth capsules and semantic revisions preserve; the final raw
registry join follows all validation reads. The Core getter revalidates nested
completed relationships. Failure cleanup and reuse revoke partial/old policy.
Other writes revoke; unsupported profiles receive no literal birth. Capture failure
restores the prior journal scope, and ordinary uncaptured allocation preserves.

An unknown exact width retains the existing placeholder behavior. Selected
numeric widths do not create a declared-width binding or prove a mutable
symbolic relationship. Generic computed-shape propagation, target legality and
external override/runtime qualification remain separate contracts. Source
parsing and scope validation continue through the existing adapter surface.

=cut
