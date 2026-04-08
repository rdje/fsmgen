#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Port;
use FSM::Composition::RealizedInstance;
use FSM::Composition::SameNameLinkBuilder;

subtest 'same-name top-input builder fans one top input out to matching child inputs' => sub {
    my $links = FSM::Composition::SameNameLinkBuilder->build_top_input_links(
        ports => [
            FSM::Composition::Port->new(
                name => 'payload',
                direction => 'input',
                width => 8,
            ),
        ],
        explicit_links => [],
        realized_instances => [
            realized_instance('left', input_port('payload', 8)),
            realized_instance('right', input_port('payload', 8)),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is(scalar(@$links), 2, 'builder emits one inferred link per matching child input');
    is_deeply(
        [map { [$_->source, $_->target, $_->origin_kind] } @$links],
        [
            ['payload', 'left.payload',  'inferred_plain_explicit_top_input_link'],
            ['payload', 'right.payload', 'inferred_plain_explicit_top_input_link'],
        ],
        'builder preserves the bounded same-name top-input fanout shape',
    );
};

subtest 'same-name top-input builder rejects mixed-direction same-name candidates' => sub {
    my $exception = eval {
        FSM::Composition::SameNameLinkBuilder->build_top_input_links(
            ports => [
                FSM::Composition::Port->new(
                    name => 'foo',
                    direction => 'input',
                    width => 8,
                ),
            ],
            explicit_links => [],
            realized_instances => [
                realized_instance('producer', output_port('foo', 8)),
                realized_instance('consumer', input_port('foo', 8)),
            ],
            fsm_file => 'fixture.fsm',
            header => 'fixture',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/same-name top-input convention is blocked because same-name child endpoints include incompatible directions/s,
        'builder keeps the mixed-direction top-input convention diagnostic',
    );
};

subtest 'same-name top-output builder keeps one unique top-facing child output' => sub {
    my $links = FSM::Composition::SameNameLinkBuilder->build_top_output_links(
        ports => [
            FSM::Composition::Port->new(
                name => 'status',
                direction => 'output',
                width => 8,
            ),
        ],
        explicit_links => [],
        realized_instances => [
            realized_instance('producer', output_port('status', 8)),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is(scalar(@$links), 1, 'builder emits one inferred top-output link');
    is($links->[0]->source, 'producer.status', 'builder uses the matching child output as the source');
    is($links->[0]->target, 'status', 'builder uses the declared top output as the target');
    is($links->[0]->origin_kind, 'inferred_plain_explicit_top_output_link', 'builder preserves the bounded top-output origin kind');
};

subtest 'same-name top-input builder rejects incompatible declared type contracts' => sub {
    my $exception = eval {
        FSM::Composition::SameNameLinkBuilder->build_top_input_links(
            ports => [
                FSM::Composition::Port->new(
                    name => 'payload',
                    direction => 'input',
                    width => 8,
                    declared_type_name => 'header_t',
                    declared_type_spec => record_spec(
                        tag => bit_spec(),
                        payload => bits_spec(7),
                    ),
                ),
            ],
            explicit_links => [],
            realized_instances => [
                realized_instance('left', input_port('payload', 8, undef,
                    declared_type_name => 'byte_t',
                    declared_type_spec => bits_spec(8),
                )),
                realized_instance('right', input_port('payload', 8, undef,
                    declared_type_name => 'byte_t',
                    declared_type_spec => bits_spec(8),
                )),
            ],
            fsm_file => 'fixture.fsm',
            header => 'fixture',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/same-name top-input convention is blocked because same-name child inputs do not all match that declared type contract/s,
        'builder rejects explicit same-name top-input fanout across incompatible declared type contracts',
    );
};

subtest 'same-name top-output builder rejects incompatible declared type contracts' => sub {
    my $exception = eval {
        FSM::Composition::SameNameLinkBuilder->build_top_output_links(
            ports => [
                FSM::Composition::Port->new(
                    name => 'status',
                    direction => 'output',
                    width => 8,
                    declared_type_name => 'header_t',
                    declared_type_spec => record_spec(
                        tag => bit_spec(),
                        payload => bits_spec(7),
                    ),
                ),
            ],
            explicit_links => [],
            realized_instances => [
                realized_instance('producer', output_port('status', 8, undef,
                    declared_type_name => 'byte_t',
                    declared_type_spec => bits_spec(8),
                )),
            ],
            fsm_file => 'fixture.fsm',
            header => 'fixture',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/same-name top-output convention is blocked because the remaining top-facing child output 'producer\.status' preserves incompatible declared type/s,
        'builder rejects explicit same-name top-output re-export across incompatible declared type contracts',
    );
};

subtest 'same-name internal-carrier builder emits re-export plus sink links' => sub {
    my $links = FSM::Composition::SameNameLinkBuilder->build_internal_same_name_links(
        ports => [
            FSM::Composition::Port->new(
                name => 'payload',
                direction => 'output',
                width => 8,
            ),
        ],
        explicit_links => [],
        realized_instances => [
            realized_instance('producer', output_port('payload', 8)),
            realized_instance('left', input_port('payload', 8)),
            realized_instance('right', input_port('payload', 8)),
        ],
        fsm_file => 'fixture.fsm',
        header => 'fixture',
    );

    is(scalar(@$links), 3, 'builder emits one re-export link plus one link per child sink');
    is_deeply(
        [map { [$_->source, $_->target, $_->origin_kind] } @$links],
        [
            ['producer.payload', 'payload',       'inferred_internal_carrier_reexport_link'],
            ['producer.payload', 'left.payload',  'inferred_internal_carrier_link'],
            ['producer.payload', 'right.payload', 'inferred_internal_carrier_link'],
        ],
        'builder preserves the bounded internal-carrier link family',
    );
};

subtest 'same-name internal-carrier builder rejects top-input re-export attempts' => sub {
    my $exception = eval {
        FSM::Composition::SameNameLinkBuilder->build_internal_same_name_links(
            ports => [
                FSM::Composition::Port->new(
                    name => 'payload',
                    direction => 'input',
                    width => 8,
                ),
            ],
            explicit_links => [],
            realized_instances => [
                realized_instance('producer', output_port('payload', 8)),
                realized_instance('consumer', input_port('payload', 8)),
            ],
            fsm_file => 'fixture.fsm',
            header => 'fixture',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/only allows that same-name internal carrier family to be re-exported through an explicit top output, not through a top input of the same name/s,
        'builder keeps the bounded top-input re-export block for internal carriers',
    );
};

subtest 'same-name internal-carrier builder rejects conflicting declared type contracts' => sub {
    my $exception = eval {
        FSM::Composition::SameNameLinkBuilder->build_internal_same_name_links(
            ports => [],
            explicit_links => [],
            realized_instances => [
                realized_instance('producer', output_port('payload', 8, undef,
                    declared_type_name => 'byte_t',
                    declared_type_spec => bits_spec(8),
                )),
                realized_instance('consumer', input_port('payload', 8, undef,
                    declared_type_name => 'header_t',
                    declared_type_spec => record_spec(
                        tag => bit_spec(),
                        payload => bits_spec(7),
                    ),
                )),
            ],
            fsm_file => 'fixture.fsm',
            header => 'fixture',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/undeclared internal-carrier inference is blocked because same-name child ports disagree on declared type contract/s,
        'builder rejects inferred internal carriers across incompatible declared type contracts',
    );
};

done_testing();

sub realized_instance {
    my ($instance_name, @ports) = @_;

    return FSM::Composition::RealizedInstance->new(
        kind => '?fsmc',
        instance_name => $instance_name,
        module_name => $instance_name.'_mod',
        source_name => $instance_name.'_src',
        interface_ports => \@ports,
        port_bindings => [],
        module_info => {},
        hdl_code => '',
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
