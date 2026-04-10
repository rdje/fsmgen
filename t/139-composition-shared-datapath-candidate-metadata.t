#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'composition module_info surfaces shared-datapath candidates across multi-fsm child outputs' => sub {
    my $composition_path = write_fsm('shared_datapath_candidate_top.fsm', <<'FSM');
(?top:shared_datapath_candidate_top
  (?ports:public_io
    clk
    rstn
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?toplink:wiring
    /left.status_bus/left_status/
    /right.status_bus/right_status/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (status_bus> <= 8'1)
  )
  (+size
    (status_bus 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (status_bus> <= 8'2)
  )
  (+size
    (status_bus 8)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $module_info = $result->{module_info};
    my $structural_rtl_ir = $result->{structural_rtl_ir};

    is($result->{composition_plan}->lane, 'C2', 'two fsm children with explicit top wiring stay in C2');
    is($module_info->{composition_shared_datapath_candidate_count}, 1, 'top module_info reports one shared-datapath candidate family');
    is($result->{statistics}{composition_shared_datapath_candidate_count}, 1, 'statistics report one shared-datapath candidate family');
    is_deeply(
        $module_info->{composition_shared_datapath_candidates}[0]{top_output_signals},
        [
            map { $_->{name} }
            grep { (($_->{direction} || '') eq 'output') }
            @{$structural_rtl_ir->{ports} || []}
        ],
        'shared-datapath candidate top-output bindings now stay aligned with structural_rtl_ir output ports',
    );
    is_deeply(
        clone_without_forward_ir($module_info->{composition_shared_datapath_candidates}),
        [
            {
                signal_name => 'status_bus',
                width => 8,
                interface_type => 'data',
                storage_class => 'registered',
                reset_value => "8'h00",
                contributor_count => 2,
                contributors => [
                    {
                        kind => 'fsmc',
                        instance_name => 'left',
                        module_name => 'left_src',
                        source_name => 'left_src',
                        endpoint => 'left.status_bus',
                        bound_signal => 'left_status',
                        bound_signals => ['left_status'],
                        bound_connection_expr => {
                            kind => 'signal_ref',
                            signal_name => 'left_status',
                        },
                        output_drive_family => {
                            signal_name => 'status_bus',
                            width => 8,
                            multiplexer_type => 'flop',
                            default_value => 'status_bus',
                            reset_value => "8'h00",
                            driver_count => 1,
                            driver_blocks => ['-state0'],
                            rhs_values => ["8'd1"],
                            driver_enable_signals => ['state0_status_bus__8_d1_en'],
                            family_enable_signals => ['status_bus__8_d1_en'],
                            rhs_enable_families => [
                                {
                                    rhs_value => "8'd1",
                                    family_enable_signal => 'status_bus__8_d1_en',
                                    driver_blocks => ['-state0'],
                                    driver_enable_signals => ['state0_status_bus__8_d1_en'],
                                },
                            ],
                        },
                        drive_intent => {
                            multiplexer_type => 'flop',
                            default_value => 'status_bus',
                            reset_value => "8'h00",
                            driver_count => 1,
                            driver_blocks => ['-state0'],
                            rhs_values => ["8'd1"],
                            driver_enable_signals => ['state0_status_bus__8_d1_en'],
                            family_enable_signals => ['status_bus__8_d1_en'],
                            rhs_enable_families => [
                                {
                                    rhs_value => "8'd1",
                                    family_enable_signal => 'status_bus__8_d1_en',
                                    driver_blocks => ['-state0'],
                                    driver_enable_signals => ['state0_status_bus__8_d1_en'],
                                },
                            ],
                        },
                    },
                    {
                        kind => 'fsmc',
                        instance_name => 'right',
                        module_name => 'right_src',
                        source_name => 'right_src',
                        endpoint => 'right.status_bus',
                        bound_signal => 'right_status',
                        bound_signals => ['right_status'],
                        bound_connection_expr => {
                            kind => 'signal_ref',
                            signal_name => 'right_status',
                        },
                        output_drive_family => {
                            signal_name => 'status_bus',
                            width => 8,
                            multiplexer_type => 'flop',
                            default_value => 'status_bus',
                            reset_value => "8'h00",
                            driver_count => 1,
                            driver_blocks => ['-state0'],
                            rhs_values => ["8'd2"],
                            driver_enable_signals => ['state0_status_bus__8_d2_en'],
                            family_enable_signals => ['status_bus__8_d2_en'],
                            rhs_enable_families => [
                                {
                                    rhs_value => "8'd2",
                                    family_enable_signal => 'status_bus__8_d2_en',
                                    driver_blocks => ['-state0'],
                                    driver_enable_signals => ['state0_status_bus__8_d2_en'],
                                },
                            ],
                        },
                        drive_intent => {
                            multiplexer_type => 'flop',
                            default_value => 'status_bus',
                            reset_value => "8'h00",
                            driver_count => 1,
                            driver_blocks => ['-state0'],
                            rhs_values => ["8'd2"],
                            driver_enable_signals => ['state0_status_bus__8_d2_en'],
                            family_enable_signals => ['status_bus__8_d2_en'],
                            rhs_enable_families => [
                                {
                                    rhs_value => "8'd2",
                                    family_enable_signal => 'status_bus__8_d2_en',
                                    driver_blocks => ['-state0'],
                                    driver_enable_signals => ['state0_status_bus__8_d2_en'],
                                },
                            ],
                        },
                    },
                ],
                top_output_signals => ['left_status', 'right_status'],
                peer_input_count => 0,
                peer_input_endpoints => [],
                default_lifted_visibility => 'top_output',
                planned_reexport_top_output_signals => [],
                loopback_allowed => 0,
                lifted_runtime_kind => 'registered_shared_public_fanout',
                lifted_runtime_signal => 'status_bus_shared_q',
                lifted_runtime_next_signal => 'status_bus_shared_next',
                lifted_runtime_reset_value => "8'h00",
                lifted_runtime_reset_active_level => 1,
                lifted_runtime_reset_kind => 'sync',
                lifted_runtime_reset_keyword => 'sreset',
                aggregate_target_enable_signal => 'status_bus_shared_en',
                multi_value_conflict_signal => 'status_bus_multi_value_conflict',
                multi_value_assertion => {
                    kind => 'onehot0',
                    result_signal => 'status_bus_multi_value_conflict',
                    input_count => 2,
                    input_enable_signals => [
                        'status_bus__8_d1_shared_en',
                        'status_bus__8_d2_shared_en',
                    ],
                },
                aggregate_enable_family_count => 2,
                aggregate_enable_families => [
                    {
                        rhs_value => "8'd1",
                        aggregate_enable_signal => 'status_bus__8_d1_shared_en',
                        same_value_conflict_signal => 'status_bus__8_d1_multi_src_conflict',
                        same_value_assertion => {
                            kind => 'onehot0',
                            result_signal => 'status_bus__8_d1_multi_src_conflict',
                            input_count => 1,
                            input_enable_signals => ['left_status_bus__8_d1_src_en'],
                        },
                        contributor_count => 1,
                        contributors => [
                            {
                                endpoint => 'left.status_bus',
                                family_enable_signal => 'status_bus__8_d1_en',
                                source_enable_signal => 'left_status_bus__8_d1_src_en',
                                driver_blocks => ['-state0'],
                                driver_enable_signals => ['state0_status_bus__8_d1_en'],
                            },
                        ],
                    },
                    {
                        rhs_value => "8'd2",
                        aggregate_enable_signal => 'status_bus__8_d2_shared_en',
                        same_value_conflict_signal => 'status_bus__8_d2_multi_src_conflict',
                        same_value_assertion => {
                            kind => 'onehot0',
                            result_signal => 'status_bus__8_d2_multi_src_conflict',
                            input_count => 1,
                            input_enable_signals => ['right_status_bus__8_d2_src_en'],
                        },
                        contributor_count => 1,
                        contributors => [
                            {
                                endpoint => 'right.status_bus',
                                family_enable_signal => 'status_bus__8_d2_en',
                                source_enable_signal => 'right_status_bus__8_d2_src_en',
                                driver_blocks => ['-state0'],
                                driver_enable_signals => ['state0_status_bus__8_d2_en'],
                            },
                        ],
                    },
                ],
            },
        ],
        'top module_info groups same-name fsm child outputs into one shared-datapath candidate family',
    );
};

subtest 'CLI prints shared-datapath candidate summary for composition tops' => sub {
    my $composition_path = write_fsm('shared_datapath_candidate_cli_top.fsm', <<'FSM');
(?top:shared_datapath_candidate_cli_top
  (?ports:public_io
    clk
    rstn
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?toplink:wiring
    /left.status_bus/left_status/
    /right.status_bus/right_status/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (status_bus> <= 8'1)
  )
  (+size
    (status_bus 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (status_bus> <= 8'2)
  )
  (+size
    (status_bus 8)
  )
)
FSM
    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_candidate_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for shared-datapath candidate summary fixture');
    ok(-e $output_path, 'CLI writes HDL for shared-datapath candidate summary fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Shared-Datapath Candidates:/s, 'CLI prints shared-datapath candidate summary header');
    like($combined_output, qr/Count:\s+1/s, 'CLI reports one shared-datapath candidate family');
    like(
        $combined_output,
        qr/status_bus \[width=8, type=data\] from left\.status_bus <= left_status, right\.status_bus <= right_status \(top outputs: left_status, right_status\)/s,
        'CLI prints the grouped same-name output family together with contributor bindings',
    );
    like($combined_output, qr/\* storage class: registered/s, 'CLI prints the shared-datapath storage class');
    like($combined_output, qr/\* default lifted visibility: top_output/s, 'CLI prints the default lifted visibility for top-facing shared outputs');
    like($combined_output, qr/\* lifted runtime: registered shared public fanout active/s, 'CLI prints the registered public-fanout runtime label');
    like($combined_output, qr/\* lifted signal: status_bus_shared_q/s, 'CLI prints the lifted shared register name for public fanout');
    like($combined_output, qr/\* loopback allowed: no/s, 'CLI prints that loopback is not currently planned when no peer-read inputs exist');
    like($combined_output, qr/\* aggregate target enable: status_bus_shared_en/s, 'CLI prints the shared target aggregate enable name');
    like($combined_output, qr/\* multi-value conflict: status_bus_multi_value_conflict/s, 'CLI prints the whole-target multi-value conflict name');
    like($combined_output, qr/\* multi-value onehot0 over status_bus__8_d1_shared_en, status_bus__8_d2_shared_en => status_bus_multi_value_conflict/s, 'CLI prints the planned multi-value onehot0 check inputs');
    like($combined_output, qr/\* aggregate value 8'd1 => status_bus__8_d1_shared_en from left\.status_bus\/status_bus__8_d1_en/s, 'CLI prints the first aggregate value-enable family');
    like($combined_output, qr/\* same-value conflict 8'd1 => status_bus__8_d1_multi_src_conflict/s, 'CLI prints the first same-value conflict name');
    like($combined_output, qr/\* aggregate value 8'd2 => status_bus__8_d2_shared_en from right\.status_bus\/status_bus__8_d2_en/s, 'CLI prints the second aggregate value-enable family');
    like($combined_output, qr/\* same-value conflict 8'd2 => status_bus__8_d2_multi_src_conflict/s, 'CLI prints the second same-value conflict name');
};

done_testing();

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}

sub clone_without_forward_ir {
    my ($value) = @_;
    return undef unless defined $value;

    if (ref($value) eq 'ARRAY') {
        return [ map { clone_without_forward_ir($_) } @$value ];
    }

    if (ref($value) eq 'HASH') {
        return {
            map {
                my $key = $_;
                ($key => clone_without_forward_ir($value->{$key}))
            } grep {
                $_ ne 'intent_hir' && $_ ne 'lowered_rtl_ir' && $_ ne 'structural_rtl_ir'
            } sort keys %$value
        };
    }

    return $value;
}
