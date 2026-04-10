#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;
use FSM::Package::AggregateExpressionTypeSupport;
use FSM::Package::PayloadTypeSupport;

my $payload_t = {
    kind => 'list',
    width => 3,
    signed => 0,
    items => [
        { kind => 'bit', width => 1, signed => 0 },
        { kind => 'bits', width => 2, signed => 0 },
    ],
};

my $bad_payload_t = {
    kind => 'record',
    width => 3,
    signed => 0,
    member_order => [qw(mode flag)],
    members => {
        mode => { kind => 'bits', width => 2, signed => 0 },
        flag => { kind => 'bit', width => 1, signed => 0 },
    },
};

my $frame_t = {
    kind => 'record',
    width => 7,
    signed => 0,
    member_order => [qw(tag payload)],
    members => {
        tag => { kind => 'bits', width => 4, signed => 0 },
        payload => $payload_t,
    },
};

my $flag = signal('FLAG', 1);
my $data = signal('DATA', 2);
my $tag = signal('TAG', 4);
my $payload = signal('PAYLOAD', 3, $payload_t);
my $bad_payload = signal('BAD_PAYLOAD', 3, $bad_payload_t);
my $out = signal('OUT', 7, $frame_t);

subtest 'concat expression support infers list and record aggregate contracts' => sub {
    my $payload_concat = concat(ref_($flag), ref_($data));
    my $payload_contract = FSM::Package::AggregateExpressionTypeSupport->concat_expression_type_spec_for_target(
        source_expr => $payload_concat,
        target_expr => ref_($payload),
        width_resolver => \&exact_width,
    );

    is(
        FSM::Package::PayloadTypeSupport->type_spec_label($payload_contract),
        'list<bit, bits[2]>',
        'list target compares against ordered concat operand list shape',
    );

    my $nested_contract = FSM::Package::AggregateExpressionTypeSupport->concat_expression_list_type_spec(
        concat($payload_concat, ref_($tag)),
        width_resolver => \&exact_width,
    );

    is(
        FSM::Package::PayloadTypeSupport->type_spec_label($nested_contract),
        'list<list<bit, bits[2]>, bits[4]>',
        'nested concat operands keep nested list shape',
    );

    my $record_contract = FSM::Package::AggregateExpressionTypeSupport->concat_expression_type_spec_for_target(
        source_expr => concat(ref_($tag), ref_($payload)),
        target_expr => ref_($out),
        width_resolver => \&exact_width,
    );

    is(
        FSM::Package::PayloadTypeSupport->type_spec_label($record_contract),
        'record{tag:bits[4], payload:list<bit, bits[2]>}',
        'record target maps exact concat operands onto record member order',
    );

    my $bad_record_contract = FSM::Package::AggregateExpressionTypeSupport->concat_expression_type_spec_for_target(
        source_expr => concat(ref_($tag), ref_($bad_payload)),
        target_expr => ref_($out),
        width_resolver => \&exact_width,
    );

    is(
        FSM::Package::PayloadTypeSupport->type_spec_label($bad_record_contract),
        'record{tag:bits[4], payload:record{mode:bits[2], flag:bit}}',
        'record mapping preserves wrong nested member shape so validation can reject it',
    );
};

done_testing();

sub signal {
    my ($name, $width, $declared_type_spec) = @_;
    return FSM::CoreAST::Signal->new(
        name => $name,
        width => $width,
        defined($declared_type_spec) ? (declared_type_spec => $declared_type_spec) : (),
    );
}

sub ref_ {
    my ($signal, %args) = @_;
    return FSM::CoreAST::SignalRef->new($signal, %args);
}

sub concat {
    return FSM::CoreAST::Concatenation->new(@_);
}

sub exact_width {
    my ($expr) = @_;
    return unless $expr && blessed($expr);

    if ($expr->isa('FSM::CoreAST::SignalRef')) {
        if ($expr->slice) {
            my ($high, $low) = @{$expr->slice};
            return abs($high - $low) + 1;
        }
        return $expr->signal->width if $expr->signal && $expr->signal->can('width');
    }

    if ($expr->isa('FSM::CoreAST::IndexedRef')) {
        return 1;
    }

    if ($expr->isa('FSM::CoreAST::Concatenation')) {
        my $width = 0;
        for my $operand (@{$expr->operands || []}) {
            my $operand_width = exact_width($operand);
            return unless defined($operand_width) && $operand_width > 0;
            $width += $operand_width;
        }
        return $width if $width > 0;
    }

    return $expr->width if $expr->can('width') && defined($expr->width);
    return;
}
