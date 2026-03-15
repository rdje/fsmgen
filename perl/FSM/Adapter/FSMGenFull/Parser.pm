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
    }, $class;
}

sub get_fsm_module($self) {
    return $self->{fsm_module};
}

sub parse_fsm($self, $raw_ast) {
    fsm_trace_enter('Parser parse_fsm() entry', 2);
    fsm_debug("Starting full FSMGen parsing", 3);
    $self->reset_combinational_dependency_tracking();

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
            "The active toolchain supports '?fsm:name' and '+fsm' as FSM sources, and '?top:name' through the composition pipeline. ".
            "Other tagged source kinds such as '?define:' are out of active support. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }
    
    if (ref($raw_ast) eq 'ARRAY') {
        if (@$raw_ast > 0 && !ref($raw_ast->[0]) && $raw_ast->[0] =~ /^\?fsm:/) {
            fsm_trace_decision(1, "Detected '?fsm:' structured AST header", 2);
            my $module = $self->parse_fsm_module($raw_ast);
            fsm_trace_exit('Parser parse_fsm() completed via ?fsm path', 2);
            return $module;
        }
        
        if (@$raw_ast > 0 && ref($raw_ast->[0]) eq 'ARRAY' && $raw_ast->[0][0] eq '+fsm') {
            fsm_trace_decision(1, "Detected '+fsm' flattened AST header", 2);
            my $module = $self->parse_fsm_module(['root_array', $raw_ast], 1);
            fsm_trace_exit('Parser parse_fsm() completed via +fsm path', 2);
            return $module;
        }
        
        for my $ast_node (@$raw_ast) {
            if (ref($ast_node) eq 'ARRAY' && @$ast_node > 0 && !ref($ast_node->[0]) && $ast_node->[0] =~ /^\?fsm:/) {
                fsm_trace_decision(1, "Detected nested '?fsm:' AST node", 2);
                my $module = $self->parse_fsm_module($ast_node);
                fsm_trace_exit('Parser parse_fsm() completed via nested ?fsm path', 2);
                return $module;
            }
        }
    }
    
    fsm_trace_decision(0, "AST root did not match expected FSM shape", 1);
    Carp::confess "Expected FSM structure containing '?fsm:name' or '+fsm'";
}

sub parse_fsm_module($self, $fsm_ast, $is_flat_ast = 0) {
    fsm_trace_enter('Parser parse_fsm_module() entry', 2);
    $self->reset_combinational_dependency_tracking();
    my $module_name;
    my $fsm_contents;
    
    if ($is_flat_ast) {
        fsm_trace_decision(1, 'Using flat AST module header decoding path', 2);
        my $ast_array = $fsm_ast->[1];
        my $fsm_header = $ast_array->[0];
        $module_name = $fsm_header->[1][0];
        $fsm_contents = $ast_array;
    } else {
        fsm_trace_decision(1, 'Using standard AST module header decoding path', 2);
        my ($fsm_header, $contents) = @$fsm_ast;
        ($module_name) = $fsm_header =~ /\?fsm:(\w+)/;
        $fsm_contents = $contents;
    }
    
    fsm_debug("Parsing FSM module: $module_name", 3);
    
    my $module = FSM::CoreAST::FSMModule->new(name => $module_name);
    $self->{fsm_module} = $module;
    
    for my $element (@$fsm_contents) {
        next unless ref($element) eq 'ARRAY';
        my $element_name = $element->[0];
        
        if ($element_name eq '+fsm') {
            next;
        } elsif ($element_name eq '+system') {
            fsm_debug("Parsing +system block", 3);
            $self->parse_system_section($element);
        } elsif ($element_name eq '+size') {
            fsm_debug("Parsing +size block", 3);
            if (ref($element->[1]) eq 'ARRAY') {
                for my $size_def (@{$element->[1]}) {
                    my ($sig, $width) = @$size_def;
                    my $resolved_width = (ref($width) eq 'ARRAY') ? $width->[0] : $width;
                    $self->{signal_manager}->register_signal($sig, width => $resolved_width);
                    
                    # Keep rm/mr auxiliary outputs width-aligned with their parent signal
                    # even when +size appears after assignment actions.
                    my $next_aux = "next_$sig";
                    if ($self->{signal_manager}->get_signal($next_aux)) {
                        $self->{signal_manager}->register_signal(
                            $next_aux,
                            width => $resolved_width,
                            is_output => 1,
                            is_aux_output => 1,
                        );
                    }
                    my $q_aux = "${sig}_r";
                    if ($self->{signal_manager}->get_signal($q_aux)) {
                        $self->{signal_manager}->register_signal(
                            $q_aux,
                            width => $resolved_width,
                            is_output => 1,
                            is_aux_output => 1,
                        );
                    }
                }
            }
        } elsif ($element_name eq '+constants') {
            fsm_debug("Parsing constants section", 3);
            $self->parse_constants_section($element);
        } elsif ($element_name eq '+enums') {
            fsm_debug("Parsing enums section", 3);
            $self->parse_enums_section($element);
        } elsif ($element_name eq '+define') {
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
                "Inside '?fsm:name', the active contract supports directive sections, ':=' init/reset directives, and state/DT blocks only. ".
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
                "Inside '?fsm:name', the active contract supports directive sections, ':=' init/reset directives, and state/DT blocks only. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        } elsif ($element_name =~ /^\+/) {
            Carp::confess
                "Unsupported top-level directive '$element_name'. ".
                "The active contract currently supports only '+system', '+size', '+constants', '+enums', '+define', and '+params' inside '?fsm:name'. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        } elsif ($element_name =~ /^[a-zA-Z_]/ && $element_name !~ /^(idle|-syncrst|-syncreset|-asyncrst|-asyncreset)$/ && !ref($element->[1])) {
            my $detail = join(' ', map {
                defined($_) ? (ref($_) ? ref($_) : $_) : 'undef'
            } @$element);
            Carp::confess
                "Unsupported top-level form '($detail)'. ".
                "Inside '?fsm:name', the active contract supports directive sections, ':=' init/reset directives, and state/DT blocks only. ".
                "Future-looking bare forms such as '(lhs := value)' are not part of the active contract yet. ".
                "See docs/USER_GUIDE.md for the current supported boundary.\n";
        } else {
            fsm_debug("Parsing state block: $element_name", 3);
            my $state = $self->parse_state($element);
            $module->add_state($state) if $state;
        }
    }

    $self->validate_no_combinational_self_dependency();
    fsm_trace_exit("Parser parse_fsm_module() completed for '$module_name'", 2);
    return $module;
}

