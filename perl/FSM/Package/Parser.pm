package FSM::Package::Parser;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Package::DeclarativeTypeSupport;
use FSM::Package::DeclarativeSymbolResolver;
use FSM::Package::DeclarativeTypeResolver;
use FSM::Package::Spec;
use FSM::Package::SignalManagerProjectionSupport;
use FSM::Package::Symbols;

sub new ($class, %args) {
    return bless {
        debug => $args{debug} // 0,
    }, $class;
}

sub parse_source ($self, $raw_ast) {
    my $package_ast = $self->find_package_root($raw_ast);
    confess "Expected package source containing '?pkg:name'" unless $package_ast;
    return $self->parse_package_root($package_ast);
}

sub find_package_root ($self, $raw_ast) {
    return undef unless ref($raw_ast) eq 'ARRAY';

    if (@$raw_ast > 0 && !ref($raw_ast->[0]) && $raw_ast->[0] =~ /^\?pkg:/) {
        return $raw_ast;
    }

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY';
        next unless @$ast_node > 0;
        next if ref($ast_node->[0]);
        return $ast_node if $ast_node->[0] =~ /^\?pkg:/;
    }

    return undef;
}

sub parse_package_root ($self, $package_ast) {
    my ($header, $children) = @$package_ast;
    my $package_name = $self->decode_package_name($header);

    $children ||= [];
    confess "Package '$package_name' must contain a child list" unless ref($children) eq 'ARRAY';

    my $symbols = FSM::Package::Symbols->new();
    my $symbol_manager = FSM::Adapter::FSMGenFull::SignalManager->new(
        debug => ($self->{debug} ? 1 : 0),
    );
    my $expression_builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(
        debug => ($self->{debug} ? 1 : 0),
        signal_manager => $symbol_manager,
    );
    my @pending_constant_entries;
    my @pending_enum_entries;
    my @pending_type_entries;

    for my $child (@$children) {
        confess
            "Package '$package_name' contains a non-list child item, ".
            "but package child structure is blocked because every package child must be a real declaration block such as '+constants' or '+enums'."
            unless ref($child) eq 'ARRAY';
        confess
            "Package '$package_name' contains an empty child entry, ".
            "but package child structure is blocked because every package child must begin with a real string header such as '+constants' or '+enums'."
            unless @$child;
        my $child_header = $child->[0];
        confess
            "Package '$package_name' contains a child entry that does not begin with a string header, ".
            "but package child header shape is blocked because every package child must begin with a real string header such as '+constants' or '+enums'."
            if ref($child_header);

        if (defined($child_header) && $child_header eq '+constants') {
            push @pending_constant_entries, @{ $self->parse_package_constants_block(
                $package_name,
                $child,
                $symbols,
            ) };
            next;
        }

        if (defined($child_header) && $child_header eq '+enums') {
            push @pending_enum_entries, @{ $self->parse_package_enums_block(
                $package_name,
                $child,
                $symbols,
            ) };
            next;
        }

        if (defined($child_header) && $child_header eq '+types') {
            push @pending_type_entries, @{ $self->parse_package_types_block(
                $package_name,
                $child,
                $symbols,
            ) };
            next;
        }

        confess
            "Package '$package_name' contains child '$child_header', ".
            "but package child kind support is blocked because the active package parser currently accepts only '+constants', '+enums', and '+types'.";
    }

    $self->resolve_pending_package_types(
        $package_name,
        $symbols,
        $symbol_manager,
        \@pending_type_entries,
    );

    $self->resolve_pending_package_symbols(
        $package_name,
        $symbols,
        $symbol_manager,
        $expression_builder,
        \@pending_constant_entries,
        \@pending_enum_entries,
    );

    return FSM::Package::Spec->new(
        name => $package_name,
        symbols => $symbols,
        raw_ast => $package_ast,
    );
}

