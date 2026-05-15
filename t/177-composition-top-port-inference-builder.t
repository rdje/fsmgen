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
use FSM::Composition::WiringBlock;
use FSM::Composition::TopPortInferenceBuilder;

subtest 'explicit-wiring builder infers renamed top ports from child endpoints' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
        ports => [],
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
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
            ['start',  'input',  1, 'inferred_explicit_wiring_port'],
            ['status', 'output', 1, 'inferred_explicit_wiring_port'],
        ],
        'builder keeps the bounded renamed explicit-wiring inference surface',
    );
};

subtest 'explicit-wiring builder infers undeclared top inputs from source-side top expressions' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
        ports => [],
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
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
            ['payload_bus', 'input', 16, 'inferred_explicit_wiring_port'],
            ['status_bus',  'input',  1, 'inferred_explicit_wiring_port'],
        ],
        'builder infers undeclared top-input width from bounded top-expression evidence',
    );
};

subtest 'explicit-wiring builder infers undeclared top inputs from concat top-expression operands' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
        ports => [],
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
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
            ['payload_hi', 'input', 4, 'inferred_explicit_wiring_port'],
            ['payload_lo', 'input', 4, 'inferred_explicit_wiring_port'],
            ['status_bus', 'input', 1, 'inferred_explicit_wiring_port'],
        ],
        'builder infers undeclared top-input widths from bounded concat top-expression operands',
    );
};

subtest 'explicit-wiring builder infers undeclared top inputs from concat operands even when child-output operands participate too' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
        ports => [],
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => '{producer.tag,status_bus[0],payload_lo[3:0]}',
                        target => 'sink.frame_in',
                    ),
                ],
            ),
        ],
        realized_instances => [
            realized_instance('producer',
                output_port('tag', 2),
            ),
            realized_instance('sink',
                input_port('frame_in', 7),
            ),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is_deeply(
        [map { [$_->name, $_->direction, $_->width, $_->origin_kind] } @$ports],
        [
            ['payload_lo', 'input', 4, 'inferred_explicit_wiring_port'],
            ['status_bus', 'input', 1, 'inferred_explicit_wiring_port'],
        ],
        'builder still infers only undeclared top-input operands when concat also includes child-output operands',
    );
};

subtest 'explicit-wiring builder infers one undeclared repeated whole-port operand from child target width' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
        ports => [],
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => '{2{payload_bus}}',
                        target => 'sink.frame_in',
                    ),
                ],
            ),
        ],
        realized_instances => [
            realized_instance('sink',
                input_port('frame_in', 8),
            ),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is_deeply(
        [map { [$_->name, $_->direction, $_->width, $_->origin_kind] } @$ports],
        [
            ['payload_bus', 'input', 4, 'inferred_explicit_wiring_port'],
        ],
        'builder can infer one undeclared repeated whole-port operand when the remaining child-target width divides evenly across the repeat count',
    );
};

subtest 'explicit-wiring builder infers one undeclared whole-port concat operand from child target width' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
        ports => [],
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => 'header_bus,status_bus[0],payload_bus[3:0]',
                        target => 'sink.frame_in',
                    ),
                ],
            ),
        ],
        realized_instances => [
            realized_instance('sink',
                input_port('frame_in', 8),
            ),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is_deeply(
        [map { [$_->name, $_->direction, $_->width, $_->origin_kind] } @$ports],
        [
            ['header_bus', 'input', 3, 'inferred_explicit_wiring_port'],
            ['payload_bus', 'input', 4, 'inferred_explicit_wiring_port'],
            ['status_bus',  'input', 1, 'inferred_explicit_wiring_port'],
        ],
        'builder can size one undeclared whole-port concat operand from the child-input target width',
    );
};

