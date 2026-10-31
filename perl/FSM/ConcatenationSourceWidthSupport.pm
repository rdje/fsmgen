package FSM::ConcatenationSourceWidthSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(refaddr);
use FSM::ConcatenationSourceObservationSupport;
use FSM::DirectDeclaredWidthSupport;
use FSM::ParameterDefaultEnvironmentSupport;
use FSM::WidthExpressionSupport;
use FSM::Backend::VerilogFamily::WidthExpressionEmitter;

sub _json { return JSON::PP->new->canonical }
sub _identity { return sprintf('%x', refaddr($_[0])) }
sub _fail { confess "Direct concatenation source $_[0]\n" }

# The raw observation has already bounded and checked every value read here.
# This projection deliberately does not invoke the semantic getters it checks.
sub _raw_signal {
    my ($signal) = @_;
    return {identity => _identity($signal),
        (map { $_ => $signal->{$_} } qw(name type signed state_model declared_type_name declared_type_spec constraints)),
        width => $signal->{_width}, declared_width_source => $signal->{_declared_width_source},
        declared_width_binding => $signal->{_declared_width_binding},
        declared_width_requirements => $signal->{_declared_width_requirements},
        _intermediate_width_allocation_revision => $signal->{_intermediate_width_allocation_revision} // 0};
}

sub _raw_source_state {
    my (%args) = @_;
    my ($module, $analysis) = @args{qw(fsm_module assignment_analysis)};
    my %signals = map { $_ => _raw_signal($module->{signals}{$_}) } sort keys %{$module->{signals}};
    my %assignments;
    for my $name (sort keys %$analysis) {
        my $entry = $analysis->{$name};
        my $lhs = $entry->{lhs_ast};
        my $row = {lhs_identity => _identity($lhs), lhs_class => ref($lhs)};
        if (ref($lhs) eq 'FSM::CoreAST::SignalRef') {
            $row->{name} = $lhs->{signal}{name};
            $row->{signal} = _raw_signal($lhs->{signal});
        } else {
            $row->{name} = $lhs->{signal_name};
            $row->{state_next} = $lhs->{is_fsm_state_next} ? 1 : 0;
            $row->{assignments} = [map {
                my $assignment = $_;
                # Match the canonical legacy flattened assignment snapshot.
                map { $_ => $assignment->{$_} }
                    qw(is_state_trans assignment_intent source_provenance operator rhs);
            } @{$entry->{assignments}}];
        }
        $assignments{$name} = $row;
    }
    return _json()->encode({module_identity => _identity($module), name => $module->{name},
        parameters => $module->{parameters}, sources => $module->{_parameter_default_sources} // {},
        bindings => $module->{_parameter_default_bindings} // {}, signals => \%signals,
        assignments => \%assignments});
}

sub _barrier {
    my (%args) = @_;
    return FSM::ConcatenationSourceObservationSupport->current(%args, holder => $args{observation})
        // _fail('requires the original current complete raw observation');
}

sub _coherent_getters {
    my ($expected, %args) = @_;
    my $actual = FSM::DirectDeclaredWidthSupport->_capture_source_state(\%args);
    _fail('semantic getters disagree with the observed raw declarations') unless $actual eq $expected;
    _barrier(%args);
}

sub _operand {
    my ($name, $fields, $plan) = @_;
    _fail("'$name' requires a plain unsigned whole declared operand")
        if $fields->{signed} || defined($fields->{state_model})
            || defined($fields->{declared_type_name}) || defined($fields->{declared_type_spec})
            || !defined($fields->{type}) || ref($fields->{type}) || $fields->{type} !~ /\A(?:wire|reg)\z/
            || ref($fields->{constraints}) ne 'ARRAY' || @{$fields->{constraints}};
    _fail("'$name' excludes computed or intermediate source declarations")
        if $fields->{roles}{is_intermediate}
            || ($fields->{roles}{signal_role} // '') =~ /INTERMEDIATE/;
    my $binding = $fields->{_declared_width_binding};
    my $requirements = $fields->{_declared_width_requirements};
    if ($requirements && !$binding) {
        # A plain literal declaration supplies an independent fixed contract.
        # Generated floors, combined declarations and unexplained captures do not.
        my $rows = $requirements->{requirements};
        _fail("'$name' has opaque or combined fixed declaration requirements")
            unless ref($rows) eq 'ARRAY' && @$rows == 1;
        my $row = $rows->[0];
        _fail("'$name' has an unproved fixed declaration requirement")
            unless ($row->{kind} // '') eq 'declaration'
                && defined($row->{expression}) && !ref($row->{expression})
                && $row->{expression} =~ /\A[0-9]*[1-9][0-9]*\z/
                && $row->{expression} == $fields->{_width} && $row->{width} == $fields->{_width}
                && ($row->{signal} // '') eq $name
                && !defined($row->{width_capture}) && !defined($row->{declared_type_name})
                && !defined($row->{declared_type_spec});
    }
    _fail("'$name' canonical source plan disagrees with the raw declaration")
        unless ref($plan) eq 'HASH' && $plan->{name} eq $name
            && $plan->{width} == $fields->{_width} && !$plan->{signed}
            && !defined($plan->{state_model}) && !defined($plan->{declared_type_name})
            && !defined($plan->{declared_type_spec})
            && defined($plan->{width_plan}) == defined($binding);
    my $width_plan = $plan->{width_plan};
    return {name => $name, width => $plan->{width},
        is_vector => $width_plan ? $width_plan->{is_vector} : ($plan->{width} > 1 ? 1 : 0),
        width_plan => $width_plan};
}

sub prepare {
    my ($class, %args) = @_;
    my $frame = _barrier(%args);
    my $raw = _raw_source_state(%args);
    _coherent_getters($raw, %args);
    my $source = FSM::DirectDeclaredWidthSupport->prepare_module(%args);
    _barrier(%args);
    _coherent_getters($raw, %args);
    my @operands;
    for my $name (@{$frame->{record}{source_names}}) {
        my $entry = $frame->{record}{source_signals}{$name};
        _fail("'$name' excludes a computed driving expression") if defined($entry->{driving_ast});
        # Numeric checks may change Perl scalar JSON flags. Keep the original
        # observation byte/kind identity separate from the eligibility walk.
        my $fields = _json()->decode(_json()->encode($entry->{fields}));
        push @operands, _operand($name, $fields, $source->{signals}{$name});
    }
    # Nothing above infers a common maximum or concatenation result width.
    my $record = {kind => 'concatenation_source_widths', target_language => $source->{target_language},
        source_scope => $source->{source_scope}, expression_tree => $frame->{record}{expression_tree},
        source_names => $frame->{record}{source_names}, operands => \@operands};
    _barrier(%args); # last operation touching live inputs, after every semantic read
    return _json()->decode(_json()->encode({record => $record, observation => $frame}));
}

sub current {
    my ($class, %args) = @_;
    my $result = eval {
        my $holder = $args{holder};
        return unless ref($holder) eq 'HASH' && !tied(%$holder)
            && join(',', sort keys %$holder) eq 'observation,record';
        my $expected = $class->prepare(%args, observation => $holder->{observation});
        return unless FSM::ConcatenationSourceObservationSupport::_same_record($holder, $expected);
        return $expected;
    };
    return $@ ? undef : $result;
}

# Walk only the authenticated detached tree, in the source's original order.
# A repeated signal consumes another independent slot; literals never borrow a
# neighbouring signal width or the target's unrelated unsized-literal rule.
sub _sum_terms {
    my ($tree, $operands, $terms, $cursor) = @_;
    if ($tree->[0] eq 'concat') {
        _sum_terms($tree->[$_], $operands, $terms, $cursor) for 1 .. $#$tree;
        return;
    }
    _fail('sum exceeds 32 ordered width terms') if @$terms >= 32;
    if ($tree->[0] eq 'signal') {
        my $operand = $operands->[$$cursor++];
        _fail('sum source slots disagree with the original ordered tree')
            unless $operand && $operand->{name} eq $tree->[1];
        push @$terms, {kind => 'signal', %$operand};
        return;
    }
    my $literal = $tree->[1];
    _fail('sum requires an explicit positive literal width')
        unless defined($literal->{width}) && !ref($literal->{width})
            && $literal->{width} =~ /\A[0-9]*[1-9][0-9]*\z/;
    my $width = $literal->{width};
    $width =~ s/\A0+//;
    push @$terms, {kind => 'literal', literal => $literal,
        width => $width, is_vector => $width eq '1' ? 0 : 1,
        width_plan => undef};
}

sub prepare_sum {
    my ($class, %args) = @_;
    my $sources = $class->current(%args)
        // _fail('sum requires the original current independent source holder');
    my $source = $sources->{record};
    _fail('sum currently requires a Verilog-family target')
        unless $source->{target_language} =~ /\A(?:systemverilog|verilog)\z/;
    my @source_args = (%args, observation => $sources->{observation});
    my $raw = _raw_source_state(%args);
    my $module = $args{fsm_module};
    my $maps = {parameters => $module->parameters, sources => $module->parameter_default_sources,
        bindings => $module->parameter_default_bindings};
    my $environment = FSM::ParameterDefaultEnvironmentSupport->prove_binding_observations(%$maps)->{environment};
    _coherent_getters($raw, @source_args);
    my (@terms, $cursor);
    $cursor = 0;
    _sum_terms($source->{expression_tree}, $source->{operands}, \@terms, \$cursor);
    _fail('sum has unused original source slots') unless $cursor == @{$source->{operands}};
    my $evaluator = FSM::WidthExpressionSupport->new;
    my @values = map {$evaluator->evaluate_constant_integer_scalar($_->{width}, 'Concatenation source sum')} @terms;
    my $width = sprintf('%s', $evaluator->apply_constant_width_operator(
        '+', \@values, 'Concatenation source sum')->bstr);
    my $symbolic = grep {$_->{width_plan} && $_->{width_plan}{profile} eq 'symbolic'} @terms;
    my $range;
    if ($symbolic) {
        _fail('sum requires the original matching parameter environment')
            unless $environment && _json()->encode($environment->{scope}) eq _json()->encode($source->{source_scope});
        $range = FSM::Backend::VerilogFamily::WidthExpressionEmitter->lower_sum_range(
            target_language => $source->{target_language}, environment => $environment,
            required_scope_kind => 'direct_module', context => 'Concatenation source sum',
            operands => [map {{width => $_->{width},
                width_contract => $_->{width_plan} ? $_->{width_plan}{width_contract} : undef}} @terms]);
    }
    my $record = {kind => 'concatenation_source_sum', target_language => $source->{target_language},
        profile => $symbolic ? 'symbolic' : 'fixed', source_scope => $source->{source_scope},
        width => $width, is_vector => 1, terms => \@terms, range_text => $range};
    _barrier(@source_args); # getter-free closure after every source/environment read
    return _json()->decode(_json()->encode({sources => $sources, record => $record}));
}

sub current_sum {
    my ($class, %args) = @_;
    my $result = eval {
        my $holder = $args{holder};
        return unless ref($holder) eq 'HASH' && !tied(%$holder)
            && join(',', sort keys %$holder) eq 'record,sources';
        my $expected = $class->prepare_sum(%args, holder => $holder->{sources});
        return unless FSM::ConcatenationSourceObservationSupport::_same_record($holder, $expected);
        return $expected;
    };
    return $@ ? undef : $result;
}

1;

=head1 NAME

FSM::ConcatenationSourceWidthSupport - Private independent current concatenation operand contracts

=head1 DESCRIPTION

C<prepare> takes the actual C<factorizer>, C<signal_name>, C<fsm_module>, complete
normalized C<assignment_analysis>, C<target_language> and an original getter-free
C<observation> from C<ConcatenationSourceObservationSupport>. It requires that
observation to remain current before and after canonical
C<DirectDeclaredWidthSupport::prepare_module>. Complete raw barriers include
nonoperand declarations and late semantic reads. Getter snapshots must agree
with the bounded raw declaration projection; stale observations are never
recaptured or refreshed. Canonical preparation owns parameter environment,
requirement/binding consistency, target range legality and width-one vector rank.

The detached result contains C<observation> and a C<record> with
C<kind =E<gt> concatenation_source_widths>, canonical C<target_language>, original
C<source_scope>, ordered C<expression_tree>, duplicate-preserving C<source_names>
and ordered C<operands>. Each operand has C<name>, numeric C<width>, C<is_vector>
and its independent canonical C<width_plan> (undef for a plain fixed width).
Independent fixed and mutable contracts may coexist; repeated slots and literal
value/width/radix fields remain separate, including unknown literal widths.
No shared-maximum rule, selected sum, generic result range or emission authority
is supplied.

Signed, state, named-type, constrained, computed/intermediate, opaque, combined,
foreign or stale source profiles refuse. Without a captured binding, a retained
requirement must be a single matching literal declaration. A plain Core Signal
with no source metadata retains its explicit fixed width. Parameter/source/type
getters that withhold installed records fail the raw coherence check. Preparation
throws on unsupported input; C<current> recomputes from the holder's original
observation, checks the complete detached result and returns undef on divergence.
No module, Signal, AST or allocator owner is retained and no tracker is installed.

These are in-process observations of trusted built-in Core representations, not
an attestation of arbitrary caller code or hidden write history. Restored scalar
writes without a surviving revision remain outside the raw observer contract.
Backend event completion, current symbolic sum proof, target emission, override
execution and full/public qualification remain separate consumers.

C<prepare_sum> consumes that original source C<holder> with the same actual
inputs and revalidates it; it never captures a replacement observation. Only
Verilog-family targets qualify. It walks the authenticated nested tree in order,
preserving each repeated source slot and explicit literal value/width/radix.
Unknown literal widths refuse rather than borrowing another target sizing rule.
At most 32 flattened terms qualify. Canonical integer arithmetic produces an
exact positive decimal-string sum. Fixed-only sums have no symbolic range;
mutable sums use the canonical parameter environment and shared prepared-sum
renderer, retaining independent contracts and width-one operand vector rank.
Complete getter coherence and final raw barriers include nonoperand declarations
and all parameter maps. Failed/stale reads cannot refresh the original holder.

The detached result has C<sources> (the original revalidated source holder) and
C<record> with C<kind =E<gt> concatenation_source_sum>, canonical target, profile,
source scope, exact C<width>, packed C<is_vector>, ordered C<terms> and optional
C<range_text>. Each term retains its signal contract or original literal fields.
C<current_sum> checks the complete original result, including scalar JSON kinds,
and returns undef on divergence. Neither operation installs metadata, retains a
caller graph or proves a completed backend event, target declaration/namespace,
emitted expression or ledger. Those joins and external execution remain separate.

=head1 METHODS

=head2 prepare(factorizer => OWNER, signal_name => NAME, fsm_module => MODULE, assignment_analysis => MAP, target_language => LANGUAGE, observation => FRAME)

Prepare independent current operand contracts or throw. Language aliases are the
canonical direct-width aliases. Unknown literal widths stay unknown.

=head2 current(factorizer => OWNER, signal_name => NAME, fsm_module => MODULE, assignment_analysis => MAP, target_language => LANGUAGE, holder => PLAN)

Revalidate the exact original observation and complete plan without refreshing it.
Return detached data on agreement, otherwise undef.

=head2 prepare_sum(factorizer => OWNER, signal_name => NAME, fsm_module => MODULE, assignment_analysis => MAP, target_language => LANGUAGE, holder => SOURCES)

Derive an ordered sum from the original current source holder or throw.

=head2 current_sum(factorizer => OWNER, signal_name => NAME, fsm_module => MODULE, assignment_analysis => MAP, target_language => LANGUAGE, holder => SUM)

Revalidate the original complete source sum without recapture; return undef on
stale, unsupported or changed input.

=cut