sub parse_package_constants_block ($self, $package_name, $child_ast, $symbols) {
    my (undef, $constants_list) = @$child_ast;

    confess
        "Package '$package_name' contains malformed '+constants' section, ".
        "but package symbol section shape is blocked because '+constants' currently requires a non-empty list of '(NAME value)' entries where the value is either a literal scalar, a non-empty list aggregate, or a non-empty hash-like aggregate."
        unless ref($constants_list) eq 'ARRAY' && @$constants_list;

    my @constant_entries;
    for my $constant_def (@$constants_list) {
        confess
            "Package '$package_name' contains malformed '+constants' entry, ".
            "but package symbol entry shape is blocked because each '+constants' entry must be a pair '(NAME value)'."
            unless ref($constant_def) eq 'ARRAY' && @$constant_def == 2;

        my ($name, $value) = @$constant_def;
        my $resolved_name = $self->unwrap_scalar_token($name);

        confess
            "Package '$package_name' contains malformed '+constants' entry for constant '".$self->describe_contract_name($resolved_name)."', ".
            "but package symbol token shape is blocked because each '+constants' entry must use an HDL-identifier-compatible name."
            unless $self->is_contract_identifier($resolved_name);

        push @constant_entries, {
            name => $resolved_name,
            value_ast => $value,
        };
    }

    $symbols->push_raw_block($child_ast);
    return \@constant_entries;
}

