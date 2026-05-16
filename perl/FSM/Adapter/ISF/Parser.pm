package FSM::Adapter::ISF::Parser;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::smartmatch);

use Lispish;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Slurp qw(read_file);
use File::Spec;
use FSM::Adapter::ISF::LispishAdapter;
use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Debug;
use FSM::Package::AggregatePathSupport;
use FSM::Package::ImportResolver;
use FSM::Package::IntegerLiteralSupport;
use FSM::Package::Parser;
use FSM::Package::Symbols;
use FSM::SourcePathResolver;
use FSM::Support::ISFResourceCatalog qw(
    isf_resource_arbiter_values
    isf_resource_kind_values
);

my @RESOURCE_ARBITERS = @{isf_resource_arbiter_values()};
my @RESOURCE_KINDS    = @{isf_resource_kind_values()};
my $RESOURCE_ARBITER_SYNTAX = join('|', @RESOURCE_ARBITERS);
my $RESOURCE_KIND_SYNTAX    = join('|', @RESOURCE_KINDS);
my %RESOURCE_ARBITERS = map { $_ => 1 } @RESOURCE_ARBITERS;
my %RESOURCE_KINDS    = map { $_ => 1 } @RESOURCE_KINDS;
my %RULE_ASSIGNMENT_FORBIDDEN_EXPR_HEADS = map { $_ => 1 } qw(
    when switch repeat wait do spawn complete store load set
);
my %RULE_GUARD_SHORTHAND_EXPR_HEADS = map { $_ => 1 } qw(
    & | ! ~ ^ = == != < > <= >= !| ~|
);

# Parses .isf source files into a structured, validated AST.
#
# Pipeline: Lispish raw parse -> LispishAdapter normalization -> validation
#
# Output shape:
#   {
#     actor_name    => "apb_requester",
#     clock         => "clk",
#     reset         => { name => "rst_n", kind => "async", polarity => "active_low" },
#     clock_domains => undef, # or { default => "core", domains => [...] }
#     watchdog      => 65536,
#     interface     => { inputs => [...], outputs => [...] },
#     handshakes    => {}, # deprecated compatibility placeholder; parsed
#                          # handshake clauses are validated then ignored
#     transactions  => [ { name => ..., ports => { inputs => [...], outputs => [...] }, clauses => [...] }, ... ],
#     rules         => [ { name => ..., when => ..., actions => [...] }, ... ],
#     resources     => [ { name => ..., arbiter => ..., kind => ..., users => [...] }, ... ],
#     storage       => [ { kind => "var"|"bank", name => ..., width => ..., depth => ..., signals => [...] }, ... ],
#     constants     => [ { name => ..., value => ... }, ... ],
#     type_declarations => [ ... ],
#     enum_declarations => [ ... ],
#     enum_symbols => { local => ..., packages => ... },
#     crossings     => [ { kind => "event", name => ..., from => ..., to => ..., ready => ... }, ... ],
#     priorities    => [ ... ],
#     imports       => [ ... ], # ISF library imports
#     package_imports => [ ... ], # .fsm package imports used by typed declarations
#     library_uses  => [ ... ],
#   }

sub new($class, %args) {
    return bless {
        debug   => ($args{debug} // 0),
        adapter => FSM::Adapter::ISF::LispishAdapter->new(debug => ($args{debug} // 0)),
    }, $class;
}

sub parse_file($self, $isf_path) {
    fsm_trace_enter("Parser parse_file: $isf_path", 2);
    my $source_text = read_file($isf_path);
    my $result = $self->parse_source($source_text, $isf_path);
    fsm_trace_exit("Parser parse_file completed for $isf_path", 2);
    return $result;
}

sub parse_source($self, $source_text, $source_label) {
    fsm_trace_enter("Parser parse_source: $source_label", 2);

    # Stage 1: raw Lispish parse
    fsm_debug("Raw Lispish parse", 3);
    my $raw = Lispish::multi(\$source_text);
    confess "Error: failed to parse .isf source '$source_label' with Lispish\n"
        unless defined $raw && ref($raw) eq 'ARRAY';
    fsm_debug("Lispish produced " . scalar(@$raw) . " top-level form(s)", 3);

    # Stage 2: normalize through the Lispish adapter
    my $forms = $self->{adapter}->normalize_multi($raw);
    my $actor_ast = _first_form_by_head($forms, 'actor');
    confess "Error: no (actor ...) root found in '$source_label'\n"
        unless $actor_ast;

    # Stage 3: validate and build typed AST
    fsm_debug("Building typed actor AST", 3);
    my $result = $self->_build_actor($actor_ast, $source_label);
    $self->_resolve_library_uses($result, $forms, $source_label);
    $self->_finalize_actor_domain_annotations($result);
    $self->_finalize_actor_crossings($result);
    fsm_debug("Actor '" . $result->{actor_name} . "' parsed: "
        . scalar(@{$result->{transactions}}) . " tx, "
        . scalar(@{$result->{rules}}) . " rules, "
        . scalar(@{$result->{interface}{inputs}}) . " inputs, "
        . scalar(@{$result->{interface}{outputs}}) . " outputs", 2);
    fsm_trace_exit("Parser parse_source completed for $source_label", 2);
    return $result;
}

# Build the typed actor hash from the normalized actor AST.
# The LispishAdapter has already produced canonical [actor, name, body...] form.
sub _build_actor($self, $actor_ast, $source_label) {
    fsm_trace_enter('Parser _build_actor', 3);
    my ($actor_head, $actor_name, @body) = @$actor_ast;

    fsm_debug("Building actor '$actor_name' with " . scalar(@body) . " body clause(s)", 3);

    confess "Error: (actor ...) requires a scalar name\n"
        unless defined($actor_name) && !ref($actor_name) && length($actor_name);

    my $result = {
        actor_name   => $actor_name,
        clock        => undef,
        reset        => undef,
        clock_domains => undef,
        watchdog     => undef,
        interface    => { inputs => [], outputs => [] },
        handshakes   => {},
        transactions => [],
        rules        => [],
        resources    => [],
        storage      => [],
        constants    => [],
        crossings    => [],
        priorities   => [],
        drives       => {},
        phases       => [],
        stages       => [],
        params       => [],
        imports      => [],
        package_imports => [],
        type_declarations => [],
        enum_declarations => [],
        type_symbols => { local => {}, packages => {} },
        enum_symbols => { local => {}, packages => {} },
        package_roots => [],
        uses         => [],
        library_uses => [],
    };
    my %actor_phase_names;
    my %actor_stage_names;
    my %handshake_names;
    my %singleton_actor_clauses;
    my %transaction_names;
    my %rule_names;

    for my $clause (@body) {
        confess "Error: expected list, got " . (ref($clause) || 'scalar') . " in actor body\n"
            unless ref($clause) eq 'ARRAY';

        my $keyword = $clause->[0];
        given ($keyword) {
            when ('clock')     {
                $self->_claim_singleton_actor_clause($actor_name, 'clock', \%singleton_actor_clauses);
                $result->{clock} = $self->_parse_clock($clause);
            }
            when ('clock-domains') {
                $self->_claim_singleton_actor_clause($actor_name, 'clock-domains', \%singleton_actor_clauses);
                $result->{clock_domains} = $self->_parse_clock_domains($clause, $actor_name);
            }
            when ('reset')     {
                $self->_claim_singleton_actor_clause($actor_name, 'reset', \%singleton_actor_clauses);
                $result->{reset} = $self->_parse_reset($clause);
            }
            when ('watchdog')  {
                $self->_claim_singleton_actor_clause($actor_name, 'watchdog', \%singleton_actor_clauses);
                $result->{watchdog} = $self->_parse_watchdog($clause);
            }
            when ('interface') {
                $self->_claim_singleton_actor_clause($actor_name, 'interface', \%singleton_actor_clauses);
                $result->{interface} = $self->_parse_interface($clause);
            }
            when ('params') {
                $self->_claim_singleton_actor_clause($actor_name, 'params', \%singleton_actor_clauses);
                $result->{params} = $self->_parse_actor_params($clause, $actor_name);
            }
            when ('imports') {
                $self->_claim_singleton_actor_clause($actor_name, 'imports', \%singleton_actor_clauses);
                my $imports = $self->_parse_imports($clause, $actor_name);
                $result->{imports} = $imports->{libraries};
                $result->{package_imports} = $imports->{packages};
            }
            when ('types') {
                $self->_claim_singleton_actor_clause($actor_name, 'types', \%singleton_actor_clauses);
                $result->{type_declarations} = $self->_parse_actor_types($clause, $actor_name);
            }
            when ('enums') {
                $self->_claim_singleton_actor_clause($actor_name, 'enums', \%singleton_actor_clauses);
                $result->{enum_declarations} = $self->_parse_actor_enums($clause, $actor_name);
            }
            when ('use')       { push @{$result->{uses}}, $self->_parse_use($clause, $actor_name); }
            when ('handshake') {
                my $handshake_name = $self->_parse_handshake($clause);  # deprecated, validated then ignored
                confess "Error: duplicate handshake '$handshake_name' in actor '$actor_name'; "
                    . "legacy handshakes are ignored compatibility input\n"
                    if $handshake_names{$handshake_name}++;
            }
            when ('transaction') {
                my $transaction = $self->_parse_transaction($clause);
                confess "Error: duplicate transaction '$transaction->{name}' in actor '$actor_name'\n"
                    if $transaction_names{$transaction->{name}}++;
                push @{$result->{transactions}}, $transaction;
            }
            when ('rule')      {
                my $rule = $self->_parse_rule($clause);
                confess "Error: duplicate rule '$rule->{name}' in actor '$actor_name'\n"
                    if $rule_names{$rule->{name}}++;
                push @{$result->{rules}}, $rule;
            }
            when ('resources') {
                $self->_claim_singleton_actor_clause($actor_name, 'resources', \%singleton_actor_clauses);
                $result->{resources} = $self->_parse_resources($clause);
            }
            when ('storage') {
                $self->_claim_singleton_actor_clause($actor_name, 'storage', \%singleton_actor_clauses);
                $result->{storage} = $self->_parse_storage($clause, $actor_name);
            }
            when ('constants') {
                $self->_claim_singleton_actor_clause($actor_name, 'constants', \%singleton_actor_clauses);
                $result->{constants} = $self->_parse_actor_constants($clause, $actor_name);
            }
            when ('crossings') {
                $self->_claim_singleton_actor_clause($actor_name, 'crossings', \%singleton_actor_clauses);
                $result->{crossings} = $self->_parse_crossings($clause, $actor_name);
            }
            when ('priority')  { push @{$result->{priorities}}, $self->_parse_priority($clause); }
            when ('drive')     { $self->_parse_drive_def($clause, $result->{drives}); }
            when ('phase')     {
                my $phase = $self->_parse_phase($clause);
                confess "Error: duplicate actor phase '$phase->{name}'\n"
                    if $actor_phase_names{$phase->{name}}++;
                push @{$result->{phases}}, $phase;
            }
            when ('stage')     {
                my $stage = $self->_parse_stage($clause);
                confess "Error: duplicate actor stage '$stage->{name}'\n"
                    if $actor_stage_names{$stage->{name}}++;
                push @{$result->{stages}}, $stage;
            }
            default {
                confess "Error: unknown actor clause '$keyword' in actor '$actor_name'\n";
            }
        }
    }

    $self->_finalize_actor_symbol_tables($result, $source_label);
    $self->_finalize_actor_constant_values($result);
    $self->_finalize_actor_param_values($result);
    $self->_finalize_actor_type_references($result);
    $self->_validate_actor_aggregate_storage_paths($result);
    $self->_validate_actor_enum_member_value_contexts($result);
    $self->_finalize_actor_clock_domain_timing($result, \%singleton_actor_clauses);
    $self->_validate_rule_trigger_targets($result);
    $self->_validate_rule_priority_targets($result);
    $self->_validate_actor_priority_targets($result);
    $self->_validate_resource_user_targets($result);
    $self->_validate_storage_actor_names($result);
    $self->_validate_actor_constant_names($result);

    fsm_trace_exit('Parser _build_actor completed', 3);
    return $result;
}

# --- Individual clause parsers ---

sub _claim_singleton_actor_clause($self, $actor_name, $keyword, $seen) {
    confess "Error: duplicate actor clause '$keyword' in actor '$actor_name'\n"
        if $seen->{$keyword}++;

    return 1;
}

sub _first_form_by_head($forms, $head) {
    for my $form (@{$forms || []}) {
        next unless ref($form) eq 'ARRAY' && @$form;
        next unless defined($form->[0]) && !ref($form->[0]);
        return $form if $form->[0] eq $head;
    }
    return undef;
}

sub _forms_by_head($forms, $head) {
    return grep {
        ref($_) eq 'ARRAY'
            && @$_
            && defined($_->[0])
            && !ref($_->[0])
            && $_->[0] eq $head
    } @{$forms || []};
}

sub _parse_actor_params($self, $clause, $actor_name) {
    confess "Error: actor '$actor_name' params require '(params (NAME value) ...)'\n"
        unless @$clause >= 2;

    my @params;
    my %seen;
    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' params entries require '(NAME value)'\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 2;
        my ($name, $value) = @$entry;
        confess "Error: actor '$actor_name' parameter names must be scalar HDL identifiers\n"
            unless _is_hdl_identifier($name);
        confess "Error: actor '$actor_name' has duplicate parameter '$name'\n"
            if $seen{$name}++;
        _validate_actor_param_value(
            $value,
            "Error: actor '$actor_name' parameter '$name'",
        );
        push @params, {
            name  => $name,
            value => _clone_isf_value($value),
        };
    }

    return \@params;
}

sub _parse_actor_constants($self, $clause, $actor_name) {
    confess "Error: actor '$actor_name' constants require '(constants (NAME non_negative_integer_literal_or_enum_member) ...)'\n"
        unless @$clause >= 2;

    my @constants;
    my %seen;
    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' constants entries require '(NAME non_negative_integer_literal_or_enum_member)'\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 2;
        my ($name, $value) = @$entry;
        confess "Error: actor '$actor_name' constant names must be scalar HDL identifiers\n"
            unless _is_hdl_identifier($name);
        confess "Error: actor '$actor_name' has duplicate constant '$name'\n"
            if $seen{$name}++;
        confess "Error: actor '$actor_name' constant '$name' requires a non-negative integer literal value or enum member reference\n"
            unless _is_non_negative_integer_literal_value($value)
                || _is_enum_member_reference($value);
        push @constants, {
            name  => $name,
            value => _clone_isf_value($value),
        };
    }

    return \@constants;
}

sub _parse_actor_types($self, $clause, $actor_name) {
    confess "Error: actor '$actor_name' types require '(types (type NAME spec) ...)'\n"
        unless @$clause >= 2;

    my @types;
    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' types entries must use '(type NAME spec)'\n"
            unless ref($entry) eq 'ARRAY' && @$entry >= 3;
        push @types, _clone_isf_value($entry);
    }

    return \@types;
}

sub _parse_actor_enums($self, $clause, $actor_name) {
    confess "Error: actor '$actor_name' enums require '(enums (enum_name (MEMBER value) ...) ...)'\n"
        unless @$clause >= 2;

    my @enums;
    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' enums entries must use '(enum_name (MEMBER value) ...)'\n"
            unless ref($entry) eq 'ARRAY' && @$entry >= 2;
        push @enums, _clone_isf_value($entry);
    }

    return \@enums;
}

sub _finalize_actor_symbol_tables($self, $actor, $source_label) {
    my $actor_name = $actor->{actor_name} // 'unknown';
    my $local_symbols = $self->_resolve_actor_local_symbols($actor);
    my $package_info = $self->_resolve_actor_package_symbols($actor, $source_label);

    $actor->{type_symbols} = {
        local => $local_symbols->{types} || {},
        packages => $package_info->{types},
    };
    $actor->{enum_symbols} = {
        local => $local_symbols->{enums} || {},
        packages => $package_info->{enums},
    };
    $actor->{package_roots} = $package_info->{roots};

    return 1;
}

sub _resolve_actor_local_symbols($self, $actor) {
    my $actor_name = $actor->{actor_name} // 'unknown';
    my $parser = FSM::Package::Parser->new(debug => ($self->{debug} ? 1 : 0));
    my $symbols = FSM::Package::Symbols->new();
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(
        debug => ($self->{debug} ? 1 : 0),
    );
    my $expression_builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(
        debug => ($self->{debug} ? 1 : 0),
        signal_manager => $signal_manager,
    );

    my @type_entries;
    if (@{$actor->{type_declarations} || []}) {
        push @type_entries, @{ $parser->parse_package_types_block(
            "ISF actor '$actor_name'",
            ['+types', _clone_isf_value($actor->{type_declarations})],
            $symbols,
        ) };
    }

    my @enum_entries;
    if (@{$actor->{enum_declarations} || []}) {
        my $package_enum_declarations = _package_enum_declarations_for_parser(
            $actor->{enum_declarations},
        );
        push @enum_entries, @{ $parser->parse_package_enums_block(
            "ISF actor '$actor_name'",
            ['+enums', $package_enum_declarations],
            $symbols,
        ) };
    }

    $parser->resolve_pending_package_types(
        "ISF actor '$actor_name'",
        $symbols,
        $signal_manager,
        \@type_entries,
    );
    $parser->resolve_pending_package_symbols(
        "ISF actor '$actor_name'",
        $symbols,
        $signal_manager,
        $expression_builder,
        [],
        \@enum_entries,
    );

    return $symbols->as_hashref;
}

