package FSM::ParameterValueSupport;

=head1 NAME

FSM::ParameterValueSupport - Parameter/generic value helpers

=head1 DESCRIPTION

Normalizes the bounded integer literal and aggregate payload surface used by
semantic parameter/generic declarations and instance overrides.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Math::BigInt;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Package::IntegerLiteralSupport;
use FSM::Package::PayloadLiteralSupport;
use FSM::Package::PayloadTypeSupport;

sub canonical_value_text ($class, %args) {
    return $class->canonical_value(%args)->{value_text};
}

sub canonical_value ($class, %args) {
    my $context = $args{context} // 'Parameter/generic value';
    my $docs_hint = $args{docs_hint} // '';
    my $value_ast = exists($args{value_ast}) ? $args{value_ast} : $args{value};
    my $resolve_symbol_payload = $args{resolve_symbol_payload};

    my $payload = $class->_canonical_payload(
        $value_ast,
        $context,
        $docs_hint,
        $resolve_symbol_payload,
    );
    my ($bits, $width, $reason) = FSM::Package::PayloadLiteralSupport->payload_to_bits_and_width($payload);
    my $type_spec = FSM::Package::PayloadTypeSupport->payload_to_type_spec($payload);

    if (($payload->{kind} || '') eq 'scalar' || ($payload->{kind} || '') eq 'scalar_expr') {
        my %result = (
            value_text => $payload->{payload},
            value_payload => $payload,
            value_kind => 'scalar',
        );
        $result{value_width} = $width if defined $width;
        $result{value_type_spec} = $type_spec if ref($type_spec) eq 'HASH';
        return \%result;
    }

    confess
        "$context is blocked because aggregate parameter/generic values must lower to one packed literal before backend emission, but this aggregate did not lower; reason '$reason'.".
        $docs_hint."\n"
        unless defined($bits) && defined($width) && $width > 0;

    my %result = (
        value_text => $width."'b".$bits,
        value_payload => $payload,
        value_kind => ($payload->{kind} || 'aggregate'),
        value_width => $width,
    );
    $result{value_type_spec} = $type_spec if ref($type_spec) eq 'HASH';
    return \%result;
}

sub resolve_payload_path ($class, $payload, $suffix) {
    return undef unless defined $payload;
    $suffix //= '';
    return $class->_clone_payload($payload) if $suffix eq '';

    my $current = $payload;
    my $remaining = $suffix;

    while (length $remaining) {
        if ($remaining =~ s/\A\.([A-Za-z_]\w*)//) {
            return undef unless ref($current) eq 'HASH' && ($current->{kind} || '') eq 'map';
            $current = ($current->{members} || {})->{$1};
            return undef unless defined $current;
            next;
        }

        if ($remaining =~ s/\A\[(\d+)\]//) {
            return undef unless ref($current) eq 'HASH' && ($current->{kind} || '') eq 'list';
            my $items = $current->{items} || [];
            return undef if $1 > $#$items;
            $current = $items->[$1];
            return undef unless defined $current;
            next;
        }

        return undef;
    }

    return $class->_clone_payload($current);
}

