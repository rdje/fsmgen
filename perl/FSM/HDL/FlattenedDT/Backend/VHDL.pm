package FSM::HDL::FlattenedDT::Backend::VHDL;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::Support::HDLInstanceIdentifierPolicy;
use FSM::Backend::VHDL::DirectParameterEmitter;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::Backend::VHDL::DirectDeclarationPlan;
use FSM::DirectDeclaredWidthSupport;

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[VHDL.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

sub generate_vhdl ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    fsm_debug("[VHDL.pm][generate_vhdl()] Starting flattened DT direct VHDL generation for " . $fsm_module->name, 3);
    my $capture = $ctx->{declared_width_declaration_capture}
        // FSM::Backend::VerilogFamily::DeclarationCapture->new;
    local $ctx->{declared_width_declaration_capture} = $capture;
    my $sv_hdl = $ctx->{orchestrator}->generate_systemverilog($fsm_module);
    my $snapshot;
    if (keys %{$fsm_module->parameters}) {
        my $source = eval {FSM::DirectDeclaredWidthSupport->prepare_module(
            fsm_module => $fsm_module, assignment_analysis => $ctx->{assignment_analysis},
            target_language => 'systemverilog')};
        confess _unsupported("direct source width preparation failed: $@") if $@;
        if ($source->{profile} eq 'symbolic') {
            _validate_symbolic_generated_shapes($ctx, $fsm_module, $source);
            $snapshot = $capture->snapshot;
        }
    }
    return $self->_convert_systemverilog_to_vhdl($sv_hdl, $fsm_module, $snapshot);
}

sub _validate_symbolic_generated_shapes ($ctx, $fsm_module, $source) {
    # Register helpers carry actual allocation origins and have already passed
    # complete declaration/range/origin qualification in source generation.
    # Pulse and other unproved allocation families must not borrow that shape.
    my $internal = $ctx->{enable_graph_module_planning_support}->build_internal_signal_declaration_plan(
        $fsm_module, $ctx->{declared_port_signals});
    for my $name (sort keys %{$internal->{aux_decls}}) {
        my $origin = $internal->{aux_width_origins}{$name};
        my $parent = ref($origin) eq 'HASH' && defined($origin->{source_name})
            && !ref($origin->{source_name}) ? $source->{signals}{$origin->{source_name}} : undef;
        confess _unsupported("symbolic source auxiliary '$name' requires a qualified register parent shape")
            unless ref($origin) eq 'HASH' && join(',', sort keys %$origin) eq 'kind,source_name'
                && defined($origin->{kind}) && !ref($origin->{kind})
                && $origin->{kind} =~ /\A(?:register_next|register_q)\z/
                && $parent && $internal->{aux_decls}{$name} == $parent->{width};
    }
    confess _unsupported('symbolic source intermediate computed shapes require separate qualification')
        if keys %{$ctx->{intermediate_signals}};
    my $state = $ctx->{enable_graph_module_planning_support}->build_state_register_plan($fsm_module);
    confess _unsupported('symbolic source without transitions requires qualified state-hold lowering')
        if $state->{has_state_registers} && !exists($ctx->{assignment_analysis}{next_state});
    return;
}

sub convert_systemverilog_to_vhdl ($self, $sv_hdl) {
    return $self->_convert_systemverilog_to_vhdl($sv_hdl);
}

sub _convert_systemverilog_to_vhdl ($self, $sv_hdl, $fsm_module = undef, $capture = undef) {
    my $identifiers = _plan_generated_vhdl_identifiers($sv_hdl);
    $sv_hdl = $identifiers->{text};
    my %aggregate_type_widths = _parse_packed_struct_typedef_widths($sv_hdl);
    my $module = _parse_module($sv_hdl);
    my ($plan, $parsed);
    if (defined $capture) {
        $plan = eval {FSM::Backend::VHDL::DirectDeclarationPlan->prepare(
            fsm_module => $fsm_module, declaration_capture => $capture,
            assignment_analysis => $self->{flattened_dt}{assignment_analysis},
            identifier_map => $identifiers->{identifier_map})};
        confess _unsupported("direct declaration preparation failed: $@") if $@;
        $parsed = _parse_direct_declarations($sv_hdl, $plan);
    }
    my @generics = _parse_generics($module->{parameters});
    my @ports = $parsed ? @{$parsed->{ports}} : _parse_ports($module->{ports}, \%aggregate_type_widths);
    my $body = $module->{body};
    my @constants = _parse_constants($body);
    my @signals = $parsed ? @{$parsed->{signals}}
        : _parse_signal_declarations($body, { map { $_->{name} => 1 } @ports });
    if ($plan) {
        @generics = _direct_generics_from_plan(\@generics, $plan->{generic_plan});
    }
    elsif (defined($fsm_module) && keys %{$fsm_module->parameters}) {
        @generics = _prepare_direct_generics(
            $fsm_module,
            {
                module_name => $module->{name},
                identifier_map => $identifiers->{identifier_map},
                parameter_names => [map { $_->{name} } @generics],
                ports => [map { $_->{name} } @ports],
                signals => [map { $_->{name} } @signals],
                constants => [map { $_->{name} } @constants],
                types => [],
            },
            \@generics,
        );
    }
    my %decls_by_name = map { $_->{name} => $_ } (@ports, @signals);
    my %vector_reduction_helpers = _required_vector_reduction_helpers($body, \%decls_by_name);
    _validate_vector_reduction_helper_names(
        \%vector_reduction_helpers,
        $module->{name},
        \@generics,
        \@constants,
        \@ports,
        \@signals,
    );
    my @assigns = _parse_continuous_assignments($body);
    my @processes = _parse_processes($body, \%decls_by_name);

    return _render_vhdl(
        module_name => $module->{name},
        generics => \@generics,
        ports => \@ports,
        constants => \@constants,
        signals => \@signals,
        assigns => \@assigns,
        processes => \@processes,
        decls_by_name => \%decls_by_name,
        vector_reduction_helpers => \%vector_reduction_helpers,
    );
}

sub _prepare_direct_generics ($fsm_module, $namespace, $generics) {
    my $plan = eval {
        FSM::Backend::VHDL::DirectParameterEmitter->lower_declarations(
            fsm_module => $fsm_module,
            target_namespace => $namespace,
            target_language => 'vhdl',
        );
    };
    confess _unsupported("direct generic preparation failed: $@") if $@;
    return _direct_generics_from_plan($generics, $plan);
}

sub _direct_generics_from_plan ($generics, $plan) {
    my %by_name = map { $_->{name} => $_ } @$generics;
    for my $declaration (@{$plan->{natural_declarations}}) {
        $by_name{$declaration->{name}} = {
            name => $declaration->{name},
            type => $declaration->{type},
            default => $declaration->{default_text},
        };
    }
    return map { $by_name{$_} } @{$plan->{parameter_order}};
}

# The source-aware path supplies an actual completed paired plan. Public raw
# conversion has no source authority and keeps the bounded numeric parser.
sub _parse_direct_declarations ($sv_hdl, $plan) {
    confess _unsupported('direct declaration parsing requires a prepared paired plan')
        unless ref($plan) eq 'HASH' && ref($plan->{ranges}) eq 'HASH'
            && ref($plan->{target_namespace}) eq 'HASH'
            && ref($plan->{target_declarations}) eq 'HASH';
    my $namespace = $plan->{target_namespace};
    my $module = _parse_module($sv_hdl);
    confess _unsupported('direct declaration module disagrees with its prepared namespace')
        unless $module->{name} eq $namespace->{module_name};
    my %types = _parse_packed_struct_typedef_widths($sv_hdl);
    my @generics = _parse_generics($module->{parameters});
    my @ports = _parse_ports($module->{ports}, \%types, $plan->{ranges});
    my @constants = _parse_constants($module->{body});
    my @signals = _parse_signal_declarations($module->{body},
        {map {$_->{name} => 1} @ports}, $plan->{ranges});
    my %groups = (parameter_names => [map {$_->{name}} @generics],
        ports => [map {$_->{name}} @ports], signals => [map {$_->{name}} @signals],
        constants => [map {$_->{name}} @constants], types => [keys %types]);
    my %seen;
    for my $role (qw(parameter_names ports signals constants types)) {
        confess _unsupported("direct declaration namespace requires '$role' membership")
            unless ref($namespace->{$role}) eq 'ARRAY';
        for my $name (@{$groups{$role}}) {
            confess _unsupported("duplicate direct declaration '$name'") if $seen{$name}++;
        }
        my @expected = sort @{$namespace->{$role}};
        my @actual = sort @{$groups{$role}};
        confess _unsupported("direct declaration $role membership disagrees with its prepared namespace")
            unless join("\0", @actual) eq join("\0", @expected);
    }
    my %decls = map {$_->{name} => $_} (@ports, @signals);
    confess _unsupported('direct declaration record membership disagrees with generated text')
        unless join("\0", sort keys %decls) eq join("\0", sort keys %{$plan->{target_declarations}});
    for my $name (sort keys %decls) {
        # Arithmetic may set Perl scalar numeric flags. Compare local copies so
        # independent parsed bounds and supplied records keep their JSON kinds.
        my $actual = {%{$decls{$name}}};
        my $expected = {%{$plan->{target_declarations}{$name}}};
        confess _unsupported("direct declaration '$name' width disagrees with its prepared record")
            unless _decl_width($actual) == $expected->{width};
        confess _unsupported("direct declaration '$name' signedness disagrees with its prepared record")
            unless ($actual->{signed} // 0) == $expected->{signed};
    }
    for my $name (sort keys %{$plan->{ranges}}) {
        confess _unsupported("direct symbolic declaration '$name' is absent from generated membership")
            unless exists($decls{$name}) && exists($decls{$name}{vhdl_type});
    }
    return {module => $module, generics => \@generics, ports => \@ports,
        constants => \@constants, signals => \@signals};
}

sub _parse_planned_range ($name, $role, $signed, $range, $plan, %attributes) {
    confess _unsupported("direct symbolic declaration '$name' has the wrong role")
        unless $plan->{declaration_kind} eq $role;
    confess _unsupported("direct symbolic declaration '$name' has the wrong signedness")
        unless $signed == $plan->{signed};
    confess _unsupported("direct symbolic declaration '$name' range disagrees with its prepared source spelling")
        unless $range eq $plan->{source_range};
    return _decl_hash(name => $name, %attributes, signed => $signed,
        msb => $plan->{width} - 1, lsb => 0,
        vhdl_range => $plan->{target_range}, vhdl_type => $plan->{target_type});
}

sub _normalize_generated_vhdl_identifiers ($sv_hdl) {
    return _plan_generated_vhdl_identifiers($sv_hdl)->{text};
}

sub _plan_generated_vhdl_identifiers ($sv_hdl) {
    my $lexeme = qr{
        "(?:\\.|[^"\\])*"
        | //[^\n]*
        | /\*.*?\*/
        | [A-Za-z_][A-Za-z0-9_]*
    }xs;
    my %identifier;
    while ($sv_hdl =~ /($lexeme)/g) {
        my $token = $1;
        next if $token =~ /\A(?:"|\/\/|\/\*)/;
        $identifier{$token} = 1;
    }

    my %owner = map { lc($_) => $_ }
        grep { _has_vhdl_basic_identifier_shape($_) } keys %identifier;
    my %replacement;
    for my $original (sort keys %identifier) {
        next if _has_vhdl_basic_identifier_shape($original);
        my $base = $original;
        $base =~ s/_+/_/g;
        $base =~ s/\A_+|_+\z//g;
        $base = "n_$base" unless $base =~ /\A[A-Za-z]/;
        $base = 'fsmgen_vhdl_identifier' unless length $base;
        $base .= '_identifier'
            if _is_vhdl_reserved_identifier($base);

        my $candidate = $base;
        my $suffix = 2;
        while (
            exists($owner{lc($candidate)})
            || _is_vhdl_reserved_identifier($candidate)
        ) {
            $candidate = "${base}_$suffix";
            ++$suffix;
        }
        $owner{lc($candidate)} = $original;
        $replacement{$original} = $candidate;
    }

    $sv_hdl =~ s{($lexeme)}{
        my $token = $1;
        exists($replacement{$token}) ? $replacement{$token} : $token;
    }gex;
    return {text => $sv_hdl, identifier_map => \%replacement};
}

