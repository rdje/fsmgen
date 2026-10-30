package FSM::ConcatenationSourceWidthSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(refaddr);
use FSM::ConcatenationSourceObservationSupport;
use FSM::DirectDeclaredWidthSupport;

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

=head1 METHODS

=head2 prepare(factorizer => OWNER, signal_name => NAME, fsm_module => MODULE, assignment_analysis => MAP, target_language => LANGUAGE, observation => FRAME)

Prepare independent current operand contracts or throw. Language aliases are the
canonical direct-width aliases. Unknown literal widths stay unknown.

=head2 current(factorizer => OWNER, signal_name => NAME, fsm_module => MODULE, assignment_analysis => MAP, target_language => LANGUAGE, holder => PLAN)

Revalidate the exact original observation and complete plan without refreshing it.
Return detached data on agreement, otherwise undef.

=cut
