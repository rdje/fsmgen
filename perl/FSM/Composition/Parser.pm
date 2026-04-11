package FSM::Composition::Parser;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Composition::Spec;
use FSM::Composition::Top;
use FSM::Composition::Instance;
use FSM::Composition::Port;
use FSM::Composition::PortWidthResolver;
use FSM::Composition::Link;
use FSM::Composition::PortsBlock;
use FSM::Composition::TopLink;
use FSM::Composition::TopSymbols;
use FSM::Package::DeclarativeTypeSupport;
use FSM::Package::DeclarativeSymbolResolver;
use FSM::Package::DeclarativeTypeResolver;
use FSM::Package::Symbols;
use FSM::Package::SignalManagerProjectionSupport;

sub new ($class, %args) {
    return bless {
        debug => $args{debug} // 0,
    }, $class;
}

sub scope_docs_suffix ($self) {
    return " See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md";
}

sub parse_source ($self, $raw_ast) {
    my $top_ast = $self->find_top_root($raw_ast);
    confess "Expected composition source containing '?top:name'" unless $top_ast;

    my $top = $self->parse_top($top_ast);
    my $embedded_fsm_sources = $self->collect_embedded_fsm_sources($raw_ast);
    my $embedded_dt_sources = $self->collect_embedded_dt_sources($raw_ast);
    my $embedded_package_sources = $self->collect_embedded_package_sources($raw_ast);

    return FSM::Composition::Spec->new(
        top => $top,
        embedded_fsm_sources => $embedded_fsm_sources,
        embedded_dt_sources => $embedded_dt_sources,
        embedded_package_sources => $embedded_package_sources,
        raw_ast => $raw_ast,
    );
}

sub find_top_root ($self, $raw_ast) {
    return undef unless ref($raw_ast) eq 'ARRAY';

    if (@$raw_ast > 0 && !ref($raw_ast->[0]) && $raw_ast->[0] =~ /^\?top:/) {
        return $raw_ast;
    }

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY';
        next unless @$ast_node > 0;
        next if ref($ast_node->[0]);
        return $ast_node if $ast_node->[0] =~ /^\?top:/;
    }

    return undef;
}

sub parse_top ($self, $top_ast) {
    my ($header, $children) = @$top_ast;
    my $top_name = $self->decode_top_name($header);

    $children ||= [];
    confess "Composition top '$top_name' must contain a child list" unless ref($children) eq 'ARRAY';

    my @instances;
    my @ports_blocks;
    my @pending_ports_blocks;
    my @toplinks;
    my @package_imports;
    my $top_symbols = FSM::Composition::TopSymbols->new();
    my @pending_constant_entries;
    my @pending_enum_entries;
    my @pending_type_entries;
    my @inline_top_items;
    my $symbol_manager = FSM::Adapter::FSMGenFull::SignalManager->new(
        debug => ($self->{debug} ? 1 : 0),
    );
    my $expression_builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(
        debug => ($self->{debug} ? 1 : 0),
        signal_manager => $symbol_manager,
    );

    for my $child (@$children) {
        if (!ref($child)) {
            push @inline_top_items, $child;
            next;
        }

        confess "Composition top '$top_name' contains a non-list child item" unless ref($child) eq 'ARRAY';

        if (@$child && defined($child->[0]) && !ref($child->[0]) && $child->[0] eq '+constants') {
            push @pending_constant_entries, @{ $self->parse_top_constants_block(
                $top_name,
                $child,
                $top_symbols,
            ) };
            next;
        }

        if (@$child && defined($child->[0]) && !ref($child->[0]) && $child->[0] eq '+enums') {
            push @pending_enum_entries, @{ $self->parse_top_enums_block(
                $top_name,
                $child,
                $top_symbols,
            ) };
            next;
        }

        if (@$child && defined($child->[0]) && !ref($child->[0]) && $child->[0] eq '+types') {
            push @pending_type_entries, @{ $self->parse_top_types_block(
                $top_name,
                $child,
                $top_symbols,
            ) };
            next;
        }

        if (@$child && defined($child->[0]) && !ref($child->[0]) && $child->[0] eq '+import') {
            push @package_imports, @{$self->parse_top_import_block($top_name, $child)};
            next;
        }

        if (@$child && defined($child->[0]) && !ref($child->[0]) && $child->[0] =~ /^\?ports(?::(\w*))?$/) {
            my $items = $child->[1] // [];
            confess
                "Composition top '$top_name' contains child '$child->[0]', ".
                "but composition child item-list shape is blocked because that child does not contain a proper item list.".
                $self->scope_docs_suffix
                unless ref($items) eq 'ARRAY';
            confess
                "Composition top '$top_name' contains child '$child->[0]', ".
                "but composition child item-list shape is blocked because dotted-pair payloads are outside the current active composition parser contract.".
                $self->scope_docs_suffix
                if @$items && !ref($items->[0]) && $items->[0] eq '.';
            push @pending_ports_blocks, [
                $child,
                (defined($1) && length($1) ? $1 : undef),
                $items,
            ];
            next;
        }

        my ($kind, $parsed_child) = $self->parse_top_child($top_name, $child);

        if ($kind eq 'instance') {
            push @instances, $parsed_child;
        } elsif ($kind eq 'ports') {
            push @ports_blocks, $parsed_child;
        } elsif ($kind eq 'toplink') {
            push @toplinks, $parsed_child;
        } else {
            confess "Internal error: unknown parsed composition child kind '$kind'";
        }
    }

    $self->resolve_pending_top_types(
        $top_name,
        $top_symbols,
        $symbol_manager,
        \@pending_type_entries,
    );

    $self->resolve_pending_top_symbols(
        $top_name,
        $top_symbols,
        $symbol_manager,
        $expression_builder,
        \@pending_constant_entries,
        \@pending_enum_entries,
    );

    for my $pending_ports (@pending_ports_blocks) {
        my ($child_ast, $block_name, $items) = @$pending_ports;
        push @ports_blocks, $self->parse_ports_block($top_name, $child_ast, $block_name, $items, $top_symbols);
    }

    if (@inline_top_items) {
        my $rendered = join ', ', @inline_top_items;
        confess
            "Composition top '$top_name' uses legacy inline top-port shorthand ($rendered), ".
            "but the active R6 composition parser only supports explicit '?ports' blocks.".
            $self->scope_docs_suffix;
    }

    return FSM::Composition::Top->new(
        name => $top_name,
        instances => \@instances,
        ports_blocks => \@ports_blocks,
        toplinks => \@toplinks,
        package_imports => \@package_imports,
        top_symbols => $top_symbols,
        raw_ast => $top_ast,
    );
}

