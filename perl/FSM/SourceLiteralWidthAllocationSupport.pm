package FSM::SourceLiteralWidthAllocationSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use Encode qw(encode FB_CROAK);
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);
use FSM::CoreExpressionWidthSupport;
use FSM::IntermediateWidthAllocationSupport;
use FSM::SourceBitwiseTreeWidthSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub _json { return JSON::PP->new->canonical }
sub _identity { return FSM::SourceBitwiseTreeWidthSupport::_identity($_[0]) }
sub _positive { return defined FSM::IntermediateWidthAllocationSupport::_width($_[0]) }
sub _capsule_digest {
    my ($text) = @_;
    return sha256_hex(encode('UTF-8', $text, FB_CROAK));
}

sub _literal_record {
    my ($record) = @_;
    return unless ref($record) eq 'HASH' && join(',', sort keys %$record) eq 'radix,value,width';
    return if !defined($record->{value}) || ref($record->{value})
        || !defined($record->{radix}) || ref($record->{radix});
    return if defined($record->{width}) && !_positive($record->{width});
    return $record;
}

sub _validate_tree {
    my ($tree, $walk, $depth) = @_;
    return unless ref($tree) eq 'ARRAY' && $depth <= FSM::CoreExpressionWidthSupport::MAX_DEPTH()
        && --$walk->{remaining} >= 0;
    my $identity = refaddr($tree);
    return if $walk->{active}{$identity};
    local $walk->{active}{$identity} = 1;
    my $kind = $tree->[0];
    return unless defined($kind) && !ref($kind);
    if ($kind eq 'signal') {
        return @$tree == 2 && FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($tree->[1]);
    }
    if ($kind eq 'literal') {
        return @$tree == 2 && _literal_record($tree->[1]);
    }
    return unless @$tree == 3 && $kind =~ /\A[&|^]\z/;
    return _validate_tree($tree->[1], $walk, $depth + 1)
        && _validate_tree($tree->[2], $walk, $depth + 1);
}

sub copy_record {
    my ($class, $record) = @_;
    confess "Source literal allocation requires a closed raw source record\n"
        unless ref($record) eq 'HASH' && join(',', sort keys %$record) eq 'expression_tree,kind,selected_width'
            && defined($record->{kind}) && !ref($record->{kind}) && $record->{kind} eq 'source_literal_operand_max'
            && (!defined($record->{selected_width}) || _positive($record->{selected_width}))
            && _validate_tree($record->{expression_tree}, {
                remaining => FSM::CoreExpressionWidthSupport::MAX_NODES(), active => {}}, 0);
    return _json()->decode(_json()->encode($record));
}

# Raw stamps are read without invoking source getters. A getter used later in a
# walk may write an earlier object; the final barrier must observe that write.
sub _raw_signal {
    my ($signal) = @_;
    my @keys = qw(name _width type signed state_model declared_type_name declared_type_spec constraints
        _declared_width_source _declared_width_binding _declared_width_requirements _declared_width_requirements_state);
    return _json()->encode({fields => {map {exists($signal->{$_}) ? ($_ => $signal->{$_}) : ()} @keys},
        revision => $signal->{_intermediate_width_allocation_revision} // 0,
        ast_identity => blessed($signal->{driving_ast}) ? _identity($signal->{driving_ast}) : undef,
        roles => {map {exists($signal->{attributes}{$_}) ? ($_ => $signal->{attributes}{$_}) : ()}
            qw(is_intermediate is_output is_aux_output width_declared signal_role)}});
}

sub _raw_node {
    my ($node) = @_;
    return _json()->encode({value => $node->{value}, width => $node->{width}, radix => $node->{radix}})
        if $node->isa('FSM::CoreAST::Literal');
    return _json()->encode({signal => blessed($node->{signal}) ? _identity($node->{signal}) : undef,
        slice => $node->{slice}}) if $node->isa('FSM::CoreAST::SignalRef');
    return _json()->encode({operator => $node->{operator},
        operands => [map {blessed($_) ? _identity($_) : undef} @{$node->{operands}}]});
}

