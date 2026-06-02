package FSM::HDL::ASTFactorization;

use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed refaddr);
use Digest::SHA qw(sha256_hex);
use Data::Dumper;
use FSM::Debug;

=head1 NAME

FSM::HDL::ASTFactorization - Generic AST-based expression factorization system

=head1 SYNOPSIS

    my $factorizer = FSM::HDL::ASTFactorization->new();
    
    # Add AST expressions from any FSM
    $factorizer->add_ast_expression($ast1, "enable_signal_1");
    $factorizer->add_ast_expression($ast2, "enable_signal_2");
    
    # Perform global factorization analysis
    my $factorization_result = $factorizer->analyze_and_factorize();
    
    # Re-enable intermediate signal generation
    my $hdl = $factorizer->generate_intermediate_signals($factorization_result);

=head1 DESCRIPTION

Generic AST factorization system that works with any FSM structure.
Uses pure AST structural analysis, no hardcoded signal names or FSM assumptions.

=cut

sub new {
    my ($class, %options) = @_;
    
    fsm_debug("AST-FACTOR-DEBUG: [NEW] Creating new ASTFactorization instance", 3);
    fsm_debug("AST-FACTOR-DEBUG: [NEW] Options received: " . join(", ", map { "$_ => $options{$_}" } keys %options), 3);
    
    my $self = {
        # Pure AST storage - no string keys
        ast_expressions             => [],              # Array of {ast => $obj, context => $str}
        ast_structure_map           => {},           # Maps AST structural hash -> AST info
        factorization_candidates    => {},    # Maps AST structural hash -> candidate info  
        intermediate_signals        => {},        # Maps signal_name -> {ast => $obj, ...}
        
        # Configuration
        min_usage_for_factorization => $options{min_usage_count} || 2,
        debug                       => $options{debug} || 0,
        debug_level                 => $options{debug_level} || 1,
        signal_name_prefix          => $options{signal_name_prefix} || "intermediate",
        
        # Counters for unique naming
        signal_counter              => 0,
    };
    
    fsm_debug("AST-FACTOR-DEBUG: [NEW] Configuration set: debug=@{[debug_enabled() ? 1 : 0]}, debug_level=@{[debug_level()]}, min_usage=$self->{min_usage_for_factorization}", 3);
    
    return bless $self, $class;
}

sub debug {
    my ($self, $message, $level) = @_;
    $level //= 1; # Default level is 1
    my $prefix = '  ' x ($level - 1);
    fsm_debug("AST-FACTOR-DEBUG: ${prefix}$message", 3);
}

=head2 add_ast_expression($ast, $context)

Add an AST expression to be analyzed for factorization.
Works with any AST structure - no assumptions about content.

=cut

