package FSM::Adapter::FSMGenFull::Parser;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Data::Dumper;
use Scalar::Util qw(blessed);
use FSM::CoreAST;
use FSM::Debug;
use FSM::Package::AggregateExpressionTypeSupport;
use FSM::Package::AggregatePathSupport;
use FSM::Package::DeclarativeSymbolResolver;
use FSM::Package::DeclarativeTypeSupport;
use FSM::Package::DeclarativeTypeResolver;
use FSM::Package::IntegerLiteralSupport;
use FSM::Package::PayloadTypeSupport;
use FSM::Package::SignalManagerProjectionSupport;
use FSM::Package::Symbols;
use FSM::ParameterValueSupport;
use FSM::SourceClassifier;
use FSM::Support::DocumentationHints qw(supported_boundary_hint supported_boundary_sentence);

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
        fsm_error("Detected unsupported tagged top-level source '$header'");
        Carp::confess
            "Unsupported top-level source '$header'. ".
            "The active toolchain supports '?fsm:name', '?dt:name', '?mod:name', '?module:name', and '+fsm' as single-module sources, and '?top:name' through the composition pipeline. ".
            "Other tagged source kinds such as '?define:' are out of active support. ".
            supported_boundary_hint();
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
        supported_boundary_hint();
}

sub parse_fsm_module($self, $fsm_ast, $is_flat_ast = 0, $root_kind = 'fsm') {
    fsm_trace_enter('Parser parse_fsm_module() entry', 2);
    $self->reset_combinational_dependency_tracking();
    $self->reset_transition_target_tracking();
    $self->{expression_builder}->clear_state_active_references;
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
    my @pending_interface_sections;
    my @pending_assert_sections;

    for my $element (@$fsm_contents) {
        Carp::confess
            "Malformed top-level " . ($root_kind eq 'dt' ? 'DT' : 'FSM') . " body item '".$self->describe_top_level_source_root([$element])."' in source '$module_name'. ".
            $top_level_forms_desc . " ".
            supported_boundary_hint()
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
        } elsif ($element_name eq '+interface') {
            fsm_debug("Collecting +interface block", 3);
            push @pending_interface_sections, $element;
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
        } elsif ($element_name eq '+assert') {
            fsm_debug("Collecting +assert block", 3);
            push @pending_assert_sections, $element;
        }
    }

    $self->resolve_pending_direct_root_symbols(
        $module_name,
        \@pending_constant_entries,
        \@pending_enum_entries,
    );

    $self->resolve_pending_direct_root_types(
        $module_name,
        \@pending_type_entries,
    );

    my @pending_param_entries;
    for my $element (@$fsm_contents) {
        next unless ref($element) eq 'ARRAY';
        my $element_name = $element->[0];

        if ($element_name eq '+define') {
            fsm_debug("Parsing define directive", 3);
            $self->parse_define_directive($element);
        } elsif ($element_name eq '+params') {
            fsm_debug("Collecting params section", 3);
            push @pending_param_entries, @{ $self->parse_params_section($element) };
        }
    }

    $self->resolve_pending_direct_root_params(
        $module_name,
        \@pending_param_entries,
    );

    for my $size_ast (@pending_size_sections) {
        $self->parse_size_section($size_ast);
    }

    for my $interface_ast (@pending_interface_sections) {
        $self->parse_interface_section($interface_ast);
    }

    for my $assert_ast (@pending_assert_sections) {
        $self->parse_asserts_section($assert_ast);
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
                || $element_name eq '+interface'
                || $element_name eq '+constants'
                || $element_name eq '+enums'
                || $element_name eq '+types'
                || $element_name eq '+import'
                || $element_name eq '+define'
                || $element_name eq '+params'
                || $element_name eq '+assert'
            )
        ) {
            next;
        }

        if ($element_name eq ':=') {
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
                supported_boundary_hint();
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
                supported_boundary_hint();
        } elsif ($element_name =~ /^\+/) {
            Carp::confess
                "Unsupported top-level directive '$element_name'. ".
                $supported_directives_desc . " ".
                supported_boundary_hint();
        } elsif ($element_name =~ /^[a-zA-Z_]/ && $element_name !~ /^(idle|-syncrst|-syncreset|-asyncrst|-asyncreset)$/ && !ref($element->[1])) {
            my $detail = join(' ', map {
                defined($_) ? (ref($_) ? ref($_) : $_) : 'undef'
            } @$element);
            Carp::confess
                "Unsupported top-level form '($detail)'. ".
                $top_level_forms_desc . " ".
                "Future-looking bare forms such as '(lhs := value)' are not part of the active contract yet. ".
                supported_boundary_hint();
        } else {
            fsm_debug("Parsing state block: $element_name", 3);
            my $state = $self->parse_state($element);
            if ($root_kind eq 'dt' && $state) {
                Carp::confess
                    "Unsupported top-level block '$element_name' inside '$root_contract_label'. ".
                    "The active '?dt:name' contract currently supports only non-state DT blocks named like '(-foo ...)' at top level. ".
                    "FSM-state blocks remain part of '?fsm:name'. ".
                    supported_boundary_hint()
                    unless $state->can('is_standalone_dt') && $state->is_standalone_dt;
            }
            $module->add_state($state) if $state;
        }
    }

    $self->reconcile_simple_assignment_signal_widths($module);
    $self->validate_transition_targets($module);
    $self->validate_state_active_references($module);
    $self->validate_no_combinational_self_dependency();
    fsm_trace_exit("Parser parse_fsm_module() completed for '$module_name'", 2);
    return $module;
}

sub validate_state_active_references($self, $module) {
    my $refs = $self->{expression_builder}->state_active_references;
    return unless @$refs;

    my %regular_state = map { $_->name => 1 }
        grep { $_ && $_->can('is_regular_state') && $_->is_regular_state }
        @{$module->states || []};

    for my $state_name (@$refs) {
        next if $regular_state{$state_name};
        $self->{expression_builder}->clear_state_active_references;
        Carp::confess
            "State-active guard references unknown regular FSM state '$state_name'. ".
            "State-active guards must reference a declared regular FSM-state DT block in the same source. ".
            supported_boundary_hint();
    }

    $self->{expression_builder}->clear_state_active_references;
}

sub reconcile_simple_assignment_signal_widths($self, $fsm_module) {
    return unless $fsm_module && $fsm_module->can('states');

    my $registry = $self->{signal_manager}{signal_registry} || {};
    my $iteration_limit = scalar(keys %$registry) + 1;
    $iteration_limit = 2 if $iteration_limit < 2;

    my $changed = 1;
    my $iteration = 0;
    while ($changed && $iteration < $iteration_limit) {
        $changed = 0;
        $iteration++;

        for my $state (@{$fsm_module->states || []}) {
            next unless blessed($state) && $state->can('decision_trees');
            for my $dt (@{$state->decision_trees || []}) {
                next unless blessed($dt) && $dt->can('elements');
                for my $element (@{$dt->elements || []}) {
                    $self->_reconcile_simple_assignment_signal_widths_in_element($element, \$changed);
                }
            }
        }
    }
}

sub _reconcile_simple_assignment_signal_widths_in_element($self, $element, $changed_ref) {
    return unless $element && blessed($element);

    if ($element->isa('FSM::CoreAST::Assignment') || $element->isa('FSM::CoreAST::RegisterAssignment')) {
        $self->_reconcile_simple_assignment_signal_widths_for_assignment($element, $changed_ref);
        return;
    }

    if ($element->isa('FSM::CoreAST::ConditionalBranch')) {
        for my $branch ($element->branches->@*) {
            for my $action ($branch->{actions}->@*) {
                $self->_reconcile_simple_assignment_signal_widths_in_element($action, $changed_ref);
            }
        }
        return;
    }

    if ($element->isa('FSM::CoreAST::TestNode')) {
        for my $branch ($element->test_branches->@*) {
            for my $action ($branch->{actions}->@*) {
                $self->_reconcile_simple_assignment_signal_widths_in_element($action, $changed_ref);
            }
        }
        return;
    }
}

sub _reconcile_simple_assignment_signal_widths_for_assignment($self, $assignment, $changed_ref) {
    my ($target_signal, $source_signal) = $self->_simple_assignment_signal_pair($assignment);
    return unless $target_signal && $source_signal;
    return if $target_signal->name eq $source_signal->name;

    my $target_width = $target_signal->width;
    my $source_width = $source_signal->width;

    if (defined($target_width) && $target_width > 1 && $self->_signal_width_accepts_inference($source_signal)) {
        $$changed_ref = 1 if $self->_update_signal_width_from_inference($source_signal, $target_width);
    }

    if (defined($source_width) && $source_width > 1 && $self->_signal_width_accepts_inference($target_signal)) {
        $$changed_ref = 1 if $self->_update_signal_width_from_inference($target_signal, $source_width);
    }
}

sub _simple_assignment_signal_pair($self, $assignment) {
    return unless $assignment && blessed($assignment);
    return unless $assignment->can('target') && $assignment->can('source');

    my $target = $assignment->target;
    my $source = $assignment->source;
    return unless $target && $source;
    return unless $target->isa('FSM::CoreAST::SignalRef');
    return unless $source->isa('FSM::CoreAST::SignalRef');
    return if $target->slice;
    return if $source->slice;

    my $target_signal = $target->signal;
    my $source_signal = $source->signal;
    return unless $target_signal && $source_signal;

    return ($target_signal, $source_signal);
}

sub _signal_width_accepts_inference($self, $signal) {
    return 0 unless $signal && $signal->can('width');
    return 0 if $signal->can('get_attribute') && $signal->get_attribute('width_declared');

    my $width = $signal->width;
    return 1 unless defined $width;
    return $width <= 1 ? 1 : 0;
}

sub _update_signal_width_from_inference($self, $signal, $required_width) {
    return 0 unless $signal && $signal->can('name');
    return 0 unless defined($required_width) && $required_width > 1;

    my $before_width = $signal->width;
    my $updated_signal = $self->{signal_manager}->register_signal(
        $signal->name,
        width => $required_width,
        type => $signal->type,
        is_output => ($signal->can('get_attribute') && $signal->get_attribute('is_output')) ? 1 : 0,
    );

    my $after_width = $updated_signal && $updated_signal->can('width')
        ? $updated_signal->width
        : undef;

    return (defined($after_width) && (!defined($before_width) || $after_width != $before_width)) ? 1 : 0;
}

sub validate_module_root_body($self, $module_name, $fsm_contents, $is_flat_ast = 0, $root_kind = 'fsm') {
    my $root_family = $is_flat_ast ? '+fsm' : '?' . $root_kind . ':' . $module_name;
    my $body_desc = $root_kind eq 'dt'
        ? "The active contract expects a non-empty list of directive sections, ':=' directives, and general DT blocks inside the DT source root. "
        : "The active contract expects a non-empty list of directive sections, ':=' directives, and state/DT blocks inside the FSM source root. ";

    Carp::confess
        "Malformed top-level " . ($root_kind eq 'dt' ? 'DT' : 'FSM') . " body for source '$root_family'. ".
        $body_desc .
        supported_boundary_hint()
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
        supported_boundary_hint();
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
        supported_boundary_hint();
}

sub root_contract_label($self, $root_kind = 'fsm') {
    return "one of '?dt:name', '?mod:name', or '?module:name'" if $root_kind eq 'dt';
    return '?fsm:name';
}

sub supported_directives_description($self, $root_kind = 'fsm') {
    return "The active contract currently supports only the conventional '+system' form, '+size', '+interface', '+constants', '+enums', '+types', '+import', '+define', '+params', and '+assert' inside '?dt:name'"
        if $root_kind eq 'dt';
    return "The active contract currently supports only '+system', '+size', '+interface', '+constants', '+enums', '+types', '+import', '+define', '+params', and '+assert' inside '?fsm:name'";
}