sub parse_top_child ($self, $top_name, $child_ast) {
    confess
        "Composition top '$top_name' contains a child entry that is empty or missing its header, ".
        "but composition child structure is blocked because every child must start with a real string header such as '?fsmc:name', '?dtc:name', '?rtl:module', '?ports', '?toplink:name', '+constants', '+enums', '+types', or '+import'.".
        $self->scope_docs_suffix
        unless @$child_ast;

    my $header = $child_ast->[0];
    confess
        "Composition top '$top_name' contains a child entry that is empty or missing its header, ".
        "but composition child structure is blocked because every child must start with a real string header such as '?fsmc:name', '?dtc:name', '?rtl:module', '?ports', '?toplink:name', '+constants', '+enums', '+types', or '+import'.".
        $self->scope_docs_suffix
        unless defined($header) && length($header);
    confess
        "Composition top '$top_name' contains a child entry that does not begin with a string header, ".
        "but composition child header shape is blocked because every child must start with a real string header such as '?fsmc:name', '?dtc:name', '?rtl:module', '?ports', '?toplink:name', '+constants', '+enums', '+types', or '+import'.".
        $self->scope_docs_suffix
        if ref($header);

    my $items = $child_ast->[1] // [];
    confess
        "Composition top '$top_name' contains child '$header', ".
        "but composition child item-list shape is blocked because that child does not contain a proper item list.".
        $self->scope_docs_suffix
        unless ref($items) eq 'ARRAY';
    confess
        "Composition top '$top_name' contains child '$header', ".
        "but composition child item-list shape is blocked because dotted-pair payloads are outside the current active composition parser contract.".
        $self->scope_docs_suffix
        if @$items && !ref($items->[0]) && $items->[0] eq '.';

    if ($header =~ /^\?fsmc(?::(\w*))?$/) {
        my $child_name = defined($1) && length($1) ? $1 : undef;
        return ('instance', $self->parse_fsmc_child($top_name, $child_ast, $child_name, $items));
    }
    if ($header =~ /^\?dtc(?::(\w*))?$/) {
        my $child_name = defined($1) && length($1) ? $1 : undef;
        return ('instance', $self->parse_dtc_child($top_name, $child_ast, $child_name, $items));
    }
    if ($header =~ /^\?rtl:(\w+)$/) {
        return ('instance', $self->parse_rtl_child($top_name, $child_ast, $1, $items));
    }
    if ($header =~ /^\?ports(?::(\w*))?$/) {
        my $block_name = defined($1) && length($1) ? $1 : undef;
        return ('ports', $self->parse_ports_block($top_name, $child_ast, $block_name, $items));
    }
    if ($header =~ /^\?toplink:(\w+)$/) {
        return ('toplink', $self->parse_toplink_block($top_name, $child_ast, $1, $items));
    }
    if ($header =~ /^\?&/) {
        confess
            "Composition top '$top_name' contains legacy macro/plugin child '$header', ".
            "but macro/plugin-oriented composition constructs are outside the active R6 composition scope.".
            $self->scope_docs_suffix;
    }
    if ($header =~ /^\?top:/) {
        confess
            "Composition top '$top_name' contains nested top '$header', ".
            "but nested '?top:name' blocks are outside the first active R6 composition lane.".
            $self->scope_docs_suffix;
    }

    confess
        "Composition top '$top_name' contains child '$header', ".
        "but composition child kind support is blocked because the active composition parser currently accepts only '?fsmc', '?dtc', '?rtl', '?ports', '?toplink', '+constants', '+enums', '+types', and '+import'.".
        $self->scope_docs_suffix;
}