sub add_ast_expression {
    my ($self, $ast, $context) = @_;
    
    return unless $ast && blessed($ast);
    
    # Get SystemVerilog representation for debugging
    my $sv_repr = eval { $ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
    
    push @{$self->{ast_expressions}}, {
        ast     => $ast,
        context => $context || "unknown_context"
    };
    
    fsm_debug("AST-FACTOR-DEBUG: Added AST expression from context: $context", 3);
    fsm_debug("AST-FACTOR-DEBUG:   AST type: " . ref($ast), 3);
    fsm_debug("AST-FACTOR-DEBUG:   SystemVerilog: $sv_repr", 3);
}

=head2 analyze_and_factorize()

Perform complete AST analysis and identify factorization candidates.
Returns factorization result data structure.

=cut

sub analyze_and_factorize {
    my ($self) = @_;
    
    fsm_debug("AST-FACTOR-DEBUG: Starting generic AST factorization analysis", 3);
    
    # Step 1: Build structural map of all sub-expressions
    $self->build_ast_structural_map();
    
    # Step 2: Identify factorization candidates based on usage
    $self->identify_factorization_candidates();
    
    # Step 3: Generate systematic names for candidates
    $self->generate_candidate_names();
    
    return {
        total_expressions        => scalar(@{$self->{ast_expressions}}),
        unique_structures        => scalar(keys %{$self->{ast_structure_map}}),
        factorization_candidates => scalar(keys %{$self->{factorization_candidates}}),
        intermediate_signals     => $self->{intermediate_signals}
    };
}

=head2 build_ast_structural_map()

Build map of AST structures using structural hashing.
Pure AST analysis - no string conversion dependencies.

=cut

sub build_ast_structural_map {
    my ($self) = @_;
    
    fsm_debug("AST-FACTOR-DEBUG: Building AST structural map", 3);
    
    my $total_subexpressions = 0;
    my $simple_expressions_skipped = 0;
    
    for my $expr_info (@{$self->{ast_expressions}}) {
        my $ast = $expr_info->{ast};
        my $context = $expr_info->{context};
        
        # For debugging, show the AST we're analyzing
        my $sv_repr = eval { $ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
        fsm_debug("AST-FACTOR-DEBUG:   Processing AST from context: $context", 3);
        fsm_debug("AST-FACTOR-DEBUG:     SystemVerilog: $sv_repr", 3);
        
        # Find all sub-expressions in this AST
        my @sub_expressions = $self->extract_all_sub_expressions($ast);
        $total_subexpressions += scalar(@sub_expressions);
        
        fsm_debug("AST-FACTOR-DEBUG:     Found " . scalar(@sub_expressions) . " sub-expressions", 3);
        
        for my $sub_ast (@sub_expressions) {
            # Skip simple expressions that don't need factorization
            if ($self->is_simple_expression($sub_ast)) {
                $simple_expressions_skipped++;
                next;
            }
            
            # Get structural identity for this AST
            my $structural_id = $self->get_ast_structural_id($sub_ast);
            my $sub_sv = eval { $sub_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
            
            # Enhanced debugging for unary negations during mapping phase
            if (($sub_ast->isa('FSM::AST::UnaryOp') || $sub_ast->isa('FSM::CoreAST::UnaryOp')) && $sub_ast->operator eq '!') {
                fsm_debug("AST-FACTOR-DEBUG: UNARY NEGATION MAPPING", 3);
                fsm_debug("AST-FACTOR-DEBUG:   Expression: $sub_sv", 3);
                fsm_debug("AST-FACTOR-DEBUG:   Context: $context", 3);
                fsm_debug("AST-FACTOR-DEBUG:   Structural ID: $structural_id", 3);
            }
            
            # Record this occurrence
            if (!exists $self->{ast_structure_map}{$structural_id}) {
                $self->{ast_structure_map}{$structural_id} = {
                    ast           => $sub_ast,                    # Keep reference to actual AST
                    usage_count   => 0,
                    contexts      => [],
                    structural_id => $structural_id,
                    sv_repr       => $sub_sv  # Store SystemVerilog representation for debugging
                };
                fsm_debug("AST-FACTOR-DEBUG:       New unique structure: $sub_sv (ID: $structural_id)", 3);
                
                # Extra logging for unary negations
                if (($sub_ast->isa('FSM::AST::UnaryOp') || $sub_ast->isa('FSM::CoreAST::UnaryOp')) && $sub_ast->operator eq '!') {
                    fsm_debug("AST-FACTOR-DEBUG:       *** NEW UNARY NEGATION STRUCTURE REGISTERED ***", 3);
                }
            }
            
            $self->{ast_structure_map}{$structural_id}{usage_count}++;
            push @{$self->{ast_structure_map}{$structural_id}{contexts}}, $context;
            fsm_debug("AST-FACTOR-DEBUG:     Mapped sub-expression: $sub_sv (ID: $structural_id, usage: " . 
                        $self->{ast_structure_map}{$structural_id}{usage_count} . ")", 3);
            
            # Enhanced debugging for unary negations when usage count increases
            if (($sub_ast->isa('FSM::AST::UnaryOp') || $sub_ast->isa('FSM::CoreAST::UnaryOp')) && $sub_ast->operator eq '!' && $self->{ast_structure_map}{$structural_id}{usage_count} >= 2) {
                fsm_debug("AST-FACTOR-DEBUG:     *** UNARY NEGATION ELIGIBLE FOR FACTORIZATION: usage=" . $self->{ast_structure_map}{$structural_id}{usage_count} . " ***", 3);
            }
        }
    }
    
    my $total_unique = scalar(keys %{$self->{ast_structure_map}});
    fsm_debug("AST-FACTOR-DEBUG: Found $total_unique unique AST structures (from $total_subexpressions total, skipped $simple_expressions_skipped simple ones)", 3);
    
    # Log the top used structures for easy analysis
    my @sorted_structures = sort { 
        $self->{ast_structure_map}{$b}{usage_count} <=> $self->{ast_structure_map}{$a}{usage_count} 
    } keys %{$self->{ast_structure_map}};
    
    fsm_debug("AST-FACTOR-DEBUG: Top used structures:", 3);
    my $count = 0;
    for my $struct_id (@sorted_structures) {
        last if $count >= 10; # Show top 10
        my $info = $self->{ast_structure_map}{$struct_id};
        fsm_debug("AST-FACTOR-DEBUG:   Usage " . $info->{usage_count} . ": " . $info->{sv_repr}, 3);
        $count++;
    }
}

=head2 get_ast_structural_id($ast)

Generate structural identity for an AST that is independent of specific signal names.
Uses tree structure, not string representation.

=cut

sub get_ast_structural_id {
    my ($self, $ast) = @_;
    
    return "null_ast" unless $ast && blessed($ast);
    
    # Build structural signature based on AST tree shape and operators
    my $structure_data = $self->extract_ast_structure($ast);
    
    # Create deterministic hash from structure using Data::Dumper for stable serialization
    my $dumper = Data::Dumper->new([$structure_data]);
    $dumper->Sortkeys(1);
    my $structure_string = $dumper->Dump;
    
    my $structural_id = sha256_hex($structure_string);
    
    # Enhanced debugging for unary negations to track structural ID generation
    if (($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) && $ast->operator eq '!') {
        my $ast_sv = eval { $ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
        fsm_debug("AST-FACTOR-DEBUG: UNARY NEGATION STRUCTURAL ID GENERATION", 3);
        fsm_debug("AST-FACTOR-DEBUG:   Expression: $ast_sv", 3);
        fsm_debug("AST-FACTOR-DEBUG:   Structural ID: $structural_id", 3);
        fsm_debug("AST-FACTOR-DEBUG:   Structure data: $structure_string", 3);
    }
    
    return $structural_id;
}

=head2 extract_ast_structure($ast)

Extract structural information from AST without depending on specific signal names.
Creates generic tree representation.

=cut

sub extract_ast_structure {
    my ($self, $ast) = @_;
    
    return { type => "null" } unless $ast && blessed($ast);
    
    my $ast_type = ref($ast);
    $ast_type =~ s/^.*:://;  # Remove package prefix
    
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        return {
            type     => "binary_op",
            operator => $ast->can('operator') ? ($ast->operator || "unknown_op") : "unknown_op",
            left     => $self->extract_ast_structure($ast->can('left') ? $ast->left : undef),
            right    => $self->extract_ast_structure($ast->can('right') ? $ast->right : undef),
        };
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        return {
            type     => "unary_op",
            operator => $ast->can('operator') ? ($ast->operator || "unknown_op") : "unknown_op",
            operand  => $self->extract_ast_structure($ast->can('operand') ? $ast->operand : undef),
        };
    } elsif ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        return {
            type  => "literal",
            value => $ast->can('value') ? ($ast->value || "unknown_value") : "unknown_value",
        };
    } elsif ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        # Include the actual signal name in the structural identity
        my $signal_name = $self->extract_signal_name_from_ast_node($ast) || "unknown_signal";
        return { 
            type => "signal_ref",
            signal => $signal_name  # This makes different signals have different structural IDs
        };
    } elsif ($ast->isa('FSM::CoreAST::AggregateRef')) {
        return {
            type => "aggregate_ref",
            signal => $self->extract_signal_name_from_ast_node($ast) || "unknown_signal",
            path => eval { $ast->to_systemverilog() } || "unknown_path",
        };
    } else {
        return { type => lc($ast_type) };
    }
}


=head2 extract_all_sub_expressions($ast)

Recursively extract all meaningful sub-expressions from an AST.
Generic traversal - works with any AST structure.

=cut

sub extract_all_sub_expressions {
    my ($self, $ast) = @_;
    my @sub_expressions;
    
    return @sub_expressions unless $ast && blessed($ast);
    
    # Always include the root AST itself as a sub-expression
    push @sub_expressions, $ast;
    
    # Recursively extract from child nodes based on AST type
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        if ($ast->can('left') && $ast->left) {
            push @sub_expressions, $self->extract_all_sub_expressions($ast->left);
        }
        if ($ast->can('right') && $ast->right) {
            push @sub_expressions, $self->extract_all_sub_expressions($ast->right);
        }
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        if ($ast->can('operand') && $ast->operand) {
            push @sub_expressions, $self->extract_all_sub_expressions($ast->operand);
        }
    }
    # Literals and SignalRefs are leaf nodes - no children to traverse
    
    return @sub_expressions;
}

