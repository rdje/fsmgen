#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::LoweredRTLIR;

subtest 'LoweredRTLIR standalone-DT target helpers provide cloned lookup by signal name' => sub {
    my $lowered_rtl_ir = FSM::IR::LoweredRTLIR->new(
        module_name => 'lowered_dt_target_helper_top',
        source_root_kind => 'dt',
        standalone_dt_multi_drive_targets => [
            {
                signal_name => 'OUT',
                multiplexer_type => 'comb',
                dt_names => ['-from_a', '-from_b'],
                rhs_values => ['A', 'B'],
                dt_enable_signals => ['from_a_out_a_en', 'from_b_out_b_en'],
                lhs_enable_signals => ['out_a_en', 'out_b_en'],
                multi_drive_assertion => {
                    kind => 'onehot0',
                    target_signal => 'OUT',
                    input_count => 2,
                    input_enable_signals => ['from_a_out_a_en', 'from_b_out_b_en'],
                },
            },
        ],
    );

    my $targets_by_signal = $lowered_rtl_ir->standalone_dt_multi_drive_targets_by_signal;
    is_deeply(
        [sort keys %$targets_by_signal],
        ['OUT'],
        'standalone_dt_multi_drive_targets_by_signal indexes lowered standalone-DT targets by signal name',
    );
    is(
        $targets_by_signal->{OUT}{multiplexer_type},
        'comb',
        'standalone_dt_multi_drive_targets_by_signal preserves the target payload',
    );

    my $out_target = $lowered_rtl_ir->standalone_dt_multi_drive_target('OUT');
    is_deeply(
        $out_target->{dt_names},
        ['-from_a', '-from_b'],
        'standalone_dt_multi_drive_target returns one lowered target by signal name',
    );

    $targets_by_signal->{OUT}{multiplexer_type} = 'mutated_after_lookup';
    $out_target->{dt_names}[0] = 'mutated_after_lookup';

    my $fresh_targets_by_signal = $lowered_rtl_ir->standalone_dt_multi_drive_targets_by_signal;
    my $fresh_out_target = $lowered_rtl_ir->standalone_dt_multi_drive_target('OUT');

    is(
        $fresh_targets_by_signal->{OUT}{multiplexer_type},
        'comb',
        'standalone_dt_multi_drive_targets_by_signal clones the indexed payload instead of aliasing caller-owned state',
    );
    is_deeply(
        $fresh_out_target->{dt_names},
        ['-from_a', '-from_b'],
        'standalone_dt_multi_drive_target clones the returned target instead of aliasing caller-owned state',
    );

    ok(
        !defined($lowered_rtl_ir->standalone_dt_multi_drive_target('missing_signal')),
        'standalone_dt_multi_drive_target returns undef for unknown lowered target signals',
    );
};

subtest 'LoweredRTLIR class-level standalone-DT target helpers also accept partial lowered hashes' => sub {
    my $lowered_rtl_ir_hash = {
        standalone_dt_multi_drive_targets => [
            {
                signal_name => 'OUT',
                multiplexer_type => 'comb',
                dt_names => ['-from_a', '-from_b'],
            },
        ],
    };

    my $targets = FSM::IR::LoweredRTLIR->standalone_dt_multi_drive_targets_from_input($lowered_rtl_ir_hash);
    is_deeply(
        $targets,
        [
            {
                signal_name => 'OUT',
                multiplexer_type => 'comb',
                dt_names => ['-from_a', '-from_b'],
            },
        ],
        'standalone_dt_multi_drive_targets_from_input accepts partial lowered hashes without requiring module_name',
    );

    my $targets_by_signal = FSM::IR::LoweredRTLIR->standalone_dt_multi_drive_targets_by_signal_from_input($lowered_rtl_ir_hash);
    is_deeply(
        [sort keys %$targets_by_signal],
        ['OUT'],
        'standalone_dt_multi_drive_targets_by_signal_from_input indexes partial lowered hashes too',
    );
    is(
        FSM::IR::LoweredRTLIR->standalone_dt_multi_drive_target_from_input($lowered_rtl_ir_hash, 'OUT')->{multiplexer_type},
        'comb',
        'standalone_dt_multi_drive_target_from_input returns one target from a partial lowered hash too',
    );

    ok(
        !defined(FSM::IR::LoweredRTLIR->standalone_dt_multi_drive_target_from_input($lowered_rtl_ir_hash, 'missing')),
        'standalone_dt_multi_drive_target_from_input returns undef for unknown target signals in partial lowered hashes too',
    );
};

done_testing();
