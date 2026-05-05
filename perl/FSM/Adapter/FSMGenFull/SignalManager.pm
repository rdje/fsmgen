package FSM::Adapter::FSMGenFull::SignalManager;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Carp ();
use Data::Dumper;
use Scalar::Util qw(blessed);
use FSM::CoreAST;
use FSM::Debug;
use FSM::Package::ScalarWidthSupport;
use FSM::ParameterValueSupport;

sub new($class, %args) {
    return bless {
        debug => $args{debug} // 0,
        signal_registry => {},  # Track all signals and their properties
        signal_usage => {},     # Track usage patterns for analysis
        # Symbol tables for constants, enums, defines, and params
        constants => {},        # +constants: name -> literal_value
        constant_definitions => {}, # declared +constants roots (for summary/continuity)
        enums => {},           # +enums: enum_name -> {member -> value}
        defines => {},         # +define: name -> value_expression
        params => {},          # +params: name -> parameter_value
        types => {},           # +types: name -> scalar type spec
        aggregate_symbols => {}, # aggregate-valued symbol roots that must resolve to scalar leaves
        aggregate_payloads => {}, # aggregate-valued symbol roots that can lower whole-list payloads
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
    
    # Normalize caller attributes into constructor fields + signal attribute bag.
    # Keys like is_output/is_intermediate are semantic attributes and must live
    # under Signal->{attributes} so later stages can query them.
    my %normalized_attrs = %attributes;
    my %attribute_bag;
    if (exists $normalized_attrs{attributes} && ref($normalized_attrs{attributes}) eq 'HASH') {
        %attribute_bag = %{ delete $normalized_attrs{attributes} };
    } else {
        delete $normalized_attrs{attributes};
    }
    for my $attr_key (qw(is_output is_intermediate is_aux_output signal_role width_declared)) {
        if (exists $normalized_attrs{$attr_key}) {
            $attribute_bag{$attr_key} = delete $normalized_attrs{$attr_key};
        }
    }
    if (%attribute_bag) {
        $normalized_attrs{attributes} = \%attribute_bag;
    }
    
    # Track usage patterns for later analysis
    my $usage = $self->initialize_signal_usage($signal_name);
    
    # Update usage flags based on attributes
    if ($attribute_bag{is_intermediate}) {
        $usage->{is_intermediate} = 1;
        fsm_debug("        USAGE: '$signal_name' marked as intermediate", 3);
    }
    if ($attribute_bag{is_output}) {
        $usage->{has_output_marker} = 1;
        fsm_debug("        USAGE: '$signal_name' marked with output marker", 3);
    }
    
    # Check if signal already exists in registry
    if (exists $self->{signal_registry}{$signal_name}) {
        my $existing = $self->{signal_registry}{$signal_name};
        fsm_debug("        SIGNAL EXISTS: '$signal_name' width=" . ($existing->width || 'undef'), 3);
        
        # Apply refinements directly to the existing object so all previously-created
        # AST signal references see the updated width/attributes.
        if (%normalized_attrs) {
            fsm_debug("        NEW ATTRIBUTES: " . Dumper(\%normalized_attrs), 3);
            
            # Update width if the new width is more specific (larger) than existing
            if (defined($normalized_attrs{width}) && $normalized_attrs{width} > ($existing->width || 1)) {
                fsm_debug("        UPDATING SIGNAL WIDTH: '$signal_name' from " .
                    ($existing->width || 'undef') . " to $normalized_attrs{width}", 3);
                $existing->{_width} = $normalized_attrs{width};
            }
            
            # Update core fields when explicitly provided
            $existing->{type} = $normalized_attrs{type} if defined $normalized_attrs{type};
            $existing->{signed} = $normalized_attrs{signed} ? 1 : 0 if exists $normalized_attrs{signed};
            $existing->{state_model} = $normalized_attrs{state_model} if exists $normalized_attrs{state_model};
            $existing->{declared_type_name} = $normalized_attrs{declared_type_name}
                if exists $normalized_attrs{declared_type_name};
            if (exists $normalized_attrs{declared_type_spec}) {
                $existing->{declared_type_spec} = _clone_type_spec($normalized_attrs{declared_type_spec});
            }
            $existing->{clock_domain} = $normalized_attrs{clock_domain} if exists $normalized_attrs{clock_domain};
            $existing->{reset_domain} = $normalized_attrs{reset_domain} if exists $normalized_attrs{reset_domain};
            
            # Merge semantic attributes
            if (ref($normalized_attrs{attributes}) eq 'HASH') {
                $existing->{attributes} //= {};
                for my $k (keys %{$normalized_attrs{attributes}}) {
                    $existing->{attributes}{$k} = $normalized_attrs{attributes}{$k};
                }
            }
        }
        
        return $existing;
    }
    
    # Create new signal in registry only (NO FSM module interaction)
    my %signal_attrs = (
        name => $signal_name,
        type => 'wire',  # Default type
        %normalized_attrs
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

sub record_constant_definition($self, $name) {
    return unless defined $name && length $name;
    $self->{constant_definitions}{$name} = 1;
    return $self->{constant_definitions}{$name};
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

sub store_type($self, $name, $type_spec) {
    $self->{types}{$name} = $type_spec;
}

sub store_aggregate_symbol($self, $name, $payload = undef) {
    $self->{aggregate_symbols}{$name} = 1 if defined $name && length $name;
    $self->{aggregate_payloads}{$name} = _clone_type_spec($payload)
        if defined $name && length $name && defined $payload;
    return $self->{aggregate_symbols}{$name};
}

sub is_aggregate_symbol($self, $name) {
    return 0 unless defined $name;
    return $self->{aggregate_symbols}{$name} ? 1 : 0;
}

sub aggregate_symbol_prefix_for($self, $name) {
    return undef unless defined $name && length $name;

    my @candidates = sort { length($b) <=> length($a) } keys %{ $self->{aggregate_symbols} || {} };
    for my $candidate (@candidates) {
        return $candidate if $name eq $candidate;
        return $candidate if $name =~ /^\Q$candidate\E(?:\.|\[)/;
    }

    return undef;
}

sub resolve_aggregate_symbol_payload($self, $name) {
    return undef unless defined $name;
    return _clone_type_spec($self->{aggregate_payloads}{$name});
}

sub resolve_parameter_value_symbol_payload($self, $symbol_name) {
    return undef unless defined $symbol_name && !ref($symbol_name);

    my $aggregate_payload = $self->resolve_aggregate_symbol_payload($symbol_name);
    return $aggregate_payload if defined $aggregate_payload;

    if (exists $self->{constants}{$symbol_name}) {
        return _literal_to_parameter_payload($self->{constants}{$symbol_name});
    }

    if (exists $self->{defines}{$symbol_name}) {
        return _literal_to_parameter_payload($self->{defines}{$symbol_name});
    }

    if ($symbol_name =~ /^([a-zA-Z_]\w*)\.([a-zA-Z_]\w*)$/) {
        my ($enum_name, $member_name) = ($1, $2);
        if (exists $self->{enums}{$enum_name} && exists $self->{enums}{$enum_name}{$member_name}) {
            return {
                kind => 'scalar',
                payload => $self->{enums}{$enum_name}{$member_name},
            };
        }
    }

    if (exists $self->{params}{$symbol_name}) {
        return _clone_type_spec($self->{params}{$symbol_name}{value_payload})
            if ref($self->{params}{$symbol_name}) eq 'HASH'
                && ref($self->{params}{$symbol_name}{value_payload}) eq 'HASH';
    }

    if ($symbol_name =~ /^([a-zA-Z_]\w*)((?:\.[a-zA-Z_]\w*|\[\d+\])+)\z/) {
        my ($param_name, $suffix) = ($1, $2);
        if (
            exists $self->{params}{$param_name}
            && ref($self->{params}{$param_name}) eq 'HASH'
            && ref($self->{params}{$param_name}{value_payload}) eq 'HASH'
        ) {
            return FSM::ParameterValueSupport->resolve_payload_path(
                $self->{params}{$param_name}{value_payload},
                $suffix,
            );
        }
    }

    return undef;
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
    
    # 4. Check params as named HDL parameters, not as clones of their defaults.
    if (exists $self->{params}{$symbol_name}) {
        my $param_value = $self->{params}{$symbol_name};
        my $param_text = ref($param_value) eq 'HASH'
            ? ($param_value->{value_text} // '')
            : $param_value;
        my $param_width = _explicit_parameter_ref_width($param_value);
        fsm_debug("      RESOLVED: $symbol_name as param -> $param_text", 3);
        return FSM::CoreAST::ParameterRef->new(
            $symbol_name,
            value_info => _clone_type_spec($param_value),
            width => $param_width,
            type_spec => ref($param_value) eq 'HASH' ? $param_value->{value_type_spec} : undef,
            default_value_text => $param_text,
        );
    }
    
    # Not found in symbol tables
    return undef;
}

sub resolve_type($self, $type_name) {
    return undef unless defined $type_name;
    my $spec = $self->{types}{$type_name};
    return undef unless defined $spec;
    return _clone_type_spec($spec);
}

sub resolve_type_width($self, $type_name) {
    my $spec = $self->resolve_type($type_name);
    return undef unless $spec && ref($spec) eq 'HASH';
    return undef unless defined $spec->{width};
    return 0 + $spec->{width};
}

sub resolve_positive_integer_scalar($self, $symbol_name) {
    return undef unless defined $symbol_name;
    return undef unless exists $self->{constants}{$symbol_name};
    return FSM::Package::ScalarWidthSupport->positive_integer_from_literal_like(
        $self->{constants}{$symbol_name},
    );
}

# Summaries
sub get_symbol_summary($self) {
    my $constant_definition_count = scalar(keys %{$self->{constant_definitions} || {}});

    my %summary = (
        constants => $constant_definition_count || scalar(keys %{$self->{constants}}),
        enums => scalar(keys %{$self->{enums}}),
        defines => scalar(keys %{$self->{defines}}),
        params => scalar(keys %{$self->{params}}),
        types => scalar(keys %{$self->{types}}),
        aggregate_symbols => scalar(keys %{$self->{aggregate_symbols}}),
    );
    return \%summary;
}

sub _clone_type_spec($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone_type_spec($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone_type_spec($_) } @$value ];
    }

    return $value;
}

sub _explicit_parameter_ref_width($param_value) {
    return undef unless ref($param_value) eq 'HASH';
    return undef unless defined($param_value->{value_width}) && $param_value->{value_width} > 0;

    my $value_kind = $param_value->{value_kind} // '';
    return $param_value->{value_width} if $value_kind ne '' && $value_kind ne 'scalar';

    my $value_text = $param_value->{value_text};
    return $param_value->{value_width}
        if defined($value_text) && $value_text =~ /\A-?\d+'s?[bBoOdDhH]/;

    return undef;
}

sub _literal_to_parameter_payload($literal_expr) {
    return undef unless defined $literal_expr;
    return undef unless blessed($literal_expr) && $literal_expr->isa('FSM::CoreAST::Literal');

    return {
        kind => 'scalar',
        payload => $literal_expr->to_systemverilog,
    };
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
        $summary{$signal_name}{declared_type_name} = $signal->declared_type_name
            if $signal->can('declared_type_name') && defined $signal->declared_type_name;
        $summary{$signal_name}{declared_type_spec} = $signal->declared_type_spec
            if $signal->can('declared_type_spec') && defined $signal->declared_type_spec;
    }
    return \%summary;
}

1;