=head2 is_simple_expression($ast)

Determine if an AST expression is too simple to warrant factorization.
Generic analysis - no hardcoded signal name assumptions.

=cut

sub is_simple_expression {
    my ($self, $ast) = @_;
    
    return 1 unless $ast && blessed($ast);
    
    # Literals are always simple
    return 1 if $ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal');
    
    # Signal references are simple
    return 1 if $ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef');
    return 1 if $ast->isa('FSM::CoreAST::AggregateRef');

    # Truthiness-style comparisons are semantically simple and should stay inline.
    return 1 if $self->is_truthiness_comparison($ast);
    
    # Everything else (binary ops, unary ops, etc.) is not simple
    return 0;
}

sub is_truthiness_comparison {
    my ($self, $ast) = @_;

    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');

    my $operator = $ast->can('operator') ? ($ast->operator || '') : '';
    return 0 unless $operator eq '==' || $operator eq '!=';

    my ($signalish_operand, $literal_operand) = $self->extract_truthiness_operands(
        $ast->can('left') ? $ast->left : undef,
        $ast->can('right') ? $ast->right : undef,
    );
    return 0 unless $signalish_operand && $literal_operand;

    my $literal_value = $self->literal_numeric_value($literal_operand);
    return 1 if defined($literal_value) && $literal_value == 0;
    return 1 if defined($literal_value) && $literal_value == 1 && $self->operand_is_single_bit($signalish_operand);
    return 0;
}

sub extract_truthiness_operands {
    my ($self, $left, $right) = @_;

    if ($self->is_truthiness_signal_operand($left) && $self->is_literal_operand($right)) {
        return ($left, $right);
    }
    if ($self->is_truthiness_signal_operand($right) && $self->is_literal_operand($left)) {
        return ($right, $left);
    }

    return;
}

sub is_truthiness_signal_operand {
    my ($self, $ast) = @_;
    return 0 unless $ast && blessed($ast);
    return 1 if $ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef');
    return 1 if $ast->isa('FSM::AST::IndexedRef') || $ast->isa('FSM::CoreAST::IndexedRef');
    return 1 if $ast->isa('FSM::CoreAST::AggregateRef');
    return 1 if $ast->isa('FSM::HDL::IntermediateSignalRef');
    return 0;
}

sub is_literal_operand {
    my ($self, $ast) = @_;
    return 0 unless $ast && blessed($ast);
    return 1 if $ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal');
    return 0;
}

sub literal_numeric_value {
    my ($self, $literal) = @_;
    return undef unless $self->is_literal_operand($literal);

    my $text = eval { $literal->to_systemverilog() };
    $text = eval { $literal->value } unless defined $text && $text ne '';
    return undef unless defined $text;

    $text =~ s/\s+//g;
    $text =~ s/_//g;

    if ($text =~ /\A(\d+)'([bdhxBDHX])([0-9a-fA-FxXzZ]+)\z/) {
        my ($radix_char, $digits) = (lc($2), $3);
        return undef if $digits =~ /[xXzZ]/;
        return oct("0b$digits") if $radix_char eq 'b';
        return 0 + $digits if $radix_char eq 'd';
        return hex($digits) if $radix_char eq 'h' || $radix_char eq 'x';
    }

    return 0 + $text if $text =~ /\A\d+\z/;
    return undef;
}

sub operand_is_single_bit {
    my ($self, $ast) = @_;
    return 0 unless $ast && blessed($ast);

    if ($ast->isa('FSM::CoreAST::IndexedRef') || $ast->isa('FSM::AST::IndexedRef')) {
        return 1;
    }

    if ($ast->isa('FSM::CoreAST::AggregateRef')) {
        my $width = eval { $ast->width };
        return defined($width) && $width == 1 ? 1 : 0;
    }

    if ($ast->isa('FSM::CoreAST::SignalRef')) {
        my $slice = eval { $ast->slice };
        if (ref($slice) eq 'ARRAY' && @$slice == 2) {
            return 1 if $slice->[0] == $slice->[1];
            return (($slice->[0] - $slice->[1]) == 0) ? 1 : 0;
        }
        my $signal = eval { $ast->signal };
        return 1 if $signal && $signal->can('width') && ($signal->width || 1) == 1;
    }

    if ($ast->isa('FSM::AST::SignalRef')) {
        return 1;
    }

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        return 1;
    }

    return 0;
}

=head2 identify_factorization_candidates()

Identify AST structures that should be factorized based on usage patterns.

=cut