sub _canonical_payload ($class, $value_ast, $context, $docs_hint, $resolve_symbol_payload = undef) {
    return $class->_canonical_existing_payload(
        $value_ast,
        $context,
        $docs_hint,
        $resolve_symbol_payload,
    ) if ref($value_ast) eq 'HASH' && exists $value_ast->{kind};

    my $scalar_value = $class->_unwrap_scalar_token($value_ast);
    if (defined($scalar_value) && !ref($scalar_value)) {
        if ($resolve_symbol_payload) {
            my $resolved_payload = $resolve_symbol_payload->($scalar_value);
            return $class->_canonical_payload(
                $resolved_payload,
                "$context symbol '$scalar_value'",
                $docs_hint,
                $resolve_symbol_payload,
            ) if defined $resolved_payload;
        }

        return {
            kind => 'scalar',
            payload => $class->_canonical_scalar_value_text($scalar_value, $context, $docs_hint),
        };
    }

    if (ref($value_ast) eq 'ARRAY') {
        my $expression_payload = $class->_canonical_expression_payload(
            $value_ast,
            $context,
            $docs_hint,
            $resolve_symbol_payload,
        );
        return $expression_payload if defined $expression_payload;
    }

    confess
        "$context is blocked because parameter/generic values must be scalar integer literals or non-empty list/map aggregate payloads.".
        $docs_hint."\n"
        unless ref($value_ast) eq 'ARRAY';

    my $value_items = $class->_value_items($value_ast);
    confess
        "$context is blocked because aggregate parameter/generic values must be non-empty.".
        $docs_hint."\n"
        unless @$value_items;

    my $hash_like_entries = 0;
    my $non_hash_entries = 0;
    for my $entry (@$value_items) {
        my $member_name = (ref($entry) eq 'ARRAY' && @$entry == 2)
            ? $class->_unwrap_scalar_token($entry->[0])
            : undef;
        if (defined($member_name) && $class->_is_contract_identifier($member_name)) {
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
            my $member_name = $class->_unwrap_scalar_token($member_name_ast);
            confess
                "$context is blocked because aggregate parameter/generic map values repeat member '$member_name'.".
                $docs_hint."\n"
                if exists $members{$member_name};
            push @member_order, $member_name;
            $members{$member_name} = $class->_canonical_payload(
                $member_value_ast,
                "$context member '$member_name'",
                $docs_hint,
                $resolve_symbol_payload,
            );
        }

        return {
            kind => 'map',
            member_order => \@member_order,
            members => \%members,
        };
    }

    confess
        "$context is blocked because aggregate parameter/generic values cannot mix list-style items and map-style '(member value)' entries in one value.".
        $docs_hint."\n"
        if $hash_like_entries && $non_hash_entries;

    return {
        kind => 'list',
        items => [
            map {
                $class->_canonical_payload(
                    $value_items->[$_],
                    "$context item $_",
                    $docs_hint,
                    $resolve_symbol_payload,
                )
            } 0 .. $#$value_items
        ],
    };
}

sub _canonical_existing_payload ($class, $payload, $context, $docs_hint, $resolve_symbol_payload = undef) {
    my $kind = $payload->{kind} || '';

    if ($kind eq 'scalar') {
        return {
            kind => 'scalar',
            payload => $class->_canonical_scalar_value_text(
                $payload->{payload},
                $context,
                $docs_hint,
            ),
        };
    }

    if ($kind eq 'scalar_expr') {
        my $payload_text = $payload->{payload};
        confess
            "$context is blocked because parameter/generic scalar expression payloads must already be normalized text.".
            $docs_hint."\n"
            unless defined($payload_text) && !ref($payload_text) && length($payload_text);
        return {
            kind => 'scalar_expr',
            payload => $payload_text,
        };
    }

    if ($kind eq 'list') {
        my $items = $payload->{items};
        confess
            "$context is blocked because aggregate parameter/generic list values must be non-empty.".
            $docs_hint."\n"
            unless ref($items) eq 'ARRAY' && @$items;

        return {
            kind => 'list',
            items => [
                map {
                    $class->_canonical_payload(
                        $items->[$_],
                        "$context item $_",
                        $docs_hint,
                        $resolve_symbol_payload,
                    )
                } 0 .. $#$items
            ],
        };
    }

    if ($kind eq 'map') {
        my $members = $payload->{members};
        my $member_order = $payload->{member_order};
        confess
            "$context is blocked because aggregate parameter/generic map values must be non-empty.".
            $docs_hint."\n"
            unless ref($members) eq 'HASH' && keys %$members;

        my @member_order = ref($member_order) eq 'ARRAY' && @$member_order
            ? @$member_order
            : sort keys %$members;
        my %canonical_members;
        for my $member_name (@member_order) {
            confess
                "$context is blocked because aggregate parameter/generic map values are missing member '$member_name'.".
                $docs_hint."\n"
                unless exists $members->{$member_name};
            $canonical_members{$member_name} = $class->_canonical_payload(
                $members->{$member_name},
                "$context member '$member_name'",
                $docs_hint,
                $resolve_symbol_payload,
            );
        }

        return {
            kind => 'map',
            member_order => \@member_order,
            members => \%canonical_members,
        };
    }

    confess
        "$context is blocked because parameter/generic values must be scalar integer literals or non-empty list/map aggregate payloads.".
        $docs_hint."\n";
}