sub _package_enum_declarations_for_parser {
    my ($enum_declarations) = @_;
    my @entries;

    for my $entry (@{$enum_declarations || []}) {
        next unless ref($entry) eq 'ARRAY' && @$entry >= 2;
        my ($enum_name, @members) = @$entry;
        if (@members == 1
            && ref($members[0]) eq 'ARRAY'
            && ref($members[0][0]) eq 'ARRAY')
        {
            push @entries, [ $enum_name, _clone_isf_value($members[0]) ];
            next;
        }
        push @entries, [ $enum_name, _clone_isf_value(\@members) ];
    }

    return \@entries;
}

sub _resolve_actor_package_symbols($self, $actor, $source_label) {
    my @package_imports = @{$actor->{package_imports} || []};
    return { types => {}, enums => {}, roots => [] } unless @package_imports;

    my $resolved = FSM::Package::ImportResolver->resolve_imports(
        package_imports => \@package_imports,
        source_path_resolver => FSM::SourcePathResolver->new(),
        fsm_file => $source_label,
        owner_label => "ISF actor '$actor->{actor_name}'",
        docs_hint => "Use '(imports (package NAME))' only for existing '.fsm' '?pkg:NAME' package roots.",
        debug_level => ($self->{debug} ? 1 : 0),
    );

    my %package_types;
    my %package_enums;
    my @package_roots;
    for my $package_name (@package_imports) {
        my $spec = $resolved->{$package_name};
        my $symbols = $spec ? $spec->symbols : undef;
        my $symbols_hash = $symbols ? $symbols->as_hashref : {};
        $package_types{$package_name} = $symbols_hash->{types} || {};
        $package_enums{$package_name} = $symbols_hash->{enums} || {};
        push @package_roots, $self->{adapter}->normalize_form($spec->raw_ast)
            if $spec;
    }

    return {
        types => \%package_types,
        enums => \%package_enums,
        roots => \@package_roots,
    };
}

sub _finalize_actor_constant_values($self, $actor) {
    my $actor_name = $actor->{actor_name} // 'unknown';

    for my $constant (@{$actor->{constants} || []}) {
        my $name = $constant->{name};
        my $value = $constant->{value};
        next if _is_non_negative_integer_literal_value($value);
        next unless _is_enum_member_reference($value);

        my $resolved_value = $self->_resolve_actor_enum_member_value($actor, $value);
        confess "Error: actor '$actor_name' constant '$name' references unknown enum member '$value'\n"
            unless defined($resolved_value) && !ref($resolved_value);
        confess "Error: actor '$actor_name' constant '$name' enum member '$value' must resolve to a non-negative integer literal value\n"
            unless _is_non_negative_integer_literal_value($resolved_value);
        $constant->{resolved_value} = _clone_isf_value($resolved_value);
    }

    return 1;
}

sub _finalize_actor_param_values($self, $actor) {
    my $actor_name = $actor->{actor_name} // 'unknown';

    for my $param (@{$actor->{params} || []}) {
        my $name = $param->{name};
        my $value = $param->{value};
        if (ref($value)) {
            my ($resolved_value, $has_enum_leaf) = $self->_resolve_actor_param_enum_leaf_values(
                $actor,
                $value,
                "actor '$actor_name' parameter '$name'",
            );
            $param->{resolved_value} = _clone_isf_value($resolved_value)
                if $has_enum_leaf;
            next;
        }

        next if _is_numeric_or_exact_width_literal($value);
        next unless _is_enum_member_reference($value);

        my ($resolved_value) = $self->_resolve_actor_param_enum_leaf_values(
            $actor,
            $value,
            "actor '$actor_name' parameter '$name'",
        );
        $param->{resolved_value} = _clone_isf_value($resolved_value);
    }

    return 1;
}

sub _resolve_actor_param_enum_leaf_values($self, $actor, $value, $context) {
    if (!ref($value)) {
        return (_clone_isf_value($value), 0)
            unless _is_enum_member_reference($value);

        my $resolved_value = $self->_resolve_actor_enum_member_value($actor, $value);
        confess "Error: $context references unknown enum member '$value'\n"
            unless defined($resolved_value) && !ref($resolved_value);
        confess "Error: $context enum member '$value' must resolve to a non-negative integer literal value\n"
            unless _is_non_negative_integer_literal_value($resolved_value);
        return (_clone_isf_value($resolved_value), 1);
    }

    my @resolved;
    my $has_enum_leaf = 0;
    for my $item (@$value) {
        my ($resolved_item, $item_has_enum_leaf) = $self->_resolve_actor_param_enum_leaf_values(
            $actor,
            $item,
            $context,
        );
        push @resolved, $resolved_item;
        $has_enum_leaf ||= $item_has_enum_leaf;
    }

    return (\@resolved, $has_enum_leaf);
}

sub _resolve_actor_enum_member_value($self, $actor, $member_ref) {
    return undef unless _is_enum_member_reference($member_ref);

    my $symbols = $actor->{enum_symbols} || {};
    if ($member_ref =~ /\A([A-Za-z_]\w*)\.([A-Za-z_]\w*)\.([A-Za-z_]\w*)\z/) {
        my ($package_name, $enum_name, $member_name) = ($1, $2, $3);
        return _clone_isf_value(((($symbols->{packages} || {})->{$package_name} || {})->{$enum_name} || {})->{$member_name});
    }

    if ($member_ref =~ /\A([A-Za-z_]\w*)\.([A-Za-z_]\w*)\z/) {
        my ($enum_name, $member_name) = ($1, $2);
        return _clone_isf_value((($symbols->{local} || {})->{$enum_name} || {})->{$member_name});
    }

    return undef;
}

