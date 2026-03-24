#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::IntentHIR;

subtest 'IntentHIR composition child helpers provide cloned semantic lookup by instance name' => sub {
    my $intent_hir = FSM::IR::IntentHIR->new(
        module_name => 'composition_child_helpers_top',
        source_root_kind => 'top',
        composition_children => [
            {
                kind => 'fsmc',
                instance_name => 'left',
                module_name => 'left_mod',
                source_name => 'left_src',
                source_root_kind => 'fsm',
                intent_hir => { module_name => 'left_src' },
            },
            {
                kind => 'rtl',
                instance_name => 'uart_tx',
                module_name => 'uart_tx',
                source_name => 'uart_tx',
                source_root_kind => 'rtl',
                structural_rtl_ir => {},
            },
        ],
    );

    my $children_by_instance = $intent_hir->composition_children_by_instance;
    is_deeply(
        [sort keys %$children_by_instance],
        ['left', 'uart_tx'],
        'composition_children_by_instance indexes semantic child exports by realized instance name',
    );
    is(
        $children_by_instance->{left}{module_name},
        'left_mod',
        'composition_children_by_instance preserves the original child payload',
    );

    my $left_child = $intent_hir->composition_child('left');
    is(
        $left_child->{source_name},
        'left_src',
        'composition_child returns the semantic child export for one realized instance',
    );

    $children_by_instance->{left}{module_name} = 'mutated_after_lookup';
    $left_child->{source_name} = 'mutated_after_lookup';

    my $fresh_children_by_instance = $intent_hir->composition_children_by_instance;
    my $fresh_left_child = $intent_hir->composition_child('left');

    is(
        $fresh_children_by_instance->{left}{module_name},
        'left_mod',
        'composition_children_by_instance clones the indexed export payload instead of aliasing caller-owned state',
    );
    is(
        $fresh_left_child->{source_name},
        'left_src',
        'composition_child clones the returned child payload instead of aliasing caller-owned state',
    );

    ok(
        !defined($intent_hir->composition_child('missing_child')),
        'composition_child returns undef for unknown realized child instances',
    );
};

subtest 'IntentHIR class-level composition child helpers also accept partial semantic hashes' => sub {
    my $intent_hir_hash = {
        composition_children => [
            {
                kind => 'fsmc',
                instance_name => 'left',
                module_name => 'left_mod',
                lowered_rtl_ir => {
                    output_drive_families => [
                        { signal_name => 'status' },
                    ],
                },
            },
        ],
    };

    my $children = FSM::IR::IntentHIR->composition_children_from_input($intent_hir_hash);
    is_deeply(
        $children,
        [
            {
                kind => 'fsmc',
                instance_name => 'left',
                module_name => 'left_mod',
                lowered_rtl_ir => {
                    output_drive_families => [
                        { signal_name => 'status' },
                    ],
                },
            },
        ],
        'composition_children_from_input accepts partial semantic hashes without requiring module_name',
    );

    my $children_by_instance = FSM::IR::IntentHIR->composition_children_by_instance_from_input($intent_hir_hash);
    is_deeply(
        [sort keys %$children_by_instance],
        ['left'],
        'composition_children_by_instance_from_input indexes partial semantic hashes too',
    );
    is(
        FSM::IR::IntentHIR->composition_child_from_input($intent_hir_hash, 'left')->{module_name},
        'left_mod',
        'composition_child_from_input returns one child from a partial semantic hash too',
    );

    ok(
        !defined(FSM::IR::IntentHIR->composition_child_from_input($intent_hir_hash, 'missing')),
        'composition_child_from_input returns undef for unknown instances in partial semantic hashes too',
    );
};

done_testing();