sub _canonical_scalar_value_text ($class, $value, $context, $docs_hint) {
    confess
        "$context is blocked because parameter/generic values must be scalar integer literals, not aggregate payloads.".
        $docs_hint."\n"
        unless defined($value) && !ref($value) && length($value);

    my $text = $value;

    if (FSM::Package::IntegerLiteralSupport->obviously_binary_like_bare_value_literal($text)) {
        my ($binary_example, $decimal_example, $exact_width_example) =
            FSM::Package::IntegerLiteralSupport->explicit_examples_for_obviously_binary_like_bare_value_literal($text);

        confess
            "$context is blocked because parameter/generic scalar value '$text' is an ambiguous bare integer literal. ".
            "FSMGen does not guess obviously bitstring-like bare 0/1 tokens in parameter/generic value position. ".
            "Use '$binary_example' for intrinsic-width binary, '$exact_width_example' for exact-width binary, or '$decimal_example' if decimal was intended.".
            $docs_hint."\n";
    }

    return _canonical_decimal($text) if $text =~ /\A-?[0-9](?:_?[0-9])*\z/;

    if ($text =~ /\A(-?)([0-9](?:_?[0-9])*)'(s?)([bBoOdDhH])([A-Fa-f0-9](?:_?[A-Fa-f0-9])*)\z/) {
        return _canonical_sv_based_literal($context, $docs_hint, $1, $2, $3, $4, $5);
    }

    if ($text =~ /\A'(s?)([bBoOdDhH])([A-Fa-f0-9](?:_?[A-Fa-f0-9])*)\z/) {
        return _canonical_unsized_sv_based_literal($context, $docs_hint, $1, $2, $3);
    }

    if ($text =~ /\A0x([A-Fa-f0-9](?:_?[A-Fa-f0-9])*)\z/i) {
        my $digits = _strip_underscores($1);
        return "'h".uc($digits);
    }

    if ($text =~ /\A0b([01](?:_?[01])*)\z/i) {
        return "'b"._strip_underscores($1);
    }

    if ($text =~ /\A0o([0-7](?:_?[0-7])*)\z/i) {
        return "'o"._strip_underscores($1);
    }

    if ($text =~ /\A0d(-?[0-9](?:_?[0-9])*)\z/i) {
        return _canonical_decimal($1);
    }

    confess
        "$context is blocked because parameter/generic values currently accept scalar integer literals such as 8, 8'hA5, 'hA5, 0xA5, 0b1010, or 0o77, but saw '$text'.".
        $docs_hint."\n";
}