sub _observe_signal {
    my ($signal, $walk) = @_;
    return unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal')
        && ref($signal->{attributes}) eq 'HASH';
    my $raw = _raw_signal($signal);
    my $descriptor = FSM::SourceBitwiseTreeWidthSupport::_plain($signal) or return;
    return unless _raw_signal($signal) eq $raw;
    push @{$walk->{signals}}, $signal;
    push @{$walk->{stamps}}, [$signal, $raw, 'signal'];
    return {%$descriptor, raw_state => $raw};
}

sub _core_tree {
    my ($node, $root, $walk, $depth) = @_;
    return unless blessed($node) && $depth <= FSM::CoreExpressionWidthSupport::MAX_DEPTH()
        && --$walk->{shared}{remaining} >= 0;
    my $address = refaddr($node);
    return if $walk->{shared}{active_nodes}{$address};
    local $walk->{shared}{active_nodes}{$address} = 1;
    return unless $node->isa('FSM::CoreAST::Literal') || $node->isa('FSM::CoreAST::SignalRef')
        || ($node->isa('FSM::CoreAST::BinaryOp') && ref($node->{operands}) eq 'ARRAY' && @{$node->{operands}} == 2);
    push @{$walk->{stamps}}, [$node, _raw_node($node), 'node'];
    push @{$walk->{nodes}}, _identity($node);
    if ($node->isa('FSM::CoreAST::Literal')) {
        my $record = _literal_record({value => $node->value, width => $node->width, radix => $node->radix}) or return;
        ++$walk->{literals};
        return ['literal', $record];
    }
    if ($node->isa('FSM::CoreAST::SignalRef')) {
        return if defined $node->slice;
        my $source = $node->signal;
        my $descriptor = _observe_signal($source, $walk) or return;
        return if refaddr($source) == refaddr($root) || $source->name eq $root->name;
        my $name = $descriptor->{name};
        my $names = $walk->{shared}{names};
        return if exists($names->{$name}) && $names->{$name} ne $descriptor->{identity_token};
        $names->{$name} = $descriptor->{identity_token};
        push @{$walk->{operands}}, $descriptor;
        if ($descriptor->{roles}{is_intermediate}) {
            return _child_tree($node, $source, $walk, $depth);
        }
        return ['signal', $name];
    }
    my $operator = $node->operator;
    return unless defined($operator) && !ref($operator) && $operator =~ /\A[&|^]\z/;
    my $left = _core_tree($node->left, $root, $walk, $depth + 1) or return;
    my $right = _core_tree($node->right, $root, $walk, $depth + 1) or return;
    ++$walk->{operators};
    return [$operator, $left, $right];
}

sub _child_tree {
    my ($reference, $source, $walk, $depth) = @_;
    my $options = $walk->{shared}{children} or return;
    # Births are explicitly supplied by the capture owner. Completion never
    # calls that lookup: it requires the actual installed Core child policy.
    my $holder = $options->{phase} eq 'birth' ? $options->{lookup}->($reference)
        : $source->{_source_literal_width_allocation};
    return unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state'
        && defined($holder->{state}) && !ref($holder->{state});
    my $record = __PACKAGE__->copy_record($holder->{record});
    my $raw = _json()->encode($holder);
    my $child = _capture_signal($source, $walk->{shared}, $depth + 1) or return;
    return unless _tracked($child) && _matches($record, $child) && $holder->{state} eq $child->{state};
    push @{$walk->{holders}}, [$holder, $raw, $options->{phase} eq 'completed' ? $source : undef];
    push @{$walk->{children}}, {reference_identity => _identity($reference),
        signal_identity => _identity($source), phase => $options->{phase}, holder_digest => _capsule_digest($raw)};
    push @{$walk->{child_captures}}, {capsule => _json()->decode($raw), capture => $child};
    # The record expands original source syntax. Separate edge identities bind
    # actual helper ownership even when two expanded subtrees are text-equal.
    for my $key (qw(signals stamps nodes operands holders)) {
        push @{$walk->{$key}}, @{$child->{walk}{$key}};
    }
    $walk->{operators} += $child->{walk}{operators};
    $walk->{literals} += $child->{walk}{literals};
    $walk->{reference_widths}{refaddr($reference)} = $record->{selected_width};
    return $record->{expression_tree};
}

