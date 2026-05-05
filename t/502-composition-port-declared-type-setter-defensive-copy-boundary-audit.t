#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Port;

subtest 'Composition::Port declared_type_spec constructor, accessor, and setter return caller-owned copies' => sub {
    my $declared_type_spec = {
        kind => 'record',
        width => 9,
        member_order => [qw(tag payload)],
        members => {
            tag => {
                kind => 'bit',
                width => 1,
            },
            payload => {
                kind => 'bits',
                width => 8,
            },
        },
    };

    my $port = FSM::Composition::Port->new(
        name => 'frame',
        direction => 'output',
        declared_type_name => 'frame_t',
        declared_type_spec => $declared_type_spec,
    );

    $declared_type_spec->{members}{payload}{width} = 99;

    my $first_spec = $port->declared_type_spec;
    $first_spec->{member_order}[0] = 'mutated_after_accessor';
    $first_spec->{members}{tag}{width} = 99;

    is_deeply(
        $port->declared_type_spec,
        {
            kind => 'record',
            width => 9,
            member_order => [qw(tag payload)],
            members => {
                tag => {
                    kind => 'bit',
                    width => 1,
                },
                payload => {
                    kind => 'bits',
                    width => 8,
                },
            },
        },
        'declared_type_spec is isolated from constructor and accessor mutation',
    );

    my $replacement_spec = {
        kind => 'bits',
        width => 16,
        signed => 1,
    };

    my $returned_spec = $port->set_declared_type_spec($replacement_spec);
    $replacement_spec->{width} = 32;
    $returned_spec->{width} = 64;

    is_deeply(
        $port->declared_type_spec,
        {
            kind => 'bits',
            width => 16,
            signed => 1,
        },
        'set_declared_type_spec return value is isolated from stored declared type spec',
    );
};

done_testing();