sub _canonical_expression_payload ($class, $value_ast, $context, $docs_hint, $resolve_symbol_payload = undef) {
    my $expr_ast = $value_ast;
    while (ref($expr_ast) eq 'ARRAY' && @$expr_ast == 1 && ref($expr_ast->[0]) eq 'ARRAY') {
        $expr_ast = $expr_ast->[0];
    }

    return undef unless ref($expr_ast) eq 'ARRAY' && @$expr_ast;

    my ($operator, @operands) = @$expr_ast;
    return undef if ref($operator);

    my $normalized_operator = $class->_normalize_scalar_expression_operator($operator);
    return undef unless defined $normalized_operator;

    if ($class->_is_unary_aggregate_expression_operator($normalized_operator)) {
        my @defined_operands = grep { defined } @operands;
        my $has_flat_multi_operand_list =
            @defined_operands == 1
            && ref($defined_operands[0]) eq 'ARRAY'
            && @{$defined_operands[0]} > 1
            && !grep { ref } @{$defined_operands[0]};

        confess
            "$context is blocked because aggregate parameter/generic expression operator '$operator' requires exactly 1 operand.".
            $docs_hint."\n"
            unless @defined_operands == 1 && !$has_flat_multi_operand_list;

        my $operand_payload = $class->_canonical_payload(
            $defined_operands[0],
            "$context expression operand for '$operator'",
            $docs_hint,
            $resolve_symbol_payload,
        );
        return $class->_canonical_unary_aggregate_expression_payload(
            $normalized_operator,
            $operator,
            $operand_payload,
            $context,
            $docs_hint,
        );
    }

    if (@operands == 1 && ref($operands[0]) eq 'ARRAY') {
        @operands = @{$operands[0]};
    }

    confess
        "$context is blocked because scalar parameter/generic expression operator '$operator' requires at least 2 operands.".
        $docs_hint."\n"
        unless @operands >= 2;

    my @operand_payloads = map {
        $class->_canonical_payload(
            $_,
            "$context expression operand for '$operator'",
            $docs_hint,
            $resolve_symbol_payload,
        )
    } @operands;

    my $saw_aggregate_operand = 0;
    for my $operand_payload (@operand_payloads) {
        my $operand_kind = ref($operand_payload) eq 'HASH' ? ($operand_payload->{kind} || '') : '';
        $saw_aggregate_operand = 1
            if $operand_kind eq 'list' || $operand_kind eq 'map';
    }

    return $class->_canonical_aggregate_expression_payload(
        $normalized_operator,
        $operator,
        \@operand_payloads,
        $context,
        $docs_hint,
    ) if $saw_aggregate_operand;

    my @operand_texts = map {
        $class->_scalar_expression_operand_text_from_payload(
            $_,
            "$context expression operand for '$operator'",
            $docs_hint,
        )
    } @operand_payloads;

    return {
        kind => 'scalar_expr',
        payload => '(' . join(" $normalized_operator ", @operand_texts) . ')',
    };
}

