package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport - Own direct consolidated intermediate metadata normalization

=head1 DESCRIPTION

Owns the bounded normalization family for the older direct generated-module
SystemVerilog consolidated intermediate path. This package centralizes:

=over 4

=item *

runtime AST normalization over the consolidated signal set

=item *

width normalization over the consolidated signal set

=item *

dependency normalization over the consolidated signal set

=item *

rendered-expression normalization over the consolidated signal set

=item *

live-usage evidence normalization over the consolidated signal set

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport>
now keeps trace plus merged-signal collection, while this package owns the
normalized metadata pass consumed by downstream selection, planning, and
emission stages.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

=head2 new

Construct one consolidated-intermediate normalization owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateNormalizationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 normalize_consolidated_intermediate_metadata

Normalize runtime ASTs, widths, dependencies, rendered expressions, and
live-usage metadata across the consolidated signal set so downstream phases can
consume one AST-first cache.

=cut

sub normalize_consolidated_intermediate_metadata ($self, $all_intermediate_signals) {
    my $ctx = $self->{flattened_dt};
    my $recovery_support = $ctx->{backend_sv_intermediate_recovery_support};
    my $width_support = $ctx->{backend_sv_intermediate_width_support};

    for my $signal_name (keys %{$all_intermediate_signals || {}}) {
        my $signal_info = $all_intermediate_signals->{$signal_name};
        my $runtime_ast = $recovery_support->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
        if ($runtime_ast && blessed($runtime_ast)) {
            fsm_debug("CONSOL_INTER_SIG: [RUNTIME_AST] '$signal_name' normalized via " . ($signal_info->{runtime_ast_source} || 'runtime_ast'), 3);
        } else {
            fsm_debug("CONSOL_INTER_SIG: [RUNTIME_AST] '$signal_name' still lacks AST; compatibility fallback remains", 3);
        }
    }

    for my $signal_name (keys %{$all_intermediate_signals || {}}) {
        my $signal_info = $all_intermediate_signals->{$signal_name};
        my $resolved_width = $width_support->resolve_intermediate_signal_width($signal_name, $signal_info, $all_intermediate_signals);
        $signal_info->{width} = $resolved_width;
        fsm_debug("CONSOL_INTER_SIG: [WIDTH] '$signal_name' width normalized to $resolved_width", 3);
    }

    for my $signal_name (keys %{$all_intermediate_signals || {}}) {
        my $signal_info = $all_intermediate_signals->{$signal_name};
        my @dependencies = $recovery_support->resolve_intermediate_signal_dependencies($signal_name, $signal_info);
        my $dependency_summary = @dependencies ? join(', ', @dependencies) : 'none';
        fsm_debug("CONSOL_INTER_SIG: [DEPENDENCIES] '$signal_name' => $dependency_summary via " . ($signal_info->{dependency_source} || 'none'), 3);
    }

    for my $signal_name (keys %{$all_intermediate_signals || {}}) {
        my $signal_info = $all_intermediate_signals->{$signal_name};
        my $rendered_expression = $recovery_support->render_intermediate_signal_expression($signal_name, $signal_info);
        my $render_source = $signal_info->{rendered_expression_source} || 'none';
        if (defined($rendered_expression) && $rendered_expression ne '') {
            fsm_debug("CONSOL_INTER_SIG: [RENDER] '$signal_name' cached via $render_source", 3);
        } else {
            fsm_debug("CONSOL_INTER_SIG: [RENDER] '$signal_name' has no cached renderable expression", 3);
        }
    }

    $ctx->{enable_graph_factorization_support}
        ->prime_intermediate_signal_live_usage($all_intermediate_signals);

    for my $signal_name (keys %{$all_intermediate_signals || {}}) {
        my $signal_info = $all_intermediate_signals->{$signal_name};
        my $live_usage = $ctx->{enable_graph_factorization_support}->resolve_intermediate_signal_live_usage($signal_name, $signal_info);
        my $usage_summary = $live_usage->{evidence_state} || 'none';
        fsm_debug("CONSOL_INTER_SIG: [LIVE_USAGE] '$signal_name' => $usage_summary via " . ($live_usage->{source} || 'ast_live_usage_metadata'), 3);
    }
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate normalization owner bound to a
specific C<FSM::HDL::FlattenedDT> backend context.

=head2 normalize_consolidated_intermediate_metadata

Normalizes runtime ASTs, widths, dependencies, rendered expressions, and
live-usage metadata across the consolidated signal set so downstream phases can
consume one AST-first cache.

=cut
