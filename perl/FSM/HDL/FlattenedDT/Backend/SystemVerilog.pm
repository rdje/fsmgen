package FSM::HDL::FlattenedDT::Backend::SystemVerilog;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::HDL::Factorization::Fixpoint;
use Data::Dumper;
use Scalar::Util qw(blessed);
use List::Util qw(min);

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[FlattenedDT::Backend::SystemVerilog.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}
sub generate_header ($self, $fsm_module) {
    my $hdl = "";
    $hdl .= "//=============================================================================\n";
    $hdl .= "// Flattened Decision Tree FSM: " . $fsm_module->name . "\n";
    $hdl .= "// Generated using Enable-based Methodology with WEN/EN Signals\n";
    $hdl .= "// Date: " . localtime() . "\n";
    $hdl .= "// \n";
    $hdl .= "// This implementation uses:\n";
    $hdl .= "// - Flattened decision tree approach\n";
    $hdl .= "// - Enable-based logic with assign statements\n";
    $hdl .= "// - Write Enable (WEN) and Enable (EN) signals for each LHS\n";
    $hdl .= "// - Flat Boolean expressions from DT traversal\n";
    $hdl .= "//=============================================================================\n\n";
    return $hdl;
}

sub generate_module_declaration ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "module " . $fsm_module->name . " (\n";
    my @base_ports = (
        "  input  wire clk",
        "  input  wire rstn",
    );
    
    # Add all the signal ports based on the parsed FSM
    my $signals = $fsm_module->signals;
    my @inputs = ();
    my @outputs = ();
    
    fsm_debug("HDL Generation: Processing " . scalar(keys %$signals) . " signals for module declaration", 3);
    
    # Track seen signals to avoid duplicates
    my %seen_signals = ('clk' => 1, 'rstn' => 1);  # Base ports
    my %port_directions = ('clk' => 'input', 'rstn' => 'input');
    
    # Check which signals are driven (outputs) vs used (inputs)
    my %driven_signals = $ctx->{enable_graph}->get_driven_signals();
    
    for my $sig_name (sort keys %$signals) {
        # Skip duplicates
        if ($seen_signals{$sig_name}) {
            fsm_debug("HDL Signal Processing: SKIPPING duplicate signal '$sig_name'", 3);
            next;
        }
        $seen_signals{$sig_name} = 1;
        
        my $signal = $signals->{$sig_name};
        
        # Skip intermediate signals from interface - they should not be ports
        my $is_intermediate = 0;
        if ($signal->can('get_attribute')) {
            my $signal_role = $signal->get_attribute('signal_role');
            $is_intermediate = ($signal_role && $signal_role eq 'INTERNAL_INTERMEDIATE');
        } elsif ($signal->can('attributes') && $signal->attributes) {
            $is_intermediate = $signal->attributes->{is_intermediate} || 0;
        }
        
        if ($is_intermediate) {
            fsm_debug("HDL Signal Processing: SKIPPING intermediate signal '$sig_name' from interface", 3);
            next;
        }
        my $width_str = "";
        
        fsm_debug("HDL Signal Processing: $sig_name", 3);
        fsm_debug("  Signal object type: " . ref($signal), 3);
        fsm_debug("  Signal dump: " . Dumper($signal), 3);
        
        my $signal_width = 1;  # default
        if ($signal->can('width')) {
            $signal_width = $signal->width;
            # Handle case where width() returns 0 or undef - keep as 1-bit
            $signal_width = 1 unless ($signal_width && $signal_width > 0);
            fsm_debug("  Signal width from ->width(): $signal_width", 3);
        } else {
            fsm_debug("  Signal does not have width() method", 3);
        }
        
        if ($signal_width && $signal_width > 1) {
            $width_str = "[" . ($signal_width - 1) . ":0] ";
            fsm_debug("  Generated width string: '$width_str'", 3);
        } else {
            fsm_debug("  Using default 1-bit width", 3);
        }
        
        # Determine signal direction based on whether it's driven by our FSM
        my $is_output = 0;
        
        # First check if this signal is driven by the FSM logic
        if ($driven_signals{$sig_name}) {
            $is_output = 1;
            fsm_debug("  Signal '$sig_name' is DRIVEN by FSM -> OUTPUT", 3);
        } else {
            # Check explicit output attributes
            if ($signal->can('is_output')) {
                $is_output = $signal->is_output;
            } elsif ($signal->can('attributes') && $signal->attributes && $signal->attributes->{is_output}) {
                $is_output = $signal->attributes->{is_output};
            } elsif ($sig_name =~ />$/) {
                # Signals ending with > are outputs
                $is_output = 1;
            }
            
            fsm_debug("  Signal '$sig_name' direction: " . ($is_output ? "OUTPUT" : "INPUT"), 3);
        }
        
        if ($is_output) {
            push @outputs, "  output reg  ${width_str}${sig_name}";
            $port_directions{$sig_name} = 'output';
        } else {
            push @inputs, "  input  wire ${width_str}${sig_name}";
            $port_directions{$sig_name} = 'input';
        }
    }
    
    # Join all port declarations with proper ANSI-C SystemVerilog syntax
    my @all_ports = (@base_ports, @inputs, @outputs);
    for my $i (0 .. $#all_ports) {
        $hdl .= $all_ports[$i];
        if ($i < $#all_ports) {
            $hdl .= ",\n";  # Comma continuation for all but last port
        } else {
            $hdl .= "\n";   # No comma for last port
        }
    }
    $hdl .= ");\n\n";
    
    # Save port declarations for downstream internal declaration generation.
    $ctx->{declared_port_signals} = { %seen_signals };
    $ctx->{port_directions} = { %port_directions };
    
    return $hdl;
}
sub should_filter_consolidated_signal ($self, $expression, $signal_name, $signal_info) {
    # AST-BASED FILTERING - Use semantic analysis instead of string patterns
    # This replaces the old string-based regex filtering with proper AST analysis
    
    $expression = $self->render_intermediate_signal_expression($signal_name, $signal_info)
        unless defined($expression) && $expression ne '';
    fsm_debug("\n*** AST_FILTER_CHECK: Analyzing signal '$signal_name' ***", 3);
    fsm_debug("  Expression: '$expression'", 3);
    fsm_debug("  Source: $signal_info->{source}", 3);
    fsm_debug("  Usage count: " . ($signal_info->{usage_count} || 'unknown'));
    
    # Try to get the AST for this signal if available
    my $ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    if ($ast && blessed($ast)) {
        fsm_debug("  Using runtime AST for filtering: " . ref($ast), 3);
    } else {
        my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
            ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
            : 'unknown_runtime_ast_miss';
        fsm_debug("  No runtime AST available - falling back to explicit runtime-AST-miss filtering ($miss_reason)", 3);
    }
    
    # AST-based filtering when AST is available
    if ($ast && blessed($ast)) {
        return $self->should_filter_ast_based($ast, $signal_name, $signal_info);
    }
    
    # Fallback to explicit runtime-AST-miss filtering (legacy-named helper delegates here).
    return $self->should_filter_runtime_ast_miss($signal_name, $signal_info);
}
sub resolve_intermediate_signal_defining_ast ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($signal_info && $signal_info->{defining_ast} && blessed($signal_info->{defining_ast})) {
        fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_defining_ast()] Using cached defining_ast for '$signal_name'", 3);
        return $signal_info->{defining_ast};
    }

    if ($signal_info && $signal_info->{ast} && blessed($signal_info->{ast})) {
        fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_defining_ast()] Using inline AST for '$signal_name'", 3);
        return $signal_info->{ast};
    }

    my $resolved_ast = $ctx->{enable_graph}->get_intermediate_signal_ast($signal_name);
    if ($resolved_ast && blessed($resolved_ast)) {
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{defining_ast} //= $resolved_ast;
            $signal_info->{ast} //= $resolved_ast unless exists $signal_info->{ast};
        }
        fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_defining_ast()] Resolved defining AST for '$signal_name' via EnableGraph", 3);
        return $resolved_ast;
    }

    fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_defining_ast()] No defining AST available for '$signal_name'", 3);
    return undef;
}
sub resolve_intermediate_signal_runtime_ast ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($signal_info && $signal_info->{runtime_ast} && blessed($signal_info->{runtime_ast})) {
        $signal_info->{runtime_ast_resolution_state} = 'resolved' if ref($signal_info) eq 'HASH';
        fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_runtime_ast()] Using cached runtime_ast for '$signal_name'", 3);
        return $signal_info->{runtime_ast};
    }

    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && ($signal_info->{runtime_ast_resolution_state} || '') eq 'missing')
    {
        my $miss_reason = $signal_info->{runtime_ast_miss_reason} || 'unknown_miss_reason';
        fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_runtime_ast()] Reusing cached runtime-AST miss for '$signal_name' ($miss_reason)", 3);
        return undef;
    }

    my $runtime_ast;
    my $runtime_ast_source;
    my $runtime_ast_miss_reason = 'no_ast_source';

    if ($ctx->{ast_factorizer}
        && $ctx->{ast_factorizer}->{intermediate_signals}
        && exists $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name})
    {
        my $substituted_ast = $self->get_substituted_ast_for_signal($signal_name, $signal_info);
        if ($substituted_ast && blessed($substituted_ast)) {
            $runtime_ast = $substituted_ast;
            $runtime_ast_source = 'substituted_ast';
        }
    }

    if ((!$runtime_ast || !blessed($runtime_ast))) {
        my $defining_ast = $self->resolve_intermediate_signal_defining_ast($signal_name, $signal_info);
        if ($defining_ast && blessed($defining_ast)) {
            $runtime_ast = $defining_ast;
            $runtime_ast_source = 'defining_ast';
        }
    }

    if ((!$runtime_ast || !blessed($runtime_ast))
        && $signal_info
        && defined($signal_info->{expression})
        && $signal_info->{expression} ne ''
        && $ctx->{expr_namer})
    {
        $runtime_ast_miss_reason = 'expression_parse_failed';
        my $parsed_ast = eval { $ctx->{expr_namer}->parse_expression($signal_info->{expression}) };
        if ($parsed_ast && blessed($parsed_ast)) {
            $runtime_ast = $parsed_ast;
            $runtime_ast_source = 'parsed_expression_ast';
            if (ref($signal_info) eq 'HASH') {
                $signal_info->{defining_ast} //= $parsed_ast;
            }
        } else {
            my $error = $@;
            chomp $error if defined $error;
            fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_runtime_ast()] Failed compatibility parse for '$signal_name': " . ($error || 'unknown parse failure'), 3);
            $runtime_ast_miss_reason = 'expression_parse_failed';
        }
    }

    if ($runtime_ast && blessed($runtime_ast)) {
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{runtime_ast} = $runtime_ast;
            $signal_info->{runtime_ast_source} = $runtime_ast_source;
            $signal_info->{runtime_ast_resolution_state} = 'resolved';
            delete $signal_info->{runtime_ast_miss_reason};
        }
        fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_runtime_ast()] Resolved runtime AST for '$signal_name' via $runtime_ast_source", 3);
        return $runtime_ast;
    }
    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{runtime_ast_resolution_state} = 'missing';
        $signal_info->{runtime_ast_miss_reason} = $runtime_ast_miss_reason;
    }

    fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_runtime_ast()] No runtime AST available for '$signal_name'", 3);
    return undef;
}
sub render_intermediate_signal_expression ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';
    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && defined($signal_info->{rendered_expression})
        && $signal_info->{rendered_expression} ne '')
    {
        fsm_debug("[SystemVerilog.pm][render_intermediate_signal_expression()] Using cached rendered expression for '$signal_name' via " . ($signal_info->{rendered_expression_source} || 'cache'), 3);
        return $signal_info->{rendered_expression};
    }

    my $runtime_ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    if ($runtime_ast && blessed($runtime_ast)) {
        my $expression = $ctx->{enable_graph}->ast_to_systemverilog($runtime_ast);
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{rendered_expression} = $expression;
            $signal_info->{rendered_expression_source} = $signal_info->{runtime_ast_source} || 'runtime_ast';
        }
        fsm_debug("[SystemVerilog.pm][render_intermediate_signal_expression()] Rendered '$signal_name' from AST", 3);
        return $expression;
    }

    if ($signal_info && defined($signal_info->{expression}) && $signal_info->{expression} ne '') {
        if (ref($signal_info) eq 'HASH') {
            $signal_info->{rendered_expression} = $signal_info->{expression};
            $signal_info->{rendered_expression_source} = 'stored_expression';
        }
        fsm_debug("[SystemVerilog.pm][render_intermediate_signal_expression()] Falling back to stored expression for '$signal_name'", 3);
        return $signal_info->{expression};
    }

    my $expression = $ctx->{enable_graph}->get_intermediate_signal_expression($signal_name);
    if (defined($expression) && $expression ne '' && $signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{expression} //= $expression;
        $signal_info->{rendered_expression} = $expression;
        $signal_info->{rendered_expression_source} = 'enable_graph_expression';

        if (($signal_info->{runtime_ast_resolution_state} || '') eq 'missing'
            && ($signal_info->{runtime_ast_miss_reason} || '') eq 'no_ast_source')
        {
            delete $signal_info->{runtime_ast_resolution_state};
            delete $signal_info->{runtime_ast_miss_reason};
            my $recovered_runtime_ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
            if ($recovered_runtime_ast && blessed($recovered_runtime_ast)) {
                my $recovered_expression = $ctx->{enable_graph}->ast_to_systemverilog($recovered_runtime_ast);
                $signal_info->{rendered_expression} = $recovered_expression;
                $signal_info->{rendered_expression_source} = $signal_info->{runtime_ast_source} || 'runtime_ast_recovery';
                fsm_debug("[SystemVerilog.pm][render_intermediate_signal_expression()] Recovered runtime AST for '$signal_name' after late expression hydration", 3);
                return $recovered_expression;
            }
        }
    }
    return $expression;
}
sub resolve_intermediate_signal_dependencies ($self, $signal_name, $signal_info) {
    return () unless defined($signal_name) && $signal_name ne '';

    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && $signal_info->{dependency_signal_names}
        && ref($signal_info->{dependency_signal_names}) eq 'ARRAY')
    {
        return @{$signal_info->{dependency_signal_names}};
    }

    my @dependencies;
    my $dependency_source = 'none';

    my $expression = $self->render_intermediate_signal_expression($signal_name, $signal_info);
    my $runtime_ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    if ($runtime_ast && blessed($runtime_ast)) {
        @dependencies = $self->{flattened_dt}->{enable_graph}->extract_intermediate_signals_from_ast($runtime_ast);
        $dependency_source = $signal_info->{runtime_ast_source} || 'runtime_ast';
        delete $signal_info->{dependency_fallback_source} if $signal_info && ref($signal_info) eq 'HASH';
    } else {
        if (defined($expression) && $expression ne '') {
            @dependencies = $self->extract_intermediate_signals_from_runtime_ast_miss($signal_name, $signal_info, $expression);
            if ($signal_info
                && ref($signal_info) eq 'HASH'
                && $signal_info->{runtime_ast}
                && blessed($signal_info->{runtime_ast}))
            {
                $dependency_source = $signal_info->{runtime_ast_source} || 'runtime_ast_recovery';
                delete $signal_info->{dependency_fallback_source};
            } else {
                $dependency_source = ($signal_info && ref($signal_info) eq 'HASH')
                    ? ($signal_info->{dependency_fallback_source} || 'runtime_ast_miss_identifier_scan')
                    : 'runtime_ast_miss_identifier_scan';
            }
        }
    }

    my %seen_dependencies;
    @dependencies = grep { defined($_) && $_ ne '' && !$seen_dependencies{$_}++ } @dependencies;

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{dependency_signal_names} = [@dependencies];
        $signal_info->{dependency_source} = $dependency_source;
    }

    my $dependency_summary = @dependencies ? join(', ', @dependencies) : 'none';
    fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_dependencies()] '$signal_name' dependencies => $dependency_summary via $dependency_source", 3);
    return @dependencies;
}
sub extract_intermediate_signals_from_runtime_ast_miss ($self, $signal_name, $signal_info, $expression) {
    my $ctx = $self->{flattened_dt};
    return () unless defined($expression) && $expression ne '';

    my $debug_signal_name = defined($signal_name) && $signal_name ne ''
        ? $signal_name
        : '<compatibility_expression>';
    my $stored_expression = ($signal_info && ref($signal_info) eq 'HASH' && defined($signal_info->{expression}))
        ? $signal_info->{expression}
        : undef;
    my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
        ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
        : 'unknown_runtime_ast_miss';
    my %seen_candidate_expressions;
    my @candidate_expressions = ([ $expression, 'rendered_expression' ]);

    if (defined($signal_name) && $signal_name ne '') {
        my $enable_graph_expression = $ctx->{enable_graph}->get_intermediate_signal_expression($signal_name);
        if (defined($enable_graph_expression) && $enable_graph_expression ne '') {
            push @candidate_expressions, [ $enable_graph_expression, 'enable_graph_expression' ];
        }
    }

    for my $candidate_info (@candidate_expressions) {
        my ($candidate_expression, $candidate_source) = @$candidate_info;
        next unless defined($candidate_expression) && $candidate_expression ne '';
        next if $seen_candidate_expressions{$candidate_expression}++;

        my $is_known_failed_expression =
            $miss_reason eq 'expression_parse_failed'
            && defined($stored_expression)
            && $stored_expression ne ''
            && $candidate_expression eq $stored_expression;

        if ($is_known_failed_expression) {
            fsm_debug("[SystemVerilog.pm][extract_intermediate_signals_from_runtime_ast_miss()] Skipping redundant parse retry for '$debug_signal_name' via $candidate_source after known parse failure", 3);
            next;
        }

        next unless $ctx->{expr_namer};
        my $parsed_ast = eval { $ctx->{expr_namer}->parse_expression($candidate_expression) };
        if ($parsed_ast && blessed($parsed_ast)) {
            my $runtime_ast_source = $candidate_source eq 'enable_graph_expression'
                ? 'dependency_enable_graph_expression_ast'
                : 'dependency_rendered_expression_ast';
            if ($signal_info && ref($signal_info) eq 'HASH') {
                $signal_info->{runtime_ast} = $parsed_ast;
                $signal_info->{runtime_ast_source} = $runtime_ast_source;
                $signal_info->{runtime_ast_resolution_state} = 'resolved';
                delete $signal_info->{runtime_ast_miss_reason};
                $signal_info->{rendered_expression} = $candidate_expression;
                $signal_info->{rendered_expression_source} = $candidate_source;
                $signal_info->{expression} //= $candidate_expression;
                delete $signal_info->{dependency_fallback_source};
                if (defined($signal_name) && $signal_name ne '') {
                    my $resolved_width = $self->resolve_intermediate_signal_width($signal_name, $signal_info);
                    $signal_info->{width} = $resolved_width if defined($resolved_width) && $resolved_width > 0;
                }
            }
            fsm_debug("[SystemVerilog.pm][extract_intermediate_signals_from_runtime_ast_miss()] Recovered runtime AST for '$debug_signal_name' via $candidate_source", 3);
            return $ctx->{enable_graph}->extract_intermediate_signals_from_ast($parsed_ast);
        }

        my $error = $@;
        chomp $error if defined $error;
        fsm_debug("[SystemVerilog.pm][extract_intermediate_signals_from_runtime_ast_miss()] Failed compatibility parse for '$debug_signal_name' via $candidate_source: " . ($error || 'unknown parse failure'), 3);
    }

    my @dependencies = $self->scan_intermediate_signal_names_in_expression($expression);
    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{dependency_fallback_source} = 'runtime_ast_miss_identifier_scan';
    }
    return @dependencies;
}
sub resolve_intermediate_signal_width ($self, $signal_name, $signal_info, $signal_registry, $seen_signals = undef) {
    my $ctx = $self->{flattened_dt};
    return 1 unless defined($signal_name) && $signal_name ne '';

    $signal_registry //= {};
    $seen_signals //= {};
    if ($seen_signals->{$signal_name}++) {
        my $cached_width = ($signal_info && defined($signal_info->{width}) && $signal_info->{width} > 0)
            ? $signal_info->{width}
            : 1;
        fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_width()] Detected recursive width lookup for '$signal_name'; using cached width $cached_width", 3);
        return $cached_width;
    }

    my $resolved_width;
    my $width_source = 'default_1bit';

    my $native_signal_info = $ctx->{enable_graph}->get_signal_info($signal_name);
    if ($native_signal_info && $native_signal_info->{width} && $native_signal_info->{width} > 0) {
        $resolved_width = $native_signal_info->{width};
        $width_source = 'native_signal_metadata';
    }

    if ((!defined($resolved_width) || $resolved_width < 1) && $signal_info && defined($signal_info->{width}) && $signal_info->{width} > 1) {
        $resolved_width = $signal_info->{width};
        $width_source = 'cached_width';
    }

    if (!defined($resolved_width) || $resolved_width < 1) {
        my $runtime_ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
        if ($runtime_ast && blessed($runtime_ast)) {
            my $ast_width = $self->infer_width_from_intermediate_ast($runtime_ast, $signal_registry, $seen_signals);
            if (defined($ast_width) && $ast_width > 0) {
                $resolved_width = $ast_width;
                $width_source = $signal_info->{runtime_ast_source} || 'runtime_ast';
            }
        }
    }

    if ((!defined($resolved_width) || $resolved_width < 1) && $signal_info && defined($signal_info->{width}) && $signal_info->{width} > 0) {
        $resolved_width = $signal_info->{width};
        $width_source = 'cached_width';
    }

    $resolved_width = 1 unless defined($resolved_width) && $resolved_width > 0;
    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{width} = $resolved_width;
        $signal_info->{width_source} = $width_source;
    }

    fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_width()] Resolved width $resolved_width for '$signal_name' via $width_source", 3);
    return $resolved_width;
}
sub infer_width_from_intermediate_ast ($self, $ast, $signal_registry = undef, $seen_signals = undef) {
    my $ctx = $self->{flattened_dt};
    return undef unless $ast && blessed($ast);

    $signal_registry //= {};
    $seen_signals //= {};

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $referenced_signal_name = eval { $ast->signal_name } || $ast->{signal_name};
        if (defined($referenced_signal_name) && $referenced_signal_name ne '') {
            my $referenced_signal_info = $signal_registry->{$referenced_signal_name}
                || ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals}
                    ? $ctx->{ast_factorizer}->{intermediate_signals}->{$referenced_signal_name}
                    : undef);
            return $self->resolve_intermediate_signal_width($referenced_signal_name, $referenced_signal_info, $signal_registry, $seen_signals);
        }
        return 1;
    }

    if ($ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        my $operator = eval { $ast->operator } || $ast->{operator} || '';
        return 1 if $operator eq '!';
        my $operand = eval { $ast->operand } || $ast->{operand};
        my $operand_width = $self->infer_width_from_intermediate_ast($operand, $signal_registry, $seen_signals);
        return (defined($operand_width) && $operand_width > 0) ? $operand_width : 1;
    }

    if ($ast->isa('FSM::HDL::SubstitutedBinaryOp')) {
        my $operator = eval { $ast->operator } || $ast->{operator} || '';
        return 1 if $operator =~ /^(==|!=|<|>|<=|>=|&&|\|\|)$/;

        my $left = eval { $ast->left } || $ast->{left};
        my $right = eval { $ast->right } || $ast->{right};
        my $left_width = $self->infer_width_from_intermediate_ast($left, $signal_registry, $seen_signals);
        my $right_width = $self->infer_width_from_intermediate_ast($right, $signal_registry, $seen_signals);

        $left_width = 1 unless defined($left_width) && $left_width > 0;
        $right_width = 1 unless defined($right_width) && $right_width > 0;
        return $left_width > $right_width ? $left_width : $right_width;
    }

    my $width = eval { $ctx->{expr_namer}->infer_ast_width($ast) };
    return $width if defined($width) && $width > 0;

    return undef;
}
sub resolve_intermediate_signal_live_usage ($self, $signal_name, $signal_info) {
    return {
        referenced_in_substitutions => 0,
        used_in_final_expressions => 0,
        evidence_state => 'none',
        source => 'ast_live_usage_metadata',
    } unless defined($signal_name) && $signal_name ne '';

    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && exists $signal_info->{referenced_in_substitutions}
        && exists $signal_info->{used_in_final_expressions})
    {
        my $evidence_state = $signal_info->{live_usage_evidence_state} || 'none';
        return {
            referenced_in_substitutions => $signal_info->{referenced_in_substitutions} ? 1 : 0,
            used_in_final_expressions => $signal_info->{used_in_final_expressions} ? 1 : 0,
            evidence_state => $evidence_state,
            source => $signal_info->{live_usage_source} || 'ast_live_usage_metadata',
        };
    }

    my $referenced_in_substitutions = $self->is_signal_referenced_in_substitutions($signal_name) ? 1 : 0;
    my $used_in_final_expressions = $self->is_signal_actually_used_in_final_expressions($signal_name) ? 1 : 0;
    my $evidence_state = $referenced_in_substitutions
        ? ($used_in_final_expressions ? 'substitutions_and_final_expressions' : 'substitutions')
        : ($used_in_final_expressions ? 'final_expressions' : 'none');

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{referenced_in_substitutions} = $referenced_in_substitutions;
        $signal_info->{used_in_final_expressions} = $used_in_final_expressions;
        $signal_info->{live_usage_evidence_state} = $evidence_state;
        $signal_info->{live_usage_source} = 'ast_live_usage_metadata';
    }

    fsm_debug("[SystemVerilog.pm][resolve_intermediate_signal_live_usage()] '$signal_name' live usage => substitutions=$referenced_in_substitutions final_expressions=$used_in_final_expressions ($evidence_state)", 3);
    return {
        referenced_in_substitutions => $referenced_in_substitutions,
        used_in_final_expressions => $used_in_final_expressions,
        evidence_state => $evidence_state,
        source => 'ast_live_usage_metadata',
    };
}
sub should_filter_ast_based ($self, $ast, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    # Pure AST-based filtering using semantic analysis
    
    fsm_debug("  AST_FILTER: Using AST-based filtering for " . ref($ast));
    
    my $usage_count = $signal_info->{usage_count} || 0;
    my $live_usage = $self->resolve_intermediate_signal_live_usage($signal_name, $signal_info);
    my $actually_used = $live_usage->{used_in_final_expressions} ? 1 : 0;
    
    # REFERENCE-AWARE FILTERING: Check if signal is referenced in substituted expressions
    # This is the fix for the bug where intermediate signals are referenced but not declared
    my $referenced_in_substitutions = $live_usage->{referenced_in_substitutions} ? 1 : 0;

    if ($referenced_in_substitutions) {
        fsm_debug("  AST_FILTER: Signal '$signal_name' is referenced in AST substitutions - KEEPING", 3);
        return 0; # Keep signals that are already referenced in substituted expressions
    }
    
    # AST_FILTER 1: TEMPORARILY DISABLED - Filter if not actually used
    # The usage tracking is not working correctly after AST substitution
    # So we're temporarily disabling this aggressive filtering
    if (!$actually_used || $usage_count == 0) {
        fsm_debug("  AST_FILTER: Signal appears unused (usage_count=$usage_count, actually_used=$actually_used) - but KEEPING due to usage tracking issues", 3);
        # return 1;  # DISABLED - usage tracking is broken
    }
    
    # AST_FILTER 2: Filter simple literals
    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        fsm_debug("  AST_FILTER: Simple literal - FILTERING", 3);
        return 1;
    }
    
    # AST_FILTER 3: Filter bare signal references (signal = signal)
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        fsm_debug("  AST_FILTER: Bare signal reference - FILTERING", 3);
        return 1;
    }
    
    # AST_FILTER 4: Handle unary operations (like negation)
    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        # Check if it's a simple negation of a signal
        if ($self->is_simple_negation($ast)) {
            # Only factor if used multiple times
            if ($usage_count >= 2) {
                fsm_debug("  AST_FILTER: Simple negation used $usage_count times - KEEPING", 3);
                return 0;
            } else {
                fsm_debug("  AST_FILTER: Simple negation used only once - FILTERING", 3);
                return 1;
            }
        } else {
            # Complex unary operation - always keep
            fsm_debug("  AST_FILTER: Complex unary operation - KEEPING", 3);
            return 0;
        }
    }
    
    # AST_FILTER 5: Handle binary operations
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Check if it's a simple comparison
        if ($self->is_simple_comparison($ast)) {
            fsm_debug("  AST_FILTER: Simple comparison - FILTERING", 3);
            return 1;
        }
        
        # Check if it's an arithmetic operation (always keep)
        if ($ctx->{enable_graph}->is_arithmetic_operation($ast)) {
            fsm_debug("  AST_FILTER: Arithmetic operation - KEEPING", 3);
            return 0;
        }
        
        # Check if it's a logical operation
        if ($ctx->{enable_graph}->is_logical_operation($ast)) {
            # Use the existing AST-based logical operation factorization logic
            my $should_factor = $ctx->{enable_graph}->should_factor_logical_operation($ast);
            if ($should_factor && $usage_count >= 2) {
                fsm_debug("  AST_FILTER: Multi-use logical operation - KEEPING", 3);
                return 0;
            } else {
                fsm_debug("  AST_FILTER: Low-use logical operation - FILTERING", 3);
                return 1;
            }
        }
        
        # Other binary operations - keep if used multiple times
        if ($usage_count >= 2) {
            fsm_debug("  AST_FILTER: Multi-use binary operation - KEEPING", 3);
            return 0;
        } else {
            fsm_debug("  AST_FILTER: Single-use binary operation - FILTERING", 3);
            return 1;
        }
    }
    
    # Default: keep complex expressions that are used multiple times
    if ($usage_count >= 2) {
        fsm_debug("  AST_FILTER: Complex multi-use expression - KEEPING", 3);
        return 0;
    } else {
        fsm_debug("  AST_FILTER: Complex single-use expression - FILTERING", 3);
        return 1;
    }
}
sub should_filter_runtime_ast_miss ($self, $signal_name, $signal_info) {
    my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
        ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
        : 'unknown_runtime_ast_miss';
    my $live_usage = $self->resolve_intermediate_signal_live_usage($signal_name, $signal_info);
    my $referenced_in_substitutions = $live_usage->{referenced_in_substitutions} ? 1 : 0;
    my $used_in_final_expressions = $live_usage->{used_in_final_expressions} ? 1 : 0;
    my $evidence_state = $live_usage->{evidence_state} || 'none';

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{filter_fallback_source} = 'runtime_ast_miss_live_usage';
        $signal_info->{filter_fallback_reason} = $miss_reason;
    }

    fsm_debug("  RUNTIME_AST_MISS_FILTER: Evaluating '$signal_name' via live usage metadata ($evidence_state, miss_reason=$miss_reason)", 3);

    if ($referenced_in_substitutions) {
        fsm_debug("  RUNTIME_AST_MISS_FILTER: Signal '$signal_name' is referenced in AST substitutions - KEEPING", 3);
        return 0;
    }

    if ($used_in_final_expressions) {
        fsm_debug("  RUNTIME_AST_MISS_FILTER: Signal '$signal_name' is used in final AST expressions - KEEPING", 3);
        return 0;
    }

    fsm_debug("  RUNTIME_AST_MISS_FILTER: No AST-backed live-usage evidence for '$signal_name' - FILTERING", 3);
    return 1;
}
sub is_signal_referenced_in_substitutions ($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    # REFERENCE-AWARE FILTERING: Check if a signal is actually referenced in substituted expressions
    # This is the critical fix for the intermediate signal bug where signals are referenced but not declared
    
    fsm_debug("REFERENCE_CHECK: Checking if '$signal_name' is referenced in substitutions", 3);
    
    # Check if we have AST factorizer results available
    if ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{ast_expressions}) {
        my $ast_expressions = $ctx->{ast_factorizer}->{ast_expressions};
        fsm_debug("  Checking " . scalar(@$ast_expressions) . " factorized expressions");
        
        # Check each factorized (substituted) expression for references to this signal
        for my $expr_info (@$ast_expressions) {
            my $ast = $expr_info->{ast};
            my $context = $expr_info->{context};
            
            # Check if this AST contains a reference to our signal
            if ($ast && blessed($ast) && $self->ast_contains_signal($ast, $signal_name)) {
                fsm_debug("  REFERENCE FOUND: Signal '$signal_name' is referenced in context '$context'", 3);
                return 1;
            }
        }
    } else {
        fsm_debug("  WARNING: No AST factorizer results available for reference checking", 3);
    }
    
    # Also check in current assignment_analysis structures (post-substitution)
    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
                
                # Check DT-specific enable expressions
                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_ast = $dt_enable_info->{enable_ast};
                    if ($enable_ast && blessed($enable_ast) && $self->ast_contains_signal($enable_ast, $signal_name)) {
                        fsm_debug("  REFERENCE FOUND: Signal '$signal_name' in DT enable '$dt_enable_info->{enable_name}'", 3);
                        return 1;
                    }
                }
                
                # Check LHS-level enable expressions
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                    my $lhs_enable_ast = $rhs_group->{lhs_level_enable}->{ast};
                    if ($lhs_enable_ast && blessed($lhs_enable_ast) && $self->ast_contains_signal($lhs_enable_ast, $signal_name)) {
                        fsm_debug("  REFERENCE FOUND: Signal '$signal_name' in LHS enable '$rhs_group->{lhs_level_enable}->{name}'", 3);
                        return 1;
                    }
                }
            }
        }
    }
    
    # Check in lhs_assignments condition ASTs (post-substitution)
    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}->{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                if ($self->ast_contains_signal($assignment->{conditions_ast}, $signal_name)) {
                    fsm_debug("  REFERENCE FOUND: Signal '$signal_name' in assignment condition for LHS '$lhs'", 3);
                    return 1;
                }
            }
        }
    }
    
    fsm_debug("  REFERENCE NOT FOUND: Signal '$signal_name' is not referenced in any substituted expressions", 3);
    return 0;
}
sub is_signal_actually_used_in_final_expressions ($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    # Check if a signal is actually referenced in the final WEN/EN expressions
    # This is a more accurate usage check than just counting AST factorization usage
    
    fsm_debug("USAGE_CHECK: Checking if '$signal_name' is actually used in final expressions", 3);
    
    # Check if the signal appears in any of the final enable expressions
    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
                
                # Check DT-specific enable expressions
                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_ast = $dt_enable_info->{enable_ast};
                    if ($enable_ast && blessed($enable_ast) && $self->ast_contains_signal($enable_ast, $signal_name)) {
                        fsm_debug("    FOUND: Signal used in DT-specific enable $dt_enable_info->{enable_name}", 3);
                        return 1;
                    }
                }
                
                # Check LHS-level enable expressions
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                    my $lhs_enable_ast = $rhs_group->{lhs_level_enable}->{ast};
                    if ($lhs_enable_ast && blessed($lhs_enable_ast) && $self->ast_contains_signal($lhs_enable_ast, $signal_name)) {
                        fsm_debug("    FOUND: Signal used in LHS-level enable $rhs_group->{lhs_level_enable}->{name}", 3);
                        return 1;
                    }
                }
            }
        }
    }
    
    # Also check if it appears in any assignment conditions
    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}->{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                if ($self->ast_contains_signal($assignment->{conditions_ast}, $signal_name)) {
                    fsm_debug("    FOUND: Signal used in assignment condition for $lhs", 3);
                    return 1;
                }
            }
        }
    }
    
    fsm_debug("    NOT FOUND: Signal '$signal_name' is not used in any final expressions", 3);
    return 0;
}
sub ast_contains_signal ($self, $ast, $signal_name) {
    my $ctx = $self->{flattened_dt};
    # Recursively check if an AST contains a reference to a specific signal
    return 0 unless $ast && blessed($ast);
    
    # If this is a signal reference, check if it matches
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $ast_signal_name = $ctx->{enable_graph}->extract_signal_name_from_ast($ast);
        return 1 if $ast_signal_name && $ast_signal_name eq $signal_name;
    }
    
    # CRITICAL FIX: Also check for intermediate signal references from AST substitution
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $ast_signal_name = $ast->{signal_name};
        if ($ast_signal_name && $ast_signal_name eq $signal_name) {
            fsm_debug("    FOUND INTERMEDIATE: Signal '$signal_name' found as IntermediateSignalRef", 3);
            return 1;
        }
    }
    
    # Also check substituted binary and unary ops (which may contain intermediate signal refs)
    if ($ast->isa('FSM::HDL::SubstitutedBinaryOp')) {
        return 1 if $ast->{left} && $self->ast_contains_signal($ast->{left}, $signal_name);
        return 1 if $ast->{right} && $self->ast_contains_signal($ast->{right}, $signal_name);
    }
    elsif ($ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        return 1 if $ast->{operand} && $self->ast_contains_signal($ast->{operand}, $signal_name);
    }
    
    # Recursively check operands in standard AST nodes
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        return 1 if $ast->can('left') && $self->ast_contains_signal($ast->left, $signal_name);
        return 1 if $ast->can('right') && $self->ast_contains_signal($ast->right, $signal_name);
    }
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        return 1 if $ast->can('operand') && $self->ast_contains_signal($ast->operand, $signal_name);
    }
    
    return 0;
}
sub is_simple_negation ($self, $ast) {
    # Check if this is a simple negation of a signal (like !signal_name)
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp');
    return 0 unless $ast->can('operator') && $ast->can('operand');
    
    my $op = $ast->operator || '';
    return 0 unless $op =~ /^(!|not)$/;
    
    my $operand = $ast->operand;
    return 0 unless $operand && blessed($operand);
    
    # Check if operand is a simple signal reference
    return ($operand->isa('FSM::AST::SignalRef') || $operand->isa('FSM::CoreAST::SignalRef'));
}
sub is_simple_comparison ($self, $ast) {
    # Check if this is a simple comparison like signal == constant
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator') && $ast->can('left') && $ast->can('right');
    
    my $op = $ast->operator || '';
    return 0 unless $op =~ /^(==|!=|<|>|<=|>=)$/;
    
    my $left = $ast->left;
    my $right = $ast->right;
    return 0 unless $left && blessed($left) && $right && blessed($right);
    
    # Check if one side is a signal and the other is a literal
    my $has_signal = ($left->isa('FSM::AST::SignalRef') || $left->isa('FSM::CoreAST::SignalRef')) ||
                     ($right->isa('FSM::AST::SignalRef') || $right->isa('FSM::CoreAST::SignalRef'));
    my $has_literal = ($left->isa('FSM::AST::Literal') || $left->isa('FSM::CoreAST::Literal')) ||
                      ($right->isa('FSM::AST::Literal') || $right->isa('FSM::CoreAST::Literal'));
    
    return $has_signal && $has_literal;
}
sub generate_state_encoding ($self, $fsm_module) {
    my @regular_states = grep { $_->name !~ /^-/ } @{$fsm_module->states};
    my $state_count = scalar(@regular_states);
    my $state_bits = $state_count > 1 ? int(log($state_count)/log(2)) + 1 : 1;
    
    my $hdl = "  // State encoding\n";
    for my $i (0 .. $#regular_states) {
        my $state_name = uc($regular_states[$i]->name);
        $hdl .= "  localparam $state_name = ${state_bits}'d$i;\n";
    }
    $hdl .= "\n";
    
    return $hdl;
}
sub generate_state_register ($self, $fsm_module) {
    my @regular_states = grep { $_->name !~ /^-/ } @{$fsm_module->states};
    my $state_count = scalar(@regular_states);
    
    # Check if this FSM has no regular states (only standalone decision trees)
    if ($state_count == 0) {
        fsm_debug("FSM has no regular states - only standalone decision trees. Skipping state register generation.", 3);
        return "  // No state registers needed - FSM contains only decision trees\n\n";
    }
    
    my $state_bits = $state_count > 1 ? int(log($state_count)/log(2)) + 1 : 1;
    
    my $hdl = "  // State registers\n";
    $hdl .= "  reg [" . ($state_bits - 1) . ":0] current_state, next_state;\n\n";
    
    $hdl .= "  // State sequential logic\n";
    $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
    $hdl .= "    if (!rstn) begin\n";
    $hdl .= "      current_state <= " . uc($regular_states[0]->name) . ";\n";
    $hdl .= "    end else begin\n";
    $hdl .= "      current_state <= next_state;\n";
    $hdl .= "    end\n";
    $hdl .= "  end\n\n";
    
    return $hdl;
}
sub generate_enable_conditions ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "  // State and DT Enable Conditions\n";
    
    # Generate state enables
    for my $state_name (sort keys %{$ctx->{state_enables}}) {
        my $enable_expr = $ctx->{state_enables}->{$state_name};
        $hdl .= "  assign ${state_name}_en = $enable_expr;\n";
    }
    
    # Generate standalone DT enables
    for my $dt_name (sort keys %{$ctx->{dt_enables}}) {
        my $enable_expr = $ctx->{dt_enables}->{$dt_name};
        my $clean_name = $dt_name;
        $clean_name =~ s/^-//;  # Remove leading dash
        $hdl .= "  assign ${clean_name}_en = $enable_expr;\n";
    }
    
    $hdl .= "\n";
    return $hdl;
}
sub prescan_wen_en_for_intermediate_signals ($self) {
    my $ctx = $self->{flattened_dt};
    # PRE-SCAN all WEN/EN expressions to identify intermediate signals that need to be declared
    # This runs BEFORE generating intermediate signals so we know which ones to create
    
    fsm_debug("\n*** PRE-SCAN: IDENTIFYING INTERMEDIATE SIGNALS NEEDED FOR WEN/EN ***", 3);
    fsm_debug("*** TIMING DEBUG: PRE-SCAN running WITHOUT logical operation counts! ***", 3);
    
    # Check if we have logical operation counts available
    if (exists $ctx->{binary_logical_op_counts}) {
        my $total_ops = 0;
        for my $count (values %{$ctx->{binary_logical_op_counts}}) {
            $total_ops += $count;
        }
        fsm_debug("PRE-SCAN: Logical operation counts ARE available: $total_ops total ops", 3);
        fsm_debug("PRE-SCAN: Counts: " . Data::Dumper::Dumper($ctx->{binary_logical_op_counts}));
    } else {
        fsm_debug("*** PRE-SCAN: CRITICAL - Logical operation counts NOT available yet! ***", 3);
        fsm_debug("*** This means pre-scan is creating intermediate signals blindly! ***", 3);
    }
    
    # Initialize tracking structure
    $ctx->{referenced_intermediate_signals} //= {};
    
    # Process each LHS from the unified analysis to scan all enable expressions
    for my $lhs (sort keys %{$ctx->{assignment_analysis}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
        
        # Scan all DT-specific enable ASTs for intermediate signal references
        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
            
            for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                my $enable_ast = $dt_enable_info->{enable_ast};
                
                if ($enable_ast && blessed($enable_ast)) {
                    fsm_debug("  PRE-SCAN: Scanning DT-specific enable: $dt_enable_info->{enable_name}", 3);
                    $ctx->{enable_graph}->track_ast_intermediate_signals($enable_ast);
                }
            }
            
            # Scan LHS-level enable ASTs for intermediate signal references
            if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                my $lhs_enable = $rhs_group->{lhs_level_enable};
                my $enable_ast = $lhs_enable->{ast};
                
                if ($enable_ast && blessed($enable_ast)) {
                    fsm_debug("  PRE-SCAN: Scanning LHS-level enable: $lhs_enable->{name}", 3);
                    $ctx->{enable_graph}->track_ast_intermediate_signals($enable_ast);
                }
            }
        }
    }
    
    # Count discovered intermediate signals
    my $signal_count = scalar(keys %{$ctx->{referenced_intermediate_signals}});
    fsm_debug("PRE-SCAN: Identified $signal_count intermediate signals that need declaration", 3);
    
    # Debug list of discovered signals
    if ($signal_count > 0) {
        for my $signal_name (sort keys %{$ctx->{referenced_intermediate_signals}}) {
            fsm_debug("  - $signal_name", 3);
        }
    }
    
    fsm_debug("*** PRE-SCAN COMPLETE ***\n", 3);
}
sub generate_intermediate_signals ($self, $fsm_module) {
    my $hdl = "";
    
    fsm_debug("\n*** PHASE: GENERATE INTERMEDIATE SIGNALS (FULLY AST-BASED) ***", 3);
    
    # STEP 1: Run global AST factorization on all WEN/EN expressions
    my $intermediate_signals = $self->run_global_ast_factorization();
    
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
sub generate_consolidated_intermediate_signals ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    # Initialize intermediate signals storage
    $ctx->{intermediate_signals} = {};

    # CONSOLIDATED APPROACH: Generate intermediate signals from AST factorization AND pre-scan
    # This eliminates the duplicate signal generation issue
    
    fsm_debug("\n*** CONSOLIDATED INTERMEDIATE SIGNAL GENERATION ***", 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] FSM module: " . ($fsm_module ? $fsm_module->name : 'undefined'), 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] Current intermediate signals count: " . scalar(keys %{$ctx->{intermediate_signals} || {}}), 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] Current referenced signals count: " . scalar(keys %{$ctx->{referenced_intermediate_signals} || {}}), 3);
    
    # SIGNAL_TRACE: Complete dump of ALL signals at FSM module level (pipeline entry)
    if ($fsm_module && $fsm_module->signals) {
        my $fsm_signals = $fsm_module->signals;
        my $total_signals = scalar(keys %$fsm_signals);
        fsm_debug("SIGNAL_TRACE: FSM module has $total_signals total signals at PIPELINE_ENTRY", 3);
        
        # Categorize signals for better analysis
        my (@intermediate_signals, @regular_signals, @or_pattern_signals, @signals_with_driving_ast);
        
        for my $sig_name (sort keys %$fsm_signals) {
            my $signal = $fsm_signals->{$sig_name};
            
            # Check signal properties
            my $has_driving_ast = ($signal->can('driving_ast') && $signal->driving_ast) ? 1 : 0;
            my $is_intermediate = 0;
            
            # Try multiple ways to check for intermediate status
            if ($signal->can('get_attribute')) {
                $is_intermediate = $signal->get_attribute('is_intermediate') || 0;
            } elsif ($signal->can('attributes') && $signal->attributes) {
                $is_intermediate = $signal->attributes->{is_intermediate} || 0;
            }
            
            # Get AST/expression information
            my $ast_info = "NONE";
            my $expression_info = "NONE";
            my $ast_dump = "NO_AST";
            
            if ($has_driving_ast) {
                my $driving_ast = $signal->driving_ast;
                $ast_info = ref($driving_ast) || "UNKNOWN_TYPE";
                
                # Try to get SystemVerilog representation
                if ($driving_ast && $driving_ast->can('to_systemverilog')) {
                    $expression_info = eval { $driving_ast->to_systemverilog() } || "[AST_TO_SV_FAILED]";
                } else {
                    $expression_info = "[NO_TO_SYSTEMVERILOG_METHOD]";
                }
                
                # Get Data::Dumper representation of the AST
                $ast_dump = Data::Dumper->new([$driving_ast], ["${sig_name}_AST"])->Indent(2)->Sortkeys(1)->Dump();
            }
            
            # Categorize the signal
            if ($is_intermediate) {
                push @intermediate_signals, $sig_name;
            }
            if ($has_driving_ast) {
                push @signals_with_driving_ast, $sig_name;
            }
            if ($sig_name =~ /^or_\d+_\d+$/) {
                push @or_pattern_signals, $sig_name;
            } else {
                push @regular_signals, $sig_name;
            }
            
            # Detailed trace for each signal with complete AST dump
            fsm_debug("\n=== SIGNAL ANALYSIS: [$sig_name] ===", 3);
            fsm_debug("  Signal object type: " . ref($signal), 3);
            fsm_debug("  Has driving_ast: " . ($has_driving_ast ? "YES" : "NO"), 3);
            fsm_debug("  Is intermediate: " . ($is_intermediate ? "YES" : "NO"), 3);
            fsm_debug("  AST type: $ast_info", 3);
            fsm_debug("  SystemVerilog expression: $expression_info", 3);
            
            # Full AST dump using Data::Dumper
            fsm_debug("  AST DUMP:", 3);
            my @dump_lines = split(/\n/, $ast_dump);
            for my $line (@dump_lines) {
                fsm_debug("    $line", 3);
            }
            fsm_debug("=== END SIGNAL: [$sig_name] ===\n", 3);
        }
        
        # Summary statistics
        fsm_debug("\n*** SIGNAL_TRACE SUMMARY ***", 3);
        fsm_debug("  - Total signals: $total_signals", 3);
        fsm_debug("  - Intermediate signals: " . scalar(@intermediate_signals) . " (" . join(", ", @intermediate_signals) . ")", 3);
        fsm_debug("  - Signals with driving_ast: " . scalar(@signals_with_driving_ast) . " (" . join(", ", @signals_with_driving_ast) . ")", 3);
        fsm_debug("  - or_*_* pattern signals: " . scalar(@or_pattern_signals) . " (" . join(", ", @or_pattern_signals) . ")", 3);
        fsm_debug("  - Regular signals: " . scalar(@regular_signals), 3);
        fsm_debug("*** END SIGNAL_TRACE SUMMARY ***\n", 3);
    } else {
        fsm_debug("SIGNAL_TRACE: WARNING - No FSM module or signals available at pipeline entry!", 3);
    }
    
    my $hdl = "";
    
    # Step 1: Run AST factorization to identify common sub-expressions
    my $ast_intermediate_signals = $self->run_global_ast_factorization();
    
    # Step 2: Merge with pre-scan results to get comprehensive list
    my %all_intermediate_signals;
    
    # Add signals from AST factorization
    if ($ast_intermediate_signals && %$ast_intermediate_signals) {
        for my $signal_name (keys %$ast_intermediate_signals) {
            $all_intermediate_signals{$signal_name} = {
                source => 'ast_factorization',
                %{$ast_intermediate_signals->{$signal_name}}
            };
        }
    }
    
    # Add signals from pre-scan (referenced by WEN/EN but not yet declared)
    if ($ctx->{referenced_intermediate_signals}) {
        for my $signal_name (keys %{$ctx->{referenced_intermediate_signals}}) {
            # Only add if not already in AST factorization results
            unless (exists $all_intermediate_signals{$signal_name}) {
                my $referenced_signal_info = $ctx->{referenced_intermediate_signals}->{$signal_name} || {};
                my $runtime_ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $referenced_signal_info);
                my $expression = (!$runtime_ast || !blessed($runtime_ast))
                    ? $ctx->{enable_graph}->get_intermediate_signal_expression($signal_name)
                    : undef;
                if (($runtime_ast && blessed($runtime_ast)) || $expression) {
                    $all_intermediate_signals{$signal_name} = {
                        source => 'prescan_reference',
                        %$referenced_signal_info,
                        ($runtime_ast && blessed($runtime_ast) ? (ast => $runtime_ast, runtime_ast => $runtime_ast) : ()),
                        (defined($expression) && $expression ne '' ? (expression => $expression) : ()),
                        usage_count => 1
                    };
                }
            }
        }
    }
    
    # Step 2.5: Add intermediate signals from FSMGenFull parsing (CRITICAL FIX)
    # These are signals created during FSMGen parsing with driving_ast already set
    if ($fsm_module && $fsm_module->can('signals') && $fsm_module->signals) {
        fsm_debug("CONSOL_INTER_SIG: [FSMGEN_SIGNALS] Scanning FSM module for intermediate signals from parsing", 3);
        my $fsm_signals = $fsm_module->signals;
        my $fsmgen_intermediate_count = 0;
        
        fsm_debug("  FSMGEN_SIGNALS: FSM module has " . scalar(keys %$fsm_signals) . " total signals", 3);
        
        for my $signal_name (keys %$fsm_signals) {
            my $signal = $fsm_signals->{$signal_name};
            
            # Debug every signal to understand the structure
            fsm_debug("  FSMGEN_SIGNAL_SCAN: '$signal_name' -> " . ref($signal), 3);
            
            # Check if this signal has driving_ast (more flexible check)
            if ($signal && $signal->can('driving_ast') && $signal->driving_ast) {
                fsm_debug("    HAS_DRIVING_AST: '$signal_name' has driving AST", 3);
                
                # Check for intermediate marker with more flexible attribute checking
                my $is_intermediate = 0;
                
                # ENHANCED DEBUG: Show what we're working with
                fsm_debug("      SIGNAL_DEBUG: Processing signal '$signal_name'", 3);
                fsm_debug("        Signal object type: " . ref($signal), 3);
                fsm_debug("        Signal blessed: " . (blessed($signal) ? 'YES' : 'NO'), 3);
                
                # Method 1: Try get_attribute method
                if ($signal->can('get_attribute')) {
                    $is_intermediate = $signal->get_attribute('is_intermediate');
                    fsm_debug("      METHOD1: get_attribute('is_intermediate') = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 2: Try attributes hash
                if (!$is_intermediate && $signal->can('attributes') && $signal->attributes) {
                    $is_intermediate = $signal->attributes->{is_intermediate};
                    fsm_debug("      METHOD2: attributes->{is_intermediate} = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 3: Try direct hash access (for FSM::CoreAST::Signal)
                if (!$is_intermediate && ref($signal) eq 'HASH' && exists($signal->{is_intermediate})) {
                    $is_intermediate = $signal->{is_intermediate};
                    fsm_debug("      METHOD3: signal->{is_intermediate} = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 4: Try direct property access (for object-based signals)
                if (!$is_intermediate && blessed($signal) && $signal->can('is_intermediate')) {
                    $is_intermediate = eval { $signal->is_intermediate } || 0;
                    fsm_debug("      METHOD4: signal->is_intermediate() = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 5: Direct dereferencing with proper error handling
                if (!$is_intermediate && blessed($signal)) {
                    # Use eval to safely access the hash representation
                    my $signal_hash = eval { \%{$signal} };
                    if ($signal_hash && exists $signal_hash->{is_intermediate}) {
                        $is_intermediate = $signal_hash->{is_intermediate};
                        fsm_debug("      METHOD5: direct hash deref to is_intermediate = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                    }
                }
                
                # Method 6: Check FSM::CoreAST::Signal internal structure
                if (!$is_intermediate && blessed($signal) && $signal->isa('FSM::CoreAST::Signal')) {
                    # FSM::CoreAST::Signal may store attributes in constructor arguments
                    # Check all keys in the signal object for is_intermediate
                    for my $key (keys %$signal) {
                        if ($key eq 'is_intermediate' && defined($signal->{$key})) {
                            $is_intermediate = $signal->{$key};
                            fsm_debug("      METHOD6: Found is_intermediate as direct key '$key' = $is_intermediate", 3);
                            last;
                        }
                    }
                }
                
                fsm_debug("    IS_INTERMEDIATE_CHECK: '$signal_name' intermediate status: " . ($is_intermediate || 'undefined'), 3);
                
                # If it has driving_ast and is marked intermediate - no arbitrary name pattern matching
                if ($is_intermediate) {
                    # CRITICAL FIX: Even if already added from other sources (pre-scan), 
                    # FSMGenFull intermediate signals should ALWAYS be processed because 
                    # they have the actual AST and expression information needed for declaration
                    
                    # Declare driving_ast once at the outer scope to avoid scoping issues
                    my $driving_ast = $signal->driving_ast;
                    
                    if (exists $all_intermediate_signals{$signal_name}) {
                        fsm_debug("  FSMGEN_INTERMEDIATE: Signal '$signal_name' already exists, but UPDATING with FSMGenFull AST data", 3);
                        # Update the existing entry with proper AST information from FSMGenFull
                        $all_intermediate_signals{$signal_name} = {
                            source => 'fsmgen_parsing',
                            ast => $driving_ast,
                            width => ($signal->can('width') ? $signal->width : undef) || 1,
                            usage_count => 1,  # Conservative estimate
                            driving_ast => $driving_ast  # Store both ast and driving_ast for compatibility
                        };
                        $fsmgen_intermediate_count++;
                        
                        fsm_debug("  FSMGEN_INTERMEDIATE: UPDATED signal '$signal_name' with driving AST: " . ref($driving_ast), 3);
                        fsm_debug("    AST SystemVerilog: " . eval { $driving_ast->to_systemverilog() } || '[AST ERROR]', 3);
                    } else {
                        # This is a new FSMGenFull intermediate signal with proper driving AST
                        fsm_debug("  FSMGEN_INTERMEDIATE: Found NEW signal '$signal_name' with driving AST: " . ref($driving_ast), 3);
                        fsm_debug("    AST SystemVerilog: " . eval { $driving_ast->to_systemverilog() } || '[AST ERROR]', 3);
                        
                        $all_intermediate_signals{$signal_name} = {
                            source => 'fsmgen_parsing',
                            ast => $driving_ast,
                            width => ($signal->can('width') ? $signal->width : undef) || 1,
                            usage_count => 1,  # Conservative estimate
                            driving_ast => $driving_ast  # Store both ast and driving_ast for compatibility
                        };
                        $fsmgen_intermediate_count++;
                    }
                } else {
                    fsm_debug("    NOT_INTERMEDIATE: Signal '$signal_name' has driving AST but is not marked as intermediate", 3);
                }
            } else {
                # Debug why this signal doesn't qualify
                if (!$signal) {
                    fsm_debug("    SKIP: '$signal_name' - signal object is null", 3);
                } elsif (!$signal->can('driving_ast')) {
                    fsm_debug("    SKIP: '$signal_name' - signal has no driving_ast method", 3);
                } elsif (!$signal->driving_ast) {
                    fsm_debug("    SKIP: '$signal_name' - signal has no driving_ast set", 3);
                }
            }
        }
        
        fsm_debug("CONSOL_INTER_SIG: [FSMGEN_SIGNALS] Found $fsmgen_intermediate_count intermediate signals from FSMGenFull parsing", 3);
    } else {
        fsm_debug("CONSOL_INTER_SIG: [FSMGEN_SIGNALS] No FSM module signals available for scanning", 3);
    }

    # Step 2.6: Normalize runtime ASTs so the live consolidated path can stay AST-first.
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my $runtime_ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
        if ($runtime_ast && blessed($runtime_ast)) {
            fsm_debug("CONSOL_INTER_SIG: [RUNTIME_AST] '$signal_name' normalized via " . ($signal_info->{runtime_ast_source} || 'runtime_ast'), 3);
        } else {
            fsm_debug("CONSOL_INTER_SIG: [RUNTIME_AST] '$signal_name' still lacks AST; compatibility fallback remains", 3);
        }
    }

    # Step 2.7: Normalize intermediate signal widths from native signal metadata or defining ASTs.
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my $resolved_width = $self->resolve_intermediate_signal_width($signal_name, $signal_info, \%all_intermediate_signals);
        $signal_info->{width} = $resolved_width;
        fsm_debug("CONSOL_INTER_SIG: [WIDTH] '$signal_name' width normalized to $resolved_width", 3);
    }

    # Step 2.8: Normalize dependency metadata so the live path consumes AST-first cached dependencies.
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my @dependencies = $self->resolve_intermediate_signal_dependencies($signal_name, $signal_info);
        my $dependency_summary = @dependencies ? join(', ', @dependencies) : 'none';
        fsm_debug("CONSOL_INTER_SIG: [DEPENDENCIES] '$signal_name' => $dependency_summary via " . ($signal_info->{dependency_source} || 'none'), 3);
    }

    # Step 2.9: Normalize rendered expressions so downstream phases reuse one cached rendering path.
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my $rendered_expression = $self->render_intermediate_signal_expression($signal_name, $signal_info);
        my $render_source = $signal_info->{rendered_expression_source} || 'none';
        if (defined($rendered_expression) && $rendered_expression ne '') {
            fsm_debug("CONSOL_INTER_SIG: [RENDER] '$signal_name' cached via $render_source", 3);
        } else {
            fsm_debug("CONSOL_INTER_SIG: [RENDER] '$signal_name' has no cached renderable expression", 3);
        }
    }

    # Step 2.10: Normalize live usage metadata so filtering consumes cached AST-derived usage facts.
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my $live_usage = $self->resolve_intermediate_signal_live_usage($signal_name, $signal_info);
        my $usage_summary = $live_usage->{evidence_state} || 'none';
        fsm_debug("CONSOL_INTER_SIG: [LIVE_USAGE] '$signal_name' => $usage_summary via " . ($live_usage->{source} || 'ast_live_usage_metadata'), 3);
    }
    
    # Step 3: Apply dependency-aware filtering to prevent referenced signals from being filtered out
    fsm_debug("\n*** DEPENDENCY-AWARE FILTERING PHASE ***", 3);
    
    # Step 3a: Build dependency map from intermediate signal expressions
    my %signal_dependencies = ();  # signal_name => [list of signals it depends on]
    
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my @referenced_signals = $self->resolve_intermediate_signal_dependencies($signal_name, $signal_info);
        
        # Find all intermediate signals referenced in this expression
        if (@referenced_signals) {
            $signal_dependencies{$signal_name} = [@referenced_signals];
            fsm_debug("  DEPENDENCY: '$signal_name' depends on: " . join(", ", @referenced_signals), 3);
        }
    }
    
    # Step 3b: Apply initial filtering pass
    my %initially_filtered_signals;
    my %initially_kept_signals;
    
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        
        # Get expression for filtering analysis
        my $expression = $self->render_intermediate_signal_expression($signal_name, $signal_info);
        unless (defined($expression) && $expression ne '') {
            next;
        }
        
        # Apply filtering logic
        my $should_filter = $self->should_filter_consolidated_signal($expression, $signal_name, $signal_info);
        if ($should_filter) {
            $initially_filtered_signals{$signal_name} = $signal_info;
            fsm_debug("  INITIAL FILTER: '$signal_name' = $expression (would be filtered)", 3);
        } else {
            $initially_kept_signals{$signal_name} = $signal_info;
            fsm_debug("  INITIAL KEEP: '$signal_name' = $expression (would be kept)", 3);
        }
    }
    
    # Step 3c: Dependency propagation - rescue filtered signals that are needed by kept signals
    my %rescued_signals = ();
    
    # Check each kept signal's dependencies
    for my $kept_signal (keys %initially_kept_signals) {
        if ($signal_dependencies{$kept_signal}) {
            for my $dependency (@{$signal_dependencies{$kept_signal}}) {
                # If the dependency was initially filtered but exists in our signal set, rescue it
                if ($initially_filtered_signals{$dependency}) {
                    $rescued_signals{$dependency} = $initially_filtered_signals{$dependency};
                    fsm_debug("  RESCUED: Signal '$dependency' rescued because it's needed by '$kept_signal'", 3);
                }
            }
        }
    }
    
    # Step 3d: Build final filtered signal set
    my %filtered_signals = (%initially_kept_signals, %rescued_signals);
    
    # Final summary
    my $initially_kept_count = scalar(keys %initially_kept_signals);
    my $rescued_count = scalar(keys %rescued_signals);
    my $filtered_count = scalar(keys %initially_filtered_signals) - $rescued_count;
    my $total_kept = scalar(keys %filtered_signals);
    
    fsm_debug("\n*** DEPENDENCY-AWARE FILTERING SUMMARY ***", 3);
    fsm_debug("  Initially kept: $initially_kept_count signals", 3);
    fsm_debug("  Rescued by dependencies: $rescued_count signals", 3);
    fsm_debug("  Actually filtered out: $filtered_count signals", 3);
    fsm_debug("  Total signals kept: $total_kept signals", 3);
    
    # Debug list of rescued signals
    if (%rescued_signals) {
        for my $rescued_signal (sort keys %rescued_signals) {
            my $signal_info = $rescued_signals{$rescued_signal};
            my $expression = $self->render_intermediate_signal_expression($rescued_signal, $signal_info);
            fsm_debug("    RESCUED: $rescued_signal = $expression", 3);
        }
    }
    
    # Debug list of finally filtered signals
    my %finally_filtered = %initially_filtered_signals;
    for my $rescued (keys %rescued_signals) {
        delete $finally_filtered{$rescued};
    }
    if (%finally_filtered) {
        for my $filtered_signal (sort keys %finally_filtered) {
            my $signal_info = $finally_filtered{$filtered_signal};
            my $expression = $self->render_intermediate_signal_expression($filtered_signal, $signal_info);
            fsm_debug("    FILTERED OUT: $filtered_signal = $expression", 3);
        }
    }
    
    fsm_debug("*** DEPENDENCY-AWARE FILTERING COMPLETE ***\n", 3);
    
    # Step 4a: LHS signal declarations are emitted once in generate_internal_signal_declarations().
    # Avoid redeclaring them here with incompatible types.
    
    # Step 4b: Generate HDL for consolidated intermediate signals
    if (%filtered_signals) {
        $hdl .= "  // Consolidated intermediate signals (AST factorization + pre-scan)\n";
        
        # Perform topological sort to ensure dependencies are declared before use
        my @sorted_signals = $self->topologically_sort_signals(\%filtered_signals, \%signal_dependencies);
        
        # First pass: Generate all wire declarations
        for my $signal_name (@sorted_signals) {
            my $signal_info = $filtered_signals{$signal_name};
            my $width = $self->resolve_intermediate_signal_width($signal_name, $signal_info, \%filtered_signals);
            
            # Generate wire declaration
            if ($width > 1) {
                $hdl .= "  wire [" . ($width - 1) . ":0] $signal_name;\n";
            } else {
                $hdl .= "  wire $signal_name;\n";
            }
        }
        
        $hdl .= "\n";  # Add spacing between declarations and assignments
        
        # Second pass: Generate all assign statements
        for my $signal_name (@sorted_signals) {
            my $signal_info = $filtered_signals{$signal_name};
            my $source = $signal_info->{source};
            
            my $expression = $self->render_intermediate_signal_expression($signal_name, $signal_info);
            unless (defined($expression) && $expression ne '') {
                fsm_debug("CONSOL_INTER_SIG: WARNING - No renderable expression for $signal_name, skipping assign emission", 3);
                next;
            }
            
            $hdl .= "  assign $signal_name = $expression; // Source: $source\n";
            
            fsm_debug("  CONSOLIDATED: wire $signal_name = $expression (source: $source)", 3);
        }
        
        $hdl .= "\n";
    } else {
        fsm_debug("  No consolidated intermediate signals needed after filtering", 3);
    }
    
    fsm_debug("*** CONSOLIDATED INTERMEDIATE SIGNAL GENERATION COMPLETE ***\n", 3);
    
    return $hdl;
}
sub topologically_sort_signals ($self, $filtered_signals, $signal_dependencies) {
    fsm_debug("TOPO_SORT: Starting topological sort of intermediate signals", 3);
    fsm_debug("TOPO_SORT: Input signals: " . scalar(keys %$filtered_signals), 3);
    fsm_debug("TOPO_SORT: Dependencies: " . scalar(keys %$signal_dependencies), 3);
    
    # Initialize tracking structures
    my @sorted_signals;
    my %visited;           # Permanent mark (already processed)
    my %temp_visited;      # Temporary mark (currently being processed)
    my %in_degree;         # Count of dependencies for each signal
    
    # Calculate in-degrees for all signals
    for my $signal (keys %$filtered_signals) {
        $in_degree{$signal} = 0;
    }
    
    for my $signal (keys %$signal_dependencies) {
        my $deps = $signal_dependencies->{$signal};
        for my $dep (@$deps) {
            if (exists $filtered_signals->{$dep}) {
                $in_degree{$signal}++;
            }
        }
    }
    
    # Debug initial in-degrees
    fsm_debug("TOPO_SORT: Initial in-degrees:", 3);
    for my $signal (sort keys %in_degree) {
        fsm_debug("  $signal: $in_degree{$signal} dependencies", 3);
    }
    
    # Kahn's algorithm: start with signals that have no dependencies
    my @queue = grep { $in_degree{$_} == 0 } keys %$filtered_signals;
    
    fsm_debug("TOPO_SORT: Starting with " . scalar(@queue) . " signals with no dependencies: " . join(", ", @queue), 3);
    
    while (@queue) {
        my $current = shift @queue;
        push @sorted_signals, $current;
        $visited{$current} = 1;
        
        fsm_debug("  Processing signal: $current", 3);
        
        # Find signals that depend on the current signal
        for my $signal (keys %$signal_dependencies) {
            next if $visited{$signal};
            
            my $deps = $signal_dependencies->{$signal};
            if (grep { $_ eq $current } @$deps) {
                $in_degree{$signal}--;
                fsm_debug("    Reduced in-degree of $signal to $in_degree{$signal}", 3);
                
                if ($in_degree{$signal} == 0) {
                    push @queue, $signal;
                    fsm_debug("    Added $signal to queue (all dependencies satisfied)", 3);
                }
            }
        }
    }
    
    # Check for circular dependencies
    my @remaining_signals = grep { !$visited{$_} } keys %$filtered_signals;
    if (@remaining_signals) {
        fsm_debug("TOPO_SORT: WARNING - Potential circular dependencies detected:", 3);
        for my $signal (@remaining_signals) {
            fsm_debug("  $signal (in-degree: $in_degree{$signal})", 3);
            # Add remaining signals to the end in alphabetical order as fallback
            push @sorted_signals, $signal;
        }
    }
    
    fsm_debug("TOPO_SORT: Final sorted order: " . join(", ", @sorted_signals), 3);
    fsm_debug("TOPO_SORT: Topological sort complete", 3);
    
    return @sorted_signals;
}
sub count_binary_logical_operation_occurrences ($self) {
    my $ctx = $self->{flattened_dt};
    # Count occurrences of specific binary logical operations across all FSM expressions
    # This is used to determine if binary logical operations should be factorized
    
    my %logical_op_counts;
    
    fsm_debug("\n*** COUNT_LOGICAL_OPS: STARTING LOGICAL OPERATION COUNTING ***", 3);
    fsm_debug("COUNT_LOGICAL_OPS: This should happen BEFORE any intermediate signal creation!", 3);
    
    # Check if pre-scan has already run
    if (exists $ctx->{referenced_intermediate_signals} && %{$ctx->{referenced_intermediate_signals}}) {
        my $prescan_count = scalar(keys %{$ctx->{referenced_intermediate_signals}});
        fsm_debug("*** COUNT_LOGICAL_OPS: WARNING - Pre-scan has already identified $prescan_count intermediate signals! ***", 3);
        fsm_debug("*** This means the logical operation counting is happening TOO LATE! ***", 3);
        fsm_debug("Pre-scan signals: " . join(", ", sort keys %{$ctx->{referenced_intermediate_signals}}));
    } else {
        fsm_debug("COUNT_LOGICAL_OPS: Good - No pre-scan signals created yet", 3);
    }
    
    fsm_debug("COUNT_LOGICAL_OPS: Counting binary logical operation occurrences", 3);
    
    # Collect all AST expressions
    my @ast_expressions = $self->collect_all_wen_en_ast_expressions();
    
    # Count logical operations in each expression
    for my $ast_info (@ast_expressions) {
        my $ast = $ast_info->{ast};
        $self->_count_logical_ops_in_ast($ast, \%logical_op_counts);
    }
    
    # Also count from any intermediate signal expressions
    for my $signal_name (keys %{$ctx->{intermediate_signals} || {}}) {
        my $ast = $ctx->{enable_graph}->_get_native_intermediate_signal_ast($signal_name);
        if ($ast && blessed($ast)) {
            $self->_count_logical_ops_in_ast($ast, \%logical_op_counts);
        } else {
            fsm_debug("COUNT_LOGICAL_OPS: Skipping '$signal_name' because no native intermediate AST is available", 3);
        }
    }
    
    # Store the counts for later use
    $ctx->{binary_logical_op_counts} = \%logical_op_counts;
    
    # Debug output
    my $total_ops = 0;
    my @high_count_ops;
    for my $op_signature (keys %logical_op_counts) {
        my $count = $logical_op_counts{$op_signature};
        $total_ops += $count;
        fsm_debug("  Logical operation '$op_signature' appears $count times", 3);
        if ($count > 1) {
            push @high_count_ops, "$op_signature ($count times)";
        }
    }
    
    fsm_debug("COUNT_LOGICAL_OPS: Found $total_ops total logical operations", 3);
    fsm_debug("COUNT_LOGICAL_OPS: Operations appearing multiple times: " . (@high_count_ops ? join(", ", @high_count_ops) : "None"));
    
    # Show the full counts structure for debugging
    fsm_debug("COUNT_LOGICAL_OPS: Complete counts structure:", 3);
    fsm_debug(Data::Dumper::Dumper(\%logical_op_counts));
    
    fsm_debug("*** COUNT_LOGICAL_OPS: LOGICAL OPERATION COUNTING COMPLETE ***\n", 3);
    return \%logical_op_counts;
}
sub collect_all_wen_en_ast_expressions ($self) {
    my $ctx = $self->{flattened_dt};
    # Collect ALL AST expressions used in WEN/EN signals across the design
    my @ast_expressions;
    
    fsm_debug("COLLECT_AST: Collecting all WEN/EN AST expressions", 3);
    
    # Collect from unified assignment analysis
    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
                
                # Collect DT-specific enable ASTs
                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast}) {
                        push @ast_expressions, {
                            ast => $dt_enable->{enable_ast},
                            context => "dt_enable:$dt_enable->{enable_name}",
                            usage_type => 'dt_enable'
                        };
                    }
                }
                
                # Collect LHS-level enable ASTs
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                    push @ast_expressions, {
                        ast => $rhs_group->{lhs_level_enable}->{ast},
                        context => "lhs_enable:$rhs_group->{lhs_level_enable}->{name}",
                        usage_type => 'lhs_enable'
                    };
                }
            }
        }
    }
    
    # Collect from any other AST sources (assignments with stored ASTs)
    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}->{$lhs}}) {
            if ($assignment->{conditions_ast}) {
                push @ast_expressions, {
                    ast => $assignment->{conditions_ast},
                    context => "assignment_condition:$lhs:$assignment->{dt}",
                    usage_type => 'assignment_condition'
                };
            }
        }
    }
    
    fsm_debug("COLLECT_AST: Collected " . scalar(@ast_expressions) . " AST expressions", 3);
    return @ast_expressions;
}
sub analyze_ast_sub_expressions ($self, $ast_expressions) {
    # Analyze all collected AST expressions to find common sub-expressions
    my %sub_expression_usage;
    
    fsm_debug("ANALYZE_AST: Analyzing sub-expressions in " . scalar(@$ast_expressions) . " AST expressions");
    
    for my $ast_info (@$ast_expressions) {
        my $ast = $ast_info->{ast};
        my $context = $ast_info->{context};
        
        # Find all sub-expressions in this AST
        my @sub_expressions = $self->find_all_ast_sub_expressions($ast);
        
        for my $sub_expr_ast (@sub_expressions) {
            # Convert to canonical string for comparison
            my $canonical = eval { $sub_expr_ast->to_systemverilog() } || "invalid_ast";
            
            # Skip simple expressions
            next if $self->is_simple_ast_expression($sub_expr_ast);
            
            # Record usage
            $sub_expression_usage{$canonical} ||= {
                ast => $sub_expr_ast,
                usage_count => 0,
                contexts => []
            };
            
            $sub_expression_usage{$canonical}->{usage_count}++;
            push @{$sub_expression_usage{$canonical}->{contexts}}, $context;
            
            fsm_debug("  Found sub-expression: '$canonical' in $context", 3);
        }
    }
    
    # Log summary
    my $total_unique = scalar(keys %sub_expression_usage);
    my $multi_use = grep { $sub_expression_usage{$_}->{usage_count} > 1 } keys %sub_expression_usage;
    fsm_debug("ANALYZE_AST: Found $total_unique unique sub-expressions, $multi_use used multiple times", 3);
    
    return %sub_expression_usage;
}
sub find_all_ast_sub_expressions ($self, $ast) {
    # Recursively find all meaningful sub-expressions in an AST
    my @sub_expressions;
    
    return @sub_expressions unless $ast && blessed($ast);
    
    # Binary operations: include operands as sub-expressions
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Add operands if they're complex enough
        if ($ast->can('left') && $ast->left && !$self->is_simple_ast_expression($ast->left)) {
            push @sub_expressions, $ast->left;
        }
        if ($ast->can('right') && $ast->right && !$self->is_simple_ast_expression($ast->right)) {
            push @sub_expressions, $ast->right;
        }
        
        # Recursively find sub-expressions in operands
        push @sub_expressions, $self->find_all_ast_sub_expressions($ast->left) if $ast->can('left');
        push @sub_expressions, $self->find_all_ast_sub_expressions($ast->right) if $ast->can('right');
    }
    # Unary operations: include operand as sub-expression
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        if ($ast->can('operand') && $ast->operand && !$self->is_simple_ast_expression($ast->operand)) {
            push @sub_expressions, $ast->operand;
        }
        
        # Recursively find sub-expressions in operand
        push @sub_expressions, $self->find_all_ast_sub_expressions($ast->operand) if $ast->can('operand');
    }
    
    return @sub_expressions;
}
sub _count_logical_ops_in_ast ($self, $ast, $counts_ref) {
    # Recursively count ALL factorizable sub-expressions in an AST
    # This traverses the ENTIRE AST tree to find every possible sub-expression that could be factored
    return unless $ast && blessed($ast);
    
    # COUNT THIS ENTIRE EXPRESSION: Check if this entire AST node is factorizable
    if ($self->_is_factorizable_sub_expression($ast)) {
        my $signature = eval { $ast->to_systemverilog() } || 'unknown';
        $counts_ref->{$signature}++;
        fsm_debug("    Found factorizable sub-expression: '$signature' (count: $counts_ref->{$signature})", 3);
    }
    
    # RECURSE INTO ALL CHILDREN: Walk the entire AST tree to find nested factorizable expressions
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Recursively analyze both operands
        $self->_count_logical_ops_in_ast($ast->left, $counts_ref) if $ast->can('left');
        $self->_count_logical_ops_in_ast($ast->right, $counts_ref) if $ast->can('right');
    }
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        # Recursively analyze operand
        $self->_count_logical_ops_in_ast($ast->operand, $counts_ref) if $ast->can('operand');
    }
    
    # Note: Literals and SignalRefs are leaf nodes - they don't need recursion
}
sub _is_factorizable_sub_expression ($self, $ast) {
    my $ctx = $self->{flattened_dt};
    # Determine if an AST node represents a sub-expression worth factoring
    # Based on the spec:
    # - Unary operations: ALWAYS create intermediate signals
    # - Binary logical operations: Only if used more than once
    # - Binary arithmetic operations: ALWAYS create intermediate signals
    
    return 0 unless $ast && blessed($ast);
    
    # DON'T factor simple literals or bare signal references
    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        return 0;
    }
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        return 0;
    }
    
    # UNARY OPERATIONS: Always factor (per spec)
    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("FACTORIZABLE: Unary operation - ALWAYS FACTOR", 3);
        return 1;
    }
    
    # BINARY OPERATIONS: Check type to determine factorization policy
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Arithmetic operations: Always factor (per spec)
        if ($ctx->{enable_graph}->is_arithmetic_operation($ast)) {
            fsm_debug("FACTORIZABLE: Arithmetic operation - ALWAYS FACTOR", 3);
            return 1;
        }
        
        # Logical operations: Only if used multiple times (per spec)
        if ($ctx->{enable_graph}->is_logical_operation($ast)) {
            my $signature = eval { $ast->to_systemverilog() } || 'unknown';
            my $count = ($ctx->{binary_logical_op_counts} || {})->{$signature} || 0;
            if ($count > 1) {
                fsm_debug("FACTORIZABLE: Logical operation '$signature' used $count times - FACTOR", 3);
                return 1;
            } else {
                fsm_debug("FACTORIZABLE: Logical operation '$signature' used only $count time - DON'T FACTOR", 3);
                return 0;
            }
        }
        
        # Other binary operations (comparisons, etc.): Always factor
        fsm_debug("FACTORIZABLE: Other binary operation - ALWAYS FACTOR", 3);
        return 1;
    }
    
    # DO factor other complex expressions
    return 1;
}
sub is_simple_ast_expression ($self, $ast) {
    my $ctx = $self->{flattened_dt};
    # Refined factorization logic:
    # - Always factor unary operations
    # - Only factor binary logical ops that appear multiple times
    # - Always factor binary arithmetic operations
    # - Literals and bare signal references remain simple
    
    return 1 unless $ast && blessed($ast);
    
    # Literals are always simple
    return 1 if $ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal');
    
    # Signal references are simple
    return 1 if $ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef');
    
    # UNARY OPERATIONS: Always factor (never simple)
    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("SIMPLE_CHECK: Unary operation - ALWAYS FACTOR (not simple)", 3);
        return 0;
    }
    
    # BINARY OPERATIONS: Check type and occurrence count
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Always factor arithmetic operations
        if ($ctx->{enable_graph}->is_arithmetic_operation($ast)) {
            fsm_debug("SIMPLE_CHECK: Arithmetic operation - ALWAYS FACTOR (not simple)", 3);
            return 0;
        }
        
        # For logical operations, only factor if they appear multiple times
        if ($ctx->{enable_graph}->is_logical_operation($ast)) {
            my $should_factor = $ctx->{enable_graph}->should_factor_logical_operation($ast);
            if ($should_factor) {
                fsm_debug("SIMPLE_CHECK: Multi-use logical operation - FACTOR (not simple)", 3);
                return 0;
            } else {
                fsm_debug("SIMPLE_CHECK: Single-use logical operation - DON'T FACTOR (simple)", 3);
                return 1;
            }
        }
        
        # Other binary operations (comparisons, etc.) - factor if complex
        fsm_debug("SIMPLE_CHECK: Other binary operation - FACTOR (not simple)", 3);
        return 0;
    }
    
    # Everything else is complex
    return 0;
}
sub run_global_ast_factorization ($self) {
    my $ctx = $self->{flattened_dt};
    # GENERIC AST-BASED GLOBAL FACTORIZATION
    # Uses pure AST structural analysis - works with any FSM
    
    fsm_debug("\n*** GENERIC GLOBAL AST FACTORIZATION PHASE ***", 3);
    fsm_debug("GLOBAL_AST_FACT: [ENTRY] Starting run_global_ast_factorization", 3);
    
    # TIMING FIX: Logical operations should already be counted by now!
    fsm_debug("GLOBAL_AST_FACT: [CHECK] Checking if binary_logical_op_counts exists", 3);
    if (exists $ctx->{binary_logical_op_counts}) {
        fsm_debug("GLOBAL_AST_FACT: [EXISTS] binary_logical_op_counts found", 3);
        my $total_ops = 0;
        for my $count (values %{$ctx->{binary_logical_op_counts}}) {
            $total_ops += $count;
        }
        fsm_debug("AST_FACTORIZATION: Using existing logical operation counts: $total_ops total ops", 3);
        # Show some details about operation counts
        for my $op_sig (keys %{$ctx->{binary_logical_op_counts}}) {
            my $count = $ctx->{binary_logical_op_counts}{$op_sig};
            fsm_debug("  Operation '$op_sig': $count occurrences", 3);
        }
    } else {
        fsm_debug("GLOBAL_AST_FACT: [NOT_EXISTS] binary_logical_op_counts NOT found - running count now", 3);
        fsm_debug("*** WARNING: No logical operation counts available - this shouldn't happen! ***", 3);
        $self->count_binary_logical_operation_occurrences();
    }
    
    # Load the generic AST factorization system
    require FSM::HDL::ASTFactorization;
    
    # Initialize generic factorizer with enhanced debugging
    my $factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => debug_enabled(),
        debug_level => 3  # Enable highest level of debug output
    );
    
    # STEP 1: Collect and add all AST expressions to factorizer
    fsm_debug("*** STEP 1: FEEDING ASTs TO FACTORIZER ***", 3);
    my $ast_count = $self->feed_asts_to_factorizer($factorizer);
    fsm_debug("Fed $ast_count AST expressions to factorizer", 3);
    
    # Show what ASTs we have in the factorizer
    fsm_debug("Factorizer now has " . scalar(@{$factorizer->{ast_expressions}}) . " AST expressions:", 3);
    for my $i (0 .. min(9, $#{$factorizer->{ast_expressions}})) { # Show first 10
        my $expr_info = $factorizer->{ast_expressions}[$i];
        my $sv = eval { $expr_info->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
        fsm_debug("  [$i] Context: $expr_info->{context}", 3);
        fsm_debug("      Expression: $sv", 3);
        fsm_debug("      AST Object: " . ref($expr_info->{ast}) . " @ " . sprintf("%p", $expr_info->{ast}), 3);
    }
    
    # STEP 2: Perform generic analysis and factorization
    fsm_debug("*** STEP 2: PERFORMING AST ANALYSIS AND FACTORIZATION ***", 3);
    fsm_debug("*** INTERMEDIATE SIGNAL CREATION DECISION TRACKING ***", 3);
    my $result = $factorizer->analyze_and_factorize();
    
    fsm_debug("Analysis results:", 3);
    fsm_debug("  Total expressions: $result->{total_expressions}", 3);
    fsm_debug("  Unique structures: $result->{unique_structures}", 3);
    fsm_debug("  Factorization candidates: $result->{factorization_candidates}", 3);
    
    # Show the intermediate signals that were generated WITH CREATION REASONING
    my $intermediate_signals = $result->{intermediate_signals};
    if (%$intermediate_signals) {
        fsm_debug("\n*** INTERMEDIATE SIGNAL CREATION DECISIONS ***", 3);
        for my $signal_name (sort keys %$intermediate_signals) {
            my $signal_info = $intermediate_signals->{$signal_name};
            my $sv = eval { $signal_info->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
            my $usage = $signal_info->{usage_count};
            my $ast_ref = sprintf("%p", $signal_info->{ast});
            
            fsm_debug("\n=== INTERMEDIATE SIGNAL CREATED: $signal_name ===", 3);
            fsm_debug("  REASON: Expression used $usage times (threshold: 2)", 3);
            fsm_debug("  EXPRESSION: $sv", 3);
            fsm_debug("  AST_OBJECT: " . ref($signal_info->{ast}) . " @ $ast_ref", 3);
            fsm_debug("  CREATED_BY: FSM::HDL::ASTFactorization->analyze_and_factorize()", 3);
            
            # Show WHERE this expression was found
            if ($signal_info->{contexts}) {
                fsm_debug("  FOUND_IN_CONTEXTS:", 3);
                for my $context (@{$signal_info->{contexts}}) {
                    fsm_debug("    - $context", 3);
                }
            }
            fsm_debug("=== END INTERMEDIATE SIGNAL: $signal_name ===", 3);
        }
    } else {
        fsm_debug("*** WARNING: NO INTERMEDIATE SIGNALS GENERATED! ***", 3);
    }
    
    # STEP 3: CRITICAL - Substitute intermediate signals back into original expressions
    fsm_debug("\n*** STEP 3: AST SUBSTITUTION PHASE ***", 3);
    fsm_debug("*** AST REPLACEMENT TRACKING - EVERY SUBSTITUTION WILL BE LOGGED ***", 3);
    my $substitution_count = $factorizer->substitute_expressions_with_intermediate_signals($factorizer->{ast_expressions});
    fsm_debug("*** AST SUBSTITUTION COMPLETE: $substitution_count expressions modified ***", 3);
    
    # Show detailed examples of substituted expressions with BEFORE/AFTER
    if ($substitution_count > 0) {
        fsm_debug("\n*** AST SUBSTITUTION RESULTS - SHOWING ALL CHANGES ***", 3);
        my $shown = 0;
        for my $expr_info (@{$factorizer->{ast_expressions}}) {
            my $sv = eval { $expr_info->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
            # Look for intermediate signal patterns - these indicate substitution occurred
            if ($sv =~ /\b\w+_and_\w+|\b\w+_or_\w+|intermediate_\d+|_expr\d*/) {
                my $context = $expr_info->{context};
                my $ast_ref = sprintf("%p", $expr_info->{ast});
                
                fsm_debug("\n--- SUBSTITUTED AST FOUND ---", 3);
                fsm_debug("  CONTEXT: $context", 3);
                fsm_debug("  AFTER_SUBSTITUTION: $sv", 3);
                fsm_debug("  AST_OBJECT_AFTER: " . ref($expr_info->{ast}) . " @ $ast_ref", 3);
                fsm_debug("  SUBSTITUTED_BY: FSM::HDL::ASTFactorization->substitute_expressions_with_intermediate_signals()", 3);
                
                # Try to identify which intermediate signals are referenced
                my @referenced_intermediates = $ctx->{enable_graph}->extract_intermediate_signals_from_ast($expr_info->{ast});
                if (@referenced_intermediates) {
                    fsm_debug("  REFERENCES_INTERMEDIATES: " . join(", ", @referenced_intermediates), 3);
                }
                fsm_debug("--- END SUBSTITUTED AST ---", 3);
                
                $shown++;
                last if $shown >= 10; # Show first 10 examples
            }
        }
        
        if ($shown == 0) {
            fsm_debug("*** WARNING: No substituted expressions found despite substitution_count = $substitution_count ***", 3);
        }
    }
    
    # STEP 4: CRITICAL FIX - Update original AST expressions with substituted versions
    fsm_debug("\n*** STEP 4: UPDATING ORIGINAL AST EXPRESSIONS WITH SUBSTITUTED VERSIONS ***", 3);
    fsm_debug("*** AST OBJECT REPLACEMENT TRACKING - EVERY UPDATE WILL BE LOGGED ***", 3);
    
    # COUNT UNARY NEGATIONS BEFORE UPDATE
    fsm_debug("\n--- BEFORE AST UPDATE: Counting unary negations in original expressions ---", 3);
    $self->count_unary_negations_in_original_expressions();

    
    my $update_count = $self->update_original_asts_with_substituted_versions($factorizer);
    fsm_debug("*** ORIGINAL AST UPDATE COMPLETE: $update_count ASTs updated ***", 3);
    
    # COUNT UNARY NEGATIONS AFTER UPDATE  
    fsm_debug("\n--- AFTER AST UPDATE: Counting unary negations in updated expressions ---", 3);
    $self->count_unary_negations_in_original_expressions();
    
    # STEP 5: FIXPOINT FACTORIZATION - Iterate on post-substitution expressions until convergence
    fsm_debug("\n*** STEP 5: FIXPOINT FACTORIZATION FOR POST-SUBSTITUTION EXPRESSIONS ***", 3);
    my $second_pass_result = $self->run_second_pass_factorization($factorizer);
    fsm_debug("*** FIXPOINT FACTORIZATION COMPLETE: " . scalar(keys %{$second_pass_result->{intermediate_signals}}) . " additional signals created across "
        . ($second_pass_result->{passes_run} // 0) . " pass(es); reason=$second_pass_result->{termination_reason} ***", 3);
    
    # Merge second-pass results into the main intermediate signals
    for my $signal_name (keys %{$second_pass_result->{intermediate_signals}}) {
        $intermediate_signals->{$signal_name} = $second_pass_result->{intermediate_signals}{$signal_name};
    }
    
    # STEP 6: Store factorizer for later lookup during HDL generation
    $ctx->{ast_factorizer} = $factorizer;
    
    fsm_debug("*** GENERIC AST FACTORIZATION COMPLETE ***", 3);
    fsm_debug("  Total expressions: $result->{total_expressions}", 3);
    fsm_debug("  Unique structures: $result->{unique_structures}", 3);
    fsm_debug("  Factorization candidates: $result->{factorization_candidates}", 3);
    fsm_debug("  Intermediate signals generated: " . scalar(keys %$intermediate_signals), 3);
    fsm_debug("  Substitution count: $substitution_count", 3);
    fsm_debug("  Original AST update count: $update_count", 3);
    fsm_debug("  Fixpoint passes run: " . ($second_pass_result->{passes_run} // 0), 3);
    fsm_debug("  Fixpoint termination reason: " . ($second_pass_result->{termination_reason} // 'unknown'), 3);
    
    return $result->{intermediate_signals};
}
sub feed_asts_to_factorizer ($self, $factorizer) {
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("FEED_ASTS: Feeding AST expressions to generic factorizer", 3);
    
    my $total_fed = 0;
    my $dt_enables_fed = 0;
    my $lhs_enables_fed = 0;
    my $assignment_conditions_fed = 0;
    
    # Feed from unified assignment analysis
    if ($ctx->{assignment_analysis}) {
        my $total_lhs = scalar(keys %{$ctx->{assignment_analysis}});
        fsm_debug("FEED_ASTS: Processing $total_lhs LHS signals from assignment analysis", 3);
        
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
            my $rhs_count = scalar(keys %{$lhs_analysis->{rhs_groups}});
            fsm_debug("  LHS '$lhs' has $rhs_count RHS groups", 3);
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                
                # Feed DT-specific enable ASTs
                my $dt_enable_count = scalar(@{$rhs_group->{dt_specific_enables} || []});
                fsm_debug("    RHS '$rhs' has $dt_enable_count DT-specific enables", 3);
                
                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast} && blessed($dt_enable->{enable_ast})) {
                        my $sv = eval { $dt_enable->{enable_ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
                        
                        $factorizer->add_ast_expression(
                            $dt_enable->{enable_ast},
                            "dt_enable:$dt_enable->{enable_name}"
                        );
                        $total_fed++;
                        $dt_enables_fed++;
                        fsm_debug("  Fed DT-specific AST: $dt_enable->{enable_name}", 3);
                        fsm_debug("    Expression: $sv", 3);
                    } else {
                        fsm_debug("  SKIPPED DT-specific enable (no AST): $dt_enable->{enable_name}", 3);
                    }
                }
                
                # Feed LHS-level enable ASTs
                if ($rhs_group->{lhs_level_enable}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    if ($lhs_enable->{ast} && blessed($lhs_enable->{ast})) {
                        my $sv = eval { $lhs_enable->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
                        
                        $factorizer->add_ast_expression(
                            $lhs_enable->{ast},
                            "lhs_enable:$lhs_enable->{name}"
                        );
                        $total_fed++;
                        $lhs_enables_fed++;
                        fsm_debug("  Fed LHS-level AST: $lhs_enable->{name}", 3);
                        fsm_debug("    Expression: $sv", 3);
                    } else {
                        fsm_debug("  SKIPPED LHS-level enable (no AST): $lhs_enable->{name}", 3);
                    }
                }
            }
        }
    } else {
        fsm_debug("*** WARNING: No assignment_analysis available for AST feeding! ***", 3);
    }
    
    # Feed from any assignments with stored ASTs
    my $total_assignments = 0;
    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        $total_assignments += scalar(@{$ctx->{lhs_assignments}{$lhs}});
    }
    
    fsm_debug("FEED_ASTS: Processing $total_assignments assignment conditions", 3);
    
    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $sv = eval { $assignment->{conditions_ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
                
                $factorizer->add_ast_expression(
                    $assignment->{conditions_ast},
                    "assignment_condition:$lhs:$assignment->{dt}"
                );
                $total_fed++;
                $assignment_conditions_fed++;
                fsm_debug("  Fed assignment condition AST: $lhs from $assignment->{dt}", 3);
                fsm_debug("    Expression: $sv", 3);
            }
        }
    }
    
    # CRITICAL FIX: Feed intermediate signals from FSMGenFull parsing
    my $fsmgen_intermediate_fed = 0;
    if ($ctx->{fsm_module} && $ctx->{fsm_module}->can('signals') && $ctx->{fsm_module}->signals) {
        fsm_debug("FEED_ASTS: Processing FSMGenFull intermediate signals", 3);
        my $fsm_signals = $ctx->{fsm_module}->signals;
        
        for my $signal_name (keys %$fsm_signals) {
            my $signal = $fsm_signals->{$signal_name};
            
            # Check if this signal has driving_ast and is marked as intermediate
            if ($signal && $signal->can('driving_ast') && $signal->driving_ast) {
                my $is_intermediate = 0;
                if ($signal->can('get_attribute')) {
                    $is_intermediate = $signal->get_attribute('is_intermediate');
                } elsif ($signal->can('attributes') && $signal->attributes) {
                    $is_intermediate = $signal->attributes->{is_intermediate};
                }
                
                # Feed intermediate signals - only based on is_intermediate flag, not naming patterns
                if ($is_intermediate) {
                    my $driving_ast = $signal->driving_ast;
                    if (blessed($driving_ast)) {
                        my $sv = eval { $driving_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
                        
                        $factorizer->add_ast_expression(
                            $driving_ast,
                            "fsmgen_intermediate:$signal_name"
                        );
                        $total_fed++;
                        $fsmgen_intermediate_fed++;
                        fsm_debug("  Fed FSMGenFull intermediate AST: $signal_name", 3);
                        fsm_debug("    Expression: $sv", 3);
                    }
                }
            }
        }
    }
    
    fsm_debug("FEED_ASTS: Fed $total_fed total AST expressions to factorizer", 3);
    fsm_debug("  - DT-specific enables: $dt_enables_fed", 3);
    fsm_debug("  - LHS-level enables: $lhs_enables_fed", 3);
    fsm_debug("  - Assignment conditions: $assignment_conditions_fed", 3);
    fsm_debug("  - FSMGenFull intermediates: $fsmgen_intermediate_fed", 3);
    
    return $total_fed;
}
sub count_unary_negations_in_original_expressions ($self) {
    my $ctx = $self->{flattened_dt};
    
    my $neg_count = 0;
    my %neg_patterns;
    
    # Check all assignment analysis expressions
    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                
                # Check DT-specific enables
                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast} && blessed($dt_enable->{enable_ast})) {
                        my $sv = eval { $dt_enable->{enable_ast}->to_systemverilog() } || "[NO SV]";
                        if ($sv =~ /!\w+/) {
                            $neg_count++;
                            $neg_patterns{$sv}++;
                            fsm_debug("    UNARY_NEG: $sv in DT enable $dt_enable->{enable_name}", 3);
                        }
                    }
                }
                
                # Check LHS-level enables
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $sv = eval { $rhs_group->{lhs_level_enable}{ast}->to_systemverilog() } || "[NO SV]";
                    if ($sv =~ /!\w+/) {
                        $neg_count++;
                        $neg_patterns{$sv}++;
                        fsm_debug("    UNARY_NEG: $sv in LHS enable $rhs_group->{lhs_level_enable}{name}", 3);
                    }
                }
            }
        }
    }
    
    fsm_debug("  Found $neg_count unary negations in expressions:", 3);
    for my $pattern (sort keys %neg_patterns) {
        fsm_debug("    '$pattern' appears $neg_patterns{$pattern} times", 3);
    }
}
sub update_original_asts_with_substituted_versions ($self, $factorizer) {
    my $ctx = $self->{flattened_dt};
    # CRITICAL FIX: Update the original AST expressions in assignment_analysis with
    # the substituted versions from the factorizer. This ensures that usage checks
    # will find intermediate signal references and not filter them out.
    
    fsm_debug("UPDATE_ORIGINAL_ASTS: Synchronizing original ASTs with substituted versions", 3);
    
    # Get the mapping of original expressions to their substituted versions
    my $ast_expressions = $factorizer->{ast_expressions};
    my $updated_count = 0;
    my $dt_ast_updates = 0;
    my $lhs_ast_updates = 0;
    my $assignment_ast_updates = 0;
    
    fsm_debug("UPDATE_ORIGINAL_ASTS: Factorizer has " . scalar(@$ast_expressions) . " AST expressions to check against");
    
    # NEW APPROACH: Build a context-to-AST mapping directly from factorizer results
    my %context_to_substituted_ast;
    for my $expr_info (@$ast_expressions) {
        my $context = $expr_info->{context};
        my $substituted_ast = $expr_info->{ast};
        $context_to_substituted_ast{$context} = $substituted_ast;
        
        my $sv = eval { $substituted_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
        fsm_debug("  Context '$context' -> AST: $sv", 3);
    }
    
    # Update ASTs in assignment_analysis structure
    if ($ctx->{assignment_analysis}) {
        fsm_debug("UPDATE_ORIGINAL_ASTS: Updating assignment_analysis structure", 3);
        
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                
                # Update DT-specific enable ASTs using context mapping
                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_name = $dt_enable_info->{enable_name};
                    my $context_key = "dt_enable:$enable_name";
                    
                    if (exists $context_to_substituted_ast{$context_key}) {
                        my $original_ast = $dt_enable_info->{enable_ast};
                        my $substituted_ast = $context_to_substituted_ast{$context_key};
                        
                        my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                        
                        $dt_enable_info->{enable_ast} = $substituted_ast;
                        $updated_count++;
                        $dt_ast_updates++;
                        
                        fsm_debug("  *** UPDATED DT-specific enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    } else {
                        fsm_debug("  No substitution found for DT enable: $dt_enable_info->{enable_name}", 3);
                    }
                }
                
                # Update LHS-level enable ASTs using context mapping
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    my $enable_name = $lhs_enable->{name};
                    my $context_key = "lhs_enable:$enable_name";
                    
                    if (exists $context_to_substituted_ast{$context_key}) {
                        my $original_ast = $lhs_enable->{ast};
                        my $substituted_ast = $context_to_substituted_ast{$context_key};
                        
                        my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                        
                        $lhs_enable->{ast} = $substituted_ast;
                        $updated_count++;
                        $lhs_ast_updates++;
                        
                        fsm_debug("  *** UPDATED LHS-level enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    } else {
                        fsm_debug("  No substitution found for LHS enable: $enable_name", 3);
                    }
                }
            }
        }
    } else {
        fsm_debug("*** WARNING: No assignment_analysis structure to update! ***", 3);
    }
    
    # Update ASTs in lhs_assignments structure using context mapping
    fsm_debug("UPDATE_ORIGINAL_ASTS: Updating lhs_assignments structure", 3);
    
    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $dt_name = $assignment->{dt};
                my $context_key = "assignment_condition:$lhs:$dt_name";
                
                if (exists $context_to_substituted_ast{$context_key}) {
                    my $original_ast = $assignment->{conditions_ast};
                    my $substituted_ast = $context_to_substituted_ast{$context_key};
                    
                    my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                    my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                    
                    $assignment->{conditions_ast} = $substituted_ast;
                    $updated_count++;
                    $assignment_ast_updates++;
                    
                    fsm_debug("  *** UPDATED assignment condition AST: $lhs from $dt_name ***", 3);
                    fsm_debug("    Original:  $original_sv", 3);
                    fsm_debug("    Updated:   $substituted_sv", 3);
                } else {
                    fsm_debug("  No substitution found for assignment condition: $lhs from $assignment->{dt}", 3);
                }
            }
        }
    }
    
    fsm_debug("UPDATE_ORIGINAL_ASTS: Updated $updated_count AST expressions with substituted versions", 3);
    fsm_debug("  - DT-specific enable updates: $dt_ast_updates", 3);
    fsm_debug("  - LHS-level enable updates: $lhs_ast_updates", 3);
    fsm_debug("  - Assignment condition updates: $assignment_ast_updates", 3);
    
    if ($updated_count == 0) {
        fsm_debug("*** WARNING: NO AST UPDATES WERE PERFORMED! This suggests the substitution/update mechanism isn't working! ***", 3);
    }
    
    return $updated_count;
}
sub run_second_pass_factorization ($self, $factorizer) {
    my $ctx = $self->{flattened_dt};
    fsm_debug("[SystemVerilog.pm][run_second_pass_factorization()] Delegating iterative post-substitution factorization to FSM::HDL::Factorization::Fixpoint", 3);
    my $factorization_fixpoint = FSM::HDL::Factorization::Fixpoint->new(flattened_dt => $ctx);
    return $factorization_fixpoint->run_post_substitution_factorization(primary_factorizer => $factorizer);
}
sub feed_current_asts_to_second_pass ($self, $second_pass_factorizer) {
    my $ctx = $self->{flattened_dt};
    # Feed the current state of all AST expressions to the second-pass factorizer
    # These expressions now contain intermediate signal references from the first pass
    
    fsm_debug("SECOND_PASS_FEED: Collecting current AST expressions", 3);
    
    my $total_fed = 0;
    
    # Feed from assignment_analysis (which should now contain substituted ASTs)
    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                
                # Feed DT-specific enable ASTs (now with intermediate signals)
                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast} && blessed($dt_enable->{enable_ast})) {
                        my $sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($dt_enable->{enable_ast}) } || "[NO SV REPRESENTATION]";
                        
                        # Only feed if the expression contains intermediate signals (signs of substitution)
                        if ($self->ast_contains_intermediate_signals($dt_enable->{enable_ast})) {
                            $second_pass_factorizer->add_ast_expression(
                                $dt_enable->{enable_ast},
                                "second_pass_dt_enable:$dt_enable->{enable_name}"
                            );
                            $total_fed++;
                            fsm_debug("  Fed second-pass DT enable: $dt_enable->{enable_name}", 3);
                            fsm_debug("    Expression: $sv", 3);
                        }
                    }
                }
                
                # Feed LHS-level enable ASTs (now with intermediate signals)
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    if (blessed($lhs_enable->{ast})) {
                        my $sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($lhs_enable->{ast}) } || "[NO SV REPRESENTATION]";
                        
                        # Only feed if the expression contains intermediate signals
                        if ($self->ast_contains_intermediate_signals($lhs_enable->{ast})) {
                            $second_pass_factorizer->add_ast_expression(
                                $lhs_enable->{ast},
                                "second_pass_lhs_enable:$lhs_enable->{name}"
                            );
                            $total_fed++;
                            fsm_debug("  Fed second-pass LHS enable: $lhs_enable->{name}", 3);
                            fsm_debug("    Expression: $sv", 3);
                        }
                    }
                }
            }
        }
    }
    
    # Feed from lhs_assignments (condition ASTs that may now have intermediate signals)
    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($assignment->{conditions_ast}) } || "[NO SV REPRESENTATION]";
                
                # Only feed if the expression contains intermediate signals
                if ($self->ast_contains_intermediate_signals($assignment->{conditions_ast})) {
                    $second_pass_factorizer->add_ast_expression(
                        $assignment->{conditions_ast},
                        "second_pass_assignment:$lhs:$assignment->{dt}"
                    );
                    $total_fed++;
                    fsm_debug("  Fed second-pass assignment condition: $lhs from $assignment->{dt}", 3);
                    fsm_debug("    Expression: $sv", 3);
                }
            }
        }
    }
    
    fsm_debug("SECOND_PASS_FEED: Fed $total_fed expressions to second-pass factorizer", 3);
    return $total_fed;
}
sub ast_contains_intermediate_signals ($self, $ast) {
    my $ctx = $self->{flattened_dt};
    # Check if an AST contains references to intermediate signals as part of COMPOUND expressions
    # CRITICAL RULE: Only compound expressions (with operators) should be considered for factorization!
    # Bare signal references should NEVER be factorized, even if they are intermediate signals.
    
    return 0 unless $ast && blessed($ast);
    
    # RULE 1: Bare signal references are NEVER factorizable, even if intermediate
    # This includes both regular signals and intermediate signals
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        # Bare signal reference - never factorize
        my $signal_name = $ctx->{enable_graph}->extract_signal_name_from_ast($ast) || 'unknown';
        my $ast_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($ast) } || 'unknown';
        fsm_debug("  SECOND_PASS_FILTER: Bare signal reference '$signal_name' (AST: $ast_sv) - NOT factorizable", 3);
        return 0;
    }
    
    # RULE 2: IntermediateSignalRef nodes are also bare signal references - never factorize
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        # Bare intermediate signal reference - never factorize
        my $signal_name = $ast->{signal_name} || 'unknown';
        my $ast_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($ast) } || 'unknown';
        fsm_debug("  SECOND_PASS_FILTER: Bare intermediate signal reference '$signal_name' (AST: $ast_sv) - NOT factorizable", 3);
        return 0;
    }
    
    # RULE 3: Only compound expressions (with operators) can contain intermediate signals worth factoring
    my $is_compound_with_intermediates = 0;
    
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # This is a compound expression with an operator - check if it contains intermediate signals
        my $left_has_intermediate = $ast->can('left') && $self->ast_has_intermediate_signals_recursive($ast->left);
        my $right_has_intermediate = $ast->can('right') && $self->ast_has_intermediate_signals_recursive($ast->right);
        
        if ($left_has_intermediate || $right_has_intermediate) {
            fsm_debug("  SECOND_PASS_FILTER: Compound binary expression contains intermediate signals - factorizable", 3);
            $is_compound_with_intermediates = 1;
        } else {
            fsm_debug("  SECOND_PASS_FILTER: Compound binary expression has no intermediate signals - not factorizable", 3);
        }
    }
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        # This is a compound expression with a unary operator - check if it contains intermediate signals
        my $operand_has_intermediate = $ast->can('operand') && $self->ast_has_intermediate_signals_recursive($ast->operand);
        
        if ($operand_has_intermediate) {
            fsm_debug("  SECOND_PASS_FILTER: Compound unary expression contains intermediate signals - factorizable", 3);
            $is_compound_with_intermediates = 1;
        } else {
            fsm_debug("  SECOND_PASS_FILTER: Compound unary expression has no intermediate signals - not factorizable", 3);
        }
    }
    else {
        # Not a compound expression (no operators) - not factorizable
        fsm_debug("  SECOND_PASS_FILTER: Not a compound expression - NOT factorizable", 3);
    }
    
    return $is_compound_with_intermediates;
}
sub ast_has_intermediate_signals_recursive ($self, $ast) {
    my $ctx = $self->{flattened_dt};
    # Helper function to recursively check if an AST contains intermediate signals
    # This is used by ast_contains_intermediate_signals to identify compound expressions
    
    return 0 unless $ast && blessed($ast);
    
    # Check if this node itself is an intermediate signal reference
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $ctx->{enable_graph}->extract_signal_name_from_ast($ast);
        if ($signal_name && $ctx->{enable_graph}->is_intermediate_signal($signal_name)) {
            return 1;
        }
    }
    
    # Check for substituted node types from factorization
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        return 1;
    }
    
    # Recursively check children
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        return 1 if $ast->can('left') && $self->ast_has_intermediate_signals_recursive($ast->left);
        return 1 if $ast->can('right') && $self->ast_has_intermediate_signals_recursive($ast->right);
    }
    elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        return 1 if $ast->can('operand') && $self->ast_has_intermediate_signals_recursive($ast->operand);
    }
    
    return 0;
}
sub update_original_asts_with_second_pass_substitutions ($self, $second_pass_factorizer) {
    my $ctx = $self->{flattened_dt};
    # Update original AST expressions with second-pass substitutions
    # This is similar to the first-pass update but for the second round of substitutions
    
    fsm_debug("UPDATE_SECOND_PASS: Updating original ASTs with second-pass substitutions", 3);
    
    my $ast_expressions = $second_pass_factorizer->{ast_expressions};
    my $updated_count = 0;
    
    # Build context-to-AST mapping from second-pass results
    my %second_pass_context_to_ast;
    for my $expr_info (@$ast_expressions) {
        my $context = $expr_info->{context};
        my $substituted_ast = $expr_info->{ast};
        $second_pass_context_to_ast{$context} = $substituted_ast;
    }
    
    # Update assignment_analysis structure with second-pass substitutions
    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                
                # Update DT-specific enables
                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_name = $dt_enable_info->{enable_name};
                    my $context_key = "second_pass_dt_enable:$enable_name";
                    
                    if (exists $second_pass_context_to_ast{$context_key}) {
                        my $original_ast = $dt_enable_info->{enable_ast};
                        my $substituted_ast = $second_pass_context_to_ast{$context_key};
                        
                        my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                        
                        $dt_enable_info->{enable_ast} = $substituted_ast;
                        $updated_count++;
                        
                        fsm_debug("  *** SECOND-PASS UPDATED DT-specific enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    }
                }
                
                # Update LHS-level enables
                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    my $enable_name = $lhs_enable->{name};
                    my $context_key = "second_pass_lhs_enable:$enable_name";
                    
                    if (exists $second_pass_context_to_ast{$context_key}) {
                        my $original_ast = $lhs_enable->{ast};
                        my $substituted_ast = $second_pass_context_to_ast{$context_key};
                        
                        my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                        
                        $lhs_enable->{ast} = $substituted_ast;
                        $updated_count++;
                        
                        fsm_debug("  *** SECOND-PASS UPDATED LHS-level enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    }
                }
            }
        }
    }
    
    # Update lhs_assignments structure
    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $dt_name = $assignment->{dt};
                my $context_key = "second_pass_assignment:$lhs:$dt_name";
                
                if (exists $second_pass_context_to_ast{$context_key}) {
                    my $original_ast = $assignment->{conditions_ast};
                    my $substituted_ast = $second_pass_context_to_ast{$context_key};
                    
                    my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                    my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
                    
                    $assignment->{conditions_ast} = $substituted_ast;
                    $updated_count++;
                    
                    fsm_debug("  *** SECOND-PASS UPDATED assignment condition AST: $lhs from $dt_name ***", 3);
                    fsm_debug("    Original:  $original_sv", 3);
                    fsm_debug("    Updated:   $substituted_sv", 3);
                }
            }
        }
    }
    
    fsm_debug("UPDATE_SECOND_PASS: Updated $updated_count AST expressions with second-pass substitutions", 3);
    return $updated_count;
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
            my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
            
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
sub scan_intermediate_signal_names_in_expression ($self, $expression) {
    my $ctx = $self->{flattened_dt};
    return () unless defined($expression) && $expression ne '';

    my @intermediate_signals;
    my @potential_signals = ($expression =~ /\b([a-zA-Z_][a-zA-Z0-9_]+)\b/g);
    my %seen;

    fsm_debug("[SystemVerilog.pm][scan_intermediate_signal_names_in_expression()] Scanning compatibility expression '$expression'", 3);

    for my $signal_name (@potential_signals) {
        next if $seen{$signal_name}++;
        next if $signal_name =~ /^(wire|reg|logic|always|assign|if|else|case|begin|end|posedge|negedge|clk|rst|reset)$/;

        if ($ctx->{enable_graph}->is_intermediate_signal($signal_name)) {
            push @intermediate_signals, $signal_name;
            fsm_debug("[SystemVerilog.pm][scan_intermediate_signal_names_in_expression()] Found intermediate signal '$signal_name'", 3);
        } else {
            fsm_debug("[SystemVerilog.pm][scan_intermediate_signal_names_in_expression()] Identifier '$signal_name' is not an intermediate signal", 3);
        }
    }

    fsm_debug("[SystemVerilog.pm][scan_intermediate_signal_names_in_expression()] Found " . scalar(@intermediate_signals) . " intermediate signal(s)", 3);
    return @intermediate_signals;
}
sub generate_wen_en_signals ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "";
    
    # UNIFIED APPROACH: Generate WEN/EN signals from Phase 1 unified data
    $hdl .= $ctx->{enable_graph}->generate_unified_wen_en_signals($fsm_module);
    
    return $hdl;
}
sub generate_intermediate_signal_declarations ($self) {
    my $ctx = $self->{flattened_dt};
    # Generate declarations for all intermediate signals that were referenced
    my $hdl = "";
    
    # Check if we have any intermediate signals to declare
    return $hdl unless $ctx->{referenced_intermediate_signals} && %{$ctx->{referenced_intermediate_signals}};
    
    $hdl .= "\n  // Intermediate signals referenced in enable expressions\n";
    
    for my $signal_name (sort keys %{$ctx->{referenced_intermediate_signals}}) {
        my $signal_info = $ctx->{referenced_intermediate_signals}->{$signal_name};
        
        # Skip if already declared
        next if $signal_info->{declared};
        
        # Get the expression for this intermediate signal
        my $expression = $ctx->{enable_graph}->get_intermediate_signal_expression($signal_name);
        if ($expression) {
            # Generate wire declaration and assign statement
            $hdl .= "  wire $signal_name;\n";
            $hdl .= "  assign $signal_name = $expression;\n";
            
            # Mark as declared
            $signal_info->{declared} = 1;
            
            fsm_debug("DECLARED_INTERMEDIATE: wire $signal_name = $expression", 3);
        } else {
            fsm_debug("WARNING: No expression found for intermediate signal: $signal_name", 3);
        }
    }
    
    # Add empty line after intermediate signals
    $hdl .= "\n" if $hdl;
    
    return $hdl;
}
sub generate_internal_signal_declarations ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my %declared_ports = %{$ctx->{declared_port_signals} || {}};
    my %signal_decls;
    my %aux_decls;
    
    my @regular_states = grep { $_->name !~ /^-/ } @{$fsm_module->states};
    my $has_state_registers = scalar(@regular_states) > 0;
    if ($has_state_registers) {
        $declared_ports{current_state} = 1;
        $declared_ports{next_state} = 1;
    }
    
    for my $lhs (sort keys %{$ctx->{assignment_analysis} || {}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
        next unless $lhs_analysis;
        
        my $width = $ctx->{enable_graph}->get_lhs_width_from_analysis($lhs_analysis);
        my $assignment_type = $ctx->{enable_graph}->get_signal_assignment_type($lhs, $lhs_analysis);
        my $multiplexer_type = $lhs_analysis->{multiplexer}->{type} || 'comb';
        
        # Declare the main LHS only when it's not already a module port/state register.
        unless ($declared_ports{$lhs}) {
            $signal_decls{$lhs} = $width;
        }
        
        # Declare mux helper registers only for flop-style multiplexers that consume them.
        if ($multiplexer_type eq 'flop' && ($assignment_type eq 'register_out' || $assignment_type eq 'register_out_dual')) {
            my $next_name = "${lhs}_next";
            $aux_decls{$next_name} = $width unless $declared_ports{$next_name};
        } elsif ($multiplexer_type eq 'flop' && ($assignment_type eq 'register_in' || $assignment_type eq 'register_in_dual')) {
            my $q_name = "${lhs}_q";
            $aux_decls{$q_name} = $width unless $declared_ports{$q_name};
        } elsif ($assignment_type eq 'pulse_delayed') {
            my $delay_cycles = $ctx->{enable_graph}->get_pulse_delay_cycles_for_lhs($lhs, $lhs_analysis);
            if ($delay_cycles > 0) {
                my $pipe_name = "${lhs}_pulse_delay_pipe";
                $aux_decls{$pipe_name} = $delay_cycles unless $declared_ports{$pipe_name};
            }
        }
    }
    
    return "" unless (%signal_decls || %aux_decls);
    
    my $hdl = "  // Internal signal declarations\n";
    for my $signal_name (sort keys %signal_decls) {
        my $width = $signal_decls{$signal_name} || 1;
        my $width_str = ($width > 1) ? "[" . ($width - 1) . ":0] " : "";
        $hdl .= "  reg ${width_str}${signal_name};\n";
    }
    
    if (%aux_decls) {
        $hdl .= "  // Internal mux helper registers\n";
        for my $signal_name (sort keys %aux_decls) {
            my $width = $aux_decls{$signal_name} || 1;
            my $width_str = ($width > 1) ? "[" . ($width - 1) . ":0] " : "";
            $hdl .= "  reg ${width_str}${signal_name};\n";
        }
    }
    $hdl .= "\n";
    
    return $hdl;
}
sub generate_comb_mux ($self, $lhs, $clean_lhs) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "  // Combinational mux for: $lhs\n";
    
    $hdl .= "  always_comb begin\n";
    $hdl .= "    $lhs = " . $ctx->{enable_graph}->get_default_value($lhs) . ";  // Default value\n";
    
    # Use the enable/value pairs passed down from LHS-Level WEN generation
    for my $pair (@{$ctx->{lhs_to_enable_value_pairs}{$lhs}}) {
        my $enable_signal_name = $pair->{enable_signal};
        my $rhs_value = $pair->{rhs_value};
        $hdl .= "    if ($enable_signal_name) begin\n";
        $hdl .= "      $lhs = $rhs_value;\n";
        $hdl .= "    end\n";
    }
    
    $hdl .= "  end\n";
    
    return $hdl;
}
sub generate_flop_mux ($self, $lhs, $clean_lhs) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "  // Flop with mux for: $lhs\n";
    
    # Generate the multiplexer logic
    $hdl .= "  always_comb begin\n";
    $hdl .= "    ${lhs}_next = " . $ctx->{enable_graph}->get_default_value($lhs) . ";  // Default value\n";
    
    # Use the enable/value pairs passed down from LHS-Level WEN generation
    for my $pair (@{$ctx->{lhs_to_enable_value_pairs}{$lhs}}) {
        my $enable_signal_name = $pair->{enable_signal};
        my $rhs_value = $pair->{rhs_value};
        $hdl .= "    if ($enable_signal_name) begin\n";
        $hdl .= "      ${lhs}_next = $rhs_value;\n";
        $hdl .= "    end\n";
    }
    
    $hdl .= "  end\n";
    
    # Generate the flop
    $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
    $hdl .= "    if (!rstn) begin\n";
    $hdl .= "      $lhs <= " . $ctx->{enable_graph}->get_reset_value($lhs) . ";\n";
    $hdl .= "    end else begin\n";
    $hdl .= "      $lhs <= ${lhs}_next;\n";
    $hdl .= "    end\n";
    $hdl .= "  end\n";
    
    return $hdl;
}

1;