sub _canonical_aggregate_expression_payload ($class, $normalized_operator, $display_operator, $operand_payloads, $context, $docs_hint) {
    confess
        "$context is blocked because aggregate parameter/generic expressions currently support only matching-shape leafwise operators '+', '-', '*', '/', '%', '&', '|', '^' and aliases 'add', 'sub', 'mul', 'div', 'mod', 'and', 'or', 'xor', binary aggregate comparison operators '==' and '!=', plus unary '~' and 'not', but saw operator '$display_operator'.".
        $docs_hint."\n"
        unless $class->_is_aggregate_expression_operator($normalized_operator);

    confess
        "$context is blocked because aggregate parameter/generic comparison operator '$display_operator' requires exactly 2 operands.".
        $docs_hint."\n"
        if $class->_is_aggregate_comparison_expression_operator($normalized_operator)
            && @$operand_payloads != 2;

    my $first_payload = $operand_payloads->[0];
    my $first_kind = ref($first_payload) eq 'HASH' ? ($first_payload->{kind} || '') : '';
    confess
        "$context is blocked because aggregate parameter/generic expression operator '$display_operator' requires all operands to be aggregate values with matching shape, but operand 1 resolved to '$first_kind'.".
        $docs_hint."\n"
        unless $first_kind eq 'list' || $first_kind eq 'map';

    my $first_type_spec = FSM::Package::PayloadTypeSupport->payload_to_type_spec($first_payload);
    confess
        "$context is blocked because aggregate parameter/generic expression operator '$display_operator' could not infer a packed aggregate type for operand 1.".
        $docs_hint."\n"
        unless ref($first_type_spec) eq 'HASH';

    for my $operand_index (1 .. $#$operand_payloads) {
        my $operand_payload = $operand_payloads->[$operand_index];
        my $operand_kind = ref($operand_payload) eq 'HASH' ? ($operand_payload->{kind} || '') : '';
        confess
            "$context is blocked because aggregate parameter/generic expression operator '$display_operator' requires all operands to be aggregate values with matching shape, but operand ".($operand_index + 1)." resolved to '$operand_kind'.".
            $docs_hint."\n"
            unless $operand_kind eq 'list' || $operand_kind eq 'map';

        my $operand_type_spec = FSM::Package::PayloadTypeSupport->payload_to_type_spec($operand_payload);
        confess
            "$context is blocked because aggregate parameter/generic expression operator '$display_operator' could not infer a packed aggregate type for operand ".($operand_index + 1).".".
            $docs_hint."\n"
            unless ref($operand_type_spec) eq 'HASH';

        my $matches_first = FSM::Package::PayloadTypeSupport->payload_compatible_with_type_spec(
            $operand_type_spec,
            $first_type_spec,
        ) && FSM::Package::PayloadTypeSupport->payload_compatible_with_type_spec(
            $first_type_spec,
            $operand_type_spec,
        );
        confess
            "$context is blocked because aggregate parameter/generic expression operator '$display_operator' requires matching aggregate shapes; operand 1 is '".
            FSM::Package::PayloadTypeSupport->type_spec_label($first_type_spec).
            "' but operand ".($operand_index + 1)." is '".
            FSM::Package::PayloadTypeSupport->type_spec_label($operand_type_spec).
            "'.".
            $docs_hint."\n"
            unless $matches_first;
    }

    return $class->_canonical_aggregate_comparison_expression_payload(
        $normalized_operator,
        $display_operator,
        $operand_payloads,
        $context,
        $docs_hint,
    ) if $class->_is_aggregate_comparison_expression_operator($normalized_operator);

    return $class->_apply_aggregate_expression_operator(
        $normalized_operator,
        $operand_payloads,
        "$context aggregate expression operator '$display_operator'",
        $docs_hint,
    );
}

sub _canonical_unary_aggregate_expression_payload ($class, $normalized_operator, $display_operator, $operand_payload, $context, $docs_hint) {
    my $operand_kind = ref($operand_payload) eq 'HASH' ? ($operand_payload->{kind} || '') : '';
    confess
        "$context is blocked because aggregate parameter/generic expression operator '$display_operator' requires one aggregate operand, but operand 1 resolved to '$operand_kind'.".
        $docs_hint."\n"
        unless $operand_kind eq 'list' || $operand_kind eq 'map';

    my $operand_type_spec = FSM::Package::PayloadTypeSupport->payload_to_type_spec($operand_payload);
    confess
        "$context is blocked because aggregate parameter/generic expression operator '$display_operator' could not infer a packed aggregate type for operand 1.".
        $docs_hint."\n"
        unless ref($operand_type_spec) eq 'HASH';

    return $class->_apply_aggregate_expression_operator(
        $normalized_operator,
        [ $operand_payload ],
        "$context aggregate expression operator '$display_operator'",
        $docs_hint,
    );
}

sub _scalar_expression_operand_text_from_payload ($class, $operand_payload, $context, $docs_hint) {
    my $operand_kind = ref($operand_payload) eq 'HASH' ? ($operand_payload->{kind} || '') : '';
    return $operand_payload->{payload}
        if ($operand_kind eq 'scalar' || $operand_kind eq 'scalar_expr')
            && defined($operand_payload->{payload})
            && !ref($operand_payload->{payload});

    confess
        "$context is blocked because scalar parameter/generic expressions may use only scalar operands, but this operand resolved to '$operand_kind'.".
        $docs_hint."\n";
}

sub _normalize_scalar_expression_operator ($class, $operator) {
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
        not => '~',
    );

    my $normalized = $operator_aliases{$operator} // $operator;
    my %supported = map { $_ => 1 } qw(+ - * / % & | ^ ~ == !=);
    return $supported{$normalized} ? $normalized : undef;
}