sub _is_vhdl_basic_identifier ($value) {
    return _has_vhdl_basic_identifier_shape($value)
        && !_is_vhdl_reserved_identifier($value);
}

sub _has_vhdl_basic_identifier_shape ($value) {
    return defined($value)
        && $value =~ /\A[A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)*\z/;
}

sub _is_vhdl_reserved_identifier ($value) {
    return scalar grep { $_ eq 'VHDL' }
        @{FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages($value)};
}

sub _parse_module ($sv_hdl) {
    $sv_hdl =~ /\bmodule\s+([A-Za-z_][A-Za-z0-9_]*)\b/g
        or confess _unsupported('could not locate the generated module boundary');

    my $name = $1;
    my $pos = _skip_ws($sv_hdl, pos($sv_hdl));
    my $parameters = '';

    if (substr($sv_hdl, $pos, 1) eq '#') {
        $pos = _skip_ws($sv_hdl, $pos + 1);
        my $parameter_block = _consume_parenthesized($sv_hdl, $pos, 'parameter block');
        $parameters = $parameter_block->{content};
        $pos = _skip_ws($sv_hdl, $parameter_block->{next});
    }

    my $port_block = _consume_parenthesized($sv_hdl, $pos, 'port list');
    $pos = _skip_ws($sv_hdl, $port_block->{next});
    substr($sv_hdl, $pos, 1) eq ';'
        or confess _unsupported('could not locate the generated module boundary');
    $pos++;

    pos($sv_hdl) = $pos;
    $sv_hdl =~ /\G\s*(.*?)\nendmodule\b/gs
        or confess _unsupported('could not locate the generated module boundary');

    return {
        name => $name,
        parameters => $parameters,
        ports => $port_block->{content},
        body => $1,
    };
}

sub _parse_generics ($parameter_text) {
    my @generics;

    for my $raw_line (split /\n/, $parameter_text) {
        my $line = _strip_line_comment($raw_line);
        $line =~ s/^\s+|\s+$//g;
        $line =~ s/,\s*$//;
        next unless length $line;

        if ($line =~ /^parameter\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/) {
            my $default = _sv_parameter_default_to_vhdl($2);
            push @generics, {
                name => $1,
                type => $default->{type},
                default => $default->{default},
            };
            next;
        }

        confess _unsupported("unsupported generated parameter declaration '$line'");
    }

    return @generics;
}

sub _parse_ports ($port_text, $aggregate_type_widths = {}, $ranges = undef) {
    my @ports;

    for my $raw_line (split /\n/, $port_text) {
        my $line = _strip_line_comment($raw_line);
        $line =~ s/^\s+|\s+$//g;
        $line =~ s/,\s*$//;
        next unless length $line;

        if (defined($ranges) && $line =~ /^(input\s+(?:wire|bit|logic)|output(?:\s+(?:reg|wire|logic))?)\s+(?:(signed)\s+)?(\[[^\]]+\]\s+)?([A-Za-z_][A-Za-z0-9_]*)$/) {
            my ($prefix, $signed, $range, $name) = ($1, $2, $3, $4);
            if (exists($ranges->{$name})) {
                push @ports, _parse_planned_range($name, 'port', defined($signed) ? 1 : 0,
                    $range // '', $ranges->{$name}, direction => $prefix =~ /^input/ ? 'in' : 'out');
                next;
            }
        }

        if ($line =~ /^input\s+logic\s+signed\s+\[(\d+):(\d+)\]\s+([A-Za-z_][A-Za-z0-9_]*)$/) {
            push @ports, _decl_hash(name => $3, direction => 'in', signed => 1, msb => $1, lsb => $2);
            next;
        }

        if ($line =~ /^input\s+logic\s+signed\s+([A-Za-z_][A-Za-z0-9_]*)$/) {
            push @ports, _decl_hash(name => $1, direction => 'in', signed => 1);
            next;
        }

        if ($line =~ /^input\s+(?:wire|bit|logic)\s+(?:\[(\d+):(\d+)\]\s+)?([A-Za-z_][A-Za-z0-9_]*)$/) {
            push @ports, _decl_hash(name => $3, direction => 'in', msb => $1, lsb => $2);
            next;
        }

        if ($line =~ /^output(?:\s+(?:reg|wire|logic))?\s+signed\s+\[(\d+):(\d+)\]\s+([A-Za-z_][A-Za-z0-9_]*)$/) {
            push @ports, _decl_hash(name => $3, direction => 'out', signed => 1, msb => $1, lsb => $2);
            next;
        }

        if ($line =~ /^output(?:\s+(?:reg|wire|logic))?\s+signed\s+([A-Za-z_][A-Za-z0-9_]*)$/) {
            push @ports, _decl_hash(name => $1, direction => 'out', signed => 1);
            next;
        }

        if ($line =~ /^output(?:\s+(?:reg|wire))?\s+(?:\[(\d+):(\d+)\]\s+)?([A-Za-z_][A-Za-z0-9_]*)$/) {
            push @ports, _decl_hash(name => $3, direction => 'out', msb => $1, lsb => $2);
            next;
        }

        if ($line =~ /^output\s+([A-Za-z_][A-Za-z0-9_]*)\s+([A-Za-z_][A-Za-z0-9_]*)$/) {
            my ($type_name, $port_name) = ($1, $2);
            my $width = $aggregate_type_widths->{$type_name}
                or confess _unsupported("unsupported generated aggregate output type '$type_name'");
            push @ports, _decl_hash(name => $port_name, direction => 'out', msb => $width - 1, lsb => 0);
            next;
        }

        confess _unsupported("unsupported generated port declaration '$line'");
    }

    return @ports;
}

sub _parse_packed_struct_typedef_widths ($sv_hdl) {
    my %widths;

    while ($sv_hdl =~ /\btypedef\s+struct\s+packed\s*\{/g) {
        my $block = _consume_braced($sv_hdl, pos($sv_hdl) - 1, 'packed struct typedef');
        my $after_block = _skip_ws($sv_hdl, $block->{next});
        my $tail = substr($sv_hdl, $after_block);
        $tail =~ /\A([A-Za-z_][A-Za-z0-9_]*)\s*;/
            or confess _unsupported('unsupported packed struct typedef');
        my $type_name = $1;
        $widths{$type_name} = _packed_struct_member_width($block->{content});
        pos($sv_hdl) = $after_block + length($&);
    }

    return %widths;
}

sub _packed_struct_member_width ($content) {
    my $width = 0;
    pos($content) = 0;

    while (1) {
        my $pos = _skip_ws($content, pos($content) // 0);
        last if $pos >= length($content);
        pos($content) = $pos;

        if ($content =~ /\Gstruct\s+packed\s*\{/gc) {
            my $block = _consume_braced($content, pos($content) - 1, 'nested packed struct member');
            my $after_block = _skip_ws($content, $block->{next});
            my $tail = substr($content, $after_block);
            $tail =~ /\A[A-Za-z_][A-Za-z0-9_]*\s*;/
                or confess _unsupported('unsupported nested packed struct member');
            $width += _packed_struct_member_width($block->{content});
            pos($content) = $after_block + length($&);
            next;
        }

        if ($content =~ /\Glogic\s+(?:\[(\d+):(\d+)\]\s+)?[A-Za-z_][A-Za-z0-9_]*\s*;/gc) {
            my ($msb, $lsb) = ($1, $2);
            $width += defined($msb) && defined($lsb) ? abs($msb - $lsb) + 1 : 1;
            next;
        }

        my $snippet = substr($content, $pos, 80);
        $snippet =~ s/\s+/ /g;
        confess _unsupported("unsupported packed struct member '$snippet'");
    }

    return $width;
}

sub _parse_constants ($body) {
    my @constants;

    while ($body =~ /^\s*localparam\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^;]+);\s*$/mg) {
        my ($name, $expr) = ($1, $2);
        my $literal = _parse_sized_literal($expr)
            or confess _unsupported("unsupported localparam expression '$expr'");
        push @constants, {
            name => $name,
            type => _vhdl_type($literal->{width} - 1, 0),
            value => _literal_bits_value($literal, force_vector => 1),
        };
    }

    return @constants;
}

sub _parse_signal_declarations ($body, $port_names, $ranges = undef) {
    my @signals;

    for my $raw_line (split /\n/, $body) {
        my $line = _strip_line_comment($raw_line);
        $line =~ s/^\s+|\s+$//g;
        next unless length $line;

        if (defined($ranges) && $line =~ /^(reg|wire|bit|logic)\s+(?:(signed)\s+)?(\[[^\]]+\]\s+)?(.+);$/) {
            my ($kind, $signed, $range, $names) = ($1, $2, $3, $4);
            for my $name (split /,/, $names) {
                $name = _trim($name);
                confess _unsupported("direct declaration '$name' has a duplicate port/storage role")
                    if $port_names->{$name};
                if (exists($ranges->{$name})) {
                    push @signals, _parse_planned_range($name, 'signal', defined($signed) ? 1 : 0,
                        $range // '', $ranges->{$name}, kind => $kind);
                } else {
                    # Use the unchanged numeric parser for every independent row.
                    push @signals, _parse_signal_declarations(
                        "$kind " . (defined($signed) ? 'signed ' : '') . ($range // '') . "$name;", {});
                }
            }
            next;
        }

        next unless $line =~ /^(reg|wire|bit|logic)\s+(?:(signed)\s+)?(?:\[(\d+):(\d+)\]\s+)?(.+);$/;
        my ($kind, $signed_keyword, $msb, $lsb, $names_text) = ($1, $2, $3, $4, $5);
        my $signed = defined $signed_keyword ? 1 : 0;

        my @names = map {
            my $name = $_;
            $name =~ s/^\s+|\s+$//g;
            $name;
        } split /,/, $names_text;

        for my $name (@names) {
            confess _unsupported("unsupported generated declaration name '$name'")
                unless $name =~ /^[A-Za-z_][A-Za-z0-9_]*$/;
            next if $port_names->{$name};
            push @signals, _decl_hash(name => $name, kind => $kind, signed => $signed, msb => $msb, lsb => $lsb);
        }
    }

    return @signals;
}

sub _parse_continuous_assignments ($body) {
    my @assigns;

    for my $raw_line (split /\n/, $body) {
        my $line = _strip_line_comment($raw_line);
        $line =~ s/^\s+|\s+$//g;
        next unless length $line;

        next unless $line =~ /^assign\s+([A-Za-z_][A-Za-z0-9_]*(?:\[[^\]]+\])?)\s*=\s*(.+);$/;
        my ($lhs, $expr) = ($1, $2);
        push @assigns, {
            raw_lhs => $lhs,
            lhs => _sv_lvalue_to_vhdl($lhs),
            expr => $expr,
        };
    }

    return @assigns;
}

sub _parse_processes ($body, $decls_by_name) {
    # Discover procedural keywords outside comments, quoted metadata and
    # identifiers. This converter accepts only the generated multiline profile;
    # silently overlooking another process would discard executable behavior.
    my $lexeme = qr{
        "(?:\\.|[^"\\])*"
        | //[^\n]*
        | /\*.*?\*/
        | \\[^\s]+
        | [A-Za-z_\$][A-Za-z0-9_\$]*
    }xs;
    $body =~ s{($lexeme)}{
        my $token = $1;
        $token =~ /\A(?:\/\/|\/\*)/ ? ($token =~ s/[^\n]/ /gr) : $token;
    }gex;
    while ($body =~ /($lexeme)/g) {
        my ($token, $offset) = ($1, $-[0]);
        next unless $token =~ /\A(?:always|always_comb|always_ff|always_latch|initial|final)\z/;
        my $start = rindex($body, "\n", $offset) + 1;
        my $end = index($body, "\n", $offset);
        $end = length($body) if $end < 0;
        my $header = substr($body, $start, $end - $start);
        confess _unsupported("unsupported direct process header '$header'; expected generated always_comb/always_ff begin blocks")
            unless $header =~ /\A\s*always_comb\s+begin\s*\z/
                || $header =~ /\A\s*always_ff\s*\@\([^)]+\)\s+begin\s*\z/;
    }

    my @lines = split /\n/, $body;
    my @processes;

    for (my $idx = 0; $idx <= $#lines; $idx++) {
        next unless $lines[$idx] =~ /^\s*always_(?:comb|ff)\b/;

        my @block;
        my $depth = 0;
        while ($idx <= $#lines) {
            my $line = $lines[$idx];
            push @block, $line;
            my $without_comment = _strip_line_comment($line);
            my $begins = () = $without_comment =~ /\bbegin\b/g;
            my $ends = () = $without_comment =~ /\bend\b/g;
            $depth += $begins - $ends;
            last if @block > 1 && $depth <= 0;
            $idx++;
        }

        confess _unsupported('unterminated generated always block')
            if $depth != 0;

        my $header = $block[0];
        if ($header =~ /^\s*always_comb\s+begin\b/) {
            push @processes, {
                kind => 'comb',
                lines => [ _convert_comb_process($decls_by_name, @block) ],
            };
            next;
        }

        if ($header =~ /^\s*always_ff\s*@\(([^)]+)\)\s+begin\b/) {
            push @processes, {
                kind => 'ff',
                lines => [ _convert_ff_process($decls_by_name, $1, @block) ],
            };
            next;
        }

        confess _unsupported("unsupported generated always block header '$header'");
    }

    return @processes;
}

