package FSM::ConcatenationSourceObservationSupport;

use v5.20;
use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(refaddr);
use FSM::ConcatenationWidthBirthSupport;
use FSM::CoreExpressionWidthSupport;

sub _json { return JSON::PP->new->canonical }
sub _identity { return ref($_[0]) ? sprintf('%x', refaddr($_[0])) : undef }
sub _invalid { die "Unsupported concatenation source observation\n" }

# Traverse the bounded expected record, never an unbounded caller record. Exact
# scalar JSON kinds matter as well as values. No caller serialization hooks run.
sub _same_record {
    my ($actual, $expected) = @_;
    if (!ref($expected)) {
        return 0 if ref($actual) || defined($actual) != defined($expected);
        return 1 unless defined $expected;
        return 0 unless length($actual) == length($expected);
        return _json()->allow_nonref->encode($actual) eq _json()->allow_nonref->encode($expected);
    }
    return 0 unless ref($actual) eq ref($expected);
    return ($actual ? 1 : 0) == ($expected ? 1 : 0) if ref($expected) eq 'JSON::PP::Boolean';
    if (ref($expected) eq 'ARRAY') {
        return 0 if tied(@$actual) || @$actual != @$expected;
        for my $index (0 .. $#$expected) {
            return 0 unless _same_record($actual->[$index], $expected->[$index]);
        }
        return 1;
    }
    return 0 unless ref($expected) eq 'HASH' && !tied(%$actual) && keys(%$actual) == keys(%$expected);
    for my $key (sort keys %$expected) {
        return 0 unless exists($actual->{$key}) && _same_record($actual->{$key}, $expected->{$key});
    }
    return 1;
}

# Copy raw declaration data without TO_JSON, overload or arbitrary getters.
# Container identities distinguish equal-valued replacements. These are read
# observations, not a write tracker or a promise to detect restored scalar edits.
sub _plain {
    my ($value, $walk, $depth) = @_;
    _invalid() if $depth > FSM::CoreExpressionWidthSupport::MAX_DEPTH()
        || --$walk->{remaining} < 0;
    if (!ref($value)) {
        _invalid() if defined($value) && length($value) > FSM::CoreExpressionWidthSupport::MAX_NODES();
        return $value;
    }
    return $value ? JSON::PP::true : JSON::PP::false if JSON::PP::is_bool($value);
    my $class = ref($value);
    _invalid() unless $class eq 'HASH' || $class eq 'ARRAY';
    my $identity = _identity($value);
    _invalid() if $walk->{active}{$identity};
    local $walk->{active}{$identity} = 1;
    push @{$walk->{containers}}, [$class, $identity];
    if ($class eq 'ARRAY') {
        _invalid() if tied(@$value) || @$value > $walk->{remaining};
        return [map { _plain($_, $walk, $depth + 1) } @$value];
    }
    _invalid() if tied(%$value) || keys(%$value) > $walk->{remaining};
    my %copy;
    for my $key (sort keys %$value) {
        _invalid() if length($key) > FSM::CoreExpressionWidthSupport::MAX_NODES();
        $copy{$key} = _plain($value->{$key}, $walk, $depth + 1);
    }
    return \%copy;
}

sub _signal {
    my ($signal, $walk) = @_;
    _invalid() unless ref($signal) eq 'FSM::CoreAST::Signal' && !tied(%$signal);
    _invalid() if defined($signal->{driving_ast}) && !ref($signal->{driving_ast});
    my %fields;
    for my $field (qw(name _width type signed state_model declared_type_name declared_type_spec
        constraints _declared_width_source _declared_width_binding _declared_width_requirements
        _declared_width_requirements_state _intermediate_width_allocation_revision)) {
        $fields{$field} = _plain($signal->{$field}, $walk, 0);
    }
    my $attributes = $signal->{attributes};
    _invalid() unless ref($attributes) eq 'HASH' && !tied(%$attributes);
    $fields{roles} = {map { $_ => _plain($attributes->{$_}, $walk, 0) }
        qw(is_intermediate is_output is_aux_output width_declared signal_role)};
    return {identity => _identity($signal), fields => \%fields,
        driving_ast => _identity($signal->{driving_ast}), attributes => _identity($attributes)};
}

