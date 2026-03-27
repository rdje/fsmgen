package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ASTFactorizationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ASTFactorizationSupport - Own direct SystemVerilog AST factorization and substitution support

=head1 DESCRIPTION

Owns the remaining substituted-AST lookup and legacy direct intermediate-signal
rendering family for the older direct generated-module SystemVerilog backend.
The live first-pass AST-factorization pipeline now lives in
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GlobalFactorizationSupport>,
while this package keeps the smaller downstream lookup surface that other
direct-backend owners still consume after factorization has already run.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ASTFactorizationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

sub generate_intermediate_signals ($self, $fsm_module) {
    my $hdl = "";
    my $ctx = $self->{flattened_dt};

    fsm_debug("\n*** PHASE: GENERATE INTERMEDIATE SIGNALS (FULLY AST-BASED) ***", 3);

    # STEP 1: Run global AST factorization on all WEN/EN expressions
    my $intermediate_signals = $ctx->{backend_sv_global_factorization}->run_global_ast_factorization();

    # STEP 2: Generate SystemVerilog declarations and assignments
    if (%$intermediate_signals) {
        $hdl .= "  // Intermediate signals for complex expressions\n";

        # Sort for deterministic output
        for my $signal_name (sort keys %$intermediate_signals) {
            my $signal_info = $intermediate_signals->{$signal_name};
            my $ast = $signal_info->{ast};
            my $width = $signal_info->{width} || 1;
            my $usage_count = $signal_info->{usage_count};

            fsm_debug("  Generating intermediate signal: $signal_name (width=$width, usage=$usage_count)", 3);

            # Generate wire declaration
            if ($width > 1) {
                $hdl .= "  wire [" . ($width - 1) . ":0] $signal_name;\n";
            } else {
                $hdl .= "  wire $signal_name;\n";
            }

            # Generate assign statement from AST
            my $systemverilog_expr = $ast->to_systemverilog();
            $hdl .= "  assign $signal_name = $systemverilog_expr;\n";
        }
    } else {
        fsm_debug("  No intermediate signals needed", 3);
    }

    fsm_debug("*** END PHASE: GENERATE INTERMEDIATE SIGNALS ***\n", 3);

    return $hdl;
}

sub get_substituted_ast_for_signal ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    # Get the substituted AST for an intermediate signal from the factorizer results
    # This fixes the core issue where intermediate signal definitions use original ASTs
    # instead of substituted ASTs that reference other intermediate signals

    fsm_debug("GET_SUBSTITUTED_AST: Looking for substituted AST for signal '$signal_name'", 3);

    # CRITICAL FIX: Get the substituted AST directly from the factorizer's intermediate signals
    # After substitution, the factorizer stores the final substituted AST in its intermediate_signals structure
    if ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals}) {
        my $factorizer_signal_info = $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name};

        if ($factorizer_signal_info && $factorizer_signal_info->{ast}) {
            my $substituted_ast = $factorizer_signal_info->{ast};
            my $substituted_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

            fsm_debug("  FOUND substituted AST from factorizer: '$substituted_sv'", 3);
            return $substituted_ast;
        } else {
            fsm_debug("  Signal '$signal_name' not found in factorizer intermediate signals", 3);
        }
    } else {
        fsm_debug("  WARNING: No AST factorizer results available", 3);
    }

    # If no substituted version found, return nil to indicate original should be used
    return undef;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one AST-factorization support owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_intermediate_signals

Renders the older direct intermediate-signal block from the AST-factorization
result set. This is retained as a bounded owner surface for the legacy direct
backend path even though the live flow now prefers the consolidated emitter.

=head2 get_substituted_ast_for_signal

Returns the substituted AST for one generated intermediate signal from the
stored factorizer results when available, or C<undef> when the original AST
should still be used.

=cut