sub _unchanged {
    my ($walk) = @_;
    for my $stamp (@{$walk->{stamps}}) {
        my ($object, $raw, $kind) = @$stamp;
        return unless ($kind eq 'signal' ? _raw_signal($object) : _raw_node($object)) eq $raw;
    }
    for my $stamp (@{$walk->{holders}}) {
        my ($holder, $raw, $completed_source) = @$stamp;
        return unless _json()->encode($holder) eq $raw;
        if ($completed_source) {
            my $installed = $completed_source->{_source_literal_width_allocation};
            return unless ref($installed) eq 'HASH' && _json()->encode($installed) eq $raw;
        }
    }
    return 1;
}

sub _capture {
    my ($signal, $children) = @_;
    if (defined $children) {
        confess "Source literal children require explicit birth lookup or completed policy\n"
            unless ref($children) eq 'HASH' && defined($children->{phase}) && !ref($children->{phase})
                && (($children->{phase} eq 'birth' && join(',', sort keys %$children) eq 'lookup,phase'
                        && ref($children->{lookup}) eq 'CODE')
                    || ($children->{phase} eq 'completed' && join(',', sort keys %$children) eq 'phase'));
    }
    return _capture_signal($signal, {remaining => FSM::CoreExpressionWidthSupport::MAX_NODES(),
        active_nodes => {}, active_signals => {}, names => {}, children => $children}, 0);
}

sub _capture_signal {
    my ($signal, $shared, $depth) = @_;
    return unless blessed($signal) && $depth <= FSM::CoreExpressionWidthSupport::MAX_DEPTH();
    my $identity = refaddr($signal);
    return if $shared->{active_signals}{$identity};
    local $shared->{active_signals}{$identity} = 1;
    my $walk = {shared => $shared, signals => [], stamps => [], nodes => [], operands => [],
        holders => [], children => [], child_captures => [], reference_widths => {}, operators => 0, literals => 0};
    my $own = _observe_signal($signal, $walk) or return;
    return if exists($shared->{names}{$own->{name}}) && $shared->{names}{$own->{name}} ne $own->{identity_token};
    $shared->{names}{$own->{name}} = $own->{identity_token};
    my $roles = $own->{roles};
    return unless $own->{type} eq 'wire' && $roles->{is_intermediate}
        && !$roles->{is_output} && !$roles->{is_aux_output} && !$roles->{width_declared};
    my $role = $roles->{signal_role};
    return if defined($role) && (ref($role) || ($role ne 'intermediate' && $role ne 'INTERNAL_INTERMEDIATE'));
    return if grep {exists($signal->{$_})} qw(_declared_width_source _declared_width_binding _declared_width_requirements);
    my $tree = _core_tree($signal->driving_ast, $signal, $walk, $depth) or return;
    return unless $walk->{operators} && $walk->{literals};
    my %inference = %{$walk->{reference_widths}} ? (source_reference_width => sub {
        my ($reference) = @_;
        my $key = refaddr($reference);
        return exists($walk->{reference_widths}{$key}) ? {width => $walk->{reference_widths}{$key}} : undef;
    }) : ();
    my $width = FSM::CoreExpressionWidthSupport->infer_width($signal->driving_ast, %inference);
    my $expected = defined($width) ? $width : 1;
    return unless FSM::IntermediateWidthAllocationSupport::_width($signal->width)
        eq FSM::IntermediateWidthAllocationSupport::_width($expected);
    return unless _unchanged($walk);
    my $record = {kind => 'source_literal_operand_max', selected_width => $width, expression_tree => $tree};
    return {record => $record, objects => $walk->{signals}, walk => $walk, state => _json()->encode({signal => $own,
        nodes => $walk->{nodes}, operands => $walk->{operands}, record => $record,
        (@{$walk->{children}} ? (children => $walk->{children}) : ()),
        stamps => [map {[_identity($_->[0]), $_->[1], $_->[2]]} @{$walk->{stamps}}]})};
}

sub _tracked {
    my ($capture) = @_;
    return !grep {!exists($_->{_intermediate_width_allocation_revision})} @{$capture->{objects}};
}

