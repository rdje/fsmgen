#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Link;
use FSM::Composition::Port;
use FSM::Composition::RealizedInstance;
use FSM::Composition::TopLink;
use FSM::Composition::TopPortInferenceBuilder;

subtest 'explicit-toplink builder infers renamed top ports from child endpoints' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
        ports => [],
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => 'start', target => 'producer.go'),
                    FSM::Composition::Link->new(source => 'consumer.done', target => 'status'),
                ],
            ),
        ],
        realized_instances => [
            realized_instance('producer',
                input_port('clk', 1, 'clock'),
                input_port('rstn', 1, 'reset'),
                input_port('go', 1),
                output_port('payload', 8),
            ),
            realized_instance('consumer',
                input_port('clk', 1, 'clock'),
                input_port('rstn', 1, 'reset'),
                input_port('payload', 8),
                output_port('done', 1),
            ),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is_deeply(
        [map { [$_->name, $_->direction, $_->width, $_->origin_kind] } @$ports],
        [
            ['start',  'input',  1, 'inferred_explicit_toplink_port'],
            ['status', 'output', 1, 'inferred_explicit_toplink_port'],
        ],
        'builder keeps the bounded renamed explicit-toplink inference surface',
    );
};

subtest 'explicit-toplink builder infers undeclared top inputs from source-side top expressions' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
        ports => [],
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => 'payload_bus[15:8]', target => 'sink.data_in'),
                    FSM::Composition::Link->new(source => 'status_bus[0]', target => 'sink.enable'),
                ],
            ),
        ],
        realized_instances => [
            realized_instance('sink',
                input_port('data_in', 8),
                input_port('enable', 1),
            ),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is_deeply(
        [map { [$_->name, $_->direction, $_->width, $_->origin_kind] } @$ports],
        [
            ['payload_bus', 'input', 16, 'inferred_explicit_toplink_port'],
            ['status_bus',  'input',  1, 'inferred_explicit_toplink_port'],
        ],
        'builder infers undeclared top-input width from bounded top-expression evidence',
    );
};

subtest 'explicit-toplink builder infers undeclared top inputs from concat top-expression operands' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
        ports => [],
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => '{payload_hi[3:0],status_bus[0],payload_lo[3:0]}',
                        target => 'sink.frame_in',
                    ),
                ],
            ),
        ],
        realized_instances => [
            realized_instance('sink',
                input_port('frame_in', 9),
            ),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is_deeply(
        [map { [$_->name, $_->direction, $_->width, $_->origin_kind] } @$ports],
        [
            ['payload_hi', 'input', 4, 'inferred_explicit_toplink_port'],
            ['payload_lo', 'input', 4, 'inferred_explicit_toplink_port'],
            ['status_bus', 'input', 1, 'inferred_explicit_toplink_port'],
        ],
        'builder infers undeclared top-input widths from bounded concat top-expression operands',
    );
};

subtest 'explicit-toplink builder rejects incompatible exact-width and top-expression width evidence' => sub {
    my $exception = eval {
        FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => 'payload_bus[15:8]', target => 'sink.byte_in'),
                        FSM::Composition::Link->new(source => 'payload_bus', target => 'sink.full_in'),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance('sink',
                    input_port('byte_in', 8),
                    input_port('full_in', 8),
                ),
            ],
            fsm_file => 'fixture.fsm',
            header => 'fixture',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits top port 'payload_bus', .*top-expression evidence requires declared width at least 16, while another explicit top-link use fixes that same top port at width 8.*payload_bus\[15:8\] -> sink\.byte_in.*payload_bus -> sink\.full_in/s,
        'builder rejects exact-width evidence that is narrower than required top-expression width',
    );
};

subtest 'undeclared top-input builder infers shared same-name input fanout' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_undeclared_top_inputs(
        ports => [
            FSM::Composition::Port->new(name => 'result_data', direction => 'output', width => 8, binding_mode => 'explicit'),
        ],
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => 'left.output_data', target => 'result_data'),
                ],
            ),
        ],
        realized_instances => [
            realized_instance('left',
                input_port('clk', 1, 'clock'),
                input_port('rstn', 1, 'reset'),
                input_port('shared_cfg', 8),
                output_port('output_data', 8),
            ),
            realized_instance('right',
                input_port('clk', 1, 'clock'),
                input_port('rstn', 1, 'reset'),
                input_port('shared_cfg', 8),
                output_port('spare_out', 1),
            ),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is_deeply(
        [map { [$_->name, $_->direction, $_->binding_mode, $_->origin_kind] } @$ports],
        [
            ['result_data', 'output', 'explicit',         undef],
            ['clk',         'input',  'implicit_fanout', 'inferred_undeclared_top_input_port'],
            ['rstn',        'input',  'implicit_fanout', 'inferred_undeclared_top_input_port'],
            ['shared_cfg',  'input',  'implicit_fanout', 'inferred_undeclared_top_input_port'],
        ],
        'builder preserves undeclared same-name top-input inference, including shared system inputs',
    );
};

subtest 'undeclared top-output builder infers one unique top-facing child output' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_undeclared_top_outputs(
        ports => [],
        toplinks => [],
        realized_instances => [
            realized_instance('producer',
                output_port('status_out', 8),
            ),
            realized_instance('consumer',
                input_port('payload_in', 8),
            ),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is_deeply(
        [map { [$_->name, $_->direction, $_->raw_token, $_->binding_mode, $_->origin_kind] } @$ports],
        [
            ['status_out', 'output', 'producer.status_out', 'implicit_unique_output', 'inferred_undeclared_top_output_port'],
        ],
        'builder keeps the bounded unique top-facing child-output inference surface',
    );
};

subtest 'undeclared top-output builder rejects several top-facing same-name child outputs' => sub {
    my $exception = eval {
        FSM::Composition::TopPortInferenceBuilder->augment_undeclared_top_outputs(
            ports => [],
            toplinks => [],
            realized_instances => [
                realized_instance('left', output_port('status_out', 1)),
                realized_instance('right', output_port('status_out', 1)),
            ],
            fsm_file => 'fixture.fsm',
            header => 'fixture',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits top port 'status_out', .*undeclared top-output inference is blocked because several same-name child outputs remain unconsumed by explicit links/s,
        'builder keeps the bounded same-name top-output ambiguity diagnostic',
    );
};

done_testing();

sub realized_instance {
    my ($instance_name, @ports) = @_;

    return FSM::Composition::RealizedInstance->new(
        kind => 'fsmc',
        instance_name => $instance_name,
        module_name => $instance_name.'_mod',
        source_name => $instance_name.'_src',
        interface_ports => \@ports,
        port_bindings => [],
        module_info => {},
        hdl_code => undef,
    );
}

sub input_port {
    my ($name, $width, $type) = @_;
    return FSM::Composition::Port->new(
        name => $name,
        direction => 'input',
        width => $width,
        type => $type,
    );
}

sub output_port {
    my ($name, $width, $type) = @_;
    return FSM::Composition::Port->new(
        name => $name,
        direction => 'output',
        width => $width,
        type => $type,
    );
}