sub identify_factorization_candidates {
    my ($self) = @_;
    
    fsm_debug("AST-FACTOR-DEBUG: Identifying factorization candidates", 3);
    
    my $candidate_count = 0;
    my $total_structures = scalar(keys %{$self->{ast_structure_map}});
    my $filtered_out = 0;
    
    for my $structural_id (keys %{$self->{ast_structure_map}}) {
        my $structure_info = $self->{ast_structure_map}{$structural_id};
        my $usage_count = $structure_info->{usage_count};
        my $sv_repr = $structure_info->{sv_repr} || eval { $structure_info->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
        
        # Generic rule: factor expressions used multiple times
        if ($usage_count >= $self->{min_usage_for_factorization}) {
            $self->{factorization_candidates}{$structural_id} = $structure_info;
            $candidate_count++;
            
            fsm_debug("AST-FACTOR-DEBUG: CANDIDATE ACCEPTED: usage=$usage_count, expression='$sv_repr'", 3);
            fsm_debug("AST-FACTOR-DEBUG:   Structural ID: $structural_id", 3);
            fsm_debug("AST-FACTOR-DEBUG:   Contexts: " . join(", ", @{$structure_info->{contexts}}), 3);
            
            # Special logging for unary negation candidates
            if (($structure_info->{ast}->isa('FSM::AST::UnaryOp') || $structure_info->{ast}->isa('FSM::CoreAST::UnaryOp')) && $structure_info->{ast}->operator eq '!') {
                fsm_debug("AST-FACTOR-DEBUG:   *** UNARY NEGATION CANDIDATE ACCEPTED FOR FACTORIZATION ***", 3);
            }
        } else {
            $filtered_out++;
            fsm_debug("AST-FACTOR-DEBUG:       CANDIDATE REJECTED: usage=$usage_count, expression='$sv_repr'", 3);
            
            # Special logging for rejected unary negations
            if (($structure_info->{ast}->isa('FSM::AST::UnaryOp') || $structure_info->{ast}->isa('FSM::CoreAST::UnaryOp')) && $structure_info->{ast}->operator eq '!') {
                fsm_debug("AST-FACTOR-DEBUG:       *** UNARY NEGATION CANDIDATE REJECTED: usage=$usage_count < threshold " . $self->{min_usage_for_factorization} . " ***", 3);
            }
        }
    }
    
    fsm_debug("AST-FACTOR-DEBUG: Identified $candidate_count factorization candidates (from $total_structures structures, filtered out $filtered_out)", 3);
}

=head2 generate_candidate_names()

Generate systematic names for factorization candidates.
Creates meaningful names based on AST structure.

=cut

sub generate_candidate_names {
    my ($self) = @_;
    
    fsm_debug("AST-FACTOR-DEBUG: Generating names for factorization candidates", 3);
    
    for my $structural_id (keys %{$self->{factorization_candidates}}) {
        my $candidate_info = $self->{factorization_candidates}{$structural_id};
        my $ast = $candidate_info->{ast};
        
        # Generate systematic name based on AST structure
        my $base_name = $self->generate_ast_based_name($ast);
        
        # Ensure uniqueness
        my $signal_name = $self->ensure_unique_name($base_name);
        
        # Store the intermediate signal
        $self->{intermediate_signals}{$signal_name} = {
            ast           => $ast,
            structural_id => $structural_id,
            usage_count   => $candidate_info->{usage_count},
            contexts      => _clone_factorization_value($candidate_info->{contexts} || []),
            width         => 1  # Default to 1-bit, could be made configurable
        };
        
        fsm_debug("AST-FACTOR-DEBUG: Generated signal: $signal_name (usage: $candidate_info->{usage_count})", 3);
    }
}

=head2 generate_ast_based_name($ast)

Generate systematic signal name based on AST structure.
Generic naming that works with any AST content.

=cut

sub generate_ast_based_name {
    my ($self, $ast) = @_;
    
    return "unknown_signal" unless $ast && blessed($ast);
    
    if ($self->is_truthiness_comparison($ast)) {
        my ($signalish_operand, $literal_operand) = $self->extract_truthiness_operands(
            $ast->can('left') ? $ast->left : undef,
            $ast->can('right') ? $ast->right : undef,
        );
        my $literal_value = $self->literal_numeric_value($literal_operand);
        my $signal_name = $self->generate_ast_based_name($signalish_operand);
        my $operator = $ast->can('operator') ? ($ast->operator || '') : '';

        return $signal_name
            if defined($literal_value)
            && (($literal_value == 0 && $operator eq '!=')
                || ($literal_value == 1 && $operator eq '==' && $self->operand_is_single_bit($signalish_operand)));

        return "not_${signal_name}"
            if defined($literal_value)
            && (($literal_value == 0 && $operator eq '==')
                || ($literal_value == 1 && $operator eq '!=' && $self->operand_is_single_bit($signalish_operand)));
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        my $left_name = $self->generate_ast_based_name($ast->can('left') ? $ast->left : undef) || "unknown";
        my $right_name = $self->generate_ast_based_name($ast->can('right') ? $ast->right : undef) || "unknown";
        my $op_name = $self->operator_to_name($ast->can('operator') ? ($ast->operator || "op") : "op");
        
        return "${left_name}_${op_name}_${right_name}";
        
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        my $operand_name = $self->generate_ast_based_name($ast->can('operand') ? $ast->operand : undef) || "unknown";
        my $op_name = $self->operator_to_name($ast->can('operator') ? ($ast->operator || "not") : "not");
        
        return "${op_name}_${operand_name}";
        
    } elsif ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        # Try multiple methods to extract the actual signal name
        my $signal_name = $self->extract_signal_name_from_ast_node($ast);
        return $signal_name || "unknown_sig";
    } elsif ($ast->isa('FSM::CoreAST::AggregateRef')) {
        my $aggregate_name = eval { $ast->to_systemverilog() } || "aggregate_ref";
        $aggregate_name =~ s/[^a-zA-Z0-9_]+/_/g;
        $aggregate_name =~ s/^_+|_+$//g;
        return $aggregate_name || "aggregate_ref";
    } elsif ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        my $val = $ast->can('value') ? $ast->value : "lit";
        $val =~ s/[^a-zA-Z0-9_]//g; # basic sanitization
        return "const_$val";
    } elsif ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        # Handle intermediate signal references created during substitution
        my $signal_name = $ast->{signal_name} || "unknown_intermediate";
        return $signal_name;
    } else {
        my $type_name = ref($ast);
        $type_name =~ s/^.*:://;
        return lc($type_name) . "_expr";
    }
}