sub _convert_comb_process ($decls_by_name, @block) {
    my @out = ('  process(all) begin');
    my $indent_level = 0;

    for my $raw_line (@block[1 .. $#block - 1]) {
        my $line = _strip_line_comment($raw_line);
        $line =~ s/^\s+|\s+$//g;
        next unless length $line;

        if ($line =~ /^if\s*\((.+)\)\s+begin$/) {
            push @out, _indent(2 + $indent_level) . 'if '
                . _sv_condition_to_vhdl($1, { decls_by_name => $decls_by_name }) . ' then';
            $indent_level++;
            next;
        }

        if ($line =~ /^end$/) {
            $indent_level--;
            confess _unsupported('generated always_comb block closed more if statements than it opened')
                if $indent_level < 0;
            push @out, _indent(2 + $indent_level) . 'end if;';
            next;
        }

        if ($line =~ /^([A-Za-z_][A-Za-z0-9_]*(?:\[[^\]]+\])?)\s*=\s*(.+);$/) {
            push @out, _indent(2 + $indent_level) . _sv_lvalue_to_vhdl($1) . ' <= '
                . _sv_expr_to_vhdl($2, { decls_by_name => $decls_by_name, target_lhs => $1 }) . ';';
            next;
        }

        confess _unsupported("unsupported generated always_comb statement '$line'");
    }

    confess _unsupported('generated always_comb block left an if statement open')
        if $indent_level != 0;

    push @out, '  end process;';
    return @out;
}

sub _convert_ff_process ($decls_by_name, $sensitivity, @block) {
    my @inner = @block[1 .. $#block - 1];
    my $branches = _split_if_else_assignments($decls_by_name, @inner);
    my $reset_condition = $branches->{condition};
    my @reset_assigns = @{$branches->{reset_assigns}};
    my @clock_assigns = @{$branches->{clock_assigns}};

    if ($sensitivity =~ /^\s*posedge\s+([A-Za-z_][A-Za-z0-9_]*)\s*$/) {
        my $clock = $1;
        my @reset_lines = map { '        ' . $_ } @reset_assigns;
        my @clock_lines = map { '        ' . $_ } @clock_assigns;
        return (
            "  process($clock) begin",
            "    if rising_edge($clock) then",
            '      if ' . _sv_condition_to_vhdl($reset_condition, { decls_by_name => $decls_by_name }) . ' then',
            @reset_lines,
            '      else',
            @clock_lines,
            '      end if;',
            '    end if;',
            '  end process;',
        );
    }

    if ($sensitivity =~ /^\s*posedge\s+([A-Za-z_][A-Za-z0-9_]*)\s+or\s+(posedge|negedge)\s+([A-Za-z_][A-Za-z0-9_]*)\s*$/) {
        my ($clock, $edge, $reset) = ($1, $2, $3);
        my $expected_reset = $edge eq 'negedge' ? "$reset = '0'" : "$reset = '1'";
        my $reset_vhdl = _sv_condition_to_vhdl($reset_condition, { decls_by_name => $decls_by_name });
        confess _unsupported("asynchronous reset condition '$reset_condition' does not match sensitivity '$sensitivity'")
            unless $reset_vhdl eq $expected_reset;

        my @reset_lines = map { '      ' . $_ } @reset_assigns;
        my @clock_lines = map { '      ' . $_ } @clock_assigns;
        return (
            "  process($clock, $reset) begin",
            "    if $reset_vhdl then",
            @reset_lines,
            "    elsif rising_edge($clock) then",
            @clock_lines,
            '    end if;',
            '  end process;',
        );
    }

    confess _unsupported("unsupported generated always_ff sensitivity '$sensitivity'");
}

sub _split_if_else_assignments ($decls_by_name, @inner) {
    confess _unsupported('empty generated always_ff body')
        unless @inner;

    my $first = _trim(_strip_line_comment(shift @inner));
    $first =~ /^if\s*\((.+)\)\s+begin$/
        or confess _unsupported("unsupported generated always_ff condition '$first'");
    my $condition = $1;

    my (@reset_raw_lines, @clock_raw_lines);
    my $target = \@reset_raw_lines;
    my $saw_else = 0;
    my $nested_depth = 0;

    for my $raw_line (@inner) {
        my $line = _trim(_strip_line_comment($raw_line));
        next unless length $line;

        if (!$saw_else && $nested_depth == 0 && $line =~ /^end\s+else\s+begin$/) {
            $target = \@clock_raw_lines;
            $saw_else = 1;
            next;
        }

        last if $saw_else && $nested_depth == 0 && $line eq 'end';

        push @{$target}, $raw_line;
        if ($line =~ /^if\s*\(.+\)\s+begin$/) {
            $nested_depth++;
        } elsif ($line eq 'end') {
            $nested_depth--;
            confess _unsupported('generated always_ff nested sequential block closed more if statements than it opened')
                if $nested_depth < 0;
        }
    }

    confess _unsupported('generated always_ff body missing else branch')
        unless $saw_else;
    confess _unsupported('generated always_ff nested sequential block left an if statement open')
        if $nested_depth != 0;

    return {
        condition => $condition,
        reset_assigns => [ _convert_sequential_branch_statements($decls_by_name, @reset_raw_lines) ],
        clock_assigns => [ _convert_sequential_branch_statements($decls_by_name, @clock_raw_lines) ],
    };
}

sub _convert_sequential_branch_statements ($decls_by_name, @raw_lines) {
    my @out;

    for (my $idx = 0; $idx <= $#raw_lines; $idx++) {
        my $line = _trim(_strip_line_comment($raw_lines[$idx]));
        next unless length $line;

        if ($line =~ /^if\s*\((.+)\)\s+begin$/) {
            my $condition = $1;
            my @nested_raw_lines;
            my $nested_depth = 1;
            $idx++;

            while ($idx <= $#raw_lines) {
                my $nested_line = _trim(_strip_line_comment($raw_lines[$idx]));
                if ($nested_line =~ /^end\s+else\s+begin$/) {
                    confess _unsupported("unsupported generated nested always_ff else branch '$nested_line'");
                }

                if ($nested_line =~ /^if\s*\(.+\)\s+begin$/) {
                    $nested_depth++;
                    push @nested_raw_lines, $raw_lines[$idx];
                    $idx++;
                    next;
                }

                if ($nested_line eq 'end') {
                    $nested_depth--;
                    last if $nested_depth == 0;
                    push @nested_raw_lines, $raw_lines[$idx];
                    $idx++;
                    next;
                }

                push @nested_raw_lines, $raw_lines[$idx];
                $idx++;
            }

            confess _unsupported('generated nested always_ff branch left an if statement open')
                if $nested_depth != 0;

            my @nested_lines = _convert_sequential_branch_statements($decls_by_name, @nested_raw_lines);
            push @out, 'if ' . _sv_condition_to_vhdl($condition, { decls_by_name => $decls_by_name }) . ' then';
            push @out, map { '  ' . $_ } @nested_lines;
            push @out, 'end if;';
            next;
        }

        push @out, _convert_sequential_assignment($decls_by_name, $line);
    }

    return @out;
}

sub _convert_sequential_assignment ($decls_by_name, $line) {
    $line =~ /^([A-Za-z_][A-Za-z0-9_]*(?:\[[^\]]+\])?)\s*<=\s*(.+);$/
        or confess _unsupported("unsupported generated always_ff assignment '$line'");
    return _sv_lvalue_to_vhdl($1) . ' <= '
        . _sv_expr_to_vhdl($2, { decls_by_name => $decls_by_name, target_lhs => $1 }) . ';';
}

