package FSM::Adapter::FSMGenFull::Parser;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Data::Dumper;
use FSM::CoreAST;
use FSM::Debug;
use FSM::Package::DeclarativeSymbolResolver;
use FSM::Package::DeclarativeScalarTypeSupport;
use FSM::Package::DeclarativeTypeResolver;
use FSM::Package::SignalManagerProjectionSupport;
use FSM::Package::Symbols;
use FSM::SourceClassifier;

sub new($class, %args) {
    Carp::confess "Parser requires signal_manager" unless $args{signal_manager};
    Carp::confess "Parser requires expression_builder" unless $args{expression_builder};
    
    return bless {
        debug => $args{debug} // 0,
        signal_manager => $args{signal_manager},
        expression_builder => $args{expression_builder},
        fsm_module => undef,
        combinational_dependency_graph => {},
        parsed_transition_targets => [],
    }, $class;
}

sub get_fsm_module($self) {
    return $self->{fsm_module};
}

sub parse_fsm($self, $raw_ast) {
    fsm_trace_enter('Parser parse_fsm() entry', 2);
    fsm_debug("Starting full FSMGen parsing", 3);
    $self->reset_combinational_dependency_tracking();
    $self->reset_transition_target_tracking();

    my $source_info = FSM::SourceClassifier::classify_source_ast($raw_ast);
    if ($source_info->{kind} eq 'composition') {
        my $header = $source_info->{header} // '?top:name';
        fsm_trace_decision(0, "Detected composition source '$header' at FSM-only parser boundary", 1);
        Carp::confess
            "Composition source '$header' is not supported by the FSM-only parser. ".
            "Route '?top:name' inputs through the composition pipeline described in docs/COMPOSITION_SCOPE.md";
    }
    if (($source_info->{kind} // 'unknown') eq 'unknown' && defined($source_info->{header}) && $source_info->{header} =~ /^\?[A-Za-z_][\w-]*:/) {
        my $header = $source_info->{header};
        fsm_trace_decision(0, "Detected unsupported tagged top-level source '$header'", 1);
        Carp::confess
            "Unsupported top-level source '$header'. ".
            "The active toolchain supports '?fsm:name', '?dt:name', '?mod:name', '?module:name', and '+fsm' as single-module sources, and '?top:name' through the composition pipeline. ".
            "Other tagged source kinds such as '?define:' are out of active support. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }
    
    if (ref($raw_ast) eq 'ARRAY') {
        if (@$raw_ast > 0 && !ref($raw_ast->[0]) && $raw_ast->[0] =~ /^\?fsm:/) {
            fsm_trace_decision(1, "Detected '?fsm:' structured AST header", 2);
            my $module = $self->parse_fsm_module($raw_ast, 0, 'fsm');
            fsm_trace_exit('Parser parse_fsm() completed via ?fsm path', 2);
            return $module;
        }

        if (@$raw_ast > 0 && !ref($raw_ast->[0]) && $raw_ast->[0] =~ /^\?(?:dt|mod|module):/) {
            fsm_trace_decision(1, "Detected standalone-DT structured AST header", 2);
            my $module = $self->parse_fsm_module($raw_ast, 0, 'dt');
            fsm_trace_exit('Parser parse_fsm() completed via ?dt path', 2);
            return $module;
        }
        
        if (@$raw_ast > 0 && ref($raw_ast->[0]) eq 'ARRAY' && $raw_ast->[0][0] eq '+fsm') {
            fsm_trace_decision(1, "Detected '+fsm' flattened AST header", 2);
            my $module = $self->parse_fsm_module(['root_array', $raw_ast], 1, 'fsm');
            fsm_trace_exit('Parser parse_fsm() completed via +fsm path', 2);
            return $module;
        }
        
        for my $ast_node (@$raw_ast) {
            if (ref($ast_node) eq 'ARRAY' && @$ast_node > 0 && !ref($ast_node->[0]) && $ast_node->[0] =~ /^\?fsm:/) {
                fsm_trace_decision(1, "Detected nested '?fsm:' AST node", 2);
                my $module = $self->parse_fsm_module($ast_node, 0, 'fsm');
                fsm_trace_exit('Parser parse_fsm() completed via nested ?fsm path', 2);
                return $module;
            }
            if (ref($ast_node) eq 'ARRAY' && @$ast_node > 0 && !ref($ast_node->[0]) && $ast_node->[0] =~ /^\?(?:dt|mod|module):/) {
                fsm_trace_decision(1, "Detected nested standalone-DT AST node", 2);
                my $module = $self->parse_fsm_module($ast_node, 0, 'dt');
                fsm_trace_exit('Parser parse_fsm() completed via nested ?dt path', 2);
                return $module;
            }
        }
    }
    
    fsm_trace_decision(0, "AST root did not match expected FSM shape", 1);
    my $root_display = $self->describe_top_level_source_root($raw_ast);
    Carp::confess
        "Malformed top-level source root '$root_display'. ".
        "The active single-module parser expects '?fsm:module_name', one of '?dt:module_name' / '?mod:module_name' / '?module:module_name', or the legacy '+fsm' root family at the source root. ".
        "Bare top-level forms like '(+system ...)' or '(idle ...)' must be wrapped inside a supported source root. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub parse_fsm_module($self, $fsm_ast, $is_flat_ast = 0, $root_kind = 'fsm') {
    fsm_trace_enter('Parser parse_fsm_module() entry', 2);
    $self->reset_combinational_dependency_tracking();
    $self->reset_transition_target_tracking();
    my $module_name;
    my $fsm_contents;
    
    if ($is_flat_ast) {
        fsm_trace_decision(1, 'Using flat AST module header decoding path', 2);
        my $ast_array = $fsm_ast->[1];
        ($module_name, $fsm_contents) = $self->decode_flat_fsm_structure($ast_array);
    } else {
        fsm_trace_decision(1, 'Using standard AST module header decoding path', 2);
        my ($fsm_header, $contents) = @$fsm_ast;
        $module_name = $self->decode_structured_module_name($fsm_header, $root_kind);
        $fsm_contents = $contents;
    }

    $self->validate_module_root_body($module_name, $fsm_contents, $is_flat_ast, $root_kind);
    
    fsm_debug("Parsing FSM module: $module_name", 3);
    
    my $module = FSM::CoreAST::FSMModule->new(name => $module_name);
    $self->{fsm_module} = $module;
    $module->{attributes}{source_root_kind} = $root_kind;
    $module->{attributes}{direct_root_symbols} //= FSM::Package::Symbols->new();
    my $root_contract_label = $self->root_contract_label($root_kind);
    my $top_level_forms_desc = $self->supported_top_level_forms_description($root_kind, $is_flat_ast);
    my $supported_directives_desc = $self->supported_directives_description($root_kind);
    
    my @pending_size_sections;
    my @pending_constant_entries;
    my @pending_enum_entries;
    my @pending_type_entries;

    for my $element (@$fsm_contents) {
        Carp::confess
            "Malformed top-level " . ($root_kind eq 'dt' ? 'DT' : 'FSM') . " body item '".$self->describe_top_level_source_root([$element])."' in source '$module_name'. ".
            $top_level_forms_desc . " ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless ref($element) eq 'ARRAY';

        next unless ref($element) eq 'ARRAY';
        my $element_name = $element->[0];
        
        if ($element_name eq '+fsm') {
            next;
        } elsif ($element_name eq '+system') {
            fsm_debug("Parsing +system block", 3);
            $self->parse_system_section($element);
        } elsif ($element_name eq '+size') {
            fsm_debug("Collecting +size block", 3);
            push @pending_size_sections, $element;
        } elsif ($element_name eq '+constants') {
            fsm_debug("Collecting constants section", 3);
            push @pending_constant_entries, @{ $self->parse_constants_section($element) };
        } elsif ($element_name eq '+enums') {
            fsm_debug("Collecting enums section", 3);
            push @pending_enum_entries, @{ $self->parse_enums_section($element) };
        } elsif ($element_name eq '+types') {
            fsm_debug("Collecting types section", 3);
            push @pending_type_entries, @{ $self->parse_types_section($element) };
        } elsif ($element_name eq '+import') {
            fsm_debug("Parsing import section", 3);
            $self->parse_import_section($module_name, $element);
        }
    }

    $self->resolve_pending_direct_root_types(
        $module_name,
        \@pending_type_entries,
    );

    $self->resolve_pending_direct_root_symbols(
        $module_name,
        \@pending_constant_entries,
        \@pending_enum_entries,
    );

    for my $size_ast (@pending_size_sections) {
        $self->parse_size_section($size_ast);
    }

    for my $element (@$fsm_contents) {
        next unless ref($element) eq 'ARRAY';
        my $element_name = $element->[0];

        if (
            defined($element_name)
            && !ref($element_name)
            && (
                $element_name eq '+fsm'
                || $element_name eq '+system'
                || $element_name eq '+size'
                || $element_name eq '+constants'
                || $element_name eq '+enums'
                || $element_name eq '+types'
                || $element_name eq '+import'
            )
        ) {
            next;
        }

        if ($element_name eq '+define') {
            fsm_debug("Parsing define directive", 3);
            $self->parse_define_directive($element);
        } elsif ($element_name eq '+params') {
            fsm_debug("Parsing params section", 3);
            $self->parse_params_section($element);
        } elsif ($element_name eq ':=') {
            fsm_debug("Parsing init/reset directive", 3);
            $self->parse_init_assignment_directive($element);
        } elsif (
            $element_name =~ /^[a-zA-Z_]/
                && ref($element->[1]) eq 'ARRAY'
                && @{$element->[1]} >= 1
                && !ref($element->[1][0])
                && $element->[1][0] eq ':='
        ) {
            my @tail = @{$element->[1]};
            my $detail = join(' ', map {
                defined($_) ? (ref($_) ? ref($_) : $_) : 'undef'
            } ($element_name, @tail));
            Carp::confess
                "Unsupported top-level form '($detail)'. ".
                $top_level_forms_desc . " ".
                "Future-looking bare forms such as '(lhs := value)' are not part of the active contract yet. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        } elsif (
            $element_name =~ /^[a-zA-Z_]/
                && ref($element->[1]) eq 'ARRAY'
                && @{$element->[1]} == 1
                && !ref($element->[1][0])
        ) {
            my $detail = join(' ', map {
                defined($_) ? (ref($_) ? ref($_) : $_) : 'undef'
            } ($element_name, $element->[1][0]));
            Carp::confess
                "Unsupported top-level form '($detail)'. ".
                $top_level_forms_desc . " ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        } elsif ($element_name =~ /^\+/) {
            Carp::confess
                "Unsupported top-level directive '$element_name'. ".
                $supported_directives_desc . " ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        } elsif ($element_name =~ /^[a-zA-Z_]/ && $element_name !~ /^(idle|-syncrst|-syncreset|-asyncrst|-asyncreset)$/ && !ref($element->[1])) {
            my $detail = join(' ', map {
                defined($_) ? (ref($_) ? ref($_) : $_) : 'undef'
            } @$element);
            Carp::confess
                "Unsupported top-level form '($detail)'. ".
                $top_level_forms_desc . " ".
                "Future-looking bare forms such as '(lhs := value)' are not part of the active contract yet. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        } else {
            fsm_debug("Parsing state block: $element_name", 3);
            my $state = $self->parse_state($element);
            if ($root_kind eq 'dt' && $state) {
                Carp::confess
                    "Unsupported top-level block '$element_name' inside '$root_contract_label'. ".
                    "The active '?dt:name' contract currently supports only general DT blocks named like '(-foo ...)' at top level. ".
                    "FSM-state blocks and dedicated reset-state blocks remain part of '?fsm:name'. ".
                    "See docs/USER_GUIDE.md for the current supported boundary.\n"
                    unless $state->can('is_standalone_dt') && $state->is_standalone_dt;
            }
            $module->add_state($state) if $state;
        }
    }

    $self->validate_transition_targets($module);
    $self->validate_no_combinational_self_dependency();
    fsm_trace_exit("Parser parse_fsm_module() completed for '$module_name'", 2);
    return $module;
}

sub validate_module_root_body($self, $module_name, $fsm_contents, $is_flat_ast = 0, $root_kind = 'fsm') {
    my $root_family = $is_flat_ast ? '+fsm' : '?' . $root_kind . ':' . $module_name;
    my $body_desc = $root_kind eq 'dt'
        ? "The active contract expects a non-empty list of directive sections, ':=' directives, and general DT blocks inside the DT source root. "
        : "The active contract expects a non-empty list of directive sections, ':=' directives, and state/DT blocks inside the FSM source root. ";

    Carp::confess
        "Malformed top-level " . ($root_kind eq 'dt' ? 'DT' : 'FSM') . " body for source '$root_family'. ".
        $body_desc .
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($fsm_contents) eq 'ARRAY' && @$fsm_contents;

    return 1;
}

sub decode_flat_fsm_structure($self, $ast_array) {
    my $fsm_header = ref($ast_array) eq 'ARRAY' ? $ast_array->[0] : undef;
    my $name_payload = ref($fsm_header) eq 'ARRAY' ? $fsm_header->[1] : undef;
    my $module_name = ref($name_payload) eq 'ARRAY' ? $name_payload->[0] : undef;

    if (ref($name_payload) eq 'ARRAY'
        && defined($module_name)
        && !ref($module_name)
        && $module_name ne '')
    {
        if (@$ast_array == 1) {
            my @nested_contents = @$name_payload[1 .. $#$name_payload];
            return ($module_name, \@nested_contents);
        }

        if (@$name_payload == 1) {
            return ($module_name, $ast_array);
        }
    }

    Carp::confess
        "Malformed '+fsm' root. ".
        "The active contract supports the legacy '+fsm' source family only as either ".
        "'(+fsm module_name)' followed by sibling sections/state/DT blocks, or ".
        "the nested legacy root form '(+fsm module_name ... )'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub decode_structured_module_name($self, $fsm_header, $root_kind = 'fsm') {
    if ($root_kind eq 'dt') {
        return $1
            if defined($fsm_header)
            && !ref($fsm_header)
            && $fsm_header =~ /\A\?(?:dt|mod|module):([A-Za-z_]\w*)\z/;
    }

    return $1
        if defined($fsm_header)
        && !ref($fsm_header)
        && $fsm_header =~ /\A\?$root_kind:([A-Za-z_]\w*)\z/;

    my $display = defined($fsm_header) ? (ref($fsm_header) ? ref($fsm_header) : $fsm_header) : 'undef';
    my $root_contract_label = $self->root_contract_label($root_kind);
    Carp::confess
        "Malformed top-level " . ($root_kind eq 'dt' ? 'DT' : 'FSM') . " source '$display'. ".
        "The active contract expects '$root_contract_label' with an HDL-identifier-compatible module name ([A-Za-z_]\\w*). ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub root_contract_label($self, $root_kind = 'fsm') {
    return "one of '?dt:name', '?mod:name', or '?module:name'" if $root_kind eq 'dt';
    return '?fsm:name';
}

sub supported_directives_description($self, $root_kind = 'fsm') {
    return "The active contract currently supports only the conventional '+system' form, '+size', '+constants', '+enums', '+types', '+import', '+define', and '+params' inside '?dt:name'"
        if $root_kind eq 'dt';
    return "The active contract currently supports only '+system', '+size', '+constants', '+enums', '+types', '+import', '+define', and '+params' inside '?fsm:name'";
}

sub supported_top_level_forms_description($self, $root_kind = 'fsm', $is_flat_ast = 0) {
    return "Inside '?dt:name', the active contract supports the conventional '+system' section, other directive sections, ':=' init/reset directives, and general DT blocks like '(-foo ...)' only"
        if $root_kind eq 'dt';
    return "Inside '?fsm:module_name' and the legacy '+fsm' root family, top-level content must be a list of directive sections, ':=' directives, and state/DT blocks"
        if $is_flat_ast;
    return "Inside '?fsm:name', the active contract supports directive sections, ':=' init/reset directives, and state/DT blocks only";
}

sub describe_top_level_source_root($self, $raw_ast) {
    return 'undef' unless defined $raw_ast;
    return ref($raw_ast) unless ref($raw_ast) eq 'ARRAY';
    return 'empty' unless @$raw_ast;

    if (!ref($raw_ast->[0])) {
        return $raw_ast->[0];
    }

    if (ref($raw_ast->[0]) eq 'ARRAY' && @{$raw_ast->[0]} > 0 && !ref($raw_ast->[0][0])) {
        return $raw_ast->[0][0];
    }

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY' && @$ast_node > 0;
        next if ref($ast_node->[0]);
        return $ast_node->[0];
    }

    return 'unknown';
}

sub parse_constants_section($self, $constants_ast) {
    my (undef, $constants_list) = @$constants_ast;

    Carp::confess
        "Malformed '+constants' section. ".
        "The active contract supports '+constants' only as a non-empty list of '(NAME value)' entries where the value is either a scalar literal or a bounded aggregate list/hash payload. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($constants_list) eq 'ARRAY' && @$constants_list;

    my @constant_entries;
    for my $constant_def (@$constants_list) {
        Carp::confess
            "Malformed '+constants' entry. ".
            "Each '+constants' entry must be a pair '(NAME value)'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless ref($constant_def) eq 'ARRAY' && @$constant_def == 2;

        my ($name, $value) = @$constant_def;
        my $resolved_name = $self->unwrap_scalar_token($name);

        Carp::confess
            "Malformed '+constants' entry for constant '".$self->describe_contract_name($resolved_name)."'. ".
            "Each '+constants' entry must use an HDL-identifier-compatible name. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless $self->is_contract_identifier($resolved_name);

        $self->{signal_manager}->record_constant_definition($resolved_name);
        push @constant_entries, {
            name => $resolved_name,
            value_ast => $value,
        };
    }

    if ($self->{fsm_module} && $self->{fsm_module}->can('direct_root_symbols')) {
        $self->{fsm_module}->direct_root_symbols->push_raw_block($constants_ast);
    }

    return \@constant_entries;
}

sub parse_types_section($self, $types_ast) {
    my (undef, $types_list) = @$types_ast;

    Carp::confess
        "Malformed '+types' section. ".
        "The active contract supports '+types' only as a non-empty list of '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', or '(type NAME other_type)' entries. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($types_list) eq 'ARRAY' && @$types_list;

    my @type_entries;
    for my $type_def (@$types_list) {
        Carp::confess
            "Malformed '+types' entry. ".
            "Each '+types' entry must use the shape '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', or '(type NAME other_type)'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless ref($type_def) eq 'ARRAY' && @$type_def >= 2;

        my ($keyword, $name, $spec_ast);
        if (@$type_def >= 3) {
            ($keyword, $name) = @$type_def[0, 1];
            $spec_ast = @$type_def == 3
                ? $type_def->[2]
                : [ @$type_def[2 .. $#$type_def] ];
        } elsif (@$type_def == 2 && ref($type_def->[1]) eq 'ARRAY' && @{$type_def->[1]} >= 2) {
            $keyword = $type_def->[0];
            $name = $type_def->[1][0];
            $spec_ast = @{$type_def->[1]} == 2
                ? $type_def->[1][1]
                : [ @{$type_def->[1]}[1 .. $#{$type_def->[1]}] ];
        } else {
            Carp::confess
                "Malformed '+types' entry. ".
                "Each '+types' entry must use the shape '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', or '(type NAME other_type)'. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        }

        my $resolved_keyword = $self->unwrap_scalar_token($keyword);
        my $resolved_name = $self->unwrap_scalar_token($name);

        Carp::confess
            "Malformed '+types' entry for type '".$self->describe_contract_name($resolved_name)."'. ".
            "Each '+types' entry must begin with the literal keyword 'type' and use an HDL-identifier-compatible type name. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless defined($resolved_keyword)
                && !ref($resolved_keyword)
                && $resolved_keyword eq 'type'
                && $self->is_contract_identifier($resolved_name);

        push @type_entries, {
            name => $resolved_name,
            spec_ast => $spec_ast,
        };
    }

    if ($self->{fsm_module} && $self->{fsm_module}->can('direct_root_symbols')) {
        $self->{fsm_module}->direct_root_symbols->push_raw_block($types_ast);
    }

    return \@type_entries;
}

sub parse_size_section($self, $size_ast) {
    my (undef, $size_entries) = @$size_ast;

    # Legacy no-op form still exists in the shipped corpus.
    return unless defined $size_entries;

    Carp::confess
        "Malformed '+size' section. ".
        "The active contract supports '+size' only as a list of '(signal width)' entries, ".
        "or the legacy empty no-op form '(+size)'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($size_entries) eq 'ARRAY';

    for my $size_def (@$size_entries) {
        Carp::confess
            "Malformed '+size' entry. ".
            "Each '+size' entry must be a pair '(signal positive_integer_width)'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless ref($size_def) eq 'ARRAY' && @$size_def == 2;

        my ($sig, $width) = @$size_def;
        my $resolved_sig = $self->unwrap_scalar_token($sig);
        my $resolved_width = $self->unwrap_scalar_token($width);

        Carp::confess
            "Malformed '+size' entry for signal '$resolved_sig'. ".
            "Each '+size' entry must use an HDL-identifier-compatible signal name and either a positive integer width or a named scalar type. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless defined($resolved_sig)
                && !ref($resolved_sig)
                && $resolved_sig =~ /\A[A-Za-z_]\w*\z/;

        my $width_contract = $self->resolve_declared_width_contract(
            signal_name => $resolved_sig,
            width_token => $resolved_width,
        );

        $self->{signal_manager}->register_signal(
            $resolved_sig,
            width => $width_contract->{width},
            signed => ($width_contract->{signed} // 0),
            state_model => $width_contract->{state_model},
            width_declared => 1,
        );

        # Keep rm/mr auxiliary outputs width-aligned with their parent signal
        # even when +size appears after assignment actions.
        my $next_aux = "next_$resolved_sig";
        if ($self->{signal_manager}->get_signal($next_aux)) {
            $self->{signal_manager}->register_signal(
                $next_aux,
                width => $width_contract->{width},
                signed => ($width_contract->{signed} // 0),
                state_model => $width_contract->{state_model},
                is_output => 1,
                is_aux_output => 1,
                width_declared => 1,
            );
        }
        my $q_aux = "${resolved_sig}_r";
        if ($self->{signal_manager}->get_signal($q_aux)) {
            $self->{signal_manager}->register_signal(
                $q_aux,
                width => $width_contract->{width},
                signed => ($width_contract->{signed} // 0),
                state_model => $width_contract->{state_model},
                is_output => 1,
                is_aux_output => 1,
                width_declared => 1,
            );
        }
    }
}

sub parse_system_section($self, $system_ast) {
    my (undef, $system_entries) = @$system_ast;

    Carp::confess
        "The active '+system' contract currently supports only the conventional shared system declaration ".
        "'(+system (clock clk) (sreset rstn))' or '(+system (clock clk) (asreset rstn))'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($system_entries) eq 'ARRAY' && @$system_entries;

    my %seen;
    my %parsed;

    for my $entry (@$system_entries) {
        Carp::confess
            "Unsupported '+system' entry structure. ".
            "The active contract currently supports only '(clock clk)' plus one reset declaration naming 'rstn' via '(sreset rstn)' or '(asreset rstn)' inside '+system'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 2;

        my ($directive, $name) = @$entry;
        my $resolved_name = $self->unwrap_scalar_token($name);

        Carp::confess
            "Unsupported '+system' entry '$directive'. ".
            "The active contract currently supports only '(clock clk)' plus '(sreset rstn)' or '(asreset rstn)'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless defined $directive && !ref($directive);

        Carp::confess
            "Unsupported '+system' entry structure. ".
            "The active contract currently supports only '(clock clk)' plus one reset declaration naming 'rstn' via '(sreset rstn)' or '(asreset rstn)' inside '+system'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless defined $resolved_name && !ref($resolved_name);

        Carp::confess
            "Duplicate '+system' entry '$directive'. ".
            "The active contract currently expects exactly one '(clock clk)' and one reset declaration naming 'rstn'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            if $seen{$directive}++;

        if ($directive eq 'clock') {
            Carp::confess
                "Unsupported '+system' clock name '$resolved_name'. ".
                "The active contract currently supports only '(clock clk)'. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n"
                unless defined $resolved_name && !ref($resolved_name) && $resolved_name eq 'clk';

            $parsed{clock} = $resolved_name;
        } elsif ($directive eq 'sreset' || $directive eq 'asreset') {
            Carp::confess
                "Duplicate '+system' reset declaration '$directive'. ".
                "The active contract currently expects exactly one reset declaration naming 'rstn'. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n"
                if $parsed{reset};

            Carp::confess
                "Unsupported '+system' reset name '$resolved_name'. ".
                "The active contract currently supports only '(sreset rstn)' or '(asreset rstn)'. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n"
                unless defined $resolved_name && !ref($resolved_name) && $resolved_name eq 'rstn';

            $parsed{reset} = $resolved_name;
            $parsed{reset_keyword} = $directive;
        } else {
            Carp::confess
                "Unsupported '+system' entry '$directive'. ".
                "The active contract currently supports only '(clock clk)' plus '(sreset rstn)' or '(asreset rstn)'. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        }
    }

    Carp::confess
        "Incomplete '+system' section. ".
        "The active contract currently expects exactly '(clock clk)' and one reset declaration naming 'rstn'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless $parsed{clock} && $parsed{reset};

    my $fsm_module = $self->{fsm_module};
    $fsm_module->{attributes}{system_contract} = {
        clock => $parsed{clock},
        reset => $parsed{reset},
        reset_keyword => $parsed{reset_keyword},
    };
    $fsm_module->{clock_domains}{default} = $parsed{clock};
    $fsm_module->{reset_domains}{default} = $parsed{reset};

    $self->{signal_manager}->register_signal(
        $parsed{clock},
        type => 'clock',
        width => 1,
        attributes => { is_system_signal => 1 },
    );
    $self->{signal_manager}->register_signal(
        $parsed{reset},
        type => 'reset',
        width => 1,
        attributes => { is_system_signal => 1 },
    );
}

sub unwrap_scalar_token($self, $value) {
    my $unwrapped = $value;
    while (ref($unwrapped) eq 'ARRAY' && @$unwrapped == 1) {
        $unwrapped = $unwrapped->[0];
    }
    return $unwrapped;
}

sub unwrap_single_nested_list($self, $value) {
    my $unwrapped = $value;
    while (ref($unwrapped) eq 'ARRAY' && @$unwrapped == 1 && ref($unwrapped->[0]) eq 'ARRAY') {
        $unwrapped = $unwrapped->[0];
    }
    return $unwrapped;
}

sub is_contract_identifier($self, $value) {
    return defined($value)
        && !ref($value)
        && $value =~ /\A[A-Za-z_]\w*\z/;
}

sub describe_contract_name($self, $value) {
    return defined($value) && !ref($value) ? $value : 'unknown';
}

sub is_contract_type_reference($self, $value) {
    return defined($value)
        && !ref($value)
        && $value =~ /\A(?:[A-Za-z_]\w*)(?:\.[A-Za-z_]\w*)?\z/;
}

sub resolve_declared_width_token($self, %args) {
    my $width_contract = $self->resolve_declared_width_contract(%args);
    return $width_contract->{width};
}

sub resolve_declared_width_contract($self, %args) {
    my $signal_name = $args{signal_name} // 'signal';
    my $width_token = $args{width_token};

    return {
        width => 0 + $width_token,
        signed => 0,
        state_model => undef,
    }
        if defined($width_token)
            && !ref($width_token)
            && $width_token =~ /\A\d+\z/
            && $width_token > 0;

    if ($self->is_contract_type_reference($width_token)) {
        my $resolved_type = $self->{signal_manager}->resolve_type($width_token);
        if ($resolved_type && ref($resolved_type) eq 'HASH'
            && defined($resolved_type->{width}) && $resolved_type->{width} > 0) {
            return {
                width => 0 + $resolved_type->{width},
                signed => ($resolved_type->{signed} // 0) ? 1 : 0,
                state_model => $resolved_type->{state_model},
            };
        }

        my $resolved_scalar_width = $self->{signal_manager}->resolve_positive_integer_scalar($width_token);
        return {
            width => $resolved_scalar_width,
            signed => 0,
            state_model => undef,
        } if defined $resolved_scalar_width && $resolved_scalar_width > 0;
    }

    Carp::confess
        "Malformed '+size' entry for signal '$signal_name'. ".
        "Each '+size' entry must use an HDL-identifier-compatible signal name and either a positive integer width, a named scalar type such as 'bit', 'byte', or 'pkg_name.byte', or a positive integer scalar symbol such as 'BYTE_W' or 'pkg_name.BYTE_W'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub canonicalize_scalar_type_spec($self, %args) {
    my $module_name = $args{module_name} // 'source';
    my $type_name = $args{type_name} // 'unknown';
    my $spec_ast = $args{spec_ast};

    my $resolved_spec = FSM::Package::DeclarativeScalarTypeSupport->canonicalize_type_spec(
        spec_ast => $spec_ast,
        unwrap_scalar_token => sub ($value) { return $self->unwrap_scalar_token($value) },
        unwrap_single_nested_list => sub ($value) { return $self->unwrap_single_nested_list($value) },
        is_contract_type_reference => sub ($value) { return $self->is_contract_type_reference($value) },
        resolve_type_reference => sub ($type_ref) { return $self->{signal_manager}->resolve_type($type_ref) },
    );
    return $resolved_spec if $resolved_spec;

    Carp::confess
        "Malformed '+types' entry for type '$type_name' in source '$module_name'. ".
        "The first active '+types' lane supports only 'bit', '(bits N)', '(signed bit)', '(signed (bits N))', '(two_state ...)', '(four_state ...)', or aliases to already-resolved scalar types. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub canonicalize_constant_literal_payload($self, %args) {
    my $module_name = $args{module_name} // 'source';
    my $section_header = $args{section_header} // '+constants';
    my $symbol_kind = $args{symbol_kind} // 'symbol';
    my $symbol_name = $args{symbol_name} // 'unknown';
    my $value_token = $args{value_token};

    my $literal_expr = eval {
        $self->{expression_builder}->parse_scalar_expression($value_token);
    };
    my $parse_error = $@;

    Carp::confess
        "Malformed '$section_header' entry for $symbol_kind '$symbol_name' in source '$module_name' with value token '$value_token'. ".
        "Each '$section_header' value must resolve to a literal scalar value such as '0', '8'3', '8'hA5', or 'const_8b0'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        if $parse_error || ref($literal_expr) ne 'FSM::CoreAST::Literal';

    my $value = $literal_expr->value;
    my $width = $literal_expr->width;
    my $radix = $literal_expr->radix // 'decimal';

    return $value unless defined $width;
    return $width."'b".$value if $radix eq 'binary';
    return $width."'h".$value if $radix eq 'hex';
    return $width."'d".$value;
}

sub canonicalize_constant_payload($self, %args) {
    my $module_name = $args{module_name} // 'source';
    my $section_header = $args{section_header} // '+constants';
    my $symbol_kind = $args{symbol_kind} // 'constant';
    my $symbol_name = $args{symbol_name} // 'unknown';
    my $value_ast = $args{value_ast};

    my $scalar_value = $self->unwrap_scalar_token($value_ast);
    if (defined($scalar_value) && !ref($scalar_value)) {
        my $payload = $self->canonicalize_constant_literal_payload(
            %args,
            value_token => $scalar_value,
        );
        return {
            kind => 'scalar',
            payload => $payload,
        };
    }

    Carp::confess
        "Malformed '$section_header' entry for $symbol_kind '$symbol_name' in source '$module_name'. ".
        "Each '$section_header' value must be either a scalar literal, a non-empty list aggregate, or a non-empty hash-like aggregate written as '(member value)' pairs. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($value_ast) eq 'ARRAY';

    Carp::confess
        "Malformed '$section_header' entry for $symbol_kind '$symbol_name' in source '$module_name' with an empty aggregate value. ".
        "Aggregate constant values must be non-empty lists or non-empty hash-like member sets. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless @$value_ast;

    my $value_items = $self->constant_value_items($value_ast);

    Carp::confess
        "Malformed '$section_header' entry for $symbol_kind '$symbol_name' in source '$module_name' with an empty aggregate value. ".
        "Aggregate constant values must be non-empty lists or non-empty hash-like member sets. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless @$value_items;

    my $hash_like_entries = 0;
    my $non_hash_entries = 0;
    for my $entry (@$value_items) {
        my $member_name = (ref($entry) eq 'ARRAY' && @$entry == 2)
            ? $self->unwrap_scalar_token($entry->[0])
            : undef;
        if (defined($member_name) && $self->is_contract_identifier($member_name)) {
            $hash_like_entries++;
        } else {
            $non_hash_entries++;
        }
    }

    if ($hash_like_entries && !$non_hash_entries) {
        my %members;
        my @member_order;
        for my $entry (@$value_items) {
            my ($member_name_ast, $member_value_ast) = @$entry;
            my $member_name = $self->unwrap_scalar_token($member_name_ast);
            Carp::confess
                "Malformed '$section_header' entry for $symbol_kind '$symbol_name' in source '$module_name' with duplicate member '$member_name'. ".
                "Hash-like aggregate values must use each member name at most once so one packed aggregate order remains unambiguous. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n"
                if exists $members{$member_name};
            push @member_order, $member_name;
            $members{$member_name} = $self->canonicalize_constant_payload(
                module_name => $module_name,
                section_header => $section_header,
                symbol_kind => "$symbol_kind member",
                symbol_name => $symbol_name.'.'.$member_name,
                value_ast => $member_value_ast,
            );
        }

        return {
            kind => 'map',
            member_order => \@member_order,
            members => \%members,
        };
    }

    Carp::confess
        "Malformed '$section_header' entry for $symbol_kind '$symbol_name' in source '$module_name' with a mixed aggregate value. ".
        "List-style and hash-style aggregate entries cannot be mixed in one constant value. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        if $hash_like_entries && $non_hash_entries;

    my @items;
    for my $index (0 .. $#$value_items) {
        push @items, $self->canonicalize_constant_payload(
            module_name => $module_name,
            section_header => $section_header,
            symbol_kind => "$symbol_kind item",
            symbol_name => $symbol_name."[$index]",
            value_ast => $value_items->[$index],
        );
    }

    return {
        kind => 'list',
        items => \@items,
    };
}

sub constant_value_items($self, $value_ast) {
    my $cursor = $value_ast;

    while (ref($cursor) eq 'ARRAY' && @$cursor == 1 && ref($cursor->[0]) eq 'ARRAY') {
        $cursor = $cursor->[0];
    }

    my @items;
    while (1) {
        if (!ref($cursor)) {
            push @items, $cursor if defined $cursor;
            last;
        }

        if (ref($cursor) eq 'ARRAY' && @$cursor == 1) {
            push @items, $cursor->[0] if defined $cursor->[0];
            last;
        }

        if (ref($cursor) eq 'ARRAY' && @$cursor == 2) {
            push @items, $cursor->[0];
            $cursor = $cursor->[1];
            next;
        }

        if (ref($cursor) eq 'ARRAY') {
            push @items, @$cursor;
            last;
        }

        push @items, $cursor;
        last;
    }

    return \@items;
}

sub reset_transition_target_tracking($self) {
    $self->{parsed_transition_targets} = [];
}

sub record_transition_target($self, $target_state) {
    push @{$self->{parsed_transition_targets}}, {
        target_state => $target_state,
        source_state => ($self->{current_state} && $self->{current_state}->can('name'))
            ? $self->{current_state}->name
            : undef,
    };
}

sub validate_transition_targets($self, $fsm_module) {
    return unless $fsm_module && $fsm_module->can('states') && $fsm_module->states;

    my %regular_states = map { $_->name => 1 }
        grep { $_ && $_->can('is_regular_state') ? $_->is_regular_state : 0 }
        @{$fsm_module->states};

    for my $transition (@{$self->{parsed_transition_targets} || []}) {
        my $target_state = $transition->{target_state};
        next if exists $regular_states{$target_state};

        my $source_desc = defined($transition->{source_state}) && $transition->{source_state} ne ''
            ? " from state/DT '$transition->{source_state}'"
            : '';

        Carp::confess
            "Unknown transition target '$target_state'$source_desc. ".
            "State transitions must target a declared regular FSM-state DT block inside the same FSM source. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }
}

sub is_compound_update_shorthand($self, $action_target, $action_spec) {
    return 0 unless defined $action_target;
    return 0 unless ref($action_spec) eq 'ARRAY' && @$action_spec >= 1;
    
    # Supported forms:
    #   (++ signal)
    #   (-- signal)
    #   (+= signal) / (-= signal)
    #   (+=2 signal) / (-=4 signal)
    #   (+= signal amount) / (-= signal amount)
    return ($action_target =~ /^(?:\+\+|--|\+=.*|-=.*)$/) ? 1 : 0;
}

sub is_inline_compound_modifier_spec($self, $spec) {
    return 0 unless ref($spec) eq 'ARRAY' && @$spec >= 1;
    return 0 if ref($spec->[0]);
    return ($spec->[0] eq '+=' || $spec->[0] eq '-=') ? 1 : 0;
}

sub describe_inline_compound_modifier($self, $spec) {
    return 'undef' unless defined $spec;
    return ref($spec) unless ref($spec) eq 'ARRAY';

    my @parts;
    for my $part (@$spec) {
        if (ref($part) eq 'ARRAY') {
            push @parts, map {
                !defined($_) ? 'undef'
                : ref($_) ? ref($_)
                : $_
            } @$part;
        } else {
            push @parts, !defined($part) ? 'undef'
                : ref($part) ? ref($part)
                : $part;
        }
    }

    return '(' . join(' ', @parts) . ')';
}

sub normalize_inline_compound_modifier($self, $signal_name, $compound_spec) {
    my $modifier_desc = $self->describe_inline_compound_modifier($compound_spec);

    Carp::confess
        "Malformed inline compound modifier '$modifier_desc' on signal '$signal_name'. ".
        "Inline compound modifiers must use '(+=)', '(-=)', '(+= delta)', or '(-= delta)' after the RHS expression. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless $self->is_inline_compound_modifier_spec($compound_spec) && @$compound_spec <= 2;

    my ($compound_op, $compound_payload) = @$compound_spec;
    my $delta_spec;

    if (@$compound_spec == 1) {
        $delta_spec = '1';
    } elsif (ref($compound_payload) eq 'ARRAY') {
        Carp::confess
            "Malformed inline compound modifier '$modifier_desc' on signal '$signal_name'. ".
            "Inline compound modifiers must use '(+=)', '(-=)', '(+= delta)', or '(-= delta)' after the RHS expression. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless @$compound_payload == 1;
        $delta_spec = $compound_payload->[0];
    } else {
        $delta_spec = $compound_payload;
    }

    $delta_spec = '1' unless defined $delta_spec;
    return ($compound_op, $delta_spec);
}

sub parse_compound_update_shorthand($self, $action) {
    my ($compound_token, $args) = @$action;
    Carp::confess
        "Malformed update shorthand '".$self->describe_action_for_error($action)."'. ".
        "Update shorthand must target a scalar signal name, for example '(++ counter)', '(+= counter)', '(+=4 counter)', or '(+= counter 4)'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($args) eq 'ARRAY' && @$args >= 1;
    
    my ($compound_op, $delta_spec);
    
    if ($compound_token eq '++') {
        $compound_op = '+=';
        $delta_spec = '1';
    } elsif ($compound_token eq '--') {
        $compound_op = '-=';
        $delta_spec = '1';
    } elsif ($compound_token =~ /^(\+=|-=)(.+)$/) {
        $compound_op = $1;
        $delta_spec = $2;
        $delta_spec =~ s/^\s+|\s+$//g;
    } elsif ($compound_token eq '+=' || $compound_token eq '-=') {
        $compound_op = $compound_token;
    } else {
        return undef;
    }
    
    my $signal_name = $args->[0];
    Carp::confess
        "Malformed update shorthand '".$self->describe_action_for_error($action)."'. ".
        "Update shorthand must target a scalar signal name, for example '(++ counter)', '(+= counter)', '(+=4 counter)', or '(+= counter 4)'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless defined $signal_name && !ref($signal_name);
    
    my @remaining = @$args[1 .. $#$args];
    if (!defined($delta_spec) && @remaining) {
        $delta_spec = shift @remaining;
    }
    $delta_spec = '1' unless defined $delta_spec;
    $self->validate_compound_update_trailing_parts($action, @remaining);
    
    fsm_debug("[Parser.pm][parse_compound_update_shorthand()] Expanding '$compound_token' for '$signal_name' with delta '$delta_spec'", 3);
    
    # Canonical expansion:
    #   (++ x)      => (x <- x (+= 1))
    #   (+=2 x)     => (x <- x (+= 2))
    #   (-=4 x)     => (x <- x (-= 4))
    my @operation_spec = ('<-', $signal_name, [$compound_op, [$delta_spec]], @remaining);
    my $expanded_action = [$signal_name, \@operation_spec];
    
    return $self->parse_signal_action($expanded_action);
}

sub describe_compound_update_action($self, $action) {
    return $self->describe_action_for_error($action) unless ref($action) eq 'ARRAY' && @$action >= 2;

    my ($compound_token, $args) = @$action;
    my @parts = (
        defined($compound_token) ? (ref($compound_token) ? ref($compound_token) : $compound_token) : 'undef'
    );

    if (ref($args) eq 'ARRAY') {
        push @parts, map {
            !defined($_) ? 'undef'
            : ref($_) eq 'ARRAY' ? 'ARRAY'
            : ref($_) ? ref($_)
            : $_
        } @$args;
    } elsif (defined $args) {
        push @parts, ref($args) ? ref($args) : $args;
    } else {
        push @parts, 'undef';
    }

    return '(' . join(' ', @parts) . ')';
}

sub validate_compound_update_trailing_parts($self, $action, @condition_parts) {
    return 1 unless @condition_parts;

    if (@condition_parts == 1 && !ref($condition_parts[0]) && $condition_parts[0] =~ /^[<>]/) {
        return 1;
    }

    if (@condition_parts == 2 && !ref($condition_parts[0]) && ($condition_parts[0] eq '<' || $condition_parts[0] eq '<!')) {
        return 1 if defined $condition_parts[1];
    }

    my $tail_desc = join(', ', map { ref($_) ? ref($_) : $_ } @condition_parts);
    Carp::confess
        "Malformed update shorthand tail '$tail_desc' in '".$self->describe_compound_update_action($action)."'. ".
        "Update shorthand supports only an optional delta plus an optional explicit guard suffix like '<start', '<!full', or '< (& req ready)'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub build_full_condition_from_parts($self, @condition_parts) {
    return undef unless @condition_parts;
    
    # New-format encoded condition payloads:
    #   ['<',  <expr-ast>]
    #   ['<!', <expr-ast>]
    if (@condition_parts >= 2 && !ref($condition_parts[0]) && ($condition_parts[0] eq '<' || $condition_parts[0] eq '<!')) {
        my ($prefix, $payload) = @condition_parts[0, 1];
        if (ref($payload) eq 'ARRAY') {
            return ($prefix eq '<!') ? ['!', $payload] : $payload;
        } elsif (defined $payload && !ref($payload)) {
            return ($prefix eq '<!') ? "<!$payload" : "<$payload";
        }
    }
    
    # Legacy/string forms:
    #   '<signal', '<!signal', '<signal=value'
    if (@condition_parts == 1 && !ref($condition_parts[0]) && $condition_parts[0] =~ /^[<>]/) {
        return $condition_parts[0];
    }

    my $raw_suffix = join(', ', map { ref($_) ? ref($_) : $_ } @condition_parts);
    Carp::confess
        "Unsupported bare condition suffix '$raw_suffix'. ".
        "Suffix guards must use the explicit guarded forms '<sig', '<!sig', or an explicit condition expression payload. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub normalize_explicit_condition_suffix($self, $raw_suffix) {
    return $raw_suffix if ref($raw_suffix);
    return $raw_suffix if defined($raw_suffix) && !ref($raw_suffix) && $raw_suffix =~ /^[<>]/;

    my $display = defined($raw_suffix) ? (ref($raw_suffix) ? ref($raw_suffix) : $raw_suffix) : 'undef';
    Carp::confess
        "Unsupported bare condition suffix '$display'. ".
        "Suffix guards must use the explicit guarded forms '<sig', '<!sig', or an explicit condition expression payload. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}
sub reset_combinational_dependency_tracking($self) {
    $self->{combinational_dependency_graph} = {};
}

sub normalize_signal_name($self, $signal_name) {
    my $normalized = $signal_name // '';
    $normalized =~ s/\..*$//;       # Strip member suffix
    $normalized =~ s/\[.*$//;       # Strip bit/slice suffix
    $normalized =~ s/'.*$//;        # Strip width suffix
    $normalized =~ s/>$//;          # Strip output marker
    $normalized =~ s/^\s+|\s+$//g;
    return $normalized;
}

sub extract_expression_signal_names($self, $expr) {
    return [] unless $expr && ref($expr);

    my %unique_names;
    if ($expr->can('get_signals')) {
        my $signals = eval { $expr->get_signals() };
        if ($signals && ref($signals) eq 'ARRAY') {
            for my $signal (@$signals) {
                next unless $signal && ref($signal) && $signal->can('name');
                my $name = eval { $signal->name() };
                next unless defined $name;
                my $normalized = $self->normalize_signal_name($name);
                $unique_names{$normalized} = 1 if $normalized ne '';
            }
        }
    }

    return [sort keys %unique_names];
}

sub record_combinational_dependencies($self, $target_signal_name, $source_expr) {
    my $target_name = $self->normalize_signal_name($target_signal_name);
    return if $target_name eq '';

    my $sources = $self->extract_expression_signal_names($source_expr);
    $self->{combinational_dependency_graph}{$target_name} //= {};
    for my $source_name (@$sources) {
        next if !defined($source_name) || $source_name eq '';
        $self->{combinational_dependency_graph}{$target_name}{$source_name} = 1;
    }

    fsm_debug(
        "[Parser.pm][record_combinational_dependencies()] Recorded '=' dependencies for '$target_name': "
        . (@$sources ? join(', ', @$sources) : '<none>'),
        3
    );
}

sub find_cycle_path_from_target($self, $target_signal_name) {
    my $graph = $self->{combinational_dependency_graph} || {};
    return undef unless exists $graph->{$target_signal_name};

    my @queue = map { [$target_signal_name, $_] } sort keys $graph->{$target_signal_name}->%*;
    my %visited;

    while (@queue) {
        my $path = shift @queue;
        my $node = $path->[-1];
        return $path if $node eq $target_signal_name;

        next if $visited{$node}++;
        next unless exists $graph->{$node};

        for my $next_node (sort keys $graph->{$node}->%*) {
            push @queue, [@$path, $next_node];
        }
    }

    return undef;
}

sub validate_no_combinational_self_dependency($self) {
    my $graph = $self->{combinational_dependency_graph} || {};
    return unless keys %$graph;

    for my $target_signal_name (sort keys %$graph) {
        my $cycle_path = $self->find_cycle_path_from_target($target_signal_name);
        next unless $cycle_path && @$cycle_path >= 2;

        my $path_str = join(' -> ', @$cycle_path);
        fsm_debug(
            "[Parser.pm][validate_no_combinational_self_dependency()] Illegal combinational cycle detected: $path_str",
            3
        );
        Carp::confess(
            "[Parser.pm][validate_no_combinational_self_dependency()] Illegal combinational self-dependency for '$target_signal_name' using '='. "
            . "RHS depends on LHS through combinational chain ($path_str); use '<-' or rewrite expression."
        );
    }
}
sub get_target_base_signal_name($self, $raw_signal_name, $target_expr) {
    if ($target_expr) {
        if ($target_expr->isa('FSM::CoreAST::SignalRef') && $target_expr->signal && $target_expr->signal->can('name')) {
            my $name = eval { $target_expr->signal->name() };
            my $normalized = $self->normalize_signal_name($name);
            return $normalized if $normalized ne '';
        }
        if ($target_expr->isa('FSM::CoreAST::IndexedRef') && $target_expr->signal && $target_expr->signal->can('name')) {
            my $name = eval { $target_expr->signal->name() };
            my $normalized = $self->normalize_signal_name($name);
            return $normalized if $normalized ne '';
        }
    }

    return $self->normalize_signal_name($raw_signal_name);
}

sub get_target_base_signal_width($self, $target_expr, $fallback_width) {
    my $resolved_width = 0;

    if ($target_expr) {
        if ($target_expr->isa('FSM::CoreAST::SignalRef')) {
            my $signal_width = eval { $target_expr->signal && $target_expr->signal->width };
            if (defined($signal_width) && $signal_width > $resolved_width) {
                $resolved_width = $signal_width;
            }

            if ($target_expr->slice) {
                my ($high, $low) = @{$target_expr->slice};
                my $required_width = (($high > $low) ? $high : $low) + 1;
                if ($required_width > $resolved_width) {
                    $resolved_width = $required_width;
                }
            }
        } elsif ($target_expr->isa('FSM::CoreAST::IndexedRef')) {
            my $signal_width = eval { $target_expr->signal && $target_expr->signal->width };
            if (defined($signal_width) && $signal_width > $resolved_width) {
                $resolved_width = $signal_width;
            }

            my $index = $target_expr->index;
            $index = $index->value if ref($index) && $index->can('value');
            if (defined($index) && $index =~ /^\d+$/) {
                my $required_width = $index + 1;
                if ($required_width > $resolved_width) {
                    $resolved_width = $required_width;
                }
            }
        }
    }

    if (defined($fallback_width) && $fallback_width > $resolved_width) {
        $resolved_width = $fallback_width;
    }

    return $resolved_width > 0 ? $resolved_width : 1;
}

sub parse_enums_section($self, $enums_ast) {
    my (undef, $enums_list) = @$enums_ast;

    Carp::confess
        "Malformed '+enums' section. ".
        "The active contract supports '+enums' only as a non-empty list of '(enum_name (MEMBER value) ...)' definitions. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($enums_list) eq 'ARRAY' && @$enums_list;

    my @enum_entries;
    for my $enum_def (@$enums_list) {
        Carp::confess
            "Malformed '+enums' definition. ".
            "Each '+enums' definition must use the shape '(enum_name (MEMBER value) ...)'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless ref($enum_def) eq 'ARRAY' && @$enum_def == 2;

        my ($enum_name, $members_list) = @$enum_def;
        my $resolved_enum_name = $self->unwrap_scalar_token($enum_name);

        Carp::confess
            "Malformed '+enums' definition for enum '".$self->describe_contract_name($resolved_enum_name)."'. ".
            "Each '+enums' definition must use an HDL-identifier-compatible enum name and at least one '(MEMBER value)' entry. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless $self->is_contract_identifier($resolved_enum_name)
                && ref($members_list) eq 'ARRAY'
                && @$members_list;

        my @member_entries;
        for my $member_def (@$members_list) {
            Carp::confess
                "Malformed '+enums' member for enum '$resolved_enum_name'. ".
                "Each enum member must be a pair '(MEMBER value)'. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n"
                unless ref($member_def) eq 'ARRAY' && @$member_def == 2;

            my ($member_name, $member_value_array) = @$member_def;
            my $resolved_member_name = $self->unwrap_scalar_token($member_name);
            my $resolved_member_value = $self->unwrap_scalar_token($member_value_array);

            Carp::confess
                "Malformed '+enums' member '".$self->describe_contract_name($resolved_member_name)."' for enum '$resolved_enum_name'. ".
                "Each enum member must use an HDL-identifier-compatible member name and a scalar value token. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n"
                unless $self->is_contract_identifier($resolved_member_name)
                    && defined($resolved_member_value)
                    && !ref($resolved_member_value);

            push @member_entries, {
                name => $resolved_member_name,
                value_token => $resolved_member_value,
            };
        }
        push @enum_entries, {
            name => $resolved_enum_name,
            members => \@member_entries,
        };
    }

    if ($self->{fsm_module} && $self->{fsm_module}->can('direct_root_symbols')) {
        $self->{fsm_module}->direct_root_symbols->push_raw_block($enums_ast);
    }

    return \@enum_entries;
}

sub resolve_pending_direct_root_symbols($self, $module_name, $constant_entries, $enum_entries) {
    $constant_entries ||= [];
    $enum_entries ||= [];
    return 1 unless @$constant_entries || @$enum_entries;

    my $direct_root_symbols = ($self->{fsm_module} && $self->{fsm_module}->can('direct_root_symbols'))
        ? $self->{fsm_module}->direct_root_symbols
        : FSM::Package::Symbols->new();

    FSM::Package::DeclarativeSymbolResolver->resolve_symbols(
        constant_entries => $constant_entries,
        enum_entries => $enum_entries,
        value_items => sub ($value_ast) { return $self->constant_value_items($value_ast) },
        unwrap_scalar_token => sub ($value) { return $self->unwrap_scalar_token($value) },
        is_contract_identifier => sub ($value) { return $self->is_contract_identifier($value) },
        resolve_constant_payload => sub ($entry) {
            return $self->canonicalize_constant_payload(
                module_name => $module_name,
                section_header => '+constants',
                symbol_kind => 'constant',
                symbol_name => $entry->{name},
                value_ast => $entry->{value_ast},
            );
        },
        resolve_enum_member_payload => sub ($enum_entry, $member_entry) {
            return $self->canonicalize_constant_literal_payload(
                module_name => $module_name,
                section_header => '+enums',
                symbol_kind => 'enum member',
                symbol_name => $enum_entry->{name}.'.'.$member_entry->{name},
                value_token => $member_entry->{value_token},
            );
        },
        store_constant => sub ($name, $payload) {
            $direct_root_symbols->store_constant($name, $payload);
            FSM::Package::SignalManagerProjectionSupport->project_symbols_into_signal_manager(
                signal_manager => $self->{signal_manager},
                symbols => FSM::Package::Symbols->new(
                    constants => {
                        $name => $payload,
                    },
                ),
                expression_builder => $self->{expression_builder},
            );
            return $payload;
        },
        store_enum => sub ($enum_name, $members_hashref) {
            $direct_root_symbols->store_enum($enum_name, $members_hashref);
            FSM::Package::SignalManagerProjectionSupport->project_symbols_into_signal_manager(
                signal_manager => $self->{signal_manager},
                symbols => FSM::Package::Symbols->new(
                    enums => {
                        $enum_name => $members_hashref,
                    },
                ),
                expression_builder => $self->{expression_builder},
            );
            return $members_hashref;
        },
        cycle_error => sub (%cycle) {
            my @chain = map {
                my $node_type = $_->{type} eq 'enum' ? 'enum' : 'constant';
                $node_type . " '" . ($_->{name} // 'unknown') . "'";
            } @{ $cycle{chain} || [] };

            Carp::confess
                "Malformed declarative symbol scope in source '$module_name'. ".
                "The active '+constants'/'+enums' contract now resolves normal non-cyclic references without depending on declaration order, but symbol dependency cycles are blocked. ".
                "Cycle: ".join(' -> ', @chain).". ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        },
    );

    return 1;
}

sub resolve_pending_direct_root_types($self, $module_name, $type_entries) {
    $type_entries ||= [];
    return 1 unless @$type_entries;

    my $direct_root_symbols = ($self->{fsm_module} && $self->{fsm_module}->can('direct_root_symbols'))
        ? $self->{fsm_module}->direct_root_symbols
        : FSM::Package::Symbols->new();

    FSM::Package::DeclarativeTypeResolver->resolve_types(
        type_entries => $type_entries,
        unwrap_scalar_token => sub ($value) { return $self->unwrap_scalar_token($value) },
        unwrap_single_nested_list => sub ($value) { return $self->unwrap_single_nested_list($value) },
        is_contract_identifier => sub ($value) { return $self->is_contract_identifier($value) },
        resolve_type_spec => sub ($entry) {
            return $self->canonicalize_scalar_type_spec(
                module_name => $module_name,
                type_name => $entry->{name},
                spec_ast => $entry->{spec_ast},
            );
        },
        store_type => sub ($type_name, $type_spec) {
            $direct_root_symbols->store_type($type_name, $type_spec);
            FSM::Package::SignalManagerProjectionSupport->project_symbols_into_signal_manager(
                signal_manager => $self->{signal_manager},
                symbols => FSM::Package::Symbols->new(
                    types => {
                        $type_name => $type_spec,
                    },
                ),
                expression_builder => $self->{expression_builder},
            );
            return $type_spec;
        },
        cycle_error => sub (%cycle) {
            my @chain = map {
                "type '" . ($_->{name} // 'unknown') . "'";
            } @{ $cycle{chain} || [] };

            Carp::confess
                "Malformed declarative type scope in source '$module_name'. ".
                "The active '+types' contract resolves normal non-cyclic scalar type aliases without depending on declaration order, but type dependency cycles are blocked. ".
                "Cycle: ".join(' -> ', @chain).". ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        },
    );

    return 1;
}

sub parse_import_section($self, $module_name, $imports_ast) {
    my (undef, $imports_list) = @$imports_ast;

    Carp::confess
        "Malformed '+import' section in source '$module_name'. ".
        "The active contract supports '+import' only as a non-empty list of HDL-identifier-compatible package names. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($imports_list) eq 'ARRAY' && @$imports_list;

    my $module = $self->{fsm_module};
    $module->{attributes}{package_imports} //= [];
    my %seen = map { $_ => 1 } @{ $module->{attributes}{package_imports} || [] };

    for my $package_name (@$imports_list) {
        my $resolved_name = $self->unwrap_scalar_token($package_name);

        Carp::confess
            "Malformed '+import' package name '".$self->describe_contract_name($resolved_name)."' in source '$module_name'. ".
            "The active contract expects each imported package name to be an HDL-identifier-compatible bare name. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless $self->is_contract_identifier($resolved_name);

        next if $seen{$resolved_name}++;
        push @{ $module->{attributes}{package_imports} }, $resolved_name;
    }
}

sub parse_define_directive($self, $define_ast) {
    my (undef, $define_spec) = @$define_ast;

    $define_spec = $self->unwrap_single_nested_list($define_spec);

    Carp::confess
        "Malformed '+define' directive. ".
        "The active contract supports '+define' only as exactly one '(NAME scalar_value)' pair. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($define_spec) eq 'ARRAY' && @$define_spec == 2;

    my ($name, $value) = @$define_spec;
    my $resolved_name = $self->unwrap_scalar_token($name);
    my $resolved_value = $self->unwrap_scalar_token($value);

    Carp::confess
        "Malformed '+define' entry for name '".$self->describe_contract_name($resolved_name)."'. ".
        "The active contract expects an HDL-identifier-compatible name and a scalar value token. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless $self->is_contract_identifier($resolved_name)
            && defined($resolved_value)
            && !ref($resolved_value);

    my $value_expr = $self->{expression_builder}->parse_scalar_expression(
        $resolved_value
    );
    $self->{signal_manager}->store_define($resolved_name, $value_expr);
}

sub parse_params_section($self, $params_ast) {
    my (undef, $params_list) = @$params_ast;

    Carp::confess
        "Malformed '+params' section. ".
        "The active contract supports '+params' only as a non-empty list of '(NAME scalar_value)' entries. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($params_list) eq 'ARRAY' && @$params_list;

    for my $param_def (@$params_list) {
        Carp::confess
            "Malformed '+params' entry. ".
            "Each '+params' entry must be a pair '(NAME scalar_value)'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless ref($param_def) eq 'ARRAY' && @$param_def == 2;

        my ($name, $value_array) = @$param_def;
        my $resolved_name = $self->unwrap_scalar_token($name);
        my $resolved_value = $self->unwrap_scalar_token($value_array);

        Carp::confess
            "Malformed '+params' entry for parameter '".$self->describe_contract_name($resolved_name)."'. ".
            "Each '+params' entry must use an HDL-identifier-compatible name and a scalar value token. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless $self->is_contract_identifier($resolved_name)
                && defined($resolved_value)
                && !ref($resolved_value);

        $self->{signal_manager}->store_param($resolved_name, $resolved_value);
    }
}

sub parse_init_assignment_directive($self, $init_ast) {
    my (undef, $init_payload) = @$init_ast;
    my $init_spec = $self->unwrap_scalar_token($init_payload);

    Carp::confess
        "Malformed ':=' directive payload. ".
        "The active contract currently supports only compact top-level init/reset directives like '(:= signal=literal)'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless defined $init_spec && !ref($init_spec);

    my ($signal_name, $reset_value) = $init_spec =~ /^([a-zA-Z_]\w*)=(.+)$/;
    Carp::confess
        "Unsupported ':=' directive '$init_spec'. ".
        "The active contract currently supports only compact top-level init/reset directives like '(:= signal=literal)'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless defined $signal_name && defined $reset_value;

    my $reset_expr = eval { $self->{expression_builder}->parse_expression($reset_value) };
    my $reset_expr_error = $@;
    Carp::confess
        "Unsupported ':=' reset value '$reset_value' for signal '$signal_name'. ".
        "The active contract currently expects a valid scalar reset/default expression on the right-hand side. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        if $reset_expr_error || !$reset_expr;

    my %register_args = (
        attributes => {
            reset_value => $reset_value,
            is_explicit_reset => 1,
        },
    );
    if ($reset_expr->can('width') && defined($reset_expr->width) && $reset_expr->width > 1) {
        $register_args{width} = $reset_expr->width;
    }

    my $signal = $self->{signal_manager}->register_signal($signal_name, %register_args);
    $signal->{initial_value} = $reset_value;
    $signal->set_attribute('reset_value', $reset_value);
    $signal->set_attribute('is_explicit_reset', 1);
}


sub parse_state($self, $state_ast) {
    my ($state_name, $decision_trees) = @$state_ast;

    my ($state_type, $clean_name) = $self->classify_state_name($state_name);
    
    my $state = FSM::CoreAST::State->new(
        name => $clean_name,
        state_type => $state_type
    );
    $self->{current_state} = $state;
    
    my @trees;
    if (ref($decision_trees) eq 'ARRAY' && @$decision_trees > 0 && ref($decision_trees->[0]) eq 'ARRAY') {
        @trees = @$decision_trees;
    } elsif (ref($decision_trees) eq 'ARRAY') {
        @trees = ($decision_trees);
    }

    Carp::confess
        "Malformed state/DT block '$state_name'. ".
        "FSM-state DT blocks like '(aState ...)' and general/combinational DT blocks like '(-mycombDT ...)' ".
        "must contain at least one nested decision-tree body or action form. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless @trees;
    
    for my $tree (@trees) {
        if (ref($tree) eq 'ARRAY') {
            my $dt = $self->parse_decision_tree($tree);
            $state->add_decision_tree($dt) if $dt;
        }
    }

    Carp::confess
        "Malformed state/DT block '$state_name'. ".
        "FSM-state DT blocks like '(aState ...)' and general/combinational DT blocks like '(-mycombDT ...)' ".
        "must contain at least one real nested decision-tree action. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless $state->decision_trees && @{$state->decision_trees};
    
    return $state;
}

sub classify_state_name($self, $state_name) {
    Carp::confess
        "Malformed state/DT name '".$self->describe_contract_name($state_name)."'. ".
        "FSM-state DT blocks must use an HDL-identifier-compatible name like 'aState'; ".
        "general/combinational DT blocks must use a single leading '-' plus an HDL-identifier-compatible name like '-mycombDT'; ".
        "and reset-state names remain limited to '-syncrst', '-syncreset', '-asyncrst', or '-asyncreset'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless defined($state_name) && !ref($state_name);

    return ('sync_reset', 'syncreset')
        if $state_name eq '-syncrst' || $state_name eq '-syncreset';
    return ('async_reset', 'asyncreset')
        if $state_name eq '-asyncrst' || $state_name eq '-asyncreset';
    return ('standalone_dt', $state_name)
        if $state_name =~ /^-[A-Za-z_]\w*$/;
    return ('normal', $state_name)
        if $state_name =~ /^[A-Za-z_]\w*$/;

    Carp::confess
        "Malformed state/DT name '$state_name'. ".
        "FSM-state DT blocks must use an HDL-identifier-compatible name like 'aState'; ".
        "general/combinational DT blocks must use a single leading '-' plus an HDL-identifier-compatible name like '-mycombDT'; ".
        "and reset-state names remain limited to '-syncrst', '-syncreset', '-asyncrst', or '-asyncreset'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub parse_decision_tree($self, $tree_ast) {
    my $dt = FSM::CoreAST::DecisionTree->new(name => 'main_dt');
    
    my @elements_to_parse;
    if (ref($tree_ast->[0]) eq 'ARRAY') {
        @elements_to_parse = @$tree_ast;
    } else {
        @elements_to_parse = ($tree_ast);
    }
    
    for my $element (@elements_to_parse) {
        my $parsed_action = $self->parse_action($element);
        if ($parsed_action) {
            $dt->add_element($parsed_action);
        }
    }
    
    return $dt;
}

sub describe_action_for_error($self, $action) {
    return 'undef' unless defined $action;
    return ref($action) unless ref($action) eq 'ARRAY';

    my @elements = @$action;
    pop @elements while @elements > 1 && !defined($elements[-1]);

    my @parts = map {
        !defined($_) ? 'undef'
        : ref($_) eq 'ARRAY' ? 'ARRAY'
        : ref($_) ? ref($_)
        : $_
    } @elements;
    return '(' . join(' ', @parts) . ')';
}

sub parse_action($self, $action) {
    Carp::confess
        "Malformed action form '".$self->describe_action_for_error($action)."'. ".
        "Actions inside decision trees must use a supported transition, assignment, guarded block, test node, or update form. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($action) eq 'ARRAY' && @$action >= 2;
    
    my ($action_target, $action_spec) = @$action;
    fsm_debug("      Parsing action: $action_target", 3);
    
    if ($action_target eq '->') {
        return $self->parse_transition_new_format($action);
    } elsif ($action_target =~ /^\?repeat:/) {
        Carp::confess
            "Unsupported generic/template repeat action '$action_target'. ".
            "The active contract does not support legacy '?repeat:...' expansion forms. ".
            "Expand the template before parsing or keep it in legacy-only sources. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    } elsif ($action_target =~ /^\?\[[^\]]+\]$/) {
        Carp::confess
            "Unsupported generic/template test selector '$action_target'. ".
            "The active contract does not support legacy placeholder selectors like '?[NAME]'. ".
            "Expand the template before parsing or keep it in legacy-only sources. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    } elsif ($action_target =~ /^\?/) {
        return $self->parse_test_node_new_format($action);
    } elsif ($self->is_compound_update_shorthand($action_target, $action_spec)) {
        return $self->parse_compound_update_shorthand($action);
    } elsif ($action_target =~ /^[<>]/) {
        return $self->parse_nested_condition_new_format($action);
    } elsif (ref($action_spec) eq 'ARRAY' && @$action_spec >= 2) {
        return $self->parse_signal_action($action);
    } else {
        Carp::confess
            "Unsupported action form '".$self->describe_action_for_error($action)."'. ".
            "Actions inside decision trees must use a supported transition, assignment, guarded block, test node, or update form. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }
}

sub parse_transition_new_format($self, $action) {
    my (undef, $target_spec) = @$action;
    
    my $target_state;
    my $condition_suffix;
    
    if (ref($target_spec) eq 'ARRAY') {
        Carp::confess
            "Malformed transition target '".($self->describe_action_for_error($action))."'. ".
            "State transitions must use '(-> target_state)' or '(-> target_state <condition_suffix)'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless @$target_spec >= 1 && @$target_spec <= 2;

        $target_state = $target_spec->[0];
        $condition_suffix = $target_spec->[1] if @$target_spec > 1;
    } else {
        $target_state = $target_spec;
    }

    my $target_display = defined($target_state)
        ? (ref($target_state) ? ref($target_state) : $target_state)
        : 'undef';

    Carp::confess
        "Malformed transition target '$target_display'. ".
        "State transitions must target an HDL-identifier-compatible regular FSM-state DT name like 'busy'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless defined($target_state)
            && !ref($target_state)
            && $target_state =~ /\A[A-Za-z_]\w*\z/;

    $self->record_transition_target($target_state);
    
    my $transition = FSM::CoreAST::StateTransition->new(
        target_state => $target_state,
        transition_type => 'goto'
    );
    
    if (defined $condition_suffix) {
        $condition_suffix = $self->normalize_explicit_condition_suffix($condition_suffix);
        my $condition_expr = $self->{expression_builder}->parse_condition($condition_suffix);
        if ($condition_expr) {
            return FSM::CoreAST::ConditionalBranch->new(
                condition => $condition_expr,
                branches => [{
                    condition => $condition_expr,
                    actions => [$transition]
                }]
            );
        }
    }
    
    return $transition;
}

sub parse_test_node_new_format($self, $action) {
    my ($test_signal, $branches) = @$action;
    
    my $signal;
    if ($test_signal eq '?') {
        Carp::confess
            "Malformed computed test selector '?'. ".
            "Computed test nodes must use '?(expr)' with a valid selector expression followed by at least one selector branch such as '(?(| A B) (=0 ...) (=1 ...))'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless ref($branches) eq 'ARRAY' && @$branches >= 2;

        # Format: (?(| a b) (=0 x))
        # The condition expression is the first element of branches
        my $cond_ast = shift @$branches;

        if (ref($cond_ast) eq 'ARRAY' && @$cond_ast) {
            my $selector_head = $cond_ast->[0];
            if (defined($selector_head) && !ref($selector_head) && $selector_head =~ /^(?:==|!=|<=|>=|=|<|>).+/) {
                Carp::confess
                    "Malformed computed test selector '?'. ".
                    "Computed test nodes must start with a real selector expression before the branch list, for example '(?(| A B) (=0 ...) (=1 ...))'. ".
                    "See docs/USER_GUIDE.md for the current supported boundary.\n";
            }
        }

        my $condition_expr = $self->{expression_builder}->parse_condition($cond_ast);
        
        if ($condition_expr && $condition_expr->isa('FSM::CoreAST::SignalRef')) {
            $signal = $condition_expr->signal;
        } else {
            # Need to create an intermediate signal for this complex condition
            my $intermediate_name = $self->{expression_builder}->generate_intermediate_signal('cond', [$condition_expr || FSM::CoreAST::Literal->new('0')]);
            $signal = $self->{signal_manager}->register_signal($intermediate_name, 
                type => 'wire',
                is_intermediate => 1
            );
            $signal->set_driving_ast($condition_expr) if $condition_expr;
        }
    } else {
        # Format: (?is_last (=0 x))
        my ($signal_name) = $test_signal =~ /^\?(.+)/;

        Carp::confess
            "Malformed test signal '$test_signal'. ".
            "Plain test nodes must use '?signal_name' with an HDL-identifier-compatible signal name, or the computed form '?(expr)'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless defined($signal_name)
                && $signal_name =~ /\A[A-Za-z_]\w*\z/;

        $signal = $self->{signal_manager}->register_signal($signal_name);
    }
    
    my $test_node = FSM::CoreAST::TestNode->new(test_signal => $signal);
    
	    if (ref($branches) eq 'ARRAY') {
	        for my $branch (@$branches) {
            my $branch_desc = defined($branch)
                ? (ref($branch) eq 'ARRAY'
                    ? '(' . join(' ', map { defined($_) ? (ref($_) ? ref($_) : $_) : 'undef' } @$branch) . ')'
                    : (ref($branch) ? ref($branch) : $branch))
                : 'undef';

            Carp::confess
                "Malformed test branch '$branch_desc'. ".
                "Test-node branches must include a value selector like '=0' plus at least one nested action. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n"
                unless ref($branch) eq 'ARRAY' && @$branch >= 2;

	            my ($test_value, @branch_actions) = @$branch;
            $self->validate_test_branch_selector($test_value);
	            my @parsed_actions;

            for my $branch_action (@branch_actions) {
                Carp::confess
                    "Malformed test branch '$test_value'. ".
                    "Test-node branches must include at least one real nested action after the selector. ".
                    "See docs/USER_GUIDE.md for the current supported boundary.\n"
                    unless defined $branch_action;

                if (ref($branch_action) eq 'ARRAY') {
                    if (@$branch_action > 0 && ref($branch_action->[0]) eq 'ARRAY') {
                        for my $nested_assignment (@$branch_action) {
                            my $parsed_action = $self->parse_action($nested_assignment);
                            push @parsed_actions, $parsed_action if $parsed_action;
                        }
                    } else {
                        my $parsed_action = $self->parse_action($branch_action);
                        push @parsed_actions, $parsed_action if $parsed_action;
                    }
                } else {
                    my $parsed_action = $self->parse_action($branch_action);
                    push @parsed_actions, $parsed_action if $parsed_action;
                }
            }
            $test_node->add_test_branch($test_value, \@parsed_actions);
        }
    }
    
	    return $test_node;
}

sub validate_test_branch_selector($self, $test_value) {
    my $display = defined($test_value)
        ? (ref($test_value) ? ref($test_value) : $test_value)
        : 'undef';

    Carp::confess
        "Malformed test selector '$display'. ".
        "Test-node branches must use an explicit selector token like '=0', '=OTHER', '!=8\\'0', or '>8\\'3'. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless defined($test_value)
            && !ref($test_value)
            && $test_value =~ /^(?:==|!=|<=|>=|=|<|>).+/;

    return 1;
}

sub parse_nested_condition_new_format($self, $action) {
    my ($condition, $nested_actions) = @$action;
    
    my $condition_expr;
    my @actions_to_parse;
    
    # Lispish parser often encodes nested blocks as:
    #   ['<',  [ <condition_expr>, <action1>, <action2>, ... ]]
    #   ['<!', [ <condition_expr>, <action1>, <action2>, ... ]]
    if (($condition eq '<' || $condition eq '<!') && ref($nested_actions) eq 'ARRAY' && @$nested_actions >= 1) {
        my ($condition_payload, @nested_body_actions) = @$nested_actions;
        my $parsed_payload = $self->{expression_builder}->parse_condition($condition_payload);
        
        if ($condition eq '<!' && $parsed_payload) {
            $condition_expr = FSM::CoreAST::UnaryOp->new(
                operator => '!',
                operand  => $parsed_payload
            );
        } else {
            $condition_expr = $parsed_payload;
        }
        @actions_to_parse = @nested_body_actions;
    } else {
        $condition_expr = $self->{expression_builder}->parse_condition($condition);
        @actions_to_parse = @$nested_actions if ref($nested_actions) eq 'ARRAY';
    }
    
    my @parsed_actions;
    for my $nested_action (@actions_to_parse) {
        if (ref($nested_action) eq 'ARRAY' && @$nested_action > 0 && ref($nested_action->[0]) eq 'ARRAY') {
            for my $inner_action (@$nested_action) {
                my $parsed_action = $self->parse_action($inner_action);
                push @parsed_actions, $parsed_action if $parsed_action;
            }
        } else {
            my $parsed_action = $self->parse_action($nested_action);
            push @parsed_actions, $parsed_action if $parsed_action;
        }
    }
    
    if ($condition_expr && @parsed_actions) {
        return FSM::CoreAST::ConditionalBranch->new(
            condition => $condition_expr,
            branches => [{
                condition => $condition_expr,
                actions => \@parsed_actions
            }]
        );
    }

    my $condition_desc = defined($condition)
        ? (ref($condition) ? ref($condition) : $condition)
        : 'undef';
    Carp::confess
        "Malformed guarded block '$condition_desc'. ".
        "Guarded blocks must have a valid condition and at least one nested action. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n";
}

sub parse_signal_action($self, $action) {
    my ($signal_name, $operation_spec) = @$action;
    return undef unless ref($operation_spec) eq 'ARRAY' && @$operation_spec >= 2;
    
    my ($operator, $value_expr, @operation_tail) = @$operation_spec;
    
    my $compound_spec;
    my @condition_parts;
    for my $tail (@operation_tail) {
        if ($self->is_inline_compound_modifier_spec($tail)) {
            Carp::confess
                "Duplicate inline compound modifier '".$self->describe_inline_compound_modifier($tail)."' on signal '$signal_name'. ".
                "Only one inline compound modifier may follow the RHS expression. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n"
                if $compound_spec;
            $compound_spec = $tail;
            next;
        }
        push @condition_parts, $tail;
    }
    my $full_condition = $self->build_full_condition_from_parts(@condition_parts);

    my $target_expr = $self->{expression_builder}->parse_signal_reference($signal_name);
    my $source_expr = $self->{expression_builder}->parse_expression($value_expr);
    my ($compound_operator_used, $compound_delta_used);
    
    if ($compound_spec) {
        my ($compound_op, $delta_spec) = $self->normalize_inline_compound_modifier($signal_name, $compound_spec);
        
        my $delta_expr = $self->{expression_builder}->parse_expression($delta_spec);
        $delta_expr //= FSM::CoreAST::Literal->new('1');
        
        my $arith_op = ($compound_op eq '+=') ? '+' : '-';
        $source_expr = FSM::CoreAST::BinaryOp->new($arith_op, $source_expr, $delta_expr);
        $compound_operator_used = $compound_op;
        $compound_delta_used = $delta_spec;
        
        fsm_debug("[Parser.pm][parse_signal_action()] Applied compound modifier '$compound_op' with delta '$delta_spec' on '$signal_name'", 3);
    }
    
    my $target_base_signal = $self->get_target_base_signal_name($signal_name, $target_expr);
    if ($operator eq '=') {
        $self->record_combinational_dependencies($target_base_signal, $source_expr);
    }

    my ($lhs_width, $rhs_width, $final_width);
    my ($lhs_explicit, $rhs_explicit) = (0, 0);

    if ($signal_name =~ /'(\d+)$/) {
        $lhs_width = $1;
        $lhs_explicit = 1;
    } elsif (ref($target_expr) eq 'FSM::CoreAST::SignalRef' && $target_expr->slice) {
        my ($high, $low) = @{$target_expr->slice};
        $lhs_width = abs($high - $low) + 1;
        $lhs_explicit = 1;
    } elsif (ref($target_expr) eq 'FSM::CoreAST::IndexedRef') {
        $lhs_width = 1;
        $lhs_explicit = 1;
    } elsif (ref($target_expr) eq 'FSM::CoreAST::SignalRef'
        && $target_expr->signal
        && defined($target_expr->signal->width)
        && $target_expr->signal->width > 0
        && (
            $target_expr->signal->width > 1
            || ($target_expr->signal->can('get_attribute') && $target_expr->signal->get_attribute('width_declared'))
        )) {
        $lhs_width = $target_expr->signal->width;
        $lhs_explicit = 1;
    }

    if ($source_expr && $source_expr->can('width') && $source_expr->width) {
        $rhs_width = $source_expr->width;
        $rhs_explicit = 1;
    } elsif (ref($source_expr) eq 'FSM::CoreAST::SignalRef' && $source_expr->slice) {
        my ($high, $low) = @{$source_expr->slice};
        $rhs_width = abs($high - $low) + 1;
        $rhs_explicit = 1;
    } elsif (ref($source_expr) eq 'FSM::CoreAST::IndexedRef') {
        $rhs_width = 1;
        $rhs_explicit = 1;
    } elsif (ref($source_expr) eq 'FSM::CoreAST::SignalRef'
        && $source_expr->signal
        && defined($source_expr->signal->width)
        && $source_expr->signal->width > 0
        && (
            $source_expr->signal->width > 1
            || ($source_expr->signal->can('get_attribute') && $source_expr->signal->get_attribute('width_declared'))
        )) {
        $rhs_width = $source_expr->signal->width;
        $rhs_explicit = 1;
    }

    my %width_contract = (
        lhs_width => $lhs_width,
        rhs_width => $rhs_width,
        lhs_explicit => $lhs_explicit ? 1 : 0,
        rhs_explicit => $rhs_explicit ? 1 : 0,
    );

    if ($lhs_explicit && $rhs_explicit) {
        if ($lhs_width != $rhs_width) {
            $self->{expression_builder}->handle_width_mismatch($lhs_width, $rhs_width, $signal_name, $value_expr, \$source_expr);
            $width_contract{resolution} = $lhs_width > $rhs_width
                ? 'rhs_expanded_to_lhs'
                : 'rhs_truncated_to_lhs';
        } else {
            $width_contract{resolution} = 'exact_match';
        }
        $final_width = $lhs_width;
    } elsif ($lhs_explicit) {
        $final_width = $lhs_width;
        $self->{expression_builder}->propagate_width_to_expression($source_expr, $final_width);
        $width_contract{resolution} = 'rhs_width_inferred_from_lhs';
    } elsif ($rhs_explicit) {
        $final_width = $rhs_width;
        $self->{expression_builder}->propagate_width_to_expression($target_expr, $final_width);
        $width_contract{resolution} = 'lhs_width_inferred_from_rhs';
    } else {
        $final_width = 1;
        $width_contract{resolution} = 'default_1bit';
    }
    $width_contract{final_width} = $final_width if defined $final_width;

    my $target_base_width = $self->get_target_base_signal_width($target_expr, $final_width);
    if ($target_base_signal ne '' && $target_base_width > 1) {
        $self->{signal_manager}->register_signal($target_base_signal, width => $target_base_width);
    }
    
    $target_expr = $self->{expression_builder}->parse_signal_reference($signal_name); 
    
    my $output_exposure = ($signal_name =~ />$/) ? 'explicit' : 'auto';
    if ($output_exposure eq 'auto') {
        if (ref($target_expr) eq 'FSM::CoreAST::SignalRef' && $target_expr->signal && $target_expr->signal->can('get_attribute')) {
            $output_exposure = $target_expr->signal->get_attribute('is_output') ? 'explicit' : 'auto';
        } elsif (ref($target_expr) eq 'FSM::CoreAST::IndexedRef' && $target_expr->signal && $target_expr->signal->can('get_attribute')) {
            $output_exposure = $target_expr->signal->get_attribute('is_output') ? 'explicit' : 'auto';
        }
    }
    
    my %source_provenance = (
        raw_signal_name => $signal_name,
        raw_operator => $operator,
        raw_value_expr => ref($value_expr) ? ref($value_expr) : $value_expr,
        raw_condition_suffix => defined($full_condition) ? (ref($full_condition) ? ref($full_condition) : $full_condition) : undef,
        had_compound_modifier => $compound_spec ? 1 : 0,
    );
    if (defined $compound_operator_used) {
        $source_provenance{compound_operator} = $compound_operator_used;
        $source_provenance{compound_delta} = $compound_delta_used;
    }
    $source_provenance{width_contract} = \%width_contract;

    my $assignment;
    if ($operator eq '<-') {
        $assignment = FSM::CoreAST::RegisterAssignment->new(
            target => $target_expr,
            source => $source_expr,
            register_style => 'output_named',
            output_exposure => $output_exposure,
            source_provenance => \%source_provenance,
            assignment_intent => {
                operator_symbol => '<-',
                sequencing => 'clocked',
                register_style => 'output_named',
                assignment_family => 'register',
                lhs_binding => 'flop_q_output',
                hold_policy => 'q_feedback_when_no_enable',
            },
        );
    } elsif ($operator eq '<-=') {
        my $next_output_name = "next_$target_base_signal";
        $self->{signal_manager}->register_signal(
            $next_output_name,
            width => $target_base_width,
            is_output => 1,
            is_aux_output => 1,
        );
        $assignment = FSM::CoreAST::RegisterAssignment->new(
            target => $target_expr,
            source => $source_expr,
            register_style => 'output_named',
            output_exposure => $output_exposure,
            source_provenance => \%source_provenance,
            assignment_intent => {
                operator_symbol => '<-=',
                sequencing => 'clocked',
                register_style => 'output_named',
                assignment_family => 'register_dual_output',
                lhs_binding => 'flop_q_output',
                hold_policy => 'q_feedback_when_no_enable',
                expose_next_output => 1,
                auxiliary_output_name => $next_output_name,
            },
        );
    } elsif ($operator eq '<=') {
        $assignment = FSM::CoreAST::RegisterAssignment->new(
            target => $target_expr,
            source => $source_expr,
            register_style => 'input_named',
            output_exposure => $output_exposure,
            source_provenance => \%source_provenance,
            assignment_intent => {
                operator_symbol => '<=',
                sequencing => 'clocked',
                register_style => 'input_named',
                assignment_family => 'register',
                lhs_binding => 'flop_d_input',
                immediate_visibility => 'same_cycle_on_d_input',
                hold_policy => 'q_feedback_when_no_enable',
            },
        );
    } elsif ($operator eq '<=+') {
        my $q_output_name = $target_base_signal . '_r';
        $self->{signal_manager}->register_signal(
            $q_output_name,
            width => $target_base_width,
            is_output => 1,
            is_aux_output => 1,
        );
        $assignment = FSM::CoreAST::RegisterAssignment->new(
            target => $target_expr,
            source => $source_expr,
            register_style => 'input_named',
            output_exposure => $output_exposure,
            source_provenance => \%source_provenance,
            assignment_intent => {
                operator_symbol => '<=+',
                sequencing => 'clocked',
                register_style => 'input_named',
                assignment_family => 'mux_dual_output',
                lhs_binding => 'flop_d_input',
                immediate_visibility => 'same_cycle_on_d_input',
                hold_policy => 'q_feedback_when_no_enable',
                expose_q_output => 1,
                auxiliary_output_name => $q_output_name,
            },
        );
    } elsif ($operator =~ /^<(\d+)$/) {
        my $delay_cycles = $1;
        my $active_level = $self->resolve_single_bit_logic_level($source_expr, $value_expr);
        my $rest_level = $active_level ? 0 : 1;
        $source_provenance{pulse_delay_cycles} = $delay_cycles;
        $source_provenance{pulse_active_level} = $active_level;
        $source_provenance{pulse_rest_level} = $rest_level;
        $assignment = FSM::CoreAST::PulseAssignment->new(
            target => $target_expr,
            source => $source_expr,
            pulse_cycles => $delay_cycles,
            output_exposure => $output_exposure,
            source_provenance => \%source_provenance,
            assignment_intent => {
                operator_symbol => $operator,
                sequencing => 'clocked',
                register_style => 'pulse_delayed',
                assignment_family => 'pulse_delay',
                pulse_delay_cycles => $delay_cycles,
                pulse_width_cycles => 1,
                pulse_active_level => $active_level,
                pulse_rest_level => $rest_level,
                pulse_timing_reference => 'decision_cycle_q_plus_n',
            },
        );
    } elsif ($operator eq '=') {
        $assignment = FSM::CoreAST::Assignment->new(
            target => $target_expr,
            source => $source_expr,
            assignment_type => 'combinatorial',
            output_exposure => $output_exposure,
            source_provenance => \%source_provenance,
            assignment_intent => {
                operator_symbol => '=',
                sequencing => 'combinational',
                register_style => 'none',
                assignment_family => 'combinatorial',
            },
        );
    } else {
        Carp::confess
            "Unsupported assignment operator '$operator' for signal '$signal_name'. ".
            "Decision-tree assignments must use one of '=', '<-', '<-=', '<=', '<=+', or a delayed-pulse form like '<1'. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }
    
    if (defined $full_condition) {
        my $condition_expr = $self->{expression_builder}->parse_condition($full_condition);
        if ($condition_expr) {
            return FSM::CoreAST::ConditionalBranch->new(
                condition => $condition_expr,
                branches => [{
                    condition => $condition_expr,
                    actions => [$assignment]
                }]
            );
        }
    }
    
    return $assignment;
}

sub resolve_single_bit_logic_level($self, $source_expr, $raw_value_expr) {
    my $rhs_desc = defined($raw_value_expr)
        ? (ref($raw_value_expr) ? ref($raw_value_expr) : $raw_value_expr)
        : 'undef';
    my $logic_level;
    if ($source_expr && $source_expr->isa('FSM::CoreAST::Literal')) {
        my $value = $source_expr->value;
        my $width = $source_expr->width;
        my $radix = $source_expr->radix // 'decimal';
        if (defined($width) && $width != 1) {
            Carp::confess
                "Malformed delayed pulse RHS '$rhs_desc'. ".
                "Delayed pulse assignments must use '(P <N 0)' or '(P <N 1)' with a 1-bit literal RHS. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        }
        if (defined($value) && $value =~ /^[01]$/) {
            $logic_level = int($value);
        } elsif ($radix eq 'binary' && defined($value) && $value =~ /^[01]$/) {
            $logic_level = int($value);
        } elsif ($radix eq 'decimal' && defined($value) && $value =~ /^[01]$/) {
            $logic_level = int($value);
        } elsif ($radix eq 'hex' && defined($value) && ($value eq '0' || $value eq '1')) {
            $logic_level = int($value);
        }
    }
    if (!defined($logic_level) && defined($raw_value_expr) && !ref($raw_value_expr) && $raw_value_expr =~ /^[01]$/) {
        $logic_level = int($raw_value_expr);
    }
    if (!defined($logic_level)) {
        Carp::confess
            "Malformed delayed pulse RHS '$rhs_desc'. ".
            "Delayed pulse assignments must use '(P <N 0)' or '(P <N 1)' with a 1-bit literal RHS. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }
    return $logic_level;
}

1;
