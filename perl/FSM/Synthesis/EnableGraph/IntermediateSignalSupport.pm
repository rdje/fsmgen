package FSM::Synthesis::EnableGraph::IntermediateSignalSupport;

=head1 NAME

FSM::Synthesis::EnableGraph::IntermediateSignalSupport - Own intermediate-signal registry and dependency-recovery support for EnableGraph

=head1 DESCRIPTION

This package owns the bounded intermediate-signal support family that used to
live inline inside C<FSM::Synthesis::EnableGraph>. It centralizes:

=over 4

=item *

intermediate-signal registry normalization

=item *

native AST lookup and compatibility-expression parsing

=item *

rendered-expression recovery for intermediate signals

=item *

signal-name-based dependency AST recovery

=item *

tracking of referenced intermediate signals that still need declarations

=back

The owning C<EnableGraph> still provides the broader synthesis and AST
analysis API. This package exists so the intermediate-signal support family
has one explicit owner instead of remaining mixed into that larger class.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Scalar::Util qw(blessed);

use FSM::AST::Node;
use FSM::Debug;

=head2 new

Construct an intermediate-signal support owner for one live
C<FSM::HDL::FlattenedDT> context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[IntermediateSignalSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 _get_intermediate_signal_registry_entry

Return the normalized registry entry for one intermediate signal, including the
legacy string-entry compatibility shape.

=cut

sub _get_intermediate_signal_registry_entry ($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';
    return undef unless exists $ctx->{intermediate_signals}->{$signal_name};

    my $entry = $ctx->{intermediate_signals}->{$signal_name};
    if (ref($entry) eq 'HASH') {
        $entry->{name} //= $signal_name;
        return $entry;
    }

    return {
        name => $signal_name,
        expression => $entry,
        source => 'legacy_string_registry',
    };
}

=head2 _register_intermediate_signal_registry_entry

Merge updates into the normalized registry entry for one intermediate signal.

=cut

sub _register_intermediate_signal_registry_entry ($self, $signal_name, %updates) {
    my $ctx = $self->{flattened_dt};
    my $existing = $self->_get_intermediate_signal_registry_entry($signal_name) || {};
    my %merged = (
        %$existing,
        %updates,
        name => $signal_name,
    );
    $ctx->{intermediate_signals}->{$signal_name} = \%merged;
    return $ctx->{intermediate_signals}->{$signal_name};
}

=head2 _get_native_intermediate_signal_ast

Resolve an intermediate signal back to its native defining AST when one exists
in the factorizer, normalized registry, or live FSM module signal metadata.

=cut

sub _get_native_intermediate_signal_ast ($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals}) {
        my $signal_info = $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name};
        if ($signal_info && $signal_info->{ast} && blessed($signal_info->{ast})) {
            fsm_debug("[IntermediateSignalSupport.pm][_get_native_intermediate_signal_ast()] Resolved '$signal_name' from AST factorizer", 3);
            return $signal_info->{ast};
        }
    }

    my $registry_entry = $self->_get_intermediate_signal_registry_entry($signal_name);
    if ($registry_entry && $registry_entry->{ast} && blessed($registry_entry->{ast})) {
        fsm_debug("[IntermediateSignalSupport.pm][_get_native_intermediate_signal_ast()] Resolved '$signal_name' from intermediate registry", 3);
        return $registry_entry->{ast};
    }

    if ($ctx->{fsm_module} && $ctx->{fsm_module}->can('signals') && $ctx->{fsm_module}->signals) {
        my $signal = $ctx->{fsm_module}->signals->{$signal_name};
        if ($signal && blessed($signal) && $signal->can('driving_ast')) {
            my $driving_ast = $signal->driving_ast;
            if ($driving_ast && blessed($driving_ast)) {
                fsm_debug("[IntermediateSignalSupport.pm][_get_native_intermediate_signal_ast()] Resolved '$signal_name' from FSM module driving_ast", 3);
                return $driving_ast;
            }
        }
    }

    return undef;
}

=head2 get_intermediate_signal_ast

Resolve an intermediate signal to the best defining AST available, preferring
native AST-backed sources and only then compatibility parsing.

=cut

sub get_intermediate_signal_ast ($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    my $native_ast = $self->_get_native_intermediate_signal_ast($signal_name);
    if ($native_ast && blessed($native_ast)) {
        return $native_ast;
    }

    my $registry_entry = $self->_get_intermediate_signal_registry_entry($signal_name);
    if ($registry_entry && defined($registry_entry->{expression}) && $registry_entry->{expression} ne '') {
        my $ast = $self->_parse_intermediate_expression_to_ast(
            $registry_entry->{expression},
            $signal_name,
            $registry_entry->{source} || 'intermediate_signals',
        );
        return $ast if $ast;
    }

    if ($ctx->{global_expressions}) {
        for my $expr (keys %{$ctx->{global_expressions}}) {
            next unless $ctx->{global_expressions}->{$expr} eq $signal_name;
            my $ast = $self->_parse_intermediate_expression_to_ast($expr, $signal_name, 'global_expressions');
            return $ast if $ast;
            last;
        }
    }

    fsm_debug("[IntermediateSignalSupport.pm][get_intermediate_signal_ast()] No defining AST found for '$signal_name'", 3);
    return undef;
}