sub _render_vhdl (%args) {
    my $module_name = $args{module_name};
    my @lines = (
        "-- Flattened Decision Tree FSM: $module_name",
        "-- Generated by FSMGen direct VHDL scaffold",
        'library ieee;',
        'use ieee.std_logic_1164.all;',
        'use ieee.numeric_std.all;',
        '',
        "entity $module_name is",
    );

    if (@{$args{generics}}) {
        push @lines, '  generic (';
        for my $idx (0 .. $#{$args{generics}}) {
            my $generic = $args{generics}->[$idx];
            my $suffix = $idx == $#{$args{generics}} ? '' : ';';
            push @lines, sprintf(
                '    %s : %s := %s%s',
                $generic->{name},
                $generic->{type},
                $generic->{default},
                $suffix,
            );
        }
        push @lines, '  );';
    }

    if (@{$args{ports}}) {
        push @lines, '  port (';
        for my $idx (0 .. $#{$args{ports}}) {
            my $port = $args{ports}->[$idx];
            my $suffix = $idx == $#{$args{ports}} ? '' : ';';
            push @lines, sprintf(
                '    %s : %s %s%s',
                $port->{name},
                $port->{direction},
                _vhdl_type_for_decl($port),
                $suffix,
            );
        }
        push @lines, '  );';
    }

    push @lines,
        "end entity $module_name;",
        '',
        "architecture rtl of $module_name is";

    for my $constant (@{$args{constants}}) {
        push @lines, "  constant $constant->{name} : $constant->{type} := $constant->{value};";
    }
    push @lines, '' if @{$args{constants}} && @{$args{signals}};

    for my $signal (@{$args{signals}}) {
        push @lines, "  signal $signal->{name} : " . _vhdl_type_for_decl($signal) . ';';
    }

    my @reduction_operators = grep { $args{vector_reduction_helpers}{$_} } ('|', '&', '^');
    if (@reduction_operators) {
        push @lines, '' if @{$args{constants}} || @{$args{signals}};
        for my $index (0 .. $#reduction_operators) {
            push @lines, _render_vector_reduction_helper($reduction_operators[$index]);
            push @lines, '' if $index != $#reduction_operators;
        }
    }

    push @lines, 'begin', '';

    for my $assign (@{$args{assigns}}) {
        my $expr = $assign->{expr};
        push @lines, '  ' . $assign->{lhs} . ' <= '
            . _sv_expr_to_vhdl($expr, { decls_by_name => $args{decls_by_name}, target_lhs => $assign->{raw_lhs} }) . ';';
    }

    push @lines, '' if @{$args{assigns}} && @{$args{processes}};
    for my $process (@{$args{processes}}) {
        push @lines, @{$process->{lines}}, '';
    }

    push @lines, 'end architecture rtl;';
    return join("\n", @lines) . "\n";
}

sub _decl_hash (%args) {
    my ($msb, $lsb) = ($args{msb}, $args{lsb});
    return {
        %args,
        scalar => (defined($msb) && defined($lsb)) ? 0 : 1,
        msb => $msb,
        lsb => $lsb,
    };
}

sub _vhdl_type_for_decl ($decl) {
    return $decl->{vhdl_type} if exists($decl->{vhdl_type});
    return 'std_logic' if $decl->{scalar};
    return _vhdl_type($decl->{msb}, $decl->{lsb}, $decl->{signed});
}

sub _vhdl_type ($msb, $lsb, $signed = 0) {
    confess _unsupported("unsupported vector range [$msb:$lsb]")
        unless defined($msb) && defined($lsb) && $msb =~ /^\d+$/ && $lsb =~ /^\d+$/;
    my $type = $signed ? 'signed' : 'std_logic_vector';
    return "$type($msb downto $lsb)";
}

sub _sv_lvalue_to_vhdl ($lhs) {
    my $converted = $lhs;
    $converted =~ s/\[([0-9]+):([0-9]+)\]/($1 downto $2)/g;
    $converted =~ s/\[([0-9]+)\]/($1)/g;
    return $converted;
}

sub _sv_condition_to_vhdl ($expr, $ctx = {}) {
    my $trimmed = _trim($expr);

    return _sv_symbolic_condition_to_vhdl($trimmed, $ctx)
        if _condition_uses_symbolic_declaration($trimmed, $ctx->{decls_by_name} || {});

    if ($trimmed =~ /^!([A-Za-z_][A-Za-z0-9_]*)$/) {
        return "$1 = '0'";
    }

    if ($trimmed =~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
        return "$trimmed = '1'";
    }

    my $converted = _sv_expr_to_vhdl($trimmed, {%$ctx, boolean_context => 1});
    return $converted if $converted =~ /=/ || _has_comparison_operator($trimmed);
    return "($converted) = '1'";
}

# Symbolic vectors retain vector rank even at a selected width of one.
# Keep the static converter's products separate while parsing Boolean operators
# structurally; a textual scalar substitution cannot preserve their precedence.
sub _condition_uses_symbolic_declaration ($expr, $decls) {
    for my $name ($expr =~ /\b([A-Za-z_][A-Za-z0-9_]*)\b/g) {
        return 1 if exists($decls->{$name}) && exists($decls->{$name}{vhdl_type});
    }
    return 0;
}

sub _split_condition_terms ($expr, $operator) {
    my (@terms, $start, $depth);
    $start = $depth = 0;
    for (my $pos = 0; $pos < length($expr); $pos++) {
        my $char = substr($expr, $pos, 1);
        $depth++ if $char eq '(';
        $depth-- if $char eq ')';
        confess _unsupported('unbalanced symbolic condition parentheses') if $depth < 0;
        if (!$depth && substr($expr, $pos, 2) eq $operator) {
            push @terms, substr($expr, $start, $pos - $start);
            $start = $pos + 2;
            $pos++;
        }
    }
    confess _unsupported('unbalanced symbolic condition parentheses') if $depth;
    push @terms, substr($expr, $start);
    return \@terms;
}