sub operator_to_name {
    my ($self, $op) = @_;
    my %op_map = (
        '&&' => 'and', '&' => 'and',
        '||' => 'or',  '|' => 'or',
        '==' => 'eq',  '!=' => 'ne',
        '!'  => 'not', '~'  => 'not',
        '+'  => 'plus', '-'  => 'minus',
        '*'  => 'mul', '/'  => 'div',
        '<'  => 'lt',  '>'  => 'gt',
        '<=' => 'le',  '>=' => 'ge',
    );
    return $op_map{$op} || 'op';
}

=head2 extract_signal_name_from_ast_node($ast)

Extract the actual signal name from an AST signal reference node.
Tries multiple methods to handle different AST node structures.

=cut

sub extract_signal_name_from_ast_node {
    my ($self, $ast) = @_;
    
    return undef unless $ast && blessed($ast);
    
    fsm_debug("AST-FACTOR-DEBUG:       EXTRACT_SIGNAL_NAME: Analyzing AST node: " . ref($ast), 3);
    
    # Method 1: Direct name attribute
    if ($ast->can('name') && defined($ast->name)) {
        my $name = $ast->name;
        fsm_debug("AST-FACTOR-DEBUG:         Found name via ->name(): '$name'", 3);
        return $name;
    }
    
    # Method 2: signal_name attribute
    if ($ast->can('signal_name') && defined($ast->signal_name)) {
        my $name = $ast->signal_name;
        fsm_debug("AST-FACTOR-DEBUG:         Found name via ->signal_name(): '$name'", 3);
        return $name;
    }
    
    # Method 3: signal->name chain
    if ($ast->can('signal') && $ast->signal && blessed($ast->signal)) {
        if ($ast->signal->can('name') && defined($ast->signal->name)) {
            my $name = $ast->signal->name;
            fsm_debug("AST-FACTOR-DEBUG:         Found name via ->signal->name(): '$name'", 3);
            return $name;
        }
    }
    
    # Method 4: Extract from SystemVerilog representation
    my $sv_repr = eval { $ast->to_systemverilog() };
    if ($sv_repr && $sv_repr =~ /^([a-zA-Z_][a-zA-Z0-9_]*)$/) {
        my $name = $1;
        fsm_debug("AST-FACTOR-DEBUG:         Extracted name from SystemVerilog: '$name'", 3);
        return $name;
    }
    
    # Method 5: Check if this is an intermediate signal reference (our own creation)
    if ($ast->isa('FSM::HDL::IntermediateSignalRef') && $ast->{signal_name}) {
        my $name = $ast->{signal_name};
        fsm_debug("AST-FACTOR-DEBUG:         Found intermediate signal name: '$name'", 3);
        return $name;
    }
    
    # Method 6: Debug all available methods and try to find something useful
    my @available_methods = grep { $ast->can($_) } qw(name signal_name signal value operator left right operand);
    fsm_debug("AST-FACTOR-DEBUG:         Available methods: " . join(", ", @available_methods), 3);
    
    # Try to dump the object structure for debugging
    if (debug_level() >= 3) {
        my $dumper = Data::Dumper->new([$ast]);
        $dumper->Maxdepth(2);
        fsm_debug("AST-FACTOR-DEBUG:         AST structure: " . $dumper->Dump, 3);
    }
    
    fsm_warn("AST-FACTOR-DEBUG: Could not extract signal name from AST node");
    return undef;
}

sub ensure_unique_name {
    my ($self, $base_name) = @_;
    my $final_name = $base_name;
    my $i = 0;
    while (exists $self->{intermediate_signals}{$final_name}) {
        $i++;
        $final_name = "${base_name}_${i}";
    }
    return $final_name;
}

sub _clone_factorization_value {
    my ($value) = @_;
    return undef unless defined $value;
    return $value if blessed($value);

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone_factorization_value($value->{$_}) } sort keys %{$value}
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone_factorization_value($_) } @{$value} ];
    }

    return $value;
}

=head2 substitute_expressions_with_intermediate_signals()

Substitute factorized sub-expressions with references to intermediate signals.
This is the critical step that replaces complex expressions with intermediate signal references.
Uses multi-pass iterative approach to handle intermediate signals that reference other intermediate signals.

=cut

