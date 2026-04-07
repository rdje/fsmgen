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
use FSM::Composition::Link;
use FSM::Composition::PortsBlock;
use FSM::Composition::TopLink;
use FSM::Composition::TopSymbols;
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
    my @toplinks;
    my @package_imports;
    my $top_symbols = FSM::Composition::TopSymbols->new();
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
            $self->parse_top_constants_block(
                $top_name,
                $child,
                $top_symbols,
                $symbol_manager,
                $expression_builder,
            );
            next;
        }

        if (@$child && defined($child->[0]) && !ref($child->[0]) && $child->[0] eq '+enums') {
            $self->parse_top_enums_block(
                $top_name,
                $child,
                $top_symbols,
                $symbol_manager,
                $expression_builder,
            );
            next;
        }

        if (@$child && defined($child->[0]) && !ref($child->[0]) && $child->[0] eq '+import') {
            push @package_imports, @{$self->parse_top_import_block($top_name, $child)};
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
        "but composition child structure is blocked because every child must start with a real string header such as '?fsmc:name', '?dtc:name', '?rtl:module', '?ports', '?toplink:name', '+constants', '+enums', or '+import'.".
        $self->scope_docs_suffix
        unless @$child_ast;

    my $header = $child_ast->[0];
    confess
        "Composition top '$top_name' contains a child entry that is empty or missing its header, ".
        "but composition child structure is blocked because every child must start with a real string header such as '?fsmc:name', '?dtc:name', '?rtl:module', '?ports', '?toplink:name', '+constants', '+enums', or '+import'.".
        $self->scope_docs_suffix
        unless defined($header) && length($header);
    confess
        "Composition top '$top_name' contains a child entry that does not begin with a string header, ".
        "but composition child header shape is blocked because every child must start with a real string header such as '?fsmc:name', '?dtc:name', '?rtl:module', '?ports', '?toplink:name', '+constants', '+enums', or '+import'.".
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
        return ('instance', FSM::Composition::Instance->new(
            kind => 'rtl',
            module_name => $1,
            raw_items => $items,
            raw_ast => $child_ast,
        ));
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
        "but composition child kind support is blocked because the active composition parser currently accepts only '?fsmc', '?dtc', '?rtl', '?ports', '?toplink', '+constants', '+enums', and '+import'.".
        $self->scope_docs_suffix;
}

sub parse_top_constants_block ($self, $top_name, $child_ast, $top_symbols, $symbol_manager, $expression_builder) {
    my (undef, $constants_list) = @$child_ast;

    confess
        "Composition top '$top_name' contains malformed '+constants' section, ".
        "but composition top symbol section shape is blocked because '+constants' currently requires a non-empty list of '(NAME value)' entries where the value is either a literal scalar, a non-empty list aggregate, or a non-empty hash-like aggregate.".
        $self->scope_docs_suffix
        unless ref($constants_list) eq 'ARRAY' && @$constants_list;

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

        my $canonical_payload = $self->canonicalize_top_constant_payload(
            top_name => $top_name,
            section_header => '+constants',
            symbol_kind => 'constant',
            symbol_name => $resolved_name,
            value_ast => $value,
            expression_builder => $expression_builder,
        );

        $top_symbols->store_constant($resolved_name, $canonical_payload);
        FSM::Package::SignalManagerProjectionSupport->project_symbols_into_signal_manager(
            signal_manager => $symbol_manager,
            symbols => FSM::Package::Symbols->new(
                constants => {
                    $resolved_name => $canonical_payload,
                },
            ),
            expression_builder => $expression_builder,
        );
    }

    $top_symbols->push_raw_block($child_ast);
    return $top_symbols;
}

sub parse_top_enums_block ($self, $top_name, $child_ast, $top_symbols, $symbol_manager, $expression_builder) {
    my (undef, $enums_list) = @$child_ast;

    confess
        "Composition top '$top_name' contains malformed '+enums' section, ".
        "but composition top symbol section shape is blocked because '+enums' currently requires a non-empty list of '(enum_name (MEMBER value) ...)' definitions.".
        $self->scope_docs_suffix
        unless ref($enums_list) eq 'ARRAY' && @$enums_list;

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

        my %enum_values;
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

            $enum_values{$resolved_member_name} = $self->canonicalize_top_symbol_literal_payload(
                top_name => $top_name,
                section_header => '+enums',
                symbol_kind => 'enum member',
                symbol_name => $resolved_enum_name.'.'.$resolved_member_name,
                value_token => $resolved_member_value,
                expression_builder => $expression_builder,
            );
        }

        $top_symbols->store_enum($resolved_enum_name, \%enum_values);
        FSM::Package::SignalManagerProjectionSupport->project_symbols_into_signal_manager(
            signal_manager => $symbol_manager,
            symbols => FSM::Package::Symbols->new(
                enums => {
                    $resolved_enum_name => \%enum_values,
                },
            ),
            expression_builder => $expression_builder,
        );
    }

    $top_symbols->push_raw_block($child_ast);
    return $top_symbols;
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

sub parse_ports_block ($self, $top_name, $child_ast, $block_name, $items) {
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

        push @ports, $self->parse_port_token($top_name, $item);
    }

    return FSM::Composition::PortsBlock->new(
        name => $block_name,
        ports => \@ports,
        raw_ast => $child_ast,
    );
}

sub parse_port_token ($self, $top_name, $token) {
    $token =~ /^(?<binding>=)?(?<port>\w+)(?:(?<direction>[<>])(?<size>\d+)?(?:[:](?<type>\w+))?)?$/o;
    my ($binding, $port, $direction, $size, $type) = @+{qw/binding port direction size type/};

    confess "Composition top '$top_name' contains '?ports' token '$token', ".
        "but composition port token shape is blocked because it is not a valid explicit top-port token for the current active contract.".
        $self->scope_docs_suffix
        unless $port;
    confess "Composition top '$top_name' contains '?ports' token '$token', ".
        "but composition port sizing is blocked because it declares non-positive width '$size'.".
        $self->scope_docs_suffix
        if defined($size) && $size < 1;

    return FSM::Composition::Port->new(
        name => $port,
        direction => defined($direction) ? ($direction eq '<' ? 'input' : 'output') : 'input',
        width => $size // 1,
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

sub is_contract_identifier ($self, $value) {
    return defined($value)
        && !ref($value)
        && $value =~ /\A[A-Za-z_]\w*\z/;
}

sub describe_contract_name ($self, $value) {
    return defined($value) && !ref($value) ? $value : 'unknown';
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
        for my $entry (@$value_items) {
            my ($member_name_ast, $member_value_ast) = @$entry;
            my $member_name = $self->unwrap_scalar_token($member_name_ast);
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
