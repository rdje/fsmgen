#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    signal_ref_expr
    signal_ref_binding
    update_binding_signal_ref
    binding_expr
    expr_signal_name
    binding_signal_name
    binding_expr_text
);

subtest 'signal_ref helper builds the first bounded structural connection node' => sub {
    is_deeply(
        signal_ref_expr('top_data'),
        {
            kind => 'signal_ref',
            signal_name => 'top_data',
        },
        'signal_ref helper returns the backend-neutral signal_ref expression shape',
    );

    is(
        expr_signal_name(signal_ref_expr('top_data')),
        'top_data',
        'expr signal-name recovery understands the bounded signal_ref form',
    );

    is_deeply(
        signal_ref_binding('data_in', 'top_data'),
        {
            port_name => 'data_in',
            signal_name => 'top_data',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'top_data',
            },
        },
        'signal_ref binding helper builds the bounded binding payload with both compatibility and typed fields',
    );
};

subtest 'binding signal-name lookup prefers the typed connection expression when present' => sub {
    is(
        binding_signal_name({
            port_name => 'data_in',
            signal_name => 'stale_mirror',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'typed_source',
            },
        }),
        'typed_source',
        'binding signal-name recovery follows the typed expression instead of the compatibility mirror',
    );

    is(
        binding_signal_name({
            port_name => 'data_in',
            signal_name => 'fallback_name',
        }),
        'fallback_name',
        'binding signal-name recovery still falls back to the mirrored signal_name field',
    );

    is_deeply(
        binding_expr({
            port_name => 'data_in',
            signal_name => 'fallback_name',
        }),
        {
            kind => 'signal_ref',
            signal_name => 'fallback_name',
        },
        'binding expression recovery synthesizes the bounded signal_ref node from the compatibility mirror when needed',
    );
};

subtest 'binding expression text rendering stays backend-neutral for the bounded signal_ref case' => sub {
    is(
        binding_expr_text({
            port_name => 'data_in',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'typed_source',
            },
        }),
        'typed_source',
        'binding text rendering emits the signal name for the current bounded signal_ref form',
    );

    is(
        binding_expr_text({
            port_name => 'data_in',
            signal_name => 'fallback_name',
        }),
        'fallback_name',
        'binding text rendering still supports the mirrored signal_name fallback path',
    );
};

subtest 'signal_ref binding updates keep compatibility and typed fields aligned' => sub {
    my $binding = signal_ref_binding('data_in', 'old_data');

    is(
        update_binding_signal_ref($binding, 'new_data'),
        $binding,
        'signal_ref binding update returns the same binding reference for in-place callers',
    );

    is_deeply(
        $binding,
        {
            port_name => 'data_in',
            signal_name => 'new_data',
            connection_expr => {
                kind => 'signal_ref',
                signal_name => 'new_data',
            },
        },
        'signal_ref binding update keeps the compatibility and typed fields aligned',
    );
};

subtest 'unsupported structural connection kinds fail explicitly' => sub {
    my $error = eval {
        binding_expr_text({
            port_name => 'data_in',
            connection_expr => {
                kind => 'concat',
            },
        });
        undef;
    };

    like(
        $@,
        qr/unsupported connection_expr kind 'concat'/,
        'unsupported structural connection kinds fail with clear bounded wording',
    );
};

done_testing();
