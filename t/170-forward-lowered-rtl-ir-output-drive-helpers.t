#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::LoweredRTLIR;

subtest 'LoweredRTLIR output-drive helpers provide cloned lookup by signal name' => sub {
    my $lowered_rtl_ir = FSM::IR::LoweredRTLIR->new(
        module_name => 'lowered_drive_helper_top',
        source_root_kind => 'fsm',
        output_drive_families => [
            {
                signal_name => 'status',
                multiplexer_type => 'flop',
                reset_value => '0',
                rhs_enable_families => [],
            },
            {
                signal_name => 'data_bus',
                multiplexer_type => 'combinational',
                default_value => "8'h00",
                rhs_enable_families => [],
            },
        ],
    );

    my $families_by_signal = $lowered_rtl_ir->output_drive_families_by_signal;
    is_deeply(
        [sort keys %$families_by_signal],
        ['data_bus', 'status'],
        'output_drive_families_by_signal indexes lowered output-drive families by signal name',
    );
    is(
        $families_by_signal->{status}{multiplexer_type},
        'flop',
        'output_drive_families_by_signal preserves the family payload',
    );

    my $status_family = $lowered_rtl_ir->output_drive_family('status');
    is(
        $status_family->{reset_value},
        '0',
        'output_drive_family returns one lowered output-drive family by signal name',
    );

    $families_by_signal->{status}{multiplexer_type} = 'mutated_after_lookup';
    $status_family->{reset_value} = 'mutated_after_lookup';

    my $fresh_families_by_signal = $lowered_rtl_ir->output_drive_families_by_signal;
    my $fresh_status_family = $lowered_rtl_ir->output_drive_family('status');

    is(
        $fresh_families_by_signal->{status}{multiplexer_type},
        'flop',
        'output_drive_families_by_signal clones the indexed payload instead of aliasing caller-owned state',
    );
    is(
        $fresh_status_family->{reset_value},
        '0',
        'output_drive_family clones the returned family instead of aliasing caller-owned state',
    );

    ok(
        !defined($lowered_rtl_ir->output_drive_family('missing_signal')),
        'output_drive_family returns undef for unknown lowered signal names',
    );
};

subtest 'LoweredRTLIR class-level output-drive helpers also accept partial lowered hashes' => sub {
    my $lowered_rtl_ir_hash = {
        output_drive_families => [
            {
                signal_name => 'status',
                multiplexer_type => 'flop',
                rhs_enable_families => [],
            },
        ],
    };

    my $families = FSM::IR::LoweredRTLIR->output_drive_families_from_input($lowered_rtl_ir_hash);
    is_deeply(
        $families,
        [
            {
                signal_name => 'status',
                multiplexer_type => 'flop',
                rhs_enable_families => [],
            },
        ],
        'output_drive_families_from_input accepts partial lowered hashes without requiring module_name',
    );

    my $families_by_signal = FSM::IR::LoweredRTLIR->output_drive_families_by_signal_from_input($lowered_rtl_ir_hash);
    is_deeply(
        [sort keys %$families_by_signal],
        ['status'],
        'output_drive_families_by_signal_from_input indexes partial lowered hashes too',
    );
    is(
        FSM::IR::LoweredRTLIR->output_drive_family_from_input($lowered_rtl_ir_hash, 'status')->{multiplexer_type},
        'flop',
        'output_drive_family_from_input returns one family from a partial lowered hash too',
    );

    ok(
        !defined(FSM::IR::LoweredRTLIR->output_drive_family_from_input($lowered_rtl_ir_hash, 'missing')),
        'output_drive_family_from_input returns undef for unknown signals in partial lowered hashes too',
    );
};

done_testing();