sub substitute_expressions_with_intermediate_signals {
    my ($self, $ast_expressions) = @_;
    
    fsm_debug("AST-FACTOR-DEBUG: Starting multi-pass AST substitution phase", 3);
    
    # Create a reverse lookup: structural_id -> signal_name
    my %structural_id_to_signal;
    for my $signal_name (keys %{$self->{intermediate_signals}}) {
        my $signal_info = $self->{intermediate_signals}{$signal_name};
        my $structural_id = $signal_info->{structural_id};
        $structural_id_to_signal{$structural_id} = $signal_name;
        
        my $sv_repr = $signal_info->{sv_repr} || eval { $signal_info->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
        fsm_debug("AST-FACTOR-DEBUG:   Intermediate signal for substitution: $signal_name = $sv_repr", 3);
        fsm_debug("AST-FACTOR-DEBUG:     Structural ID: $structural_id", 3);
        
        # Special tracking for negation signals
        if ($signal_name =~ /^not_/) {
            fsm_debug("AST-FACTOR-DEBUG:     NEGATION SIGNAL: $signal_name (id: $structural_id)", 3);
        }
    }
    
    # Debug structural ID lookup table
    fsm_debug("AST-FACTOR-DEBUG: Structural ID lookup table:", 3);
    my @negation_signals = grep { $_ =~ /^not_/ } values %structural_id_to_signal;
    fsm_debug("AST-FACTOR-DEBUG:   Negation signals available: " . (@negation_signals ? join(", ", @negation_signals) : "None"), 3);
    
    fsm_debug("AST-FACTOR-DEBUG: Preparing to substitute with " . scalar(keys %{$self->{intermediate_signals}}) . " intermediate signals", 3);
    
    # Debug: Show all intermediate signals and their expressions BEFORE substitution
    fsm_debug("AST-FACTOR-DEBUG: BEFORE multi-pass substitution:", 3);
    for my $sig_name (sort keys %{$self->{intermediate_signals}}) {
        my $sig_info = $self->{intermediate_signals}{$sig_name};
        my $expr = eval { $sig_info->{ast}->to_systemverilog() } || "[NO SV]";
        fsm_debug("  INTERMEDIATE SIGNAL MAP: $sig_name = $expr (usage: " . ($sig_info->{usage_count} || 0) . ")", 3);
    }
    
    # Multi-pass substitution with convergence
    my $total_substitution_count = 0;
    my $pass_number = 1;
    my $max_passes = 10; # Safety limit to prevent infinite loops
    
    while ($pass_number <= $max_passes) {
        fsm_debug("AST-FACTOR-DEBUG: === SUBSTITUTION PASS $pass_number ===", 3);
        
        my $pass_substitution_count = $self->perform_single_substitution_pass(
            $ast_expressions, \%structural_id_to_signal, $pass_number
        );
        
        $total_substitution_count += $pass_substitution_count;
        fsm_debug("AST-FACTOR-DEBUG: Pass $pass_number complete: $pass_substitution_count substitutions made", 3);
        
        # Check for convergence
        if ($pass_substitution_count == 0) {
            fsm_debug("AST-FACTOR-DEBUG: CONVERGENCE REACHED after $pass_number passes", 3);
            last;
        }
        
        $pass_number++;
    }
    
    if ($pass_number > $max_passes) {
        fsm_warn("AST-FACTOR-DEBUG: Maximum passes ($max_passes) reached without convergence");
    }
    
    # Debug: Show all intermediate signals and their expressions AFTER substitution
    fsm_debug("AST-FACTOR-DEBUG: AFTER multi-pass substitution:", 3);
    for my $sig_name (sort keys %{$self->{intermediate_signals}}) {
        my $sig_info = $self->{intermediate_signals}{$sig_name};
        my $expr = eval { $sig_info->{ast}->to_systemverilog() } || "[NO SV]";
        fsm_debug("  FINAL INTERMEDIATE SIGNAL: $sig_name = $expr (usage: " . ($sig_info->{usage_count} || 0) . ")", 3);
    }
    
    fsm_debug("AST-FACTOR-DEBUG: Multi-pass AST substitution complete: $total_substitution_count total substitutions across " . ($pass_number - 1) . " passes", 3);
    return $total_substitution_count;
}

=head2 perform_single_substitution_pass($ast_expressions, $structural_id_to_signal, $pass_number)

Perform a single pass of substitution on both WEN/EN expressions and intermediate signal expressions.
Returns the number of substitutions made in this pass.

=cut

sub perform_single_substitution_pass {
    my ($self, $ast_expressions, $structural_id_to_signal, $pass_number) = @_;
    
    my $substitution_count = 0;
    
    # Phase 1: Substitute in WEN/EN expressions (original approach)
    fsm_debug("AST-FACTOR-DEBUG: Pass $pass_number Phase 1: Substituting WEN/EN expressions", 3);
    for my $expr_info (@$ast_expressions) {
        my $original_ast = $expr_info->{ast};
        my $context = $expr_info->{context};
        
        my $original_sv = eval { $original_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
        
        # Perform substitution on this AST
        my $substituted_ast = $self->substitute_ast_recursively(
            $original_ast, 
            $structural_id_to_signal
        );
        
        if ($substituted_ast != $original_ast) {
            $expr_info->{ast} = $substituted_ast;
            $substitution_count++;
            
            my $substituted_sv = eval { $substituted_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
            fsm_debug("AST-FACTOR-DEBUG: Pass $pass_number WEN/EN SUBSTITUTION in context: $context", 3);
            fsm_debug("AST-FACTOR-DEBUG:   Original:   $original_sv", 3);
            fsm_debug("AST-FACTOR-DEBUG:   Substituted: $substituted_sv", 3);
        }
    }
    
    # Phase 2: Substitute in intermediate signal expressions (NEW approach)
    fsm_debug("AST-FACTOR-DEBUG: Pass $pass_number Phase 2: Substituting intermediate signal expressions", 3);
    for my $signal_name (keys %{$self->{intermediate_signals}}) {
        my $signal_info = $self->{intermediate_signals}{$signal_name};
        my $original_ast = $signal_info->{ast};
        
        my $original_sv = eval { $original_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
        
        # CRITICAL FIX: Pass the current signal name to prevent self-reference
        # Perform substitution on this intermediate signal's AST
        my $substituted_ast = $self->substitute_ast_recursively(
            $original_ast, 
            $structural_id_to_signal,
            $signal_name  # Pass current signal name to prevent self-substitution
        );
        
        if ($substituted_ast != $original_ast) {
            $signal_info->{ast} = $substituted_ast;
            $substitution_count++;
            
            my $substituted_sv = eval { $substituted_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
            fsm_debug("AST-FACTOR-DEBUG: Pass $pass_number INTERMEDIATE SUBSTITUTION: $signal_name", 3);
            fsm_debug("AST-FACTOR-DEBUG:   Original:   $original_sv", 3);
            fsm_debug("AST-FACTOR-DEBUG:   Substituted: $substituted_sv", 3);
        } else {
            fsm_debug("AST-FACTOR-DEBUG: Pass $pass_number INTERMEDIATE NO-CHANGE: $signal_name (preserved to avoid self-reference)", 3);
            fsm_debug("AST-FACTOR-DEBUG:   Expression: $original_sv", 3);
        }
    }
    
    fsm_debug("AST-FACTOR-DEBUG: Pass $pass_number complete: $substitution_count total substitutions (WEN/EN + intermediates)", 3);
    return $substitution_count;
}

=head2 substitute_ast_recursively($ast, $structural_id_to_signal)

Recursively substitute sub-expressions in an AST with intermediate signal references.

=cut

sub substitute_ast_recursively {
    my ($self, $ast, $structural_id_to_signal, $current_signal_name) = @_;
    
    return $ast unless $ast && blessed($ast);
    
    # Get SystemVerilog representation for debugging
    my $ast_sv = eval { $ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
    fsm_debug("AST-FACTOR-DEBUG:       Examining for substitution: $ast_sv", 3);
    
    # Check if this entire AST should be replaced with an intermediate signal
    my $structural_id = $self->get_ast_structural_id($ast);
    
    # Special debug for unary negations
    if (($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) && $ast->operator eq '!') {
        fsm_debug("AST-FACTOR-DEBUG:     UNARY NEGATION CHECK: $ast_sv (structural_id: $structural_id)", 3);
        fsm_debug("AST-FACTOR-DEBUG:       Available intermediate signals for substitution:", 3);
        for my $sid (keys %$structural_id_to_signal) {
            my $sig_name = $structural_id_to_signal->{$sid};
            if ($sig_name =~ /^not_/) {
                fsm_debug("AST-FACTOR-DEBUG:         $sig_name (id: $sid)", 3);
            }
        }
        if (exists $structural_id_to_signal->{$structural_id}) {
            fsm_debug("AST-FACTOR-DEBUG:       FOUND MATCH for unary negation!", 3);
        } else {
            fsm_debug("AST-FACTOR-DEBUG:       NO MATCH for unary negation structural_id: $structural_id", 3);
        }
    }
    
    if (exists $structural_id_to_signal->{$structural_id}) {
        my $signal_name = $structural_id_to_signal->{$structural_id};
        
        # CRITICAL FIX: Prevent self-reference in intermediate signal definitions
        # If we're processing an intermediate signal's own AST, do not substitute it with itself
        if ($current_signal_name && $current_signal_name eq $signal_name) {
            fsm_debug("AST-FACTOR-DEBUG:     PREVENTING SELF-SUBSTITUTION: Signal '$signal_name' would reference itself - skipping substitution", 3);
            fsm_debug("AST-FACTOR-DEBUG:       Original: $ast_sv (preserved to avoid self-reference)", 3);
            # Continue with recursive substitution of children instead of substituting the whole AST
        } else {
            fsm_debug("AST-FACTOR-DEBUG:     SUBSTITUTING AST with intermediate signal: $signal_name", 3);
            fsm_debug("AST-FACTOR-DEBUG:       Original: $ast_sv", 3);
            
            # Create a new SignalRef AST node pointing to the intermediate signal
            my $new_node = $self->create_signal_ref_ast($signal_name);
            my $new_sv = eval { $new_node->to_systemverilog() } || "[NO SV REPRESENTATION]";
            fsm_debug("AST-FACTOR-DEBUG:       Replacement: $new_sv", 3);
            return $new_node;
        }
    }
    
    # Recursively substitute in child nodes
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        my $left_original = $ast->can('left') ? $ast->left : undef;
        my $right_original = $ast->can('right') ? $ast->right : undef;
        
        my $left_substituted = $self->substitute_ast_recursively($left_original, $structural_id_to_signal);
        my $right_substituted = $self->substitute_ast_recursively($right_original, $structural_id_to_signal);
        
        # If any child was substituted, create a new AST node
        if ($left_substituted != $left_original || $right_substituted != $right_original) {
            fsm_debug("AST-FACTOR-DEBUG:       SUBSTITUTING children in binary op: " . $ast->operator, 3);
            
            my $new_node = $self->create_binary_op_ast($ast->operator, $left_substituted, $right_substituted);
            my $new_sv = eval { $new_node->to_systemverilog() } || "[NO SV REPRESENTATION]";
            fsm_debug("AST-FACTOR-DEBUG:         Original: $ast_sv", 3);
            fsm_debug("AST-FACTOR-DEBUG:         With substituted children: $new_sv", 3);
            return $new_node;
        }
        
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        my $operand_original = $ast->can('operand') ? $ast->operand : undef;
        my $operand_substituted = $self->substitute_ast_recursively($operand_original, $structural_id_to_signal);
        
        # If operand was substituted, create a new AST node
        if ($operand_substituted != $operand_original) {
            fsm_debug("AST-FACTOR-DEBUG:       SUBSTITUTING operand in unary op: " . $ast->operator, 3);
            
            my $new_node = $self->create_unary_op_ast($ast->operator, $operand_substituted);
            my $new_sv = eval { $new_node->to_systemverilog() } || "[NO SV REPRESENTATION]";
            fsm_debug("AST-FACTOR-DEBUG:         Original: $ast_sv", 3);
            fsm_debug("AST-FACTOR-DEBUG:         With substituted operand: $new_sv", 3);
            return $new_node;
        }
    }
    
    # No substitution needed - return original AST
    return $ast;
}

=head2 create_signal_ref_ast($signal_name)

Create a new SignalRef AST node for an intermediate signal.

=cut

sub create_signal_ref_ast {
    my ($self, $signal_name) = @_;
    
    # This is a simplified implementation - in a real system, you'd need to
    # create a proper Signal object and SignalRef AST node
    # For now, we'll create a generic representation that can be converted to SystemVerilog

    return FSM::HDL::IntermediateSignalRef->new(signal_name => $signal_name);
}

=head2 create_binary_op_ast($operator, $left, $right)

Create a new BinaryOp AST node with substituted children.

=cut

sub create_binary_op_ast {
    my ($self, $operator, $left, $right) = @_;

    return FSM::HDL::SubstitutedBinaryOp->new(
        operator => $operator,
        left => $left,
        right => $right,
    );
}

=head2 create_unary_op_ast($operator, $operand)

Create a new UnaryOp AST node with substituted operand.

=cut

sub create_unary_op_ast {
    my ($self, $operator, $operand) = @_;

    return FSM::HDL::SubstitutedUnaryOp->new(
        operator => $operator,
        operand => $operand,
    );
}

# Proper AST classes for intermediate signals
package FSM::AST::IntermediateSignal;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);

sub new {
    my ($class, %args) = @_;

    my $name = defined($args{name}) && $args{name} ne ''
        ? $args{name}
        : Carp::confess("IntermediateSignal requires name");
    my $original_expression = $args{original_expression}
        || Carp::confess("IntermediateSignal requires original_expression");

    return bless {
        name => $name,
        original_expression => $original_expression,
        usage_count => $args{usage_count} || 0,
        contexts => _clone_intermediate_signal_value($args{contexts} || []),
        signal_type => $args{signal_type} || "wire",
        width => $args{width} || 1,
        structural_id => $args{structural_id},
        is_intermediate => 1,  # Mark this as an intermediate signal
    }, $class;
}

# AST interface compatibility
sub name { return shift->{name}; }
sub signal_name { return shift->{name}; }
sub original_expression { return shift->{original_expression}; }
sub usage_count { return shift->{usage_count}; }
sub contexts {
    my $contexts = _clone_intermediate_signal_value(shift->{contexts} || []);
    return @{$contexts};
}
sub is_intermediate { return 1; }

# SystemVerilog generation - ONLY place strings are used
sub to_systemverilog { return shift->{name}; }

# For debugging and analysis
sub debug_info {
    my $self = shift;
    return {
        name => $self->{name},
        usage_count => $self->{usage_count},
        contexts => _clone_intermediate_signal_value($self->{contexts} || []),
        original_sv => eval { $self->{original_expression}->to_systemverilog() } || "[ERROR]"
    };
}

sub _clone_intermediate_signal_value {
    my ($value) = @_;
    return undef unless defined $value;
    return $value if blessed($value);

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone_intermediate_signal_value($value->{$_}) } sort keys %{$value}
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone_intermediate_signal_value($_) } @{$value} ];
    }

    return $value;
}