sub _is_unary_aggregate_expression_operator ($class, $operator) {
    return defined($operator) && !ref($operator) && $operator eq '~';
}

sub _is_aggregate_expression_operator ($class, $operator) {
    return defined($operator) && !ref($operator) && (
        $operator eq '+'
        || $operator eq '-'
        || $operator eq '*'
        || $operator eq '/'
        || $operator eq '%'
        || $operator eq '&'
        || $operator eq '|'
        || $operator eq '^'
        || $operator eq '~'
        || $operator eq '=='
        || $operator eq '!='
    );
}

sub _is_aggregate_comparison_expression_operator ($class, $operator) {
    return defined($operator) && !ref($operator) && (
        $operator eq '=='
        || $operator eq '!='
    );
}

sub _canonical_aggregate_comparison_expression_payload ($class, $operator, $display_operator, $payloads, $context, $docs_hint) {
    my @bitstrings;
    my $expected_width;
    for my $operand_index (0 .. $#$payloads) {
        my ($bits, $width, $reason) =
            FSM::Package::PayloadLiteralSupport->payload_to_bits_and_width($payloads->[$operand_index]);
        confess
            "$context is blocked because aggregate parameter/generic comparison operator '$display_operator' operand ".($operand_index + 1)." did not lower to bits; reason '$reason'.".
            $docs_hint."\n"
            unless defined($bits) && defined($width) && $width > 0;
        if (defined $expected_width) {
            confess
                "$context is blocked because aggregate parameter/generic comparison operator '$display_operator' operand widths must match; expected width $expected_width but operand ".($operand_index + 1)." has width $width.".
                $docs_hint."\n"
                unless $width == $expected_width;
        } else {
            $expected_width = $width;
        }
        push @bitstrings, $bits;
    }

    my $equal = $bitstrings[0] eq $bitstrings[1] ? 1 : 0;
    my $result = $operator eq '==' ? $equal : !$equal;
    return {
        kind => 'scalar',
        payload => "1'b".($result ? '1' : '0'),
    };
}

sub _apply_aggregate_expression_operator ($class, $operator, $payloads, $context, $docs_hint) {
    my $first_payload = $payloads->[0];
    my $kind = ref($first_payload) eq 'HASH' ? ($first_payload->{kind} || '') : '';

    if ($kind eq 'scalar') {
        return $class->_apply_scalar_leaf_operator(
            $operator,
            $payloads,
            $context,
            $docs_hint,
        );
    }

    if ($kind eq 'list') {
        my $items = $first_payload->{items} || [];
        my @result_items;
        for my $item_index (0 .. $#$items) {
            push @result_items, $class->_apply_aggregate_expression_operator(
                $operator,
                [ map { ($_->{items} || [])->[$item_index] } @$payloads ],
                "$context item $item_index",
                $docs_hint,
            );
        }

        return {
            kind => 'list',
            items => \@result_items,
        };
    }

    if ($kind eq 'map') {
        my $member_order = $first_payload->{member_order} || [];
        my %result_members;
        for my $member_name (@$member_order) {
            $result_members{$member_name} = $class->_apply_aggregate_expression_operator(
                $operator,
                [ map { ($_->{members} || {})->{$member_name} } @$payloads ],
                "$context member '$member_name'",
                $docs_hint,
            );
        }

        return {
            kind => 'map',
            member_order => [ @$member_order ],
            members => \%result_members,
        };
    }

    confess
        "$context is blocked because aggregate parameter/generic expressions require scalar/list/map payloads, but saw '$kind'.".
        $docs_hint."\n";
}

sub _apply_scalar_leaf_operator ($class, $operator, $payloads, $context, $docs_hint) {
    return $class->_apply_scalar_bitwise_operator($operator, $payloads, $context, $docs_hint)
        if $operator eq '&' || $operator eq '|' || $operator eq '^' || $operator eq '~';

    return $class->_apply_scalar_arithmetic_operator($operator, $payloads, $context, $docs_hint)
        if $operator eq '+' || $operator eq '-' || $operator eq '*' || $operator eq '/' || $operator eq '%';

    confess
        "$context is blocked because internal aggregate expression folding saw unsupported operator '$operator'.".
        $docs_hint."\n";
}

