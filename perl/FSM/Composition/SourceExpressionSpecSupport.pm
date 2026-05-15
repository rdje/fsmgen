package FSM::Composition::SourceExpressionSpecSupport;

=head1 NAME

FSM::Composition::SourceExpressionSpecSupport - Composition source-expression parsing

=head1 DESCRIPTION

Owns the bounded source-expression spec parser used by explicit composition
wiring blocks. The linked-plan builder consumes these specs during endpoint
resolution, but parsing concat/repeat/source operand forms lives here.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::ActualLiteralSupport;
use FSM::Package::PayloadLiteralSupport;

sub top_expression_spec ($class, $endpoint, %opts) {
    return $class->parse_top_expression_spec(
        $endpoint,
        %opts,
        allow_plain_top_ref => 0,
        allow_literal_actual => 0,
    );
}

sub top_expression_base_port_name ($class, $endpoint, %opts) {
    my $spec = $class->top_expression_spec($endpoint, %opts);
    return undef unless $spec;
    return $spec->{port_name};
}

sub top_expression_inference_specs ($class, $endpoint, %opts) {
    my $spec = $class->top_expression_spec($endpoint, %opts);
    return [] unless $spec;
    return $class->collect_top_expression_inference_specs($spec);
}

sub top_expression_child_base_endpoints ($class, $endpoint, %opts) {
    my $spec = $class->top_expression_spec($endpoint, %opts);
    return [] unless $spec;

    my %seen_endpoint;
    my @base_endpoints;
    for my $child_spec (@{$class->collect_top_expression_child_specs($spec)}) {
        my $base_endpoint = $child_spec->{instance_name}.'.'.$child_spec->{port_name};
        next if $seen_endpoint{$base_endpoint}++;
        push @base_endpoints, $base_endpoint;
    }

    return \@base_endpoints;
}

sub child_expression_spec ($class, $endpoint) {
    return undef unless defined($endpoint) && !ref($endpoint);

    if ($endpoint =~ /\A(\w+)\.(\w+)\[(\d+)\]\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'bit_select',
            index => 0 + $3,
        };
    }

    if ($endpoint =~ /\A(\w+)\.(\w+)\[(\d+):(\d+)\]\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'slice',
            msb => 0 + $3,
            lsb => 0 + $4,
        };
    }

    if ($endpoint =~ /\A(\w+)\.(\w+)((?:\.[A-Za-z_]\w*|\[\d+(?::\d+)?\])+)\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'aggregate_ref',
            path_text => $3,
        };
    }

    return undef;
}

sub child_expression_base_endpoint ($class, $endpoint) {
    my $spec = $class->child_expression_spec($endpoint);
    return undef unless $spec;
    return $spec->{instance_name}.'.'.$spec->{port_name};
}

sub collect_top_expression_inference_specs ($class, $spec) {
    return [] unless ref($spec) eq 'HASH';

    my $expr_kind = $spec->{expr_kind} || '';
    if ($expr_kind eq 'bit_select' || $expr_kind eq 'slice') {
        return [_clone($spec)];
    }

    if ($expr_kind eq 'concat') {
        my @requirements;
        for my $operand_spec (@{$spec->{operands} || []}) {
            push @requirements, @{$class->collect_top_expression_inference_specs($operand_spec)};
        }
        return \@requirements;
    }

    if ($expr_kind eq 'repeat') {
        return $class->collect_top_expression_inference_specs($spec->{operand});
    }

    return [];
}

sub collect_top_expression_child_specs ($class, $spec) {
    return [] unless ref($spec) eq 'HASH';

    my $expr_kind = $spec->{expr_kind} || '';
    if ($expr_kind eq 'child_signal_ref' || $expr_kind eq 'child_bit_select' || $expr_kind eq 'child_slice' || $expr_kind eq 'child_aggregate_ref') {
        return [_clone($spec)];
    }

    if ($expr_kind eq 'concat') {
        my @child_specs;
        for my $operand_spec (@{$spec->{operands} || []}) {
            push @child_specs, @{$class->collect_top_expression_child_specs($operand_spec)};
        }
        return \@child_specs;
    }

    if ($expr_kind eq 'repeat') {
        return $class->collect_top_expression_child_specs($spec->{operand});
    }

    return [];
}