sub _finalize_actor_type_references($self, $actor) {
    my $actor_name = $actor->{actor_name} // 'unknown';

    for my $direction (qw(inputs outputs)) {
        for my $port (@{$actor->{interface}{$direction} || []}) {
            $self->_resolve_typed_width_entry(
                $actor,
                $port,
                "actor '$actor_name' interface port '$port->{name}'",
            );
        }
    }

    for my $entry (@{$actor->{storage} || []}) {
        $self->_resolve_typed_width_entry(
            $actor,
            $entry,
            "actor '$actor_name' storage '$entry->{name}'",
            allow_aggregate => (($entry->{kind} // '') eq 'var' ? 1 : 0),
        );
        for my $signal (@{$entry->{signals} || []}) {
            $signal->{width} = $entry->{width};
            $signal->{type} = $entry->{type} if exists $entry->{type};
            $signal->{type_spec} = _clone_isf_value($entry->{type_spec})
                if exists $entry->{type_spec};
        }
    }

    for my $tx (@{$actor->{transactions} || []}) {
        for my $direction (qw(inputs outputs)) {
            for my $port (@{($tx->{ports} || {})->{$direction} || []}) {
                $self->_resolve_typed_width_entry(
                    $actor,
                    $port,
                    "transaction '$tx->{name}' port '$port->{name}'",
                );
            }
        }
    }

    return 1;
}

sub _resolve_typed_width_entry($self, $actor, $entry, $context, %options) {
    return 1 unless exists $entry->{type};

    my $type_name = $entry->{type};
    my $type_spec = $self->_resolve_actor_type_spec($actor, $type_name);
    confess "Error: $context references unknown type '$type_name'\n"
        unless ref($type_spec) eq 'HASH';

    my $kind = $type_spec->{kind} || '';
    my $is_scalar = $kind eq 'bit' || $kind eq 'bits';
    my $is_aggregate = _is_aggregate_type_spec($type_spec);
    confess "Error: $context references aggregate type '$type_name'; this ISF slice accepts aggregate type aliases only on actor-owned storage variables\n"
        if $is_aggregate && !$options{allow_aggregate};
    confess "Error: $context references unsupported type '$type_name' of kind '$kind'\n"
        unless $is_scalar || $is_aggregate;
    confess "Error: $context type '$type_name' does not resolve to a positive width\n"
        unless defined($type_spec->{width}) && !ref($type_spec->{width}) && $type_spec->{width} > 0;

    $entry->{width} = 0 + $type_spec->{width};
    $entry->{type_spec} = _clone_isf_value($type_spec);
    return 1;
}

sub _resolve_actor_type_spec($self, $actor, $type_name) {
    return undef unless _is_type_reference($type_name);

    my $symbols = $actor->{type_symbols} || {};
    if ($type_name =~ /\A([A-Za-z_]\w*)\.([A-Za-z_]\w*)\z/) {
        my ($package_name, $local_type_name) = ($1, $2);
        return _clone_isf_value((($symbols->{packages} || {})->{$package_name} || {})->{$local_type_name});
    }

    return _clone_isf_value(($symbols->{local} || {})->{$type_name});
}

sub _validate_actor_aggregate_storage_paths($self, $actor) {
    my %aggregate_roots = map { $_->{name} => _clone_isf_value($_->{type_spec}) }
        grep { _is_aggregate_type_spec($_->{type_spec}) }
        @{$actor->{storage} || []};
    return 1 unless keys %aggregate_roots;

    for my $tx (@{$actor->{transactions} || []}) {
        _validate_transaction_aggregate_storage_paths(
            $tx->{clauses},
            \%aggregate_roots,
            "transaction '$tx->{name}'",
            $actor,
        );
    }

    for my $rule (@{$actor->{rules} || []}) {
        _validate_rule_aggregate_storage_paths($rule, \%aggregate_roots);
    }

    for my $drive_name (sort keys %{$actor->{drives} || {}}) {
        _validate_drive_aggregate_storage_paths(
            $drive_name,
            $actor->{drives}{$drive_name},
            \%aggregate_roots,
        );
    }

    return 1;
}

sub _validate_actor_enum_member_value_contexts($self, $actor) {
    my %aggregate_roots = map { $_->{name} => 1 }
        grep { _is_aggregate_type_spec($_->{type_spec}) }
        @{$actor->{storage} || []};

    for my $tx (@{$actor->{transactions} || []}) {
        _validate_transaction_enum_member_value_contexts(
            $tx->{clauses},
            $actor,
            \%aggregate_roots,
            "transaction '$tx->{name}'",
        );
    }

    for my $rule (@{$actor->{rules} || []}) {
        _validate_rule_enum_member_value_contexts(
            $rule,
            $actor,
            \%aggregate_roots,
        );
    }

    for my $drive_name (sort keys %{$actor->{drives} || {}}) {
        _validate_drive_enum_member_value_contexts(
            $drive_name,
            $actor->{drives}{$drive_name},
            $actor,
            \%aggregate_roots,
        );
    }

    return 1;
}

sub _validate_transaction_enum_member_value_contexts {
    my ($clauses, $actor, $aggregate_roots, $context) = @_;
    return 1 unless ref($clauses) eq 'ARRAY';

    for my $clause (@$clauses) {
        _validate_transaction_enum_member_value_clause($clause, $actor, $aggregate_roots, $context);
    }

    return 1;
}

sub _validate_transaction_enum_member_value_clause {
    my ($clause, $actor, $aggregate_roots, $context) = @_;
    return _reject_enum_member_value_contexts($clause, $actor, $aggregate_roots, $context)
        unless ref($clause) eq 'ARRAY' && @$clause;

    my $head = $clause->[0];
    return _reject_enum_member_value_contexts($clause, $actor, $aggregate_roots, $context)
        unless defined($head) && !ref($head);

    if ($head eq 'params') {
        _validate_transaction_params_enum_member_values($clause, $actor, $aggregate_roots, $context);
        return 1;
    }

    if ($head eq 'set') {
        _reject_enum_member_value_contexts($clause->[1], $actor, $aggregate_roots, "$context set target");
        _validate_transaction_set_enum_member_rhs($clause->[2], $actor, $aggregate_roots, "$context set RHS")
            if @$clause >= 3;
        for my $extra (@{$clause}[3 .. $#$clause]) {
            _reject_enum_member_value_contexts($extra, $actor, $aggregate_roots, "$context set clause");
        }
        return 1;
    }

    if ($head eq 'when' || $head eq 'while' || $head eq 'until') {
        _validate_transaction_condition_enum_member_values(
            $clause->[1],
            $actor,
            $aggregate_roots,
            "$context $head condition",
        );
        _validate_transaction_enum_member_value_contexts(
            [ @{$clause}[2 .. $#$clause] ],
            $actor,
            $aggregate_roots,
            "$context $head body",
        );
        return 1;
    }

    if ($head eq 'repeat') {
        _reject_enum_member_value_contexts($clause->[1], $actor, $aggregate_roots, "$context repeat count");
        _validate_transaction_enum_member_value_contexts(
            [ @{$clause}[2 .. $#$clause] ],
            $actor,
            $aggregate_roots,
            "$context repeat body",
        );
        return 1;
    }

    if ($head eq 'switch') {
        _reject_enum_member_value_contexts($clause->[1], $actor, $aggregate_roots, "$context switch selector");
        for my $branch (@{$clause}[2 .. $#$clause]) {
            next unless ref($branch) eq 'ARRAY' && @$branch;
            _validate_transaction_switch_branch_enum_member_value(
                $branch->[0],
                $actor,
                $aggregate_roots,
                "$context switch branch value",
            );
            _validate_transaction_enum_member_value_contexts(
                [ @{$branch}[1 .. $#$branch] ],
                $actor,
                $aggregate_roots,
                "$context switch branch",
            );
        }
        return 1;
    }

    if ($head eq 'drive') {
        my $drive_name = $clause->[1];
        if (defined($drive_name) && !ref($drive_name) && exists(($actor->{drives} || {})->{$drive_name})) {
            for my $actual (@{$clause}[2 .. $#$clause]) {
                _validate_drive_call_enum_member_actual(
                    $actual,
                    $actor,
                    $aggregate_roots,
                    "$context drive '$drive_name' actual",
                );
            }
            return 1;
        }

        _validate_inline_drive_enum_member_values($clause, $actor, $aggregate_roots, $context);
        return 1;
    }

    if ($head eq 'spawn' || $head eq 'do') {
        _validate_activation_param_enum_member_values(
            $clause,
            $actor,
            $aggregate_roots,
            "$context $head",
        );
        return 1;
    }

    return _reject_enum_member_value_contexts($clause, $actor, $aggregate_roots, $context);
}

sub _validate_transaction_condition_enum_member_values {
    my ($condition, $actor, $aggregate_roots, $context) = @_;

    return _reject_enum_member_value_contexts($condition, $actor, $aggregate_roots, $context)
        unless ref($condition);

    return _validate_transaction_condition_enum_member_expr($condition, $actor, $aggregate_roots, $context);
}

sub _validate_transaction_condition_enum_member_expr {
    my ($expr, $actor, $aggregate_roots, $context) = @_;

    if (!ref($expr)) {
        my $member = _enum_member_value_token($expr, $aggregate_roots);
        _validate_enum_member_value($member, $actor, $context)
            if defined $member;
        return 1;
    }

    return 1 unless ref($expr) eq 'ARRAY';

    for my $index (0 .. $#$expr) {
        my $item = $expr->[$index];
        if ($index == 0 && defined($item) && !ref($item)) {
            my $member = _enum_member_value_token($item, $aggregate_roots);
            confess "Error: $context expression operator references enum member '$member'; this ISF slice accepts enum member references inside transaction condition expressions only as scalar operands\n"
                if defined $member;
            next;
        }
        _validate_transaction_condition_enum_member_expr($item, $actor, $aggregate_roots, $context);
    }

    return 1;
}

sub _validate_transaction_set_enum_member_rhs {
    my ($rhs, $actor, $aggregate_roots, $context) = @_;
    return _validate_transaction_set_rhs_enum_member_values($rhs, $actor, $aggregate_roots, $context);
}

sub _validate_transaction_set_rhs_enum_member_values {
    my ($value, $actor, $aggregate_roots, $context) = @_;
    if (!ref($value)) {
        my $member = _enum_member_value_token($value, $aggregate_roots);
        _validate_enum_member_value($member, $actor, $context)
            if defined $member;
        return 1;
    }

    if (ref($value) eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            my $item = $value->[$index];
            if ($index == 0 && defined($item) && !ref($item)) {
                my $member = _enum_member_value_token($item, $aggregate_roots);
                confess "Error: $context expression operator references enum member '$member'; this ISF slice accepts enum member references inside set RHS expressions only as scalar operands\n"
                    if defined $member;
                next;
            }
            _validate_transaction_set_rhs_enum_member_values($item, $actor, $aggregate_roots, $context);
        }
    }

    return 1;
}

sub _validate_transaction_switch_branch_enum_member_value {
    my ($value, $actor, $aggregate_roots, $context) = @_;
    return _reject_enum_member_value_contexts($value, $actor, $aggregate_roots, $context)
        if ref($value);

    my $member = _enum_member_value_token($value, $aggregate_roots);
    _validate_enum_member_value($member, $actor, $context)
        if defined $member;
    return 1;
}

sub _validate_transaction_params_enum_member_values {
    my ($clause, $actor, $aggregate_roots, $context) = @_;

    for my $entry (@{$clause}[1 .. $#$clause]) {
        return _reject_enum_member_value_contexts($entry, $actor, $aggregate_roots, $context)
            unless ref($entry) eq 'ARRAY' && @$entry == 2;

        my ($name, $value) = @$entry;
        return _reject_enum_member_value_contexts($entry, $actor, $aggregate_roots, $context)
            unless defined($name) && !ref($name) && length($name);

        _validate_transaction_param_enum_member_value(
            $value,
            $actor,
            $aggregate_roots,
            "$context parameter '$name'",
        );
    }

    return 1;
}

sub _validate_transaction_param_enum_member_value {
    my ($value, $actor, $aggregate_roots, $context) = @_;

    if (!ref($value)) {
        my $member = _enum_member_value_token($value, $aggregate_roots);
        _validate_enum_member_value($member, $actor, $context)
            if defined $member;
        return 1;
    }

    return 1 unless ref($value) eq 'ARRAY';

    for my $item (@$value) {
        _validate_transaction_param_enum_member_aggregate_leaf(
            $item,
            $actor,
            $aggregate_roots,
            $context,
        );
    }

    return 1;
}

sub _validate_transaction_param_enum_member_aggregate_leaf {
    my ($value, $actor, $aggregate_roots, $context) = @_;

    if (!ref($value)) {
        my $member = _enum_member_value_token($value, $aggregate_roots);
        _validate_enum_member_value($member, $actor, $context)
            if defined $member;
        return 1;
    }

    if (ref($value) eq 'ARRAY') {
        _validate_transaction_param_enum_member_aggregate_leaf(
            $_,
            $actor,
            $aggregate_roots,
            $context,
        ) for @$value;
    }

    return 1;
}

sub _validate_rule_enum_member_value_contexts {
    my ($rule, $actor, $aggregate_roots) = @_;
    my $rule_name = $rule->{name};

    _validate_rule_guard_enum_member_values(
        $rule->{when},
        $actor,
        $aggregate_roots,
        "rule '$rule_name' guard",
    );

    for my $action (@{$rule->{actions} || []}) {
        if (ref($action) eq 'ARRAY'
            && @$action
            && defined($action->[0])
            && !ref($action->[0])
            && $action->[0] eq 'trigger')
        {
            _validate_activation_param_enum_member_values(
                $action,
                $actor,
                $aggregate_roots,
                "rule '$rule_name' trigger",
            );
            next;
        }

        if (ref($action) eq 'ARRAY'
            && @$action
            && defined($action->[0])
            && !ref($action->[0])
            && $action->[0] eq 'set')
        {
            _reject_enum_member_value_contexts(
                $action->[1],
                $actor,
                $aggregate_roots,
                "rule '$rule_name' set target",
            );
            _validate_rule_assignment_enum_member_rhs(
                $action->[2],
                $actor,
                $aggregate_roots,
                "rule '$rule_name' assignment RHS",
            ) if @$action >= 3;
            next;
        }

        if (ref($action) eq 'ARRAY'
            && @$action
            && defined($action->[0])
            && !ref($action->[0])
            && !exists($RULE_ASSIGNMENT_FORBIDDEN_EXPR_HEADS{$action->[0]})
            && $action->[0] ne 'priority'
            && $action->[0] ne 'store'
            && $action->[0] ne 'load')
        {
            _reject_enum_member_value_contexts(
                $action->[0],
                $actor,
                $aggregate_roots,
                "rule '$rule_name' assignment target",
            );
            _validate_rule_assignment_enum_member_rhs(
                $action->[1],
                $actor,
                $aggregate_roots,
                "rule '$rule_name' assignment RHS",
            ) if @$action >= 2;
            next;
        }

        _reject_enum_member_value_contexts(
            $action,
            $actor,
            $aggregate_roots,
            "rule '$rule_name'",
        );
    }

    return 1;
}

sub _validate_rule_guard_enum_member_values {
    my ($guard, $actor, $aggregate_roots, $context) = @_;
    return 1 unless defined $guard;

    my $condition = $guard;
    $condition = $guard->[1]
        if ref($guard) eq 'ARRAY'
            && @$guard
            && defined($guard->[0])
            && !ref($guard->[0])
            && $guard->[0] eq 'when';

    return _reject_enum_member_value_contexts($condition, $actor, $aggregate_roots, $context)
        unless ref($condition);

    return _validate_rule_guard_enum_member_expr($condition, $actor, $aggregate_roots, $context);
}

sub _validate_rule_guard_enum_member_expr {
    my ($expr, $actor, $aggregate_roots, $context) = @_;

    if (!ref($expr)) {
        my $member = _enum_member_value_token($expr, $aggregate_roots);
        _validate_enum_member_value($member, $actor, $context)
            if defined $member;
        return 1;
    }

    return 1 unless ref($expr) eq 'ARRAY';

    for my $index (0 .. $#$expr) {
        my $item = $expr->[$index];
        if ($index == 0 && defined($item) && !ref($item)) {
            my $member = _enum_member_value_token($item, $aggregate_roots);
            confess "Error: $context expression operator references enum member '$member'; this ISF slice accepts enum member references inside rule guard expressions only as scalar operands\n"
                if defined $member;
            next;
        }
        _validate_rule_guard_enum_member_expr($item, $actor, $aggregate_roots, $context);
    }

    return 1;
}

sub _validate_rule_assignment_enum_member_rhs {
    my ($rhs, $actor, $aggregate_roots, $context) = @_;

    if (!ref($rhs)) {
        my $member = _enum_member_value_token($rhs, $aggregate_roots);
        _validate_enum_member_value($member, $actor, $context)
            if defined $member;
        return 1;
    }

    return 1 unless ref($rhs) eq 'ARRAY';

    for my $index (0 .. $#$rhs) {
        my $item = $rhs->[$index];
        if ($index == 0 && defined($item) && !ref($item)) {
            my $member = _enum_member_value_token($item, $aggregate_roots);
            confess "Error: $context expression operator references enum member '$member'; this ISF slice accepts enum member references inside rule assignment RHS expressions only as scalar operands\n"
                if defined $member;
            next;
        }
        _validate_rule_assignment_enum_member_rhs($item, $actor, $aggregate_roots, $context);
    }

    return 1;
}

sub _validate_activation_param_enum_member_values {
    my ($clause, $actor, $aggregate_roots, $context) = @_;
    return _reject_enum_member_value_contexts($clause, $actor, $aggregate_roots, $context)
        unless ref($clause) eq 'ARRAY' && @$clause;

    my $head = $clause->[0];
    return _reject_enum_member_value_contexts($clause, $actor, $aggregate_roots, $context)
        unless defined($head) && !ref($head);

    my $start = $head eq 'spawn' ? 4 : 2;
    return 1 if $#$clause < $start;

    my $instance = $head eq 'spawn' ? $clause->[3] : $clause->[1];
    for my $structural_value ($clause->[1], ($head eq 'spawn' ? $clause->[3] : ())) {
        _reject_enum_member_value_contexts(
            $structural_value,
            $actor,
            $aggregate_roots,
            $context,
        );
    }
    $instance = 'unknown' if !defined($instance) || ref($instance) || !length($instance);

    for my $subclause (@{$clause}[$start .. $#$clause]) {
        if (ref($subclause) eq 'ARRAY'
            && @$subclause
            && defined($subclause->[0])
            && !ref($subclause->[0])
            && $subclause->[0] eq 'params')
        {
            _validate_activation_params_clause_enum_member_values(
                $subclause,
                $actor,
                $aggregate_roots,
                "$context instance '$instance'",
            );
            next;
        }

        _reject_enum_member_value_contexts($subclause, $actor, $aggregate_roots, $context);
    }

    return 1;
}

sub _validate_activation_params_clause_enum_member_values {
    my ($params_clause, $actor, $aggregate_roots, $context) = @_;

    for my $entry (@{$params_clause}[1 .. $#$params_clause]) {
        return _reject_enum_member_value_contexts($entry, $actor, $aggregate_roots, $context)
            unless ref($entry) eq 'ARRAY' && @$entry == 2;

        my ($name, $value) = @$entry;
        return _reject_enum_member_value_contexts($entry, $actor, $aggregate_roots, $context)
            unless defined($name) && !ref($name) && length($name);

        _validate_activation_param_enum_member_value(
            $value,
            $actor,
            $aggregate_roots,
            "$context parameter '$name'",
        );
    }

    return 1;
}

sub _validate_activation_param_enum_member_value {
    my ($value, $actor, $aggregate_roots, $context) = @_;

    if (!ref($value)) {
        my $member = _enum_member_value_token($value, $aggregate_roots);
        _validate_enum_member_value($member, $actor, $context)
            if defined $member;
        return 1;
    }

    return 1 unless ref($value) eq 'ARRAY';

    for my $item (@$value) {
        _validate_activation_param_enum_member_aggregate_leaf(
            $item,
            $actor,
            $aggregate_roots,
            $context,
        );
    }

    return 1;
}

sub _validate_activation_param_enum_member_aggregate_leaf {
    my ($value, $actor, $aggregate_roots, $context) = @_;

    if (!ref($value)) {
        my $member = _enum_member_value_token($value, $aggregate_roots);
        _validate_enum_member_value($member, $actor, $context)
            if defined $member;
        return 1;
    }

    if (ref($value) eq 'ARRAY') {
        _validate_activation_param_enum_member_aggregate_leaf(
            $_,
            $actor,
            $aggregate_roots,
            $context,
        ) for @$value;
    }

    return 1;
}

sub _validate_drive_enum_member_value_contexts {
    my ($drive_name, $drive, $actor, $aggregate_roots) = @_;
    for my $entry (@{$drive->{body} || []}) {
        next unless ref($entry) eq 'ARRAY' && @$entry;
        _reject_enum_member_value_contexts(
            $entry->[0],
            $actor,
            $aggregate_roots,
            "drive '$drive_name' target",
        );
        _validate_drive_body_enum_member_rhs(
            $entry->[1],
            $actor,
            $aggregate_roots,
            "drive '$drive_name' RHS",
        ) if @$entry >= 2;
        for my $extra (@{$entry}[2 .. $#$entry]) {
            _reject_enum_member_value_contexts($extra, $actor, $aggregate_roots, "drive '$drive_name' body");
        }
    }
    return 1;
}

sub _validate_inline_drive_enum_member_values {
    my ($clause, $actor, $aggregate_roots, $context) = @_;

    my $first_assignment = (ref($clause->[1]) eq 'ARRAY') ? 1 : 2;
    return 1 if $first_assignment > $#$clause;

    for my $entry (@{$clause}[$first_assignment .. $#$clause]) {
        return _reject_enum_member_value_contexts(
            $entry,
            $actor,
            $aggregate_roots,
            "$context inline drive",
        ) unless ref($entry) eq 'ARRAY' && @$entry;

        _reject_enum_member_value_contexts(
            $entry->[0],
            $actor,
            $aggregate_roots,
            "$context inline drive target",
        );
        _validate_inline_drive_enum_member_rhs(
            $entry->[1],
            $actor,
            $aggregate_roots,
            "$context inline drive RHS",
        ) if @$entry >= 2;
        for my $extra (@{$entry}[2 .. $#$entry]) {
            _reject_enum_member_value_contexts(
                $extra,
                $actor,
                $aggregate_roots,
                "$context inline drive assignment",
            );
        }
    }

    return 1;
}

sub _validate_inline_drive_enum_member_rhs {
    my ($rhs, $actor, $aggregate_roots, $context) = @_;
    return _validate_drive_assignment_rhs_enum_member_operands(
        $rhs,
        $actor,
        $aggregate_roots,
        $context,
        'inline drive RHS expressions',
    );
}

sub _validate_drive_body_enum_member_rhs {
    my ($rhs, $actor, $aggregate_roots, $context) = @_;
    return _validate_drive_assignment_rhs_enum_member_operands(
        $rhs,
        $actor,
        $aggregate_roots,
        $context,
        'drive body RHS expressions',
    );
}

sub _validate_drive_assignment_rhs_enum_member_operands {
    my ($rhs, $actor, $aggregate_roots, $context, $accepted_context) = @_;

    if (!ref($rhs)) {
        my $member = _enum_member_value_token($rhs, $aggregate_roots);
        _validate_enum_member_value($member, $actor, $context)
            if defined $member;
        return 1;
    }

    return 1 unless ref($rhs) eq 'ARRAY';

    for my $index (0 .. $#$rhs) {
        my $item = $rhs->[$index];
        if ($index == 0 && defined($item) && !ref($item)) {
            my $member = _enum_member_value_token($item, $aggregate_roots);
            confess "Error: $context expression operator references enum member '$member'; this ISF slice accepts enum member references inside $accepted_context only as scalar operands\n"
                if defined $member;
            next;
        }
        _validate_drive_assignment_rhs_enum_member_operands(
            $item,
            $actor,
            $aggregate_roots,
            $context,
            $accepted_context,
        );
    }

    return 1;
}

sub _validate_drive_call_enum_member_actual {
    my ($actual, $actor, $aggregate_roots, $context) = @_;
    return _validate_drive_call_actual_enum_member_values($actual, $actor, $aggregate_roots, $context);
}

sub _validate_drive_call_actual_enum_member_values {
    my ($value, $actor, $aggregate_roots, $context) = @_;
    if (!ref($value)) {
        my $member = _enum_member_value_token($value, $aggregate_roots);
        _validate_enum_member_value($member, $actor, $context)
            if defined $member;
        return 1;
    }

    if (ref($value) eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            my $item = $value->[$index];
            if ($index == 0 && defined($item) && !ref($item)) {
                my $member = _enum_member_value_token($item, $aggregate_roots);
                confess "Error: $context expression operator references enum member '$member'; this ISF slice accepts enum member references inside drive-call actual expressions only as scalar operands\n"
                    if defined $member;
                next;
            }
            _validate_drive_call_actual_enum_member_values($item, $actor, $aggregate_roots, $context);
        }
    }

    return 1;
}

sub _validate_enum_member_value {
    my ($member, $actor, $context) = @_;
    my $resolved_value = FSM::Adapter::ISF::Parser->_resolve_actor_enum_member_value($actor, $member);
    confess "Error: $context references unknown enum member '$member'\n"
        unless defined($resolved_value) && !ref($resolved_value);
    confess "Error: $context enum member '$member' must resolve to a non-negative integer literal value\n"
        unless _is_non_negative_integer_literal_value($resolved_value);
    return 1;
}

sub _reject_enum_member_value_contexts {
    my ($value, $actor, $aggregate_roots, $context) = @_;
    if (!ref($value)) {
        my $member = _enum_member_value_token($value, $aggregate_roots);
        confess "Error: $context references enum member '$member'; this ISF surface accepts enum member references only as actor constants, actor scalar parameter defaults or aggregate/list parameter default leaves, transaction scalar parameter defaults or aggregate/list parameter default leaves, activation scalar parameter overrides or aggregate/list override leaves, reusable-library use-site parameter override values or leaves, transaction condition expression operands, transaction set RHS scalar values or operands, transaction switch branch values, rule guard expression operands, rule assignment RHS scalar values or operands, drive body RHS scalar values or operands, inline drive assignment RHS scalar values or operands, and drive-call actual scalar values or operands\n"
            if defined $member;
        return 1;
    }

    if (ref($value) eq 'ARRAY') {
        _reject_enum_member_value_contexts($_, $actor, $aggregate_roots, $context) for @$value;
    }

    return 1;
}

sub _enum_member_value_token {
    my ($value, $aggregate_roots) = @_;
    return undef unless _is_enum_member_reference($value);
    return undef if defined _aggregate_storage_path_token($value, $aggregate_roots);
    return $value;
}

sub _validate_transaction_aggregate_storage_paths {
    my ($clauses, $aggregate_roots, $context, $actor) = @_;
    return 1 unless ref($clauses) eq 'ARRAY';

    for my $clause (@$clauses) {
        _validate_transaction_aggregate_storage_clause($clause, $aggregate_roots, $context, $actor);
    }

    return 1;
}

sub _validate_transaction_aggregate_storage_clause {
    my ($clause, $aggregate_roots, $context, $actor) = @_;
    return _reject_aggregate_storage_paths($clause, $aggregate_roots, $context)
        unless ref($clause) eq 'ARRAY' && @$clause;

    my $head = $clause->[0];
    return _reject_aggregate_storage_paths($clause, $aggregate_roots, $context)
        unless defined($head) && !ref($head);

    if ($head eq 'set') {
        _validate_transaction_set_aggregate_storage_target(
            $clause->[1],
            $aggregate_roots,
            "$context set target",
        );
        if (@$clause >= 3) {
            _validate_transaction_set_aggregate_storage_rhs(
                $clause->[2],
                $aggregate_roots,
                "$context set RHS",
            );
        }
        for my $extra (@{$clause}[3 .. $#$clause]) {
            _reject_aggregate_storage_paths($extra, $aggregate_roots, "$context set clause");
        }
        return 1;
    }

    if ($head eq 'when' || $head eq 'while' || $head eq 'until') {
        _validate_transaction_condition_aggregate_storage_paths(
            $clause->[1],
            $aggregate_roots,
            "$context $head condition",
        );
        _validate_transaction_aggregate_storage_paths(
            [ @{$clause}[2 .. $#$clause] ],
            $aggregate_roots,
            "$context $head body",
            $actor,
        );
        return 1;
    }

    if ($head eq 'repeat') {
        _reject_aggregate_storage_paths($clause->[1], $aggregate_roots, "$context repeat count");
        _validate_transaction_aggregate_storage_paths(
            [ @{$clause}[2 .. $#$clause] ],
            $aggregate_roots,
            "$context repeat body",
            $actor,
        );
        return 1;
    }

    if ($head eq 'switch') {
        _reject_aggregate_storage_paths($clause->[1], $aggregate_roots, "$context switch selector");
        for my $branch (@{$clause}[2 .. $#$clause]) {
            next unless ref($branch) eq 'ARRAY' && @$branch;
            _reject_aggregate_storage_paths($branch->[0], $aggregate_roots, "$context switch branch value");
            _validate_transaction_aggregate_storage_paths(
                [ @{$branch}[1 .. $#$branch] ],
                $aggregate_roots,
                "$context switch branch",
                $actor,
            );
        }
        return 1;
    }

    if ($head eq 'drive') {
        my $drive_name = $clause->[1];
        if (defined($drive_name)
            && !ref($drive_name)
            && exists((($actor || {})->{drives} || {})->{$drive_name}))
        {
            for my $actual (@{$clause}[2 .. $#$clause]) {
                _validate_drive_call_actual_aggregate_storage_value(
                    $actual,
                    $aggregate_roots,
                    "$context drive '$drive_name' actual",
                );
            }
            return 1;
        }

        return _reject_aggregate_storage_paths($clause, $aggregate_roots, "$context drive");
    }

    return _reject_aggregate_storage_paths($clause, $aggregate_roots, $context);
}

sub _validate_rule_aggregate_storage_paths {
    my ($rule, $aggregate_roots) = @_;
    my $rule_name = $rule->{name};

    _validate_rule_guard_aggregate_storage_paths(
        $rule->{when},
        $aggregate_roots,
        "rule '$rule_name' guard",
    );

    for my $action (@{$rule->{actions} || []}) {
        if (ref($action) eq 'ARRAY'
            && @$action
            && defined($action->[0])
            && !ref($action->[0])
            && $action->[0] eq 'set')
        {
            _reject_aggregate_storage_paths(
                $action->[1],
                $aggregate_roots,
                "rule '$rule_name' set target",
            );
            _validate_rule_assignment_aggregate_storage_rhs(
                $action->[2],
                $aggregate_roots,
                "rule '$rule_name' assignment RHS",
            ) if @$action >= 3;
            next;
        }

        if (ref($action) eq 'ARRAY'
            && @$action
            && defined($action->[0])
            && !ref($action->[0])
            && !exists($RULE_ASSIGNMENT_FORBIDDEN_EXPR_HEADS{$action->[0]})
            && $action->[0] ne 'priority'
            && $action->[0] ne 'store'
            && $action->[0] ne 'load')
        {
            _reject_aggregate_storage_paths(
                $action->[0],
                $aggregate_roots,
                "rule '$rule_name' assignment target",
            );
            _validate_rule_assignment_aggregate_storage_rhs(
                $action->[1],
                $aggregate_roots,
                "rule '$rule_name' assignment RHS",
            ) if @$action >= 2;
            next;
        }

        _reject_aggregate_storage_paths(
            $action,
            $aggregate_roots,
            "rule '$rule_name'",
        );
    }

    return 1;
}

sub _validate_drive_aggregate_storage_paths {
    my ($drive_name, $drive, $aggregate_roots) = @_;

    for my $entry (@{$drive->{body} || []}) {
        return _reject_aggregate_storage_paths(
            $entry,
            $aggregate_roots,
            "drive '$drive_name'",
        ) unless ref($entry) eq 'ARRAY' && @$entry;

        _reject_aggregate_storage_paths(
            $entry->[0],
            $aggregate_roots,
            "drive '$drive_name' target",
        );
        _validate_drive_body_aggregate_storage_rhs(
            $entry->[1],
            $aggregate_roots,
            "drive '$drive_name' RHS",
        ) if @$entry >= 2;
        for my $extra (@{$entry}[2 .. $#$entry]) {
            _reject_aggregate_storage_paths(
                $extra,
                $aggregate_roots,
                "drive '$drive_name' body",
            );
        }
    }

    return 1;
}

sub _validate_transaction_set_aggregate_storage_rhs {
    my ($rhs, $aggregate_roots, $context) = @_;
    return _validate_transaction_set_rhs_aggregate_storage_reads($rhs, $aggregate_roots, $context);
}

sub _validate_drive_body_aggregate_storage_rhs {
    my ($rhs, $aggregate_roots, $context) = @_;

    if (!ref($rhs)) {
        my $path = _aggregate_storage_path_token($rhs, $aggregate_roots);
        _validate_aggregate_storage_leaf_read_path($path, $aggregate_roots, $context)
            if defined $path;
        return 1;
    }

    return _reject_aggregate_storage_paths($rhs, $aggregate_roots, "$context expression")
        unless ref($rhs) eq 'ARRAY';

    for my $index (0 .. $#$rhs) {
        my $item = $rhs->[$index];
        if ($index == 0 && defined($item) && !ref($item)) {
            my $path = _aggregate_storage_path_token($item, $aggregate_roots);
            confess "Error: $context expression operator references aggregate storage path '$path'; this ISF slice accepts aggregate storage paths inside drive body RHS expressions only as scalar operands\n"
                if defined $path;
            next;
        }
        _validate_drive_body_aggregate_storage_rhs($item, $aggregate_roots, $context);
    }

    return 1;
}

sub _validate_drive_call_actual_aggregate_storage_value {
    my ($actual, $aggregate_roots, $context) = @_;

    if (!ref($actual)) {
        my $path = _aggregate_storage_path_token($actual, $aggregate_roots);
        _validate_aggregate_storage_leaf_read_path($path, $aggregate_roots, $context)
            if defined $path;
        return 1;
    }

    return _reject_aggregate_storage_paths($actual, $aggregate_roots, "$context expression");
}

sub _validate_rule_assignment_aggregate_storage_rhs {
    my ($rhs, $aggregate_roots, $context) = @_;
    if (!ref($rhs)) {
        my $path = _aggregate_storage_path_token($rhs, $aggregate_roots);
        _validate_aggregate_storage_leaf_read_path($path, $aggregate_roots, $context)
            if defined $path;
        return 1;
    }

    if (ref($rhs) eq 'ARRAY') {
        for my $index (0 .. $#$rhs) {
            my $item = $rhs->[$index];
            if ($index == 0 && defined($item) && !ref($item)) {
                my $path = _aggregate_storage_path_token($item, $aggregate_roots);
                confess "Error: $context expression operator references aggregate storage path '$path'; this ISF slice accepts aggregate storage paths inside rule assignment RHS expressions only as scalar operands\n"
                    if defined $path;
                next;
            }
            _validate_rule_assignment_aggregate_storage_rhs($item, $aggregate_roots, $context);
        }
        return 1;
    }

    return _reject_aggregate_storage_paths($rhs, $aggregate_roots, "$context expression");
}

sub _validate_rule_guard_aggregate_storage_paths {
    my ($guard, $aggregate_roots, $context) = @_;
    return 1 unless defined $guard;

    my $condition = $guard;
    $condition = $guard->[1]
        if ref($guard) eq 'ARRAY'
            && @$guard
            && defined($guard->[0])
            && !ref($guard->[0])
            && $guard->[0] eq 'when';

    return _reject_aggregate_storage_paths($condition, $aggregate_roots, $context)
        unless ref($condition);

    return _validate_rule_guard_aggregate_storage_expr($condition, $aggregate_roots, $context);
}

sub _validate_rule_guard_aggregate_storage_expr {
    my ($expr, $aggregate_roots, $context) = @_;

    if (!ref($expr)) {
        my $path = _aggregate_storage_path_token($expr, $aggregate_roots);
        _validate_aggregate_storage_leaf_read_path($path, $aggregate_roots, $context)
            if defined $path;
        return 1;
    }

    return _reject_aggregate_storage_paths($expr, $aggregate_roots, "$context expression")
        unless ref($expr) eq 'ARRAY';

    for my $index (0 .. $#$expr) {
        my $item = $expr->[$index];
        if ($index == 0 && defined($item) && !ref($item)) {
            my $path = _aggregate_storage_path_token($item, $aggregate_roots);
            confess "Error: $context expression operator references aggregate storage path '$path'; this ISF slice accepts aggregate storage paths inside rule guard expressions only as scalar operands\n"
                if defined $path;
            next;
        }
        _validate_rule_guard_aggregate_storage_expr($item, $aggregate_roots, $context);
    }

    return 1;
}

sub _validate_transaction_condition_aggregate_storage_paths {
    my ($condition, $aggregate_roots, $context) = @_;

    return _reject_aggregate_storage_paths($condition, $aggregate_roots, $context)
        unless ref($condition);

    return _validate_transaction_condition_aggregate_storage_expr($condition, $aggregate_roots, $context);
}

sub _validate_transaction_condition_aggregate_storage_expr {
    my ($expr, $aggregate_roots, $context) = @_;

    if (!ref($expr)) {
        my $path = _aggregate_storage_path_token($expr, $aggregate_roots);
        _validate_aggregate_storage_leaf_read_path($path, $aggregate_roots, $context)
            if defined $path;
        return 1;
    }

    return _reject_aggregate_storage_paths($expr, $aggregate_roots, "$context expression")
        unless ref($expr) eq 'ARRAY';

    for my $index (0 .. $#$expr) {
        my $item = $expr->[$index];
        if ($index == 0 && defined($item) && !ref($item)) {
            my $path = _aggregate_storage_path_token($item, $aggregate_roots);
            confess "Error: $context expression operator references aggregate storage path '$path'; this ISF slice accepts aggregate storage paths inside transaction condition expressions only as scalar operands\n"
                if defined $path;
            next;
        }
        _validate_transaction_condition_aggregate_storage_expr($item, $aggregate_roots, $context);
    }

    return 1;
}

sub _validate_transaction_set_rhs_aggregate_storage_reads {
    my ($value, $aggregate_roots, $context) = @_;
    if (!ref($value)) {
        my $path = _aggregate_storage_path_token($value, $aggregate_roots);
        _validate_aggregate_storage_leaf_read_path($path, $aggregate_roots, $context)
            if defined $path;
        return 1;
    }

    if (ref($value) eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            my $item = $value->[$index];
            if ($index == 0 && defined($item) && !ref($item)) {
                my $path = _aggregate_storage_path_token($item, $aggregate_roots);
                confess "Error: $context expression operator references aggregate storage path '$path'; this ISF slice accepts aggregate storage paths inside set RHS expressions only as scalar operands\n"
                    if defined $path;
                next;
            }
            _validate_transaction_set_rhs_aggregate_storage_reads($item, $aggregate_roots, $context);
        }
    }

    return 1;
}

sub _validate_transaction_set_aggregate_storage_target {
    my ($target, $aggregate_roots, $context) = @_;
    if (!ref($target)) {
        my $path = _aggregate_storage_path_token($target, $aggregate_roots);
        _validate_aggregate_storage_leaf_write_path($path, $aggregate_roots, $context)
            if defined $path;
        return 1;
    }

    return _reject_aggregate_storage_paths($target, $aggregate_roots, $context);
}

sub _validate_aggregate_storage_leaf_read_path {
    return _validate_aggregate_storage_scalar_leaf_path(@_, 'read');
}

sub _validate_aggregate_storage_leaf_write_path {
    return _validate_aggregate_storage_scalar_leaf_path(@_, 'write');
}

sub _validate_aggregate_storage_scalar_leaf_path {
    my ($path, $aggregate_roots, $context, $access) = @_;
    $access //= 'read';
    my $access_noun = $access eq 'write' ? 'writes' : 'reads';
    my ($root, $path_text) = _aggregate_storage_path_parts($path, $aggregate_roots);
    confess "Error: $context references aggregate storage path '$path'; this ISF slice accepts aggregate storage leaf $access_noun only from declared actor-owned storage variables\n"
        unless defined($root) && defined($path_text);

    my $result = FSM::Package::AggregatePathSupport->resolve(
        root_type_spec => $aggregate_roots->{$root},
        path_text => $path_text,
    );
    confess "Error: $context references invalid aggregate storage path '$path': "
        . _aggregate_storage_path_error_summary($result) . "\n"
        unless $result->{ok};

    my $type_spec = $result->{type_spec};
    confess "Error: $context references aggregate storage path '$path' that resolves to aggregate kind '$type_spec->{kind}'; this ISF slice accepts only scalar aggregate leaf $access_noun\n"
        if _is_aggregate_type_spec($type_spec);

    return 1;
}

sub _reject_aggregate_storage_paths {
    my ($value, $aggregate_roots, $context) = @_;
    if (!ref($value)) {
        my $path = _aggregate_storage_path_token($value, $aggregate_roots);
        confess "Error: $context references aggregate storage path '$path'; this ISF slice accepts aggregate storage paths only as direct transaction set RHS scalar leaf reads, direct transaction set target scalar leaf writes, transaction condition expression scalar operands, rule assignment RHS scalar values or operands, rule guard expression scalar operands, drive body RHS scalar values or operands, or drive-call actual scalar values\n"
            if defined $path;
        return 1;
    }

    if (ref($value) eq 'ARRAY') {
        _reject_aggregate_storage_paths($_, $aggregate_roots, $context) for @$value;
    }

    return 1;
}

sub _aggregate_storage_path_token {
    my ($value, $aggregate_roots) = @_;
    return undef unless defined($value) && !ref($value);
    for my $root (sort { length($b) <=> length($a) } keys %{$aggregate_roots || {}}) {
        return $value if $value =~ /\A\Q$root\E(?:\.|\[)/;
    }
    return undef;
}

sub _aggregate_storage_path_parts {
    my ($value, $aggregate_roots) = @_;
    return unless defined($value) && !ref($value);
    for my $root (sort { length($b) <=> length($a) } keys %{$aggregate_roots || {}}) {
        return ($root, $1) if $value =~ /\A\Q$root\E((?:\.|\[).*)\z/;
    }
    return;
}

sub _aggregate_storage_path_error_summary {
    my ($error) = @_;
    my $code = ref($error) eq 'HASH' ? ($error->{code} || 'unknown') : 'unknown';

    return "member access '." . ($error->{member_name} // '?') . "' is only valid on record values; current path type is '"
        . ($error->{current_type_label} || 'unknown') . "'"
        if $code eq 'member_on_non_record';

    return "record member '" . ($error->{member_name} // '?') . "' is not declared; known members: "
        . join(', ', @{ $error->{known_members} || [] })
        if $code eq 'unknown_member';

    return "list ranges are not supported; select one item with '[N]'"
        if $code eq 'list_range_not_supported';

    return "list index '" . ($error->{index} // '?') . "' is outside the declared item range 0.."
        . ($error->{max_index} // -1)
        if $code eq 'list_index_out_of_range';

    return "scalar slice [" . ($error->{high} // '?') . ':' . ($error->{low} // '?')
        . "] exceeds resolved scalar width '" . ($error->{scalar_width} // '?') . "'"
        if $code eq 'scalar_slice_out_of_range';

    return "scalar index '" . ($error->{index} // '?')
        . "' exceeds resolved scalar width '" . ($error->{scalar_width} // '?') . "'"
        if $code eq 'scalar_index_out_of_range';

    return "index access is valid only on list and scalar bit-vector values; current path type is '"
        . ($error->{current_type_label} || 'unknown') . "'"
        if $code eq 'index_on_non_indexable';

    return "could not parse remaining path '" . ($error->{remaining} || '') . "'"
        if $code eq 'parse_error';

    return "resolved aggregate leaf has no positive packed width"
        if $code eq 'missing_leaf_width';

    return "aggregate path resolution failed with code '$code'";
}

sub _validate_actor_constant_names($self, $actor) {
    my $actor_name = $actor->{actor_name} // 'unknown';
    my %params = map { $_->{name} => 1 } @{$actor->{params} || []};
    for my $constant (@{$actor->{constants} || []}) {
        my $name = $constant->{name};
        confess "Error: actor '$actor_name' constant '$name' conflicts with actor parameter '$name'\n"
            if $params{$name};
    }

    return 1;
}

sub _finalize_actor_domain_annotations($self, $actor) {
    my $actor_name = $actor->{actor_name} // 'unknown';
    my $clock_domains = $actor->{clock_domains};
    my $has_clock_domains = ref($clock_domains) eq 'HASH';
    my %declared_domains = $has_clock_domains
        ? map { $_->{name} => 1 } @{$clock_domains->{domains} || []}
        : (default => 1);
    my $default_domain = $has_clock_domains
        ? $clock_domains->{default}
        : 'default';

    for my $direction (qw(inputs outputs)) {
        for my $port (@{$actor->{interface}{$direction} || []}) {
            $self->_finalize_domain_annotation(
                $port,
                $default_domain,
                \%declared_domains,
                "actor '$actor_name' interface port '$port->{name}'",
                $has_clock_domains,
            );
        }
    }

    for my $entry (@{$actor->{storage} || []}) {
        $self->_finalize_domain_annotation(
            $entry,
            $default_domain,
            \%declared_domains,
            "actor '$actor_name' storage '$entry->{name}'",
            $has_clock_domains,
        );
        if (exists $entry->{domain}) {
            for my $signal (@{$entry->{signals} || []}) {
                $signal->{domain} = $entry->{domain};
            }
        }
    }

    for my $tx (@{$actor->{transactions} || []}) {
        $self->_finalize_domain_annotation(
            $tx,
            $default_domain,
            \%declared_domains,
            "actor '$actor_name' transaction '$tx->{name}'",
            $has_clock_domains,
        );
    }

    for my $rule (@{$actor->{rules} || []}) {
        $self->_finalize_domain_annotation(
            $rule,
            $default_domain,
            \%declared_domains,
            "actor '$actor_name' rule '$rule->{name}'",
            $has_clock_domains,
        );
    }

    for my $use (@{$actor->{uses} || []}) {
        $self->_finalize_domain_annotation(
            $use,
            $default_domain,
            \%declared_domains,
            "actor '$actor_name' use '$use->{instance}'",
            $has_clock_domains,
        );
    }

    for my $use (@{$actor->{library_uses} || []}) {
        $self->_finalize_domain_annotation(
            $use,
            $default_domain,
            \%declared_domains,
            "actor '$actor_name' library use '$use->{instance}'",
            $has_clock_domains,
        );
    }

    return 1;
}

sub _finalize_actor_crossings($self, $actor) {
    my $actor_name = $actor->{actor_name} // 'unknown';
    return 1 unless @{$actor->{crossings} || []};

    confess "Error: actor '$actor_name' crossings require '(clock-domains ...)'\n"
        unless ref($actor->{clock_domains}) eq 'HASH';

    my %declared_domains = map {
        $_->{name} => 1
    } @{$actor->{clock_domains}{domains} || []};

    for my $crossing (@{$actor->{crossings} || []}) {
        my $name = $crossing->{name};
        my $from = $crossing->{from};
        my $to = $crossing->{to};

        confess "Error: actor '$actor_name' crossing event '$name' source domain '$from->{domain}' is not declared\n"
            unless $declared_domains{$from->{domain}};
        confess "Error: actor '$actor_name' crossing event '$name' destination domain '$to->{domain}' is not declared\n"
            unless $declared_domains{$to->{domain}};
        confess "Error: actor '$actor_name' crossing event '$name' source and destination domains must differ\n"
            if $from->{domain} eq $to->{domain};

        $crossing->{ready}{domain} = $from->{domain};
    }

    return 1;
}

sub _finalize_domain_annotation($self, $entry, $default_domain, $declared_domains, $context, $materialize_default) {
    confess "Error: $context uses unknown clock domain '$entry->{domain}'\n"
        if exists($entry->{domain}) && !$declared_domains->{$entry->{domain}};

    if (!exists($entry->{domain}) && $materialize_default) {
        $entry->{domain} = $default_domain;
    }

    return 1;
}

sub _parse_imports($self, $clause, $actor_name) {
    my @library_imports;
    my @package_imports;
    my %seen_namespace;

    confess "Error: actor '$actor_name' imports require '(imports (library name [as alias]) ... (package NAME) ...)'\n"
        unless @$clause >= 2;

    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' import entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry;
        my $kind = $entry->[0];
        confess "Error: actor '$actor_name' import entry kind must be 'library' or 'package'\n"
            unless defined($kind) && !ref($kind) && ($kind eq 'library' || $kind eq 'package');

        if ($kind eq 'package') {
            confess "Error: actor '$actor_name' package imports require '(package NAME)'\n"
                unless @$entry == 2
                    && defined($entry->[1])
                    && !ref($entry->[1])
                    && _is_hdl_identifier($entry->[1]);
            my $package = $entry->[1];
            confess "Error: actor '$actor_name' has duplicate import namespace '$package'\n"
                if $seen_namespace{$package}++;
            push @package_imports, $package;
            next;
        }

        confess "Error: actor '$actor_name' import entries require '(library name [as alias])'\n"
            unless (@$entry == 2 || @$entry == 4)
                && defined($entry->[1])
                && !ref($entry->[1])
                && _is_library_namespace($entry->[1]);

        my $library = $entry->[1];
        my $alias = $library;
        if (@$entry == 4) {
            confess "Error: actor '$actor_name' import for library '$library' requires '(library $library as alias)'\n"
                unless defined($entry->[2])
                    && !ref($entry->[2])
                    && $entry->[2] eq 'as'
                    && defined($entry->[3])
                    && !ref($entry->[3])
                    && _is_hdl_identifier($entry->[3]);
            $alias = $entry->[3];
        }

        confess "Error: actor '$actor_name' has duplicate import namespace '$alias'\n"
            if $seen_namespace{$alias}++;

        push @library_imports, {
            kind    => 'library',
            library => $library,
            alias   => $alias,
        };
    }

    return {
        libraries => \@library_imports,
        packages  => \@package_imports,
    };
}

sub _parse_use($self, $clause, $actor_name) {
    confess "Error: actor '$actor_name' use requires '(use alias.actor as instance [(domain name)] [(params ...)] (bind ...))'\n"
        unless @$clause >= 4
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1])
            && defined($clause->[2])
            && !ref($clause->[2])
            && $clause->[2] eq 'as'
            && defined($clause->[3])
            && !ref($clause->[3])
            && _is_hdl_identifier($clause->[3]);

    my %seen_subclause;
    my @params;
    my @bindings;
    my $domain;
    my $saw_bind;

    for my $subclause (@{$clause}[4 .. $#$clause]) {
        confess "Error: actor '$actor_name' use '$clause->[3]' subclauses must be list forms\n"
            unless ref($subclause) eq 'ARRAY' && @$subclause;
        my $head = $subclause->[0];
        confess "Error: actor '$actor_name' use '$clause->[3]' subclause heads must be scalar\n"
            unless defined($head) && !ref($head) && length($head);
        confess "Error: actor '$actor_name' use '$clause->[3]' has duplicate '$head' subclause\n"
            if $seen_subclause{$head}++;

        if ($head eq 'params') {
            @params = @{$self->_parse_use_params($subclause, $actor_name, $clause->[3])};
            next;
        }
        if ($head eq 'domain') {
            $domain = _parse_domain_option(
                $subclause,
                "Error: actor '$actor_name' use '$clause->[3]' domain",
            );
            next;
        }
        if ($head eq 'bind') {
            $saw_bind = 1;
            @bindings = @{$self->_parse_use_bind($subclause, $actor_name, $clause->[3])};
            next;
        }

        confess "Error: actor '$actor_name' use '$clause->[3]' has unsupported subclause '$head'\n";
    }

    confess "Error: actor '$actor_name' use '$clause->[3]' requires a '(bind ...)' subclause\n"
        unless $saw_bind;

    return {
        target              => $clause->[1],
        instance            => $clause->[3],
        parameter_overrides => \@params,
        bindings            => \@bindings,
        (defined($domain) ? (domain => $domain) : ()),
    };
}

sub _parse_use_params($self, $clause, $actor_name, $instance) {
    confess "Error: actor '$actor_name' use '$instance' params require '(params (NAME value) ...)'\n"
        unless @$clause >= 2;

    my @params;
    my %seen;
    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' use '$instance' params entries require '(NAME value)'\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 2;
        my ($name, $value) = @$entry;
        confess "Error: actor '$actor_name' use '$instance' parameter override names must be scalar HDL identifiers\n"
            unless _is_hdl_identifier($name);
        confess "Error: actor '$actor_name' use '$instance' has duplicate parameter override '$name'\n"
            if $seen{$name}++;
        _validate_isf_param_value(
            $value,
            "Error: actor '$actor_name' use '$instance' parameter '$name'",
        );
        push @params, {
            name  => $name,
            value => _clone_isf_value($value),
        };
    }

    return \@params;
}

sub _parse_use_bind($self, $clause, $actor_name, $instance) {
    confess "Error: actor '$actor_name' use '$instance' bind requires binding entries\n"
        unless @$clause >= 2;

    my @bindings;
    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' use '$instance' bind entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry;
        my $role = $entry->[0];
        confess "Error: actor '$actor_name' use '$instance' bind entry roles must be scalar\n"
            unless defined($role) && !ref($role) && length($role);

        if ($role eq 'clock' || $role eq 'reset') {
            confess "Error: actor '$actor_name' use '$instance' $role binding requires '($role parent_signal)'\n"
                unless @$entry == 2
                    && defined($entry->[1])
                    && !ref($entry->[1])
                    && length($entry->[1]);
            push @bindings, {
                role        => $role,
                parent_name => $entry->[1],
            };
            next;
        }

        if ($role eq 'input' || $role eq 'output') {
            confess "Error: actor '$actor_name' use '$instance' $role binding requires '($role library_port parent_signal)'\n"
                unless @$entry == 3
                    && defined($entry->[1])
                    && !ref($entry->[1])
                    && length($entry->[1])
                    && defined($entry->[2])
                    && !ref($entry->[2])
                    && length($entry->[2]);
            push @bindings, {
                role         => $role,
                library_name => $entry->[1],
                parent_name  => $entry->[2],
            };
            next;
        }

        confess "Error: actor '$actor_name' use '$instance' has unsupported bind role '$role'\n";
    }

    return \@bindings;
}

sub _resolve_library_uses($self, $actor, $forms, $source_label) {
    return 1 unless @{$actor->{uses} || []};

    confess "Error: actor '$actor->{actor_name}' uses imported libraries but has no '(imports ...)' clause\n"
        unless @{$actor->{imports} || []};

    my %same_source_libraries = $self->_same_source_libraries($forms, $source_label);
    my %imports_by_alias;
    my %resolved_by_alias;

    for my $import (@{$actor->{imports}}) {
        my $alias = $import->{alias};
        my $library = $import->{library};
        confess "Error: actor '$actor->{actor_name}' has duplicate library import alias '$alias'\n"
            if $imports_by_alias{$alias}++;
        $resolved_by_alias{$alias} = $self->_resolve_library(
            $library,
            \%same_source_libraries,
            $source_label,
            {},
        );
    }

    my %seen_instance;
    my @resolved_uses;
    for my $use (@{$actor->{uses}}) {
        my $instance = $use->{instance};
        confess "Error: actor '$actor->{actor_name}' has duplicate library use instance '$instance'\n"
            if $seen_instance{$instance}++;

        my ($alias, $export) = _split_use_target($use->{target}, \%resolved_by_alias);
        confess "Error: actor '$actor->{actor_name}' use '$instance' target '$use->{target}' does not match any imported library alias\n"
            unless defined $alias;

        my $library = $resolved_by_alias{$alias};
        my $exported_actor = $library->{exports}{actor}{$export};
        confess "Error: actor '$actor->{actor_name}' use '$instance' references missing actor export '$export' from library '$library->{name}'\n"
            unless $exported_actor;

        $self->_validate_use_params($actor, $use, $exported_actor);
        my $bindings = $self->_validate_use_bindings($actor, $use, $exported_actor);

        my $module = _specialized_library_module_name($actor->{actor_name}, $instance);
        push @resolved_uses, {
            library             => $library->{name},
            library_source      => $library->{source},
            alias               => $alias,
            export              => $export,
            kind                => 'actor',
            instance            => $instance,
            module              => $module,
            scheduled_fsm       => "$module.fsm",
            actor               => _clone_isf_value($exported_actor),
            parameter_overrides => _clone_isf_value($use->{parameter_overrides} || []),
            bindings            => $bindings,
            (defined($use->{domain}) ? (domain => $use->{domain}) : ()),
        };
    }

    $actor->{library_uses} = \@resolved_uses;
    return 1;
}

sub _same_source_libraries($self, $forms, $source_label) {
    my %libraries;
    for my $form (_forms_by_head($forms, 'library')) {
        my $library = $self->_parse_library_form($form, $source_label);
        confess "Error: duplicate library '$library->{name}' in '$source_label'\n"
            if exists $libraries{$library->{name}};
        $libraries{$library->{name}} = $library;
    }
    return %libraries;
}

sub _resolve_library($self, $library_name, $same_source_libraries, $source_label, $seen) {
    return $same_source_libraries->{$library_name}
        if exists $same_source_libraries->{$library_name};

    my @candidates = _library_file_candidates($library_name, $source_label);
    my @searched;
    for my $candidate (@candidates) {
        push @searched, $candidate;
        next unless -f $candidate && -r $candidate;
        my $abs = abs_path($candidate) || $candidate;
        my $key = "$abs:$library_name";
        confess "Error: recursive library import of '$library_name' through '$candidate' is unsupported\n"
            if $seen->{$key}++;

        my $source = read_file($candidate);
        my $raw = Lispish::multi(\$source);
        confess "Error: failed to parse library '$library_name' source '$candidate' with Lispish\n"
            unless defined $raw && ref($raw) eq 'ARRAY';
        my $forms = $self->{adapter}->normalize_multi($raw);

        my @matching;
        for my $form (_forms_by_head($forms, 'library')) {
            next unless defined($form->[1]) && !ref($form->[1]) && $form->[1] eq $library_name;
            push @matching, $form;
        }
        confess "Error: library source '$candidate' contains multiple '(library $library_name ...)' roots\n"
            if @matching > 1;
        confess "Error: library source '$candidate' does not contain '(library $library_name ...)'\n"
            unless @matching;

        return $self->_parse_library_form($matching[0], $candidate);
    }

    confess "Error: library '$library_name' not found for '$source_label'; searched:\n"
        . join('', map { "  - $_\n" } @searched);
}

sub _parse_library_form($self, $form, $source_label) {
    confess "Error: (library ...) requires a scalar dotted namespace name\n"
        unless ref($form) eq 'ARRAY'
            && @$form >= 3
            && defined($form->[1])
            && !ref($form->[1])
            && _is_library_namespace($form->[1]);

    my $library_name = $form->[1];
    my %exported_actor_names;
    my %actor_defs;
    my $saw_exports;

    for my $clause (@{$form}[2 .. $#$form]) {
        confess "Error: library '$library_name' body clauses must be list forms\n"
            unless ref($clause) eq 'ARRAY' && @$clause;
        my $head = $clause->[0];
        confess "Error: library '$library_name' body clause heads must be scalar\n"
            unless defined($head) && !ref($head) && length($head);

        if ($head eq 'exports') {
            confess "Error: library '$library_name' accepts only one '(exports ...)'\n"
                if $saw_exports++;
            for my $entry (@{$clause}[1 .. $#$clause]) {
                confess "Error: library '$library_name' exports require '(actor name)' entries\n"
                    unless ref($entry) eq 'ARRAY'
                        && @$entry == 2
                        && defined($entry->[0])
                        && !ref($entry->[0])
                        && defined($entry->[1])
                        && !ref($entry->[1])
                        && length($entry->[1]);
                confess "Error: library '$library_name' export kind '$entry->[0]' is not supported yet; first shipped library exports are actors\n"
                    unless $entry->[0] eq 'actor';
                confess "Error: library '$library_name' has duplicate actor export '$entry->[1]'\n"
                    if $exported_actor_names{$entry->[1]}++;
            }
            next;
        }

        if ($head eq 'actor') {
            my $actor = $self->_build_actor($clause, $source_label);
            confess "Error: library '$library_name' has duplicate actor definition '$actor->{actor_name}'\n"
                if exists $actor_defs{$actor->{actor_name}};
            confess "Error: library '$library_name' actor '$actor->{actor_name}' cannot import libraries yet\n"
                if @{$actor->{imports} || []} || @{$actor->{uses} || []};
            $actor_defs{$actor->{actor_name}} = $actor;
            next;
        }

        confess "Error: library '$library_name' has unsupported body clause '$head'\n";
    }

    confess "Error: library '$library_name' requires an '(exports ...)' clause\n"
        unless $saw_exports;
    confess "Error: library '$library_name' exports at least one actor\n"
        unless keys %exported_actor_names;

    my %exports = (actor => {});
    for my $actor_name (sort keys %exported_actor_names) {
        confess "Error: library '$library_name' exports unknown actor '$actor_name'\n"
            unless exists $actor_defs{$actor_name};
        $exports{actor}{$actor_name} = $actor_defs{$actor_name};
    }

    return {
        name    => $library_name,
        source  => $source_label,
        exports => \%exports,
    };
}

sub _validate_use_params($self, $actor, $use, $exported_actor) {
    my %declared = map { $_->{name} => $_ } @{$exported_actor->{params} || []};
    for my $override (@{$use->{parameter_overrides} || []}) {
        my $name = $override->{name};
        confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' overrides unknown parameter '$name'\n"
            unless exists $declared{$name};
        confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' parameter '$name' shape does not match actor '$exported_actor->{actor_name}' declaration\n"
            unless _param_values_shape_compatible($declared{$name}{value}, $override->{value});
        $override->{value} = $self->_resolve_library_use_param_value(
            $actor,
            $override->{value},
            "actor '$actor->{actor_name}' use '$use->{instance}' parameter '$name'",
        );
    }
    return 1;
}

sub _resolve_library_use_param_value($self, $actor, $value, $context) {
    if (!ref($value)) {
        confess "Error: $context uses undefined parameter value; reusable-library use-site parameter overrides accept numeric, exact-width, enum member, and aggregate/list literal values only\n"
            unless defined($value);
        return _clone_isf_value($value)
            if _is_numeric_or_exact_width_literal($value);
        if (_is_enum_member_reference($value)) {
            my $resolved_value = $self->_resolve_actor_enum_member_value($actor, $value);
            confess "Error: $context references unknown enum member '$value'\n"
                unless defined($resolved_value) && !ref($resolved_value);
            confess "Error: $context enum member '$value' must resolve to a non-negative integer literal value\n"
                unless _is_non_negative_integer_literal_value($resolved_value);
            return _clone_isf_value($resolved_value);
        }

        confess "Error: $context uses unsupported parameter value '$value'; reusable-library use-site parameter overrides accept numeric, exact-width, enum member, and aggregate/list literal values only\n";
    }

    confess "Error: $context uses unsupported parameter value shape; reusable-library use-site parameter overrides accept non-empty aggregate/list literal values only\n"
        unless ref($value) eq 'ARRAY' && @$value;

    return [
        map {
            $self->_resolve_library_use_param_value($actor, $_, $context)
        } @$value
    ];
}

sub _validate_use_bindings($self, $actor, $use, $exported_actor) {
    my @bindings = @{$use->{bindings} || []};
    my %parent_ports = (
        map({ $_->{name} => { %$_, direction => 'input' } } @{$actor->{interface}{inputs} || []}),
        map({ $_->{name} => { %$_, direction => 'output' } } @{$actor->{interface}{outputs} || []}),
    );
    my %library_ports = (
        map({ $_->{name} => { %$_, direction => 'input' } } @{$exported_actor->{interface}{inputs} || []}),
        map({ $_->{name} => { %$_, direction => 'output' } } @{$exported_actor->{interface}{outputs} || []}),
    );

    my %seen_clock_reset;
    my %seen_library_port;
    my @resolved;

    for my $binding (@bindings) {
        my $role = $binding->{role};
        if ($role eq 'clock' || $role eq 'reset') {
            confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' has duplicate $role binding\n"
                if $seen_clock_reset{$role}++;
            my $parent_name = $binding->{parent_name};
            confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' $role binding references unknown parent signal '$parent_name'\n"
                unless exists $parent_ports{$parent_name}
                    || (defined($actor->{$role}) && $actor->{$role} && (($role eq 'clock' ? $actor->{clock} : $actor->{reset}{name}) // '') eq $parent_name);
            push @resolved, { %$binding, width => 1 };
            next;
        }

        my $library_name = $binding->{library_name};
        my $parent_name = $binding->{parent_name};
        confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' has duplicate binding for library port '$library_name'\n"
            if $seen_library_port{$library_name}++;
        confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' references unknown library port '$library_name'\n"
            unless exists $library_ports{$library_name};
        confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' binding for '$library_name' declares role '$role' but exported actor role is '$library_ports{$library_name}{direction}'\n"
            unless $library_ports{$library_name}{direction} eq $role;
        confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' binding for '$library_name' references unknown parent signal '$parent_name'\n"
            unless exists $parent_ports{$parent_name};
        confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' binding for '$library_name' targets parent '$parent_name' with direction '$parent_ports{$parent_name}{direction}', expected '$role'\n"
            unless $parent_ports{$parent_name}{direction} eq $role;

        my $library_width = $library_ports{$library_name}{width} // 1;
        my $parent_width = $parent_ports{$parent_name}{width} // 1;
        confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' binding for '$library_name' width $library_width does not match parent '$parent_name' width $parent_width\n"
            unless $library_width == $parent_width;

        push @resolved, { %$binding, width => $library_width };
    }

    confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' requires a clock binding for actor '$exported_actor->{actor_name}'\n"
        if defined($exported_actor->{clock}) && length($exported_actor->{clock}) && !$seen_clock_reset{clock};
    confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' has a clock binding but actor '$exported_actor->{actor_name}' has no clock\n"
        if (!defined($exported_actor->{clock}) || !length($exported_actor->{clock})) && $seen_clock_reset{clock};
    confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' requires a reset binding for actor '$exported_actor->{actor_name}'\n"
        if $exported_actor->{reset} && !$seen_clock_reset{reset};
    confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' has a reset binding but actor '$exported_actor->{actor_name}' has no reset\n"
        if !$exported_actor->{reset} && $seen_clock_reset{reset};

    for my $port_name (sort keys %library_ports) {
        confess "Error: actor '$actor->{actor_name}' use '$use->{instance}' does not bind library port '$port_name'\n"
            unless $seen_library_port{$port_name};
    }

    return \@resolved;
}

sub _split_use_target($target, $libraries_by_alias) {
    for my $alias (sort { length($b) <=> length($a) || $a cmp $b } keys %{$libraries_by_alias || {}}) {
        next unless index($target, "$alias.") == 0;
        my $export = substr($target, length($alias) + 1);
        next unless defined($export) && length($export) && _is_hdl_identifier($export);
        return ($alias, $export);
    }
    return (undef, undef);
}

sub _library_file_candidates($library_name, $source_label) {
    my @roots;
    if (defined($source_label) && !ref($source_label) && -f $source_label) {
        push @roots, dirname(File::Spec->rel2abs($source_label));
    }
    push @roots, grep { defined($_) && length($_) } split(/:/, $ENV{FSMLIB} || '');
    push @roots, File::Spec->curdir();

    my $flat = "$library_name.isf";
    my $pathish = File::Spec->catfile(split(/\./, $library_name)) . '.isf';
    my @candidates;
    my %seen;
    for my $root (@roots) {
        for my $rel ($flat, $pathish) {
            my $candidate = File::Spec->catfile($root, $rel);
            push @candidates, $candidate unless $seen{$candidate}++;
        }
    }
    return @candidates;
}

sub _specialized_library_module_name($actor_name, $instance) {
    my $name = "${actor_name}__${instance}";
    $name =~ s/[^A-Za-z0-9_]/_/g;
    return $name;
}

sub _is_hdl_identifier {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value =~ /\A[A-Za-z_]\w*\z/;
}

sub _is_type_reference {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?\z/;
}

sub _is_enum_member_reference {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value =~ /\A[A-Za-z_]\w*\.[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?\z/;
}

sub _is_aggregate_type_spec {
    my ($type_spec) = @_;
    return 0 unless ref($type_spec) eq 'HASH';
    my $kind = $type_spec->{kind} || '';
    return ($kind eq 'list' || $kind eq 'record') ? 1 : 0;
}

sub _is_activation_input_binding_expr_shape {
    my ($expr) = @_;
    return 1 if ref($expr) eq 'ARRAY' && @$expr;
    return 0 if ref($expr);
    return 0 unless defined($expr) && length($expr);
    return 1 if _is_hdl_identifier($expr);
    return 1 if _is_numeric_or_exact_width_literal($expr);
    return 0;
}

sub _is_library_namespace {
    my ($value) = @_;
    return defined($value)
        && !ref($value)
        && $value =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\z/;
}

sub _validate_isf_param_value {
    my ($value, $context) = @_;
    if (!ref($value)) {
        confess "$context uses unsupported parameter value '$value'; first ISF library parameter binding accepts numeric, exact-width, enum member, and aggregate/list literals only\n"
            unless defined($value) && (_is_numeric_or_exact_width_literal($value) || _is_enum_member_reference($value));
        return 1;
    }

    confess "$context uses unsupported parameter value shape; first ISF library parameter binding accepts non-empty aggregate/list literals only\n"
        unless ref($value) eq 'ARRAY' && @$value;

    for my $item (@$value) {
        _validate_isf_param_value($item, $context);
    }
    return 1;
}

sub _validate_actor_param_value {
    my ($value, $context) = @_;
    if (!ref($value)) {
        confess "$context uses unsupported parameter value '$value'; actor parameter defaults accept numeric, exact-width, aggregate/list, and scalar enum member literals only\n"
            unless defined($value)
                && (_is_numeric_or_exact_width_literal($value) || _is_enum_member_reference($value));
        return 1;
    }

    confess "$context uses unsupported parameter value shape; actor parameter defaults accept non-empty aggregate/list literals\n"
        unless ref($value) eq 'ARRAY' && @$value;

    for my $item (@$value) {
        _validate_actor_param_aggregate_leaf_value($item, $context);
    }
    return 1;
}

sub _validate_actor_param_aggregate_leaf_value {
    my ($value, $context) = @_;
    if (!ref($value)) {
        confess "$context uses unsupported aggregate/list parameter leaf '$value'; actor parameter aggregate/list defaults accept numeric, exact-width, and enum member literal leaves only\n"
            unless defined($value)
                && (_is_numeric_or_exact_width_literal($value) || _is_enum_member_reference($value));
        return 1;
    }

    confess "$context uses unsupported parameter value shape; actor parameter defaults accept non-empty aggregate/list literals\n"
        unless ref($value) eq 'ARRAY' && @$value;

    for my $item (@$value) {
        _validate_actor_param_aggregate_leaf_value($item, $context);
    }
    return 1;
}

sub _is_numeric_or_exact_width_literal {
    my ($value) = @_;
    return 0 unless defined($value) && !ref($value);
    return 1 if $value =~ /\A\d+\z/;
    return 1 if $value =~ /\A\d+'[bBoOdDhH][0-9a-fA-F_xXzZ]+\z/;
    return 0;
}

sub _is_non_negative_integer_literal_value {
    my ($value) = @_;
    return 0 unless defined($value) && !ref($value);

    my $integer = FSM::Package::IntegerLiteralSupport->integer_from_literal_like($value);
    return 0 unless defined $integer;
    return $integer->bcmp(0) >= 0;
}

sub _param_values_shape_compatible {
    my ($declared, $override) = @_;
    return 1 if !ref($declared) && !ref($override);
    return 0 unless ref($declared) eq 'ARRAY' && ref($override) eq 'ARRAY';
    return 0 unless @$declared == @$override;
    for my $index (0 .. $#$declared) {
        return 0 unless _param_values_shape_compatible($declared->[$index], $override->[$index]);
    }
    return 1;
}

sub _clone_isf_value {
    my ($value) = @_;
    return [ map { _clone_isf_value($_) } @$value ] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_isf_value($value->{$_}) } keys %$value } if ref($value) eq 'HASH';
    return $value;
}

sub _parse_clock($self, $clause) {
    confess "Error: (clock ...) requires exactly one name\n" unless @$clause == 2;
    confess "Error: (clock ...) requires a scalar name\n"
        unless defined($clause->[1]) && !ref($clause->[1]) && length($clause->[1]);
    return $clause->[1];
}

sub _parse_reset($self, $clause) {
    my $spec = $clause->[1];
    # Flat form: (reset rst_n)
    if (!ref($spec)) {
        confess "Error: (reset ...) requires a scalar name\n"
            unless defined($spec) && length($spec);
        my $polarity = $spec =~ /_[nb]$/ ? 'active_low' : 'active_high';
        return { name => $spec, kind => 'sync', polarity => $polarity };
    }
    # List form: (reset (rst_n async active_low))
    confess "Error: (reset ...) requires a name\n" unless ref($spec) eq 'ARRAY';
    my $name = $spec->[0];
    confess "Error: (reset ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);
    my $kind = 'sync';
    my $polarity = $name =~ /_[nb]$/ ? 'active_low' : 'active_high';

    for my $i (1 .. $#$spec) {
        my $val = $spec->[$i];
        next unless defined $val;
        if ($val eq 'async')      { $kind = 'async'; }
        elsif ($val eq 'active_low')  { $polarity = 'active_low'; }
        elsif ($val eq 'active_high') { $polarity = 'active_high'; }
    }

    return { name => $name, kind => $kind, polarity => $polarity };
}

sub _parse_clock_domains($self, $clause, $actor_name) {
    confess "Error: actor '$actor_name' clock-domains require '(clock-domains (domain name (clock clk) ...) ...)'\n"
        unless @$clause >= 2;

    my @domains;
    my %seen_domain;
    my %seen_clock;
    my %reset_by_name;
    my @default_domains;

    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' clock-domains entries require '(domain name (clock clk) ...)'\n"
            unless ref($entry) eq 'ARRAY'
                && @$entry >= 3
                && defined($entry->[0])
                && !ref($entry->[0])
                && $entry->[0] eq 'domain';

        my $name = $entry->[1];
        confess "Error: actor '$actor_name' clock-domain names must be scalar HDL identifiers\n"
            unless _is_hdl_identifier($name);
        confess "Error: actor '$actor_name' has duplicate clock domain '$name'\n"
            if $seen_domain{$name}++;

        my (%seen_subclause, $clock, $reset);
        my $is_default = 0;
        for my $part (@{$entry}[2 .. $#$entry]) {
            if (defined($part) && !ref($part) && $part eq ':default') {
                confess "Error: actor '$actor_name' clock domain '$name' has duplicate ':default' marker\n"
                    if $is_default++;
                push @default_domains, $name;
                next;
            }

            confess "Error: actor '$actor_name' clock domain '$name' entries must be '(clock ...)', '(reset ...)', or ':default'\n"
                unless ref($part) eq 'ARRAY'
                    && @$part
                    && defined($part->[0])
                    && !ref($part->[0])
                    && length($part->[0]);

            my $head = $part->[0];
            confess "Error: actor '$actor_name' clock domain '$name' has duplicate '$head' subclause\n"
                if $seen_subclause{$head}++;

            if ($head eq 'clock') {
                $clock = $self->_parse_clock($part);
                next;
            }
            if ($head eq 'reset') {
                confess "Error: actor '$actor_name' clock domain '$name' reset requires '(reset name_or_reset_spec)'\n"
                    unless @$part == 2;
                $reset = $self->_parse_reset($part);
                next;
            }

            confess "Error: actor '$actor_name' clock domain '$name' has unsupported subclause '$head'\n";
        }

        confess "Error: actor '$actor_name' clock domain '$name' requires '(clock name)'\n"
            unless defined($clock);
        confess "Error: actor '$actor_name' clock signal '$clock' is used by multiple clock domains\n"
            if $seen_clock{$clock}++;

        if ($reset) {
            my $previous = $reset_by_name{$reset->{name}};
            confess "Error: actor '$actor_name' reset '$reset->{name}' is reused with conflicting clock-domain reset policy\n"
                if $previous
                    && (($previous->{kind} // 'sync') ne ($reset->{kind} // 'sync')
                        || ($previous->{polarity} // 'active_high') ne ($reset->{polarity} // 'active_high'));
            $reset_by_name{$reset->{name}} = $reset;
        }

        my %domain = (
            name  => $name,
            clock => $clock,
        );
        $domain{reset} = $reset if $reset;
        $domain{default} = 1 if $is_default;
        push @domains, \%domain;
    }

    my $default;
    if (@domains == 1 && !@default_domains) {
        $default = $domains[0]{name};
        $domains[0]{default} = 1;
    } else {
        confess "Error: actor '$actor_name' multi-domain clock-domains require exactly one ':default' domain\n"
            unless @default_domains == 1;
        $default = $default_domains[0];
    }

    return {
        default => $default,
        domains => \@domains,
    };
}

sub _parse_crossings($self, $clause, $actor_name) {
    confess "Error: actor '$actor_name' crossings require '(crossings (event name ...) ...)'\n"
        unless @$clause >= 2;

    my @crossings;
    my %seen_event;
    my %seen_signal;

    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' crossings entries require '(event name (from domain signal) (to domain signal) (ready signal))'\n"
            unless ref($entry) eq 'ARRAY'
                && @$entry >= 5
                && defined($entry->[0])
                && !ref($entry->[0])
                && $entry->[0] eq 'event';

        my $name = $entry->[1];
        confess "Error: actor '$actor_name' crossing event names must be scalar HDL identifiers\n"
            unless _is_hdl_identifier($name);
        confess "Error: actor '$actor_name' has duplicate crossing event '$name'\n"
            if $seen_event{$name}++;

        my (%seen_subclause, $from, $to, $ready);
        for my $part (@{$entry}[2 .. $#$entry]) {
            confess "Error: actor '$actor_name' crossing event '$name' subclauses must be '(from domain signal)', '(to domain signal)', or '(ready signal)'\n"
                unless ref($part) eq 'ARRAY'
                    && @$part
                    && defined($part->[0])
                    && !ref($part->[0])
                    && length($part->[0]);

            my $head = $part->[0];
            confess "Error: actor '$actor_name' crossing event '$name' has duplicate '$head' subclause\n"
                if $seen_subclause{$head}++;

            if ($head eq 'from' || $head eq 'to') {
                confess "Error: actor '$actor_name' crossing event '$name' requires '($head domain signal)'\n"
                    unless @$part == 3
                        && _is_hdl_identifier($part->[1])
                        && _is_hdl_identifier($part->[2]);
                my $parsed = {
                    domain => $part->[1],
                    signal => $part->[2],
                };
                $from = $parsed if $head eq 'from';
                $to = $parsed if $head eq 'to';
                next;
            }

            if ($head eq 'ready') {
                confess "Error: actor '$actor_name' crossing event '$name' requires '(ready signal)'\n"
                    unless @$part == 2 && _is_hdl_identifier($part->[1]);
                $ready = { signal => $part->[1] };
                next;
            }

            confess "Error: actor '$actor_name' crossing event '$name' has unsupported subclause '$head'\n";
        }

        confess "Error: actor '$actor_name' crossing event '$name' requires '(from domain signal)'\n"
            unless $from;
        confess "Error: actor '$actor_name' crossing event '$name' requires '(to domain signal)'\n"
            unless $to;
        confess "Error: actor '$actor_name' crossing event '$name' requires '(ready signal)'\n"
            unless $ready;

        for my $endpoint ($from->{signal}, $to->{signal}, $ready->{signal}) {
            confess "Error: actor '$actor_name' crossing endpoint signal '$endpoint' is used by multiple crossing endpoints\n"
                if $seen_signal{$endpoint}++;
        }

        push @crossings, {
            kind  => 'event',
            name  => $name,
            from  => $from,
            to    => $to,
            ready => $ready,
        };
    }

    return \@crossings;
}

sub _finalize_actor_clock_domain_timing($self, $actor, $singleton_actor_clauses) {
    return 1 unless ref($actor->{clock_domains}) eq 'HASH';

    my $actor_name = $actor->{actor_name};
    confess "Error: actor '$actor_name' cannot mix '(clock ...)' with '(clock-domains ...)'\n"
        if $singleton_actor_clauses->{clock};
    confess "Error: actor '$actor_name' cannot mix actor-level '(reset ...)' with '(clock-domains ...)'\n"
        if $singleton_actor_clauses->{reset};

    my $default_domain = $actor->{clock_domains}{default};
    my ($domain) = grep { $_->{name} eq $default_domain } @{$actor->{clock_domains}{domains} || []};
    confess "Error: actor '$actor_name' clock-domains default '$default_domain' is not declared\n"
        unless $domain;

    $actor->{clock} = $domain->{clock};
    $actor->{reset} = _clone_isf_value($domain->{reset}) if $domain->{reset};
    return 1;
}

sub _parse_watchdog($self, $clause) {
    confess "Error: (watchdog ...) requires a positive integer\n" unless @$clause == 2;
    confess "Error: (watchdog ...) requires a positive integer\n"
        unless defined($clause->[1]) && !ref($clause->[1]) && $clause->[1] =~ /\A[1-9][0-9]*\z/;
    return $clause->[1];
}

sub _parse_interface($self, $clause) {
    my @inputs;
    my @outputs;
    my %seen_names;

    for my $i (1 .. $#$clause) {
        my $port = $clause->[$i];
        confess "Error: interface port must be a list\n" unless ref($port) eq 'ARRAY';
        my $dir = $port->[0];
        my $name = $port->[1];
        my $width = 1;
        my $type;
        my $domain;

        confess "Error: interface port direction must be input or output\n"
            unless defined($dir) && !ref($dir) && ($dir eq 'input' || $dir eq 'output');
        confess "Error: interface port requires a scalar name\n"
            unless defined($name) && !ref($name) && length($name);
        confess "Error: duplicate interface port '$name'\n" if $seen_names{$name}++;

        # Check for (width N) in remaining elements
        my %seen_options;
        for my $j (2 .. $#$port) {
            my $prop = $port->[$j];
            next unless ref($prop) eq 'ARRAY' && @$prop;
            my $option_name = $prop->[0];
            next unless defined($option_name) && !ref($option_name);
            confess "Error: interface port '$name' has duplicate '$option_name' option\n"
                if $seen_options{$option_name}++;
            if (ref($prop) eq 'ARRAY' && $prop->[0] eq 'width') {
                confess "Error: interface port '$name' width must be a positive integer\n"
                    unless @$prop == 2
                        && defined($prop->[1])
                        && !ref($prop->[1])
                        && $prop->[1] =~ /\A[1-9][0-9]*\z/;
                $width = $prop->[1];
                next;
            }
            if ($prop->[0] eq 'type') {
                confess "Error: interface port '$name' type requires '(type NAME)'\n"
                    unless @$prop == 2 && _is_type_reference($prop->[1]);
                $type = $prop->[1];
                next;
            }
            if ($prop->[0] eq 'domain') {
                $domain = _parse_domain_option(
                    $prop,
                    "Error: interface port '$name' domain",
                );
                next;
            }
        }
        confess "Error: interface port '$name' cannot specify both '(width ...)' and '(type ...)'\n"
            if defined($type) && exists($seen_options{width});

        my $entry = { name => $name, width => $width };
        $entry->{type} = $type if defined $type;
        $entry->{domain} = $domain if defined $domain;
        if ($dir eq 'input')  { push @inputs,  $entry; }
        if ($dir eq 'output') { push @outputs, $entry; }
    }

    return { inputs => \@inputs, outputs => \@outputs };
}

sub _parse_storage($self, $clause, $actor_name) {
    confess "Error: actor '$actor_name' storage requires '(storage (var name (width N)) ...)' entries\n"
        unless @$clause >= 2;

    my @entries;
    my %seen_logical_name;
    my %seen_signal_name;

    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' storage entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry;

        my ($authored_kind, $name, @options) = @$entry;
        my $kind = _normalize_storage_kind($authored_kind);
        confess "Error: actor '$actor_name' storage entry kind must be 'var', 'variable', or 'bank'\n"
            unless defined($kind);
        confess "Error: actor '$actor_name' storage '$kind' entry requires a scalar HDL identifier name\n"
            unless _is_hdl_identifier($name);
        confess "Error: actor '$actor_name' has duplicate storage name '$name'\n"
            if $seen_logical_name{$name}++;

        my %parsed_options;
        for my $option (@options) {
            confess "Error: actor '$actor_name' storage '$name' options must be list forms\n"
                unless ref($option) eq 'ARRAY' && @$option;
            my $option_name = $option->[0];
            confess "Error: actor '$actor_name' storage '$name' option name must be scalar\n"
                unless defined($option_name) && !ref($option_name) && length($option_name);
            confess "Error: actor '$actor_name' storage '$name' has duplicate '$option_name' option\n"
                if $parsed_options{$option_name}++;

            if ($option_name eq 'width') {
                $parsed_options{width_value} = _parse_storage_positive_integer_option(
                    $option,
                    "Error: actor '$actor_name' storage '$name' width",
                );
                next;
            }
            if ($option_name eq 'type') {
                confess "Error: actor '$actor_name' storage '$name' type requires '(type NAME)'\n"
                    unless @$option == 2 && _is_type_reference($option->[1]);
                $parsed_options{type_value} = $option->[1];
                next;
            }
            if ($option_name eq 'depth') {
                $parsed_options{depth_value} = _parse_storage_positive_integer_option(
                    $option,
                    "Error: actor '$actor_name' storage '$name' depth",
                );
                next;
            }
            if ($option_name eq 'domain') {
                $parsed_options{domain_value} = _parse_domain_option(
                    $option,
                    "Error: actor '$actor_name' storage '$name' domain",
                );
                next;
            }

            confess "Error: actor '$actor_name' storage '$name' has unsupported option '$option_name'\n";
        }

        my $width = $parsed_options{width_value};
        my $type = $parsed_options{type_value};
        confess "Error: actor '$actor_name' storage '$name' cannot specify both '(width ...)' and '(type ...)'\n"
            if defined($width) && defined($type);
        confess "Error: actor '$actor_name' storage '$name' requires '(width N)' or '(type NAME)'\n"
            unless defined($width) || defined($type);

        my @signals;
        if ($kind eq 'var') {
            confess "Error: actor '$actor_name' storage $kind '$name' does not accept '(depth N)'\n"
                if defined($parsed_options{depth_value});
            @signals = ({ name => $name, width => $width });
        } else {
            my $depth = $parsed_options{depth_value};
            confess "Error: actor '$actor_name' storage bank '$name' requires '(depth N)'\n"
                unless defined($depth);
            @signals = map { +{ name => "${name}_$_", width => $width, index => $_ } } 0 .. $depth - 1;
        }

        for my $signal (@signals) {
            my $signal_name = $signal->{name};
            confess "Error: actor '$actor_name' storage '$name' lowers to duplicate signal '$signal_name'\n"
                if $seen_signal_name{$signal_name}++;
        }

        push @entries, {
            kind    => $kind,
            name    => $name,
            width   => $width,
            signals => \@signals,
            ($kind eq 'bank' ? (depth => $parsed_options{depth_value}) : ()),
        };
        $entries[-1]{type} = $type if defined $type;
        $entries[-1]{domain} = $parsed_options{domain_value}
            if defined($parsed_options{domain_value});
    }

    return \@entries;
}

sub _normalize_storage_kind {
    my ($kind) = @_;
    return undef unless defined($kind) && !ref($kind);
    return 'var' if $kind eq 'var' || $kind eq 'variable';
    return 'bank' if $kind eq 'bank';
    return undef;
}

sub _parse_storage_positive_integer_option {
    my ($option, $context) = @_;

    confess "$context requires '(name positive_integer)'\n"
        unless ref($option) eq 'ARRAY'
            && @$option == 2
            && defined($option->[1])
            && !ref($option->[1])
            && $option->[1] =~ /\A[1-9][0-9]*\z/;

    return 0 + $option->[1];
}

sub _parse_domain_option {
    my ($option, $context) = @_;

    confess "$context requires '(domain name)'\n"
        unless ref($option) eq 'ARRAY'
            && @$option == 2
            && defined($option->[0])
            && !ref($option->[0])
            && $option->[0] eq 'domain'
            && _is_hdl_identifier($option->[1]);

    return $option->[1];
}

sub _parse_handshake($self, $clause) {
    confess "Error: (handshake ...) requires '(handshake name (valid signal) (ready signal))'\n"
        unless @$clause >= 3 && @$clause <= 4;
    my $name = $clause->[1];
    confess "Error: (handshake ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);

    my %seen;
    for my $i (2 .. $#$clause) {
        my $pair = $clause->[$i];
        confess "Error: handshake '$name' properties must be '(valid signal)' or '(ready signal)'\n"
            unless ref($pair) eq 'ARRAY'
                && @$pair == 2
                && defined($pair->[0])
                && !ref($pair->[0])
                && ($pair->[0] eq 'valid' || $pair->[0] eq 'ready')
                && defined($pair->[1])
                && !ref($pair->[1])
                && length($pair->[1]);

        my $key = $pair->[0];
        confess "Error: duplicate handshake '$name' property '$key'\n" if $seen{$key}++;
    }

    confess "Error: handshake '$name' requires exactly one '(valid signal)' and one '(ready signal)' property; "
        . "legacy handshakes are ignored compatibility input, use '(on ...)' activation "
        . "or transaction '(stage ...)' for ready/valid behavior\n"
        unless $seen{valid} && $seen{ready};

    return $name;
}

sub _parse_transaction($self, $clause) {
    confess "Error: (transaction ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    confess "Error: (transaction ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);
    my @clauses;
    my $ports = { inputs => [], outputs => [] };
    my $saw_ports;
    my $domain;

    for my $i (2 .. $#$clause) {
        my $body_clause = $clause->[$i];
        if (ref($body_clause) eq 'ARRAY'
            && @$body_clause
            && defined($body_clause->[0])
            && !ref($body_clause->[0])
            && $body_clause->[0] eq 'ports')
        {
            confess "Error: transaction '$name' accepts only one '(ports ...)' clause\n"
                if $saw_ports++;
            $ports = $self->_parse_transaction_ports($body_clause, $name);
            next;
        }
        if (ref($body_clause) eq 'ARRAY'
            && @$body_clause
            && defined($body_clause->[0])
            && !ref($body_clause->[0])
            && $body_clause->[0] eq 'domain')
        {
            confess "Error: transaction '$name' accepts only one '(domain ...)' clause\n"
                if defined $domain;
            $domain = _parse_domain_option(
                $body_clause,
                "Error: transaction '$name' domain",
            );
            next;
        }

        push @clauses, $body_clause;
    }
    $self->_validate_transaction_phase_stage_clauses(\@clauses);

    my %transaction = (name => $name, ports => $ports, clauses => \@clauses);
    $transaction{domain} = $domain if defined $domain;
    return \%transaction;
}

sub _parse_transaction_ports($self, $clause, $transaction_name) {
    confess "Error: transaction '$transaction_name' ports require '(ports (input name [(width N)]) ...)'\n"
        unless @$clause >= 2;

    my @inputs;
    my @outputs;
    my %seen_names;

    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: transaction '$transaction_name' port entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry >= 2;

        my ($direction, $name, @options) = @$entry;
        confess "Error: transaction '$transaction_name' port direction must be input or output\n"
            unless defined($direction) && !ref($direction) && ($direction eq 'input' || $direction eq 'output');
        confess "Error: transaction '$transaction_name' port requires a scalar HDL identifier name\n"
            unless _is_hdl_identifier($name);
        confess "Error: transaction '$transaction_name' has duplicate port '$name'\n"
            if $seen_names{$name}++;

        my $width = 1;
        my $type;
        my %seen_options;
        for my $option (@options) {
            confess "Error: transaction '$transaction_name' port '$name' options must be list forms\n"
                unless ref($option) eq 'ARRAY' && @$option;
            my $option_name = $option->[0];
            confess "Error: transaction '$transaction_name' port '$name' option name must be scalar\n"
                unless defined($option_name) && !ref($option_name) && length($option_name);
            confess "Error: transaction '$transaction_name' port '$name' has duplicate '$option_name' option\n"
                if $seen_options{$option_name}++;

            if ($option_name eq 'width') {
                confess "Error: transaction '$transaction_name' port '$name' width requires '(width positive_integer)'\n"
                    unless @$option == 2
                        && defined($option->[1])
                        && !ref($option->[1])
                        && $option->[1] =~ /\A[1-9][0-9]*\z/;
                $width = 0 + $option->[1];
                next;
            }
            if ($option_name eq 'type') {
                confess "Error: transaction '$transaction_name' port '$name' type requires '(type NAME)'\n"
                    unless @$option == 2 && _is_type_reference($option->[1]);
                $type = $option->[1];
                next;
            }

            confess "Error: transaction '$transaction_name' port '$name' has unsupported option '$option_name'\n";
        }
        confess "Error: transaction '$transaction_name' port '$name' cannot specify both '(width ...)' and '(type ...)'\n"
            if defined($type) && exists($seen_options{width});

        my $parsed = { name => $name, width => $width };
        $parsed->{type} = $type if defined $type;
        if ($direction eq 'input') {
            push @inputs, $parsed;
        } else {
            push @outputs, $parsed;
        }
    }

    return { inputs => \@inputs, outputs => \@outputs };
}

sub _parse_rule($self, $clause) {
    confess "Error: (rule ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    confess "Error: (rule ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);
    my $when;
    my @actions;
    my @body = @{$clause}[2 .. $#$clause];
    my $domain;
    my @domain_filtered_body;

    for my $elem (@body) {
        if (ref($elem) eq 'ARRAY'
            && @$elem
            && defined($elem->[0])
            && !ref($elem->[0])
            && $elem->[0] eq 'domain')
        {
            confess "Error: rule '$name' accepts only one '(domain ...)' clause\n"
                if defined $domain;
            $domain = _parse_domain_option(
                $elem,
                "Error: rule '$name' domain",
            );
            next;
        }
        push @domain_filtered_body, $elem;
    }
    @body = @domain_filtered_body;

    if (@body && defined($body[0]) && !ref($body[0])) {
        $when = $self->_parse_rule_when(['when', shift @body], $name);
    } elsif (@body && _is_rule_guard_shorthand_expr($body[0])) {
        $when = $self->_parse_rule_when(['when', shift @body], $name);
    }

    for my $elem (@body) {
        if (ref($elem) eq 'ARRAY' && defined($elem->[0]) && !ref($elem->[0]) && $elem->[0] eq 'when') {
            confess "Error: rule '$name' accepts only one guard condition\n"
                if defined $when;
            $when = $self->_parse_rule_when($elem, $name);
        } else {
            $self->_parse_rule_action($elem, $name);
            push @actions, $elem;
        }
    }

    my %rule = (name => $name, when => $when, actions => \@actions);
    $rule{domain} = $domain if defined $domain;
    return \%rule;
}

sub _parse_rule_when($self, $clause, $rule_name) {
    confess "Error: rule '$rule_name' guard requires exactly one condition\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause == 2
            && defined($clause->[1]);

    my $condition = $clause->[1];
    if (!ref($condition)) {
        confess "Error: rule '$rule_name' guard condition must be a non-empty scalar or list expression\n"
            unless length($condition);
        return ['when', $condition];
    }

    $self->_validate_rule_guard_expr($condition, $rule_name);
    return ['when', _clone_isf_value($condition)];
}

sub _is_rule_guard_shorthand_expr {
    my ($expr) = @_;
    return 0 unless ref($expr) eq 'ARRAY' && @$expr;
    my $head = $expr->[0];
    return defined($head)
        && !ref($head)
        && $RULE_GUARD_SHORTHAND_EXPR_HEADS{$head};
}

sub _validate_rule_guard_expr($self, $expr, $rule_name) {
    confess "Error: rule '$rule_name' guard expression must be a non-empty list\n"
        unless ref($expr) eq 'ARRAY' && @$expr;

    my $head = $expr->[0];
    confess "Error: rule '$rule_name' guard expression heads must be scalar\n"
        unless defined($head) && !ref($head) && length($head);

    confess "Error: rule '$rule_name' guard expression cannot use control-flow form '$head'\n"
        if $RULE_ASSIGNMENT_FORBIDDEN_EXPR_HEADS{$head};

    for my $operand (@{$expr}[1 .. $#$expr]) {
        confess "Error: rule '$rule_name' guard expression operands must be defined\n"
            unless defined($operand);
        $self->_validate_rule_guard_expr($operand, $rule_name)
            if ref($operand);
    }

    return 1;
}

sub _parse_rule_priority($self, $clause, $rule_name) {
    confess "Error: rule '$rule_name' priority requires '(priority over other_rule)'\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause == 3
            && defined($clause->[1])
            && !ref($clause->[1])
            && $clause->[1] eq 'over'
            && defined($clause->[2])
            && !ref($clause->[2])
            && length($clause->[2]);

    return 1;
}

sub _parse_rule_action($self, $action, $rule_name) {
    confess "Error: rule '$rule_name' actions must be list forms\n"
        unless ref($action) eq 'ARRAY' && @$action;

    my $keyword = $action->[0];
    confess "Error: rule '$rule_name' action heads must be scalar\n"
        unless defined($keyword) && !ref($keyword) && length($keyword);

    if ($keyword eq 'trigger') {
        confess "Error: rule '$rule_name' trigger requires '(trigger transaction [(params (NAME value) ...)] [(bind ...)])'\n"
            unless @$action >= 2
                && defined($action->[1])
                && !ref($action->[1])
                && length($action->[1]);

        my %seen_subclause;
        for my $subclause (@{$action}[2 .. $#$action]) {
            confess "Error: rule '$rule_name' trigger '$action->[1]' subclauses must be '(params ...)' or '(bind ...)'\n"
                unless ref($subclause) eq 'ARRAY'
                    && @$subclause
                    && defined($subclause->[0])
                    && !ref($subclause->[0])
                    && length($subclause->[0]);
            my $head = $subclause->[0];
            confess "Error: rule '$rule_name' trigger '$action->[1]' has duplicate '$head' subclause\n"
                if $seen_subclause{$head}++;
            if ($head eq 'params') {
                $self->_parse_rule_trigger_params($subclause, $rule_name, $action->[1]);
                next;
            }
            if ($head eq 'bind') {
                $self->_parse_rule_trigger_bind($subclause, $rule_name, $action->[1]);
                next;
            }
            confess "Error: rule '$rule_name' trigger '$action->[1]' has unsupported '$head' subclause\n";
        }
        return 1;
    }
    if ($keyword eq 'priority') {
        return $self->_parse_rule_priority($action, $rule_name);
    }
    if ($keyword eq 'store') {
        confess "Error: rule '$rule_name' store action requires '(store <bank-name> <index> <value>)'\n"
            unless @$action == 4
                && _is_hdl_identifier($action->[1])
                && defined($action->[2])
                && !ref($action->[2])
                && length($action->[2])
                && defined($action->[3]);
        $self->_validate_rule_assignment_expr($action->[3], $rule_name);
        return 1;
    }
    if ($keyword eq 'load') {
        confess "Error: rule '$rule_name' load action requires '(load <bank-name> <index> as <target>)'\n"
            unless @$action == 5
                && _is_hdl_identifier($action->[1])
                && defined($action->[2])
                && !ref($action->[2])
                && length($action->[2])
                && defined($action->[3])
                && !ref($action->[3])
                && $action->[3] eq 'as'
                && _is_hdl_identifier($action->[4]);
        return 1;
    }
    if ($keyword eq 'set') {
        confess "Error: rule '$rule_name' set action requires '(set port expr)'\n"
            unless @$action == 3
                && _is_hdl_identifier($action->[1])
                && defined($action->[2]);
        $self->_validate_rule_assignment_expr($action->[2], $rule_name);
        return 1;
    }
    if ($RULE_ASSIGNMENT_FORBIDDEN_EXPR_HEADS{$keyword}) {
        confess "Error: rule '$rule_name' action cannot use control-flow form '$keyword'\n";
    }

    confess "Error: rule '$rule_name' assignment actions require '(port expr)'\n"
        unless @$action == 2
            && defined($action->[1]);

    $self->_validate_rule_assignment_expr($action->[1], $rule_name);

    return 1;
}

sub _parse_rule_trigger_params($self, $clause, $rule_name, $transaction_name) {
    confess "Error: rule '$rule_name' trigger '$transaction_name' params require '(params (NAME value) ...)'\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause >= 2
            && defined($clause->[0])
            && !ref($clause->[0])
            && $clause->[0] eq 'params';

    my %seen;
    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: rule '$rule_name' trigger '$transaction_name' params entries require '(NAME value)'\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 2;
        my ($name, $value) = @$entry;
        confess "Error: rule '$rule_name' trigger '$transaction_name' parameter override names must be scalar HDL identifiers\n"
            unless _is_hdl_identifier($name);
        confess "Error: rule '$rule_name' trigger '$transaction_name' has duplicate parameter override '$name'\n"
            if $seen{$name}++;
        confess "Error: rule '$rule_name' trigger '$transaction_name' parameter '$name' value must be defined\n"
            unless defined $value;
    }

    return 1;
}

sub _parse_rule_trigger_bind($self, $clause, $rule_name, $transaction_name) {
    confess "Error: rule '$rule_name' trigger '$transaction_name' bind requires '(bind (input port expr) ...)'\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause >= 2
            && defined($clause->[0])
            && !ref($clause->[0])
            && $clause->[0] eq 'bind';

    my %seen;
    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: rule '$rule_name' trigger '$transaction_name' bind entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 3;
        my ($role, $port, $actor_endpoint) = @$entry;
        confess "Error: rule '$rule_name' trigger '$transaction_name' bind role must be input or output\n"
            unless defined($role) && !ref($role) && ($role eq 'input' || $role eq 'output');
        confess "Error: rule '$rule_name' trigger '$transaction_name' bind port must be a scalar HDL identifier\n"
            unless _is_hdl_identifier($port);
        if ($role eq 'output') {
            confess "Error: rule '$rule_name' trigger '$transaction_name' output bind target must be a scalar HDL identifier\n"
                unless _is_hdl_identifier($actor_endpoint);
        } else {
            confess "Error: rule '$rule_name' trigger '$transaction_name' input bind expression must be a scalar signal, numeric/exact-width literal, or non-empty list expression\n"
                unless _is_activation_input_binding_expr_shape($actor_endpoint);
        }
        confess "Error: rule '$rule_name' trigger '$transaction_name' has duplicate binding for port '$port'\n"
            if $seen{$port}++;
    }

    return 1;
}

sub _validate_rule_assignment_expr($self, $expr, $rule_name) {
    return 1 unless ref($expr);

    confess "Error: rule '$rule_name' assignment RHS expression must be a non-empty list\n"
        unless ref($expr) eq 'ARRAY' && @$expr;

    my $head = $expr->[0];
    confess "Error: rule '$rule_name' assignment expression heads must be scalar\n"
        unless defined($head) && !ref($head) && length($head);

    confess "Error: rule '$rule_name' assignment RHS cannot use control-flow form '$head'\n"
        if $RULE_ASSIGNMENT_FORBIDDEN_EXPR_HEADS{$head};

    for my $operand (@{$expr}[1 .. $#$expr]) {
        $self->_validate_rule_assignment_expr($operand, $rule_name)
            if ref($operand);
    }

    return 1;
}

sub _validate_rule_trigger_targets($self, $actor) {
    my $actor_name = $actor->{actor_name};
    my %transaction_names = map { $_->{name} => 1 } @{$actor->{transactions} || []};

    for my $rule (@{$actor->{rules} || []}) {
        my $rule_name = $rule->{name};
        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY' && @$action;
            next unless defined($action->[0]) && !ref($action->[0]) && $action->[0] eq 'trigger';

            my $target = $action->[1];
            confess "Error: rule '$rule_name' triggers unknown transaction '$target' in actor '$actor_name'\n"
                unless defined($target)
                    && !ref($target)
                    && $transaction_names{$target};
        }
    }

    return 1;
}

sub _validate_rule_priority_targets($self, $actor) {
    my $actor_name = $actor->{actor_name};
    my %rule_names = map { $_->{name} => 1 } @{$actor->{rules} || []};

    for my $rule (@{$actor->{rules} || []}) {
        my $rule_name = $rule->{name};
        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY' && @$action;
            next unless defined($action->[0]) && !ref($action->[0]) && $action->[0] eq 'priority';

            my $target = $action->[2];
            confess "Error: rule '$rule_name' priority targets unknown rule '$target' in actor '$actor_name'\n"
                unless defined($target)
                    && !ref($target)
                    && $rule_names{$target};
        }
    }

    return 1;
}

sub _validate_actor_priority_targets($self, $actor) {
    my $actor_name = $actor->{actor_name};
    my %names = (
        map({ $_->{name} => 1 } @{$actor->{transactions} || []}),
        map({ $_->{name} => 1 } @{$actor->{rules} || []}),
    );

    for my $priority (@{$actor->{priorities} || []}) {
        for my $target ($priority->[0], $priority->[2]) {
            confess "Error: priority target '$target' is not a declared transaction or rule in actor '$actor_name'\n"
                unless defined($target)
                    && !ref($target)
                    && $names{$target};
        }
    }

    return 1;
}

sub _parse_resources($self, $clause) {
    my @resources;
    my %seen;

    for my $i (1 .. $#$clause) {
        my $res = $clause->[$i];
        confess "Error: resource must be a list\n" unless ref($res) eq 'ARRAY';
        my ($kw, $name, @forms) = @$res;
        confess "Error: resource entries require '(resource name (arbiter $RESOURCE_ARBITER_SYNTAX) [(kind kind)] [(users rule...)])'\n"
            unless @$res >= 3
                && defined($kw)
                && !ref($kw)
                && $kw eq 'resource'
                && defined($name)
                && !ref($name)
                && length($name);

        confess "Error: duplicate resource '$name'\n" if $seen{$name}++;

        my %seen_subclause;
        my ($arbiter, $kind);
        my @users;
        my %seen_users;

        for my $form (@forms) {
            confess "Error: resource '$name' subclauses must be list forms\n"
                unless ref($form) eq 'ARRAY' && @$form;
            my $head = $form->[0];
            confess "Error: resource '$name' subclause heads must be scalar\n"
                unless defined($head) && !ref($head) && length($head);
            confess "Error: duplicate resource '$name' subclause '$head'\n"
                if $seen_subclause{$head}++;

            if ($head eq 'arbiter') {
                confess "Error: resource '$name' arbiter requires '(arbiter $RESOURCE_ARBITER_SYNTAX)'\n"
                    unless @$form == 2
                        && defined($form->[1])
                        && !ref($form->[1])
                        && $RESOURCE_ARBITERS{$form->[1]};
                $arbiter = $form->[1];
                next;
            }

            if ($head eq 'kind') {
                confess "Error: resource '$name' kind requires '(kind $RESOURCE_KIND_SYNTAX)'\n"
                    unless @$form == 2
                        && defined($form->[1])
                        && !ref($form->[1])
                        && $RESOURCE_KINDS{$form->[1]};
                $kind = $form->[1];
                next;
            }

            if ($head eq 'users') {
                confess "Error: resource '$name' users requires '(users rule...)'\n"
                    unless @$form >= 2;
                for my $u (@{$form}[1 .. $#$form]) {
                    confess "Error: resource '$name' users must be scalar names\n"
                        unless defined($u) && !ref($u) && length($u);
                    confess "Error: duplicate resource '$name' user '$u'\n"
                        if $seen_users{$u}++;
                    push @users, $u;
                }
                next;
            }

            confess "Error: resource '$name' has unsupported subclause '$head'\n";
        }

        confess "Error: resource '$name' requires '(arbiter $RESOURCE_ARBITER_SYNTAX)'\n"
            unless defined($arbiter);
        confess "Error: resource '$name' with users requires '(kind rule_slot)'\n"
            if @users && !defined($kind);

        my %resource = (name => $name, arbiter => $arbiter);
        $resource{kind} = $kind if defined($kind);
        $resource{users} = \@users if @users;
        push @resources, \%resource;
    }
    return \@resources;
}

sub _validate_resource_user_targets($self, $actor) {
    my $actor_name = $actor->{actor_name};
    my %rule_names = map { $_->{name} => 1 } @{$actor->{rules} || []};

    for my $resource (@{$actor->{resources} || []}) {
        next unless ($resource->{kind} // '') eq 'rule_slot';
        for my $user (@{$resource->{users} || []}) {
            confess "Error: resource '$resource->{name}' user '$user' is not a declared rule in actor '$actor_name'\n"
                unless defined($user)
                    && !ref($user)
                    && $rule_names{$user};
        }
    }

    return 1;
}

sub _validate_storage_actor_names($self, $actor) {
    my $actor_name = $actor->{actor_name};
    my %ports = (
        map({ $_->{name} => 'input' } @{$actor->{interface}{inputs} || []}),
        map({ $_->{name} => 'output' } @{$actor->{interface}{outputs} || []}),
    );

    my %reserved;
    $reserved{$actor->{clock}} = 'clock'
        if defined($actor->{clock}) && length($actor->{clock});
    $reserved{$actor->{reset}{name}} = 'reset'
        if ref($actor->{reset}) eq 'HASH'
            && defined($actor->{reset}{name})
            && length($actor->{reset}{name});
    if (ref($actor->{clock_domains}) eq 'HASH') {
        for my $domain (@{$actor->{clock_domains}{domains} || []}) {
            $reserved{$domain->{clock}} = "clock-domain '$domain->{name}' clock"
                if defined($domain->{clock}) && length($domain->{clock});
            $reserved{$domain->{reset}{name}} = "clock-domain '$domain->{name}' reset"
                if ref($domain->{reset}) eq 'HASH'
                    && defined($domain->{reset}{name})
                    && length($domain->{reset}{name});
        }
    }
    for my $crossing (@{$actor->{crossings} || []}) {
        my $name = $crossing->{name};
        $reserved{$crossing->{from}{signal}} = "crossing event '$name' request"
            if ref($crossing->{from}) eq 'HASH'
                && defined($crossing->{from}{signal})
                && length($crossing->{from}{signal});
        $reserved{$crossing->{to}{signal}} = "crossing event '$name' pulse"
            if ref($crossing->{to}) eq 'HASH'
                && defined($crossing->{to}{signal})
                && length($crossing->{to}{signal});
        $reserved{$crossing->{ready}{signal}} = "crossing event '$name' ready"
            if ref($crossing->{ready}) eq 'HASH'
                && defined($crossing->{ready}{signal})
                && length($crossing->{ready}{signal});
    }
    $reserved{can_accept} = 'scheduler-generated signal';

    for my $entry (@{$actor->{storage} || []}) {
        for my $signal (@{$entry->{signals} || []}) {
            my $name = $signal->{name};
            confess "Error: actor '$actor_name' storage signal '$name' conflicts with interface $ports{$name} port '$name'\n"
                if exists $ports{$name};
            confess "Error: actor '$actor_name' storage signal '$name' conflicts with $reserved{$name} '$name'\n"
                if exists $reserved{$name};
        }
    }

    return 1;
}

sub _parse_priority($self, $clause) {
    confess "Error: (priority ...) requires '(priority lhs over rhs)'\n"
        unless @$clause == 4
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1])
            && defined($clause->[2])
            && !ref($clause->[2])
            && $clause->[2] eq 'over'
            && defined($clause->[3])
            && !ref($clause->[3])
            && length($clause->[3]);

    return [ @{$clause}[1 .. $#$clause] ];
}

sub _parse_drive_def($self, $clause, $drives) {
    confess "Error: (drive ...) requires a name\n" unless @$clause >= 2;
    my $spec = $clause->[1];
    my ($name, @params);
    if (ref($spec) eq 'ARRAY') {
        # Parameterized: (drive (name p1 p2) body...)
        $name = $spec->[0];
        @params = @{$spec}[1 .. $#$spec];
    } else {
        # Simple: (drive name body...)
        $name = $spec;
        @params = ();
    }
    confess "Error: (drive ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);
    my %seen_params;
    for my $param (@params) {
        confess "Error: drive '$name' parameter names must be scalar\n"
            unless defined($param) && !ref($param) && length($param);
        confess "Error: duplicate drive '$name' parameter '$param'\n"
            if $seen_params{$param}++;
    }
    confess "Error: duplicate drive '$name'\n" if exists $drives->{$name};
    my @body = @{$clause}[2 .. $#$clause];
    for my $entry (@body) {
        confess "Error: drive '$name' body entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry;
        confess "Error: drive '$name' body entry heads must be scalar\n"
            unless defined($entry->[0]) && !ref($entry->[0]) && length($entry->[0]);
        confess "Error: drive '$name' body assignments require '(port value)'\n"
            unless @$entry == 2
                && defined($entry->[1])
                && (!ref($entry->[1]) || ref($entry->[1]) eq 'ARRAY');
    }
    $drives->{$name} = { body => \@body, params => \@params };
}

sub _parse_phase($self, $clause) {
    return $self->_parse_named_body_clause($clause, 'phase');
}

sub _parse_stage($self, $clause) {
    return $self->_parse_named_body_clause($clause, 'stage');
}

sub _validate_transaction_phase_stage_clauses($self, $clauses) {
    return unless ref($clauses) eq 'ARRAY';

    for my $clause (@$clauses) {
        next unless ref($clause) eq 'ARRAY' && @$clause;
        my $keyword = $clause->[0];
        next unless defined($keyword) && !ref($keyword);

        if ($keyword eq 'phase' || $keyword eq 'stage') {
            $self->_parse_named_body_clause($clause, $keyword);
        }

        if ($keyword eq 'when' || $keyword eq 'repeat') {
            $self->_validate_transaction_phase_stage_clauses([@{$clause}[2 .. $#$clause]]);
        } elsif ($keyword eq 'switch') {
            for my $branch (@{$clause}[2 .. $#$clause]) {
                next unless ref($branch) eq 'ARRAY';
                $self->_validate_transaction_phase_stage_clauses([@{$branch}[1 .. $#$branch]]);
            }
        }
    }
}

sub _parse_named_body_clause($self, $clause, $kind) {
    confess "Error: ($kind ...) requires a name\n" unless @$clause >= 2;
    my $name = $clause->[1];
    confess "Error: ($kind ...) requires a scalar name\n"
        unless defined($name) && !ref($name) && length($name);

    my @body;
    for my $i (2 .. $#$clause) {
        my $entry = $clause->[$i];
        confess "Error: $kind '$name' body entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry;
        confess "Error: $kind '$name' body entry heads must be scalar\n"
            unless defined($entry->[0]) && !ref($entry->[0]) && length($entry->[0]);
        push @body, $entry;
    }

    return { name => $name, body => \@body };
}

1;