sub supported_top_level_forms_description($self, $root_kind = 'fsm', $is_flat_ast = 0) {
    return "Inside '?dt:name', the active contract supports the conventional '+system' section, other directive sections, ':=' init/reset directives, and general DT blocks like '(-foo ...)' or guarded non-state DT blocks like '(-foo <cond ...)' only"
        if $root_kind eq 'dt';
    return "Inside '?fsm:module_name' and the legacy '+fsm' root family, top-level content must be a list of directive sections, ':=' directives, and state/DT blocks"
        if $is_flat_ast;
    return "Inside '?fsm:name', the active contract supports directive sections, ':=' init/reset directives, state DT blocks like '(state ...)' or '(state <cond ...)', and non-state DT blocks like '(-foo ...)' or '(-foo <cond ...)' only";
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
        supported_boundary_hint()
        unless ref($constants_list) eq 'ARRAY' && @$constants_list;

    my @constant_entries;
    for my $constant_def (@$constants_list) {
        Carp::confess
            "Malformed '+constants' entry. ".
            "Each '+constants' entry must be a pair '(NAME value)'. ".
            supported_boundary_hint()
            unless ref($constant_def) eq 'ARRAY' && @$constant_def == 2;

        my ($name, $value) = @$constant_def;
        my $resolved_name = $self->unwrap_scalar_token($name);

        Carp::confess
            "Malformed '+constants' entry for constant '".$self->describe_contract_name($resolved_name)."'. ".
            "Each '+constants' entry must use an HDL-identifier-compatible name. ".
            supported_boundary_hint()
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
        "The active contract supports '+types' only as a non-empty list of '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', '(type NAME (list ...))', '(type NAME (record (field TYPE) ...))', or '(type NAME other_type)' entries. ".
        supported_boundary_hint()
        unless ref($types_list) eq 'ARRAY' && @$types_list;

    my @type_entries;
    for my $type_def (@$types_list) {
        Carp::confess
            "Malformed '+types' entry. ".
            "Each '+types' entry must use the shape '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', '(type NAME (list ...))', '(type NAME (record (field TYPE) ...))', or '(type NAME other_type)'. ".
            supported_boundary_hint()
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
                "Each '+types' entry must use the shape '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', '(type NAME (list ...))', '(type NAME (record (field TYPE) ...))', or '(type NAME other_type)'. ".
                supported_boundary_hint();
        }

        my $resolved_keyword = $self->unwrap_scalar_token($keyword);
        my $resolved_name = $self->unwrap_scalar_token($name);

        Carp::confess
            "Malformed '+types' entry for type '".$self->describe_contract_name($resolved_name)."'. ".
            "Each '+types' entry must begin with the literal keyword 'type' and use an HDL-identifier-compatible type name. ".
            supported_boundary_hint()
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

# ISF-ASSERT: parse a `(+assert (NAME COND ["message"]) ...)` directive, storing the parsed
# immediate (combinational) assertions on the module so the backend can project them to
# verification-only SV assertions. COND is parsed by the shared expression builder.
sub parse_asserts_section($self, $assert_ast) {
    # Lispish head+grouped-rest: (+assert ENTRY...) -> ['+assert', [ENTRY...]] and each entry
    # (NAME KIND COND ["msg"]) -> ['NAME', [KIND, COND, "msg"?]]. KIND in {assert,cover,assume}.
    my (undef, $entries) = @$assert_ast;
    my $module = $self->{fsm_module};
    $module->{attributes}{immediate_assertions} //= [];
    for my $entry (@{ $entries || [] }) {
        Carp::confess "Unsupported '+assert' entry: each must be '(NAME KIND COND [\"message\"])'"
            unless ref($entry) eq 'ARRAY' && @$entry == 2 && ref($entry->[1]) eq 'ARRAY';
        my $name = $self->unwrap_scalar_token($entry->[0]);
        Carp::confess "'+assert' entry requires a scalar name"
            unless defined($name) && length($name);
        my ($kind_tok, $cond_tok, $msg_tok) = @{ $entry->[1] };
        my $kind = $self->unwrap_scalar_token($kind_tok);
        Carp::confess "'+assert' entry '$name' requires a kind in {assert,cover,assume}"
            unless defined($kind) && $kind =~ /^(?:assert|cover|assume)$/;
        Carp::confess "'+assert' entry '$name' requires a condition expression"
            unless defined $cond_tok;
        my $condition = $self->parse_check_property($cond_tok);
        my $message = defined($msg_tok) ? $self->unwrap_scalar_token($msg_tok) : undef;
        push @{ $module->{attributes}{immediate_assertions} }, {
            name      => $name,
            kind      => $kind,
            condition => $condition,
            (defined $message ? (message => $message) : ()),
        };
    }
    return $module->{attributes}{immediate_assertions};
}

# ISF-PROPERTY-IMPLICATION: a check condition is either a boolean expression (parsed by the
# expression builder) or a temporal PROPERTY combinator that does not fit the boolean grammar.
# Lispish head+grouped-rest: (=> ANT CONS) -> ['=>', [ANT, CONS]]. The boolean leaves are parsed
# by the expression builder; the combinator is kept as a tagged struct the backend renders to SVA.
sub parse_check_property($self, $cond_tok) {
    if (ref($cond_tok) eq 'ARRAY' && @$cond_tok == 2
        && defined($cond_tok->[0]) && !ref($cond_tok->[0])) {
        my $head = $cond_tok->[0];
        my $args = $cond_tok->[1];

        if ($head eq '=>') {
            # (=> ANT CONS) overlapping implication -> (ANT) |-> (CONS)
            Carp::confess "'(=> ANT CONS)' implication requires exactly an antecedent and a consequent"
                unless ref($args) eq 'ARRAY' && @$args == 2 && defined($args->[0]) && defined($args->[1]);
            return {
                __property__ => 1,
                op          => 'implies_overlap',
                antecedent  => $self->parse_check_property($args->[0]),
                consequent  => $self->parse_check_property($args->[1]),
            };
        }
        if ($head eq 'after') {
            # (after SIG CONS) event trigger -> $rose(SIG) |-> (CONS); anchors a bounded-eventually
            # consequent to a signal's rising edge (ISF-TRIGGER-ANCHOR, decision 0009 — "event" form).
            Carp::confess "'(after SIG CONS)' requires a trigger signal and a consequent"
                unless ref($args) eq 'ARRAY' && @$args == 2 && defined($args->[0]) && defined($args->[1]);
            return {
                __property__ => 1,
                op          => 'after_event',
                trigger     => $self->parse_check_property($args->[0]),
                consequent  => $self->parse_check_property($args->[1]),
            };
        }
        if ($head eq 'next') {
            # (next X) -> ##1 (X)  (one-cycle delay; an `(=> A (next B))` is the SVA |=> idiom)
            Carp::confess "'(next X)' requires exactly one operand"
                unless ref($args) eq 'ARRAY' && @$args == 1 && defined($args->[0]);
            return { __property__ => 1, op => 'next', operand => $self->parse_check_property($args->[0]) };
        }
        if ($head eq 'within') {
            # (within X N)       -> ##[1:N] (X)      (X holds at some cycle 1..N)
            # (within X MIN MAX) -> ##[MIN:MAX] (X)  (ISF-PROPERTY-WINDOW-RANGE: explicit lower
            #   bound — the min>1 MTL window; literal 1 <= MIN <= MAX, SPECFORGE-confirmed range)
            Carp::confess "'(within X N)' / '(within X MIN MAX)' requires an operand and one or two literal bounds"
                unless ref($args) eq 'ARRAY' && (@$args == 2 || @$args == 3) && !(grep { !defined } @$args);
            my ($lower, $upper);
            if (@$args == 2) {
                $upper = $self->unwrap_scalar_token($args->[1]);
                Carp::confess "'(within X N)' bound must be a literal integer >= 1"
                    unless defined($upper) && !ref($upper) && $upper =~ /^\d+$/ && $upper + 0 >= 1;
                ($lower, $upper) = (1, $upper + 0);
            }
            else {
                ($lower, $upper) = map { $self->unwrap_scalar_token($_) } @{$args}[1, 2];
                Carp::confess "'(within X MIN MAX)' bounds must be literal integers"
                    unless defined($lower) && !ref($lower) && $lower =~ /^\d+$/
                        && defined($upper) && !ref($upper) && $upper =~ /^\d+$/;
                ($lower, $upper) = ($lower + 0, $upper + 0);
                Carp::confess "'(within X MIN MAX)' bounds must satisfy 1 <= MIN <= MAX"
                    unless $lower >= 1 && $lower <= $upper;
            }
            return {
                __property__ => 1,
                op      => 'within',
                operand => $self->parse_check_property($args->[0]),
                lower   => $lower,
                bound   => $upper,
            };
        }
        # ISF-PROPERTY-SAMPLED-VALUE: SystemVerilog sampled-value functions as property leaves.
        # (stable SIG)/(changed SIG)/(rose SIG)/(fell SIG) -> $stable/$changed/$rose/$fell(SIG):
        # boolean edge/stability predicates over a signal, well-defined only in the clocked
        # assertion context. Usable standalone or as an =>/after antecedent/consequent.
        my %sampled_value_fn = (stable => '$stable', changed => '$changed', rose => '$rose', fell => '$fell');
        if (my $fn = $sampled_value_fn{$head}) {
            Carp::confess "'($head SIG)' sampled-value predicate requires exactly one signal operand"
                unless ref($args) eq 'ARRAY' && @$args == 1 && defined($args->[0]);
            return {
                __property__ => 1,
                op           => 'sampled_value',
                fn           => $fn,
                operand      => $self->parse_check_property($args->[0]),
            };
        }
    }
    return $self->{expression_builder}->parse_expression($cond_tok, property_value_context => 1);
}

sub parse_size_section($self, $size_ast) {
    my (undef, $size_entries) = @$size_ast;

    # Legacy no-op form still exists in the shipped corpus.
    return unless defined $size_entries;

    Carp::confess
        "Malformed '+size' section. ".
        "The active contract supports '+size' only as a list of '(signal width)' entries, ".
        "or the legacy empty no-op form '(+size)'. ".
        supported_boundary_hint()
        unless ref($size_entries) eq 'ARRAY';

    for my $size_def (@$size_entries) {
        Carp::confess
            "Malformed '+size' entry. ".
            "Each '+size' entry must be a pair '(signal width_or_type)'. ".
            supported_boundary_hint()
            unless ref($size_def) eq 'ARRAY' && @$size_def == 2;

        my ($sig, $width) = @$size_def;

        # ISF-REGISTER-RESET-VALUES: an optional `(reset V)` marker inside the width
        # field pins the register's hardware reset value — `(signal width (reset V))`.
        # It is carried as a signal attribute the HDL backend already consumes; absent
        # it, the register resets to all-0s as before (fully backward-compatible). The
        # marker is split out here so the remaining tokens form the plain width
        # expression; `(reset V)` is unambiguous against width expressions (whose head
        # is an arithmetic/bitwise operator, never `reset`).
        my $reset_value;
        if (ref($width) eq 'ARRAY') {
            my @rest;
            for my $tok (@$width) {
                my $head = (ref($tok) eq 'ARRAY' && @$tok >= 2)
                    ? ($self->unwrap_scalar_token($tok->[0]) // '') : '';
                if ($head eq 'reset') {
                    $reset_value = $self->unwrap_scalar_token($tok->[1]);
                } else {
                    push @rest, $tok;
                }
            }
            $width = \@rest;
        }

        my $resolved_sig = $self->unwrap_scalar_token($sig);
        my $resolved_width = $self->unwrap_scalar_token($width);
        if (defined $reset_value) {
            Carp::confess
                "Malformed '+size' reset value for signal '". ($resolved_sig // '?') ."'. ".
                "A '(reset V)' reset value must be a non-negative integer literal. ".
                supported_boundary_hint()
                unless !ref($reset_value) && $reset_value =~ /\A[0-9]+\z/;
        }

        Carp::confess
            "Malformed '+size' entry for signal '$resolved_sig'. ".
            "Each '+size' entry must use an HDL-identifier-compatible signal name and either a positive integer width or a named scalar type. ".
            supported_boundary_hint()
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
            declared_type_name => $width_contract->{declared_type_name},
            declared_type_spec => $width_contract->{declared_type_spec},
            width_declared => 1,
            (defined $reset_value ? (attributes => { reset_value => $reset_value }) : ()),
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
                declared_type_name => $width_contract->{declared_type_name},
                declared_type_spec => $width_contract->{declared_type_spec},
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
                declared_type_name => $width_contract->{declared_type_name},
                declared_type_spec => $width_contract->{declared_type_spec},
                is_output => 1,
                is_aux_output => 1,
                width_declared => 1,
            );
        }
    }
}

sub parse_interface_section($self, $interface_ast) {
    my (undef, $interface_entries) = @$interface_ast;

    return unless defined $interface_entries;

    Carp::confess
        "Malformed '+interface' section. ".
        "The active contract supports '+interface' only as a list of '(input signal)' or '(output signal)' role entries. ".
        supported_boundary_hint()
        unless ref($interface_entries) eq 'ARRAY';

    for my $entry (@$interface_entries) {
        Carp::confess
            "Malformed '+interface' entry. ".
            "Each '+interface' entry must be '(input signal)' or '(output signal)'. ".
            supported_boundary_hint()
            unless ref($entry) eq 'ARRAY' && @$entry == 2;

        my ($direction, $signal_name) = map { $self->unwrap_scalar_token($_) } @$entry;
        Carp::confess
            "Malformed '+interface' entry. ".
            "The interface role must be 'input' or 'output'. ".
            supported_boundary_hint()
            unless defined($direction)
                && !ref($direction)
                && ($direction eq 'input' || $direction eq 'output');
        my $display_signal = defined($signal_name)
            ? (ref($signal_name) ? ref($signal_name) : $signal_name)
            : 'undef';
        Carp::confess
            "Malformed '+interface' entry for signal '$display_signal'. ".
            "Interface role entries require an HDL-identifier-compatible signal name. ".
            supported_boundary_hint()
            unless defined($signal_name)
                && !ref($signal_name)
                && $signal_name =~ /\A[A-Za-z_]\w*\z/;

        $self->{signal_manager}->register_signal(
            $signal_name,
            attributes => {
                explicit_port_role => uc($direction),
            },
        );
    }
}

sub parse_system_section($self, $system_ast) {
    my (undef, $system_entries) = @$system_ast;

    Carp::confess
        "The active '+system' contract currently supports a shared system declaration ".
        "with '(clock name)' and an optional reset declaration via '(sreset reset)' or '(areset rst_n)'. ".
        supported_boundary_hint()
        unless ref($system_entries) eq 'ARRAY' && @$system_entries;

    my %seen;
    my %parsed;

    for my $entry (@$system_entries) {
        Carp::confess
            "Unsupported '+system' entry structure. ".
            "The active contract currently supports only '(clock name)' plus at most one reset declaration via '(sreset reset)' or '(areset rst_n)' inside '+system'. ".
            supported_boundary_hint()
            unless ref($entry) eq 'ARRAY' && @$entry == 2;

        my ($directive, $name) = @$entry;
        my $resolved_name = $self->unwrap_scalar_token($name);

        Carp::confess
            "Unsupported '+system' entry '$directive'. ".
            "The active contract currently supports only '(clock name)' plus optional '(sreset reset)' or '(areset rst_n)'. ".
            supported_boundary_hint()
            unless defined $directive && !ref($directive);

        Carp::confess
            "Unsupported '+system' entry structure. ".
            "The active contract currently supports only '(clock name)' plus at most one reset declaration via '(sreset reset)' or '(areset rst_n)' inside '+system'. ".
            supported_boundary_hint()
            unless defined $resolved_name && !ref($resolved_name);

        Carp::confess
            "Duplicate '+system' entry '$directive'. ".
            "The active contract currently expects exactly one '(clock clk)' and at most one reset declaration. ".
            supported_boundary_hint()
            if $seen{$directive}++;

        if ($directive eq 'clock') {
            Carp::confess
                "Unsupported '+system' clock name '$resolved_name'. ".
                "Clock declarations must use an HDL-identifier-compatible clock signal name. ".
                supported_boundary_hint()
                unless $self->is_contract_identifier($resolved_name);

            $parsed{clock} = $resolved_name;
        } elsif ($directive eq 'sreset' || $directive eq 'areset' || $directive eq 'asreset') {
            Carp::confess
                "Duplicate '+system' reset declaration '$directive'. ".
                "The active contract currently expects exactly one reset declaration. ".
                supported_boundary_hint()
                if $parsed{reset};

            Carp::confess
                "Unsupported '+system' reset name '$resolved_name'. ".
                "Reset declarations must use an HDL-identifier-compatible reset signal name. ".
                supported_boundary_hint()
                unless $self->is_contract_identifier($resolved_name);

            $parsed{reset} = $resolved_name;
            $parsed{reset_keyword} = $directive;
            $parsed{reset_kind} = $directive eq 'sreset' ? 'sync' : 'async';
            $parsed{reset_active_level} = $directive eq 'sreset' ? 1 : 0;
        } else {
            Carp::confess
                "Unsupported '+system' entry '$directive'. ".
                "The active contract currently supports only '(clock name)' plus optional '(sreset reset)' or '(areset rst_n)'. ".
                supported_boundary_hint();
        }
    }

    Carp::confess
        "Incomplete '+system' section. ".
        "The active contract currently expects exactly one '(clock name)' entry. ".
        supported_boundary_hint()
        unless $parsed{clock};

    my $fsm_module = $self->{fsm_module};
    $fsm_module->{attributes}{system_contract} = {
        clock => $parsed{clock},
        reset => $parsed{reset},
        reset_keyword => $parsed{reset_keyword},
        reset_kind => $parsed{reset_kind},
        reset_active_level => $parsed{reset_active_level},
    };
    $fsm_module->{clock_domains}{default} = $parsed{clock};
    $fsm_module->{reset_domains}{default} = $parsed{reset}
        if defined($parsed{reset}) && length($parsed{reset});

    $self->{signal_manager}->register_signal(
        $parsed{clock},
        type => 'clock',
        width => 1,
        attributes => { is_system_signal => 1 },
    );
    if (defined($parsed{reset}) && length($parsed{reset})) {
        $self->{signal_manager}->register_signal(
            $parsed{reset},
            type => 'reset',
            width => 1,
            attributes => { is_system_signal => 1 },
        );
    }
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

    if (defined($width_token) && !ref($width_token) && $self->is_contract_type_reference($width_token)) {
        my $resolved_type = $self->{signal_manager}->resolve_type($width_token);
        if ($resolved_type && ref($resolved_type) eq 'HASH'
            && defined($resolved_type->{width}) && $resolved_type->{width} > 0) {
            return {
                width => 0 + $resolved_type->{width},
                signed => ($resolved_type->{signed} // 0) ? 1 : 0,
                state_model => $resolved_type->{state_model},
                declared_type_name => $width_token,
                declared_type_spec => $resolved_type,
            };
        }

        my $resolved_scalar_width = $self->{signal_manager}->resolve_positive_integer_scalar($width_token);
        return {
            width => $resolved_scalar_width,
            signed => 0,
            state_model => undef,
        } if defined $resolved_scalar_width && $resolved_scalar_width > 0;
    }

    my $expression_error;
    my $resolved_expression_width = eval {
        $self->resolve_positive_width_expression(
            $width_token,
            "Width expression for '+size' signal '$signal_name'",
        );
    };
    $expression_error = $@ if $@;
    return {
        width => $resolved_expression_width,
        signed => 0,
        state_model => undef,
    } if defined($resolved_expression_width) && $resolved_expression_width > 0;

    my $expression_detail = $expression_error
        ? " Width expression resolution failed: $expression_error"
        : '';
    $expression_detail =~ s/\s+\z//;

    Carp::confess
        "Malformed '+size' entry for signal '$signal_name'. ".
        "Each '+size' entry must use an HDL-identifier-compatible signal name and either a positive integer width, a named type such as 'bit', 'byte', 'frame_t', or 'pkg_name.byte', or a positive integer constant expression using literals, constants, enum members, params/generics, aggregate scalar leaves, and supported Lisp-ish arithmetic/bitwise operators. ".
        $expression_detail." ".
        supported_boundary_hint();
}

sub resolve_positive_width_expression($self, $width_expr, $context) {
    my $value = $self->evaluate_constant_integer_expression($width_expr, $context);
    return undef unless defined $value;

    Carp::confess "$context must resolve to a positive integer width.\n"
        unless $value->bcmp(0) > 0;

    return 0 + $value->bstr;
}

sub evaluate_constant_integer_expression($self, $expr, $context) {
    my $normalized = $self->unwrap_scalar_token($expr);

    if (defined($normalized) && !ref($normalized)) {
        return $self->evaluate_constant_integer_scalar($normalized, $context);
    }

    Carp::confess "$context is malformed because the expression payload is empty.\n"
        unless ref($normalized) eq 'ARRAY' && @$normalized;

    my ($operator, @operands) = @$normalized;
    Carp::confess "$context is malformed because the expression operator is not a scalar token.\n"
        if ref($operator);

    my $normalized_operator = $self->normalize_constant_width_operator($operator);
    Carp::confess
        "$context uses unsupported width expression operator '$operator'. ".
        "Supported operators are '+', '-', '*', '/', '%', '&', '|', '^' and aliases 'add', 'sub', 'mul', 'div', 'mod', 'and', 'or', 'xor'.\n"
        unless defined $normalized_operator;

    if (@operands == 1 && ref($operands[0]) eq 'ARRAY') {
        @operands = @{$operands[0]};
    }

    Carp::confess "$context operator '$operator' requires at least two operands.\n"
        unless @operands >= 2;

    my @values = map {
        $self->evaluate_constant_integer_expression($_, "$context operand for '$operator'")
    } @operands;

    return $self->apply_constant_width_operator($normalized_operator, \@values, $context);
}

sub normalize_constant_width_operator($self, $operator) {
    return undef unless defined($operator) && !ref($operator);

    my %operator_aliases = (
        add => '+',
        sub => '-',
        mul => '*',
        div => '/',
        mod => '%',
        and => '&',
        or  => '|',
        xor => '^',
    );

    my $normalized = $operator_aliases{$operator} // $operator;
    my %supported = map { $_ => 1 } qw(+ - * / % & | ^);
    return $supported{$normalized} ? $normalized : undef;
}

sub apply_constant_width_operator($self, $operator, $values, $context) {
    Carp::confess "$context has no width-expression operands.\n"
        unless ref($values) eq 'ARRAY' && @$values;

    my $result = $values->[0]->copy;
    for my $index (1 .. $#$values) {
        my $operand = $values->[$index];
        if ($operator eq '+') {
            $result->badd($operand);
        } elsif ($operator eq '-') {
            $result->bsub($operand);
        } elsif ($operator eq '*') {
            $result->bmul($operand);
        } elsif ($operator eq '/') {
            Carp::confess "$context divides by zero in a width expression.\n"
                if $operand->is_zero;
            $result->bdiv($operand);
        } elsif ($operator eq '%') {
            Carp::confess "$context takes modulo by zero in a width expression.\n"
                if $operand->is_zero;
            $result->bmod($operand);
        } elsif ($operator eq '&') {
            $result->band($operand);
        } elsif ($operator eq '|') {
            $result->bior($operand);
        } elsif ($operator eq '^') {
            $result->bxor($operand);
        } else {
            Carp::confess "$context uses unsupported width expression operator '$operator'.\n";
        }
    }

    Carp::confess "$context resolved to a negative width-expression value.\n"
        if $result->bcmp(0) < 0;

    return $result;
}

sub evaluate_constant_integer_scalar($self, $scalar, $context) {
    my $literal_value = $self->parse_constant_integer_literal($scalar);
    return $literal_value if defined $literal_value;

    my $payload = $self->{signal_manager}->resolve_parameter_value_symbol_payload($scalar);
    if (defined $payload) {
        return $self->evaluate_constant_integer_payload($payload, "$context symbol '$scalar'");
    }

    Carp::confess "$context references unknown or non-scalar constant symbol '$scalar'.\n";
}

sub evaluate_constant_integer_payload($self, $payload, $context) {
    Carp::confess "$context has no constant payload.\n"
        unless defined $payload;

    if (!ref($payload)) {
        my $literal_value = $self->parse_constant_integer_literal($payload);
        Carp::confess "$context payload '$payload' is not an integer literal.\n"
            unless defined $literal_value;
        return $literal_value;
    }

    Carp::confess "$context has malformed constant payload '".ref($payload)."'.\n"
        unless ref($payload) eq 'HASH';

    my $kind = $payload->{kind} || '';
    if ($kind eq 'scalar') {
        return $self->evaluate_constant_integer_payload($payload->{payload}, $context);
    }

    if ($kind eq 'scalar_expr') {
        return $self->evaluate_infix_constant_integer_expression(
            $payload->{payload},
            "$context scalar expression",
        );
    }

    Carp::confess "$context resolved to aggregate payload kind '$kind', not a scalar integer.\n";
}

sub evaluate_infix_constant_integer_expression($self, $expr_text, $context) {
    Carp::confess "$context has no expression text.\n"
        unless defined($expr_text) && !ref($expr_text) && length($expr_text);

    my @tokens = $self->tokenize_infix_constant_integer_expression($expr_text, $context);
    my $index = 0;
    my $value = $self->parse_infix_expression_bp(\@tokens, \$index, 0, $context);

    Carp::confess "$context has trailing tokens after scalar expression.\n"
        if $index < @tokens;

    return $value;
}

sub tokenize_infix_constant_integer_expression($self, $expr_text, $context) {
    my @tokens;
    my $expect_operand = 1;
    pos($expr_text) = 0;
    while (pos($expr_text) < length($expr_text)) {
        if ($expr_text =~ /\G\s+/gc) {
            next;
        }
        if ($expr_text =~ /\G([()])\s*/gc) {
            push @tokens, $1;
            $expect_operand = $1 eq '(' ? 1 : 0;
            next;
        }
        if ($expr_text =~ /\G([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?(?:\[\d+\])*)\s*/gc) {
            push @tokens, $1;
            $expect_operand = 0;
            next;
        }
        my $literal_pattern = $expect_operand
            ? qr/\d+'(?:s?[bodhx][+-]?[0-9A-Fa-f_]+|[+-]?(?:0[dbohx][+-]?[0-9A-Fa-f_]+|\d[\d_]*))|(?:\d+)?'s?[bodhx][+-]?[0-9A-Fa-f_]+|[+-]?0d[+-]?\d[\d_]*|[+-]?0x[+-]?[0-9A-Fa-f_]+|[+-]?0b[+-]?[01_]+|[+-]?0o[+-]?[0-7_]+|[+-]?\d[\d_]*/i
            : qr/\d+'(?:s?[bodhx][+-]?[0-9A-Fa-f_]+|(?:0[dbohx][+-]?[0-9A-Fa-f_]+|\d[\d_]*))|(?:\d+)?'s?[bodhx][+-]?[0-9A-Fa-f_]+|0d[+-]?\d[\d_]*|0x[+-]?[0-9A-Fa-f_]+|0b[+-]?[01_]+|0o[+-]?[0-7_]+|\d[\d_]*/i;
        if ($expr_text =~ /\G($literal_pattern)\s*/gc) {
            push @tokens, $1;
            $expect_operand = 0;
            next;
        }
        if ($expr_text =~ /\G([+\-*\/%&|^])\s*/gc) {
            push @tokens, $1;
            $expect_operand = 1;
            next;
        }

        Carp::confess "$context contains unsupported token near '".substr($expr_text, pos($expr_text), 24)."'.\n";
    }

    return @tokens;
}

sub parse_infix_expression_bp($self, $tokens, $index_ref, $min_bp, $context) {
    Carp::confess "$context ended unexpectedly.\n"
        if $$index_ref >= @$tokens;

    my $token = $tokens->[$$index_ref++];
    my $left;
    if ($token eq '(') {
        $left = $self->parse_infix_expression_bp($tokens, $index_ref, 0, $context);
        Carp::confess "$context is missing a closing parenthesis.\n"
            unless $$index_ref < @$tokens && $tokens->[$$index_ref] eq ')';
        $$index_ref++;
    } else {
        $left = $self->evaluate_constant_integer_scalar($token, $context);
    }

    while ($$index_ref < @$tokens) {
        my $operator = $tokens->[$$index_ref];
        last if $operator eq ')';

        my ($left_bp, $right_bp) = $self->constant_infix_binding_power($operator);
        last unless defined $left_bp && $left_bp >= $min_bp;

        $$index_ref++;
        my $right = $self->parse_infix_expression_bp($tokens, $index_ref, $right_bp, $context);
        $left = $self->apply_constant_width_operator($operator, [$left, $right], $context);
    }

    return $left;
}

sub constant_infix_binding_power($self, $operator) {
    return unless defined($operator) && !ref($operator);
    return (1, 2) if $operator eq '|';
    return (3, 4) if $operator eq '^';
    return (5, 6) if $operator eq '&';
    return (7, 8) if $operator eq '+' || $operator eq '-';
    return (9, 10) if $operator eq '*' || $operator eq '/' || $operator eq '%';
    return;
}

sub parse_constant_integer_literal($self, $literal) {
    return FSM::Package::IntegerLiteralSupport->integer_from_literal_like($literal);
}

sub canonicalize_scalar_type_spec($self, %args) {
    my $module_name = $args{module_name} // 'source';
    my $type_name = $args{type_name} // 'unknown';
    my $spec_ast = $args{spec_ast};

    my $resolved_spec = FSM::Package::DeclarativeTypeSupport->canonicalize_type_spec(
        spec_ast => $spec_ast,
        unwrap_scalar_token => sub ($value) { return $self->unwrap_scalar_token($value) },
        unwrap_single_nested_list => sub ($value) { return $self->unwrap_single_nested_list($value) },
        is_contract_type_reference => sub ($value) { return $self->is_contract_type_reference($value) },
        resolve_type_reference => sub ($type_ref) { return $self->{signal_manager}->resolve_type($type_ref) },
        resolve_positive_integer_width_symbol => sub ($width_symbol) {
            return $self->{signal_manager}->resolve_positive_integer_width_symbol($width_symbol);
        },
        is_contract_identifier => sub ($value) { return $self->is_contract_identifier($value) },
    );
    return $resolved_spec if $resolved_spec;

    Carp::confess
        "Malformed '+types' entry for type '$type_name' in source '$module_name'. ".
        "The first active '+types' lane supports 'bit', '(bits N)', '(bits WIDTH_SYMBOL)', '(signed bit)', '(signed (bits N))', '(signed (bits WIDTH_SYMBOL))', '(two_state ...)', '(four_state ...)', '(list ...)', '(record (field TYPE) ...)', or aliases to already-resolved local/imported types. ".
        supported_boundary_hint();
}

sub canonicalize_constant_literal_payload($self, %args) {
    my $module_name = $args{module_name} // 'source';
    my $section_header = $args{section_header} // '+constants';
    my $symbol_kind = $args{symbol_kind} // 'symbol';
    my $symbol_name = $args{symbol_name} // 'unknown';
    my $value_token = $args{value_token};

    if (FSM::Package::IntegerLiteralSupport->obviously_binary_like_bare_value_literal($value_token)) {
        my ($binary_example, $decimal_example, $exact_width_example) =
            FSM::Package::IntegerLiteralSupport->explicit_examples_for_obviously_binary_like_bare_value_literal($value_token);

        Carp::confess
            "Malformed '$section_header' entry for $symbol_kind '$symbol_name' in source '$module_name' with value token '$value_token'. ".
            "Ambiguous bare integer literals are blocked because FSMGen does not guess obviously bitstring-like bare 0/1 tokens in symbol-value position. ".
            "Use '$binary_example' for intrinsic-width binary, '$exact_width_example' for exact-width binary, or '$decimal_example' if decimal was intended. ".
            supported_boundary_hint();
    }

    my $literal_expr = eval {
        $self->{expression_builder}->parse_scalar_expression($value_token);
    };
    my $parse_error = $@;

    Carp::confess
        "Malformed '$section_header' entry for $symbol_kind '$symbol_name' in source '$module_name' with value token '$value_token'. ".
        "Each '$section_header' value must resolve to a literal scalar value such as '0', '8'3', '8'hA5', or 'const_8b0'. ".
        supported_boundary_hint()
        if $parse_error || ref($literal_expr) ne 'FSM::CoreAST::Literal';

    return $literal_expr->to_systemverilog;
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
        supported_boundary_hint()
        unless ref($value_ast) eq 'ARRAY';

    Carp::confess
        "Malformed '$section_header' entry for $symbol_kind '$symbol_name' in source '$module_name' with an empty aggregate value. ".
        "Aggregate constant values must be non-empty lists or non-empty hash-like member sets. ".
        supported_boundary_hint()
        unless @$value_ast;

    my $value_items = $self->constant_value_items($value_ast);

    Carp::confess
        "Malformed '$section_header' entry for $symbol_kind '$symbol_name' in source '$module_name' with an empty aggregate value. ".
        "Aggregate constant values must be non-empty lists or non-empty hash-like member sets. ".
        supported_boundary_hint()
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
                supported_boundary_hint()
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
        supported_boundary_hint()
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
            supported_boundary_hint();
    }
}

sub is_compound_update_shorthand($self, $action_target, $action_spec) {
    return 0 unless defined $action_target;
    return 0 if ref($action_target);
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
        supported_boundary_hint()
        unless $self->is_inline_compound_modifier_spec($compound_spec) && @$compound_spec <= 2;

    my ($compound_op, $compound_payload) = @$compound_spec;
    my $delta_spec;

    if (@$compound_spec == 1) {
        $delta_spec = '1';
    } elsif (ref($compound_payload) eq 'ARRAY') {
        Carp::confess
            "Malformed inline compound modifier '$modifier_desc' on signal '$signal_name'. ".
            "Inline compound modifiers must use '(+=)', '(-=)', '(+= delta)', or '(-= delta)' after the RHS expression. ".
            supported_boundary_hint()
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
        supported_boundary_hint()
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
        supported_boundary_hint()
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
        supported_boundary_hint();
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
        supported_boundary_hint();
}

sub normalize_explicit_condition_suffix($self, $raw_suffix) {
    return $raw_suffix if ref($raw_suffix);
    return $raw_suffix if defined($raw_suffix) && !ref($raw_suffix) && $raw_suffix =~ /^[<>]/;

    my $display = defined($raw_suffix) ? (ref($raw_suffix) ? ref($raw_suffix) : $raw_suffix) : 'undef';
    Carp::confess
        "Unsupported bare condition suffix '$display'. ".
        "Suffix guards must use the explicit guarded forms '<sig', '<!sig', or an explicit condition expression payload. ".
        supported_boundary_hint();
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
        die(
            "Error: Illegal combinational self-dependency for '$target_signal_name' using '='. "
            . "RHS depends on LHS through combinational chain ($path_str); use '<-' or rewrite expression.\n"
        );
    }
}

sub validate_no_register_input_self_dependency($self, $operator, $target_base_specs, $expr, $expr_role, $target_display) {
    return unless $operator eq '<=' || $operator eq '<=-' || $operator eq '<=+';
    return unless $target_base_specs && ref($target_base_specs) eq 'ARRAY' && @$target_base_specs;
    return unless $expr && ref($expr);

    my %target_names = map {
        my $name = $self->normalize_signal_name($_->{name});
        $name ne '' ? ($name => 1) : ()
    } @$target_base_specs;
    return unless keys %target_names;

    my $source_names = $self->extract_expression_signal_names($expr);
    for my $source_name (@$source_names) {
        next unless defined($source_name) && $source_name ne '';
        next unless $target_names{$source_name};

        die(
            "Error: Illegal D-input self-dependency for '$target_display' using '$operator'. "
            . "The $expr_role references '$source_name', which is the same D-input-named LHS. "
            . "This creates combinational feedback before HDL generation; use '<-' for Q/output-named synchronous feedback, "
            . "or use '<=-' and read the generated '<signal>_r' Q mirror when same-cycle D visibility is required. "
            . supported_boundary_hint()
            . "\n"
        );
    }
}
sub get_target_base_signal_name($self, $raw_signal_name, $target_expr) {
    if ($target_expr) {
        if ($target_expr->can('signal') && $target_expr->signal && $target_expr->signal->can('name')) {
            my $name = eval { $target_expr->signal->name() };
            my $normalized = $self->normalize_signal_name($name);
            return $normalized if $normalized ne '';
        }
    }

    return $self->normalize_signal_name($raw_signal_name);
}

sub describe_assignment_target($self, $raw_target, $target_expr = undef) {
    if ($target_expr && blessed($target_expr) && $target_expr->can('to_systemverilog')) {
        my $rendered = eval { $target_expr->to_systemverilog };
        return $rendered if defined($rendered) && $rendered ne '';
    }

    return 'undef' unless defined $raw_target;
    if (ref($raw_target) eq 'ARRAY') {
        return '(' . join(' ', map {
            !defined($_) ? 'undef'
                : ref($_) eq 'ARRAY' ? 'ARRAY'
                : ref($_) ? ref($_)
                : $_
        } @$raw_target) . ')';
    }
    return ref($raw_target) || $raw_target;
}

sub validate_assignment_lhs_target($self, $raw_target, $target_expr) {
    my $target_display = $self->describe_assignment_target($raw_target, $target_expr);

    if ($target_expr && blessed($target_expr) && $target_expr->isa('FSM::CoreAST::Concatenation')) {
        return $self->validate_lhs_deconstruct_target($target_display, $target_expr);
    }

    return undef if $self->is_static_assignment_lvalue($target_expr);

    my $target_type = defined($target_expr) && ref($target_expr) ? ref($target_expr) : 'undef';
    Carp::confess
        "Malformed assignment target '$target_display'. ".
        "Assignment LHS forms must be writable signal references, static bit/slice references, typed aggregate leaf references, or a bounded '(concat ...)' / '(cat ...)' LHS deconstruct made only of those static lvalues. ".
        "Got '$target_type'. ".
        supported_boundary_hint();
}

sub validate_delayed_pulse_lhs_target($self, $raw_target, $target_expr) {
    my $target_display = $self->describe_assignment_target($raw_target, $target_expr);

    return
        if $target_expr
        && blessed($target_expr)
        && $target_expr->isa('FSM::CoreAST::SignalRef')
        && !$target_expr->slice;

    Carp::confess
        "Malformed delayed pulse target '$target_display'. ".
        "Delayed pulse assignments require a scalar 1-bit signal target, for example '(P <1 1)' or '(<1 (P 1))'. ".
        "Indexed, sliced, aggregate, and deconstruct LHS targets are not supported for '<N' delayed pulses. ".
        supported_boundary_hint();
}

sub is_static_assignment_lvalue($self, $target_expr) {
    return 0 unless $target_expr && blessed($target_expr);
    return 1 if $target_expr->isa('FSM::CoreAST::SignalRef');
    return 1 if $target_expr->isa('FSM::CoreAST::IndexedRef');
    return 1 if $target_expr->isa('FSM::CoreAST::AggregateRef');
    return 0;
}

sub validate_lhs_deconstruct_target($self, $target_display, $target_expr) {
    my @operands = @{$target_expr->operands || []};
    Carp::confess
        "Malformed LHS deconstruct target '$target_display'. ".
        "LHS deconstruct requires at least two static writable operands inside '(concat ...)' or '(cat ...)'. ".
        supported_boundary_hint()
        unless @operands >= 2;

    my @operand_widths;
    my @operand_displays;
    my @ranges;
    my $total_width = 0;

    for my $operand (@operands) {
        my $operand_display = $self->describe_assignment_target(undef, $operand);
        Carp::confess
            "Malformed LHS deconstruct target '$target_display'. ".
            "Operand '$operand_display' is not a legal static writable LHS operand; use a signal, bit/slice, or typed aggregate leaf reference. ".
            supported_boundary_hint()
            unless $self->is_static_assignment_lvalue($operand);

        my $operand_width = $self->{expression_builder}->infer_exact_expression_width($operand);
        Carp::confess
            "Malformed LHS deconstruct target '$target_display'. ".
            "Operand '$operand_display' has no exact positive width; every deconstruct operand must be width-resolved before generation. ".
            supported_boundary_hint()
            unless defined($operand_width) && $operand_width > 0;

        my ($base_name, $high, $low) = $self->assignment_lvalue_range($operand);
        if (defined($base_name) && $base_name ne '') {
            for my $range (@ranges) {
                next unless $range->{base_name} eq $base_name;
                my $overlaps = $low <= $range->{high} && $high >= $range->{low};
                if ($overlaps) {
                    Carp::confess
                        "Malformed LHS deconstruct target '$target_display'. ".
                        "Operand '$operand_display' overlaps an earlier write range on '$base_name'. ".
                        "LHS deconstruct operands must not overlap or duplicate target bits. ".
                        supported_boundary_hint();
                }
            }
            push @ranges, {
                base_name => $base_name,
                high => $high,
                low => $low,
                display => $operand_display,
            };
        }

        push @operand_widths, $operand_width;
        push @operand_displays, $operand_display;
        $total_width += $operand_width;
    }

    return {
        target_display => $target_display,
        operand_widths => \@operand_widths,
        operand_displays => \@operand_displays,
        total_width => $total_width,
    };
}

sub assignment_lvalue_range($self, $target_expr) {
    return unless $target_expr && blessed($target_expr);

    if ($target_expr->isa('FSM::CoreAST::SignalRef')) {
        my $signal = $target_expr->signal;
        my $name = $signal && $signal->can('name') ? $signal->name : undef;
        return unless defined($name) && $name ne '';

        if ($target_expr->slice) {
            my ($raw_high, $raw_low) = @{$target_expr->slice};
            my ($high, $low) = $raw_high >= $raw_low
                ? ($raw_high, $raw_low)
                : ($raw_low, $raw_high);
            return ($name, $high, $low);
        }

        my $width = $signal && $signal->can('width') ? $signal->width : 1;
        $width = 1 unless defined($width) && $width > 0;
        return ($name, $width - 1, 0);
    }

    if ($target_expr->isa('FSM::CoreAST::IndexedRef')) {
        my $signal = $target_expr->signal;
        my $name = $signal && $signal->can('name') ? $signal->name : undef;
        my $index = $target_expr->index;
        $index = $index->value if blessed($index) && $index->can('value');
        return ($name, $index, $index)
            if defined($name) && $name ne '' && defined($index) && $index =~ /^\d+$/;
        return;
    }

    if ($target_expr->isa('FSM::CoreAST::AggregateRef')) {
        my $signal = $target_expr->signal;
        my $name = $signal && $signal->can('name') ? $signal->name : undef;
        my $root_type_spec = $signal && $signal->can('declared_type_spec')
            ? $signal->declared_type_spec
            : undef;
        my $range = FSM::Package::AggregatePathSupport->resolve_packed_range(
            root_type_spec => $root_type_spec,
            path_segments => $target_expr->path,
        );
        return ($name, $range->{high}, $range->{low})
            if defined($name) && $name ne '' && $range->{ok};
    }

    return;
}

sub infer_assignment_lhs_width($self, $raw_target, $target_expr, $deconstruct_contract = undef) {
    if ($deconstruct_contract) {
        my $width = $deconstruct_contract->{total_width};
        return ($width, 1) if defined($width) && $width > 0;
    }

    if (!ref($raw_target) && defined($raw_target) && $raw_target =~ /'(\d+)$/) {
        return ($1, 1);
    }

    if ($target_expr && blessed($target_expr)) {
        if ($target_expr->isa('FSM::CoreAST::SignalRef') && $target_expr->slice) {
            my ($high, $low) = @{$target_expr->slice};
            return (abs($high - $low) + 1, 1);
        }

        if ($target_expr->isa('FSM::CoreAST::IndexedRef')) {
            return (1, 1);
        }

        if ($target_expr->isa('FSM::CoreAST::AggregateRef')
            && $target_expr->can('width')
            && defined($target_expr->width)
            && $target_expr->width > 0) {
            return ($target_expr->width, 1);
        }

        if ($target_expr->isa('FSM::CoreAST::SignalRef')
            && $target_expr->signal
            && defined($target_expr->signal->width)
            && $target_expr->signal->width > 0
            && (
                $target_expr->signal->width > 1
                || ($target_expr->signal->can('get_attribute') && $target_expr->signal->get_attribute('width_declared'))
            )) {
            return ($target_expr->signal->width, 1);
        }
    }

    return (undef, 0);
}

sub assignment_target_base_specs($self, $target_expr, $fallback_width = undef) {
    my $is_concat_target = $target_expr && blessed($target_expr) && $target_expr->isa('FSM::CoreAST::Concatenation');
    my @targets = ($target_expr);
    if ($is_concat_target) {
        @targets = @{$target_expr->operands || []};
    }

    my @specs;
    my %seen;
    for my $target (@targets) {
        next unless $target && blessed($target) && $target->can('signal') && $target->signal && $target->signal->can('name');
        my $name = $target->signal->name;
        my $normalized = $self->normalize_signal_name($name);
        next if $normalized eq '' || $seen{$normalized}++;
        push @specs, {
            name => $normalized,
            width => $self->get_target_base_signal_width($target, $is_concat_target ? undef : $fallback_width),
        };
    }

    return @specs;
}

sub assignment_target_has_explicit_output_marker($self, $raw_target, $target_expr) {
    return 1 if !ref($raw_target) && defined($raw_target) && $raw_target =~ />$/;

    my @targets = ($target_expr);
    if ($target_expr && blessed($target_expr) && $target_expr->isa('FSM::CoreAST::Concatenation')) {
        @targets = @{$target_expr->operands || []};
    }

    for my $target (@targets) {
        next unless $target && blessed($target) && $target->can('signal') && $target->signal && $target->signal->can('get_attribute');
        return 1 if $target->signal->get_attribute('is_output');
    }

    return 0;
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
        } elsif ($target_expr->isa('FSM::CoreAST::AggregateRef')) {
            my $signal_width = eval { $target_expr->signal && $target_expr->signal->width };
            if (defined($signal_width) && $signal_width > $resolved_width) {
                $resolved_width = $signal_width;
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
        supported_boundary_hint()
        unless ref($enums_list) eq 'ARRAY' && @$enums_list;

    my @enum_entries;
    for my $enum_def (@$enums_list) {
        Carp::confess
            "Malformed '+enums' definition. ".
            "Each '+enums' definition must use the shape '(enum_name (MEMBER value) ...)'. ".
            supported_boundary_hint()
            unless ref($enum_def) eq 'ARRAY' && @$enum_def == 2;

        my ($enum_name, $members_list) = @$enum_def;
        my $resolved_enum_name = $self->unwrap_scalar_token($enum_name);

        Carp::confess
            "Malformed '+enums' definition for enum '".$self->describe_contract_name($resolved_enum_name)."'. ".
            "Each '+enums' definition must use an HDL-identifier-compatible enum name and at least one '(MEMBER value)' entry. ".
            supported_boundary_hint()
            unless $self->is_contract_identifier($resolved_enum_name)
                && ref($members_list) eq 'ARRAY'
                && @$members_list;

        my @member_entries;
        for my $member_def (@$members_list) {
            Carp::confess
                "Malformed '+enums' member for enum '$resolved_enum_name'. ".
                "Each enum member must be a pair '(MEMBER value)'. ".
                supported_boundary_hint()
                unless ref($member_def) eq 'ARRAY' && @$member_def == 2;

            my ($member_name, $member_value_array) = @$member_def;
            my $resolved_member_name = $self->unwrap_scalar_token($member_name);
            my $resolved_member_value = $self->unwrap_scalar_token($member_value_array);

            Carp::confess
                "Malformed '+enums' member '".$self->describe_contract_name($resolved_member_name)."' for enum '$resolved_enum_name'. ".
                "Each enum member must use an HDL-identifier-compatible member name and a scalar value token. ".
                supported_boundary_hint()
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
                supported_boundary_hint();
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
                "The active '+types' contract resolves normal non-cyclic type aliases without depending on declaration order, but type dependency cycles are blocked. ".
                "Cycle: ".join(' -> ', @chain).". ".
                supported_boundary_hint();
        },
    );

    return 1;
}

sub parse_import_section($self, $module_name, $imports_ast) {
    my (undef, $imports_list) = @$imports_ast;

    Carp::confess
        "Malformed '+import' section in source '$module_name'. ".
        "The active contract supports '+import' only as a non-empty list of HDL-identifier-compatible package names. ".
        supported_boundary_hint()
        unless ref($imports_list) eq 'ARRAY' && @$imports_list;

    my $module = $self->{fsm_module};
    $module->{attributes}{package_imports} //= [];
    my %seen = map { $_ => 1 } @{ $module->{attributes}{package_imports} || [] };

    for my $package_name (@$imports_list) {
        my $resolved_name = $self->unwrap_scalar_token($package_name);

        Carp::confess
            "Malformed '+import' package name '".$self->describe_contract_name($resolved_name)."' in source '$module_name'. ".
            "The active contract expects each imported package name to be an HDL-identifier-compatible bare name. ".
            supported_boundary_hint()
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
        supported_boundary_hint()
        unless ref($define_spec) eq 'ARRAY' && @$define_spec == 2;

    my ($name, $value) = @$define_spec;
    my $resolved_name = $self->unwrap_scalar_token($name);
    my $resolved_value = $self->unwrap_scalar_token($value);

    Carp::confess
        "Malformed '+define' entry for name '".$self->describe_contract_name($resolved_name)."'. ".
        "The active contract expects an HDL-identifier-compatible name and a scalar value token. ".
        supported_boundary_hint()
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
        "The active contract supports '+params' only as a non-empty list of '(NAME value)' scalar or aggregate entries. ".
        supported_boundary_hint()
        unless ref($params_list) eq 'ARRAY' && @$params_list;

    my @param_entries;
    for my $param_def (@$params_list) {
        Carp::confess
            "Malformed '+params' entry. ".
            "Each '+params' entry must be a pair '(NAME value)'. ".
            supported_boundary_hint()
            unless ref($param_def) eq 'ARRAY' && @$param_def == 2;

        my ($name, $value_array) = @$param_def;
        my $resolved_name = $self->unwrap_scalar_token($name);

        Carp::confess
            "Malformed '+params' entry for parameter '".$self->describe_contract_name($resolved_name)."'. ".
            "Each '+params' entry must use an HDL-identifier-compatible name. ".
            supported_boundary_hint()
            unless $self->is_contract_identifier($resolved_name);

        Carp::confess
            "Malformed '+params' entry for parameter '".$self->describe_contract_name($resolved_name)."'. ".
            "Each '+params' entry must provide a scalar or aggregate value. ".
            supported_boundary_hint()
            unless defined $value_array;

        push @param_entries, {
            name => $resolved_name,
            value_ast => $value_array,
        };
    }

    return \@param_entries;
}

sub resolve_pending_direct_root_params($self, $module_name, $param_entries) {
    $param_entries ||= [];
    return 1 unless @$param_entries;

    my %entry_by_name;
    my @param_order;
    for my $entry (@$param_entries) {
        my $name = $entry->{name};
        Carp::confess
            "Malformed '+params' entry for parameter '".$self->describe_contract_name($name)."' in source '$module_name'. ".
            "Each '+params' declaration may bind a parameter/generic name at most once so one default value remains unambiguous. ".
            supported_boundary_hint()
            if exists $entry_by_name{$name};
        $entry_by_name{$name} = $entry;
        push @param_order, $name;
    }

    my %resolved;
    my %visiting;
    my @stack;
    my $docs_hint = ' ' . supported_boundary_sentence();

    my $resolve_param;
    $resolve_param = sub ($name) {
        return $resolved{$name} if exists $resolved{$name};

        if ($visiting{$name}) {
            my @cycle = (@stack, $name);
            Carp::confess
                "Malformed '+params' dependency graph in source '$module_name'. ".
                "The active '+params' contract resolves normal non-cyclic parameter references without depending on declaration order, but parameter dependency cycles are blocked. ".
                "Cycle: ".join(' -> ', map { "parameter '$_'" } @cycle).". ".
                supported_boundary_hint();
        }

        my $entry = $entry_by_name{$name}
            or return undef;

        $visiting{$name} = 1;
        push @stack, $name;
        my $value_info = FSM::ParameterValueSupport->canonical_value(
            value_ast => $entry->{value_ast},
            context => "Direct source parameter '$name'",
            docs_hint => $docs_hint,
            resolve_symbol_payload => sub ($symbol_name) {
                if (exists $entry_by_name{$symbol_name}) {
                    my $symbol_value_info = $resolve_param->($symbol_name);
                    return $symbol_value_info->{value_payload} if ref($symbol_value_info) eq 'HASH';
                    return undef;
                }
                if ($symbol_name =~ /^([a-zA-Z_]\w*)((?:\.[a-zA-Z_]\w*|\[\d+\])+)\z/ && exists $entry_by_name{$1}) {
                    my ($param_name, $suffix) = ($1, $2);
                    my $symbol_value_info = $resolve_param->($param_name);
                    return FSM::ParameterValueSupport->resolve_payload_path(
                        $symbol_value_info->{value_payload},
                        $suffix,
                    ) if ref($symbol_value_info) eq 'HASH';
                    return undef;
                }
                return $self->{signal_manager}->resolve_parameter_value_symbol_payload($symbol_name);
            },
        );
        pop @stack;
        delete $visiting{$name};

        $resolved{$name} = $value_info;
        return $value_info;
    };

    for my $name (@param_order) {
        my $value_info = $resolve_param->($name);
        $self->{signal_manager}->store_param($name, $value_info);

        if ($self->{fsm_module} && $self->{fsm_module}->can('set_parameter')) {
            $self->{fsm_module}->set_parameter($name, {
                %$value_info,
                origin_kind => 'direct_root_parameter',
            });
        }
    }

    return 1;
}

sub parse_init_assignment_directive($self, $init_ast) {
    my (undef, $payload_list) = @$init_ast;

    Carp::confess
        "Malformed ':=' directive payload. ".
        "The active contract supports canonical top-level init/reset directives like '(:= (signal literal))'. ".
        "Default mode also accepts legacy compact directives like '(:= signal=literal)'. ".
        supported_boundary_hint()
        unless ref($payload_list) eq 'ARRAY' && @$payload_list;

    my @assignments;
    if (@$payload_list == 1) {
        my $init_payload = $self->unwrap_scalar_token($payload_list->[0]);
        if (defined $init_payload && !ref($init_payload)) {
            push @assignments, $self->parse_compact_init_assignment_spec($init_payload);
        } else {
            push @assignments, $self->parse_canonical_init_assignment_payload($init_payload);
        }
    } else {
        for my $init_payload (@$payload_list) {
            my $payload = $self->unwrap_scalar_token($init_payload);
            Carp::confess
                "Malformed ':=' directive payload. ".
                "Multiple entries must use canonical pair payloads like '(:= (signal literal) (other value))'. ".
                "Default-mode legacy compact entries remain single-entry only. ".
                supported_boundary_hint()
                unless ref($payload) eq 'ARRAY';
            push @assignments, $self->parse_canonical_init_assignment_payload($payload);
        }
    }

    for my $assignment (@assignments) {
        $self->register_init_assignment(%$assignment);
    }
}

sub parse_compact_init_assignment_spec($self, $init_spec) {
    my ($signal_name, $reset_value) = $init_spec =~ /^([a-zA-Z_]\w*)=(.+)$/;
    Carp::confess
        "Unsupported ':=' directive '$init_spec'. ".
        "The active contract supports canonical top-level init/reset directives like '(:= (signal literal))'. ".
        "Default mode also accepts legacy compact directives like '(:= signal=literal)'. ".
        supported_boundary_hint()
        unless defined $signal_name && defined $reset_value;

    return {
        signal_name => $signal_name,
        reset_value => $reset_value,
    };
}

sub parse_canonical_init_assignment_payload($self, $payload) {
    Carp::confess
        "Malformed ':=' directive payload. ".
        "Canonical ':=' entries must be pairs like '(signal value)'. ".
        supported_boundary_hint()
        unless ref($payload) eq 'ARRAY' && @$payload == 2;

    my ($signal_token, $reset_token) = @$payload;
    my $signal_name = $self->unwrap_scalar_token($signal_token);
    my $reset_value = $self->unwrap_scalar_token($reset_token);

    Carp::confess
        "Malformed ':=' directive payload. ".
        "Canonical ':=' entries must use an HDL-identifier-compatible signal name and a reset/default expression. ".
        supported_boundary_hint()
        unless defined($signal_name)
            && !ref($signal_name)
            && $signal_name =~ /\A[A-Za-z_]\w*\z/
            && defined($reset_value);

    return {
        signal_name => $signal_name,
        reset_value => $reset_value,
    };
}

sub register_init_assignment($self, %args) {
    my $signal_name = $args{signal_name};
    my $reset_value = $args{reset_value};
    my $reset_value_display = $self->render_lispish_payload($reset_value);

    my $reset_expr = eval { $self->{expression_builder}->parse_expression($reset_value) };
    my $reset_expr_error = $@;
    Carp::confess
        "Unsupported ':=' reset value '$reset_value_display' for signal '$signal_name'. ".
        "The active contract currently expects a valid reset/default expression on the right-hand side. ".
        supported_boundary_hint()
        if $reset_expr_error || !$reset_expr;

    my $reset_value_text = $self->expression_to_systemverilog_text($reset_expr);
    $reset_value_text = $reset_value_display
        unless defined($reset_value_text) && length($reset_value_text);

    my %register_args = (
        attributes => {
            reset_value => $reset_value_text,
            reset_expr => $reset_expr,
            is_explicit_reset => 1,
        },
    );
    my $reset_width = $self->{expression_builder}->infer_exact_expression_width($reset_expr);
    if (defined($reset_width) && $reset_width > 1) {
        $register_args{width} = $reset_width;
    }

    my $signal = $self->{signal_manager}->register_signal($signal_name, %register_args);
    $signal->{initial_value} = $reset_value_text;
    $signal->set_attribute('reset_value', $reset_value_text);
    $signal->set_attribute('reset_expr', $reset_expr);
    $signal->set_attribute('is_explicit_reset', 1);
}

sub render_lispish_payload($self, $payload) {
    return 'undef' unless defined $payload;
    return $payload unless ref($payload);

    if (ref($payload) eq 'ARRAY') {
        return '(' . join(' ', map { $self->render_lispish_payload($_) } @$payload) . ')';
    }

    return ref($payload);
}

sub expression_to_systemverilog_text($self, $expr) {
    return undef unless $expr && blessed($expr) && $expr->can('to_systemverilog');

    if ($expr->isa('FSM::CoreAST::BinaryOp')) {
        my $operator = $expr->operator;
        my %op_map = (
            and => '&',
            or  => '|',
            xor => '^',
            add => '+',
            sub => '-',
            mul => '*',
            div => '/',
            mod => '%',
        );
        my $op = $op_map{$operator} // $operator;
        my $left = $self->expression_to_systemverilog_text($expr->left);
        my $right = $self->expression_to_systemverilog_text($expr->right);
        $left = defined($left) && length($left) ? $left : '0';
        $right = defined($right) && length($right) ? $right : '0';

        return "{$left, $right}" if $op eq 'concat';
        $left = "($left)" if $expr->left && blessed($expr->left) && $expr->left->isa('FSM::CoreAST::BinaryOp');
        $right = "($right)" if $expr->right && blessed($expr->right) && $expr->right->isa('FSM::CoreAST::BinaryOp');
        return "$left $op $right";
    }

    if ($expr->isa('FSM::CoreAST::UnaryOp')) {
        my %op_map = (
            not => '~',
            neg => '-',
            pos => '+',
        );
        my $op = $op_map{$expr->operator} // $expr->operator;
        my $operand = $self->expression_to_systemverilog_text($expr->operand);
        $operand = defined($operand) && length($operand) ? $operand : '0';
        return "$op($operand)";
    }

    if ($expr->isa('FSM::CoreAST::Concatenation')) {
        my @operands = map {
            my $operand_text = $self->expression_to_systemverilog_text($_);
            defined($operand_text) && length($operand_text) ? $operand_text : '0';
        } @{$expr->operands || []};
        return '{' . join(', ', @operands) . '}';
    }

    my $text = eval { $expr->to_systemverilog(undef) };
    return $text if !$@ && defined($text) && length($text);

    $text = eval { $expr->to_systemverilog() };
    return $text if !$@ && defined($text) && length($text);

    return undef;
}


sub parse_state($self, $state_ast) {
    my ($state_name, $decision_trees) = @$state_ast;

    my ($state_type, $clean_name) = $self->classify_state_name($state_name);
    my $dt_enable_condition;

    ($dt_enable_condition, $decision_trees)
        = $self->extract_dt_header_enable_condition($state_name, $decision_trees);
    
    my $state = FSM::CoreAST::State->new(
        name => $clean_name,
        state_type => $state_type,
        dt_enable_condition => $dt_enable_condition,
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
        supported_boundary_hint()
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
        supported_boundary_hint()
        unless $state->decision_trees && @{$state->decision_trees};
    
    return $state;
}

sub extract_dt_header_enable_condition($self, $state_name, $decision_trees) {
    return (undef, $decision_trees)
        unless ref($decision_trees) eq 'ARRAY' && @$decision_trees;

    my @items = @$decision_trees;
    my @condition_parts;

    if (!ref($items[0]) && ($items[0] eq '<' || $items[0] eq '<!')) {
        Carp::confess
            "Malformed DT header enable guard in '$state_name'. ".
            "Guarded DT headers must use '(name <cond ...)', '(-name <cond ...)', or the spaced expression form '(name < condition_expression ...)' with at least one body action after the guard. ".
            supported_boundary_hint()
            unless @items >= 3;
        @condition_parts = splice(@items, 0, 2);
    } elsif (!ref($items[0]) && $items[0] =~ /^<!?.+/) {
        Carp::confess
            "Malformed DT header enable guard in '$state_name'. ".
            "Guarded DT headers must leave at least one body action after the guard condition. ".
            supported_boundary_hint()
            unless @items >= 2;
        @condition_parts = (shift @items);
    } else {
        return (undef, $decision_trees);
    }

    my $full_condition = $self->build_full_condition_from_parts(@condition_parts);
    $full_condition = $self->normalize_explicit_condition_suffix($full_condition);
    my $condition_expr = $self->{expression_builder}->parse_condition($full_condition);

    Carp::confess
        "Malformed DT header enable guard in '$state_name'. ".
        "The guard must lower to a valid condition expression and must be followed by at least one body action. ".
        supported_boundary_hint()
        unless $condition_expr && @items;

    return ($condition_expr, \@items);
}

sub classify_state_name($self, $state_name) {
    Carp::confess
        "Malformed state/DT name '".$self->describe_contract_name($state_name)."'. ".
        "FSM-state DT blocks must use an HDL-identifier-compatible name like 'aState'; ".
        "and non-state DT blocks must use a single leading '-' plus an HDL-identifier-compatible name like '-mycombDT'. ".
        supported_boundary_hint()
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
        "and non-state DT blocks must use a single leading '-' plus an HDL-identifier-compatible name like '-mycombDT'. ".
        supported_boundary_hint();
}

sub parse_decision_tree($self, $tree_ast) {
    my $dt = FSM::CoreAST::DecisionTree->new(name => 'main_dt');
    
    my @elements_to_parse;
    if ($self->is_array_target_assignment_action($tree_ast)) {
        @elements_to_parse = ($tree_ast);
    } elsif (ref($tree_ast->[0]) eq 'ARRAY') {
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

sub is_array_target_assignment_action($self, $action) {
    return 0 unless ref($action) eq 'ARRAY' && @$action >= 2;
    my ($target, $spec) = @$action[0, 1];
    return 0 unless ref($target) eq 'ARRAY';
    return 0 unless ref($spec) eq 'ARRAY' && @$spec >= 2 && !ref($spec->[0]);
    return 0 unless $self->is_assignment_operator_token($spec->[0]);

    my $head = $target->[0];
    return 0 if ref($head);
    my $normalized_operator = $self->{expression_builder}->normalize_expression_operator($head);
    return defined($normalized_operator) && $normalized_operator eq 'concat' ? 1 : 0;
}

sub is_assignment_operator_token($self, $token) {
    return defined($token)
        && !ref($token)
        && $token =~ /^(?:=|<-|<-=|<=|<=-|<=\+|<[0-9]+)$/;
}

sub normalize_assignment_pair_action($self, $action) {
    my ($operator, @raw_payload) = @$action;

    Carp::confess
        "Malformed assignment pair form '".$self->describe_action_for_error($action)."'. ".
        "Canonical pair assignments must use '(assign-op (lhs rhs))' or '(assign-op (lhs rhs) <cond)'. ".
        "Supported assign-op tokens are '=', '<-', '<=', '<-=', '<=-', legacy '<=+', and delayed-pulse forms such as '<1'. ".
        supported_boundary_hint()
        unless $self->is_assignment_operator_token($operator);

    my @payload_items = @raw_payload == 1 && ref($raw_payload[0]) eq 'ARRAY'
        ? @{$raw_payload[0]}
        : @raw_payload;

    Carp::confess
        "Malformed assignment pair form '".$self->describe_action_for_error($action)."'. ".
        "Canonical pair assignments must use '(assign-op (lhs rhs))' or '(assign-op (lhs rhs) <cond)'. ".
        "The first payload after the operator must be one '(lhs rhs)' pair. ".
        supported_boundary_hint()
        unless @payload_items >= 1;

    my $pair = $self->unwrap_scalar_token(shift @payload_items);
    Carp::confess
        "Malformed assignment pair form '".$self->describe_action_for_error($action)."'. ".
        "Canonical pair assignments must use one '(lhs rhs)' payload after the operator, for example '(= (OUT VALUE))'. ".
        supported_boundary_hint()
        unless ref($pair) eq 'ARRAY' && @$pair == 2;

    my ($lhs, $rhs) = @$pair;
    $lhs = $self->unwrap_scalar_token($lhs);
    $rhs = $self->unwrap_scalar_token($rhs);

    Carp::confess
        "Malformed assignment pair form '".$self->describe_action_for_error($action)."'. ".
        "Canonical pair assignments require both LHS and RHS payloads, for example '(= (OUT VALUE))'. ".
        supported_boundary_hint()
        unless defined($lhs) && defined($rhs);

    return [$lhs, [$operator, $rhs, @payload_items]];
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
        supported_boundary_hint()
        unless ref($action) eq 'ARRAY' && @$action >= 2;
    
    my ($action_target, $action_spec) = @$action;
    my $action_target_display = defined($action_target)
        ? (ref($action_target) ? ref($action_target) : $action_target)
        : 'undef';
    fsm_debug("      Parsing action: $action_target_display", 3);
    
    if (!ref($action_target) && $action_target eq '->') {
        return $self->parse_transition_new_format($action);
    } elsif (!ref($action_target) && $action_target =~ /^\?repeat:/) {
        Carp::confess
            "Unsupported generic/template repeat action '$action_target'. ".
            "The active contract does not support legacy '?repeat:...' expansion forms. ".
            "Expand the template before parsing or keep it in legacy-only sources. ".
            supported_boundary_hint();
    } elsif (!ref($action_target) && $action_target =~ /^\?\[[^\]]+\]$/) {
        Carp::confess
            "Unsupported generic/template test selector '$action_target'. ".
            "The active contract does not support legacy placeholder selectors like '?[NAME]'. ".
            "Expand the template before parsing or keep it in legacy-only sources. ".
            supported_boundary_hint();
    } elsif (!ref($action_target) && $action_target =~ /^\?/) {
        return $self->parse_test_node_new_format($action);
    } elsif ($self->is_compound_update_shorthand($action_target, $action_spec)) {
        return $self->parse_compound_update_shorthand($action);
    } elsif ($self->is_assignment_operator_token($action_target)) {
        return $self->parse_signal_action($self->normalize_assignment_pair_action($action));
    } elsif (!ref($action_target) && $action_target =~ /^[<>]/) {
        return $self->parse_nested_condition_new_format($action);
    } elsif (ref($action_spec) eq 'ARRAY' && @$action_spec >= 2) {
        return $self->parse_signal_action($action);
    } else {
        Carp::confess
            "Unsupported action form '".$self->describe_action_for_error($action)."'. ".
            "Actions inside decision trees must use a supported transition, assignment, guarded block, test node, or update form. ".
            supported_boundary_hint();
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
            supported_boundary_hint()
            unless @$target_spec >= 1;

        $target_state = $target_spec->[0];
        my @condition_parts = @$target_spec[1 .. $#$target_spec];
        if (@condition_parts) {
            if (@condition_parts == 1) {
                $condition_suffix = $self->build_full_condition_from_parts(@condition_parts);
            } elsif (@condition_parts == 2
                && !ref($condition_parts[0])
                && ($condition_parts[0] eq '<' || $condition_parts[0] eq '<!')
                && defined $condition_parts[1]) {
                $condition_suffix = $self->build_full_condition_from_parts(@condition_parts);
            } else {
                my $suffix_display = join(', ', map { ref($_) ? ref($_) : $_ } @condition_parts);
                Carp::confess
                    "Malformed transition condition suffix '$suffix_display'. ".
                    "State transitions must use '(-> target_state)', '(-> target_state <condition_suffix)', or '(-> target_state < condition_expression)'. ".
                    supported_boundary_hint();
            }
        }
    } else {
        $target_state = $target_spec;
    }

    my $target_display = defined($target_state)
        ? (ref($target_state) ? ref($target_state) : $target_state)
        : 'undef';

    Carp::confess
        "Malformed transition target '$target_display'. ".
        "State transitions must target an HDL-identifier-compatible regular FSM-state DT name like 'busy'. ".
        supported_boundary_hint()
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
        my @payload = @$action > 2
            ? @$action[1 .. $#$action]
            : (ref($branches) eq 'ARRAY' ? @$branches : ());

        Carp::confess
            "Malformed computed test selector '?'. ".
            "Computed test nodes must use '?(expr)' with a valid selector expression followed by at least one selector branch such as '(?(| A B) (=0 ...) (=1 ...))'. ".
            supported_boundary_hint()
            unless @payload >= 2;

        # Format: (?(| a b) (=0 x))
        # The condition expression is the first payload element; the remaining
        # payload elements are selector branches.
        my $cond_ast = shift @payload;
        $branches = \@payload;

        if (ref($cond_ast) eq 'ARRAY' && @$cond_ast) {
            my $selector_head = $cond_ast->[0];
            if ($self->is_computed_test_branch_marker($selector_head)) {
                Carp::confess
                    "Malformed computed test selector '?'. ".
                    "Computed test nodes must start with a real selector expression before the branch list, for example '(?(| A B) (=0 ...) (=1 ...))'. ".
                    supported_boundary_hint();
            }
        }

        if (
            ref($cond_ast) eq 'ARRAY'
            && @$cond_ast >= 1
            && !ref($cond_ast->[0])
            && (@$cond_ast == 1 || (@$cond_ast == 2 && !defined($cond_ast->[1])))
        ) {
            $cond_ast = $cond_ast->[0];
        }

        my $condition_expr = $self->{expression_builder}->parse_condition($cond_ast);
        
        if ($condition_expr && $condition_expr->isa('FSM::CoreAST::SignalRef')) {
            $signal = $condition_expr->signal;
        } else {
            # Need to create an intermediate signal for this complex condition
            my $intermediate_name = $self->{expression_builder}->generate_intermediate_signal('cond', [$condition_expr || FSM::CoreAST::Literal->new('0')]);
            my $selector_width = eval { $self->{expression_builder}->infer_exact_expression_width($condition_expr) };
            my %signal_attributes = (
                type => 'wire',
                is_intermediate => 1,
            );
            $signal_attributes{width} = $selector_width
                if defined($selector_width) && $selector_width > 0;

            $signal = $self->{signal_manager}->register_signal($intermediate_name, %signal_attributes);
            $signal->set_driving_ast($condition_expr) if $condition_expr;
        }
    } else {
        # Format: (?is_last (=0 x))
        my ($signal_name) = $test_signal =~ /^\?(.+)/;

        Carp::confess
            "Malformed test signal '$test_signal'. ".
            "Plain test nodes must use '?signal_name' with an HDL-identifier-compatible signal name, or the computed form '?(expr)'. ".
            supported_boundary_hint()
            unless defined($signal_name)
                && $signal_name =~ /\A[A-Za-z_]\w*\z/;

        $signal = $self->{signal_manager}->register_signal($signal_name);
    }
    
    my $test_node = FSM::CoreAST::TestNode->new(test_signal => $signal);
    my $seen_default_branch = 0;
    
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
                supported_boundary_hint()
                unless ref($branch) eq 'ARRAY' && @$branch >= 2;

	            my ($test_value, @branch_actions) = @$branch;
            $self->validate_test_branch_selector($test_value);
            if ($self->is_default_test_branch_selector($test_value)) {
                Carp::confess
                    "Malformed test selector '$test_value'. ".
                    "A test node may contain at most one default selector branch, spelled 'default' or '_'. ".
                    supported_boundary_hint()
                    if $seen_default_branch++;
            }
            $self->propagate_test_selector_width_to_signal($signal, $test_value);
	            my @parsed_actions;

            for my $branch_action (@branch_actions) {
                Carp::confess
                    "Malformed test branch '$test_value'. ".
                    "Test-node branches must include at least one real nested action after the selector. ".
                    supported_boundary_hint()
                    unless defined $branch_action;

                if (ref($branch_action) eq 'ARRAY') {
                    if (@$branch_action > 0
                        && ref($branch_action->[0]) eq 'ARRAY'
                        && !$self->is_array_target_assignment_action($branch_action)) {
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

sub is_computed_test_branch_marker($self, $value) {
    return 0 unless defined($value) && !ref($value);
    return 1 if $self->is_default_test_branch_selector($value);
    return $value =~ /\A(?:==|!=|<=|>=|=|<|>).+\z/
        && $value !~ /\A(?:==|!=|<=|>=|=|<|>)\z/;
}

sub validate_test_branch_selector($self, $test_value) {
    my $display = defined($test_value)
        ? (ref($test_value) ? ref($test_value) : $test_value)
        : 'undef';

    return 1 if $self->is_default_test_branch_selector($test_value);

    Carp::confess
        "Malformed test selector '$display'. ".
        "Test-node branches must use an explicit selector token like '=0', '=OTHER', '!=8\\'0', or '>8\\'3', or a single default selector spelled 'default' or '_'. ".
        supported_boundary_hint()
        unless defined($test_value)
            && !ref($test_value)
            && $test_value =~ /^(?:==|!=|<=|>=|=|<|>).+/;

    return 1;
}

sub is_default_test_branch_selector($self, $test_value) {
    return defined($test_value)
        && !ref($test_value)
        && ($test_value eq 'default' || $test_value eq '_');
}

sub propagate_test_selector_width_to_signal($self, $signal, $test_value) {
    return unless $signal && $signal->can('name');
    return unless defined($test_value) && !ref($test_value);
    return if $self->is_default_test_branch_selector($test_value);

    my ($raw_value) = $test_value =~ /^(?:==|!=|<=|>=|=|<|>)(.+)$/;
    return unless defined($raw_value) && length($raw_value);

    my $selector_expr = eval { $self->{expression_builder}->parse_expression($raw_value) };
    return unless $selector_expr;

    my $selector_width = eval { $self->{expression_builder}->infer_exact_expression_width($selector_expr) };
    return unless defined($selector_width) && $selector_width > 0;

    $self->{signal_manager}->register_signal(
        $signal->name,
        width => $selector_width,
    );
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
        if (ref($nested_action) eq 'ARRAY'
            && @$nested_action > 0
            && ref($nested_action->[0]) eq 'ARRAY'
            && !$self->is_array_target_assignment_action($nested_action)) {
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
        supported_boundary_hint();
}

sub parse_signal_action($self, $action) {
    my ($signal_name, $operation_spec) = @$action;
    return undef unless ref($operation_spec) eq 'ARRAY' && @$operation_spec >= 2;
    
    my ($operator, $value_expr, @operation_tail) = @$operation_spec;
    my $signal_name_display = $self->describe_assignment_target($signal_name);
    
    my $compound_spec;
    my @condition_parts;
    for my $tail (@operation_tail) {
        if ($self->is_inline_compound_modifier_spec($tail)) {
            Carp::confess
                "Duplicate inline compound modifier '".$self->describe_inline_compound_modifier($tail)."' on signal '$signal_name_display'. ".
                "Only one inline compound modifier may follow the RHS expression. ".
                supported_boundary_hint()
                if $compound_spec;
            $compound_spec = $tail;
            next;
        }
        push @condition_parts, $tail;
    }
    my $full_condition = $self->build_full_condition_from_parts(@condition_parts);

    my $target_expr = $self->{expression_builder}->parse_signal_reference($signal_name);
    my $lhs_deconstruct_contract = $self->validate_assignment_lhs_target($signal_name, $target_expr);
    $signal_name_display = $self->describe_assignment_target($signal_name, $target_expr);
    $self->validate_delayed_pulse_lhs_target($signal_name, $target_expr)
        if defined($operator) && $operator =~ /^<\d+$/;
    my $source_expr = $self->{expression_builder}->parse_expression($value_expr);
    my $raw_source_expr_display;
    my ($compound_operator_used, $compound_delta_used);
    
    if ($compound_spec) {
        my ($compound_op, $delta_spec) = $self->normalize_inline_compound_modifier($signal_name_display, $compound_spec);
        
        my $delta_expr = $self->{expression_builder}->parse_expression($delta_spec);
        $delta_expr //= FSM::CoreAST::Literal->new('1');
        
        my $arith_op = ($compound_op eq '+=') ? '+' : '-';
        $source_expr = FSM::CoreAST::BinaryOp->new($arith_op, $source_expr, $delta_expr);
        $compound_operator_used = $compound_op;
        $compound_delta_used = $delta_spec;
        
        fsm_debug("[Parser.pm][parse_signal_action()] Applied compound modifier '$compound_op' with delta '$delta_spec' on '$signal_name_display'", 3);
    }
    $raw_source_expr_display = eval { $source_expr->to_systemverilog };

    my $aggregate_contract = $compound_spec
        ? undef
        : $self->resolve_direct_assignment_aggregate_contract($value_expr, $source_expr, $target_expr);
    $self->infer_whole_target_aggregate_contract_from_source(
        target_expr => $target_expr,
        aggregate_contract => $aggregate_contract,
    );
    
    my @target_base_specs = $self->assignment_target_base_specs($target_expr);
    my $target_base_signal = @target_base_specs == 1
        ? $target_base_specs[0]{name}
        : '';
    if ($operator eq '=') {
        for my $target_base_spec (@target_base_specs) {
            $self->record_combinational_dependencies($target_base_spec->{name}, $source_expr);
        }
    } elsif ($operator eq '<=' || $operator eq '<=-' || $operator eq '<=+') {
        $self->validate_no_register_input_self_dependency(
            $operator,
            \@target_base_specs,
            $source_expr,
            'RHS expression',
            $signal_name_display,
        );
    }

    my ($lhs_width, $rhs_width, $final_width);
    my ($lhs_explicit, $rhs_explicit) = (0, 0);

    ($lhs_width, $lhs_explicit) = $self->infer_assignment_lhs_width(
        $signal_name,
        $target_expr,
        $lhs_deconstruct_contract,
    );

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
    } elsif (ref($source_expr) eq 'FSM::CoreAST::AggregateRef'
        && $source_expr->can('width')
        && defined($source_expr->width)
        && $source_expr->width > 0) {
        $rhs_width = $source_expr->width;
        $rhs_explicit = 1;
    } elsif (ref($source_expr) eq 'FSM::CoreAST::Concatenation') {
        my $concat_width = $self->{expression_builder}->infer_exact_expression_width($source_expr);
        if (defined($concat_width) && $concat_width > 0) {
            $rhs_width = $concat_width;
            $rhs_explicit = 1;
        }
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

    if ($lhs_deconstruct_contract) {
        Carp::confess
            "Malformed LHS deconstruct assignment '$signal_name_display'. ".
            "The RHS must have an exact positive width before generation so the deconstruct split is unambiguous. ".
            supported_boundary_hint()
            unless $rhs_explicit && defined($rhs_width) && $rhs_width > 0;

        Carp::confess
            "Malformed LHS deconstruct assignment '$signal_name_display'. ".
            "LHS deconstruct total width $lhs_width does not match RHS width $rhs_width. ".
            "FSMGen will not silently pad or truncate deconstruct assignments; align the RHS explicitly before generation. ".
            supported_boundary_hint()
            unless $lhs_width == $rhs_width;

        $width_contract{resolution} = 'exact_match';
        $final_width = $lhs_width;
    } elsif ($lhs_explicit && $rhs_explicit) {
        if ($lhs_width != $rhs_width) {
            $self->{expression_builder}->handle_width_mismatch($lhs_width, $rhs_width, $signal_name_display, $value_expr, \$source_expr);
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

    @target_base_specs = $self->assignment_target_base_specs($target_expr, $final_width);
    $target_base_signal = @target_base_specs == 1
        ? $target_base_specs[0]{name}
        : '';
    for my $target_base_spec (@target_base_specs) {
        if ($target_base_spec->{name} ne '' && $target_base_spec->{width} > 1) {
            $self->{signal_manager}->register_signal($target_base_spec->{name}, width => $target_base_spec->{width});
        }
    }
    
    $target_expr = $self->{expression_builder}->parse_signal_reference($signal_name); 
    if ($lhs_deconstruct_contract) {
        $lhs_deconstruct_contract = $self->validate_assignment_lhs_target($signal_name, $target_expr);
    }
    
    my $output_exposure = $self->assignment_target_has_explicit_output_marker($signal_name, $target_expr) ? 'explicit' : 'auto';
    if ($output_exposure eq 'auto') {
        if (ref($target_expr) && $target_expr->can('signal') && $target_expr->signal && $target_expr->signal->can('get_attribute')) {
            $output_exposure = $target_expr->signal->get_attribute('is_output') ? 'explicit' : 'auto';
        }
    }
    
    my %source_provenance = (
        raw_signal_name => ref($signal_name) ? $signal_name_display : $signal_name,
        raw_operator => $operator,
        raw_value_expr => ref($value_expr) ? ref($value_expr) : $value_expr,
        raw_value_expr_rendered => $raw_source_expr_display,
        raw_condition_suffix => defined($full_condition) ? (ref($full_condition) ? ref($full_condition) : $full_condition) : undef,
        had_compound_modifier => $compound_spec ? 1 : 0,
    );
    $aggregate_contract //= $self->resolve_direct_assignment_aggregate_contract($value_expr, $source_expr, $target_expr);
    if ($aggregate_contract) {
        $source_provenance{aggregate_symbol_name} = $aggregate_contract->{symbol_name};
        $source_provenance{aggregate_type_spec} = $aggregate_contract->{type_spec};
    }
    if (defined $compound_operator_used) {
        $source_provenance{compound_operator} = $compound_operator_used;
        $source_provenance{compound_delta} = $compound_delta_used;
    }
    $source_provenance{width_contract} = \%width_contract;
    $source_provenance{lhs_deconstruct} = $lhs_deconstruct_contract
        if $lhs_deconstruct_contract;

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
        my $next_output_name = $target_base_signal ne '' ? "next_$target_base_signal" : undef;
        for my $target_base_spec (@target_base_specs) {
            my $aux_output_name = "next_$target_base_spec->{name}";
            $self->{signal_manager}->register_signal(
                $aux_output_name,
                width => $target_base_spec->{width},
                is_output => 1,
                is_aux_output => 1,
            );
        }
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
                (defined($next_output_name) ? (auxiliary_output_name => $next_output_name) : ()),
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
    } elsif ($operator eq '<=-' || $operator eq '<=+') {
        my $q_output_name = $target_base_signal ne '' ? $target_base_signal . '_r' : undef;
        for my $target_base_spec (@target_base_specs) {
            my $aux_output_name = $target_base_spec->{name} . '_r';
            $self->{signal_manager}->register_signal(
                $aux_output_name,
                width => $target_base_spec->{width},
                is_output => 1,
                is_aux_output => 1,
            );
        }
        $assignment = FSM::CoreAST::RegisterAssignment->new(
            target => $target_expr,
            source => $source_expr,
            register_style => 'input_named',
            output_exposure => $output_exposure,
            source_provenance => \%source_provenance,
            assignment_intent => {
                operator_symbol => $operator,
                sequencing => 'clocked',
                register_style => 'input_named',
                assignment_family => 'mux_dual_output',
                lhs_binding => 'flop_d_input',
                immediate_visibility => 'same_cycle_on_d_input',
                hold_policy => 'q_feedback_when_no_enable',
                expose_q_output => 1,
                (defined($q_output_name) ? (auxiliary_output_name => $q_output_name) : ()),
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
            "Unsupported assignment operator '$operator' for signal '$signal_name_display'. ".
            "Decision-tree assignments must use one of '=', '<-', '<-=', '<=', '<=-', legacy '<=+', or a delayed-pulse form like '<1'. ".
            supported_boundary_hint();
    }
    
    if (defined $full_condition) {
        my $condition_expr = $self->{expression_builder}->parse_condition($full_condition);
        if ($condition_expr) {
            if ($operator eq '<=' || $operator eq '<=-' || $operator eq '<=+') {
                $self->validate_no_register_input_self_dependency(
                    $operator,
                    \@target_base_specs,
                    $condition_expr,
                    'guard condition',
                    $signal_name_display,
                );
            }
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

sub resolve_direct_assignment_aggregate_contract($self, $value_expr, $source_expr = undef, $target_expr = undef) {
    if (!ref($value_expr) && defined($value_expr) && length($value_expr)) {
        my $aggregate_payload = $self->{signal_manager}->resolve_aggregate_symbol_payload($value_expr);
        if (defined $aggregate_payload) {
            my $type_spec = FSM::Package::PayloadTypeSupport->payload_to_type_spec($aggregate_payload);
            if (FSM::Package::AggregateExpressionTypeSupport->is_aggregate_type_spec($type_spec)) {
                return {
                    symbol_name => $value_expr,
                    type_spec => $type_spec,
                    source_kind => 'aggregate_constant_root',
                };
            }
        }
    }

    return undef unless $source_expr && blessed($source_expr);

    my ($type_spec, $symbol_name);
    if ($source_expr->isa('FSM::CoreAST::Concatenation')) {
        my %type_spec_args = (
            source_expr => $source_expr,
            target_expr => $target_expr,
            width_resolver => sub($expr) {
                return $self->{expression_builder}->infer_exact_expression_width($expr);
            },
        );
        $type_spec = FSM::Package::AggregateExpressionTypeSupport->concat_expression_type_spec_for_target(
            %type_spec_args,
        );
        $type_spec //= FSM::Package::AggregateExpressionTypeSupport->concat_expression_list_type_spec(
            $source_expr,
            width_resolver => $type_spec_args{width_resolver},
        );
        $symbol_name = eval { $source_expr->to_systemverilog };
        return undef unless FSM::Package::AggregateExpressionTypeSupport->is_aggregate_type_spec($type_spec);
        return {
            symbol_name => $symbol_name,
            type_spec => $type_spec,
            source_kind => 'concat_expression',
        };
    } elsif ($source_expr->isa('FSM::CoreAST::SignalRef')) {
        return undef if $source_expr->slice;
        my $signal = $source_expr->signal;
        return undef unless $signal && blessed($signal) && $signal->can('declared_type_spec');

        $type_spec = $signal->declared_type_spec;
        $symbol_name = eval { $source_expr->to_systemverilog };
        $symbol_name ||= $signal->can('name') ? $signal->name : undef;
        return undef unless FSM::Package::AggregateExpressionTypeSupport->is_aggregate_type_spec($type_spec);
        return {
            symbol_name => $symbol_name,
            type_spec => $type_spec,
            source_kind => 'typed_signal',
        };
    } elsif ($source_expr->isa('FSM::CoreAST::AggregateRef')) {
        $type_spec = $source_expr->type_spec;
        $symbol_name = eval { $source_expr->to_systemverilog };
        return undef unless FSM::Package::AggregateExpressionTypeSupport->is_aggregate_type_spec($type_spec);
        return {
            symbol_name => $symbol_name,
            type_spec => $type_spec,
            source_kind => 'aggregate_ref',
        };
    } else {
        return undef;
    }

    return undef;
}

sub infer_whole_target_aggregate_contract_from_source($self, %args) {
    my $target_expr = $args{target_expr};
    my $aggregate_contract = $args{aggregate_contract};

    return undef unless ref($aggregate_contract) eq 'HASH';
    my $source_kind = $aggregate_contract->{source_kind} || '';
    return undef unless $source_kind eq 'aggregate_constant_root' || $source_kind eq 'concat_expression';

    my $type_spec = $aggregate_contract->{type_spec};
    return undef unless FSM::Package::AggregateExpressionTypeSupport->is_aggregate_type_spec($type_spec);
    return undef if $source_kind eq 'concat_expression' && ($type_spec->{kind} || '') ne 'list';

    return undef unless $target_expr && blessed($target_expr) && $target_expr->isa('FSM::CoreAST::SignalRef');
    return undef if $target_expr->slice;

    my $signal = $target_expr->signal;
    return undef unless $signal && blessed($signal) && $signal->can('name');

    return undef if defined($signal->declared_type_name);
    my $existing_type_spec = $signal->can('declared_type_spec') ? $signal->declared_type_spec : undef;
    return undef if ref($existing_type_spec) eq 'HASH';
    return undef if $signal->can('get_attribute') && $signal->get_attribute('width_declared');

    my $inferred_width = $type_spec->{width};
    return undef unless defined($inferred_width) && $inferred_width > 0;

    my $current_width = $signal->can('width') ? $signal->width : undef;
    return undef
        if defined($current_width)
            && $current_width > 1
            && $current_width != $inferred_width;

    my $signal_name = $signal->name;
    my $inferred_type_name = $self->inferred_aggregate_type_name_for_signal($signal_name);

    $self->{signal_manager}->register_signal(
        $signal_name,
        width => $inferred_width,
        declared_type_name => $inferred_type_name,
        declared_type_spec => $type_spec,
    );

    return {
        symbol_name => $aggregate_contract->{symbol_name},
        inferred_type_name => $inferred_type_name,
        type_spec => $type_spec,
    };
}

sub inferred_aggregate_type_name_for_signal($self, $signal_name) {
    my $safe_name = defined($signal_name) ? $signal_name : 'signal';
    $safe_name =~ s/[^A-Za-z0-9_]+/_/g;
    $safe_name = 'signal' unless $safe_name =~ /[A-Za-z0-9_]/;
    $safe_name = "_$safe_name" unless $safe_name =~ /\A[A-Za-z_]/;
    return "fsmgen_inferred_${safe_name}";
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
                supported_boundary_hint();
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
            supported_boundary_hint();
    }
    return $logic_level;
}

1;