sub _sv_symbolic_condition_to_vhdl ($expr, $ctx, $negated = 0) {
    my $trimmed = _trim($expr);
    confess _unsupported('empty symbolic condition operand') unless length($trimmed);
    while (substr($trimmed, 0, 1) eq '(') {
        my $group = _consume_parenthesized($trimmed, 0, 'symbolic condition');
        last unless $group->{next} == length($trimmed);
        # Reduction parentheses belong to the existing reduction consumer.
        last if $group->{content} =~ /\A\s*~?[|&^]/;
        $trimmed = _trim($group->{content});
    }
    confess _unsupported('empty symbolic condition group') unless length($trimmed);
    for my $operator ('||', '&&') {
        my $terms = _split_condition_terms($trimmed, $operator);
        if (@$terms > 1) {
            my $join = (($operator eq '||') != $negated) ? ' or ' : ' and ';
            return join($join, map {
                '(' . _sv_symbolic_condition_to_vhdl($_, $ctx, $negated) . ')'
            } @$terms);
        }
    }
    if ($trimmed =~ /\A!(?!=)\s*(.+)\z/s) {
        my $operand = $1;
        confess _unsupported('negated symbolic condition requires an atom or complete parenthesized operand')
            unless $operand =~ /\A!*\s*[A-Za-z_][A-Za-z0-9_]*\z/
                || substr($operand, 0, 1) eq '(';
        return _sv_symbolic_condition_to_vhdl($operand, $ctx, !$negated);
    }
    my $decls = $ctx->{decls_by_name} || {};
    my $identifier = qr/[A-Za-z_][A-Za-z0-9_]*/;
    if ($trimmed =~ /\A$identifier\z/ && exists($decls->{$trimmed})) {
        my $decl = $decls->{$trimmed};
        my $operand = $trimmed;
        if (!$decl->{scalar}) {
            $operand = "std_logic_vector($operand)" if $decl->{signed};
            $operand = _vector_reduction_helper_name('|') . "($operand)";
        }
        return "$operand = '" . ($negated ? '0' : '1') . "'";
    }
    my $selected = qr/$identifier(?:\[[0-9]+(?::[0-9]+)?\])?/;
    if ($trimmed =~ /\A\(\s*(~?)\s*([|&^])\s*($selected|\(\s*$selected\s*\))\s*\)\z/) {
        my ($complement, $operator, $operand) = ($1, $2, $3);
        if ($operand =~ /($identifier)\[/) {
            my $decl = $decls->{$1};
            confess _unsupported('selected symbolic reduction conditions require separate qualification')
                if $decl && exists($decl->{vhdl_type});
        }
        $complement = $complement ? '' : '~' if $negated;
        return _sv_reduction_to_vhdl($trimmed, $complement, $operator, $operand, $decls, 1);
    }
    if (!_condition_uses_symbolic_declaration($trimmed, $decls)) {
        my $converted = _sv_condition_to_vhdl($trimmed, $ctx);
        return $negated ? "not ($converted)" : $converted;
    }
    my $sized = qr/[0-9]+'[bBdDhH][0-9A-Fa-f_xXzZ]+/;
    my $comparison = qr/(?:==|!=|<=|>=|<|>)/;
    my $qualified = $trimmed =~ /\A(?:$identifier\s*$comparison\s*$sized|$sized\s*$comparison\s*$identifier)\z/
        || $trimmed =~ /\A(?:$identifier\s*(?:==|!=)\s*-?[0-9]+|-?[0-9]+\s*(?:==|!=)\s*$identifier)\z/;
    confess _unsupported("symbolic condition leaf '$trimmed' requires separate expression qualification")
        if !$qualified || $negated;
    return _sv_expr_to_vhdl($trimmed, {%$ctx, boolean_context => 1});
}

sub _sv_expr_to_vhdl ($expr, $ctx = {}) {
    my $trimmed = _trim($expr);
    if (!$ctx->{boolean_context}) {
        my $decls = $ctx->{decls_by_name} || {};
        my $target = _decl_for_lvalue($ctx->{target_lhs}, $decls);
        if (($target && exists($target->{vhdl_type}))
            || _condition_uses_symbolic_declaration($trimmed, $decls)) {
            my $assignment = _sv_symbolic_assignment_to_vhdl($trimmed, $ctx, $target);
            return $assignment if defined $assignment;
        }
    }
    if (!$ctx->{boolean_context} && _has_comparison_operator($trimmed)) {
        my $decl = _decl_for_lvalue($ctx->{target_lhs}, $ctx->{decls_by_name} || {});
        my ($true, $false) = $decl
            ? map { _vhdl_decimal_equality_literal($_, $decl) } (1, 0)
            : ("'1'", "'0'");
        return $true . ' when ' . _sv_condition_to_vhdl($trimmed, $ctx) . ' else ' . $false;
    }
    $trimmed = _sv_reduction_expressions_to_vhdl($trimmed, $ctx);
    confess _unsupported("bitwise complement expression '$expr' is outside the direct VHDL scaffold")
        if $trimmed =~ /~/;
    my $target_decl = _decl_for_lvalue($ctx->{target_lhs}, $ctx->{decls_by_name} || {});
    if ($target_decl && exists($target_decl->{vhdl_type})) {
        if (my $literal = _parse_sized_literal($trimmed)) {
            my $bits = _literal_bits_value($literal, force_vector => 1);
            my $type = $target_decl->{signed} ? 'signed' : 'std_logic_vector';
            # Supported sized literals are unsigned. Resize before applying
            # target signedness so a high source bit never sign-extends.
            return "$type(resize(unsigned'($bits), $target_decl->{name}'length))";
        }
    }
    if ($target_decl && $target_decl->{scalar} && $trimmed =~ /^-?\d+$/) {
        my $low_bit = substr($trimmed, -1) =~ /[13579]\z/ ? 1 : 0;
        return "'$low_bit'";
    }
    if ($target_decl && !$target_decl->{scalar} && $trimmed =~ /^-?\d+$/) {
        my $width = exists($target_decl->{vhdl_type})
            ? "$target_decl->{name}'length" : _decl_width($target_decl);
        return "to_signed($trimmed, $width)" if $target_decl->{signed};
        return "std_logic_vector(to_signed($trimmed, $width))" if $trimmed =~ /^-/;
        return "std_logic_vector(to_unsigned($trimmed, $width))";
    }

    return _simple_arithmetic_to_vhdl($trimmed, $ctx)
        if _has_arithmetic_operator($trimmed);

    $trimmed = _sv_unsigned_vector_comparison_literals_to_vhdl(
        $trimmed,
        $ctx->{decls_by_name} || {},
    );
    $trimmed = _sv_decimal_equality_literals_to_vhdl(
        $trimmed,
        $ctx->{decls_by_name} || {},
    );
    $trimmed = _sv_scalar_condition_operands_to_vhdl(
        $trimmed,
        $ctx->{decls_by_name} || {},
    ) if $ctx->{boolean_context};

    my $converted = $trimmed;
    $converted = _convert_concat_braces($converted);
    $converted =~ s/\b([A-Za-z_][A-Za-z0-9_]*)\[([0-9]+):([0-9]+)\]/$1($2 downto $3)/g;
    $converted =~ s/\b([A-Za-z_][A-Za-z0-9_]*)\[([0-9]+)\]/$1($2)/g;
    $converted =~ s/\b([0-9]+)'([bdhBDH])([0-9A-Fa-f_xXzZ]+)\b/_literal_match_to_vhdl($1, lc($2), $3)/ge;
    $converted =~ s/!=/\/=/g;
    $converted =~ s/==/=/g;
    $converted =~ s/&&/ and /g;
    $converted =~ s/\|\|/ or /g;
    $converted =~ s/\s+\|\s+/ or /g;
    $converted =~ s/(?<![<>=!])!(?!=)/not /g;
    $converted =~ s/\s*&\s*/ and /g;
    $converted =~ s/__FSMGEN_CONCAT__/&/g;
    $converted =~ s/\s+/ /g;
    my $arithmetic_residue = $converted;
    $arithmetic_residue =~ s{/=}{}g;
    confess _unsupported("arithmetic expression '$expr' is outside the direct VHDL scaffold")
        if $arithmetic_residue =~ /[+\-*\/%]/ || $arithmetic_residue =~ /\bmod\b/i;
    return _trim($converted);
}

sub _sv_symbolic_assignment_to_vhdl ($expr, $ctx, $target) {
    confess _unsupported('symbolic assignment requires a resolved target declaration')
        unless $target && defined($ctx->{target_lhs});
    confess _unsupported('selected symbolic target lvalues require separate type-rank integration')
        unless $ctx->{target_lhs} eq $target->{name};
    confess _unsupported('selected symbolic assignment operands require separate shape qualification')
        if $expr =~ /\[/;
    # Existing literal and Boolean-result consumers already use actual target
    # length. Keep those authorities, after checking the complete lvalue.
    return undef if $expr =~ /^-?\d+$/ || _parse_sized_literal($expr)
        || _has_comparison_operator($expr);

    my $atom = $expr;
    while ($atom =~ /^\(/) {
        my $group = _consume_parenthesized($atom, 0, 'symbolic assignment');
        last unless $group->{next} == length($atom);
        $atom = _trim($group->{content});
    }
    my $decls = $ctx->{decls_by_name} || {};
    my ($operand, $scalar);
    if ($atom =~ /^[A-Za-z_][A-Za-z0-9_]*$/ && $decls->{$atom}) {
        my $source = $decls->{$atom};
        $operand = $atom;
        $scalar = $source->{scalar};
        # A one-bit destination takes the low bit regardless of source sign.
        return $scalar ? $operand : "$operand($source->{lsb})" if $target->{scalar};
        # Signed resize preserves the sign bit when narrowing; that is not
        # assignment truncation. Do not route it through numeric-width logic.
        confess _unsupported('signed source in symbolic assignment requires separate shape qualification')
            if !$scalar && $source->{signed};
    }
    elsif ($expr =~ /^\(/ && $atom =~ /^(~?)([|&^])\s*([A-Za-z_][A-Za-z0-9_]*|\(\s*[A-Za-z_][A-Za-z0-9_]*\s*\))$/) {
        $operand = _sv_reduction_to_vhdl($expr, $1, $2, $3, $decls);
        $scalar = 1;
    }
    else {
        confess _unsupported("symbolic assignment expression '$expr' requires separate computed-shape qualification");
    }
    return $operand if $target->{scalar};
    my $unsigned = $scalar ? "unsigned'(0 => $operand)" : "unsigned($operand)";
    my $width = exists($target->{vhdl_type}) ? "$target->{name}'length" : _decl_width({%$target});
    my $type = $target->{signed} ? 'signed' : 'std_logic_vector';
    return "$type(resize($unsigned, $width))";
}

sub _has_comparison_operator ($expr) {
    return $expr =~ /==|!=|<=|>=|(?<![<])<(?![<])|(?<![>])>(?![>])/;
}

# SystemVerilog zero-extends unsigned comparison operands to their common
# width. VHDL's unequal-length vector comparison is lexicographic instead,
# and a one-bit character literal has no vector comparison overload.
sub _sv_unsigned_vector_comparison_literals_to_vhdl ($expr, $decls_by_name) {
    my $identifier = qr/[A-Za-z_][A-Za-z0-9_]*/;
    my $operator = qr/(?:==|!=|<=|>=|<|>)/;
    my $literal = qr/[0-9]+'[bBdDhH][0-9A-Fa-f_]+/;
    my $operands = sub {
        my ($name, $text) = @_;
        my $decl = $decls_by_name->{$name};
        return ($name, $text) unless $decl && !$decl->{scalar};
        confess _unsupported('signed symbolic sized comparison requires separate qualification')
            if exists($decl->{vhdl_type}) && $decl->{signed};
        return ($name, $text) if $decl->{signed};
        my $parsed = _parse_sized_literal($text);
        # Validate the authored literal at its own width before extending it.
        my $bits = _literal_bits_value($parsed, force_vector => 1);
        # numeric_std compares unsigned vectors numerically at their actual
        # lengths. Padding at the selected default would lose that contract.
        return ("unsigned($name)", "unsigned'($bits)")
            if exists($decl->{vhdl_type});
        my $signal_width = _decl_width($decl);
        if ($signal_width >= $parsed->{width}) {
            substr($bits, 1, 0, '0' x ($signal_width - $parsed->{width}));
        } else {
            $name = "std_logic_vector(resize(unsigned($name), $parsed->{width}))";
        }
        return ($name, $bits);
    };
    my $converted = $expr;
    $converted =~ s{
        \b($identifier)\b(\s*$operator\s*)($literal)(?![A-Za-z0-9_])
    }{
        my ($name, $op, $text) = ($1, $2, $3);
        my ($signal, $value) = $operands->($name, $text);
        $signal . $op . $value;
    }gex;
    $converted =~ s{
        (?<![A-Za-z0-9_])($literal)(\s*$operator\s*)\b($identifier)\b
    }{
        my ($text, $op, $name) = ($1, $2, $3);
        my ($signal, $value) = $operands->($name, $text);
        $value . $op . $signal;
    }gex;
    return $converted;
}

sub _sv_decimal_equality_literals_to_vhdl ($expr, $decls_by_name) {
    my $identifier = qr/[A-Za-z_][A-Za-z0-9_]*/;
    my $operands = sub {
        my ($name, $value) = @_;
        my $decl = $decls_by_name->{$name};
        return ($name, $value) unless defined($decl);
        if (exists($decl->{vhdl_type})) {
            confess _unsupported("negative equality literal '$value' is outside the unsigned direct VHDL scaffold")
                if !$decl->{signed} && $value < 0;
            # The numeric scalar overload checks representability instead of
            # truncating an out-of-range literal to the signal's length.
            return ($decl->{signed} ? $name : "unsigned($name)", $value);
        }
        return ($name, _vhdl_decimal_equality_literal($value, $decl));
    };
    my $converted = $expr;
    $converted =~ s{
        \b($identifier)\b
        (\s*(?:==|!=)\s*)
        (-?\d+)(?!\s*')
    }{
        my ($name, $operator, $value) = ($1, $2, $3);
        my ($signal, $literal) = $operands->($name, $value);
        $signal . $operator . $literal;
    }gex;
    $converted =~ s{
        (?<![A-Za-z0-9_'])(-?\d+)
        (\s*(?:==|!=)\s*)
        \b($identifier)\b
    }{
        my ($value, $operator, $name) = ($1, $2, $3);
        my ($signal, $literal) = $operands->($name, $value);
        $literal . $operator . $signal;
    }gex;
    return $converted;
}

sub _vhdl_decimal_equality_literal ($value, $decl) {
    confess _unsupported("scalar equality literal '$value' is outside the direct VHDL scaffold")
        if $decl->{scalar} && $value !~ /\A[01]\z/;
    return "'$value'" if $decl->{scalar};

    my $width = exists($decl->{vhdl_type})
        ? "$decl->{name}'length" : _decl_width($decl);
    return "to_signed($value, $width)" if $decl->{signed};
    confess _unsupported("negative equality literal '$value' is outside the unsigned direct VHDL scaffold")
        if $value < 0;
    return "std_logic_vector(to_unsigned($value, $width))"
        if exists($decl->{vhdl_type});
    return _literal_bits_value({
        width => $width,
        base => 'd',
        digits => $value,
    }, force_vector => 1);
}

sub _sv_scalar_condition_operands_to_vhdl ($expr, $decls_by_name) {
    my $converted = $expr;
    my @scalar = sort { length($b) <=> length($a) || $a cmp $b }
        grep { $decls_by_name->{$_}{scalar} } keys %$decls_by_name;
    for my $name (@scalar) {
        $converted =~ s{!\s*\b\Q$name\E\b}{($name = '0')}g;
        $converted =~ s{\b\Q$name\E\b}{
            my $before = substr($converted, 0, $-[0]);
            my $after = substr($converted, $+[0]);
            $before =~ /(?:==|!=|<=|>=|=|<|>)\s*\z/
                || $after =~ /\A\s*(?:==|!=|<=|>=|=|<|>)/
                ? $name
                : "($name = '1')";
        }gex;
    }
    return $converted;
}

sub _sv_reduction_expressions_to_vhdl ($expr, $ctx) {
    my $decls_by_name = $ctx->{decls_by_name} || {};
    my $identifier = qr/[A-Za-z_][A-Za-z0-9_]*/;
    my $candidate_operand = qr/$identifier(?:\[[0-9]+(?::[0-9]+)?\])?/;
    # Source unary ASTs group the operand as well as the expression. Accept
    # exactly one balanced wrapper around the same declaration-proven operand.
    my $reduction_operand = qr/(?:$candidate_operand|\(\s*$candidate_operand\s*\))/;
    my $converted = $expr;

    $converted =~ s{
        (\(\s*(~?)\s*([|&^])\s*($reduction_operand)\s*\))
    }{
        _sv_reduction_to_vhdl(
            $1,
            $2,
            $3,
            $4,
            $decls_by_name,
            $ctx->{boolean_context} ? 1 : 0,
        )
    }gex;

    if ($converted =~ /\(\s*~?\s*[|&^]/) {
        my $authored = _first_parenthesized_reduction_expression($converted);
        confess _unsupported(
            "unary reduction expression '$authored' is outside the direct VHDL scaffold: "
            . 'operand shape is unresolved or compound; only scalar identifiers and in-range static bit selects are supported'
        );
    }

    return $converted;
}

sub _sv_reduction_to_vhdl ($authored, $complement, $operator, $operand, $decls_by_name, $boolean_context = 0) {
    $operand =~ s/\A\(\s*(.*?)\s*\)\z/$1/;
    my ($base, $select) = $operand =~ /^([A-Za-z_][A-Za-z0-9_]*)(?:\[([^\]]+)\])?$/;
    my $decl = defined($base) ? $decls_by_name->{$base} : undef;
    confess _unsupported(
        "unary reduction expression '$authored' is outside the direct VHDL scaffold: "
        . "operand '$operand' has no resolved declaration; only scalar identifiers and in-range static bit selects are supported"
    ) unless $decl;

    my $operand_vhdl;
    if (!defined $select) {
        if ($decl->{scalar}) {
            $operand_vhdl = $operand;
        }
        else {
            my $helper_name = _vector_reduction_helper_name($operator);
            my $vector_operand = $decl->{signed} ? "std_logic_vector($operand)" : $operand;
            $operand_vhdl = "$helper_name($vector_operand)";
        }
    }
    elsif ($select =~ /^([0-9]+)$/) {
        my $index = $1 + 0;
        confess _unsupported(
            "unary reduction expression '$authored' is outside the direct VHDL scaffold: "
            . "operand '$operand' selects a scalar declaration; only scalar identifiers and in-range static bit selects are supported"
        ) if $decl->{scalar};

        my $low = $decl->{msb} < $decl->{lsb} ? $decl->{msb} : $decl->{lsb};
        my $high = $decl->{msb} > $decl->{lsb} ? $decl->{msb} : $decl->{lsb};
        confess _unsupported(
            "unary reduction expression '$authored' is outside the direct VHDL scaffold: "
            . "operand '$operand' selects outside declared range [$decl->{msb}:$decl->{lsb}]; "
            . 'only scalar identifiers and in-range static bit selects are supported'
        ) if $index < $low || $index > $high;
        $operand_vhdl = _sv_lvalue_to_vhdl($operand);
    }
    else {
        my ($range_msb, $range_lsb) = split /:/, $select, 2;
        my $width = abs($range_msb - $range_lsb) + 1;
        confess _unsupported(
            "unary reduction expression '$authored' is outside the direct VHDL scaffold: "
            . "operand '$operand' is a $width-bit range slice; only scalar identifiers and in-range static bit selects are supported"
        );
    }

    return "($operand_vhdl = '" . ($complement ? '0' : '1') . "')"
        if $boolean_context;
    return $complement ? "(not $operand_vhdl)" : "($operand_vhdl)";
}

sub _required_vector_reduction_helpers ($body, $decls_by_name) {
    my %required;
    # Reserve whole-vector truth before process conversion/rendering so the
    # same collision check covers both explicit and implicit reductions.
    $required{'|'} = 1
        if grep { exists($_->{vhdl_type}) } values %$decls_by_name;
    while ($body =~ /\(\s*~?\s*([|&^])\s*(?:([A-Za-z_][A-Za-z0-9_]*)|\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\))\s*\)/g) {
        my ($operator, $operand) = ($1, $2 // $3);
        my $decl = $decls_by_name->{$operand};
        $required{$operator} = 1
            if $decl && !$decl->{scalar};
    }
    return %required;
}

sub _validate_vector_reduction_helper_names ($required, $module_name, @declaration_groups) {
    my %declared_names = ($module_name => 1);
    for my $group (@declaration_groups) {
        $declared_names{$_->{name}} = 1 for @$group;
    }

    for my $operator (grep { $required->{$_} } ('|', '&', '^')) {
        my $helper_name = _vector_reduction_helper_name($operator);
        confess _unsupported(
            "vector reduction helper name '$helper_name' collides with a generated declaration"
        ) if $declared_names{$helper_name};
    }
}

sub _vector_reduction_helper_name ($operator) {
    return 'fsmgen_direct_vhdl_reduce_or' if $operator eq '|';
    return 'fsmgen_direct_vhdl_reduce_and' if $operator eq '&';
    return 'fsmgen_direct_vhdl_reduce_xor' if $operator eq '^';
    confess _unsupported("unknown unary reduction operator '$operator'");
}

sub _render_vector_reduction_helper ($operator) {
    my $helper_name = _vector_reduction_helper_name($operator);
    my $identity = $operator eq '&' ? '1' : '0';
    my $vhdl_operator = $operator eq '|' ? 'or' : $operator eq '&' ? 'and' : 'xor';
    return (
        "  function $helper_name(value : std_logic_vector) return std_logic is",
        "    variable result : std_logic := '$identity';",
        '  begin',
        "    for index in value'range loop",
        "      result := result $vhdl_operator value(index);",
        '    end loop;',
        '    return result;',
        "  end function $helper_name;",
    );
}

sub _first_parenthesized_reduction_expression ($expr) {
    $expr =~ /\(\s*~?\s*[|&^]/g
        or return $expr;
    my $start = $-[0];
    my $depth = 0;
    for my $index ($start .. length($expr) - 1) {
        my $character = substr($expr, $index, 1);
        $depth++ if $character eq '(';
        if ($character eq ')') {
            $depth--;
            return substr($expr, $start, $index - $start + 1)
                if $depth == 0;
        }
    }
    return substr($expr, $start);
}

sub _has_arithmetic_operator ($expr) {
    return 1 if $expr =~ /[+\-*\/%]/;
    return 1 if $expr =~ /\^/;
    return 1 if $expr =~ /\bmod\b/i;
    return 0;
}

sub _simple_arithmetic_to_vhdl ($expr, $ctx) {
    my $unsupported = sub {
        confess _unsupported("arithmetic expression '$expr' is outside the direct VHDL scaffold");
    };

    my $bounded_wrap = _bounded_unsigned_wrap_arithmetic_to_vhdl($expr, $ctx, $unsupported);
    return $bounded_wrap if defined $bounded_wrap;

    my $signed_negative_add_sub_mul_div_mod = _signed_vector_negative_literal_add_sub_mul_div_mod_to_vhdl($expr, $ctx, $unsupported);
    return $signed_negative_add_sub_mul_div_mod if defined $signed_negative_add_sub_mul_div_mod;

    my $vector_negative_add_sub_mul_div_mod = _non_signed_vector_negative_literal_add_sub_mul_div_mod_to_vhdl($expr, $ctx, $unsupported);
    return $vector_negative_add_sub_mul_div_mod if defined $vector_negative_add_sub_mul_div_mod;

    my $operator;
    my @operators = map { lc($_) eq 'mod' ? '%' : $_ } $expr =~ /(\bmod\b|[+*^\/%]|-)/ig;
    my %operator_seen = map { $_ => 1 } @operators;
    if (!@operators || keys(%operator_seen) != 1) {
        $unsupported->();
    }
    else {
        ($operator) = keys %operator_seen;
    }

    my $separator;
    if ($operator eq '+') {
        $separator = qr/\s*\+\s*/;
    }
    elsif ($operator eq '-') {
        $separator = qr/\s*-\s*/;
    }
    elsif ($operator eq '*') {
        $separator = qr/\s*\*\s*/;
    }
    elsif ($operator eq '^') {
        $separator = qr/\s*\^\s*/;
    }
    elsif ($operator eq '/') {
        $separator = qr/\s*\/\s*/;
    }
    elsif ($operator eq '%') {
        $separator = qr/\s*(?:%|\bmod\b)\s*/i;
    }

    my @operand_names = map { _trim($_) } split $separator, $expr;
    $unsupported->()
        unless @operand_names >= 2;

    my $decls_by_name = $ctx->{decls_by_name} || {};
    my $target_decl = _decl_for_lvalue($ctx->{target_lhs}, $decls_by_name)
        or $unsupported->();

    my $target_width = _decl_width($target_decl);
    if (($operator eq '+' || $operator eq '-' || $operator eq '*') && $target_decl->{scalar}) {
        $unsupported->()
            unless $operator eq '*' || $operator eq '+' || $operator eq '-';
        my $target_signed = $target_decl->{signed} ? 1 : 0;
        my @scalar_operands;
        for my $operand_name (@operand_names) {
            my $operand_decl = $decls_by_name->{$operand_name}
                or $unsupported->();
            $unsupported->()
                unless $operand_decl->{scalar};
            $unsupported->()
                if ($operand_decl->{signed} ? 1 : 0) != $target_signed;
            push @scalar_operands, $operand_name;
        }
        return join($operator eq '*' ? ' and ' : ' xor ', @scalar_operands);
    }

    if (($operator eq '+' || $operator eq '-' || $operator eq '*' || $operator eq '/' || $operator eq '%') && !$target_decl->{scalar} && $target_decl->{signed}) {
        my @signed_operands;
        my $saw_signed_signal_operand = 0;
        for my $operand_name (@operand_names) {
            my $literal_value = _arithmetic_literal_value($operand_name);
            if (defined $literal_value) {
                $unsupported->()
                    unless $operator eq '+'
                    || $operator eq '-'
                    || $operator eq '*'
                    || $operator eq '/'
                    || $operator eq '%';
                push @signed_operands, "to_signed($literal_value, $target_width)";
                next;
            }

            $unsupported->()
                unless $operand_name =~ /^[A-Za-z_][A-Za-z0-9_]*$/;
            my $operand_decl = $decls_by_name->{$operand_name}
                or $unsupported->();
            $unsupported->()
                if $operand_decl->{scalar} || !$operand_decl->{signed} || _decl_width($operand_decl) != $target_width;
            $saw_signed_signal_operand = 1;
            push @signed_operands, $operand_name;
        }
        $unsupported->()
            unless $saw_signed_signal_operand;
        my $signed_operator = $operator eq '%' ? 'mod' : $operator;
        my $signed_expression = join(" $signed_operator ", @signed_operands);
        return "resize($signed_expression, $target_width)"
            if $operator eq '*' || $operator eq '/' || $operator eq '%';
        return $signed_expression;
    }

    my $literal_operand_count = grep { defined _arithmetic_literal_value($_) } @operand_names;
    my @converted_operands;
    for my $operand_name (@operand_names) {
        my $literal_value = _arithmetic_literal_value($operand_name);
        if (defined $literal_value) {
            my $is_scoped_positive_decimal_literal_arithmetic = ($operator eq '*' || $operator eq '/' || $operator eq '%')
                && !$target_decl->{scalar}
                && @operand_names == 2
                && $literal_operand_count == 1
                && @converted_operands == 1
                && $operand_name =~ /^\d+$/
                && $literal_value > 0;
            my $is_scoped_literal_first_positive_decimal_multiply_divide_or_modulo = ($operator eq '*' || $operator eq '/' || $operator eq '%')
                && !$target_decl->{scalar}
                && @operand_names == 2
                && $literal_operand_count == 1
                && @converted_operands == 0
                && $operand_name =~ /^\d+$/
                && $literal_value > 0;
            my $is_scoped_positive_decimal_literal_pair_multiply_divide_or_modulo = ($operator eq '*' || $operator eq '/' || $operator eq '%')
                && !$target_decl->{scalar}
                && @operand_names == 2
                && $literal_operand_count == 2
                && $operand_name =~ /^\d+$/
                && $literal_value > 0;
            $unsupported->()
                unless (($operator eq '+' || $operator eq '-') && !$target_decl->{scalar})
                || $is_scoped_positive_decimal_literal_arithmetic
                || $is_scoped_literal_first_positive_decimal_multiply_divide_or_modulo
                || $is_scoped_positive_decimal_literal_pair_multiply_divide_or_modulo;
            push @converted_operands, "to_unsigned($literal_value, $target_width)";
            next;
        }

        $unsupported->()
            unless $operand_name =~ /^[A-Za-z_][A-Za-z0-9_]*$/;
        my $operand_decl = $decls_by_name->{$operand_name}
            or $unsupported->();
        my $operand_width = _decl_width($operand_decl);
        if ($operator eq '^') {
            $unsupported->()
                if $target_width != $operand_width;
            push @converted_operands, $operand_name;
            next;
        }

        $unsupported->()
            if $target_decl->{scalar} || $operand_decl->{scalar} || $target_width != $operand_width;
        $unsupported->()
            if $operand_decl->{signed};
        push @converted_operands, "unsigned($operand_name)";
    }

    return join(' xor ', @converted_operands)
        if $operator eq '^';

    my $vhdl_operator = $operator eq '%' ? 'mod' : $operator;
    my $converted_expression = join(" $vhdl_operator ", @converted_operands);
    return "std_logic_vector(resize($converted_expression, $target_width))"
        if $operator eq '*' || $operator eq '/' || $operator eq '%';

    return "std_logic_vector($converted_expression)";
}

sub _signed_vector_negative_literal_add_sub_mul_div_mod_to_vhdl ($expr, $ctx, $unsupported) {
    my $identifier = qr/[A-Za-z_][A-Za-z0-9_]*/;
    my ($signal_name, $operator, $literal_value, $literal_first);
    if ($expr =~ /\A\s*($identifier)\s*([+*\/%\-])\s*(-\d+)\s*\z/) {
        ($signal_name, $operator, $literal_value, $literal_first) = ($1, $2, $3, 0);
    }
    elsif ($expr =~ /\A\s*(-\d+)\s*([+*])\s*($identifier)\s*\z/) {
        ($literal_value, $operator, $signal_name, $literal_first) = ($1, $2, $3, 1);
    }
    else {
        return undef;
    }

    my $decls_by_name = $ctx->{decls_by_name} || {};
    my $target_decl = _decl_for_lvalue($ctx->{target_lhs}, $decls_by_name)
        or $unsupported->();
    return undef if $target_decl->{scalar} || !$target_decl->{signed};

    my $operand_decl = $decls_by_name->{$signal_name}
        or $unsupported->();
    my $target_width = _decl_width($target_decl);
    $unsupported->()
        if $operand_decl->{scalar} || !$operand_decl->{signed} || _decl_width($operand_decl) != $target_width;

    my $literal = "to_signed($literal_value, $target_width)";
    my $vhdl_operator = $operator eq '%' ? 'mod' : $operator;
    my $expression = $literal_first ? "$literal $vhdl_operator $signal_name" : "$signal_name $vhdl_operator $literal";
    return "resize($expression, $target_width)"
        if $operator eq '*' || $operator eq '/' || $operator eq '%';
    return $expression;
}

sub _non_signed_vector_negative_literal_add_sub_mul_div_mod_to_vhdl ($expr, $ctx, $unsupported) {
    my $identifier = qr/[A-Za-z_][A-Za-z0-9_]*/;
    my ($signal_name, $operator, $literal_value, $literal_first);
    if ($expr =~ /\A\s*($identifier)\s*([+*\/%\-])\s*(-\d+)\s*\z/) {
        ($signal_name, $operator, $literal_value, $literal_first) = ($1, $2, $3, 0);
    }
    elsif ($expr =~ /\A\s*(-\d+)\s*([+*])\s*($identifier)\s*\z/) {
        ($literal_value, $operator, $signal_name, $literal_first) = ($1, $2, $3, 1);
    }
    else {
        return undef;
    }

    my $decls_by_name = $ctx->{decls_by_name} || {};
    my $target_decl = _decl_for_lvalue($ctx->{target_lhs}, $decls_by_name)
        or $unsupported->();
    return undef if $target_decl->{scalar} || $target_decl->{signed};

    my $operand_decl = $decls_by_name->{$signal_name}
        or $unsupported->();
    my $target_width = _decl_width($target_decl);
    $unsupported->()
        if $operand_decl->{scalar} || $operand_decl->{signed} || _decl_width($operand_decl) != $target_width;

    my $literal = "unsigned(to_signed($literal_value, $target_width))";
    my $vhdl_operator = $operator eq '%' ? 'mod' : $operator;
    my $expression = $literal_first ? "$literal $vhdl_operator unsigned($signal_name)" : "unsigned($signal_name) $vhdl_operator $literal";
    return "std_logic_vector(resize($expression, $target_width))"
        if $operator eq '*' || $operator eq '/' || $operator eq '%';
    return "std_logic_vector($expression)";
}

sub _bounded_unsigned_wrap_arithmetic_to_vhdl ($expr, $ctx, $unsupported) {
    my $decls_by_name = $ctx->{decls_by_name} || {};
    my $target_decl = _decl_for_lvalue($ctx->{target_lhs}, $decls_by_name)
        or return undef;
    return undef if $target_decl->{scalar} || $target_decl->{signed};

    my $target_width = _decl_width($target_decl);
    my $identifier = qr/[A-Za-z_][A-Za-z0-9_]*/;
    my $mod_operator = qr/(?:%|\bmod\b)/i;

    if ($expr =~ /\A($identifier)\s*-\s*\1\s*$mod_operator\s*\(\s*($identifier)\s*\*\s*($identifier)\s*\)\s*\+\s*\2\s*\*\s*\3\z/) {
        my ($base_name, $product_left, $product_right) = ($1, $2, $3);
        my $base_vhdl = _bounded_unsigned_wrap_target_operand_to_vhdl($base_name, $decls_by_name, $target_width, $unsupported);
        my $product_vhdl = _bounded_unsigned_wrap_product_to_vhdl($product_left, $product_right, $decls_by_name, $target_width, $unsupported);
        return "std_logic_vector($base_vhdl - ($base_vhdl mod $product_vhdl) + $product_vhdl)";
    }

    if ($expr =~ /\A($identifier)\s*-\s*\1\s*$mod_operator\s*\(\s*($identifier)\s*\*\s*($identifier)\s*\)\z/) {
        my ($base_name, $product_left, $product_right) = ($1, $2, $3);
        my $base_vhdl = _bounded_unsigned_wrap_target_operand_to_vhdl($base_name, $decls_by_name, $target_width, $unsupported);
        my $product_vhdl = _bounded_unsigned_wrap_product_to_vhdl($product_left, $product_right, $decls_by_name, $target_width, $unsupported);
        return "std_logic_vector($base_vhdl - ($base_vhdl mod $product_vhdl))";
    }

    if ($expr =~ /\A($identifier)\s*\*\s*($identifier)\z/) {
        my ($product_left, $product_right) = ($1, $2);
        return undef
            unless _bounded_unsigned_wrap_product_is_mixed_target_width($product_left, $product_right, $decls_by_name, $target_width);
        my $product_vhdl = _bounded_unsigned_wrap_product_to_vhdl($product_left, $product_right, $decls_by_name, $target_width, $unsupported);
        return "std_logic_vector($product_vhdl)";
    }

    return undef;
}

sub _bounded_unsigned_wrap_product_is_mixed_target_width ($left_name, $right_name, $decls_by_name, $target_width) {
    my $left_decl = $decls_by_name->{$left_name} or return 0;
    my $right_decl = $decls_by_name->{$right_name} or return 0;
    return 0 if $left_decl->{scalar} || $right_decl->{scalar};
    return 0 if $left_decl->{signed} || $right_decl->{signed};

    my $left_width = _decl_width($left_decl);
    my $right_width = _decl_width($right_decl);
    return 1 if $left_width == $target_width && $right_width < $target_width;
    return 1 if $right_width == $target_width && $left_width < $target_width;
    return 0;
}

sub _bounded_unsigned_wrap_product_to_vhdl ($left_name, $right_name, $decls_by_name, $target_width, $unsupported) {
    $unsupported->()
        unless _bounded_unsigned_wrap_product_is_mixed_target_width($left_name, $right_name, $decls_by_name, $target_width);
    my $left_vhdl = _bounded_unsigned_wrap_operand_to_vhdl($left_name, $decls_by_name, $target_width, $unsupported);
    my $right_vhdl = _bounded_unsigned_wrap_operand_to_vhdl($right_name, $decls_by_name, $target_width, $unsupported);
    return "resize($left_vhdl * $right_vhdl, $target_width)";
}

sub _bounded_unsigned_wrap_target_operand_to_vhdl ($operand_name, $decls_by_name, $target_width, $unsupported) {
    my $decl = $decls_by_name->{$operand_name} or $unsupported->();
    $unsupported->()
        if $decl->{scalar} || $decl->{signed} || _decl_width($decl) != $target_width;
    return "unsigned($operand_name)";
}

sub _bounded_unsigned_wrap_operand_to_vhdl ($operand_name, $decls_by_name, $target_width, $unsupported) {
    my $decl = $decls_by_name->{$operand_name} or $unsupported->();
    $unsupported->()
        if $decl->{scalar} || $decl->{signed};

    my $width = _decl_width($decl);
    $unsupported->()
        if $width > $target_width;
    return "unsigned($operand_name)" if $width == $target_width;
    return "resize(unsigned($operand_name), $target_width)";
}

sub _arithmetic_literal_value ($operand) {
    my $trimmed = _trim($operand);
    return $trimmed + 0
        if $trimmed =~ /^\d+$/;

    my $literal = _parse_sized_literal($trimmed);
    return undef unless $literal;
    return _literal_integer_value($literal);
}

sub _decl_for_lvalue ($lhs, $decls_by_name) {
    return undef unless defined $lhs;
    my $name = $lhs;
    $name =~ s/\[.*\]\z//;
    return $decls_by_name->{$name};
}

sub _decl_width ($decl) {
    return 1 if $decl->{scalar};
    return abs($decl->{msb} - $decl->{lsb}) + 1;
}

sub _convert_concat_braces ($expr) {
    my $converted = $expr;
    while ($converted =~ /\{([^{}]+)\}/) {
        my $inner = $1;
        my @parts = map { _trim($_) } split /,/, $inner;
        confess _unsupported("unsupported empty concatenation '{$inner}'")
            unless @parts;
        my $replacement = '(' . join(' __FSMGEN_CONCAT__ ', @parts) . ')';
        $converted =~ s/\{\Q$inner\E\}/$replacement/;
    }
    confess _unsupported("unsupported nested concatenation expression '$expr'")
        if $converted =~ /[{}]/;
    return $converted;
}

sub _parse_sized_literal ($expr) {
    my $trimmed = _trim($expr);
    return undef unless $trimmed =~ /^([0-9]+)'([bdhBDH])([0-9A-Fa-f_xXzZ]+)$/;
    return {
        width => $1 + 0,
        base => lc($2),
        digits => $3,
    };
}

sub _literal_match_to_vhdl ($width, $base, $digits) {
    return _literal_bits_value({
        width => $width + 0,
        base => $base,
        digits => $digits,
    });
}

sub _literal_bits_value ($literal, %opts) {
    my $width = $literal->{width};
    my $bits = _literal_bits($literal);
    confess _unsupported("literal width $width cannot represent '$literal->{digits}'")
        if length($bits) > $width;
    $bits = ('0' x ($width - length($bits))) . $bits;

    return "'$bits'" if $width == 1 && !$opts{force_vector};
    return qq{"$bits"};
}

sub _literal_bits ($literal) {
    my ($base, $digits) = ($literal->{base}, $literal->{digits});
    confess _unsupported("literal '$digits' uses x/z bits outside the direct VHDL scaffold")
        if $digits =~ /[xz]/i;
    $digits =~ s/_//g;

    return $digits if $base eq 'b';

    if ($base eq 'd') {
        confess _unsupported("negative decimal literals are outside the direct VHDL scaffold")
            unless $digits =~ /^\d+$/;
        return sprintf('%b', $digits);
    }

    if ($base eq 'h') {
        my %hex = (
            0 => '0000', 1 => '0001', 2 => '0010', 3 => '0011',
            4 => '0100', 5 => '0101', 6 => '0110', 7 => '0111',
            8 => '1000', 9 => '1001', a => '1010', b => '1011',
            c => '1100', d => '1101', e => '1110', f => '1111',
        );
        my $bits = join '', map { $hex{lc($_)} } split //, $digits;
        $bits =~ s/^0+(?=.)//;
        return $bits;
    }

    confess _unsupported("unsupported literal base '$base'");
}

sub _sv_parameter_default_to_vhdl ($expr) {
    my $converted = _trim($expr);
    my $literal = _parse_sized_literal($converted);
    if ($literal) {
        return {
            type => $literal->{width} == 1 ? 'std_logic' : _vhdl_type($literal->{width} - 1, 0),
            default => _literal_bits_value($literal),
        };
    }

    return {
        type => 'integer',
        default => _sv_integer_expr_to_vhdl($expr),
    };
}

sub _sv_integer_expr_to_vhdl ($expr) {
    my $converted = _trim($expr);
    $converted =~ s/\b([0-9]+)'([bdhBDH])([0-9A-Fa-f_xXzZ]+)\b/_literal_integer_match_to_vhdl($1, lc($2), $3)/ge;
    confess _unsupported("unsupported parameter expression '$expr'")
        unless length $converted;
    confess _unsupported("unsupported parameter expression '$expr'")
        unless $converted =~ /\A[A-Za-z0-9_()\s+\-*\/%]+\z/;

    $converted =~ s/%/ mod /g;
    $converted =~ s/\+\s*-(?=\s*(?:[0-9]|[A-Za-z_]))/- /g;
    $converted =~ s/\s+/ /g;
    return _trim($converted);
}

sub _literal_integer_match_to_vhdl ($width, $base, $digits) {
    return _literal_integer_value({
        width => $width + 0,
        base => $base,
        digits => $digits,
    });
}

sub _literal_integer_value ($literal) {
    my $bits = _literal_bits($literal);
    my $value = 0;
    for my $bit (split //, $bits) {
        $value = ($value * 2) + ($bit eq '1' ? 1 : 0);
    }
    return $value;
}

sub _skip_ws ($text, $pos) {
    $pos++ while $pos < length($text) && substr($text, $pos, 1) =~ /\s/;
    return $pos;
}

sub _consume_parenthesized ($text, $pos, $label) {
    substr($text, $pos, 1) eq '('
        or confess _unsupported("could not locate the generated module $label");

    my $depth = 0;
    my $start = $pos + 1;
    for (my $idx = $pos; $idx < length($text); $idx++) {
        my $char = substr($text, $idx, 1);
        if ($char eq '(') {
            $depth++;
            next;
        }
        if ($char eq ')') {
            $depth--;
            if ($depth == 0) {
                return {
                    content => substr($text, $start, $idx - $start),
                    next => $idx + 1,
                };
            }
            confess _unsupported("generated module $label closed more parentheses than it opened")
                if $depth < 0;
        }
    }

    confess _unsupported("unterminated generated module $label");
}

sub _consume_braced ($text, $pos, $label) {
    substr($text, $pos, 1) eq '{'
        or confess _unsupported("could not locate generated $label");

    my $depth = 0;
    my $start = $pos + 1;
    for (my $idx = $pos; $idx < length($text); $idx++) {
        my $char = substr($text, $idx, 1);
        if ($char eq '{') {
            $depth++;
            next;
        }
        if ($char eq '}') {
            $depth--;
            if ($depth == 0) {
                return {
                    content => substr($text, $start, $idx - $start),
                    next => $idx + 1,
                };
            }
            confess _unsupported("generated $label closed more braces than it opened")
                if $depth < 0;
        }
    }

    confess _unsupported("unterminated generated $label");
}

sub _strip_line_comment ($line) {
    $line =~ s{//.*$}{};
    return $line;
}

sub _trim ($text) {
    $text =~ s/^\s+|\s+$//g;
    return $text;
}

sub _indent ($level) {
    return '  ' x $level;
}

sub _unsupported ($message) {
    return "[VHDL.pm][direct scaffold] Unsupported generated SystemVerilog shape for direct VHDL backend: $message";
}

1;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::VHDL - Bounded direct generated-SystemVerilog conversion

=head1 PRIVATE DECLARATION PREPARATION

C<_parse_direct_declarations> accepts normalized generated SystemVerilog and a
paired C<FSM::Backend::VHDL::DirectDeclarationPlan> result. It checks the physical
module and complete parameter, port, storage, constant and aggregate-type name
membership. Duplicate declarations, port/storage role changes, selected numeric
width or signedness changes, and missing symbolic rows refuse.

Symbolic declarations must match their prepared source range spelling exactly;
equivalent arithmetic text or a selected-default numeric substitute is not the
captured declaration. Returned declaration hashes retain selected numeric
C<msb>, C<lsb>, C<signed> and C<scalar> fields for behavioral conversion, with
separate C<vhdl_range> and C<vhdl_type> strings from the canonical target plan.
A selected width of one retains vector rank. Independent static rows preserve
the existing numeric parser products, including JSON scalar kinds.

C<_vhdl_type_for_decl> consumes the canonical C<vhdl_type> when present.
Whole symbolic target decimal and sized-literal assignments use the actual
target's C<'length>, rather than its selected numeric default. Supported sized
literals are unsigned and zero-extend or truncate through C<resize> before
conversion to target signedness. Selected symbolic literal target lvalues are
withheld pending their separate integration; existing malformed and X/Z literal
refusals remain.

Private symbolic unsigned vector/sized-literal comparisons now use numeric
unsigned overloads at the actual operand lengths, in either operand order.
Decimal equality uses numeric scalar overloads rather than truncating literals
to a selected default. Boolean result literals use the symbolic target's
C<'length>. Independent static products preserve. Negative comparisons keep
the existing arithmetic refusal, and signed symbolic sized comparisons refuse
pending qualification. Generated computed-shape propagation remains pending.

Private symbolic Boolean conditions reduce whole vectors with the existing OR
helper. Structured logical grouping, negation, conjunction and disjunction keep
Boolean precedence; negated vector truth tests zero rather than negating a
Boolean test for one. The symbolic profile reserves the OR helper before the
existing collision check. Qualified comparison/reduction leaves share existing
consumers. Unqualified selected, bitwise, vector-pair, decimal-relational and
negated-comparison leaves refuse. Static condition
products and their helper inventory retain their existing conversion path.

Private symbolic assignments resize unsigned vectors to actual whole-target
lengths, with zero extension and low-bit truncation. Scalar sources and
whole-vector reduction results extend from one bit; scalar destinations take
the low source bit. Target signedness applies after unsigned resizing. Complete
atom grouping preserves the conversion. Selected operands/lvalues, signed-vector
resizing and other computed expressions refuse before numeric selected-default
width logic. Independent static assignment products preserve. Generated internal
shape propagation remains separately owned.

C<generate_vhdl> installs a per-generation actual declaration collector and joins
completed source analysis and normalized identifiers through the paired plan for
symbolic declarations. Width roots select natural generics. Independent fixed
source and public raw-text products keep the existing numeric conversion path.
Symbolic raw text has no source authority and remains unsupported.

Actual register next/q allocations now use their qualified parent shapes through
the paired declaration plan. Whole unsigned transfers and zero resets consume
the actual destination length, including vector rank at a selected width of one.
The source guard checks actual allocation origins and matching parent widths;
missing, foreign, malformed or unproved allocation shapes refuse. Pulse-delay
and intermediate computed shapes remain withheld, including unrelated pipes.
Symbolic FSMs without captured transitions refuse pending state-hold repair.
Compiler-owned fixed state-control references pass the separate complete-family
proof in C<DirectDeclaredWidthSupport>; ordinary source data still requires Core
SignalRef ownership. Bounded source/Core and strict CLI checks do not imply
external compiler, override, runtime or complete transport qualification.

The internal preparation helpers consume a source contract, not attestation of
arbitrary caller-made plans. Returned records retain no mutable plan graph;
inputs remain read-only.

=cut
