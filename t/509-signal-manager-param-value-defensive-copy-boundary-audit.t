#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::FSMGenFull::SignalManager;

sub frame_value_info {
    return {
        value_text => q{9'b101010101},
        value_kind => 'map',
        value_width => 9,
        value_payload => {
            kind => 'map',
            member_order => [qw(flag payload)],
            members => {
                flag => { kind => 'scalar', payload => q{1'b1} },
                payload => { kind => 'scalar', payload => q{8'h55} },
            },
        },
        value_type_spec => {
            kind => 'record',
            width => 9,
            member_order => [qw(flag payload)],
            members => {
                flag => { kind => 'bit', width => 1 },
                payload => { kind => 'bits', width => 8 },
            },
        },
    };
}

sub expected_payload {
    return frame_value_info()->{value_payload};
}

sub expected_type_spec {
    return frame_value_info()->{value_type_spec};
}

subtest 'stored parameter records are isolated from caller-owned input' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    my $value_info = frame_value_info();

    $signal_manager->store_param('FRAME_PARAM', $value_info);
    $value_info->{value_payload}{members}{payload}{payload} = q{8'h00};
    $value_info->{value_type_spec}{members}{payload}{width} = 99;
    $value_info->{value_text} = q{9'b0};

    is_deeply(
        $signal_manager->resolve_parameter_value_symbol_payload('FRAME_PARAM'),
        expected_payload(),
        'exact parameter payload lookup reads from the stored snapshot',
    );

    my $parameter_ref = $signal_manager->resolve_symbol('FRAME_PARAM');
    ok($parameter_ref->isa('FSM::CoreAST::ParameterRef'), 'parameter resolves to a ParameterRef');
    is($parameter_ref->default_value_text, q{9'b101010101}, 'ParameterRef default text reads from stored snapshot');
    is_deeply($parameter_ref->type_spec, expected_type_spec(), 'ParameterRef type spec reads from stored snapshot');
    is_deeply($parameter_ref->value_info->{value_payload}, expected_payload(), 'ParameterRef value info reads from stored snapshot');
};

subtest 'parameter payload lookup results remain caller-owned' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    $signal_manager->store_param('FRAME_PARAM', frame_value_info());

    my $first_payload = $signal_manager->resolve_parameter_value_symbol_payload('FRAME_PARAM');
    $first_payload->{members}{payload}{payload} = q{8'h00};

    is_deeply(
        $signal_manager->resolve_parameter_value_symbol_payload('FRAME_PARAM'),
        expected_payload(),
        'exact parameter payload lookup returns a fresh payload',
    );

    my $payload_member = $signal_manager->resolve_parameter_value_symbol_payload('FRAME_PARAM.payload');
    $payload_member->{payload} = q{8'h00};

    is_deeply(
        $signal_manager->resolve_parameter_value_symbol_payload('FRAME_PARAM.payload'),
        { kind => 'scalar', payload => q{8'h55} },
        'parameter payload suffix lookup returns a fresh payload',
    );
};

done_testing;