sub _matches {
    my ($record, $capture) = @_;
    return unless _json()->encode($record->{expression_tree}) eq _json()->encode($capture->{record}{expression_tree});
    my ($supplied, $actual) = ($record->{selected_width}, $capture->{record}{selected_width});
    return !defined($supplied) && !defined($actual) unless defined($supplied) && defined($actual);
    return FSM::IntermediateWidthAllocationSupport::_width($supplied)
        eq FSM::IntermediateWidthAllocationSupport::_width($actual);
}

sub prepare_core {
    my ($class, %args) = @_;
    my $record = $class->copy_record($args{record});
    my $capture = eval {_capture($args{signal}, $args{children})};
    confess "Source literal allocation requires the actual current plain Core literal shape\n"
        unless $capture && _matches($record, $capture);
    if ($args{track}) {
        $_->_track_intermediate_width_allocation for @{$capture->{objects}};
    }
    my $after = eval {_capture($args{signal}, $args{children})};
    confess "Source literal allocation requires unchanged tracked source state\n"
        unless $after && _tracked($after) && $capture->{state} eq $after->{state};
    return {record => $record, state => $after->{state}};
}

sub current_core {
    my ($class, %args) = @_;
    my $holder = $args{holder};
    return unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state'
        && defined($holder->{state}) && !ref($holder->{state});
    my $record = eval {
        my $capture = _capture($args{signal}, $args{children}) or return;
        return unless _tracked($capture) && $capture->{state} eq $holder->{state};
        my $copy = $class->copy_record($holder->{record});
        return unless _matches($copy, $capture);
        my $after = _capture($args{signal}, $args{children}) or return;
        return unless _tracked($after) && $after->{state} eq $capture->{state} && _matches($copy, $after);
        $copy;
    };
    return $@ ? undef : $record;
}

# Convert only the phase and child digests of an authenticated birth capture.
# Installed completed children must subsequently match this exact projection;
# a newly current child with equal source or width cannot substitute for it.
sub _completed_capsule {
    my ($capsule, $capture) = @_;
    my $completed = _json()->decode(_json()->encode($capsule));
    my $state = _json()->decode($completed->{state});
    my $edges = $state->{children} // [];
    my $proofs = $capture->{walk}{child_captures};
    return unless @$edges == @$proofs;
    for my $index (0 .. $#$edges) {
        return unless $edges->[$index]{phase} eq 'birth';
        my $child = _completed_capsule($proofs->[$index]{capsule}, $proofs->[$index]{capture}) or return;
        $edges->[$index]{phase} = 'completed';
        $edges->[$index]{holder_digest} = _capsule_digest(_json()->encode($child));
    }
    $completed->{state} = _json()->encode($state);
    return $completed;
}