package FSM::HDL::SubstitutedBinaryOp;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);

sub new {
    my ($class, %args) = @_;

    my $operator = defined($args{operator}) && $args{operator} ne ''
        ? $args{operator}
        : Carp::confess("SubstitutedBinaryOp requires operator");
    my $left = $args{left}
        || Carp::confess("SubstitutedBinaryOp requires left");
    my $right = $args{right}
        || Carp::confess("SubstitutedBinaryOp requires right");

    return bless {
        operator => $operator,
        left => $left,
        right => $right,
        type => 'binary_op'
    }, $class;
}

# AST interface compatibility
sub operator { return shift->{operator}; }
sub left { return shift->{left}; }
sub right { return shift->{right}; }

sub to_systemverilog {
    my $self = shift;
    my $left_sv = blessed($self->{left}) && $self->{left}->can('to_systemverilog') 
        ? $self->{left}->to_systemverilog() : $self->{left};
    my $right_sv = blessed($self->{right}) && $self->{right}->can('to_systemverilog') 
        ? $self->{right}->to_systemverilog() : $self->{right};
    return "($left_sv $self->{operator} $right_sv)";
}

package FSM::HDL::SubstitutedUnaryOp;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);

sub new {
    my ($class, %args) = @_;

    my $operator = defined($args{operator}) && $args{operator} ne ''
        ? $args{operator}
        : Carp::confess("SubstitutedUnaryOp requires operator");
    my $operand = $args{operand}
        || Carp::confess("SubstitutedUnaryOp requires operand");

    return bless {
        operator => $operator,
        operand => $operand,
        type => 'unary_op'
    }, $class;
}