sub _aggregate_leaf_bitstrings_and_width ($class, $payloads, $context, $docs_hint) {
    my @bitstrings;
    my $expected_width;

    for my $operand_index (0 .. $#$payloads) {
        my ($bits, $width, $reason) = FSM::Package::PayloadLiteralSupport->payload_to_bits_and_width($payloads->[$operand_index]);
        confess
            "$context is blocked because scalar leaf operand ".($operand_index + 1)." did not lower to bits for aggregate expression folding; reason '$reason'.".
            $docs_hint."\n"
            unless defined($bits) && defined($width) && $width > 0;
        if (defined $expected_width) {
            confess
                "$context is blocked because scalar leaf operand widths must match for aggregate expression folding; expected width $expected_width but operand ".($operand_index + 1)." has width $width.".
                $docs_hint."\n"
                unless $width == $expected_width;
        } else {
            $expected_width = $width;
        }
        push @bitstrings, $bits;
    }

    return (\@bitstrings, $expected_width);
}

sub _apply_scalar_bitwise_operator ($class, $operator, $payloads, $context, $docs_hint) {
    my ($bitstrings, $expected_width) = $class->_aggregate_leaf_bitstrings_and_width($payloads, $context, $docs_hint);

    my @result_bits = split //, $bitstrings->[0];
    if ($operator eq '~') {
        @result_bits = map { $_ eq '1' ? '0' : '1' } @result_bits;
        return {
            kind => 'scalar',
            payload => $expected_width."'b".join('', @result_bits),
        };
    }

    for my $operand_index (1 .. $#$bitstrings) {
        my @operand_bits = split //, $bitstrings->[$operand_index];
        for my $bit_index (0 .. $#result_bits) {
            if ($operator eq '&') {
                $result_bits[$bit_index] = ($result_bits[$bit_index] eq '1' && $operand_bits[$bit_index] eq '1') ? '1' : '0';
            } elsif ($operator eq '|') {
                $result_bits[$bit_index] = ($result_bits[$bit_index] eq '1' || $operand_bits[$bit_index] eq '1') ? '1' : '0';
            } elsif ($operator eq '^') {
                $result_bits[$bit_index] = ($result_bits[$bit_index] ne $operand_bits[$bit_index]) ? '1' : '0';
            } else {
                confess
                    "$context is blocked because internal aggregate expression folding saw unsupported bitwise operator '$operator'.".
                    $docs_hint."\n";
            }
        }
    }

    return {
        kind => 'scalar',
        payload => $expected_width."'b".join('', @result_bits),
    };
}