sub parse_top_constants_block ($self, $top_name, $child_ast, $top_symbols) {
    my (undef, $constants_list) = @$child_ast;

    confess
        "Composition top '$top_name' contains malformed '+constants' section, ".
        "but composition top symbol section shape is blocked because '+constants' currently requires a non-empty list of '(NAME value)' entries where the value is either a literal scalar, a non-empty list aggregate, or a non-empty hash-like aggregate.".
        $self->scope_docs_suffix
        unless ref($constants_list) eq 'ARRAY' && @$constants_list;

    my @constant_entries;
    for my $constant_def (@$constants_list) {
        confess
            "Composition top '$top_name' contains malformed '+constants' entry, ".
            "but composition top symbol entry shape is blocked because each '+constants' entry must be a pair '(NAME value)'.".
            $self->scope_docs_suffix
            unless ref($constant_def) eq 'ARRAY' && @$constant_def == 2;

        my ($name, $value) = @$constant_def;
        my $resolved_name = $self->unwrap_scalar_token($name);

        confess
            "Composition top '$top_name' contains malformed '+constants' entry for constant '".$self->describe_contract_name($resolved_name)."', ".
            "but composition top symbol token shape is blocked because each '+constants' entry must use an HDL-identifier-compatible name.".
            $self->scope_docs_suffix
            unless $self->is_contract_identifier($resolved_name);

        push @constant_entries, {
            name => $resolved_name,
            value_ast => $value,
        };
    }

    $top_symbols->push_raw_block($child_ast);
    return \@constant_entries;
}

