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
use FSM::Debug;
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
    when switch repeat wait do spawn complete store load
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
#     watchdog      => 65536,
#     interface     => { inputs => [...], outputs => [...] },
#     handshakes    => {}, # deprecated compatibility placeholder; parsed
#                          # handshake clauses are validated then ignored
#     transactions  => [ { name => ..., ports => { inputs => [...], outputs => [...] }, clauses => [...] }, ... ],
#     rules         => [ { name => ..., when => ..., actions => [...] }, ... ],
#     resources     => [ { name => ..., arbiter => ..., kind => ..., users => [...] }, ... ],
#     storage       => [ { kind => "state"|"bank", name => ..., width => ..., depth => ..., signals => [...] }, ... ],
#     priorities    => [ ... ],
#     imports       => [ ... ],
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
        watchdog     => undef,
        interface    => { inputs => [], outputs => [] },
        handshakes   => {},
        transactions => [],
        rules        => [],
        resources    => [],
        storage      => [],
        priorities   => [],
        drives       => {},
        phases       => [],
        stages       => [],
        params       => [],
        imports      => [],
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
                $result->{imports} = $self->_parse_imports($clause, $actor_name);
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

    $self->_validate_rule_trigger_targets($result);
    $self->_validate_rule_priority_targets($result);
    $self->_validate_actor_priority_targets($result);
    $self->_validate_resource_user_targets($result);
    $self->_validate_storage_actor_names($result);

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
        _validate_isf_param_value(
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

sub _parse_imports($self, $clause, $actor_name) {
    my @imports;
    my %seen_alias;

    confess "Error: actor '$actor_name' imports require '(imports (library name [as alias]) ...)'\n"
        unless @$clause >= 2;

    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' import entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry;
        confess "Error: actor '$actor_name' import entries require '(library name [as alias])'\n"
            unless (@$entry == 2 || @$entry == 4)
                && defined($entry->[0])
                && !ref($entry->[0])
                && $entry->[0] eq 'library'
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

        confess "Error: actor '$actor_name' has duplicate library import alias '$alias'\n"
            if $seen_alias{$alias}++;

        push @imports, {
            library => $library,
            alias   => $alias,
        };
    }

    return \@imports;
}

sub _parse_use($self, $clause, $actor_name) {
    confess "Error: actor '$actor_name' use requires '(use alias.actor as instance [(params ...)] (bind ...))'\n"
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
    }
    return 1;
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

sub _is_library_namespace {
    my ($value) = @_;
    return defined($value)
        && !ref($value)
        && $value =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\z/;
}

sub _validate_isf_param_value {
    my ($value, $context) = @_;
    if (!ref($value)) {
        confess "$context uses unsupported parameter value '$value'; first ISF library parameter binding accepts numeric, exact-width, and aggregate/list literals only\n"
            unless defined($value) && _is_numeric_or_exact_width_literal($value);
        return 1;
    }

    confess "$context uses unsupported parameter value shape; first ISF library parameter binding accepts non-empty aggregate/list literals only\n"
        unless ref($value) eq 'ARRAY' && @$value;

    for my $item (@$value) {
        _validate_isf_param_value($item, $context);
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

        confess "Error: interface port direction must be input or output\n"
            unless defined($dir) && !ref($dir) && ($dir eq 'input' || $dir eq 'output');
        confess "Error: interface port requires a scalar name\n"
            unless defined($name) && !ref($name) && length($name);
        confess "Error: duplicate interface port '$name'\n" if $seen_names{$name}++;

        # Check for (width N) in remaining elements
        for my $j (2 .. $#$port) {
            my $prop = $port->[$j];
            if (ref($prop) eq 'ARRAY' && $prop->[0] eq 'width') {
                confess "Error: interface port '$name' width must be a positive integer\n"
                    unless @$prop == 2
                        && defined($prop->[1])
                        && !ref($prop->[1])
                        && $prop->[1] =~ /\A[1-9][0-9]*\z/;
                $width = $prop->[1];
            }
        }

        my $entry = { name => $name, width => $width };
        if ($dir eq 'input')  { push @inputs,  $entry; }
        if ($dir eq 'output') { push @outputs, $entry; }
    }

    return { inputs => \@inputs, outputs => \@outputs };
}

sub _parse_storage($self, $clause, $actor_name) {
    confess "Error: actor '$actor_name' storage requires '(storage (state name (width N)) ...)' entries\n"
        unless @$clause >= 2;

    my @entries;
    my %seen_logical_name;
    my %seen_signal_name;

    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: actor '$actor_name' storage entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry;

        my ($kind, $name, @options) = @$entry;
        confess "Error: actor '$actor_name' storage entry kind must be 'state' or 'bank'\n"
            unless defined($kind) && !ref($kind) && ($kind eq 'state' || $kind eq 'bank');
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
            if ($option_name eq 'depth') {
                $parsed_options{depth_value} = _parse_storage_positive_integer_option(
                    $option,
                    "Error: actor '$actor_name' storage '$name' depth",
                );
                next;
            }

            confess "Error: actor '$actor_name' storage '$name' has unsupported option '$option_name'\n";
        }

        my $width = $parsed_options{width_value};
        confess "Error: actor '$actor_name' storage '$name' requires '(width N)'\n"
            unless defined($width);

        my @signals;
        if ($kind eq 'state') {
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
    }

    return \@entries;
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

        push @clauses, $body_clause;
    }
    $self->_validate_transaction_phase_stage_clauses(\@clauses);

    return { name => $name, ports => $ports, clauses => \@clauses };
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

            confess "Error: transaction '$transaction_name' port '$name' has unsupported option '$option_name'\n";
        }

        my $parsed = { name => $name, width => $width };
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

    return { name => $name, when => $when, actions => \@actions };
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
        confess "Error: rule '$rule_name' trigger requires '(trigger transaction [(bind ...)])'\n"
            unless (@$action == 2 || @$action == 3)
                && defined($action->[1])
                && !ref($action->[1])
                && length($action->[1]);
        $self->_parse_rule_trigger_bind($action->[2], $rule_name, $action->[1])
            if @$action == 3;
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
    if ($RULE_ASSIGNMENT_FORBIDDEN_EXPR_HEADS{$keyword}) {
        confess "Error: rule '$rule_name' action cannot use control-flow form '$keyword'\n";
    }

    confess "Error: rule '$rule_name' assignment actions require '(port expr)'\n"
        unless @$action == 2
            && defined($action->[1]);

    $self->_validate_rule_assignment_expr($action->[1], $rule_name);

    return 1;
}

sub _parse_rule_trigger_bind($self, $clause, $rule_name, $transaction_name) {
    confess "Error: rule '$rule_name' trigger '$transaction_name' bind requires '(bind (input port signal) ...)'\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause >= 2
            && defined($clause->[0])
            && !ref($clause->[0])
            && $clause->[0] eq 'bind';

    my %seen;
    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "Error: rule '$rule_name' trigger '$transaction_name' bind entries must be list forms\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 3;
        my ($role, $port, $signal) = @$entry;
        confess "Error: rule '$rule_name' trigger '$transaction_name' bind role must be input or output\n"
            unless defined($role) && !ref($role) && ($role eq 'input' || $role eq 'output');
        confess "Error: rule '$rule_name' trigger '$transaction_name' bind port must be a scalar HDL identifier\n"
            unless _is_hdl_identifier($port);
        confess "Error: rule '$rule_name' trigger '$transaction_name' bind signal must be a scalar HDL identifier\n"
            unless _is_hdl_identifier($signal);
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
                && !ref($entry->[1]);
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
