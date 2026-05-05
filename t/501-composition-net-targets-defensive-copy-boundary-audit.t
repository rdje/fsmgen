#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Net;

subtest 'Composition::Net targets and declared type spec are caller-owned copies' => sub {
    my $targets = ['consumer.payload'];
    my $declared_type_spec = {
        kind => 'bits',
        width => 8,
        signed => 1,
    };

    my $net = FSM::Composition::Net->new(
        name => 'comp_link_producer_payload',
        width => 8,
        source => 'producer.payload',
        targets => $targets,
        declared_type_name => 'byte_t',
        declared_type_spec => $declared_type_spec,
    );

    push @$targets, 'mutated_after_constructor';
    $declared_type_spec->{width} = 99;

    my $first_targets = $net->targets;
    my $first_declared_type_spec = $net->declared_type_spec;

    push @$first_targets, 'mutated_after_accessor';
    $first_declared_type_spec->{width} = 32;

    is_deeply(
        $net->targets,
        ['consumer.payload'],
        'targets is isolated from constructor and accessor mutation',
    );
    is_deeply(
        $net->declared_type_spec,
        {
            kind => 'bits',
            width => 8,
            signed => 1,
        },
        'declared_type_spec remains isolated from constructor and accessor mutation',
    );
};

subtest 'add_target is the explicit mutation API and returns caller-owned lists' => sub {
    my $net = FSM::Composition::Net->new(
        name => 'comp_link_producer_payload',
        targets => ['consumer.payload'],
    );

    my $returned_targets = $net->add_target('status_out');
    push @$returned_targets, 'mutated_after_add_target';

    is_deeply(
        $net->targets,
        ['consumer.payload', 'status_out'],
        'add_target updates stored targets without exposing the stored list',
    );

    $net->add_target(undef);
    $net->add_target('');

    is_deeply(
        $net->targets,
        ['consumer.payload', 'status_out'],
        'add_target ignores undefined and empty targets',
    );
};

done_testing();
