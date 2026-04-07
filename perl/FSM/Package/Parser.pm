package FSM::Package::Parser;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::Adapter::FSMGenFull::SignalManager;
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
            $self->parse_package_constants_block(
                $package_name,
                $child,
                $symbols,
                $symbol_manager,
                $expression_builder,
            );
            next;
        }

        if (defined($child_header) && $child_header eq '+enums') {
            $self->parse_package_enums_block(
                $package_name,
                $child,
                $symbols,
                $symbol_manager,
                $expression_builder,
            );
            next;
        }

        confess
            "Package '$package_name' contains child '$child_header', ".
            "but package child kind support is blocked because the active package parser currently accepts only '+constants' and '+enums'.";
    }

    return FSM::Package::Spec->new(
        name => $package_name,
        symbols => $symbols,
        raw_ast => $package_ast,
    );
}

sub parse_package_constants_block ($self, $package_name, $child_ast, $symbols, $symbol_manager, $expression_builder) {
    my (undef, $constants_list) = @$child_ast;

    confess
        "Package '$package_name' contains malformed '+constants' section, ".
        "but package symbol section shape is blocked because '+constants' currently requires a non-empty list of '(NAME value)' entries where the value is either a literal scalar, a non-empty list aggregate, or a non-empty hash-like aggregate."
        unless ref($constants_list) eq 'ARRAY' && @$constants_list;

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

        my $canonical_payload = $self->canonicalize_package_constant_payload(
            package_name => $package_name,
            section_header => '+constants',
            symbol_kind => 'constant',
            symbol_name => $resolved_name,
            value_ast => $value,
            expression_builder => $expression_builder,
        );

        $symbols->store_constant($resolved_name, $canonical_payload);
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

    $symbols->push_raw_block($child_ast);
    return $symbols;
}

sub parse_package_enums_block ($self, $package_name, $child_ast, $symbols, $symbol_manager, $expression_builder) {
    my (undef, $enums_list) = @$child_ast;

    confess
        "Package '$package_name' contains malformed '+enums' section, ".
        "but package symbol section shape is blocked because '+enums' currently requires a non-empty list of '(enum_name (MEMBER value) ...)' definitions."
        unless ref($enums_list) eq 'ARRAY' && @$enums_list;

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

        my %enum_values;
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

            $enum_values{$resolved_member_name} = $self->canonicalize_package_symbol_literal_payload(
                package_name => $package_name,
                section_header => '+enums',
                symbol_kind => 'enum member',
                symbol_name => $resolved_enum_name.'.'.$resolved_member_name,
                value_token => $resolved_member_value,
                expression_builder => $expression_builder,
            );
        }

        $symbols->store_enum($resolved_enum_name, \%enum_values);
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

    $symbols->push_raw_block($child_ast);
    return $symbols;
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

sub is_contract_identifier ($self, $value) {
    return defined($value)
        && !ref($value)
        && $value =~ /\A[A-Za-z_]\w*\z/;
}

sub describe_contract_name ($self, $value) {
    return defined($value) && !ref($value) ? $value : 'unknown';
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
        for my $entry (@$value_items) {
            my ($member_name_ast, $member_value_ast) = @$entry;
            my $member_name = $self->unwrap_scalar_token($member_name_ast);
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