sub parse_constants_section($self, $constants_ast) {
    my (undef, $constants_list) = @$constants_ast;
    for my $constant_def (@$constants_list) {
        my ($name, $value) = @$constant_def;
        my $literal_expr = $self->{expression_builder}->parse_scalar_expression(
            $self->unwrap_scalar_token($value)
        );
        $self->{signal_manager}->store_constant($name, $literal_expr);
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
sub is_compound_update_shorthand($self, $action_target, $action_spec) {
    return 0 unless defined $action_target;
    return 0 unless ref($action_spec) eq 'ARRAY' && @$action_spec >= 1;
    
    # Supported forms:
    #   (++ signal)
    #   (-- signal)
    #   (+=2 signal) / (-=4 signal)
    #   (+= signal amount) / (-= signal amount)
    return ($action_target =~ /^(?:\+\+|--|\+=.*|-=.*)$/) ? 1 : 0;
}

sub parse_compound_update_shorthand($self, $action) {
    my ($compound_token, $args) = @$action;
    return undef unless ref($args) eq 'ARRAY' && @$args >= 1;
    
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
    return undef unless defined $signal_name && !ref($signal_name);
    
    my @remaining = @$args[1 .. $#$args];
    if (!defined($delta_spec) && @remaining) {
        $delta_spec = shift @remaining;
    }
    $delta_spec = '1' unless defined $delta_spec;
    
    fsm_debug("[Parser.pm][parse_compound_update_shorthand()] Expanding '$compound_token' for '$signal_name' with delta '$delta_spec'", 3);
    
    # Canonical expansion:
    #   (++ x)      => (x <- x (+= 1))
    #   (+=2 x)     => (x <- x (+= 2))
    #   (-=4 x)     => (x <- x (-= 4))
    my @operation_spec = ('<-', $signal_name, [$compound_op, [$delta_spec]], @remaining);
    my $expanded_action = [$signal_name, \@operation_spec];
    
    return $self->parse_signal_action($expanded_action);
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

sub parse_enums_section($self, $enums_ast) {
    my (undef, $enums_list) = @$enums_ast;
    for my $enum_def (@$enums_list) {
        my ($enum_name, $members_list) = @$enum_def;
        my %enum_values;
        for my $member_def (@$members_list) {
            my ($member_name, $member_value_array) = @$member_def;
            $enum_values{$member_name} = $self->unwrap_scalar_token($member_value_array);
        }
        $self->{signal_manager}->store_enum($enum_name, \%enum_values);
    }
}

sub parse_define_directive($self, $define_ast) {
    my (undef, $define_spec) = @$define_ast;
    $define_spec = $define_spec->[0]
        if ref($define_spec) eq 'ARRAY' && @$define_spec == 1 && ref($define_spec->[0]) eq 'ARRAY';

    my ($name, $value) = @$define_spec;
    my $value_expr = $self->{expression_builder}->parse_scalar_expression(
        $self->unwrap_scalar_token($value)
    );
    $self->{signal_manager}->store_define($name, $value_expr);
}

sub parse_params_section($self, $params_ast) {
    my (undef, $params_list) = @$params_ast;
    for my $param_def (@$params_list) {
        my ($name, $value_array) = @$param_def;
        $self->{signal_manager}->store_param($name, $self->unwrap_scalar_token($value_array));
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

    my $reset_expr = $self->{expression_builder}->parse_expression($reset_value);
    Carp::confess
        "Unsupported ':=' reset value '$reset_value' for signal '$signal_name'. ".
        "The active contract currently expects a valid scalar reset/default expression on the right-hand side. ".
        "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless $reset_expr;

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
    
    for my $tree (@trees) {
        if (ref($tree) eq 'ARRAY') {
            my $dt = $self->parse_decision_tree($tree);
            $state->add_decision_tree($dt) if $dt;
        }
    }
    
    return $state;
}

sub classify_state_name($self, $state_name) {
    return ('sync_reset', 'syncreset')
        if $state_name eq '-syncrst' || $state_name eq '-syncreset';
    return ('async_reset', 'asyncreset')
        if $state_name eq '-asyncrst' || $state_name eq '-asyncreset';
    return ('normal', $state_name);
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
        $target_state = $target_spec->[0];
        $condition_suffix = $target_spec->[1] if @$target_spec > 1;
    } else {
        $target_state = $target_spec;
    }
    
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
        # Format: (?(| a b) (=0 x))
        # The condition expression is the first element of branches
        my $cond_ast = shift @$branches;
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
        if (!$compound_spec && ref($tail) eq 'ARRAY' && @$tail >= 1 && !ref($tail->[0]) && ($tail->[0] eq '+=' || $tail->[0] eq '-=')) {
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
        my ($compound_op, $compound_payload) = @$compound_spec;
        my $delta_spec;
        
        if (ref($compound_payload) eq 'ARRAY' && @$compound_payload) {
            $delta_spec = $compound_payload->[0];
        } elsif (defined $compound_payload) {
            $delta_spec = $compound_payload;
        }
        $delta_spec = '1' unless defined $delta_spec;
        
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
    } elsif (ref($target_expr) eq 'FSM::CoreAST::SignalRef' && $target_expr->signal && $target_expr->signal->width && $target_expr->signal->width > 1) {
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
    } elsif (ref($source_expr) eq 'FSM::CoreAST::SignalRef' && $source_expr->signal && $source_expr->signal->width && $source_expr->signal->width > 1) {
        $rhs_width = $source_expr->signal->width;
        $rhs_explicit = 1;
    }

    if ($lhs_explicit && $rhs_explicit) {
        if ($lhs_width != $rhs_width) {
            $self->{expression_builder}->handle_width_mismatch($lhs_width, $rhs_width, $signal_name, $value_expr, \$source_expr);
        }
        $final_width = $lhs_width;
    } elsif ($lhs_explicit) {
        $final_width = $lhs_width;
        $self->{expression_builder}->propagate_width_to_expression($source_expr, $final_width);
    } elsif ($rhs_explicit) {
        $final_width = $rhs_width;
        $self->{expression_builder}->propagate_width_to_expression($target_expr, $final_width);
    } else {
        $final_width = 1;
    }

    if ($final_width && ref($target_expr) eq 'FSM::CoreAST::SignalRef' && !$target_expr->slice) {
        my $signal = $target_expr->signal;
        if ($signal && (!$signal->width || $signal->width == 1) && $final_width > 1) {
            $self->{signal_manager}->register_signal($signal->name, width => $final_width);
        }
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
            width => $final_width,
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
            width => $final_width,
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
        Carp::confess "[Parser.pm][parse_signal_action()] Unsupported assignment operator '$operator' for signal '$signal_name'";
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
    my $logic_level;
    if ($source_expr && $source_expr->isa('FSM::CoreAST::Literal')) {
        my $value = $source_expr->value;
        my $width = $source_expr->width;
        my $radix = $source_expr->radix // 'decimal';
        if (defined($width) && $width != 1) {
            Carp::confess "[Parser.pm][resolve_single_bit_logic_level()] Delayed pulse RHS must be 1-bit literal 0/1, got width '$width'";
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
        my $rhs_desc = defined($raw_value_expr) ? (ref($raw_value_expr) ? ref($raw_value_expr) : $raw_value_expr) : 'undef';
        Carp::confess "[Parser.pm][resolve_single_bit_logic_level()] Delayed pulse '<N' requires RHS literal 0 or 1, got '$rhs_desc'";
    }
    return $logic_level;
}

1;