sub parse_top_expression_spec ($class, $endpoint, %opts) {
    return undef unless defined($endpoint) && length($endpoint);

    my $repeat_spec = $class->parse_repeat_group_spec($endpoint, %opts);
    return $repeat_spec if $repeat_spec;

    my $concat_payload = undef;
    if ($endpoint =~ /\A\{(.*)\}\z/s) {
        $concat_payload = $1;
    }
    elsif (index($endpoint, ',') >= 0) {
        $concat_payload = $endpoint;
    }

    if (defined $concat_payload) {
        my $operands = $class->split_concat_operands($concat_payload) or return undef;
        my @operand_specs;
        for my $operand (@$operands) {
            my $operand_spec = $class->parse_top_expression_spec(
                $operand,
                allow_plain_top_ref => 1,
                allow_literal_actual => 1,
                allow_child_ref => 1,
                top_symbols => $opts{top_symbols},
                fsm_file => $opts{fsm_file},
                header => $opts{header},
            ) or return undef;
            push @operand_specs, $operand_spec;
        }
        return {
            raw => $endpoint,
            expr_kind => 'concat',
            operands => \@operand_specs,
        };
    }

    if ($opts{allow_plain_top_ref} && $endpoint =~ /\A(\w+)\z/) {
        return {
            raw => $endpoint,
            port_name => $1,
            expr_kind => 'signal_ref',
        };
    }

    if ($opts{allow_child_ref} && $endpoint =~ /\A(\w+)\.(\w+)\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'child_signal_ref',
        };
    }

    if ($endpoint =~ /\A(\w+)\[(\d+)\]\z/) {
        return {
            raw => $endpoint,
            port_name => $1,
            expr_kind => 'bit_select',
            index => 0 + $2,
        };
    }

    if ($opts{allow_child_ref} && $endpoint =~ /\A(\w+)\.(\w+)\[(\d+)\]\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'child_bit_select',
            index => 0 + $3,
        };
    }

    if ($endpoint =~ /\A(\w+)\[(\d+):(\d+)\]\z/) {
        return {
            raw => $endpoint,
            port_name => $1,
            expr_kind => 'slice',
            msb => 0 + $2,
            lsb => 0 + $3,
        };
    }

    if ($opts{allow_child_ref} && $endpoint =~ /\A(\w+)\.(\w+)\[(\d+):(\d+)\]\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'child_slice',
            msb => 0 + $3,
            lsb => 0 + $4,
        };
    }

    if ($opts{allow_child_ref} && $endpoint =~ /\A(\w+)\.(\w+)((?:\.[A-Za-z_]\w*|\[\d+(?::\d+)?\])+)\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'child_aggregate_ref',
            path_text => $3,
        };
    }

    if ($endpoint =~ /\A(\w+)((?:\.[A-Za-z_]\w*|\[\d+(?::\d+)?\])+)\z/) {
        return {
            raw => $endpoint,
            port_name => $1,
            expr_kind => 'aggregate_ref',
            path_text => $2,
        };
    }

    if ($opts{allow_literal_actual} && $endpoint =~ /\A=(.+)\z/) {
        return undef if lc($1) eq 'open';
        my ($bits, $width) = FSM::Composition::ActualLiteralSupport->expression_literal_bits_and_width(
            $1,
            raw => "=$1",
            fsm_file => $opts{fsm_file},
            header => $opts{header},
        );
        if (!defined($bits) && $opts{top_symbols}) {
            my $resolved_payload = $class->resolve_top_symbol_actual_payload($1, $opts{top_symbols});
            ($bits, $width) = FSM::Composition::ActualLiteralSupport->expression_literal_bits_and_width(
                $resolved_payload,
                raw => "=$1",
                fsm_file => $opts{fsm_file},
                header => $opts{header},
            )
                if defined $resolved_payload;

            if (!defined($bits)) {
                my $aggregate_payload = $class->resolve_top_symbol_payload($1, $opts{top_symbols});
                if (defined $aggregate_payload) {
                    my $reason;
                    ($bits, $width, $reason) = FSM::Package::PayloadLiteralSupport->payload_to_bits_and_width($aggregate_payload);
                    if (!defined $bits) {
                        return {
                            raw => $endpoint,
                            expr_kind => 'unsupported_aggregate_literal',
                            symbol_name => $1,
                            reason => $reason,
                        };
                    }
                }
            }
        }
        return undef unless defined $bits;
        return {
            raw => $endpoint,
            expr_kind => 'literal',
            bits => $bits,
            width => $width,
        };
    }

    return undef;
}

sub parse_repeat_group_spec ($class, $endpoint, %opts) {
    return undef unless defined($endpoint) && $endpoint =~ /\A\{([1-9]\d*)\{(.*)\}\}\z/s;

    my ($repeat_count, $operand_text) = (0 + $1, $2);
    my $operand_spec = $class->parse_top_expression_spec(
        $operand_text,
        allow_plain_top_ref => 1,
        allow_literal_actual => 1,
        allow_child_ref => 1,
        top_symbols => $opts{top_symbols},
        fsm_file => $opts{fsm_file},
        header => $opts{header},
    ) or return undef;

    return {
        raw => $endpoint,
        expr_kind => 'repeat',
        repeat_count => $repeat_count,
        operand => $operand_spec,
    };
}

sub split_concat_operands ($class, $inner_text) {
    return undef unless defined $inner_text;

    my @operands;
    my $current = '';
    my $depth = 0;
    my @chars = split //, $inner_text;

    for my $char (@chars) {
        if ($char eq '{') {
            $depth++;
            $current .= $char;
            next;
        }

        if ($char eq '}') {
            return undef if $depth < 1;
            $depth--;
            $current .= $char;
            next;
        }

        if ($char eq ',' && $depth == 0) {
            my $operand = $current;
            $operand =~ s/\A\s+|\s+\z//g;
            return undef unless length $operand;
            push @operands, $operand;
            $current = '';
            next;
        }

        $current .= $char;
    }

    return undef if $depth != 0;

    $current =~ s/\A\s+|\s+\z//g;
    return undef unless length $current;
    push @operands, $current;

    return \@operands;
}

sub resolve_top_symbol_actual_payload ($class, $payload, $top_symbols) {
    return undef unless defined($payload) && !ref($payload);
    return undef unless $top_symbols && $top_symbols->can('resolve_actual_payload');

    my $resolved_payload = $top_symbols->resolve_actual_payload($payload);
    return undef unless defined($resolved_payload) && !ref($resolved_payload) && length($resolved_payload);

    return $resolved_payload;
}

sub resolve_top_symbol_payload ($class, $payload, $top_symbols) {
    return undef unless defined($payload) && !ref($payload);
    return undef unless $top_symbols && $top_symbols->can('resolve_payload');

    return $top_symbols->resolve_payload($payload);
}

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) } keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }

    return $value;
}

1;
