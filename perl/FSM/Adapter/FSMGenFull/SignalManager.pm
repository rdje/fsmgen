package FSM::Adapter::FSMGenFull::SignalManager;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Data::Dumper;
use FSM::CoreAST;
use FSM::Debug;

sub new($class, %args) {
    return bless {
        debug => $args{debug} // 0,
        signal_registry => {},  # Track all signals and their properties
        signal_usage => {},     # Track usage patterns for analysis
        # Symbol tables for constants, enums, defines, and params
        constants => {},        # +constants: name -> literal_value
        enums => {},           # +enums: enum_name -> {member -> value}
        defines => {},         # +define: name -> value_expression
        params => {},          # +params: name -> parameter_value
    }, $class;
}

# PHASE 1: Signal Registry (Parsing) - No FSM module interaction
sub register_signal($self, $signal_name, %attributes) {
    if (!defined $signal_name) {
        use Carp; Carp::confess("register_signal called with undefined signal_name!");
    }

    # DEBUG: Track where invalid signal names are created
    if ($signal_name =~ /^[!<>]/) {
        fsm_debug("*** SIGNAL REGISTRY DEBUG: Invalid signal name '$signal_name' being registered!", 3);
        fsm_debug("*** Call stack trace:", 3);
        my $i = 1;
        while (my ($package, $filename, $line, $subroutine) = caller($i)) {
            fsm_debug("***   [$i] $subroutine at $filename:$line", 3);
            $i++;
            last if $i > 5;  # Limit stack trace depth
        }
    }
    
    # Track usage patterns for later analysis
    my $usage = $self->initialize_signal_usage($signal_name);
    
    # Update usage flags based on attributes
    if ($attributes{is_intermediate}) {
        $usage->{is_intermediate} = 1;
        fsm_debug("        USAGE: '$signal_name' marked as intermediate", 3);
    }
    if ($attributes{is_output}) {
        $usage->{has_output_marker} = 1;
        fsm_debug("        USAGE: '$signal_name' marked with output marker", 3);
    }
    
    # Check if signal already exists in registry
    if (exists $self->{signal_registry}{$signal_name}) {
        my $existing = $self->{signal_registry}{$signal_name};
        fsm_debug("        SIGNAL EXISTS: '$signal_name' width=" . ($existing->width || 'undef'), 3);
        
        # Check if new attributes would override existing ones
        if (%attributes) {
            fsm_debug("        NEW ATTRIBUTES: " . Dumper(\%attributes), 3);
            
            # Update width if the new width is more specific (larger) than existing
            if (defined($attributes{width}) && $attributes{width} > ($existing->width || 1)) {
                fsm_debug("        UPDATING SIGNAL WIDTH: '$signal_name' from " . 
                    ($existing->width || 'undef') . " to $attributes{width}", 3);
                
                # Create new signal with updated attributes
                my %updated_attrs = (
                    name => $signal_name,
                    type => $existing->type,
                    width => $attributes{width},
                    %{$existing->{attributes} || {}},
                    %attributes
                );
                
                my $updated_signal = FSM::CoreAST::Signal->new(%updated_attrs);
                $self->{signal_registry}{$signal_name} = $updated_signal;
                
                return $updated_signal;
            }
        }
        
        return $existing;
    }
    
    # Create new signal in registry only (NO FSM module interaction)
    my %signal_attrs = (
        name => $signal_name,
        type => 'wire',  # Default type
        %attributes
    );
    
    fsm_debug("        REGISTER SIGNAL: '$signal_name' with attrs: " . Dumper(\%signal_attrs), 3);
    fsm_debug("        (Signal registry only - FSM interface will be generated later)", 3);
    
    my $signal = FSM::CoreAST::Signal->new(%signal_attrs);
    $self->{signal_registry}{$signal_name} = $signal;
    
    return $signal;
}

sub get_or_create_signal($self, $signal_name, %attributes) {
    fsm_debug("        WARNING: Using deprecated get_or_create_signal - should use register_signal during parsing", 2);
    return $self->register_signal($signal_name, %attributes);
}

sub get_signal($self, $signal_name) {
    return $self->{signal_registry}{$signal_name};
}

sub get_all_signal_names($self) {
    return keys %{$self->{signal_registry}};
}

sub initialize_signal_usage($self, $signal_name) {
    $self->{signal_usage}{$signal_name} //= {
        referenced_in_conditions => 0,
        assigned_to => 0,
        has_output_marker => 0,
        is_intermediate => 0,
        contexts => []  # Track where this signal was referenced
    };
    return $self->{signal_usage}{$signal_name};
}

sub get_signal_usage($self, $signal_name) {
    return $self->{signal_usage}{$signal_name};
}

sub get_all_signal_usages($self) {
    return $self->{signal_usage};
}

# Symbol Storage
sub store_constant($self, $name, $literal_expr) {
    $self->{constants}{$name} = $literal_expr;
}

sub store_enum($self, $enum_name, $enum_values_hashref) {
    $self->{enums}{$enum_name} = $enum_values_hashref;
}

sub store_define($self, $name, $value_expr) {
    $self->{defines}{$name} = $value_expr;
}

sub store_param($self, $name, $value) {
    $self->{params}{$name} = $value;
}

# Symbol resolution methods
sub resolve_symbol($self, $symbol_name) {
    # Check in order: constants, defines, enum members, params
    
    # 1. Check constants
    if (exists $self->{constants}{$symbol_name}) {
        fsm_debug("      RESOLVED: $symbol_name as constant", 3);
        return $self->{constants}{$symbol_name};
    }
    
    # 2. Check defines
    if (exists $self->{defines}{$symbol_name}) {
        fsm_debug("      RESOLVED: $symbol_name as define", 3);
        return $self->{defines}{$symbol_name};
    }
    
    # 3. Check enum members (format: enum_name.member_name)
    if ($symbol_name =~ /^([a-zA-Z_]\w*)\.([a-zA-Z_]\w*)$/) {
        my ($enum_name, $member_name) = ($1, $2);
        if (exists $self->{enums}{$enum_name} && exists $self->{enums}{$enum_name}{$member_name}) {
            my $value = $self->{enums}{$enum_name}{$member_name};
            fsm_debug("      RESOLVED: $symbol_name as enum member -> $value", 3);
            return FSM::CoreAST::Literal->new($value);
        }
    }
    
    # 4. Check params (used in expressions like {DATA_WIDTH}'b0)
    if (exists $self->{params}{$symbol_name}) {
        fsm_debug("      RESOLVED: $symbol_name as param -> $self->{params}{$symbol_name}", 3);
        return FSM::CoreAST::Literal->new($self->{params}{$symbol_name});
    }
    
    # Not found in symbol tables
    return undef;
}

# Summaries
sub get_symbol_summary($self) {
    my %summary = (
        constants => scalar(keys %{$self->{constants}}),
        enums => scalar(keys %{$self->{enums}}),
        defines => scalar(keys %{$self->{defines}}),
        params => scalar(keys %{$self->{params}}),
    );
    return \%summary;
}

sub get_signal_summary($self) {
    my %summary;
    for my $signal_name (keys %{$self->{signal_registry}}) {
        my $signal = $self->{signal_registry}{$signal_name};
        $summary{$signal_name} = {
            type => $signal->type,
            width => $signal->width,
            is_output => $signal->get_attribute('is_output') // 0,
        };
    }
    return \%summary;
}

1;
