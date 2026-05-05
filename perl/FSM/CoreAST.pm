package FSM::CoreAST;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Scalar::Util qw(blessed);
use FSM::Package::IntegerLiteralSupport;

# FSM Core AST - Semantic Foundation for Decision Tree FSMs
# Format-agnostic, semantically complete representation

#=============================================================================
# Core Signal System
#=============================================================================

package FSM::CoreAST::Signal;
    sub new($class, %args) {
        my $final_width = $args{width} // 1;
        
        # Construct hash step by step to avoid Perl hash construction issues with undef values
        my $hash_to_bless = {};
        $hash_to_bless->{name} = $args{name} // Carp::confess "Signal name required";
        $hash_to_bless->{_width} = $final_width;
        $hash_to_bless->{type} = $args{type} // 'wire';
        $hash_to_bless->{signed} = ($args{signed} // 0) ? 1 : 0;
        $hash_to_bless->{state_model} = $args{state_model};
        $hash_to_bless->{declared_type_name} = $args{declared_type_name};
        $hash_to_bless->{declared_type_spec} = _clone_structured_value($args{declared_type_spec});
        $hash_to_bless->{clock_domain} = $args{clock_domain};
        $hash_to_bless->{reset_domain} = $args{reset_domain};
        $hash_to_bless->{attributes} = $args{attributes} // {};
        $hash_to_bless->{constraints} = $args{constraints} // {};
        
        # FANIN CONE: Every signal has a driving AST expression
        # This is the core of the signal-AST relationship
        $hash_to_bless->{driving_ast} = $args{driving_ast};  # The AST expression that drives this signal
        $hash_to_bless->{fanout_signals} = $args{fanout_signals} // [];  # Signals this drives (for traversing forward)
        
        my $self = bless $hash_to_bless, $class;
        
        return $self;
    }
    
    sub name($self) { $self->{name} }
    sub width($self) { $self->{_width} }
    sub type($self) { $self->{type} }
    sub signed($self) { $self->{signed} }
    sub state_model($self) { $self->{state_model} }
    sub declared_type_name($self) { $self->{declared_type_name} }
    sub declared_type_spec($self) { return _clone_structured_value($self->{declared_type_spec}) }
    sub clock_domain($self) { $self->{clock_domain} }
    sub reset_domain($self) { $self->{reset_domain} }
    sub attributes($self) { $self->{attributes} }
    sub constraints($self) { $self->{constraints} }
    
    sub is_vector($self) { $self->{_width} > 1 }
    sub is_clock($self) { $self->{type} eq 'clock' }
    sub is_reset($self) { $self->{type} eq 'reset' }
    
    sub set_attribute($self, $key, $value) {
        if (defined($key) && $key eq 'driving_ast') {
            $self->{attributes}{$key} = $value;
            $self->set_driving_ast($value);
            return $value;
        }
        $self->{attributes}{$key} = $value;
        return $value;
    }
    sub get_attribute($self, $key) {
        if (defined($key) && $key eq 'driving_ast') {
            return $self->{driving_ast} if defined $self->{driving_ast};
        }
        return $self->{attributes}{$key};
    }
    
    sub add_constraint($self, $constraint) { push $self->{constraints}->@*, $constraint }
    
    # FANIN CONE ACCESS: Core signal-AST relationship methods
    sub driving_ast($self) { $self->{driving_ast} }
    sub fanout_signals($self) { $self->{fanout_signals} // [] }
    
    sub set_driving_ast($self, $ast) { 
        $self->{driving_ast} = $ast;
        # Update fanout for all signals in the driving AST
        $self->_update_fanout_relationships($ast) if $ast;
    }
    
    sub add_fanout_signal($self, $signal) { 
        push $self->{fanout_signals}->@*, $signal;
    }
    
    # FANIN CONE NAVIGATION: Walk up and down the AST web
    sub get_fanin_signals($self) {
        # Get all signals that feed into this signal's driving AST
        return [] unless $self->{driving_ast};
        return $self->{driving_ast}->get_signals // [];
    }
    
    sub get_fanout_signals($self) {
        # Get all signals that this signal drives
        return $self->{fanout_signals} // [];
    }
    
    # UNIFIED TEXT GENERATION: Always goes through the driving AST
    sub to_systemverilog($self) {
        return $self->{driving_ast} ? $self->{driving_ast}->to_systemverilog() : $self->name;
    }
    
    sub to_verilog($self) {
        return $self->{driving_ast} ? $self->{driving_ast}->to_verilog() : $self->name;
    }
    
    sub to_vhdl($self) {
        return $self->{driving_ast} ? $self->{driving_ast}->to_vhdl() : $self->name;
    }
    
    # Check if this is an intermediate signal (has complex driving logic)
    sub is_intermediate($self) {
        return 0 unless $self->{driving_ast};
        # Intermediate signals have AST expressions more complex than simple references
        return !$self->{driving_ast}->isa('FSM::CoreAST::SignalRef');
    }
    
    # Private method to update fanout relationships
    sub _update_fanout_relationships($self, $ast) {
        return unless $ast && $ast->can('get_signals');
        my $fanin_signals = $ast->get_signals();
        for my $fanin_signal (@$fanin_signals) {
            $fanin_signal->add_fanout_signal($self) if $fanin_signal && $fanin_signal->can('add_fanout_signal');
        }
    }

    sub _clone_structured_value($value) {
        return undef unless defined $value;

        if (ref($value) eq 'HASH') {
            return {
                map { $_ => _clone_structured_value($value->{$_}) } sort keys %$value
            };
        }

        if (ref($value) eq 'ARRAY') {
            return [ map { _clone_structured_value($_) } @$value ];
        }

        return $value;
    }

#=============================================================================
# AST Web Node System - Complete Circuit Representation
#=============================================================================

package FSM::CoreAST::ASTNode;
    # Base class for ALL nodes in the AST web (signals, gates, modules, etc.)
    sub new($class, %args) {
        my $hash_to_bless = {};
        $hash_to_bless->{node_type} = $args{node_type} // Carp::confess "AST node type required";
        $hash_to_bless->{name} = $args{name};
        $hash_to_bless->{input_ports} = $args{input_ports} // {};
        $hash_to_bless->{output_ports} = $args{output_ports} // {};
        $hash_to_bless->{attributes} = $args{attributes} // {};
        $hash_to_bless->{parent_hierarchy} = $args{parent_hierarchy};
        
        return bless $hash_to_bless, $class;
    }
    
    sub node_type($self) { $self->{node_type} }
    sub name($self) { $self->{name} }
    sub input_ports($self) { $self->{input_ports} }
    sub output_ports($self) { $self->{output_ports} }
    sub attributes($self) { $self->{attributes} }
    sub parent_hierarchy($self) { $self->{parent_hierarchy} }
    
    # AST WEB NAVIGATION: Core traversal methods
    sub get_fanin_nodes($self) { 
        # Get all nodes that feed into this node's inputs
        my @fanin_nodes;
        for my $port_name (keys %{$self->{input_ports}}) {
            my $port = $self->{input_ports}{$port_name};
            push @fanin_nodes, $port->get_driving_node() if $port->can('get_driving_node');
        }
        return \@fanin_nodes;
    }
    
    sub get_fanout_nodes($self) {
        # Get all nodes that this node's outputs drive
        my @fanout_nodes;
        for my $port_name (keys %{$self->{output_ports}}) {
            my $port = $self->{output_ports}{$port_name};
            push @fanout_nodes, $port->get_driven_nodes() if $port->can('get_driven_nodes');
        }
        return \@fanout_nodes;
    }
    
    # PORT NAVIGATION: Left/Right traversal within the same node
    sub get_related_ports($self, $port_name) {
        # Override in subclasses to define port relationships (e.g., flop: q ↔ d, q ↔ clk)
        return [];
    }
    
    # Override in subclasses
    sub to_verilog($self) { Carp::confess "to_verilog() must be implemented by subclass" }
    sub to_vhdl($self) { Carp::confess "to_vhdl() must be implemented by subclass" }
    sub to_systemverilog($self) { return $self->to_verilog() }

#=============================================================================
# Primary Gate Nodes (AND, OR, XOR, +, -, *, etc.)
#=============================================================================

package FSM::CoreAST::PrimaryGate;
    our @ISA = qw(FSM::CoreAST::ASTNode);
    
    sub new($class, %args) {
        my $gate_type = $args{gate_type} // Carp::confess "Gate type required";
        
        # Create input/output port structure based on gate type
        my ($input_ports, $output_ports) = $class->_create_gate_ports($gate_type, %args);
        
        my $self = $class->SUPER::new(
            node_type => 'primary_gate',
            name => $args{name} // "${gate_type}_gate",
            input_ports => $input_ports,
            output_ports => $output_ports,
            %args
        );
        $self->{gate_type} = $gate_type;
        
        return $self;
    }
    
    sub gate_type($self) { $self->{gate_type} }
    
    sub _create_gate_ports($class, $gate_type, %args) {
        my $input_ports = {};
        my $output_ports = {};
        
        if ($gate_type =~ /^(and|or|xor|nand|nor|xnor)$/i) {
            # Logic gates: variable inputs, single output
            my $input_count = $args{input_count} // 2;
            for my $i (0 .. $input_count - 1) {
                $input_ports->{"in$i"} = FSM::CoreAST::Port->new(name => "in$i", direction => 'input');
            }
            $output_ports->{out} = FSM::CoreAST::Port->new(name => 'out', direction => 'output');
            
        } elsif ($gate_type =~ /^(add|sub|mul|div)$/i) {
            # Arithmetic gates: typically 2 inputs, 1 output  
            $input_ports->{a} = FSM::CoreAST::Port->new(name => 'a', direction => 'input');
            $input_ports->{b} = FSM::CoreAST::Port->new(name => 'b', direction => 'input');
            $output_ports->{out} = FSM::CoreAST::Port->new(name => 'out', direction => 'output');
            
        } elsif ($gate_type eq 'not') {
            # Inverter: 1 input, 1 output
            $input_ports->{in} = FSM::CoreAST::Port->new(name => 'in', direction => 'input');
            $output_ports->{out} = FSM::CoreAST::Port->new(name => 'out', direction => 'output');
        }
        
        return ($input_ports, $output_ports);
    }
    
    sub to_systemverilog($self) {
        my $gate_type = $self->{gate_type};
        my $output_name = $self->{output_ports}{out}->get_connected_signal_name() || 'unknown_out';
        
        if ($gate_type =~ /^(and|or|xor|nand|nor|xnor)$/) {
            my @input_names;
            for my $port_name (sort keys %{$self->{input_ports}}) {
                my $port = $self->{input_ports}{$port_name};
                push @input_names, $port->get_connected_signal_name() || 'unknown_in';
            }
            my $op = $gate_type eq 'and' ? '&' : $gate_type eq 'or' ? '|' : "^";
            return "assign $output_name = " . join(" $op ", @input_names) . ";";
            
        } elsif ($gate_type eq 'not') {
            my $input_name = $self->{input_ports}{in}->get_connected_signal_name() || 'unknown_in';
            return "assign $output_name = !$input_name;";
        }
        
        return "// Unknown gate type: $gate_type";
    }

#=============================================================================
# Sequential Element Nodes (Flops, Latches)
#=============================================================================

package FSM::CoreAST::SequentialElement;
    our @ISA = qw(FSM::CoreAST::ASTNode);
    
    sub new($class, %args) {
        my $seq_type = $args{seq_type} // 'dff';  # dff, latch, etc.
        
        # Create sequential element ports
        my ($input_ports, $output_ports) = $class->_create_seq_ports($seq_type, %args);
        
        my $self = $class->SUPER::new(
            node_type => 'sequential_element',
            name => $args{name} // "${seq_type}_element",
            input_ports => $input_ports,
            output_ports => $output_ports,
            %args
        );
        $self->{seq_type} = $seq_type;
        
        return $self;
    }
    
    sub seq_type($self) { $self->{seq_type} }
    
    sub _create_seq_ports($class, $seq_type, %args) {
        my $input_ports = {};
        my $output_ports = {};
        
        if ($seq_type eq 'dff') {
            # D Flip-Flop: d, clk, rst_n → q
            $input_ports->{d} = FSM::CoreAST::Port->new(name => 'd', direction => 'input', port_type => 'data');
            $input_ports->{clk} = FSM::CoreAST::Port->new(name => 'clk', direction => 'input', port_type => 'clock');
            $input_ports->{rst_n} = FSM::CoreAST::Port->new(name => 'rst_n', direction => 'input', port_type => 'reset');
            $output_ports->{q} = FSM::CoreAST::Port->new(name => 'q', direction => 'output', port_type => 'data');
        }
        
        return ($input_ports, $output_ports);
    }
    
    # PORT RELATIONSHIPS: q ↔ d, q ↔ clk, q ↔ rst_n
    sub get_related_ports($self, $port_name) {
        if ($self->{seq_type} eq 'dff') {
            if ($port_name eq 'q') {
                return [qw(d clk rst_n)];  # From q, you can navigate to d, clk, rst_n
            } elsif ($port_name =~ /^(d|clk|rst_n)$/) {
                return ['q'];  # From any input, you can navigate to q
            }
        }
        return [];
    }
    
    sub to_systemverilog($self) {
        if ($self->{seq_type} eq 'dff') {
            my $q_name = $self->{output_ports}{q}->get_connected_signal_name() || 'unknown_q';
            my $d_name = $self->{input_ports}{d}->get_connected_signal_name() || 'unknown_d';
            my $clk_name = $self->{input_ports}{clk}->get_connected_signal_name() || 'clk';
            my $rst_name = $self->{input_ports}{rst_n}->get_connected_signal_name() || 'rst_n';
            
            return "always_ff @(posedge $clk_name or negedge $rst_name) begin\n" .
                   "    if (!$rst_name) $q_name <= 1'b0;\n" .
                   "    else $q_name <= $d_name;\n" .
                   "end";
        }
        return "// Unknown sequential type: $self->{seq_type}";
    }

#=============================================================================
# User-Defined Block Nodes (Modules, Entities)
#=============================================================================

package FSM::CoreAST::UserDefinedBlock;
    our @ISA = qw(FSM::CoreAST::ASTNode);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(
            node_type => 'user_defined_block',
            name => $args{name} // Carp::confess("User-defined block name required"),
            input_ports => $args{input_ports} // {},
            output_ports => $args{output_ports} // {},
            %args
        );
        
        $self->{block_type} = $args{block_type} // 'module';  # module, entity, etc.
        $self->{internal_nodes} = $args{internal_nodes} // [];  # AST nodes inside this block
        
        return $self;
    }
    
    sub block_type($self) { $self->{block_type} }
    sub internal_nodes($self) { $self->{internal_nodes} }
    
    # HIERARCHICAL NAVIGATION: Into/out of user-defined blocks
    sub get_internal_nodes($self) { return $self->{internal_nodes} }
    
    sub add_internal_node($self, $node) {
        push $self->{internal_nodes}->@*, $node;
        $node->{parent_hierarchy} = $self if $node->can('parent_hierarchy');
    }
    
    sub to_systemverilog($self) {
        my $name = $self->name;
        my $hdl = "module $name (\n";
        
        # Add ports
        my @port_decls;
        for my $port_name (sort keys %{$self->{input_ports}}) {
            push @port_decls, "  input wire $port_name";
        }
        for my $port_name (sort keys %{$self->{output_ports}}) {
            push @port_decls, "  output wire $port_name";
        }
        $hdl .= join(",\n", @port_decls) . "\n);\n\n";
        
        # Add internal logic
        for my $node (@{$self->{internal_nodes}}) {
            $hdl .= "  " . $node->to_systemverilog() . "\n" if $node->can('to_systemverilog');
        }
        
        $hdl .= "endmodule\n";
        return $hdl;
    }

#=============================================================================
# Port System - Connection Points Between AST Nodes  
#=============================================================================

package FSM::CoreAST::Port;
    sub new($class, %args) {
        bless {
            name => $args{name} // Carp::confess("Port name required"),
            direction => $args{direction} // Carp::confess("Port direction required"),
            port_type => $args{port_type} // 'data',  # data, clock, reset, etc.
            width => $args{width} // 1,
            connected_signal => $args{connected_signal},
            driving_node => $args{driving_node},
            driven_nodes => $args{driven_nodes} // [],
        }, $class;
    }
    
    sub name($self) { $self->{name} }
    sub direction($self) { $self->{direction} }
    sub port_type($self) { $self->{port_type} }
    sub width($self) { $self->{width} }
    
    # CONNECTION MANAGEMENT
    sub connect_signal($self, $signal) { $self->{connected_signal} = $signal }
    sub get_connected_signal($self) { $self->{connected_signal} }
    sub get_connected_signal_name($self) { 
        return $self->{connected_signal} ? $self->{connected_signal}->name : undef;
    }
    
    # DRIVING RELATIONSHIPS
    sub set_driving_node($self, $node) { $self->{driving_node} = $node }
    sub get_driving_node($self) { $self->{driving_node} }
    
    sub add_driven_node($self, $node) { push $self->{driven_nodes}->@*, $node }
    sub get_driven_nodes($self) { $self->{driven_nodes} }

#=============================================================================
# Expression System (Now part of the larger AST web)
#=============================================================================

package FSM::CoreAST::Expression;
    # Base class for all expressions (conditions, values, operations)
    sub new($class, %args) {
        # Construct hash step by step to avoid Perl hash construction issues with undef values
        my $hash_to_bless = {};
        $hash_to_bless->{type} = $args{type} // Carp::confess "Expression type required";
        $hash_to_bless->{operands} = $args{operands} // [];
        $hash_to_bless->{attributes} = $args{attributes} // {};
        
        return bless $hash_to_bless, $class;
    }
    
    sub type($self) { $self->{type} }
    sub operands($self) { $self->{operands} }
    sub attributes($self) { $self->{attributes} }
    
    # Override in subclasses
    sub evaluate($self, $context) { Carp::confess "evaluate() must be implemented by subclass" }
    sub get_signals($self) { [] }
    sub to_verilog($self) { Carp::confess "to_verilog() must be implemented by subclass" }
    sub to_vhdl($self) { Carp::confess "to_vhdl() must be implemented by subclass" }
    sub to_systemverilog($self) { 
        # Default implementation falls back to Verilog
        return $self->to_verilog();
    }

package FSM::CoreAST::SignalRef;
    our @ISA = qw(FSM::CoreAST::Expression);
    
    sub new($class, $signal, %args) {
        my $self = $class->SUPER::new(type => 'signal_ref', %args);
        $self->{signal} = $signal;
        $self->{slice} = $args{slice};  # [high, low] or undef for full signal
        return $self;
    }
    
    sub signal($self) { $self->{signal} }
    sub slice($self) { $self->{slice} }
    sub name($self) { 
        # Convenience method for HDL generators - delegate to signal's name
        return $self->{signal} && $self->{signal}->can('name') ? 
            $self->{signal}->name : 
            (defined $self->{signal} ? "unnamed_signal" : "null_signal");
    }
    
    sub get_signals($self) { [$self->{signal}] }
    
    sub to_verilog($self) {
        my $name = $self->{signal}->name;
        return $self->{slice} ? "$name\[$self->{slice}[0]:$self->{slice}[1]\]" : $name;
    }
    
    sub to_vhdl($self) {
        my $name = $self->{signal}->name;
        return $self->{slice} ? "$name($self->{slice}[0] downto $self->{slice}[1])" : $name;
    }
    
    sub to_systemverilog($self) {
        return $self->to_verilog();
    }

package FSM::CoreAST::ParameterRef;
    our @ISA = qw(FSM::CoreAST::Expression);

    sub new($class, $name, %args) {
        Carp::confess "Parameter reference name required"
            unless defined($name) && !ref($name) && length($name);

        my $value_info = _clone_parameter_ref_value($args{value_info});
        my $self = $class->SUPER::new(type => 'parameter_ref', %args);
        $self->{name} = $name;
        $self->{value_info} = $value_info;
        $self->{width} = $args{width};
        $self->{type_spec} = _clone_parameter_ref_value($args{type_spec});
        $self->{type_spec} //= _clone_parameter_ref_value($value_info->{value_type_spec})
            if ref($value_info) eq 'HASH' && ref($value_info->{value_type_spec}) eq 'HASH';
        $self->{default_value_text} = $args{default_value_text};
        $self->{default_value_text} //= $value_info->{value_text}
            if ref($value_info) eq 'HASH' && defined $value_info->{value_text};
        return $self;
    }

    sub name($self) { $self->{name} }
    sub width($self) { $self->{width} }
    sub type_spec($self) { _clone_parameter_ref_value($self->{type_spec}) }
    sub value_info($self) { _clone_parameter_ref_value($self->{value_info}) }
    sub default_value_text($self) { $self->{default_value_text} }
    sub get_signals($self) { [] }
    sub to_verilog($self) { $self->{name} }
    sub to_systemverilog($self) { $self->{name} }
    sub to_vhdl($self) { $self->{name} }

    sub _clone_parameter_ref_value($value) {
        return undef unless defined $value;

        if (ref($value) eq 'HASH') {
            return {
                map { $_ => _clone_parameter_ref_value($value->{$_}) } sort keys %$value
            };
        }

        if (ref($value) eq 'ARRAY') {
            return [ map { _clone_parameter_ref_value($_) } @$value ];
        }

        return $value;
    }

package FSM::CoreAST::Literal;
    our @ISA = qw(FSM::CoreAST::Expression);
    
    sub new($class, $value, %args) {
        my $self = $class->SUPER::new(type => 'literal', %args);
        $self->{value} = $value;
        $self->{width} = $args{width};
        $self->{radix} = $args{radix} // 'decimal';  # binary, decimal, hex
        return $self;
    }
    
    sub value($self) { $self->{value} }
    sub width($self) { $self->{width} }
    sub radix($self) { $self->{radix} }
    
    sub to_verilog($self) {
        my $normalized = FSM::Package::IntegerLiteralSupport->systemverilog_literal_from_literal_like($self);
        return $normalized if defined $normalized;

        my $v = $self->{value};
        if (defined $self->{width}) {
            return $self->{radix} eq 'hex' ? "$self->{width}'h$v" :
                   $self->{radix} eq 'binary' ? "$self->{width}'b$v" :
                   $self->{radix} eq 'octal' ? "$self->{width}'o$v" :
                   "$self->{width}'d$v";
        }
        return $v;
    }
    
    sub to_vhdl($self) {
        my $v = $self->{value};
        if (defined $self->{width}) {
            return $self->{radix} eq 'hex' ? "x\"$v\"" :
                   $self->{radix} eq 'binary' ? "\"$v\"" :
                   $self->{radix} eq 'octal' ? $v :
                   $v;
        }
        return $v;
    }
    
    sub to_systemverilog($self) {
        my $normalized = FSM::Package::IntegerLiteralSupport->systemverilog_literal_from_literal_like($self);
        return $normalized if defined $normalized;

        my $v = $self->{value};
        if (defined $self->{width}) {
            return $self->{radix} eq 'hex' ? "$self->{width}'h$v" :
                   $self->{radix} eq 'binary' ? "$self->{width}'b$v" :
                   $self->{radix} eq 'octal' ? "$self->{width}'o$v" :
                   "$self->{width}'d$v";
        }
        return $v;
    }

package FSM::CoreAST::BinaryOp;
    our @ISA = qw(FSM::CoreAST::Expression);
    
    # Extensible operator registry - can be extended at runtime
    # Higher precedence numbers mean higher precedence (evaluated first)
    # Precedence values are language-specific
    our %OPERATOR_REGISTRY = (
        # Logical operators (boolean logic)
        '&&'  => { 
            verilog => '&&', vhdl => 'and', 
            verilog_precedence => 2, vhdl_precedence => 2, systemverilog_precedence => 2,
            associative => 1, commutative => 1 
        },
        '||'  => { 
            verilog => '||', vhdl => 'or', 
            verilog_precedence => 1, vhdl_precedence => 1, systemverilog_precedence => 1,
            associative => 1, commutative => 1 
        },
        
        # Bitwise operators
        'and' => { 
            verilog => '&', vhdl => 'and', 
            verilog_precedence => 4, vhdl_precedence => 4, systemverilog_precedence => 4,
            associative => 1, commutative => 1 
        },
        '&'   => { 
            verilog => '&', vhdl => 'and', 
            verilog_precedence => 4, vhdl_precedence => 4, systemverilog_precedence => 4,
            associative => 1, commutative => 1 
        },
        'or'  => { 
            verilog => '|', vhdl => 'or', 
            verilog_precedence => 3, vhdl_precedence => 3, systemverilog_precedence => 3,
            associative => 1, commutative => 1 
        },
        '|'   => { 
            verilog => '|', vhdl => 'or', 
            verilog_precedence => 3, vhdl_precedence => 3, systemverilog_precedence => 3,
            associative => 1, commutative => 1 
        },
        'xor' => { 
            verilog => '^', vhdl => 'xor', 
            verilog_precedence => 4, vhdl_precedence => 4, systemverilog_precedence => 4,
            associative => 1, commutative => 1 
        },
        '^'   => { 
            verilog => '^', vhdl => 'xor', 
            verilog_precedence => 4, vhdl_precedence => 4, systemverilog_precedence => 4,
            associative => 1, commutative => 1 
        },
        'xnor'=> { 
            verilog => '~^', vhdl => 'xnor', 
            verilog_precedence => 4, vhdl_precedence => 4, systemverilog_precedence => 4,
            associative => 1, commutative => 1 
        },
        'nand'=> { 
            verilog => '~&', vhdl => 'nand', 
            verilog_precedence => 4, vhdl_precedence => 4, systemverilog_precedence => 4,
            associative => 1, commutative => 1 
        },
        'nor' => { 
            verilog => '~|', vhdl => 'nor', 
            verilog_precedence => 4, vhdl_precedence => 4, systemverilog_precedence => 4,
            associative => 1, commutative => 1 
        },
        
        # Comparison operators (lower precedence than bitwise)
        'eq' => { 
            verilog => '==', vhdl => '=', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 1 
        },
        '==' => { 
            verilog => '==', vhdl => '=', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 1 
        },
        'ne' => { 
            verilog => '!=', vhdl => '/=', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 1 
        },
        '!=' => { 
            verilog => '!=', vhdl => '/=', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 1 
        },
        'lt' => { 
            verilog => '<', vhdl => '<', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 0 
        },
        '<'  => { 
            verilog => '<', vhdl => '<', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 0 
        },
        'le' => { 
            verilog => '<=', vhdl => '<=', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 0 
        },
        'gt' => { 
            verilog => '>', vhdl => '>', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 0 
        },
        '>'  => { 
            verilog => '>', vhdl => '>', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 0 
        },
        'ge' => { 
            verilog => '>=', vhdl => '>=', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 0 
        },
        '>=' => { 
            verilog => '>=', vhdl => '>=', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 0 
        },
        
        # Arithmetic operators
        'add' => { 
            verilog => '+', vhdl => '+', 
            verilog_precedence => 6, vhdl_precedence => 6, systemverilog_precedence => 6,
            associative => 1, commutative => 1 
        },
        '+' => {
            verilog => '+', vhdl => '+',
            verilog_precedence => 6, vhdl_precedence => 6, systemverilog_precedence => 6,
            associative => 1, commutative => 1
        },
        'sub' => { 
            verilog => '-', vhdl => '-', 
            verilog_precedence => 6, vhdl_precedence => 6, systemverilog_precedence => 6,
            associative => 0, commutative => 0 
        },
        '-' => {
            verilog => '-', vhdl => '-',
            verilog_precedence => 6, vhdl_precedence => 6, systemverilog_precedence => 6,
            associative => 0, commutative => 0
        },
        'mul' => { 
            verilog => '*', vhdl => '*', 
            verilog_precedence => 7, vhdl_precedence => 7, systemverilog_precedence => 7,
            associative => 1, commutative => 1 
        },
        '*' => {
            verilog => '*', vhdl => '*',
            verilog_precedence => 7, vhdl_precedence => 7, systemverilog_precedence => 7,
            associative => 1, commutative => 1
        },
        'div' => { 
            verilog => '/', vhdl => '/', 
            verilog_precedence => 7, vhdl_precedence => 7, systemverilog_precedence => 7,
            associative => 0, commutative => 0 
        },
        '/' => {
            verilog => '/', vhdl => '/',
            verilog_precedence => 7, vhdl_precedence => 7, systemverilog_precedence => 7,
            associative => 0, commutative => 0
        },
        'mod' => { 
            verilog => '%', vhdl => 'mod', 
            verilog_precedence => 7, vhdl_precedence => 7, systemverilog_precedence => 7,
            associative => 0, commutative => 0 
        },
        '%' => {
            verilog => '%', vhdl => 'mod',
            verilog_precedence => 7, vhdl_precedence => 7, systemverilog_precedence => 7,
            associative => 0, commutative => 0
        },
        
        # Shift operators
        'shl' => { 
            verilog => '<<', vhdl => 'sll', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 0 
        },
        'shr' => { 
            verilog => '>>', vhdl => 'srl', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 0 
        },
        'sal' => { 
            verilog => '<<<', vhdl => 'sla', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 0 
        },
        'sar' => { 
            verilog => '>>>', vhdl => 'sra', 
            verilog_precedence => 5, vhdl_precedence => 5, systemverilog_precedence => 5,
            associative => 0, commutative => 0 
        },
        
        # Bitwise concatenation
        'concat' => { 
            verilog => '', vhdl => '&', 
            verilog_precedence => 8, vhdl_precedence => 8, systemverilog_precedence => 8,
            associative => 1, commutative => 0 
        },
    );
    
    sub new($class, $operator, $left, $right, %args) {
        my $self = $class->SUPER::new(type => 'binary_op', operands => [$left, $right], %args);
        $self->{operator} = $operator;
        return $self;
    }
    
    # Class methods for operator registry management
    sub register_operator($class, $name, %properties) {
        $OPERATOR_REGISTRY{$name} = \%properties;
    }
    
    sub get_operator_info($class, $operator) {
        return $OPERATOR_REGISTRY{$operator};
    }
    
    sub is_commutative($class, $operator) {
        my $info = $OPERATOR_REGISTRY{$operator};
        return $info ? $info->{commutative} : 0;
    }
    
    sub operator($self) { $self->{operator} }
    sub left($self) { $self->{operands}[0] }
    sub right($self) { $self->{operands}[1] }
    
    sub get_signals($self) {
        my @signals;
        push @signals, $self->left->get_signals->@* if $self->left && $self->left->can('get_signals');
        push @signals, $self->right->get_signals->@* if $self->right && $self->right->can('get_signals');
        return \@signals;
    }
    
    sub to_verilog($self, $parent_precedence = undef) {
        my $op_info = $OPERATOR_REGISTRY{$self->{operator}};
        my $op_symbol = $op_info ? $op_info->{verilog} : $self->{operator};
        my $my_precedence = $op_info ? $op_info->{verilog_precedence} : undef;
        
        my $left_verilog = $self->_render_child_with_precedence($self->left, 'to_verilog', $my_precedence);
        my $right_verilog = $self->_render_child_with_precedence($self->right, 'to_verilog', $my_precedence);
        
        # Special handling for concatenation
        if ($self->{operator} eq 'concat') {
            return "{$left_verilog, $right_verilog}";
        }

        if ($self->_right_child_needs_same_precedence_parentheses('verilog')) {
            $right_verilog = "($right_verilog)";
        }
        
        # Generate the expression
        my $expr = "$left_verilog $op_symbol $right_verilog";
        
        # Only add parentheses if this operator has lower precedence than its parent
        # or if we have no precedence information (safe default)
        if (defined($parent_precedence) && defined($my_precedence) && 
            $my_precedence >= $parent_precedence) {
            # This operation has higher or equal precedence to parent - no parens needed
            return $expr;
        } elsif (!defined($parent_precedence)) {
            # Top level expression - no parens needed
            return $expr;
        } else {
            # This operation has lower precedence - needs parentheses
            return "($expr)";
        }
    }
    
    sub to_vhdl($self, $parent_precedence = undef) {
        my $op_info = $OPERATOR_REGISTRY{$self->{operator}};
        my $op_symbol = $op_info ? $op_info->{vhdl} : $self->{operator};
        my $my_precedence = $op_info ? $op_info->{vhdl_precedence} : undef;
        
        my $left_vhdl = $self->_render_child_with_precedence($self->left, 'to_vhdl', $my_precedence);
        my $right_vhdl = $self->_render_child_with_precedence($self->right, 'to_vhdl', $my_precedence);
        
        # Special handling for concatenation (VHDL uses & operator)
        if ($self->{operator} eq 'concat') {
            return "($left_vhdl & $right_vhdl)";
        }

        if ($self->_right_child_needs_same_precedence_parentheses('vhdl')) {
            $right_vhdl = "($right_vhdl)";
        }
        
        # Generate the expression
        my $expr = "$left_vhdl $op_symbol $right_vhdl";
        
        # Only add parentheses if this operator has lower precedence than its parent
        # or if we have no precedence information (safe default)
        if (defined($parent_precedence) && defined($my_precedence) && 
            $my_precedence >= $parent_precedence) {
            # This operation has higher or equal precedence to parent - no parens needed
            return $expr;
        } elsif (!defined($parent_precedence)) {
            # Top level expression - no parens needed
            return $expr;
        } else {
            # This operation has lower precedence - needs parentheses
            return "($expr)";
        }
    }
    
    sub to_systemverilog($self, $parent_precedence = undef) {
        my $op_info = $OPERATOR_REGISTRY{$self->{operator}};
        my $op_symbol = $op_info ? $op_info->{verilog} : $self->{operator};
        my $my_precedence = $op_info ? $op_info->{systemverilog_precedence} : undef;
        
        my $left_sv = $self->_render_child_with_precedence($self->left, 'to_systemverilog', $my_precedence);
        my $right_sv = $self->_render_child_with_precedence($self->right, 'to_systemverilog', $my_precedence);
        
        # Special handling for concatenation
        if ($self->{operator} eq 'concat') {
            return "{$left_sv, $right_sv}";
        }

        if ($self->_right_child_needs_same_precedence_parentheses('systemverilog')) {
            $right_sv = "($right_sv)";
        }
        
        # Generate the expression
        my $expr = "$left_sv $op_symbol $right_sv";
        
        # Only add parentheses if this operator has lower precedence than its parent
        # or if we have no precedence information (safe default)
        if (defined($parent_precedence) && defined($my_precedence) && 
            $my_precedence >= $parent_precedence) {
            # This operation has higher or equal precedence to parent - no parens needed
            return $expr;
        } elsif (!defined($parent_precedence)) {
            # Top level expression - no parens needed
            return $expr;
        } else {
            # This operation has lower precedence - needs parentheses
            return "($expr)";
        }
    }

    sub _right_child_needs_same_precedence_parentheses($self, $language) {
        my $right = $self->right;
        return 0 unless Scalar::Util::blessed($right) && $right->isa('FSM::CoreAST::BinaryOp');

        my $parent_info = $OPERATOR_REGISTRY{$self->{operator}};
        my $child_info = $OPERATOR_REGISTRY{$right->operator};
        return 0 unless $parent_info && $child_info;

        my $precedence_key = $language . '_precedence';
        my $parent_precedence = $parent_info->{$precedence_key};
        my $child_precedence = $child_info->{$precedence_key};
        return 0 unless defined($parent_precedence) && defined($child_precedence);
        return 0 unless $parent_precedence == $child_precedence;

        my $symbol_key = $language eq 'vhdl' ? 'vhdl' : 'verilog';
        my $parent_symbol = $parent_info->{$symbol_key} // $self->{operator};
        my $child_symbol = $child_info->{$symbol_key} // $right->operator;

        return 0 if $parent_symbol eq $child_symbol
            && $parent_info->{associative}
            && $child_info->{associative};

        return 1;
    }

    sub _render_child_with_precedence($self, $child, $method, $parent_precedence) {
        return '0' unless $child && $child->can($method);
        return $child->$method($parent_precedence)
            if Scalar::Util::blessed($child) && $child->isa('FSM::CoreAST::BinaryOp');
        return $child->$method();
    }

package FSM::CoreAST::UnaryOp;
    our @ISA = qw(FSM::CoreAST::Expression);
    
    sub new($class, %args) {
        # Handle named parameter calling style
        my $operator = $args{operator} // Carp::confess "UnaryOp operator required";
        my $operand = $args{operand} // Carp::confess "UnaryOp operand required";
        
        # Remove these from args to avoid conflicts
        delete $args{operator};
        delete $args{operand};
        
        # Create the object with operands properly set
        my $self = $class->SUPER::new(
            type => 'unary_op',
            operands => [$operand],
            %args
        );
        $self->{operator} = $operator;
        return $self;
    }
    
    sub operator($self) { $self->{operator} }
    sub operand($self) { $self->{operands}[0] }
    
    sub get_signals($self) { 
        return $self->operand && $self->operand->can('get_signals') ? 
               $self->operand->get_signals : [];
    }
    
    sub to_verilog($self) {
        my $op_map = { 'not' => '~', 'neg' => '-', 'pos' => '+' };
        my $op = $op_map->{$self->{operator}} // $self->{operator};
        my $operand_verilog = $self->operand && $self->operand->can('to_verilog') ? 
                             $self->operand->to_verilog : '0';
        return "$op($operand_verilog)";
    }
    
    sub to_vhdl($self) {
        my $op_map = { 'not' => 'not ', 'neg' => '-', 'pos' => '+' };
        my $op = $op_map->{$self->{operator}} // $self->{operator};
        my $operand_vhdl = $self->operand && $self->operand->can('to_vhdl') ? 
                           $self->operand->to_vhdl : '0';
        return "$op($operand_vhdl)";
    }
    
    sub to_systemverilog($self) {
        my $op_map = { 'not' => '~', 'neg' => '-', 'pos' => '+' };
        my $op = $op_map->{$self->{operator}} // $self->{operator};
        my $operand_sv = $self->operand && $self->operand->can('to_systemverilog') ? 
                         $self->operand->to_systemverilog : '0';
        return "$op($operand_sv)";
    }

# Concatenation Expression: {a, b, c, ...}
package FSM::CoreAST::Concatenation;
    our @ISA = qw(FSM::CoreAST::Expression);
    
    sub new($class, @operands) {
        my $self = $class->SUPER::new(type => 'concatenation', operands => \@operands);
        return $self;
    }
    
    sub get_signals($self) {
        my @signals;
        for my $operand ($self->{operands}->@*) {
            push @signals, $operand->get_signals->@* if $operand && $operand->can('get_signals');
        }
        return \@signals;
    }
    
    sub to_verilog($self) {
        my @operand_strings = map { 
            $_ && $_->can('to_verilog') ? $_->to_verilog : '0' 
        } $self->{operands}->@*;
        return '{' . join(', ', @operand_strings) . '}';
    }
    
    sub to_vhdl($self) {
        my @operand_strings = map { 
            $_ && $_->can('to_vhdl') ? $_->to_vhdl : '0' 
        } $self->{operands}->@*;
        return '(' . join(' & ', @operand_strings) . ')';
    }
    
    sub to_systemverilog($self) {
        my @operand_strings = map { 
            $_ && $_->can('to_systemverilog') ? $_->to_systemverilog : '0' 
        } $self->{operands}->@*;
        return '{' . join(', ', @operand_strings) . '}';
    }

# Indexed Reference: signal[index]
package FSM::CoreAST::IndexedRef;
    our @ISA = qw(FSM::CoreAST::Expression);
    
    sub new($class, $signal, $index, %args) {
        my $self = $class->SUPER::new(type => 'indexed_ref', %args);
        $self->{signal} = $signal;
        $self->{index} = $index;  # Can be literal or expression
        return $self;
    }
    
    sub signal($self) { $self->{signal} }
    sub index($self) { $self->{index} }
    
    sub get_signals($self) { 
        my @signals = ($self->{signal});
        push @signals, $self->{index}->get_signals->@* 
            if ref($self->{index}) && $self->{index}->can('get_signals');
        return \@signals;
    }
    
    sub to_verilog($self) {
        my $signal_name = $self->{signal}->name;
        my $index_str = ref($self->{index}) ? $self->{index}->to_verilog : $self->{index};
        return "${signal_name}[${index_str}]";
    }
    
    sub to_vhdl($self) {
        my $signal_name = $self->{signal}->name;
        my $index_str = ref($self->{index}) ? $self->{index}->to_vhdl : $self->{index};
        return "${signal_name}(${index_str})";
    }
    
    sub to_systemverilog($self) {
        my $signal_name = $self->{signal}->name;
        my $index_str = ref($self->{index}) ? $self->{index}->to_systemverilog : $self->{index};
        return "${signal_name}[${index_str}]";
    }

# Aggregate Reference: signal.member / signal.item_N / signal.member[index]
package FSM::CoreAST::AggregateRef;
    our @ISA = qw(FSM::CoreAST::Expression);

    sub new($class, $signal, $path, %args) {
        Carp::confess "AggregateRef requires a signal" unless $signal;
        Carp::confess "AggregateRef requires a non-empty aggregate path"
            unless ref($path) eq 'ARRAY' && @$path;

        my $self = $class->SUPER::new(type => 'aggregate_ref', %args);
        $self->{signal} = $signal;
        $self->{path} = _clone_structured_value($path);
        $self->{type_spec} = _clone_structured_value($args{type_spec});
        $self->{width} = $args{width};
        return $self;
    }

    sub signal($self) { $self->{signal} }
    sub path($self) { _clone_structured_value($self->{path}) }
    sub type_spec($self) { _clone_structured_value($self->{type_spec}) }
    sub width($self) { $self->{width} }

    sub get_signals($self) { [$self->{signal}] }

    sub to_verilog($self) {
        return $self->_render_reference('sv');
    }

    sub to_systemverilog($self) {
        return $self->_render_reference('sv');
    }

    sub to_vhdl($self) {
        return $self->_render_reference('vhdl');
    }

    sub _render_reference($self, $language) {
        my $expr = $self->{signal}->name;
        for my $segment (@{$self->{path}}) {
            my $kind = $segment->{kind} || '';
            if ($kind eq 'member') {
                $expr .= "." . $segment->{name};
            } elsif ($kind eq 'item') {
                $expr .= "." . $self->_render_item_field_name($segment->{index});
            } elsif ($kind eq 'bit_index') {
                my $index = $segment->{index};
                $expr .= $language eq 'vhdl' ? "($index)" : "[$index]";
            } elsif ($kind eq 'bit_slice') {
                my ($high, $low) = ($segment->{high}, $segment->{low});
                $expr .= $language eq 'vhdl' ? "($high downto $low)" : "[$high:$low]";
            } else {
                Carp::confess "Unsupported AggregateRef path segment kind '$kind'";
            }
        }
        return $expr;
    }

    sub _render_item_field_name($self, $index) {
        Carp::confess "AggregateRef list item requires a numeric index"
            unless defined($index) && $index =~ /^\d+$/;
        return "item_$index";
    }

    sub _clone_structured_value($value) {
        return undef unless defined $value;

        if (ref($value) eq 'HASH') {
            return {
                map { $_ => _clone_structured_value($value->{$_}) } sort keys %$value
            };
        }

        if (ref($value) eq 'ARRAY') {
            return [ map { _clone_structured_value($_) } @$value ];
        }

        return $value;
    }

# Conditional Expression: condition ? true_val : false_val
package FSM::CoreAST::ConditionalExpression;
    our @ISA = qw(FSM::CoreAST::Expression);
    
    sub new($class, $condition, $true_expr, $false_expr, %args) {
        my $self = $class->SUPER::new(type => 'conditional', %args);
        $self->{condition} = $condition;
        $self->{true_expr} = $true_expr;
        $self->{false_expr} = $false_expr;
        return $self;
    }
    
    sub condition($self) { $self->{condition} }
    sub true_expr($self) { $self->{true_expr} }
    sub false_expr($self) { $self->{false_expr} }
    
    sub get_signals($self) {
        my @signals;
        push @signals, $self->{condition}->get_signals->@* if $self->{condition}->can('get_signals');
        push @signals, $self->{true_expr}->get_signals->@* if $self->{true_expr}->can('get_signals');
        push @signals, $self->{false_expr}->get_signals->@* if $self->{false_expr}->can('get_signals');
        return \@signals;
    }
    
    sub to_verilog($self) {
        my $cond = $self->{condition}->to_verilog;
        my $true_val = $self->{true_expr}->to_verilog;
        my $false_val = $self->{false_expr}->to_verilog;
        return "($cond ? $true_val : $false_val)";
    }
    
    sub to_vhdl($self) {
        my $cond = $self->{condition}->to_vhdl;
        my $true_val = $self->{true_expr}->to_vhdl;
        my $false_val = $self->{false_expr}->to_vhdl;
        return "($true_val when $cond else $false_val)";
    }
    
    sub to_systemverilog($self) {
        my $cond = $self->{condition}->to_systemverilog;
        my $true_val = $self->{true_expr}->to_systemverilog;
        my $false_val = $self->{false_expr}->to_systemverilog;
        return "($cond ? $true_val : $false_val)";
    }

# Function Call Expression: func(arg1, arg2, ...)
package FSM::CoreAST::FunctionCall;
    our @ISA = qw(FSM::CoreAST::Expression);
    
    sub new($class, $function_name, @arguments) {
        my $self = $class->SUPER::new(type => 'function_call', operands => \@arguments);
        $self->{function_name} = $function_name;
        return $self;
    }
    
    sub function_name($self) { $self->{function_name} }
    sub arguments($self) { $self->{operands} }
    
    sub get_signals($self) {
        my @signals;
        for my $arg ($self->{operands}->@*) {
            push @signals, $arg->get_signals->@* if $arg && $arg->can('get_signals');
        }
        return \@signals;
    }
    
    sub to_verilog($self) {
        my @arg_strings = map {
            $_ && $_->can('to_verilog') ? $_->to_verilog : '0'
        } $self->{operands}->@*;
        return $self->{function_name} . '(' . join(', ', @arg_strings) . ')';
    }
    
    sub to_vhdl($self) {
        my @arg_strings = map {
            $_ && $_->can('to_vhdl') ? $_->to_vhdl : '0'
        } $self->{operands}->@*;
        return $self->{function_name} . '(' . join(', ', @arg_strings) . ')';
    }
    
    sub to_systemverilog($self) {
        my @arg_strings = map {
            $_ && $_->can('to_systemverilog') ? $_->to_systemverilog : '0'
        } $self->{operands}->@*;
        return $self->{function_name} . '(' . join(', ', @arg_strings) . ')';
    }

#=============================================================================
# Action System (Comprehensive Assignment Framework)
#=============================================================================

package FSM::CoreAST::Action;
    # Base class for all actions that can occur in Decision Trees
    sub new($class, %args) {
        bless {
            type => $args{type} // Carp::confess("Action type required"),
            condition => $args{condition},  # Optional enabling condition
            priority => $args{priority} // 0,  # For conflict resolution
            attributes => _clone_action_metadata($args{attributes} // {}),
        }, $class;
    }
    
    sub type($self) { $self->{type} }
    sub condition($self) { $self->{condition} }
    sub priority($self) { $self->{priority} }
    sub attributes($self) { _clone_action_metadata($self->{attributes}) }
    
    # Override in subclasses
    sub get_target_signals($self) { [] }
    sub get_source_signals($self) { [] }
    sub get_all_signals($self) { 
        return [@{$self->get_target_signals()}, @{$self->get_source_signals()}];
    }
    
    sub has_timing_semantics($self) { 0 }  # Override for clocked actions
    sub get_timing_domain($self) { undef }
    
    sub conflicts_with($self, $other_action) { 0 }  # Override for conflict detection

    sub _clone_action_metadata($value) {
        return undef unless defined $value;

        if (ref($value) eq 'HASH') {
            return {
                map { $_ => _clone_action_metadata($value->{$_}) } sort keys %$value
            };
        }

        if (ref($value) eq 'ARRAY') {
            return [ map { _clone_action_metadata($_) } @$value ];
        }

        return $value;
    }

package FSM::CoreAST::Assignment;
    our @ISA = qw(FSM::CoreAST::Action);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(type => 'assignment', %args);
        $self->{target} = $args{target} // Carp::confess "Assignment target required";
        $self->{source} = $args{source} // Carp::confess "Assignment source required";
        $self->{assignment_type} = $args{assignment_type} // 'combinatorial';
        $self->{timing_semantics} = _clone_assignment_metadata($args{timing_semantics} // {});
        $self->{assignment_intent} = $class->_normalize_assignment_intent(\%args, $self->{assignment_type});
        $self->{source_provenance} = _clone_assignment_metadata($args{source_provenance} // {});
        $self->{output_exposure} = $args{output_exposure} // 'auto';
        return $self;
    }
    
    sub target($self) { $self->{target} }
    sub source($self) { $self->{source} }
    sub assignment_type($self) { $self->{assignment_type} }
    sub timing_semantics($self) { _clone_assignment_metadata($self->{timing_semantics}) }
    sub assignment_intent($self) { _clone_assignment_metadata($self->{assignment_intent} // {}) }
    sub source_provenance($self) { _clone_assignment_metadata($self->{source_provenance} // {}) }
    sub output_exposure($self) { $self->{output_exposure} // 'auto' }
    sub register_style($self) { ($self->{assignment_intent} // {})->{register_style} }
    sub operator_symbol($self) {
        my $intent = $self->assignment_intent;
        if (defined $intent->{operator_symbol} && $intent->{operator_symbol} ne '') {
            return $intent->{operator_symbol};
        }
        
        if ($self->{assignment_type} eq 'register') {
            my $style = $intent->{register_style} // '';
            return '<=' if $style eq 'input_named';
            return '<-';
        }
        
        return '=';
    }
    
    sub get_target_signals($self) { [$self->{target}->get_signals->@*] }
    sub get_source_signals($self) { [$self->{source}->get_signals->@*] }
    
    sub has_timing_semantics($self) { 
        $self->{assignment_type} =~ /^(register|pulse|latch)$/ 
    }
    
    sub get_timing_domain($self) { $self->{timing_semantics}{clock_domain} }
    
    sub conflicts_with($self, $other_action) {
        return 0 unless $other_action->isa('FSM::CoreAST::Assignment');
        # Two assignments conflict if they target the same signal
        my @my_targets = map { $_->name } $self->get_target_signals->@*;
        my @other_targets = map { $_->name } $other_action->get_target_signals->@*;
        
        for my $my_target (@my_targets) {
            return 1 if grep { $_ eq $my_target } @other_targets;
        }
        return 0;
    }
    
    sub _normalize_assignment_intent($class, $args, $assignment_type) {
        my $incoming = (ref($args->{assignment_intent}) eq 'HASH')
            ? _clone_assignment_metadata($args->{assignment_intent})
            : {};
        
        my $default_register_style = $incoming->{register_style}
            // $args->{register_style}
            // ($assignment_type eq 'register' ? 'output_named' : 'none');
        
        my $default_operator = $assignment_type eq 'register'
            ? ($default_register_style eq 'input_named' ? '<=' : '<-')
            : '=';
        
        $incoming->{assignment_family} //= $assignment_type;
        $incoming->{sequencing} //= ($assignment_type eq 'register' ? 'clocked' : 'combinational');
        $incoming->{register_style} //= $default_register_style;
        $incoming->{operator_symbol} //= $default_operator;
        
        return $incoming;
    }

    sub _clone_assignment_metadata($value) {
        return undef unless defined $value;

        if (ref($value) eq 'HASH') {
            return {
                map { $_ => _clone_assignment_metadata($value->{$_}) } sort keys %$value
            };
        }

        if (ref($value) eq 'ARRAY') {
            return [ map { _clone_assignment_metadata($_) } @$value ];
        }

        return $value;
    }

package FSM::CoreAST::StateTransition;
    our @ISA = qw(FSM::CoreAST::Action);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(type => 'state_transition', %args);
        $self->{target_state} = $args{target_state} // Carp::confess "Target state required";
        $self->{transition_type} = $args{transition_type} // 'immediate';
        return $self;
    }
    
    sub target_state($self) { $self->{target_state} }
    sub transition_type($self) { $self->{transition_type} }
    
    sub has_timing_semantics($self) { 1 }  # State transitions are always clocked

package FSM::CoreAST::SideEffect;
    our @ISA = qw(FSM::CoreAST::Action);
    
    # For actions that don't fit assignment/transition model (debugging, etc.)
    sub new($class, %args) {
        my $self = $class->SUPER::new(type => 'side_effect', %args);
        $self->{effect_type} = $args{effect_type} // Carp::confess "Side effect type required";
        $self->{parameters} = _clone_side_effect_parameters($args{parameters} // {});
        return $self;
    }
    
    sub effect_type($self) { $self->{effect_type} }
    sub parameters($self) { _clone_side_effect_parameters($self->{parameters}) }

    sub _clone_side_effect_parameters($value) {
        return undef unless defined $value;

        if (ref($value) eq 'HASH') {
            return {
                map { $_ => _clone_side_effect_parameters($value->{$_}) } sort keys %$value
            };
        }

        if (ref($value) eq 'ARRAY') {
            return [ map { _clone_side_effect_parameters($_) } @$value ];
        }

        return $value;
    }

#=============================================================================
# Specific FSM Assignment Types (Format-Independent Semantics)
#=============================================================================

# 1. RegisterAssignment: Register with clock-enabled writes
package FSM::CoreAST::RegisterAssignment;
    our @ISA = qw(FSM::CoreAST::Assignment);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(
            assignment_type => 'register',
            %args
        );
        $self->{fsm_type} = 'r';  # FSMGen type identifier
        return $self;
    }
    
    sub fsm_type($self) { $self->{fsm_type} }
    
    sub has_timing_semantics($self) { 1 }
    sub generates_wen($self) { 1 }
    
    sub to_verilog($self) {
        my $target = $self->target->to_verilog;
        my $source = $self->source->to_verilog;
        my $wen = $target . "_wen";
        return "// Register Assignment\n" .
               "assign $wen = " . ($self->condition ? $self->condition->to_verilog : '1\'b1') . ";\n" .
               "always_ff @(posedge clk) if ($wen) $target <= $source;";
    }
    
    sub to_systemverilog($self) {
        my $target = $self->target->to_systemverilog;
        my $source = $self->source->to_systemverilog;
        my $wen = $target . "_wen";
        return "// Register Assignment\n" .
               "assign $wen = " . ($self->condition ? $self->condition->to_systemverilog : '1\'b1') . ";\n" .
               "always_ff @(posedge clk) if ($wen) $target <= $source;";
    }

# 2. MuxOutputAssignment: Combinatorial mux output  
package FSM::CoreAST::MuxOutputAssignment;
    our @ISA = qw(FSM::CoreAST::Assignment);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(
            type => 'assignment',
            assignment_type => 'mux_output',
            %args
        );
        $self->{fsm_type} = 'm';
        return $self;
    }
    
    sub fsm_type($self) { $self->{fsm_type} }
    
    sub has_timing_semantics($self) { 0 }
    sub generates_wen($self) { 1 }
    
    sub to_verilog($self) {
        my $target = $self->target->to_verilog;
        my $source = $self->source->to_verilog;
        my $wen = $target . "_wen";
        return "// Mux Output Assignment\n" .
               "assign $wen = " . ($self->condition ? $self->condition->to_verilog : '1\'b1') . ";\n" .
               "assign $target = $wen ? $source : $target;";
    }

# 3. PulseAssignment: N-cycle pulse generation with counters
package FSM::CoreAST::PulseAssignment;
    our @ISA = qw(FSM::CoreAST::Assignment);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(
            type => 'assignment',
            assignment_type => 'pulse',
            %args
        );
        $self->{pulse_cycles} = $args{pulse_cycles} // Carp::confess "Pulse cycles required";
        $self->{fsm_type} = 'p' . $self->{pulse_cycles};
        return $self;
    }
    
    sub pulse_cycles($self) { $self->{pulse_cycles} }
    sub fsm_type($self) { $self->{fsm_type} }
    
    sub has_timing_semantics($self) { 1 }
    sub generates_wen($self) { 1 }
    sub requires_counter($self) { 1 }
    
    sub to_verilog($self) {
        my $target = $self->target->to_verilog;
        my $source = $self->source->to_verilog;
        my $counter = $target . "_pulse_counter";
        my $wen = $target . "_wen";
        my $cycles = $self->pulse_cycles;
        
        return "// Pulse Assignment ($cycles cycles)\n" .
               "reg [7:0] $counter;\n" .
               "assign $wen = " . ($self->condition ? $self->condition->to_verilog : '1\'b1') . ";\n" .
               "always_ff @(posedge clk) begin\n" .
               "    if ($wen) begin\n" .
               "        $target <= $source;\n" .
               "        $counter <= $cycles;\n" .
               "    end else if ($counter > 0) begin\n" .
               "        $counter <= $counter - 1;\n" .
               "        $target <= ($counter == 1) ? 1'b0 : $target;\n" .
               "    end\n" .
               "end";
    }

# 4. RegisterMuxAssignment: Register + next_ output
package FSM::CoreAST::RegisterMuxAssignment;
    our @ISA = qw(FSM::CoreAST::Assignment);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(
            type => 'assignment',
            assignment_type => 'register_mux',
            %args
        );
        $self->{fsm_type} = 'rm';
        return $self;
    }
    
    sub fsm_type($self) { $self->{fsm_type} }
    
    sub has_timing_semantics($self) { 1 }
    sub generates_wen($self) { 1 }
    sub generates_next_signal($self) { 1 }
    
    sub to_verilog($self) {
        my $target = $self->target->to_verilog;
        my $source = $self->source->to_verilog;
        my $next = "next_" . $target;
        my $wen = $target . "_wen";
        
        return "// Register+Mux Assignment\n" .
               "assign $wen = " . ($self->condition ? $self->condition->to_verilog : '1\'b1') . ";\n" .
               "assign $next = $wen ? $source : $target;\n" .
               "always_ff @(posedge clk) $target <= $next;";
    }

# 5. MuxRegisterAssignment: Mux + intermediate register
package FSM::CoreAST::MuxRegisterAssignment;
    our @ISA = qw(FSM::CoreAST::Assignment);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(
            type => 'assignment',
            assignment_type => 'mux_register',
            %args
        );
        $self->{fsm_type} = 'mr';
        return $self;
    }
    
    sub fsm_type($self) { $self->{fsm_type} }
    
    sub has_timing_semantics($self) { 1 }
    sub generates_wen($self) { 1 }
    sub has_intermediate_register($self) { 1 }
    
    sub to_verilog($self) {
        my $target = $self->target->to_verilog;
        my $source = $self->source->to_verilog;
        my $intermediate = $target . "_int_reg";
        my $wen = $target . "_wen";
        
        return "// Mux+Register Assignment\n" .
               "reg $intermediate;\n" .
               "assign $wen = " . ($self->condition ? $self->condition->to_verilog : '1\'b1') . ";\n" .
               "always_ff @(posedge clk) if ($wen) $intermediate <= $source;\n" .
               "assign $target = $intermediate;";
    }

# 6. CombinatorialAssignment: Pure combinatorial logic
package FSM::CoreAST::CombinatorialAssignment;
    our @ISA = qw(FSM::CoreAST::Assignment);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(
            type => 'assignment',
            assignment_type => 'combinatorial',
            %args
        );
        $self->{fsm_type} = 'c';
        return $self;
    }
    
    sub fsm_type($self) { $self->{fsm_type} }
    
    sub has_timing_semantics($self) { 0 }
    sub generates_wen($self) { 0 }
    
    sub to_verilog($self) {
        my $target = $self->target->to_verilog;
        my $source = $self->source->to_verilog;
        my $condition = $self->condition ? $self->condition->to_verilog . " ? " : "";
        my $default = $self->condition ? " : $target" : "";
        
        return "// Combinatorial Assignment\n" .
               "assign $target = $condition$source$default;";
    }

# 7. IncrementAssignment: Auto-increment with configurable step
package FSM::CoreAST::IncrementAssignment;
    our @ISA = qw(FSM::CoreAST::Action);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(type => 'increment', %args);
        $self->{target} = $args{target} // Carp::confess "Increment target required";
        $self->{step} = $args{step} // 1;
        $self->{fsm_type} = 'inc';
        return $self;
    }
    
    sub target($self) { $self->{target} }
    sub step($self) { $self->{step} }
    sub fsm_type($self) { $self->{fsm_type} }
    
    sub get_target_signals($self) { [$self->{target}->get_signals->@*] }
    sub get_source_signals($self) { [$self->{target}->get_signals->@*] }  # Self-referential
    
    sub has_timing_semantics($self) { 1 }
    sub generates_wen($self) { 1 }
    
    sub to_verilog($self) {
        my $target = $self->target->to_verilog;
        my $step = $self->step;
        my $wen = $target . "_inc_wen";
        
        return "// Increment Assignment\n" .
               "assign $wen = " . ($self->condition ? $self->condition->to_verilog : '1\'b1') . ";\n" .
               "always_ff @(posedge clk) if ($wen) $target <= $target + $step;";
    }

# 8. DecrementAssignment: Auto-decrement with configurable step
package FSM::CoreAST::DecrementAssignment;
    our @ISA = qw(FSM::CoreAST::Action);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(type => 'decrement', %args);
        $self->{target} = $args{target} // Carp::confess "Decrement target required";
        $self->{step} = $args{step} // 1;
        $self->{fsm_type} = 'dec';
        return $self;
    }
    
    sub target($self) { $self->{target} }
    sub step($self) { $self->{step} }
    sub fsm_type($self) { $self->{fsm_type} }
    
    sub get_target_signals($self) { [$self->{target}->get_signals->@*] }
    sub get_source_signals($self) { [$self->{target}->get_signals->@*] }  # Self-referential
    
    sub has_timing_semantics($self) { 1 }
    sub generates_wen($self) { 1 }
    
    sub to_verilog($self) {
        my $target = $self->target->to_verilog;
        my $step = $self->step;
        my $wen = $target . "_dec_wen";
        
        return "// Decrement Assignment\n" .
               "assign $wen = " . ($self->condition ? $self->condition->to_verilog : '1\'b1') . ";\n" .
               "always_ff @(posedge clk) if ($wen) $target <= $target - $step;";
    }

# 9. StateTransition: State machine transitions (enhanced version)
package FSM::CoreAST::StateTransitionFSM;
    our @ISA = qw(FSM::CoreAST::StateTransition);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(%args);
        $self->{fsm_type} = 'trans';
        return $self;
    }
    
    sub fsm_type($self) { $self->{fsm_type} }
    
    sub generates_wen($self) { 1 }
    
    sub to_verilog($self) {
        my $target_state = $self->target_state;
        my $condition = $self->condition ? $self->condition->to_verilog : '1\'b1';
        
        return "// State Transition\n" .
               "assign state_trans_wen = $condition;\n" .
               "assign next_state = state_trans_wen ? STATE_$target_state : current_state;";
    }

# 10. TestNode: Case/switch-like conditional branching
package FSM::CoreAST::TestNode;
    our @ISA = qw(FSM::CoreAST::ControlFlow);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(type => 'test_node', %args);
        $self->{test_signal} = $args{test_signal} // Carp::confess "Test signal required";
        $self->{test_branches} = _clone_test_node_value($args{test_branches} // []);  # [{value => val, actions => [...]}]
        $self->{fsm_type} = 'test';
        return $self;
    }
    
    sub test_signal($self) { $self->{test_signal} }
    sub test_branches($self) { _clone_test_node_value($self->{test_branches}) }
    sub fsm_type($self) { $self->{fsm_type} }
    
    sub add_test_branch($self, $value, $actions) {
        push $self->{test_branches}->@*, _clone_test_node_value({ value => $value, actions => $actions });
    }
    
    sub get_all_test_values($self) {
        return [map { $_->{value} } $self->{test_branches}->@*];
    }
    
    sub get_all_actions($self) {
        my @actions;
        for my $branch ($self->{test_branches}->@*) {
            push @actions, $branch->{actions}->@*;
        }
        return \@actions;
    }

    sub _clone_test_node_value($value) {
        return undef unless defined $value;

        if (ref($value) eq 'HASH') {
            return {
                map { $_ => _clone_test_node_value($value->{$_}) } sort keys %$value
            };
        }

        if (ref($value) eq 'ARRAY') {
            return [ map { _clone_test_node_value($_) } @$value ];
        }

        return $value;
    }
    
    sub to_verilog($self) {
        my $signal = $self->test_signal->to_verilog;
        my $code = "// Test Node\n";
        $code .= "case ($signal)\n";
        
        for my $branch ($self->{test_branches}->@*) {
            my $value = ref($branch->{value}) ? $branch->{value}->to_verilog : $branch->{value};
            $code .= "    $value: begin\n";
            for my $action ($branch->{actions}->@*) {
                if ($action->can('to_verilog')) {
                    my $action_code = $action->to_verilog;
                    $action_code =~ s/^/        /gm;  # Indent
                    $code .= "$action_code\n";
                }
            }
            $code .= "    end\n";
        }
        
        $code .= "endcase";
        return $code;
    }

#=============================================================================
# Control Flow System
#=============================================================================

package FSM::CoreAST::ControlFlow;
    # Base class for control flow constructs
    sub new($class, %args) {
        my $hash_ref = {};
        $hash_ref->{type} = $args{type} // Carp::confess "Control flow type required";
        $hash_ref->{condition} = $args{condition};
        $hash_ref->{branches} = _clone_control_flow_value($args{branches} // []);
        $hash_ref->{attributes} = _clone_control_flow_value($args{attributes} // {});
        return bless $hash_ref, $class;
    }
    
    sub type($self) { $self->{type} }
    sub condition($self) { $self->{condition} }
    sub branches($self) { _clone_control_flow_value($self->{branches}) }
    sub attributes($self) { _clone_control_flow_value($self->{attributes}) }

    sub _clone_control_flow_value($value) {
        return undef unless defined $value;

        if (ref($value) eq 'HASH') {
            return {
                map { $_ => _clone_control_flow_value($value->{$_}) } sort keys %$value
            };
        }

        if (ref($value) eq 'ARRAY') {
            return [ map { _clone_control_flow_value($_) } @$value ];
        }

        return $value;
    }

package FSM::CoreAST::ConditionalBranch;
    our @ISA = qw(FSM::CoreAST::ControlFlow);
    
    sub new($class, %args) {
        my $hash_ref = {
            type => 'conditional',
            condition => $args{condition},
            branches => FSM::CoreAST::ControlFlow::_clone_control_flow_value($args{branches} // []),
            attributes => FSM::CoreAST::ControlFlow::_clone_control_flow_value($args{attributes} // {}),
        };
        my $self = bless $hash_ref, $class;
        # branches: [{condition => expr, actions => [actions...]}, ...]
        # Last branch can have condition => undef for 'else'
        return $self;
    }
    
    sub get_all_conditions($self) {
        return [map { $_->{condition} } grep { defined $_->{condition} } $self->{branches}->@*];
    }
    
    sub get_all_actions($self) {
        my @actions;
        for my $branch ($self->{branches}->@*) {
            push @actions, $branch->{actions}->@*;
        }
        return \@actions;
    }

package FSM::CoreAST::CaseBranch;
    our @ISA = qw(FSM::CoreAST::ControlFlow);
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(type => 'case', %args);
        # branches: [{values => [val1, val2, ...], actions => [actions...]}, ...]
        # Special branch can have values => ['default'] for default case
        return $self;
    }
    
    sub get_case_values($self) {
        my @values;
        for my $branch ($self->{branches}->@*) {
            push @values, $branch->{values}->@* if $branch->{values};
        }
        return \@values;
    }

#=============================================================================
# Core Decision Tree
#=============================================================================

package FSM::CoreAST::DecisionTree;
    sub new($class, %args) {
        bless {
            name => $args{name} // Carp::confess("Decision tree name required"),
            enable_condition => $args{enable_condition},
            elements => $args{elements} // [],  # Mix of actions and control flow
            priority => $args{priority} // 0,
            attributes => $args{attributes} // {},
            analysis_cache => {},  # For caching analysis results
        }, $class;
    }
    
    sub name($self) { $self->{name} }
    sub enable_condition($self) { $self->{enable_condition} }
    sub elements($self) { $self->{elements} }
    sub priority($self) { $self->{priority} }
    sub attributes($self) { $self->{attributes} }
    
    sub add_element($self, $element) {
        push $self->{elements}->@*, $element;
        delete $self->{analysis_cache};  # Invalidate cache
    }
    
    # Signal Analysis
    sub analyze_signals($self) {
        return $self->{analysis_cache}{signals} //= $self->_compute_signal_analysis();
    }
    
    sub _compute_signal_analysis($self) {
        my %analysis = (
            inputs => {},
            outputs => {},
            internal => {},
            dependencies => {},
        );
        
        $self->_analyze_element_signals(\%analysis, $_) for $self->{elements}->@*;
        
        return \%analysis;
    }
    
    sub _analyze_element_signals($self, $analysis, $element) {
        if ($element->isa('FSM::CoreAST::Action')) {
            # Mark target signals as outputs
            for my $signal ($element->get_target_signals->@*) {
                $analysis->{outputs}{$signal->name} = $signal;
            }
            
            # Mark source signals as inputs  
            for my $signal ($element->get_source_signals->@*) {
                $analysis->{inputs}{$signal->name} = $signal;
                
                # Track dependencies
                for my $target ($element->get_target_signals->@*) {
                    $analysis->{dependencies}{$target->name} //= [];
                    push $analysis->{dependencies}{$target->name}->@*, $signal;
                }
            }
        } elsif ($element->isa('FSM::CoreAST::ControlFlow')) {
            # Analyze condition signals
            if ($element->condition) {
                for my $signal ($element->condition->get_signals->@*) {
                    $analysis->{inputs}{$signal->name} = $signal;
                }
            }
            
            # Recursively analyze branches
            if ($element->isa('FSM::CoreAST::ConditionalBranch')) {
                for my $branch ($element->branches->@*) {
                    $self->_analyze_element_signals($analysis, $_) for $branch->{actions}->@*;
                }
            }
        }
    }
    
    # Conflict Analysis
    sub analyze_conflicts($self) {
        return $self->{analysis_cache}{conflicts} //= $self->_compute_conflict_analysis();
    }
    
    sub _compute_conflict_analysis($self) {
        my @all_actions = $self->_get_all_actions();
        my @conflicts;
        
        for my $i (0 .. $#all_actions - 1) {
            for my $j ($i + 1 .. $#all_actions) {
                if ($all_actions[$i]->conflicts_with($all_actions[$j])) {
                    push @conflicts, [$all_actions[$i], $all_actions[$j]];
                }
            }
        }
        
        return \@conflicts;
    }
    
    sub _get_all_actions($self) {
        my @actions;
        $self->_collect_actions_from_element(\@actions, $_) for $self->{elements}->@*;
        return @actions;
    }
    
    sub _collect_actions_from_element($self, $actions, $element) {
        if ($element->isa('FSM::CoreAST::Action')) {
            push @$actions, $element;
        } elsif ($element->isa('FSM::CoreAST::ControlFlow')) {
            if ($element->isa('FSM::CoreAST::ConditionalBranch')) {
                for my $branch ($element->branches->@*) {
                    $self->_collect_actions_from_element($actions, $_) for $branch->{actions}->@*;
                }
            }
        }
    }

#=============================================================================
# FSM State and Module
#=============================================================================

package FSM::CoreAST::State;
    sub new($class, %args) {
        bless {
            name => $args{name} // Carp::confess("State name required"),
            decision_trees => $args{decision_trees} // [],
            encoding => $args{encoding},
            state_type => $args{state_type} // 'normal',
            attributes => $args{attributes} // {},
        }, $class;
    }
    
    sub name($self) { $self->{name} }
    sub decision_trees($self) { $self->{decision_trees} }
    sub encoding($self) { $self->{encoding} }
    sub state_type($self) { $self->{state_type} // 'normal' }
    sub attributes($self) { $self->{attributes} }

    sub is_reset_state($self) {
        my $state_type = $self->state_type;
        return $state_type eq 'sync_reset' || $state_type eq 'async_reset';
    }

    sub is_standalone_dt($self) {
        my $state_type = $self->state_type;
        return 1 if $state_type eq 'standalone_dt';
        return !$self->is_reset_state && $self->{name} =~ /^-/;
    }

    sub is_regular_state($self) {
        return !$self->is_reset_state && !$self->is_standalone_dt;
    }
    
    sub add_decision_tree($self, $dt) {
        push $self->{decision_trees}->@*, $dt;
    }
    
    sub get_primary_decision_tree($self) {
        return $self->{decision_trees}[0];  # First DT is primary
    }

package FSM::CoreAST::FSMModule;
    sub new($class, %args) {
        bless {
            name => $args{name} // Carp::confess("FSM module name required"),
            states => $args{states} // [],
            signals => $args{signals} // {},
            clock_domains => $args{clock_domains} // {},
            reset_domains => $args{reset_domains} // {},
            parameters => $args{parameters} // {},
            constraints => $args{constraints} // [],
            attributes => $args{attributes} // {},
        }, $class;
    }
    
    sub name($self) { $self->{name} }
    sub states($self) { $self->{states} }
    sub signals($self) { $self->{signals} }
    sub clock_domains($self) { $self->{clock_domains} }
    sub reset_domains($self) { $self->{reset_domains} }
    sub parameters($self) { $self->{parameters} }
    sub attributes($self) { $self->{attributes} }
    sub explicit_system_contract($self) { return _clone_fsm_module_value($self->{attributes}{system_contract}) }
    sub source_root_kind($self) { return $self->{attributes}{source_root_kind} // 'fsm' }
    sub direct_root_symbols($self) { return $self->{attributes}{direct_root_symbols} }
    sub package_imports($self) { return _clone_fsm_module_value($self->{attributes}{package_imports} || []) }
    sub is_dt_root($self) { return $self->source_root_kind eq 'dt' }
    sub is_fsm_root($self) { return $self->source_root_kind eq 'fsm' }

    sub has_timed_actions($self) {
        for my $state (@{$self->{states} || []}) {
            next unless Scalar::Util::blessed($state) && $state->can('decision_trees');
            for my $dt (@{$state->decision_trees || []}) {
                next unless Scalar::Util::blessed($dt) && $dt->can('elements');
                for my $element (@{$dt->elements || []}) {
                    return 1 if $self->_element_has_timed_actions($element);
                }
            }
        }
        return 0;
    }

    sub requires_implicit_system_ports($self) {
        return 1 if ref($self->explicit_system_contract) eq 'HASH';
        return 1 unless $self->is_dt_root;
        return $self->has_timed_actions ? 1 : 0;
    }

    sub effective_system_contract($self) {
        my $explicit = $self->explicit_system_contract;
        if (ref($explicit) eq 'HASH') {
            my $reset_keyword = (
                $explicit->{reset_keyword}
                // _reset_keyword_from_name($explicit->{reset} // '')
            );
            my ($reset_kind, $reset_active_level) = _reset_policy_from_keyword($reset_keyword);
            return {
                clock => ($explicit->{clock} // 'clk'),
                reset => ($explicit->{reset} // 'rst_n'),
                reset_keyword => $reset_keyword,
                reset_kind => $reset_kind,
                reset_active_level => $reset_active_level,
                implicit => 0,
                declare_ports => 1,
            };
        }

        return {
            clock => 'clk',
            reset => 'rst_n',
            reset_keyword => 'areset',
            reset_kind => 'async',
            reset_active_level => 0,
            implicit => 1,
            declare_ports => $self->requires_implicit_system_ports,
        };
    }

    sub system($self) { return $self->effective_system_contract }

    sub _clone_fsm_module_value($value) {
        return undef unless defined $value;

        if (ref($value) eq 'HASH') {
            return {
                map { $_ => _clone_fsm_module_value($value->{$_}) } sort keys %$value
            };
        }

        if (ref($value) eq 'ARRAY') {
            return [ map { _clone_fsm_module_value($_) } @$value ];
        }

        return $value;
    }

    sub _reset_keyword_from_name($reset_name) {
        return _looks_active_low_reset_name($reset_name) ? 'areset' : 'sreset';
    }

    sub _looks_active_low_reset_name($reset_name) {
        return defined($reset_name)
            && $reset_name =~ /(?:_n|n)\z/i;
    }

    sub _reset_policy_from_keyword($reset_keyword) {
        return ('sync', 1) if defined($reset_keyword) && $reset_keyword eq 'sreset';
        return ('async', 0);
    }
    
    sub add_state($self, $state) {
        push $self->{states}->@*, $state;
    }
    
    sub add_signal($self, $signal) {
        $self->{signals}{$signal->name} = $signal;
    }
    
    sub get_signal($self, $name) {
        return $self->{signals}{$name};
    }

    sub _element_has_timed_actions($self, $element) {
        return 0 unless Scalar::Util::blessed($element);

        if ($element->isa('FSM::CoreAST::Action')) {
            return ($element->can('has_timing_semantics') && $element->has_timing_semantics) ? 1 : 0;
        }

        if ($element->can('get_all_actions')) {
            for my $action (@{$element->get_all_actions || []}) {
                next unless Scalar::Util::blessed($action);
                next unless $action->can('has_timing_semantics');
                return 1 if $action->has_timing_semantics;
            }
        }

        return 0;
    }
    
    # High-level analysis
    sub analyze_fsm($self) {
        my %analysis = (
            signal_analysis => {},
            conflict_analysis => {},
            timing_analysis => {},
            resource_analysis => {},
        );
        
        # Analyze each state's decision trees
        for my $state ($self->{states}->@*) {
            for my $dt ($state->decision_trees->@*) {
                my $dt_signals = $dt->analyze_signals();
                my $dt_conflicts = $dt->analyze_conflicts();
                
                # Merge analysis results
                for my $type (qw(inputs outputs internal dependencies)) {
                    $analysis{signal_analysis}{$type} //= {};
                    %{$analysis{signal_analysis}{$type}} = (
                        %{$analysis{signal_analysis}{$type}},
                        %{$dt_signals->{$type}}
                    );
                }
                
                $analysis{conflict_analysis}{$state->name} //= [];
                push $analysis{conflict_analysis}{$state->name}->@*, @$dt_conflicts;
            }
        }
        
        return \%analysis;
    }

1;

__END__

=head1 NAME

FSM::CoreAST - Core Semantic AST for Decision Tree FSMs

=head1 DESCRIPTION

This module provides a format-agnostic, semantically complete Abstract Syntax Tree
for representing Finite State Machines based on Decision Trees. The design focuses
on capturing the fundamental concepts needed for FSM description and HDL generation
without being tied to any specific input format.

=head2 Core Concepts

=head3 Signals
Represent all signal types with comprehensive attributes including timing domains,
constraints, and type information.

=head3 Expressions  
Flexible expression system supporting all boolean operations, comparisons, and
signal references needed for Decision Tree conditions.

=head3 Actions
Comprehensive action system covering assignments, state transitions, and side effects
with conflict detection and timing analysis.

=head3 Control Flow
Support for conditional branches and case statements within Decision Trees.

=head3 Decision Trees
Core DT representation with signal analysis, conflict detection, and optimization
capabilities.

=head3 FSM Module
Complete FSM representation with states, signals, timing domains, and analysis
framework.

=head2 Key Features

=over 4

=item * Format agnostic - can be populated from any input format

=item * Comprehensive signal analysis and dependency tracking  

=item * Built-in conflict detection for resource contention

=item * Timing domain awareness for multi-clock designs

=item * Extensible action system for all FSM behaviors

=item * Analysis caching for performance

=item * Target-independent HDL generation support

=back

=cut
