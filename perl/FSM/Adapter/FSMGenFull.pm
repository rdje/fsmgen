package FSM::Adapter::FSMGenFull;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use FSM::Debug;

use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::Adapter::FSMGenFull::Parser;
use FSM::Adapter::FSMGenFull::SignalAnalyzer;

# Full FSMGen Adapter - Facade pattern implementation
sub new($class, %args) {
    fsm_trace_enter('Initialize FSMGenFull adapter facade', 2);
    my $debug = $args{debug} // 0;
    
    my $signal_manager = $args{signal_manager}
        // FSM::Adapter::FSMGenFull::SignalManager->new(debug => $debug);
    
    my $expression_builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(
        debug => $debug,
        signal_manager => $signal_manager
    );
    
    my $parser = FSM::Adapter::FSMGenFull::Parser->new(
        debug => $debug,
        signal_manager => $signal_manager,
        expression_builder => $expression_builder
    );
    
    my $signal_analyzer = FSM::Adapter::FSMGenFull::SignalAnalyzer->new(
        debug => $debug,
        signal_manager => $signal_manager
    );
    
    my $self = bless {
        debug => $debug,
        signal_manager => $signal_manager,
        expression_builder => $expression_builder,
        parser => $parser,
        signal_analyzer => $signal_analyzer,
    }, $class;
    fsm_trace_exit('FSMGenFull adapter facade initialized', 2);
    return $self;
}

# Main entry point - parse FSM from Lispish output
sub parse_fsm($self, $raw_ast) {
    fsm_trace_enter('FSMGenFull facade parse_fsm()', 2);
    fsm_debug("Starting full FSMGen parsing", 3);
    
    # Phase 1: Parse the AST and build the CoreAST structures
    my $fsm_module = $self->{parser}->parse_fsm($raw_ast);
    
    if (!$fsm_module) {
        fsm_trace_decision(0, 'Parser returned undefined FSM module', 1);
        Carp::confess "Failed to parse FSM module from AST";
    }
    
    # Phase 2: Analyze signal roles and attach interface
    $self->{signal_analyzer}->analyze_signal_roles($fsm_module);
    $self->{signal_analyzer}->generate_fsm_interface($fsm_module);
    
    fsm_trace_exit('FSMGenFull facade parse_fsm() completed', 2);
    return $fsm_module;
}

# Analysis and debugging methods
sub debug_summary($self) {
    fsm_trace_enter('FSMGenFull debug summary', 4);
    return unless debug_enabled();
    
    my $fsm_module = $self->{parser}->get_fsm_module();
    my $signal_registry = $self->{signal_manager}->{signal_registry};
    
    my $signal_count = scalar(keys %$signal_registry);
    my $state_count = $fsm_module ? scalar(@{$fsm_module->states}) : 0;
    
    fsm_debug("=== FSM Adapter Summary ===", 3);
    fsm_debug("Signals discovered: $signal_count", 3);
    fsm_debug("States/DTs parsed: $state_count", 3);
    
    if ($signal_count > 0 && debug_enabled()) {
        fsm_debug("", 3);
        fsm_debug("Signal Registry:", 3);
        my $summary = $self->{signal_manager}->get_signal_summary();
        for my $name (sort keys %$summary) {
            my $info = $summary->{$name};
            my $width = $info->{width} ? "[$info->{width}]" : "";
            my $output = $info->{is_output} ? " (output)" : "";
            fsm_debug("  $name$width$output", 3);
        }
    }
    fsm_trace_exit('FSMGenFull debug summary complete', 4);
}

1;

__END__

=head1 NAME

FSM::Adapter::FSMGenFull - Complete FSMGen Lisp Format Adapter (Refactored)

=head1 DESCRIPTION

This module acts as a facade, providing comprehensive parsing of FSMGen Lisp format files by
coordinating several specialized sub-modules:
- `SignalManager`: manages the signal registry and symbols
- `ExpressionBuilder`: handles literals, recursive expressions, conditions, and width inference
- `Parser`: handles the extraction of the FSM graph from the Lisp S-Expressions
- `SignalAnalyzer`: tracks uses of variables to determine input/output/internal ports.

=head1 METHODS

=over 4

=item parse_fsm($raw_ast)

Main entry point for parsing FSMGen AST structures.

=item debug_summary()

Prints debugging summary of parsed FSM.

=back

=cut