subtest 'explicit-wiring builder rejects several undeclared whole-port concat operands without exact widths' => sub {
    my $exception = eval {
        FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(
                            source => 'left_bus,right_bus,status_bus[0]',
                            target => 'sink.frame_in',
                        ),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance('sink',
                    input_port('frame_in', 8),
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
        qr/omits top ports 'left_bus', 'right_bus', .*top expression 'left_bus,right_bus,status_bus\[0\]' leaves several undeclared whole-port concat operands without exact widths.*left_bus,right_bus,status_bus\[0\] -> sink\.frame_in/s,
        'builder blocks omitted-port concat inference when several whole-port operands still lack exact widths',
    );
};

subtest 'explicit-wiring builder rejects incompatible exact-width and top-expression width evidence' => sub {
    my $exception = eval {
        FSM::Composition::TopPortInferenceBuilder->augment_from_explicit_links(
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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
        qr/omits top port 'payload_bus', .*top-expression evidence requires declared width at least 16, while another explicit wiring use fixes that same top port at width 8.*payload_bus -> sink\.full_in.*payload_bus\[15:8\] -> sink\.byte_in/s,
        'builder rejects exact-width evidence that is narrower than required top-expression width',
    );
};

subtest 'undeclared top-input builder infers shared same-name input fanout' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_undeclared_top_inputs(
        ports => [
            FSM::Composition::Port->new(name => 'result_data', direction => 'output', width => 8, binding_mode => 'explicit'),
        ],
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
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
        wiring_blocks => [],
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
            wiring_blocks => [],
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

subtest 'undeclared top-input builder preserves one uniform declared type contract' => sub {
    my $ports = FSM::Composition::TopPortInferenceBuilder->augment_undeclared_top_inputs(
        ports => [],
        wiring_blocks => [],
        realized_instances => [
            realized_instance('left',
                input_port('payload', 8, undef,
                    declared_type_name => 'byte_t',
                    declared_type_spec => bits_spec(8),
                ),
            ),
            realized_instance('right',
                input_port('payload', 8, undef,
                    declared_type_name => 'byte_t',
                    declared_type_spec => bits_spec(8),
                ),
            ),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is(scalar(@$ports), 1, 'builder infers one undeclared top input');
    is($ports->[0]->declared_type_name, 'byte_t', 'builder preserves the shared declared type name on inferred top inputs');
    is($ports->[0]->declared_type_spec->{width}, 8, 'builder preserves the shared declared type spec on inferred top inputs');
};

subtest 'undeclared top-input builder rejects conflicting declared type contracts' => sub {
    my $exception = eval {
        FSM::Composition::TopPortInferenceBuilder->augment_undeclared_top_inputs(
            ports => [],
            wiring_blocks => [],
            realized_instances => [
                realized_instance('left',
                    input_port('payload', 8, undef,
                        declared_type_name => 'byte_t',
                        declared_type_spec => bits_spec(8),
                    ),
                ),
                realized_instance('right',
                    input_port('payload', 8, undef,
                        declared_type_name => 'header_t',
                        declared_type_spec => record_spec(
                            tag => bit_spec(),
                            payload => bits_spec(7),
                        ),
                    ),
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
        qr/undeclared top-input inference is blocked because same-name child inputs disagree on declared type contract/s,
        'builder rejects undeclared top-input inference across incompatible declared type contracts',
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
    my ($name, $width, $type, %extra) = @_;
    return FSM::Composition::Port->new(
        name => $name,
        direction => 'input',
        width => $width,
        type => $type,
        %extra,
    );
}

sub output_port {
    my ($name, $width, $type, %extra) = @_;
    return FSM::Composition::Port->new(
        name => $name,
        direction => 'output',
        width => $width,
        type => $type,
        %extra,
    );
}

sub bit_spec {
    return {
        kind => 'bit',
        width => 1,
        signed => 0,
    };
}

sub bits_spec {
    my ($width) = @_;
    return {
        kind => 'bits',
        width => $width,
        signed => 0,
    };
}

sub record_spec {
    my (%members) = @_;
    my $width = 0;
    $width += ($_->{width} // 0) for values %members;
    return {
        kind => 'record',
        member_order => [sort keys %members],
        members => \%members,
        signed => 0,
        width => $width,
    };
}
