#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    binding_expr
    binding_expr_text
    binding_signal_name
    binding_signal_names
    bit_select_expr
    concat_expr
    normalized_binding
    signal_ref_expr
);

subtest 'binding_expr returns caller-owned connection-expression snapshots' => sub {
    my $binding = {
        port_name => 'data_in',
        signal_name => '',
        connection_expr => concat_expr(
            bit_select_expr(signal_ref_expr('payload'), 7),
            bit_select_expr(signal_ref_expr('payload'), 0),
        ),
    };

    my $expr = binding_expr($binding);
    $expr->{operands}[0]{source_expr}{signal_name} = 'mutated_payload';
    push @{$expr->{operands}}, signal_ref_expr('late_payload');

    is_deeply(
        binding_expr($binding),
        concat_expr(
            bit_select_expr(signal_ref_expr('payload'), 7),
            bit_select_expr(signal_ref_expr('payload'), 0),
        ),
        'mutating returned binding expression cannot contaminate binding storage',
    );
    is_deeply(
        binding_signal_names($binding),
        ['payload'],
        'signal-name recovery still reads the stored binding expression',
    );
    is(
        binding_expr_text($binding, 'systemverilog'),
        '{payload[7], payload[0]}',
        'rendering still reads the stored binding expression',
    );
};

subtest 'derived binding helpers keep cloned expression metadata boundaries' => sub {
    my $binding = {
        port_name => 'flag_out',
        signal_name => '',
        connection_expr => bit_select_expr(signal_ref_expr('status'), 1),
        connection_type_spec => {
            kind => 'packed',
            dimensions => [ { msb => 0, lsb => 0 } ],
        },
    };

    my $normalized = normalized_binding($binding);
    $normalized->{connection_expr}{source_expr}{signal_name} = 'mutated_status';
    $normalized->{connection_type_spec}{dimensions}[0]{msb} = 99;

    is(
        binding_signal_name($binding),
        '',
        'compound binding keeps scalar signal-name accessor unchanged',
    );
    is(
        binding_expr_text($binding, 'systemverilog'),
        'status[1]',
        'normalized-binding mutation cannot contaminate binding expression text',
    );
    is(
        $binding->{connection_type_spec}{dimensions}[0]{msb},
        0,
        'normalized-binding mutation cannot contaminate binding type metadata',
    );
};

done_testing();