sub _apply_scalar_arithmetic_operator ($class, $operator, $payloads, $context, $docs_hint) {
    my ($bitstrings, $expected_width) = $class->_aggregate_leaf_bitstrings_and_width($payloads, $context, $docs_hint);
    my @values = map { Math::BigInt->from_bin('0b'.$_) } @$bitstrings;
    my $result = shift @values;

    for my $operand_index (0 .. $#values) {
        my $operand_number = $operand_index + 2;
        my $operand_value = $values[$operand_index];

        if ($operator eq '+') {
            $result = $result + $operand_value;
        } elsif ($operator eq '-') {
            $result = $result - $operand_value;
        } elsif ($operator eq '*') {
            $result = $result * $operand_value;
        } elsif ($operator eq '/') {
            confess
                "$context is blocked because aggregate arithmetic division by zero is not a valid parameter/generic leaf value; operand $operand_number is zero.".
                $docs_hint."\n"
                if $operand_value->is_zero();
            $result = $result / $operand_value;
        } elsif ($operator eq '%') {
            confess
                "$context is blocked because aggregate arithmetic modulo by zero is not a valid parameter/generic leaf value; operand $operand_number is zero.".
                $docs_hint."\n"
                if $operand_value->is_zero();
            $result = $result % $operand_value;
        } else {
            confess
                "$context is blocked because internal aggregate expression folding saw unsupported arithmetic operator '$operator'.".
                $docs_hint."\n";
        }
    }

    confess
        "$context is blocked because aggregate arithmetic operator '$operator' underflows leaf width $expected_width.".
        $docs_hint."\n"
        if $result->bcmp(0) < 0;

    my $max_value = Math::BigInt->new(2);
    $max_value->bpow($expected_width);
    $max_value->bsub(1);
    confess
        "$context is blocked because aggregate arithmetic operator '$operator' overflows leaf width $expected_width.".
        $docs_hint."\n"
        if $result->bcmp($max_value) > 0;

    my $result_bits = $result->as_bin();
    $result_bits =~ s/\A0b//;
    $result_bits = '0' unless length $result_bits;
    $result_bits = ('0' x ($expected_width - length($result_bits))) . $result_bits
        if length($result_bits) < $expected_width;

    return {
        kind => 'scalar',
        payload => $expected_width."'b".$result_bits,
    };
}

sub _unwrap_scalar_token ($class, $value) {
    my $unwrapped = $value;
    while (ref($unwrapped) eq 'ARRAY' && @$unwrapped == 1) {
        $unwrapped = $unwrapped->[0];
    }
    return $unwrapped;
}

sub _value_items ($class, $value_ast) {
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

sub _is_contract_identifier ($class, $value) {
    return defined($value)
        && !ref($value)
        && $value =~ /\A[A-Za-z_]\w*\z/;
}

sub _canonical_decimal ($text) {
    return _strip_underscores($text);
}

sub _canonical_sv_based_literal ($context, $docs_hint, $sign, $width, $signed, $base, $digits) {
    my $canonical_width = _strip_underscores($width);
    confess
        "$context is blocked because parameter/generic literal widths must be positive, but saw width '$width'.".
        $docs_hint."\n"
        if $canonical_width == 0;

    my $canonical_base = lc($base);
    my $canonical_digits = _validated_digits($context, $docs_hint, $canonical_base, $digits);
    return ($sign // '').$canonical_width."'".lc($signed // '').$canonical_base.$canonical_digits;
}

sub _canonical_unsized_sv_based_literal ($context, $docs_hint, $signed, $base, $digits) {
    my $canonical_base = lc($base);
    my $canonical_digits = _validated_digits($context, $docs_hint, $canonical_base, $digits);
    return "'".lc($signed // '').$canonical_base.$canonical_digits;
}

sub _validated_digits ($context, $docs_hint, $base, $digits) {
    my $canonical_digits = _strip_underscores($digits);

    my $valid = (
        $base eq 'b' ? ($canonical_digits =~ /\A[01]+\z/)
      : $base eq 'o' ? ($canonical_digits =~ /\A[0-7]+\z/)
      : $base eq 'd' ? ($canonical_digits =~ /\A[0-9]+\z/)
      : $base eq 'h' ? ($canonical_digits =~ /\A[A-Fa-f0-9]+\z/)
      : 0
    );

    confess
        "$context is blocked because parameter/generic literal digits '$digits' are not valid for base '$base'.".
        $docs_hint."\n"
        unless $valid;

    return $base eq 'h' ? uc($canonical_digits) : $canonical_digits;
}

sub _strip_underscores ($text) {
    $text =~ s/_//g;
    return $text;
}

sub _clone_payload ($class, $value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return { map { $_ => $class->_clone_payload($value->{$_}) } keys %$value };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { $class->_clone_payload($_) } @$value ];
    }

    return $value;
}

1;

__END__

=head1 METHODS

=head2 canonical_value_text

Returns backend-ready literal text for the bounded parameter/generic scalar and
aggregate value surface.

=cut