=head2 _parse_intermediate_expression_to_ast

Parse one compatibility expression back to AST and cache the normalized
registry entry when parsing succeeds.

=cut

sub _parse_intermediate_expression_to_ast ($self, $expression, $signal_name, $source_name) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($expression) && $expression ne '';

    unless ($ctx->{expr_namer} && $ctx->{expr_namer}->can('parse_expression')) {
        fsm_debug("[IntermediateSignalSupport.pm][_parse_intermediate_expression_to_ast()] No expr_namer parser available for '$signal_name' from $source_name", 3);
        return undef;
    }

    my $ast = eval { $ctx->{expr_namer}->parse_expression($expression) };
    if ($ast && blessed($ast)) {
        $self->_register_intermediate_signal_registry_entry(
            $signal_name,
            ast => $ast,
            expression => $expression,
            source => $source_name,
        );
        fsm_debug("[IntermediateSignalSupport.pm][_parse_intermediate_expression_to_ast()] Parsed compatibility expression for '$signal_name' from $source_name", 3);
        return $ast;
    }

    my $error = $@;
    chomp $error if defined $error;
    fsm_debug("[IntermediateSignalSupport.pm][_parse_intermediate_expression_to_ast()] Failed to parse compatibility expression for '$signal_name' from $source_name: " . ($error || 'unknown parse failure'), 3);
    return undef;
}

=head2 get_intermediate_signal_expression

Return the best rendered expression for an intermediate signal, preferring a
defining AST and falling back to normalized registry data.

=cut

sub get_intermediate_signal_expression ($self, $signal_name) {
    my $ctx = $self->{flattened_dt};

    my $ast = $self->get_intermediate_signal_ast($signal_name);
    if ($ast && blessed($ast)) {
        my $expression = $ctx->{enable_graph}->ast_to_systemverilog($ast);
        fsm_debug("[IntermediateSignalSupport.pm][get_intermediate_signal_expression()] Rendering '$signal_name' from defining AST", 3);
        return $expression;
    }

    my $registry_entry = $self->_get_intermediate_signal_registry_entry($signal_name);
    if ($registry_entry && defined($registry_entry->{expression}) && $registry_entry->{expression} ne '') {
        return $registry_entry->{expression};
    }

    for my $expr (keys %{$ctx->{global_expressions}}) {
        if ($ctx->{global_expressions}->{$expr} eq $signal_name) {
            return $expr;
        }
    }

    fsm_debug("[IntermediateSignalSupport.pm][get_intermediate_signal_expression()] No AST-backed or registered expression found for '$signal_name'", 3);
    return undef;
}

=head2 _signal_name_supports_dependency_ast_recovery

Return true when one signal name is eligible for conservative signal-name-based
dependency AST recovery.

=cut

sub _signal_name_supports_dependency_ast_recovery ($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    return 0 unless defined($signal_name) && $signal_name ne '';

    if ($ctx->{ast_factorizer}
        && $ctx->{ast_factorizer}->{intermediate_signals}
        && exists $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name})
    {
        fsm_debug("[IntermediateSignalSupport.pm][_signal_name_supports_dependency_ast_recovery()] '$signal_name' is tracked by AST factorization", 3);
        return 1;
    }

    my $registry_entry = $self->_get_intermediate_signal_registry_entry($signal_name);
    if ($registry_entry) {
        my $source = $registry_entry->{source} || 'unknown';
        if ($source eq 'ast_signal_name' || $source eq 'global_expression') {
            fsm_debug("[IntermediateSignalSupport.pm][_signal_name_supports_dependency_ast_recovery()] '$signal_name' is AST-named via $source", 3);
            return 1;
        }
        if ($source eq 'legacy_string_registry') {
            fsm_debug("[IntermediateSignalSupport.pm][_signal_name_supports_dependency_ast_recovery()] '$signal_name' is a legacy registry signal eligible for conservative signal-name AST recovery", 3);
            return 1;
        }
    }

    fsm_debug("[IntermediateSignalSupport.pm][_signal_name_supports_dependency_ast_recovery()] '$signal_name' has no AST-name metadata for dependency recovery", 3);
    return 0;
}

=head2 _map_signal_name_operator_to_ast_symbol

