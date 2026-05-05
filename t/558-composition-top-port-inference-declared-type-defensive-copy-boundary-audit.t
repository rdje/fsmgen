#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::TopPortInferenceBuilder;

sub declared_type_spec {
    return {
        kind => 'record',
        member_order => ['flag', 'payload'],
        members => {
            flag => {
                kind => 'bit',
            },
            payload => {
                kind => 'bits',
                width => 8,
            },
        },
    };
}

subtest 'inferred top-port requirements own declared type specs' => sub {
    my %inferred_specs;
    my $type_spec = declared_type_spec();

    my $progress = FSM::Composition::TopPortInferenceBuilder->_record_inferred_top_port_requirement(
        \%inferred_specs,
        'frame_in',
        'input',
        9,
        9,
        'data',
        'frame_t',
        $type_spec,
        'producer.frame_out -> frame_in',
        'top.fsm',
        '?top:top',
    );

    ok($progress, 'initial inferred requirement records progress');

    $type_spec->{members}{payload}{width} = 99;
    push @{$type_spec->{member_order}}, 'late';

    is_deeply(
        $inferred_specs{frame_in}{declared_type_spec},
        declared_type_spec(),
        'mutating incoming declared type spec cannot contaminate inferred requirement state',
    );
};

done_testing();
