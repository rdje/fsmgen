package FSM::HDL::Factorization::Fixpoint::PassSupport;

=head1 NAME

FSM::HDL::Factorization::Fixpoint::PassSupport - Own per-pass helper support for iterative post-substitution factorization

=head1 DESCRIPTION

This package owns the bounded helper family around the iterative
post-substitution factorization loop. It centralizes:

=over 4

=item *

primary intermediate-signal lookup from the first-pass factorizer

=item *

deterministic expression-signature building for repeated-pass detection

=item *

per-pass intermediate-signal name collision recovery

=item *

selection and debug reporting for truly new second-pass signals

=back

The paired C<FSM::HDL::Factorization::Fixpoint> owner keeps pass scheduling and
top-level coordination, the paired
C<FSM::HDL::Factorization::Fixpoint::LoopStateSupport> owner keeps aggregate
loop-state and result normalization, and this package owns the per-pass
signal-processing helpers.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use Scalar::Util qw(blessed);
use FSM::Debug;

=head2 new

Construct one fixpoint pass-support owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[PassSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 resolve_primary_intermediate_signals

Return the live primary intermediate-signal map from the first-pass factorizer,
or an empty hashref when no primary factorizer was provided.

=cut

sub resolve_primary_intermediate_signals ($self, $primary_factorizer) {
    return {} unless $primary_factorizer;

    $primary_factorizer->{intermediate_signals} ||= {};
    return $primary_factorizer->{intermediate_signals};
}

=head2 build_expression_signature

Build a deterministic string signature for the current factorizer AST input so
the fixpoint loop can detect repeated pass inputs.

=cut

sub build_expression_signature ($self, $pass_factorizer) {
    my $ctx = $self->{flattened_dt};
    my @parts;

    for my $expr_info (@{$pass_factorizer->{ast_expressions} || []}) {
        my $context = $expr_info->{context} // 'unknown_context';
        my $sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($expr_info->{ast}) } || '[NO SV REPRESENTATION]';
        push @parts, "$context=$sv";
    }

    @parts = sort @parts;
    return join(' || ', @parts);
}

=head2 rename_colliding_pass_signals

Rename any newly generated second-pass signal whose name would collide with an
already accepted second-pass signal or one of the primary first-pass signals.
Returns the number of renames performed.

=cut

sub rename_colliding_pass_signals ($self, $pass_signals, $all_additional_signals, $primary_intermediate_signals, %args) {
    my $pass_number = $args{pass_number} // '?';
    my %reserved_names = map { $_ => 1 } (
        keys %{ $all_additional_signals || {} },
        keys %{ $primary_intermediate_signals || {} },
    );
    my $rename_count = 0;

    for my $signal_name (sort keys %{ $pass_signals || {} }) {
        next unless $reserved_names{$signal_name};

        my $base_name = $signal_name;
        my $counter = 1;
        my $unique_name = "${base_name}_${counter}";
        while ($reserved_names{$unique_name} || exists $pass_signals->{$unique_name}) {
            $counter++;
            $unique_name = "${base_name}_${counter}";
        }

        $pass_signals->{$unique_name} = delete $pass_signals->{$signal_name};
        $reserved_names{$unique_name} = 1;
        $rename_count++;

        fsm_debug("[PassSupport.pm][rename_colliding_pass_signals()] Pass $pass_number renamed colliding signal '$signal_name' -> '$unique_name'", 3);
    }

    return $rename_count;
}

=head2 select_new_unique_signals

Project the current pass output down to only the truly new second-pass signals,
excluding anything already accepted in a prior pass or already present in the
first-pass primary intermediate set.

=cut

sub select_new_unique_signals ($self, $pass_signals, $all_additional_signals, $primary_intermediate_signals) {
    my %new_unique_signals;

    for my $signal_name (sort keys %{ $pass_signals || {} }) {
        next if exists $all_additional_signals->{$signal_name};
        next if exists $primary_intermediate_signals->{$signal_name};
        $new_unique_signals{$signal_name} = _clone_pass_signal_value($pass_signals->{$signal_name});
    }

    return \%new_unique_signals;
}

sub _clone_pass_signal_value ($value) {
    return undef unless defined $value;
    return $value if blessed($value);

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone_pass_signal_value($value->{$_}) } sort keys %{$value}
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone_pass_signal_value($_) } @{$value} ];
    }

    return $value;
}

=head2 log_new_unique_signals

Emit the per-pass debug summary for each newly accepted second-pass signal.

=cut

sub log_new_unique_signals ($self, $new_unique_signals, %args) {
    my $ctx = $self->{flattened_dt};
    my $pass_number = $args{pass_number} // '?';

    for my $signal_name (sort keys %{ $new_unique_signals || {} }) {
        my $signal_info = $new_unique_signals->{$signal_name};
        my $expression_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($signal_info->{ast}) } || '[NO SV REPRESENTATION]';
        fsm_debug("[PassSupport.pm][log_new_unique_signals()] Pass $pass_number new signal $signal_name = $expression_sv (usage=$signal_info->{usage_count})", 3);
    }
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one fixpoint pass-support owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 resolve_primary_intermediate_signals

Returns the live primary intermediate-signal map from the first-pass
factorizer, or an empty hashref when no primary factorizer was provided.

=head2 build_expression_signature

Builds a deterministic string signature for the current factorizer AST input so
the fixpoint loop can detect repeated pass inputs.

=head2 rename_colliding_pass_signals

Renames any newly generated second-pass signal whose name would collide with an
already accepted second-pass signal or one of the primary first-pass signals.

=head2 select_new_unique_signals

Projects the current pass output down to only the truly new second-pass
signals.

=head2 log_new_unique_signals

Emits the per-pass debug summary for each newly accepted second-pass signal.

=cut