Map one systematic signal-name operator token back to the corresponding AST
operator symbol.

=cut

sub _map_signal_name_operator_to_ast_symbol ($self, $operator_name) {
    my %operator_map = (
        and   => '&&',
        or    => '||',
        eq    => '==',
        ne    => '!=',
        lt    => '<',
        gt    => '>',
        le    => '<=',
        ge    => '>=',
        plus  => '+',
        minus => '-',
        mult  => '*',
        div   => '/',
    );

    return $operator_map{$operator_name};
}

=head2 _find_dependency_recovery_signal_name_split

Find the best dependency-oriented binary operator split for one systematic
signal name.

=cut

sub _find_dependency_recovery_signal_name_split ($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    return unless defined($signal_name) && $signal_name ne '';

    my @operator_names = qw(and or eq ne le ge lt gt plus minus mult div);
    my $best_candidate;

    for my $operator_name (@operator_names) {
        my $needle = '_' . $operator_name . '_';
        my $offset = -1;
        while (1) {
            $offset = index($signal_name, $needle, $offset + 1);
            last if $offset < 0;

            my $left_name = substr($signal_name, 0, $offset);
            my $right_name = substr($signal_name, $offset + length($needle));
            next if $left_name eq '' || $right_name eq '';

            my $left_is_intermediate = $ctx->{enable_graph}->is_intermediate_signal($left_name) ? 1 : 0;
            my $right_is_intermediate = $ctx->{enable_graph}->is_intermediate_signal($right_name) ? 1 : 0;
            my $score = $left_is_intermediate + $right_is_intermediate;
            next unless $score > 0;

            my $known_length = 0;
            $known_length += length($left_name) if $left_is_intermediate;
            $known_length += length($right_name) if $right_is_intermediate;

            my $candidate = {
                operator_name => $operator_name,
                left_name => $left_name,
                right_name => $right_name,
                score => $score,
                known_length => $known_length,
            };

            if (!$best_candidate
                || $candidate->{score} > $best_candidate->{score}
                || ($candidate->{score} == $best_candidate->{score}
                    && $candidate->{known_length} > $best_candidate->{known_length}))
            {
                $best_candidate = $candidate;
            }
        }
    }

    if ($best_candidate) {
        fsm_debug(
            "[IntermediateSignalSupport.pm][_find_dependency_recovery_signal_name_split()] '$signal_name' split as "
            . "$best_candidate->{left_name} _$best_candidate->{operator_name}_ $best_candidate->{right_name}",
            3,
        );
        return @{$best_candidate}{qw(operator_name left_name right_name)};
    }

    fsm_debug("[IntermediateSignalSupport.pm][_find_dependency_recovery_signal_name_split()] No dependency-oriented split found for '$signal_name'", 3);
    return;
}

=head2 _build_dependency_recovery_operand_ast

Build one dependency-recovery operand AST while preserving direct intermediate
dependencies as leaf signal references.

=cut

sub _build_dependency_recovery_operand_ast ($self, $signal_name, $seen_signal_names) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($ctx->{enable_graph}->is_intermediate_signal($signal_name)) {
        fsm_debug("[IntermediateSignalSupport.pm][_build_dependency_recovery_operand_ast()] Preserving direct intermediate dependency '$signal_name'", 3);
        return FSM::AST::SignalRef->new($signal_name);
    }

    my $nested_ast = $self->build_dependency_recovery_ast_from_signal_name($signal_name, $seen_signal_names, 0);
    if ($nested_ast && blessed($nested_ast)) {
        fsm_debug("[IntermediateSignalSupport.pm][_build_dependency_recovery_operand_ast()] Built nested dependency AST for '$signal_name'", 3);
        return $nested_ast;
    }

    fsm_debug("[IntermediateSignalSupport.pm][_build_dependency_recovery_operand_ast()] Treating '$signal_name' as opaque leaf during dependency recovery", 3);
    return FSM::AST::SignalRef->new($signal_name);
}

=head2 build_dependency_recovery_ast_from_signal_name

Recover a conservative dependency AST from one systematic intermediate signal
name when no stronger AST-backed source is available.

=cut