# AST interface compatibility  
sub operator { return shift->{operator}; }
sub operand { return shift->{operand}; }

sub to_systemverilog {
    my $self = shift;
    my $operand_sv = blessed($self->{operand}) && $self->{operand}->can('to_systemverilog') 
        ? $self->{operand}->to_systemverilog() : $self->{operand};
    return "$self->{operator}$operand_sv";
}

package FSM::HDL::IntermediateSignalRef;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);

# This represents a reference to an intermediate signal
# It's designed to be compatible with the existing AST signal reference classes
sub new {
    my ($class, %args) = @_;

    my $signal_name = defined($args{signal_name}) && $args{signal_name} ne ''
        ? $args{signal_name}
        : Carp::confess("IntermediateSignalRef requires signal_name");

    return bless {
        signal_name => $signal_name,
        type => 'intermediate_signal_ref'
    }, $class;
}

# AST interface compatibility
sub name { return shift->{signal_name}; }
sub signal_name { return shift->{signal_name}; }

# SystemVerilog generation
sub to_systemverilog { 
    my $self = shift;
    return $self->{signal_name}; 
}

# Mark this as a signal reference for AST traversal
sub isa {
    my ($self, $class) = @_;
    return 1 if $class eq 'FSM::AST::SignalRef' || $class eq 'FSM::CoreAST::SignalRef';
    return $self->SUPER::isa($class) if ref($self) && $self->can('SUPER::isa');
    return UNIVERSAL::isa($self, $class);
}

package FSM::HDL::ASTFactorization;

1;