sub parse_top_enums_block ($self, $top_name, $child_ast, $top_symbols) {
    my (undef, $enums_list) = @$child_ast;

    confess
        "Composition top '$top_name' contains malformed '+enums' section, ".
        "but composition top symbol section shape is blocked because '+enums' currently requires a non-empty list of '(enum_name (MEMBER value) ...)' definitions.".
        $self->scope_docs_suffix
        unless ref($enums_list) eq 'ARRAY' && @$enums_list;

    my @enum_entries;
    for my $enum_def (@$enums_list) {
        confess
            "Composition top '$top_name' contains malformed '+enums' definition, ".
            "but composition top symbol entry shape is blocked because each '+enums' definition must use the shape '(enum_name (MEMBER value) ...)'.".
            $self->scope_docs_suffix
            unless ref($enum_def) eq 'ARRAY' && @$enum_def == 2;

        my ($enum_name, $members_list) = @$enum_def;
        my $resolved_enum_name = $self->unwrap_scalar_token($enum_name);

        confess
            "Composition top '$top_name' contains malformed '+enums' definition for enum '".$self->describe_contract_name($resolved_enum_name)."', ".
            "but composition top symbol token shape is blocked because each '+enums' definition must use an HDL-identifier-compatible enum name and at least one '(MEMBER value)' entry.".
            $self->scope_docs_suffix
            unless $self->is_contract_identifier($resolved_enum_name)
                && ref($members_list) eq 'ARRAY'
                && @$members_list;

        my @member_entries;
        for my $member_def (@$members_list) {
            confess
                "Composition top '$top_name' contains malformed '+enums' member for enum '$resolved_enum_name', ".
                "but composition top symbol entry shape is blocked because each enum member must be a pair '(MEMBER value)'.".
                $self->scope_docs_suffix
                unless ref($member_def) eq 'ARRAY' && @$member_def == 2;

            my ($member_name, $member_value) = @$member_def;
            my $resolved_member_name = $self->unwrap_scalar_token($member_name);
            my $resolved_member_value = $self->unwrap_scalar_token($member_value);

            confess
                "Composition top '$top_name' contains malformed '+enums' member '".$self->describe_contract_name($resolved_member_name)."' for enum '$resolved_enum_name', ".
                "but composition top symbol token shape is blocked because each enum member must use an HDL-identifier-compatible member name and a scalar value token.".
                $self->scope_docs_suffix
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

    $top_symbols->push_raw_block($child_ast);
    return \@enum_entries;
}

sub parse_top_types_block ($self, $top_name, $child_ast, $top_symbols) {
    my (undef, $types_list) = @$child_ast;

    confess
        "Composition top '$top_name' contains malformed '+types' section, ".
        "but composition top type section shape is blocked because '+types' currently requires a non-empty list of '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', '(type NAME (list ...))', '(type NAME (record (field TYPE) ...))', or '(type NAME other_type)' entries.".
        $self->scope_docs_suffix
        unless ref($types_list) eq 'ARRAY' && @$types_list;

    my @type_entries;
    for my $type_def (@$types_list) {
        confess
            "Composition top '$top_name' contains malformed '+types' entry, ".
            "but composition top type entry shape is blocked because each '+types' entry must use the shape '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', '(type NAME (list ...))', '(type NAME (record (field TYPE) ...))', or '(type NAME other_type)'.".
            $self->scope_docs_suffix
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
            confess
                "Composition top '$top_name' contains malformed '+types' entry, ".
                "but composition top type entry shape is blocked because each '+types' entry must use the shape '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', '(type NAME (list ...))', '(type NAME (record (field TYPE) ...))', or '(type NAME other_type)'.".
                $self->scope_docs_suffix;
        }

        my $resolved_keyword = $self->unwrap_scalar_token($keyword);
        my $resolved_name = $self->unwrap_scalar_token($name);

        confess
            "Composition top '$top_name' contains malformed '+types' entry for type '".$self->describe_contract_name($resolved_name)."', ".
            "but composition top type token shape is blocked because each '+types' entry must begin with the literal keyword 'type' and use an HDL-identifier-compatible type name.".
            $self->scope_docs_suffix
            unless defined($resolved_keyword)
                && !ref($resolved_keyword)
                && $resolved_keyword eq 'type'
                && $self->is_contract_identifier($resolved_name);

        push @type_entries, {
            name => $resolved_name,
            spec_ast => $spec_ast,
        };
    }

    $top_symbols->push_raw_block($child_ast);
    return \@type_entries;
}

sub resolve_pending_top_symbols ($self, $top_name, $top_symbols, $symbol_manager, $expression_builder, $constant_entries, $enum_entries) {
    $constant_entries ||= [];
    $enum_entries ||= [];
    return 1 unless @$constant_entries || @$enum_entries;

    FSM::Package::DeclarativeSymbolResolver->resolve_symbols(
        constant_entries => $constant_entries,
        enum_entries => $enum_entries,
        value_items => sub ($value_ast) { return $self->top_value_items($value_ast) },
        unwrap_scalar_token => sub ($value) { return $self->unwrap_scalar_token($value) },
        is_contract_identifier => sub ($value) { return $self->is_contract_identifier($value) },
        resolve_constant_payload => sub ($entry) {
            return $self->canonicalize_top_constant_payload(
                top_name => $top_name,
                section_header => '+constants',
                symbol_kind => 'constant',
                symbol_name => $entry->{name},
                value_ast => $entry->{value_ast},
                expression_builder => $expression_builder,
            );
        },
        resolve_enum_member_payload => sub ($enum_entry, $member_entry) {
            return $self->canonicalize_top_symbol_literal_payload(
                top_name => $top_name,
                section_header => '+enums',
                symbol_kind => 'enum member',
                symbol_name => $enum_entry->{name}.'.'.$member_entry->{name},
                value_token => $member_entry->{value_token},
                expression_builder => $expression_builder,
            );
        },
        store_constant => sub ($name, $payload) {
            $top_symbols->store_constant($name, $payload);
            FSM::Package::SignalManagerProjectionSupport->project_symbols_into_signal_manager(
                signal_manager => $symbol_manager,
                symbols => FSM::Package::Symbols->new(
                    constants => {
                        $name => $payload,
                    },
                ),
                expression_builder => $expression_builder,
            );
            return $payload;
        },
        store_enum => sub ($enum_name, $members_hashref) {
            $top_symbols->store_enum($enum_name, $members_hashref);
            FSM::Package::SignalManagerProjectionSupport->project_symbols_into_signal_manager(
                signal_manager => $symbol_manager,
                symbols => FSM::Package::Symbols->new(
                    enums => {
                        $enum_name => $members_hashref,
                    },
                ),
                expression_builder => $expression_builder,
            );
            return $members_hashref;
        },
        cycle_error => sub (%cycle) {
            my @chain = map {
                my $node_type = $_->{type} eq 'enum' ? 'enum' : 'constant';
                $node_type . " '" . ($_->{name} // 'unknown') . "'";
            } @{ $cycle{chain} || [] };

            confess
                "Composition top '$top_name' contains a declarative symbol dependency cycle, ".
                "but composition top symbol scope now resolves normal non-cyclic '+constants'/'+enums' references without depending on declaration order and still blocks cycles explicitly. ".
                "Cycle: ".join(' -> ', @chain).".".
                $self->scope_docs_suffix;
        },
    );

    return 1;
}

sub resolve_pending_top_types ($self, $top_name, $top_symbols, $symbol_manager, $type_entries) {
    $type_entries ||= [];
    return 1 unless @$type_entries;

    FSM::Package::DeclarativeTypeResolver->resolve_types(
        type_entries => $type_entries,
        unwrap_scalar_token => sub ($value) { return $self->unwrap_scalar_token($value) },
        unwrap_single_nested_list => sub ($value) { return $self->unwrap_single_nested_list($value) },
        is_contract_identifier => sub ($value) { return $self->is_contract_identifier($value) },
        resolve_type_spec => sub ($entry) {
            return $self->canonicalize_top_type_spec(
                top_name => $top_name,
                type_name => $entry->{name},
                spec_ast => $entry->{spec_ast},
                top_symbols => $top_symbols,
                allow_unresolved_imported_type_refs => 1,
            );
        },
        store_type => sub ($type_name, $type_spec) {
            $top_symbols->store_type($type_name, $type_spec);
            FSM::Package::SignalManagerProjectionSupport->project_symbols_into_signal_manager(
                signal_manager => $symbol_manager,
                symbols => FSM::Package::Symbols->new(
                    types => {
                        $type_name => $type_spec,
                    },
                ),
            );
            return $type_spec;
        },
        cycle_error => sub (%cycle) {
            my @chain = map {
                "type '" . ($_->{name} // 'unknown') . "'";
            } @{ $cycle{chain} || [] };

            confess
                "Composition top '$top_name' contains a declarative type dependency cycle, ".
                "but composition top type scope now resolves normal non-cyclic type aliases without depending on declaration order and still blocks cycles explicitly. ".
                "Cycle: ".join(' -> ', @chain).".".
                $self->scope_docs_suffix;
        },
    );

    return 1;
}

sub parse_top_import_block ($self, $top_name, $child_ast) {
    my (undef, $imports_list) = @$child_ast;

    confess
        "Composition top '$top_name' contains malformed '+import' section, ".
        "but composition package-import section shape is blocked because '+import' currently requires a non-empty list of package names."
        . $self->scope_docs_suffix
        unless ref($imports_list) eq 'ARRAY' && @$imports_list;

    my @package_names;
    for my $package_name (@$imports_list) {
        my $resolved_name = $self->unwrap_scalar_token($package_name);
        confess
            "Composition top '$top_name' contains malformed '+import' package name '".$self->describe_contract_name($resolved_name)."', ".
            "but composition package-import token shape is blocked because each imported package name must be an HDL-identifier-compatible bare name."
            . $self->scope_docs_suffix
            unless $self->is_contract_identifier($resolved_name);
        push @package_names, $resolved_name;
    }

    return \@package_names;
}

sub parse_fsmc_child ($self, $top_name, $child_ast, $child_name, $items) {
    my @scalar_items = grep { !ref($_) } @$items;
    my @non_scalar_items = grep { ref($_) } @$items;

    if (@non_scalar_items) {
        confess
            "Composition top '$top_name' contains '?fsmc' child ".
            ($child_name ? "'$child_name'" : 'without a name').
            ", but composition child source shape is blocked because the active composition parser currently requires exactly one flat FSM source name per '?fsmc'.".
            $self->scope_docs_suffix;
    }

    if (!@scalar_items && $child_name) {
        return FSM::Composition::Instance->new(
            kind => 'fsmc',
            name => $child_name,
            source_name => $child_name,
            raw_items => $items,
            raw_ast => $child_ast,
        );
    }

    if (@scalar_items != 1) {
        my $count = scalar(@scalar_items);
        confess
            "Composition top '$top_name' contains '?fsmc' child ".
            ($child_name ? "'$child_name'" : 'without a name').
            " with $count FSM source names, but composition child source count is blocked because the active composition parser currently requires exactly one FSM source name per '?fsmc'.".
            $self->scope_docs_suffix;
    }

    return FSM::Composition::Instance->new(
        kind => 'fsmc',
        name => $child_name,
        source_name => $scalar_items[0],
        raw_items => $items,
        raw_ast => $child_ast,
    );
}

sub parse_dtc_child ($self, $top_name, $child_ast, $child_name, $items) {
    my @scalar_items = grep { !ref($_) } @$items;
    my @non_scalar_items = grep { ref($_) } @$items;

    if (@non_scalar_items) {
        confess
            "Composition top '$top_name' contains '?dtc' child ".
            ($child_name ? "'$child_name'" : 'without a name').
            ", but composition child source shape is blocked because the active composition parser currently requires exactly one flat standalone-DT source name per '?dtc'.".
            $self->scope_docs_suffix;
    }

    if (!@scalar_items && $child_name) {
        return FSM::Composition::Instance->new(
            kind => 'dtc',
            name => $child_name,
            source_name => $child_name,
            raw_items => $items,
            raw_ast => $child_ast,
        );
    }

    if (@scalar_items != 1) {
        my $count = scalar(@scalar_items);
        confess
            "Composition top '$top_name' contains '?dtc' child ".
            ($child_name ? "'$child_name'" : 'without a name').
            " with $count standalone-DT source names, but composition child source count is blocked because the active composition parser currently requires exactly one standalone-DT source name per '?dtc'.".
            $self->scope_docs_suffix;
    }

    return FSM::Composition::Instance->new(
        kind => 'dtc',
        name => $child_name,
        source_name => $scalar_items[0],
        raw_items => $items,
        raw_ast => $child_ast,
    );
}

sub parse_rtl_child ($self, $top_name, $child_ast, $child_name, $items) {
    my @scalar_items = grep { !ref($_) } @$items;
    my @non_scalar_items = grep { ref($_) } @$items;

    if (@non_scalar_items) {
        confess
            "Composition top '$top_name' contains '?rtl' child '$child_name', ".
            "but composition external-RTL child source shape is blocked because the active composition parser currently accepts either '(?rtl:module)' or '(?rtl:instance module)' as the flat RTL child declaration form. ".
            "Parameter/generic override blocks are planned as a separate semantic instantiation contract and are not accepted in '?rtl' child payloads yet.".
            $self->scope_docs_suffix;
    }

    if (!@scalar_items) {
        return FSM::Composition::Instance->new(
            kind => 'rtl',
            module_name => $child_name,
            raw_items => $items,
            raw_ast => $child_ast,
        );
    }

    if (@scalar_items != 1 || $scalar_items[0] !~ /^\w+$/) {
        my $count = scalar(@scalar_items);
        confess
            "Composition top '$top_name' contains '?rtl' child '$child_name' with $count RTL module references, ".
            "but composition external-RTL child source count is blocked because the active composition parser currently accepts exactly one flat RTL module name after '?rtl:instance' when an explicit instance name is needed. ".
            "Use '(?rtl:$child_name module_name)' for instance aliasing, or '(?rtl:module_name)' when the instance name should match the module name.".
            $self->scope_docs_suffix;
    }

    return FSM::Composition::Instance->new(
        kind => 'rtl',
        name => $child_name,
        module_name => $scalar_items[0],
        raw_items => $items,
        raw_ast => $child_ast,
    );
}

sub parse_ports_block ($self, $top_name, $child_ast, $block_name, $items, $top_symbols = undef) {
    my @ports;

    for my $item (@$items) {
        confess "Composition top '$top_name' contains a nested '?ports' item, ".
            "but composition port declaration flatness is blocked because the active composition parser only supports flat explicit port tokens.".
            $self->scope_docs_suffix
            if ref($item);

        if ($item =~ m{^/} || $item =~ /^\{/) {
            confess
                "Composition top '$top_name' contains '?ports' mapping directive '$item', ".
                "but composition port declaration mode is blocked because the active composition parser only supports explicit top-port declarations inside '?ports'.".
                $self->scope_docs_suffix;
        }

        push @ports, $self->parse_port_token($top_name, $item, $top_symbols);
    }

    return FSM::Composition::PortsBlock->new(
        name => $block_name,
        ports => \@ports,
        raw_ast => $child_ast,
    );
}

sub parse_port_token ($self, $top_name, $token, $top_symbols = undef) {
    $token =~ /^(?<binding>=)?(?<port>\w+)(?:(?<direction>[<>])(?<size>(?:[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?|\d+))?(?:[:](?<type>\w+))?)?$/o;
    my ($binding, $port, $direction, $size, $type) = @+{qw/binding port direction size type/};

    confess "Composition top '$top_name' contains '?ports' token '$token', ".
        "but composition port token shape is blocked because it is not a valid explicit top-port token for the current active contract.".
        $self->scope_docs_suffix
        unless $port;
    my $resolved_contract = {
        width => 1,
        signed => 0,
        state_model => undef,
    };
    if (defined $direction) {
        $resolved_contract = FSM::Composition::PortWidthResolver->resolve_port_contract(
            top_name => $top_name,
            token => $token,
            width_token => $size,
            top_symbols => $top_symbols,
            docs_hint => $self->scope_docs_suffix,
            allow_unresolved_imported_type_refs => 1,
        );
    }

    return FSM::Composition::Port->new(
        name => $port,
        direction => defined($direction) ? ($direction eq '<' ? 'input' : 'output') : 'input',
        width => $resolved_contract->{width},
        width_token => $size,
        signed => ($resolved_contract->{signed} // 0),
        state_model => $resolved_contract->{state_model},
        declared_type_name => $resolved_contract->{declared_type_name},
        declared_type_spec => $resolved_contract->{declared_type_spec},
        type => $type,
        binding_mode => defined($binding) ? 'connect_by_name' : 'explicit',
        raw_token => $token,
        origin_kind => defined($binding) ? 'declared_connect_by_name_port' : 'declared_explicit_port',
    );
}

sub parse_toplink_block ($self, $top_name, $child_ast, $block_name, $items) {
    my @links;

    for my $item (@$items) {
        confess "Composition top '$top_name' contains a nested '?toplink' item, ".
            "but explicit top-link token flatness is blocked because the active composition parser only supports flat '/source/target/' link tokens.".
            $self->scope_docs_suffix
            if ref($item);

        if ($item =~ m{^/([^/]+)/([^/]+)/$}) {
            push @links, FSM::Composition::Link->new(
                source => $1,
                target => $2,
                raw_token => $item,
                origin_kind => 'declared_explicit_toplink',
            );
            next;
        }

        confess
            "Composition top '$top_name' contains '?toplink' token '$item', ".
            "but explicit top-link token shape is blocked because the current parser only accepts simple '/source/target/' link forms.".
            $self->scope_docs_suffix;
    }

    return FSM::Composition::TopLink->new(
        name => $block_name,
        links => \@links,
        raw_ast => $child_ast,
    );
}

sub collect_embedded_fsm_sources ($self, $raw_ast) {
    my %embedded_fsm_sources;
    return \%embedded_fsm_sources unless ref($raw_ast) eq 'ARRAY';

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY';
        next unless @$ast_node > 0;
        next if ref($ast_node->[0]);
        next unless $ast_node->[0] =~ /^\?fsm:/;
        my $fsm_name = $self->decode_embedded_fsm_source_name($ast_node->[0]);
        next unless $fsm_name;
        $embedded_fsm_sources{$fsm_name} = $ast_node;
    }

    return \%embedded_fsm_sources;
}

sub collect_embedded_dt_sources ($self, $raw_ast) {
    my %embedded_dt_sources;
    return \%embedded_dt_sources unless ref($raw_ast) eq 'ARRAY';

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY';
        next unless @$ast_node > 0;
        next if ref($ast_node->[0]);
        next unless $ast_node->[0] =~ /^\?(?:dt|mod|module):/;
        my $dt_name = $self->decode_embedded_dt_source_name($ast_node->[0]);
        next unless $dt_name;
        $embedded_dt_sources{$dt_name} = $ast_node;
    }

    return \%embedded_dt_sources;
}

sub collect_embedded_package_sources ($self, $raw_ast) {
    my %embedded_package_sources;
    return \%embedded_package_sources unless ref($raw_ast) eq 'ARRAY';

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY';
        next unless @$ast_node > 0;
        next if ref($ast_node->[0]);
        next unless $ast_node->[0] =~ /^\?pkg:/;
        my $package_name = $self->decode_embedded_package_source_name($ast_node->[0]);
        next unless $package_name;
        $embedded_package_sources{$package_name} = $ast_node;
    }

    return \%embedded_package_sources;
}

sub decode_top_name ($self, $header) {
    return $1 if defined($header) && !ref($header) && $header =~ /\A\?top:([A-Za-z_]\w*)\z/;

    my $display = defined($header) ? (ref($header) ? ref($header) : $header) : 'undef';
    confess
        "Malformed composition top root '$display'. ".
        "The active contract expects '?top:top_name' with an HDL-identifier-compatible top name ([A-Za-z_]\\w*).".
        $self->scope_docs_suffix;
}

sub decode_embedded_fsm_source_name ($self, $header) {
    return $1 if defined($header) && !ref($header) && $header =~ /\A\?fsm:([A-Za-z_]\w*)\z/;

    my $display = defined($header) ? (ref($header) ? ref($header) : $header) : 'undef';
    confess
        "Malformed embedded FSM source '$display'. ".
        "The active composition contract expects embedded child sources shaped like '?fsm:source_name' with an HDL-identifier-compatible source name ([A-Za-z_]\\w*).".
        $self->scope_docs_suffix;
}

sub decode_embedded_dt_source_name ($self, $header) {
    return $1 if defined($header) && !ref($header) && $header =~ /\A\?(?:dt|mod|module):([A-Za-z_]\w*)\z/;

    my $display = defined($header) ? (ref($header) ? ref($header) : $header) : 'undef';
    confess
        "Malformed embedded DT source '$display'. ".
        "The active composition contract expects embedded standalone-DT child sources shaped like '?dt:source_name', '?mod:source_name', or '?module:source_name' with an HDL-identifier-compatible source name ([A-Za-z_]\\w*).".
        $self->scope_docs_suffix;
}

sub decode_embedded_package_source_name ($self, $header) {
    return $1 if defined($header) && !ref($header) && $header =~ /\A\?pkg:([A-Za-z_]\w*)\z/;

    my $display = defined($header) ? (ref($header) ? ref($header) : $header) : 'undef';
    confess
        "Malformed embedded package source '$display'. ".
        "The active composition contract expects embedded package sources shaped like '?pkg:package_name' with an HDL-identifier-compatible package name ([A-Za-z_]\\w*).".
        $self->scope_docs_suffix;
}

sub unwrap_scalar_token ($self, $value) {
    my $unwrapped = $value;
    while (ref($unwrapped) eq 'ARRAY' && @$unwrapped == 1) {
        $unwrapped = $unwrapped->[0];
    }
    return $unwrapped;
}

sub unwrap_single_nested_list ($self, $value) {
    my $unwrapped = $value;
    while (ref($unwrapped) eq 'ARRAY' && @$unwrapped == 1 && ref($unwrapped->[0]) eq 'ARRAY') {
        $unwrapped = $unwrapped->[0];
    }
    return $unwrapped;
}

sub is_contract_identifier ($self, $value) {
    return defined($value)
        && !ref($value)
        && $value =~ /\A[A-Za-z_]\w*\z/;
}

sub describe_contract_name ($self, $value) {
    return defined($value) && !ref($value) ? $value : 'unknown';
}

sub is_contract_type_reference ($self, $value) {
    return defined($value)
        && !ref($value)
        && $value =~ /\A(?:[A-Za-z_]\w*)(?:\.[A-Za-z_]\w*)?\z/;
}

sub resolve_top_port_width_token ($self, %args) {
    return FSM::Composition::PortWidthResolver->resolve_width_token(
        %args,
        docs_hint => $self->scope_docs_suffix,
        allow_unresolved_imported_type_refs => ($args{allow_unresolved_imported_type_refs} // 0),
    );
}

sub canonicalize_top_type_spec ($self, %args) {
    my $top_name = $args{top_name} // 'top';
    my $type_name = $args{type_name} // 'unknown';
    my $spec_ast = $args{spec_ast};
    my $top_symbols = $args{top_symbols};
    my $allow_unresolved_imported_type_refs = $args{allow_unresolved_imported_type_refs} // 0;

    my $resolved_spec = FSM::Package::DeclarativeTypeSupport->canonicalize_type_spec(
        spec_ast => $spec_ast,
        unwrap_scalar_token => sub ($value) { return $self->unwrap_scalar_token($value) },
        unwrap_single_nested_list => sub ($value) { return $self->unwrap_single_nested_list($value) },
        is_contract_type_reference => sub ($value) { return $self->is_contract_type_reference($value) },
        resolve_type_reference => sub ($type_ref) {
            return (
                $top_symbols && $self->is_contract_type_reference($type_ref)
                    ? $top_symbols->resolve_type($type_ref)
                    : undef
            );
        },
        defer_type_reference => sub ($type_ref) {
            return undef unless $allow_unresolved_imported_type_refs;
            return undef unless $self->is_contract_type_reference($type_ref);
            return undef unless $type_ref =~ /\./;
            return {
                kind => 'deferred_imported_alias',
                imported_type_ref => $type_ref,
            };
        },
        is_contract_identifier => sub ($value) { return $self->is_contract_identifier($value) },
    );
    return $resolved_spec if $resolved_spec;

    confess
        "Composition top '$top_name' contains malformed '+types' entry for type '$type_name', ".
        "but the first active '+types' lane supports 'bit', '(bits N)', '(signed bit)', '(signed (bits N))', '(two_state ...)', '(four_state ...)', '(list ...)', '(record (field TYPE) ...)', or aliases to already-resolved local or imported types.".
        $self->scope_docs_suffix;
}

sub canonicalize_top_symbol_literal_payload ($self, %args) {
    my $top_name = $args{top_name} // 'top';
    my $section_header = $args{section_header} // '+symbols';
    my $symbol_kind = $args{symbol_kind} // 'symbol';
    my $symbol_name = $args{symbol_name} // 'unknown';
    my $value_token = $args{value_token};
    my $expression_builder = $args{expression_builder};

    my $literal_expr = eval {
        $expression_builder->parse_scalar_expression($value_token);
    };
    my $parse_error = $@;

    confess
        "Composition top '$top_name' contains '$section_header' entry for $symbol_kind '$symbol_name' with value token '$value_token', ".
        "but composition top symbol literal support is blocked because top symbol values currently must resolve to literal scalar values such as '0', '8'3', '8'hA5', 'const_8b0', or previously declared top constants/enums.".
        $self->scope_docs_suffix
        if $parse_error || ref($literal_expr) ne 'FSM::CoreAST::Literal';

    my $value = $literal_expr->value;
    my $width = $literal_expr->width;
    my $radix = $literal_expr->radix // 'decimal';

    return $value unless defined $width;
    return $width."'b".$value if $radix eq 'binary';
    return $width."'h".$value if $radix eq 'hex';
    return $width."'d".$value;
}

sub canonicalize_top_constant_payload ($self, %args) {
    my $top_name = $args{top_name} // 'top';
    my $section_header = $args{section_header} // '+constants';
    my $symbol_kind = $args{symbol_kind} // 'constant';
    my $symbol_name = $args{symbol_name} // 'unknown';
    my $value_ast = $args{value_ast};
    my $expression_builder = $args{expression_builder};

    my $scalar_value = $self->unwrap_scalar_token($value_ast);
    if (defined($scalar_value) && !ref($scalar_value)) {
        my $payload = $self->canonicalize_top_symbol_literal_payload(
            top_name => $top_name,
            section_header => $section_header,
            symbol_kind => $symbol_kind,
            symbol_name => $symbol_name,
            value_token => $scalar_value,
            expression_builder => $expression_builder,
        );
        return {
            kind => 'scalar',
            payload => $payload,
        };
    }

    confess
        "Composition top '$top_name' contains '$section_header' entry for $symbol_kind '$symbol_name', ".
        "but composition top aggregate value support is blocked because that value is neither a scalar literal nor a real aggregate list/hash payload.".
        $self->scope_docs_suffix
        unless ref($value_ast) eq 'ARRAY';

    confess
        "Composition top '$top_name' contains '$section_header' entry for $symbol_kind '$symbol_name' with an empty aggregate value, ".
        "but composition top aggregate value support is blocked because aggregate top-symbol values must be non-empty lists or non-empty hash-like member sets.".
        $self->scope_docs_suffix
        unless @$value_ast;

    my $value_items = $self->top_value_items($value_ast);

    confess
        "Composition top '$top_name' contains '$section_header' entry for $symbol_kind '$symbol_name' with an empty aggregate value, ".
        "but composition top aggregate value support is blocked because aggregate top-symbol values must be non-empty lists or non-empty hash-like member sets.".
        $self->scope_docs_suffix
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
            confess
                "Composition top '$top_name' contains '$section_header' entry for $symbol_kind '$symbol_name' with duplicate member '$member_name', ".
                "but composition top aggregate packing is blocked because hash-like aggregate values must use each member name at most once so one packed member order remains unambiguous.".
                $self->scope_docs_suffix
                if exists $members{$member_name};
            push @member_order, $member_name;
            $members{$member_name} = $self->canonicalize_top_constant_payload(
                top_name => $top_name,
                section_header => $section_header,
                symbol_kind => "$symbol_kind member",
                symbol_name => $symbol_name.'.'.$member_name,
                value_ast => $member_value_ast,
                expression_builder => $expression_builder,
            );
        }

        return {
            kind => 'map',
            member_order => \@member_order,
            members => \%members,
        };
    }

    confess
        "Composition top '$top_name' contains '$section_header' entry for $symbol_kind '$symbol_name' with a mixed aggregate value, ".
        "but composition top aggregate value support is blocked because list-style and hash-style aggregate entries cannot be mixed in one top-symbol value.".
        $self->scope_docs_suffix
        if $hash_like_entries && $non_hash_entries;

    my @items;
    for my $index (0 .. $#$value_items) {
        push @items, $self->canonicalize_top_constant_payload(
            top_name => $top_name,
            section_header => $section_header,
            symbol_kind => "$symbol_kind item",
            symbol_name => $symbol_name."[$index]",
            value_ast => $value_items->[$index],
            expression_builder => $expression_builder,
        );
    }

    return {
        kind => 'list',
        items => \@items,
    };
}

sub top_value_items ($self, $value_ast) {
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

1;