sub build_dependency_recovery_ast_from_signal_name ($self, $signal_name, $seen_signal_names = undef, $is_root = 1) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    $seen_signal_names //= {};
    if ($seen_signal_names->{$signal_name}++) {
        fsm_debug("[IntermediateSignalSupport.pm][build_dependency_recovery_ast_from_signal_name()] Skipping recursive signal-name recovery for '$signal_name'", 3);
        return undef;
    }

    if ($is_root && !$self->_signal_name_supports_dependency_ast_recovery($signal_name)) {
        delete $seen_signal_names->{$signal_name};
        return undef;
    }

    my $candidate_ast;
    if ($signal_name eq 'const_1') {
        $candidate_ast = FSM::AST::Literal->new("1'b1");
    } elsif ($signal_name eq 'const_0') {
        $candidate_ast = FSM::AST::Literal->new("1'b0");
    } elsif ($signal_name =~ /^not_(.+)$/) {
        my $operand_name = $1;
        my $operand_ast = $self->_build_dependency_recovery_operand_ast($operand_name, $seen_signal_names);
        if ($operand_ast && blessed($operand_ast)) {
            $candidate_ast = FSM::AST::UnaryOp->new('!', $operand_ast);
        }
    } else {
        my ($operator_name, $left_name, $right_name) = $self->_find_dependency_recovery_signal_name_split($signal_name);
        if (defined($operator_name) && defined($left_name) && defined($right_name)) {
            my $left_ast = $self->_build_dependency_recovery_operand_ast($left_name, $seen_signal_names);
            my $right_ast = $self->_build_dependency_recovery_operand_ast($right_name, $seen_signal_names);
            my $operator_symbol = $self->_map_signal_name_operator_to_ast_symbol($operator_name);
            if ($left_ast && blessed($left_ast)
                && $right_ast && blessed($right_ast)
                && defined($operator_symbol) && $operator_symbol ne '')
            {
                $candidate_ast = FSM::AST::BinaryOp->new($operator_symbol, $left_ast, $right_ast);
            }
        }
    }

    delete $seen_signal_names->{$signal_name};
    return undef unless $candidate_ast && blessed($candidate_ast);

    my @dependencies = $ctx->{enable_graph}->extract_intermediate_signals_from_ast($candidate_ast);
    unless (@dependencies) {
        fsm_debug("[IntermediateSignalSupport.pm][build_dependency_recovery_ast_from_signal_name()] '$signal_name' produced no direct intermediate dependencies", 3);
        return undef;
    }

    my $summary = join(', ', @dependencies);
    fsm_debug("[IntermediateSignalSupport.pm][build_dependency_recovery_ast_from_signal_name()] '$signal_name' recovered direct dependencies via signal-name AST: $summary", 3);
    return $candidate_ast;
}

=head2 track_ast_intermediate_signals

Traverse one AST and record every referenced intermediate signal that still
needs declaration metadata.

=cut

sub track_ast_intermediate_signals ($self, $ast) {
    my $ctx = $self->{flattened_dt};
    return unless $ast && blessed($ast);

    fsm_debug("TRACK_INTERMEDIATE: Traversing AST: " . ref($ast));

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name;

        if ($ast->can('name') && defined($ast->name)) {
            $signal_name = $ast->name;
        } elsif ($ast->can('signal_name') && defined($ast->signal_name)) {
            $signal_name = $ast->signal_name;
        } elsif ($ast->can('signal') && $ast->signal && $ast->signal->can('name')) {
            $signal_name = $ast->signal->name;
        } else {
            my $ast_str = eval { $ast->to_systemverilog() };
            if ($ast_str && $ast_str =~ /^([a-zA-Z_][a-zA-Z0-9_]*)$/) {
                $signal_name = $1;
                fsm_debug("TRACK_INTERMEDIATE: Extracted signal name from string: $signal_name", 3);
            } else {
                fsm_debug("TRACK_INTERMEDIATE: WARNING - Could not extract signal name from " . ref($ast)
                    . " (available methods: " . join(", ", grep { $ast->can($_) } qw(name signal_name signal to_systemverilog)) . ")");
                return;
            }
        }

        if ($ctx->{enable_graph}->is_intermediate_signal($signal_name)) {
            my $existing = $ctx->{referenced_intermediate_signals}->{$signal_name} || {};
            my $defining_ast = $existing->{defining_ast};
            if ((!$defining_ast || !blessed($defining_ast))) {
                $defining_ast = $self->_get_native_intermediate_signal_ast($signal_name);
            }

            $ctx->{referenced_intermediate_signals}->{$signal_name} = {
                %$existing,
                name => $signal_name,
                reference_ast => $ast,
                ($defining_ast && blessed($defining_ast) ? (defining_ast => $defining_ast) : ()),
                needs_declaration => 1,
            };
            if ($defining_ast && blessed($defining_ast)) {
                fsm_debug("TRACK_INTERMEDIATE: Found intermediate signal with native defining AST: $signal_name", 3);
            } else {
                fsm_debug("TRACK_INTERMEDIATE: Found intermediate signal without native defining AST yet: $signal_name", 3);
            }
        }
    } elsif ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        $self->track_ast_intermediate_signals($ast->left) if $ast->can('left');
        $self->track_ast_intermediate_signals($ast->right) if $ast->can('right');
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        $self->track_ast_intermediate_signals($ast->operand) if $ast->can('operand');
    }
}

1;