sub complete_core {
    my ($class, %args) = @_;
    my $completed = eval {
        my $children = $args{children};
        return if defined($children) && (ref($children) ne 'HASH' || ($children->{phase} // '') ne 'birth');
        my $holder = $args{holder};
        my $record = $class->current_core(%args) or return;
        my $raw = _json()->encode($holder);
        my $birth = _capture($args{signal}, $children) or return;
        return unless _tracked($birth) && _matches($record, $birth) && $birth->{state} eq $holder->{state};
        my $expected = _completed_capsule($holder, $birth) or return;
        my $current = _capture($args{signal}, {phase => 'completed'}) or return;
        return unless _tracked($current) && _matches($record, $current)
            && $current->{state} eq $expected->{state} && _json()->encode($holder) eq $raw;
        $expected;
    };
    return $@ ? undef : $completed;
}

# Project only the operation the source producer actually performed. Every
# other byte, including independent declarations, remains in the state compare.
sub _advance_raw_signal {
    my ($text, $transition, $revision) = @_;
    my $raw = _json()->decode($text);
    return unless $raw->{revision} eq $revision;
    ++$raw->{revision};
    if ($transition->{kind} eq 'role') {
        $raw->{roles}{$transition->{attribute}} = $transition->{value};
    } elsif ($transition->{kind} eq 'requirements') {
        return unless ref($transition->{record}) eq 'HASH';
        $raw->{fields}{_declared_width_requirements} = $transition->{record};
        $raw->{fields}{_declared_width_requirements_state} = _json()->encode([
            @{$raw->{fields}}{qw(_width _declared_width_source declared_type_name declared_type_spec)}]);
    } elsif ($transition->{kind} eq 'binding') {
        return unless ref($transition->{record}) eq 'HASH';
        $raw->{fields}{_declared_width_binding} = $transition->{record};
    } else {
        return;
    }
    return _json()->encode($raw);
}

sub copy_transition {
    my ($class, $transition) = @_;
    confess "Source literal transition requires a named role or width metadata operation\n"
        unless ref($transition) eq 'HASH' && defined($transition->{kind}) && !ref($transition->{kind})
            && (($transition->{kind} eq 'role'
                && join(',', sort keys %$transition) eq 'attribute,kind,value'
                && defined($transition->{attribute}) && !ref($transition->{attribute})
                && $transition->{attribute} =~ /\A(?:is_output|signal_role)\z/
                && (!ref($transition->{value}) || JSON::PP::is_bool($transition->{value})))
                || ($transition->{kind} =~ /\A(?:requirements|binding)\z/
                    && join(',', sort keys %$transition) eq 'kind,record'));
    return _json()->decode(_json()->encode($transition));
}

# Reconstruct an old child capsule using only the declared source delta. The
# parent's original digest then authenticates every other byte, including the
# child record's scalar kinds. All recursion follows the already bounded,
# current capture; it performs no source getters or child lookups.
sub _previous_child_capsule {
    my ($proof, $before, $after) = @_;
    my $capsule = _json()->decode(_json()->encode($proof->{capsule}));
    my $state = _json()->decode($capsule->{state});
    for my $descriptor ($state->{signal}, @{$state->{operands}}) {
        next unless $descriptor->{identity_token} eq $before->{identity_token};
        return unless _json()->encode($descriptor) eq _json()->encode($after);
        %$descriptor = %{_json()->decode(_json()->encode($before))};
    }
    for my $stamp (@{$state->{stamps}}) {
        next unless $stamp->[0] eq $before->{identity_token} && $stamp->[2] eq 'signal';
        return unless $stamp->[1] eq $after->{raw_state};
        $stamp->[1] = $before->{raw_state};
    }
    my $edges = $state->{children} // [];
    my $children = $proof->{capture}{walk}{child_captures};
    return unless @$edges == @$children;
    for my $index (0 .. $#$edges) {
        my $previous = _previous_child_capsule($children->[$index], $before, $after) or return;
        $edges->[$index]{holder_digest} = _capsule_digest(_json()->encode($previous));
    }
    $capsule->{state} = _json()->encode($state);
    return $capsule;
}

sub _advance_child_edges {
    my ($state, $capture, $before, $after) = @_;
    my $edges = $state->{children} // [];
    my $proofs = $capture->{walk}{child_captures};
    my $current = $capture->{walk}{children};
    return unless @$edges == @$proofs && @$edges == @$current;
    for my $index (0 .. $#$edges) {
        my $previous = _previous_child_capsule($proofs->[$index], $before, $after) or return;
        my $old_digest = _capsule_digest(_json()->encode($previous));
        my %original = (%{$current->[$index]}, holder_digest => $old_digest);
        return unless _json()->encode($edges->[$index]) eq _json()->encode(\%original);
        $edges->[$index]{holder_digest} = $current->[$index]{holder_digest};
    }
    return 1;
}

sub advance_core {
    my ($class, %args) = @_;
    my $advanced = eval {
        my $transition = $class->copy_transition($args{transition});
        my $holder = $args{holder};
        return unless ref($holder) eq 'HASH' && join(',', sort keys %$holder) eq 'record,state';
        my $record = $class->copy_record($holder->{record});
        my $state = _json()->decode($holder->{state});
        my $changed = $args{changed_signal};
        return unless blessed($changed) && $changed->isa('FSM::CoreAST::Signal');
        my $identity = _identity($changed);
        my $revision = $args{revision};
        return unless defined($revision) && !ref($revision) && $revision =~ /\A[0-9]+\z/
            && $changed->_intermediate_width_allocation_revision == $revision + 1;
        my ($before, $after);
        my $matches = 0;
        for my $descriptor ($state->{signal}, @{$state->{operands}}) {
            next unless $descriptor->{identity_token} eq $identity;
            return unless $descriptor->{revision} eq $revision;
            if ($before) {
                return unless _json()->encode($descriptor) eq _json()->encode($before);
            } else {
                $before = _json()->decode(_json()->encode($descriptor));
            }
            ++$descriptor->{revision};
            $descriptor->{roles}{$transition->{attribute}} = $transition->{value} if $transition->{kind} eq 'role';
            $descriptor->{raw_state} = _advance_raw_signal($descriptor->{raw_state}, $transition, $revision);
            return unless defined $descriptor->{raw_state};
            $after = $descriptor;
            ++$matches;
        }
        return unless $matches;
        for my $stamp (@{$state->{stamps}}) {
            next unless $stamp->[0] eq $identity && $stamp->[2] eq 'signal';
            $stamp->[1] = _advance_raw_signal($stamp->[1], $transition, $revision);
            return unless defined $stamp->[1];
        }
        my $capture = _capture($args{signal}, $args{children}) or return;
        return unless _advance_child_edges($state, $capture, $before, $after);
        return unless _tracked($capture) && _matches($record, $capture)
            && $capture->{state} eq _json()->encode($state);
        {record => $record, state => $capture->{state}};
    };
    return $@ ? undef : $advanced;
}

1;

=head1 NAME

FSM::SourceLiteralWidthAllocationSupport - Current raw source literal allocation holders

=head1 METHODS

=head2 copy_record

Validate and detach C<{kind =E<gt> source_literal_operand_max, selected_width,
expression_tree}>. Exact C<selected_width> may be undef; it is distinct from a
Core Signal's nominal scalar compatibility width. Tree nodes are canonical
binary bitwise C<&>, C<|>, C<^>, C<[signal, name]> or
C<[literal, {value, width, radix}]>. Literal data retains supplied JSON kinds.
An explicit literal size is independent; this holder assigns no backend default.
Closed schema, cycle, depth and occurrence validation precede serialization.

=head2 prepare_core

Validate producer-supplied intent against the actual current plain unsigned
wire intermediate, bitwise tree and literal data. At least one literal and one
operator are required. Whole leaf Signals must be plain unsigned independent
Signals; by default generated child references, slices and other expression
families withhold. Result declarations, constraints, named/signed types and conflicting
roles withhold. Nullable exact width comes from the shared Core width walk;
unknown results must still have their nominal compatibility width. Explicit
sizes must agree with the actual exact operand maximum.

C<track =E<gt> 1> opts validated result and source Signals into the existing
revocation counters. Complete validation precedes tracking, followed by an
unchanged-state check. Returned C<{record, state}> is detached plain JSON;
lifetime tokens use the existing weak identity table and retain no owners.
This validator does not attest source birth, publish a policy, change source
inference, or admit a target profile. The actual builder journals births and
completed Parser/facade transactions publish through the Core Signal lifecycle.
The builder uses nested birth captures at actual source allocation and converts
them at completed Parser/facade publication. Target consumers remain separate.

The optional C<children> argument explicitly opts into a prepared nested holder
boundary. C<< {phase => 'birth', lookup => sub { ... }} >> calls the lookup with
each actual whole Core SignalRef to a generated child. It must return that
child's current detached C<{record, state}> holder, not merely a record or a
numerically matching width. This supplied holder establishes current local
ownership, not fresh allocator provenance; the capture owner must attest birth.
C<< {phase => 'completed'} >> instead requires the actual installed child
C<_source_literal_width_allocation> holder and allows no lookup callback.
Provisional births cannot substitute for completed policy. Every generated
child in the expansion must have a current literal holder under that same
phase. Missing, malformed, foreign, independently constrained or stale child
proof withholds. Lookup exceptions refuse preparation; failed preparation
publishes nothing.

Each child's exact nullable width is resolved through the shared Core walk's
explicit source-reference boundary. An unknown child remains unknown even
beside an independently declared wider leaf; no nominal selected width or
backend default supplies the missing source proof. Original independent leaf
declarations and literal sizes remain unchanged. The detached expression tree
expands original raw source syntax; separate ordered edge identities and child
capsule digests bind actual typed references and child lifetimes. Repeated or
shared references retain every occurrence without becoming cycles.
Digests use strict UTF-8 bytes of canonical JSON. Raw Unicode scalar data
preserves without character-to-byte exceptions or lossy replacement; invalid
encoding withholds. This is Core data preservation, not literal interpretation.

One shared depth/occurrence budget and active AST/Signal path covers the complete
helper expansion, including reference crossings. It never resets at a child.
Final raw barriers cover all descendant Signals, AST slots and supplied child
capsules, plus continued installed-policy membership in completed mode. Only
temporary call-local state contains owners or callbacks; returned holders are
plain detached JSON. Default direct captures preserve their prior behavior.

=head2 current_core

Return a detached record only while actual identities, raw literal kinds,
explicit widths, selected state, roles, source metadata, AST slots and tracked
revisions agree. Supported matching-state writes revoke. Foreign capsules,
later object lifetimes and unknown shapes withhold. A raw complete-capture
barrier checks earlier objects after all potentially mutating getters. Ordinary
absent lookup creates no fields. Failed preparation installs nothing; the
Core Signal owner revokes any previous installation before explicit replacement.
Opted-in nested captures require the same explicit C<children> phase/lookup
contract at revalidation. Birth and completed relationships cannot impersonate
each other. Completed policy removal and late child-lookup/source writes
withhold. This method does not publish nested Core policy.

=head2 copy_transition

Detach the closed internal named operation: C<role> with C<attribute> and
C<value>, or C<requirements>/C<binding> with C<record>. The actual source
producer snapshots this before its write; failed copying does not suppress the
write or preserve previous intent. This validates data, not operation execution.

=head2 advance_core

After the source producer validated a current holder and performed exactly one
named write, compare the complete current capture against that holder with only
the expected revision and role or width-metadata delta projected. Every repeated
source slot must agree. Metadata projection includes the exact supplied record
and the existing requirement-state serialization; independent source fields,
raw literals and AST identities cannot change. The result is a refreshed detached
holder, or undef. Arbitrary, extra, failed, foreign or stale writes cannot refresh
through this operation. The caller separately proves actual registry membership
before and after its write. This transports intent, never publishes Core policy.

With the explicit C<children> phase/lookup contract, named transport also
qualifies every ordered nested child edge. Each current child's complete
capsule is reconstructed at the prior source epoch by reversing only that
declared revision/role/metadata delta through the already bounded capture.
The parent's original child-capsule digest must match that complete prior
capsule before its edge may advance. The final complete projected parent
capture must also agree. Merely supplying a current refreshed child is
insufficient: unrelated child record kinds, raw source data, typed identities,
independent declarations and phase changes cannot cross an original edge.
Reconstruction uses only detached snapshots and performs no further getters,
lookups or source writes. Current capture barriers still fence late writes.

The caller must first validate current holders and actual registry membership,
perform the named operation, then refresh affected child holders before their
parents. Unaffected child holders remain current. Completed mode requires
actual refreshed installed child policy; birth lookup cannot impersonate it.
Escaped old parent/child capsules remain stale. The source builder uses this
transport for actual nested births before completed publication.

=head2 complete_core

Return a detached completed capsule only when a current birth capsule projects
exactly to the actual installed completed child relationships. Supply the same
explicit birth C<children> lookup used to validate the original capsule; no
children option is needed for direct holders. A completed-phase lookup cannot
substitute for the original birth. Invalid, stale or changed input returns undef.

The complete bounded birth capture authenticates original source epochs, raw
state and ordered child capsules. A pure projection replaces only each edge's
phase and digest using its recursively projected original child capsule. A fresh
completed capture must equal that entire projection, including actual installed
child holders. Equal widths or source text, independently current replacement
children, changed record JSON kinds and missing completed policy cannot establish
this join. Raw source and installed-holder barriers fence late getter writes.
Original birth capsules, source data, revisions and caller kinds do not change.

This method installs nothing and does not retain source owners or callbacks.
The source publisher installs children before parents after normal validation,
with a final raw registry-membership guard. Parser/facade failure cleanup revokes
partial publication. Target literal floors and declaration agreement remain
separate contracts.

Focused executable controls:

  scripts/run_with_ram_guard.sh -- prove -Iperl t/2251-source-literal-width-holder.t
  scripts/run_with_ram_guard.sh -- prove -Iperl t/2256-source-nested-literal-holder.t
  scripts/run_with_ram_guard.sh -- prove -Iperl t/2257-source-nested-literal-transitions.t

=cut