sub _operands {
    my ($node, $module, $names, $budget, $depth) = @_;
    _invalid() if $depth > FSM::CoreExpressionWidthSupport::MAX_DEPTH() || --$$budget < 0;
    _invalid() unless (ref($node) eq 'FSM::CoreAST::SignalRef'
        || ref($node) eq 'FSM::CoreAST::Literal' || ref($node) eq 'FSM::CoreAST::Concatenation')
        && !tied(%$node);
    if (ref($node) eq 'FSM::CoreAST::SignalRef') {
        my $signal = $node->{signal};
        _invalid() unless ref($signal) eq 'FSM::CoreAST::Signal' && !tied(%$signal)
            && !defined($node->{slice}) && defined($signal->{name}) && !ref($signal->{name})
            && ($module->{signals}{$signal->{name}} // 0) == $signal;
        push @$names, $signal->{name};
        return;
    }
    return if ref($node) eq 'FSM::CoreAST::Literal';
    _invalid() unless ref($node->{operands}) eq 'ARRAY' && !tied(@{$node->{operands}})
        && @{$node->{operands}} >= 2 && @{$node->{operands}} <= $$budget;
    _operands($_, $module, $names, $budget, $depth + 1) for @{$node->{operands}};
}

sub _snapshot {
    my (%args) = @_;
    my ($factorizer, $module, $analysis, $name) = @args{qw(factorizer fsm_module assignment_analysis signal_name)};
    _invalid() unless ref($factorizer) eq 'FSM::HDL::ASTFactorization'
        && ref($module) eq 'FSM::CoreAST::FSMModule' && ref($analysis) eq 'HASH'
        && !tied(%$factorizer) && !tied(%$module) && !tied(%$analysis)
        && defined($name) && !ref($name)
        && ref($module->{signals}) eq 'HASH' && !tied(%{$module->{signals}})
        && ref($factorizer->{_concatenation_width_births}) eq 'HASH'
        && !tied(%{$factorizer->{_concatenation_width_births}})
        && ref($factorizer->{intermediate_signals}) eq 'HASH'
        && !tied(%{$factorizer->{intermediate_signals}});
    my $entry = $factorizer->{intermediate_signals}{$name};
    _invalid() unless ref($entry) eq 'HASH' && !tied(%$entry);
    my (@names, %signals, %assignments, %scope);
    my $budget = FSM::CoreExpressionWidthSupport::MAX_NODES();
    _operands($entry->{ast}, $module, \@names, \$budget, 0);
    my $birth = FSM::ConcatenationWidthBirthSupport->current_birth(
        factorizer => $factorizer, signal_name => $name,
        holder => $factorizer->{_concatenation_width_births}{$name}) or return;
    my $walk = {remaining => FSM::CoreExpressionWidthSupport::MAX_NODES(), active => {}, containers => []};
    for my $key (sort keys %{$module->{signals}}) {
        my $signal = $module->{signals}{$key};
        _invalid() unless ref($signal) eq 'FSM::CoreAST::Signal'
            && defined($signal->{name}) && !ref($signal->{name}) && $signal->{name} eq $key;
        $signals{$key} = _signal($signal, $walk);
    }
    for my $key (sort keys %$analysis) {
        my $row = $analysis->{$key};
        _invalid() unless ref($row) eq 'HASH' && !tied(%$row);
        my $lhs = $row->{lhs_ast};
        _invalid() unless (ref($lhs) eq 'FSM::CoreAST::SignalRef' || ref($lhs) eq 'FSM::AST::SignalRef')
            && !tied(%$lhs);
        my $state = {row => _identity($row), lhs => _identity($lhs), class => ref($lhs)};
        if (ref($lhs) eq 'FSM::CoreAST::SignalRef') {
            $state->{signal} = _signal($lhs->{signal}, $walk);
            $state->{slice} = _plain($lhs->{slice}, $walk, 0);
        } else {
            $state->{control} = {map { $_ => _plain($lhs->{$_}, $walk, 0) }
                qw(signal_name is_fsm_state_next is_fsm_state_register)};
            _invalid() unless ref($row->{assignments}) eq 'ARRAY' && !tied(@{$row->{assignments}});
            $state->{assignment_map} = _identity($row->{assignments});
            $state->{assignments} = [map {
                my $assignment = $_;
                _invalid() unless ref($assignment) eq 'HASH' && !tied(%$assignment);
                +{identity => _identity($assignment), fields => {map {
                    $_ => _plain($assignment->{$_}, $walk, 0)
                } qw(is_state_trans assignment_intent source_provenance operator rhs)}};
            } @{$row->{assignments}}];
        }
        $assignments{$key} = $state;
    }
    for my $field (qw(name parameters _parameter_default_sources _parameter_default_bindings)) {
        $scope{$field} = _plain($module->{$field}, $walk, 0);
    }
    _invalid() unless ref($module->{states}) eq 'ARRAY' && !tied(@{$module->{states}});
    my @states = map {
        _invalid() unless ref($_) eq 'FSM::CoreAST::State' && !tied(%$_);
        +{identity => _identity($_), name => _plain($_->{name}, $walk, 0)};
    } @{$module->{states}};
    my $record = {kind => 'concatenation_source_observation',
        expression_tree => $birth->{record}{expression_tree}, source_names => \@names,
        source_signals => {map { $_ => $signals{$_} } @names}};
    my $state = {module => _identity($module), signal_map => _identity($module->{signals}),
        assignment_map => _identity($analysis), states_map => _identity($module->{states}),
        factorizer_map => _identity($factorizer->{intermediate_signals}),
        birth_map => _identity($factorizer->{_concatenation_width_births}),
        birth_holder => _identity($factorizer->{_concatenation_width_births}{$name}),
        birth => $birth->{state}, signals => \%signals, assignments => \%assignments,
        scope => \%scope, states => \@states, containers => $walk->{containers}};
    return {record => $record, state => _json()->encode($state)};
}

sub capture {
    my ($class, %args) = @_;
    my $snapshot = eval { _snapshot(%args) };
    return $@ || !$snapshot ? undef : _json()->decode(_json()->encode($snapshot));
}

sub current {
    my ($class, %args) = @_;
    my $result = eval {
        my $holder = $args{holder};
        return unless ref($holder) eq 'HASH' && !tied(%$holder)
            && join(',', sort keys %$holder) eq 'record,state'
            && defined($holder->{state}) && !ref($holder->{state});
        my $snapshot = _snapshot(%args) or return;
        return unless $holder->{state} eq $snapshot->{state}
            && _same_record($holder->{record}, $snapshot->{record});
        return _json()->decode(_json()->encode($snapshot));
    };
    return $@ ? undef : $result;
}

1;

=head1 NAME

FSM::ConcatenationSourceObservationSupport - Private getter-free Core concatenation source observations

=head1 DESCRIPTION

C<capture> and C<current> take an actual C<factorizer>, C<signal_name>,
C<fsm_module> and complete normalized C<assignment_analysis>. A current original
factorizer birth and built-in whole Core references to the actual module Signals
are required. Runtime name-only references supply no Core membership proof.

The detached capsule contains C<record> and opaque C<state>. Its record has
C<kind =E<gt> concatenation_source_observation>, the original ordered
C<expression_tree>, duplicate-preserving C<source_names>, and C<source_signals>
keyed by physical name. Source entries retain identity tokens and raw declaration,
requirement, binding, role and revision fields. Nested/repeated occurrences and
raw literal value/width/radix preserve, including an unknown literal width.

Raw state binds the actual module, source map, normalized LHS and control rows,
parameter/declaration scope and every observed data-container identity. Nonoperand
declarations participate. Equal-valued object or container replacement invalidates
an older observation. Candidate numeric inference remains independent. No source
getter is invoked and no state is installed in the module or allocator. Retained
capsules contain no owner, AST or Signal references.

These are point-in-time read observations, not write history or source eligibility.
Restored scalar edits with no surviving revision change are not observed. Signed,
typed, constrained, opaque and computed source fields remain raw and unqualified;
numeric width one does not establish scalar/vector rank. Canonical semantic proof,
getter-versus-raw coherence, generation completion, sum ranges and target emission
remain separate consumers. Caller-supplied analysis completeness is a contract,
not attestation. A capsule alone cannot authorize any allocation or range.

AST depth/occurrences and raw-data depth/occurrences separately use the existing
Core width-walk bounds. Each raw scalar/key uses C<MAX_NODES> as a character bound.
Unsupported subclasses, foreign members, malformed/cyclic/over-bound raw data
withhold silently. Those metadata limits are not source-capacity promises.

=head1 METHODS

=head2 capture(factorizer => OWNER, signal_name => NAME, fsm_module => MODULE, assignment_analysis => MAP)

Return a detached raw observation capsule, or undef. Reads never install or
refresh allocator provenance, alter source fields or infer a selected sum.

=head2 current(factorizer => OWNER, signal_name => NAME, fsm_module => MODULE, assignment_analysis => MAP, holder => CAPSULE)

Reobserve the same actual inputs and return detached data only when the complete
record and raw state agree. A changed or malformed holder withholds. Revalidation
never refreshes a stale observation; a fresh capture is a distinct observation.

=cut