sub parse_package_enums_block ($self, $package_name, $child_ast, $symbols) {
    my (undef, $enums_list) = @$child_ast;

    confess
        "Package '$package_name' contains malformed '+enums' section, ".
        "but package symbol section shape is blocked because '+enums' currently requires a non-empty list of '(enum_name (MEMBER value) ...)' definitions."
        unless ref($enums_list) eq 'ARRAY' && @$enums_list;

    my @enum_entries;
    for my $enum_def (@$enums_list) {
        confess
            "Package '$package_name' contains malformed '+enums' definition, ".
            "but package symbol entry shape is blocked because each '+enums' definition must use the shape '(enum_name (MEMBER value) ...)'."
            unless ref($enum_def) eq 'ARRAY' && @$enum_def == 2;

        my ($enum_name, $members_list) = @$enum_def;
        my $resolved_enum_name = $self->unwrap_scalar_token($enum_name);

        confess
            "Package '$package_name' contains malformed '+enums' definition for enum '".$self->describe_contract_name($resolved_enum_name)."', ".
            "but package symbol token shape is blocked because each '+enums' definition must use an HDL-identifier-compatible enum name and at least one '(MEMBER value)' entry."
            unless $self->is_contract_identifier($resolved_enum_name)
                && ref($members_list) eq 'ARRAY'
                && @$members_list;

        my @member_entries;
        for my $member_def (@$members_list) {
            confess
                "Package '$package_name' contains malformed '+enums' member for enum '$resolved_enum_name', ".
                "but package symbol entry shape is blocked because each enum member must be a pair '(MEMBER value)'."
                unless ref($member_def) eq 'ARRAY' && @$member_def == 2;

            my ($member_name, $member_value) = @$member_def;
            my $resolved_member_name = $self->unwrap_scalar_token($member_name);
            my $resolved_member_value = $self->unwrap_scalar_token($member_value);

            confess
                "Package '$package_name' contains malformed '+enums' member '".$self->describe_contract_name($resolved_member_name)."' for enum '$resolved_enum_name', ".
                "but package symbol token shape is blocked because each enum member must use an HDL-identifier-compatible member name and a scalar value token."
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

    $symbols->push_raw_block($child_ast);
    return \@enum_entries;
}

sub parse_package_types_block ($self, $package_name, $child_ast, $symbols) {
    my (undef, $types_list) = @$child_ast;

    confess
        "Package '$package_name' contains malformed '+types' section, ".
        "but package type section shape is blocked because '+types' currently requires a non-empty list of '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', '(type NAME (list ...))', '(type NAME (record (field TYPE) ...))', or '(type NAME other_type)' entries."
        unless ref($types_list) eq 'ARRAY' && @$types_list;

    my @type_entries;
    for my $type_def (@$types_list) {
        confess
            "Package '$package_name' contains malformed '+types' entry, ".
            "but package type entry shape is blocked because each '+types' entry must use the shape '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', '(type NAME (list ...))', '(type NAME (record (field TYPE) ...))', or '(type NAME other_type)'."
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
                "Package '$package_name' contains malformed '+types' entry, ".
                "but package type entry shape is blocked because each '+types' entry must use the shape '(type NAME bit)', '(type NAME (bits N))', '(type NAME (signed bit))', '(type NAME (signed (bits N)))', '(type NAME (two_state ...))', '(type NAME (four_state ...))', '(type NAME (list ...))', '(type NAME (record (field TYPE) ...))', or '(type NAME other_type)'.";
        }

        my $resolved_keyword = $self->unwrap_scalar_token($keyword);
        my $resolved_name = $self->unwrap_scalar_token($name);

        confess
            "Package '$package_name' contains malformed '+types' entry for type '".$self->describe_contract_name($resolved_name)."', ".
            "but package type token shape is blocked because each '+types' entry must begin with the literal keyword 'type' and use an HDL-identifier-compatible type name."
            unless defined($resolved_keyword)
                && !ref($resolved_keyword)
                && $resolved_keyword eq 'type'
                && $self->is_contract_identifier($resolved_name);

        push @type_entries, {
            name => $resolved_name,
            spec_ast => $spec_ast,
        };
    }

    $symbols->push_raw_block($child_ast);
    return \@type_entries;
}

sub resolve_pending_package_symbols ($self, $package_name, $symbols, $symbol_manager, $expression_builder, $constant_entries, $enum_entries) {
    $constant_entries ||= [];
    $enum_entries ||= [];
    return 1 unless @$constant_entries || @$enum_entries;

    FSM::Package::DeclarativeSymbolResolver->resolve_symbols(
        constant_entries => $constant_entries,
        enum_entries => $enum_entries,
        value_items => sub ($value_ast) { return $self->package_value_items($value_ast) },
        unwrap_scalar_token => sub ($value) { return $self->unwrap_scalar_token($value) },
        is_contract_identifier => sub ($value) { return $self->is_contract_identifier($value) },
        resolve_constant_payload => sub ($entry) {
            return $self->canonicalize_package_constant_payload(
                package_name => $package_name,
                section_header => '+constants',
                symbol_kind => 'constant',
                symbol_name => $entry->{name},
                value_ast => $entry->{value_ast},
                expression_builder => $expression_builder,
            );
        },
        resolve_enum_member_payload => sub ($enum_entry, $member_entry) {
            return $self->canonicalize_package_symbol_literal_payload(
                package_name => $package_name,
                section_header => '+enums',
                symbol_kind => 'enum member',
                symbol_name => $enum_entry->{name}.'.'.$member_entry->{name},
                value_token => $member_entry->{value_token},
                expression_builder => $expression_builder,
            );
        },
        store_constant => sub ($name, $payload) {
            $symbols->store_constant($name, $payload);
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
            $symbols->store_enum($enum_name, $members_hashref);
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
                "Package '$package_name' contains a declarative symbol dependency cycle, ".
                "but package symbol scope now resolves normal non-cyclic '+constants'/'+enums' references without depending on declaration order and still blocks cycles explicitly. ".
                "Cycle: ".join(' -> ', @chain).".";
        },
    );

    return 1;
}

sub resolve_pending_package_types ($self, $package_name, $symbols, $symbol_manager, $type_entries) {
    $type_entries ||= [];
    return 1 unless @$type_entries;

    FSM::Package::DeclarativeTypeResolver->resolve_types(
        type_entries => $type_entries,
        unwrap_scalar_token => sub ($value) { return $self->unwrap_scalar_token($value) },
        unwrap_single_nested_list => sub ($value) { return $self->unwrap_single_nested_list($value) },
        is_contract_identifier => sub ($value) { return $self->is_contract_identifier($value) },
        resolve_type_spec => sub ($entry) {
            return $self->canonicalize_package_type_spec(
                package_name => $package_name,
                type_name => $entry->{name},
                spec_ast => $entry->{spec_ast},
                symbols => $symbols,
                signal_manager => $symbol_manager,
            );
        },
        store_type => sub ($type_name, $type_spec) {
            $symbols->store_type($type_name, $type_spec);
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
                "Package '$package_name' contains a declarative type dependency cycle, ".
                "but package type scope now resolves normal non-cyclic type aliases without depending on declaration order and still blocks cycles explicitly. ".
                "Cycle: ".join(' -> ', @chain).".";
        },
    );

    return 1;
}

sub decode_package_name ($self, $header) {
    return $1 if defined($header) && !ref($header) && $header =~ /\A\?pkg:([A-Za-z_]\w*)\z/;

    my $display = defined($header) ? (ref($header) ? ref($header) : $header) : 'undef';
    confess
        "Malformed package root '$display'. ".
        "The active contract expects '?pkg:package_name' with an HDL-identifier-compatible package name ([A-Za-z_]\\w*).";
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

sub canonicalize_package_type_spec ($self, %args) {
    my $package_name = $args{package_name} // 'package';
    my $type_name = $args{type_name} // 'unknown';
    my $spec_ast = $args{spec_ast};
    my $symbols = $args{symbols};
    my $signal_manager = $args{signal_manager};

    my $resolved_spec = FSM::Package::DeclarativeTypeSupport->canonicalize_type_spec(
        spec_ast => $spec_ast,
        unwrap_scalar_token => sub ($value) { return $self->unwrap_scalar_token($value) },
        unwrap_single_nested_list => sub ($value) { return $self->unwrap_single_nested_list($value) },
        is_contract_type_reference => sub ($value) { return $self->is_contract_type_reference($value) },
        resolve_type_reference => sub ($type_ref) {
            my $resolved_from_symbols = (
                $symbols && $self->is_contract_type_reference($type_ref)
                    ? $symbols->resolve_type($type_ref)
                    : undef
            );
            return $resolved_from_symbols if $resolved_from_symbols;

            return (
                $signal_manager && $self->is_contract_type_reference($type_ref)
                    ? $signal_manager->resolve_type($type_ref)
                    : undef
            );
        },
        is_contract_identifier => sub ($value) { return $self->is_contract_identifier($value) },
    );
    return $resolved_spec if $resolved_spec;

    confess
        "Package '$package_name' contains malformed '+types' entry for type '$type_name', ".
        "but the first active '+types' lane supports 'bit', '(bits N)', '(signed bit)', '(signed (bits N))', '(two_state ...)', '(four_state ...)', '(list ...)', '(record (field TYPE) ...)', or aliases to already-resolved local/imported types.";
}

sub canonicalize_package_symbol_literal_payload ($self, %args) {
    my $package_name = $args{package_name} // 'package';
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
        "Package '$package_name' contains '$section_header' entry for $symbol_kind '$symbol_name' with value token '$value_token', ".
        "but package symbol literal support is blocked because package symbol values currently must resolve to literal scalar values such as '0', '8'3', '8'hA5', or 'const_8b0'."
        if $parse_error || ref($literal_expr) ne 'FSM::CoreAST::Literal';

    my $value = $literal_expr->value;
    my $width = $literal_expr->width;
    my $radix = $literal_expr->radix // 'decimal';

    return $value unless defined $width;
    return $width."'b".$value if $radix eq 'binary';
    return $width."'h".$value if $radix eq 'hex';
    return $width."'d".$value;
}

sub canonicalize_package_constant_payload ($self, %args) {
    my $package_name = $args{package_name} // 'package';
    my $section_header = $args{section_header} // '+constants';
    my $symbol_kind = $args{symbol_kind} // 'constant';
    my $symbol_name = $args{symbol_name} // 'unknown';
    my $value_ast = $args{value_ast};
    my $expression_builder = $args{expression_builder};

    my $scalar_value = $self->unwrap_scalar_token($value_ast);
    if (defined($scalar_value) && !ref($scalar_value)) {
        my $payload = $self->canonicalize_package_symbol_literal_payload(
            %args,
            value_token => $scalar_value,
        );
        return {
            kind => 'scalar',
            payload => $payload,
        };
    }

    confess
        "Package '$package_name' contains '$section_header' entry for $symbol_kind '$symbol_name', ".
        "but package aggregate value support is blocked because that value is neither a scalar literal nor a real aggregate list/hash payload."
        unless ref($value_ast) eq 'ARRAY';

    confess
        "Package '$package_name' contains '$section_header' entry for $symbol_kind '$symbol_name' with an empty aggregate value, ".
        "but package aggregate value support is blocked because aggregate package values must be non-empty lists or non-empty hash-like member sets."
        unless @$value_ast;

    my $value_items = $self->package_value_items($value_ast);

    confess
        "Package '$package_name' contains '$section_header' entry for $symbol_kind '$symbol_name' with an empty aggregate value, ".
        "but package aggregate value support is blocked because aggregate package values must be non-empty lists or non-empty hash-like member sets."
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
                "Package '$package_name' contains '$section_header' entry for $symbol_kind '$symbol_name' with duplicate member '$member_name', ".
                "but package aggregate packing is blocked because hash-like aggregate values must use each member name at most once so one packed member order remains unambiguous."
                if exists $members{$member_name};
            push @member_order, $member_name;
            $members{$member_name} = $self->canonicalize_package_constant_payload(
                package_name => $package_name,
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
        "Package '$package_name' contains '$section_header' entry for $symbol_kind '$symbol_name' with a mixed aggregate value, ".
        "but package aggregate value support is blocked because list-style and hash-style aggregate entries cannot be mixed in one package value."
        if $hash_like_entries && $non_hash_entries;

    my @items;
    for my $index (0 .. $#$value_items) {
        push @items, $self->canonicalize_package_constant_payload(
            package_name => $package_name,
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

sub package_value_items ($self, $value_ast) {
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
