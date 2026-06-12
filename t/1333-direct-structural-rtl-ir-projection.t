#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'direct roots expose a bounded structural_rtl_ir port projection' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_structural_projection_guard.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_structural_projection_guard
  (+system
    (clock clk)
    (asreset rst_n)
  )
  (+size
    (request 1)
    (payload 8)
    (ready 1)
    (data_out 8)
  )
  (idle
    (<request
      (ready> <= 1)
      (data_out> <= payload)
    )
  )
)
FSM
    );

    my $result = generate_result($fsm_path);
    my $module_info = $result->{module_info};
    my $structural = $result->{structural_rtl_ir};

    ok($structural, 'direct generation returns a top-level structural_rtl_ir projection');
    is_deeply(
        $module_info->{structural_rtl_ir},
        $structural,
        'direct module_info mirrors the same serialized structural_rtl_ir projection',
    );

    is($structural->{module_name}, 'direct_structural_projection_guard', 'structural_rtl_ir preserves module name');
    is($structural->{source_root_kind}, 'fsm', 'structural_rtl_ir preserves direct root kind');
    is($structural->{target_language}, 'systemverilog', 'structural_rtl_ir preserves target language');

    my $expected_ports = expected_ports_from_module_info($module_info);
    my $actual_ports = {
        map {
            $_->{name} => {
                direction => $_->{direction},
                width => $_->{width},
                signed => $_->{signed} // 0,
                type => $_->{type},
            }
        } @{$structural->{ports} || []}
    };

    is_deeply(
        $actual_ports,
        $expected_ports,
        'direct structural_rtl_ir ports match generated module_info signal analysis plus system contract',
    );
    is($structural->{port_count}, scalar(keys %$expected_ports), 'direct structural_rtl_ir port_count matches expected ports');
    my %ports_by_name = map { $_->{name} => $_ } @{$structural->{ports} || []};
    is_deeply(
        $ports_by_name{request}{targets},
        [
            assignment_target('idle_data_out_payload_en', 'dt_specific_enable'),
            assignment_target('idle_ready_1_en', 'dt_specific_enable'),
        ],
        'direct structural_rtl_ir records generated-enable consumers on input port request',
    );
    ok(!exists $ports_by_name{payload}{targets}, 'direct structural_rtl_ir does not claim unused input-port targets');
    ok(!exists $ports_by_name{ready}{targets}, 'direct structural_rtl_ir does not claim output-port target connectivity yet');

    my $header = extract_module_header($result->{hdl_code});
    for my $port_name (sort keys %$expected_ports) {
        like(
            $header,
            qr/\b\Q$port_name\E\b/,
            "generated HDL module header includes structural port $port_name",
        );
    }

    my %nets_by_name = map { $_->{name} => $_ } @{$structural->{nets} || []};
    is_deeply(
        [sort keys %nets_by_name],
        [qw(data_out_payload_en data_out_q idle_data_out_payload_en idle_en idle_ready_1_en ready_1_en ready_q)],
        'direct structural_rtl_ir projects direct mux-helper declaration nets plus state and assignment enable wires',
    );
    is_deeply(
        $nets_by_name{idle_en},
        {
            name => 'idle_en',
            width => 1,
            signed => 0,
            source => assignment_source('idle_en', 'top_state_enable'),
            targets => [
                assignment_target('idle_data_out_payload_en', 'dt_specific_enable'),
                assignment_target('idle_ready_1_en', 'dt_specific_enable'),
            ],
        },
        'direct structural_rtl_ir records the one-bit top-level state enable wire connectivity',
    );
    is_deeply(
        $nets_by_name{data_out_q},
        {
            name => 'data_out_q',
            width => 8,
            signed => 0,
            source => undef,
            targets => [],
        },
        'direct structural_rtl_ir records the data_out_q helper declaration net',
    );
    is_deeply(
        $nets_by_name{ready_q},
        {
            name => 'ready_q',
            width => 1,
            signed => 0,
            source => undef,
            targets => [],
        },
        'direct structural_rtl_ir records the ready_q helper declaration net',
    );
    like($result->{hdl_code}, qr/\bassign\s+idle_en\s+=\s+current_state\s+==\s+IDLE;/, 'generated HDL emits the top-level state enable wire assignment');
    like($result->{hdl_code}, qr/\breg\s+\[7:0\]\s+data_out_q;/, 'generated HDL declares the data_out_q helper net');
    like($result->{hdl_code}, qr/\breg\s+ready_q;/, 'generated HDL declares the ready_q helper net');
    is_deeply(
        $structural->{auxiliary_assignments},
        [
            '  assign idle_en = current_state == IDLE;',
            '  assign idle_data_out_payload_en = idle_en & request;  // data_out <- payload',
            '  assign idle_ready_1_en = idle_en & request;  // ready <- 1',
            '  assign data_out_payload_en = idle_data_out_payload_en;',
            '  assign ready_1_en = idle_ready_1_en;',
        ],
        'direct structural_rtl_ir projects generated enable assignment lines as scalar auxiliary assignments',
    );
    is($structural->{assignment_record_count}, 5, 'direct structural_rtl_ir counts generated enable assignment records');
    is_deeply(
        [map { $_->{rendered} } @{$structural->{assignment_records} || []}],
        $structural->{auxiliary_assignments},
        'direct assignment records render the scalar auxiliary-assignment compatibility mirror',
    );
    is_deeply(
        record_by_lhs($structural, 'idle_en'),
        {
            kind => 'continuous_assign',
            lhs => {
                kind => 'signal_ref',
                name => 'idle_en',
            },
            rhs => {
                kind => 'expression',
                language => 'systemverilog',
                text => 'current_state == IDLE',
                ast => {
                    kind => 'binary_op',
                    class => 'FSM::AST::BinaryOp',
                    operator => '==',
                    left => {
                        kind => 'signal_ref',
                        class => 'FSM::AST::SignalRef',
                        name => 'current_state',
                    },
                    right => {
                        kind => 'literal',
                        class => 'FSM::AST::Literal',
                        value => 'IDLE',
                    },
                },
            },
            rendered => '  assign idle_en = current_state == IDLE;',
            provenance => {
                family => 'generated_enable',
                role => 'top_state_enable',
                state_name => 'idle',
            },
        },
        'direct assignment records expose the state enable as structured AST/provenance data',
    );
    is_deeply(
        record_by_lhs($structural, 'idle_data_out_payload_en'),
        {
            kind => 'continuous_assign',
            lhs => {
                kind => 'signal_ref',
                name => 'idle_data_out_payload_en',
            },
            rhs => {
                kind => 'expression',
                language => 'systemverilog',
                text => 'idle_en & request',
                ast => {
                    kind => 'binary_op',
                    class => 'FSM::AST::BinaryOp',
                    operator => '&&',
                    left => {
                        kind => 'signal_ref',
                        class => 'FSM::AST::SignalRef',
                        name => 'idle_en',
                    },
                    right => {
                        kind => 'binary_op',
                        class => 'FSM::AST::BinaryOp',
                        operator => '!=',
                        left => {
                            kind => 'signal_ref',
                            class => 'FSM::AST::SignalRef',
                            name => 'request',
                        },
                        right => {
                            kind => 'literal',
                            class => 'FSM::AST::Literal',
                            value => '0',
                        },
                    },
                },
            },
            rendered => '  assign idle_data_out_payload_en = idle_en & request;  // data_out <- payload',
            provenance => {
                family => 'generated_enable',
                role => 'dt_specific_enable',
                dt_name => 'idle',
                lhs_signal => 'data_out',
                rhs_value => 'payload',
                dte_gate_signal => 'idle_en',
            },
        },
        'direct assignment records expose DT-specific enables without parsing HDL strings',
    );
    is_deeply($structural->{instances}, [], 'direct structural_rtl_ir does not claim direct instances yet');
    is_deeply($structural->{declared_links}, [], 'direct structural_rtl_ir does not claim direct declared links yet');
    is_deeply($structural->{resolved_links}, [], 'direct structural_rtl_ir does not claim direct resolved links yet');
    is($structural->{net_count}, 7, 'direct structural_rtl_ir net_count matches helper declarations plus state and assignment enable wires');
    is($structural->{instance_count}, 0, 'direct structural_rtl_ir instance_count remains zero');
    is($structural->{declared_link_count}, 0, 'direct structural_rtl_ir declared_link_count remains zero');
    is($structural->{resolved_link_count}, 0, 'direct structural_rtl_ir resolved_link_count remains zero');
    is($structural->{auxiliary_assignment_count}, 5, 'direct structural_rtl_ir auxiliary_assignment_count matches generated enable assignment lines');
};

subtest 'direct structural_rtl_ir projects typed internal storage declaration nets' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_structural_internal_net_guard.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_structural_internal_net_guard
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+types
    (type signed_byte (four_state (signed (bits 8))))
  )
  (+size
    (OUT signed_byte)
    (IN signed_byte)
    (FLAG 1)
  )
  (idle
    (OUT <= IN)
    (-> run)
  )
  (run
    (FLAG = 1)
  )
)
FSM
    );

    my $result = generate_result($fsm_path);
    my $structural = $result->{structural_rtl_ir};
    my %nets_by_name = map { $_->{name} => $_ } @{$structural->{nets} || []};

    is_deeply(
        [sort keys %nets_by_name],
        [qw(FLAG OUT OUT_q flag_1_en idle_en idle_next_state_run_en idle_out_in_en next_state_run_en out_in_en run_en run_flag_1_en)],
        'direct structural_rtl_ir projects internal storage/helper declarations plus state and assignment enable wires',
    );
    is_deeply(
        $nets_by_name{idle_en},
        {
            name => 'idle_en',
            width => 1,
            signed => 0,
            source => assignment_source('idle_en', 'top_state_enable'),
            targets => [
                assignment_target('idle_out_in_en', 'dt_specific_enable'),
                assignment_target('idle_next_state_run_en', 'dt_specific_enable'),
            ],
        },
        'direct structural_rtl_ir records the idle state enable wire connectivity',
    );
    is_deeply(
        $nets_by_name{run_en},
        {
            name => 'run_en',
            width => 1,
            signed => 0,
            source => assignment_source('run_en', 'top_state_enable'),
            targets => [
                assignment_target('run_flag_1_en', 'dt_specific_enable'),
            ],
        },
        'direct structural_rtl_ir records the run state enable wire connectivity',
    );
    is_deeply(
        $nets_by_name{FLAG},
        {
            name => 'FLAG',
            width => 1,
            signed => 0,
            source => undef,
            targets => [],
        },
        'direct structural_rtl_ir records the single-bit internal storage declaration',
    );
    is_deeply(
        {
            name => $nets_by_name{OUT}{name},
            width => $nets_by_name{OUT}{width},
            signed => $nets_by_name{OUT}{signed},
            source => $nets_by_name{OUT}{source},
            targets => $nets_by_name{OUT}{targets},
            state_model => $nets_by_name{OUT}{state_model},
            declared_type_name => $nets_by_name{OUT}{declared_type_name},
            declared_type_spec => $nets_by_name{OUT}{declared_type_spec},
        },
        {
            name => 'OUT',
            width => 8,
            signed => 1,
            source => undef,
            targets => [],
            state_model => 'four_state',
            declared_type_name => 'signed_byte',
            declared_type_spec => {
                kind => 'bits',
                signed => 1,
                state_model => 'four_state',
                width => 8,
            },
        },
        'direct structural_rtl_ir preserves typed metadata on internal storage nets',
    );
    is_deeply(
        {
            name => $nets_by_name{OUT_q}{name},
            width => $nets_by_name{OUT_q}{width},
            signed => $nets_by_name{OUT_q}{signed},
            source => $nets_by_name{OUT_q}{source},
            targets => $nets_by_name{OUT_q}{targets},
            state_model => $nets_by_name{OUT_q}{state_model},
            declared_type_name => $nets_by_name{OUT_q}{declared_type_name},
            declared_type_spec => $nets_by_name{OUT_q}{declared_type_spec},
        },
        {
            name => 'OUT_q',
            width => 8,
            signed => 1,
            source => undef,
            targets => [],
            state_model => 'four_state',
            declared_type_name => 'signed_byte',
            declared_type_spec => {
                kind => 'bits',
                signed => 1,
                state_model => 'four_state',
                width => 8,
            },
        },
        'direct structural_rtl_ir preserves typed metadata on helper nets',
    );
    is($structural->{net_count}, 11, 'direct structural_rtl_ir net_count matches internal storage/helper declarations plus state and assignment enable wires');
    is_deeply(
        $structural->{auxiliary_assignments},
        [
            '  assign idle_en = current_state == IDLE;',
            '  assign run_en = current_state == RUN;',
            q{  assign idle_out_in_en = idle_en & 1'b1;  // OUT <- IN},
            q{  assign idle_next_state_run_en = idle_en & 1'b1;  // next_state <- RUN},
            q{  assign run_flag_1_en = run_en & 1'b1;  // FLAG <- 1},
            '  assign flag_1_en = run_flag_1_en;',
            '  assign out_in_en = idle_out_in_en;',
            '  assign next_state_run_en = idle_next_state_run_en;',
        ],
        'direct structural_rtl_ir projects typed fixture generated enable assignments',
    );
    is($structural->{auxiliary_assignment_count}, 8, 'direct structural_rtl_ir counts typed fixture enable assignment lines');
    is($structural->{assignment_record_count}, 8, 'direct structural_rtl_ir counts typed fixture enable assignment records');
    is_deeply(
        [map { $_->{rendered} } @{$structural->{assignment_records} || []}],
        $structural->{auxiliary_assignments},
        'typed fixture assignment records render the scalar assignment compatibility mirror',
    );
    is_deeply($structural->{instances}, [], 'direct structural_rtl_ir still does not claim direct instances');
    is_deeply($structural->{declared_links}, [], 'direct structural_rtl_ir still does not claim direct declared links');
    is_deeply($structural->{resolved_links}, [], 'direct structural_rtl_ir still does not claim direct resolved links');
    like($result->{hdl_code}, qr/\blogic\s+signed\s+\[7:0\]\s+OUT;/, 'generated HDL declares the typed internal storage net');
    like($result->{hdl_code}, qr/\blogic\s+signed\s+\[7:0\]\s+OUT_q;/, 'generated HDL declares the typed helper net');
};

subtest 'direct structural_rtl_ir projects top-level standalone-DT enable wires without claiming WEN/EN connectivity' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_structural_dt_enable_net_guard.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_structural_dt_enable_net_guard
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (EXTRA 1)
    (OUT1 1)
    (WATCH 1)
  )
  (idle <EXTRA
    (<A
      (OUT1 <= 1)
    )
  )
  (-watch <A
    (WATCH = 1)
  )
)
FSM
    );

    my $result = generate_result($fsm_path);
    my $structural = $result->{structural_rtl_ir};
    my %nets_by_name = map { $_->{name} => $_ } @{$structural->{nets} || []};

    is_deeply(
        $nets_by_name{idle_en},
        {
            name => 'idle_en',
            width => 1,
            signed => 0,
            source => assignment_source('idle_en', 'top_state_enable'),
            targets => [
                assignment_target('idle_out1_1_en', 'dt_specific_enable'),
            ],
        },
        'direct structural_rtl_ir records the guarded regular-state top-level enable wire connectivity',
    );
    is_deeply(
        $nets_by_name{watch_en},
        {
            name => 'watch_en',
            width => 1,
            signed => 0,
            source => assignment_source('watch_en', 'standalone_dt_enable'),
            targets => [
                assignment_target('watch_watch_1_en', 'dt_specific_enable'),
            ],
        },
        'direct structural_rtl_ir records the standalone-DT top-level enable wire connectivity',
    );
    is_deeply(
        $nets_by_name{idle_out1_1_en},
        {
            name => 'idle_out1_1_en',
            width => 1,
            signed => 0,
            source => assignment_source('idle_out1_1_en', 'dt_specific_enable'),
            targets => [
                assignment_target('out1_1_en', 'lhs_level_enable'),
            ],
        },
        'direct structural_rtl_ir records the regular-state DT-specific WEN/EN wire connectivity',
    );
    is_deeply(
        $nets_by_name{out1_1_en},
        {
            name => 'out1_1_en',
            width => 1,
            signed => 0,
            source => assignment_source('out1_1_en', 'lhs_level_enable'),
            targets => [],
        },
        'direct structural_rtl_ir records the regular-state LHS-level WEN/EN wire connectivity',
    );
    is_deeply(
        $nets_by_name{watch_watch_1_en},
        {
            name => 'watch_watch_1_en',
            width => 1,
            signed => 0,
            source => assignment_source('watch_watch_1_en', 'dt_specific_enable'),
            targets => [
                assignment_target('watch_1_en', 'lhs_level_enable'),
            ],
        },
        'direct structural_rtl_ir records the standalone-DT DT-specific WEN/EN wire connectivity',
    );
    is_deeply(
        $nets_by_name{watch_1_en},
        {
            name => 'watch_1_en',
            width => 1,
            signed => 0,
            source => assignment_source('watch_1_en', 'lhs_level_enable'),
            targets => [],
        },
        'direct structural_rtl_ir records the standalone-DT LHS-level WEN/EN wire connectivity',
    );
    like($result->{hdl_code}, qr/\bassign\s+idle_en\s+=\s+\(current_state\s+==\s+IDLE\)\s+\|\s+EXTRA;/, 'generated HDL emits the guarded state enable wire assignment');
    like($result->{hdl_code}, qr/\bassign\s+watch_en\s+=\s+A;/, 'generated HDL emits the standalone-DT enable wire assignment');
    is_deeply(
        $structural->{auxiliary_assignments},
        [
            '  assign idle_en = (current_state == IDLE) | EXTRA;',
            '  assign watch_en = A;',
            q{  assign watch_watch_1_en = watch_en & 1'b1;  // WATCH <- 1},
            '  assign idle_out1_1_en = idle_en & A;  // OUT1 <- 1',
            '  assign out1_1_en = idle_out1_1_en;',
            '  assign watch_1_en = watch_watch_1_en;',
        ],
        'direct structural_rtl_ir projects state, standalone-DT, DT-specific, and LHS-level enable assignments',
    );
    is($structural->{auxiliary_assignment_count}, 6, 'direct structural_rtl_ir counts the DT enable assignment lines');
    is($structural->{assignment_record_count}, 6, 'direct structural_rtl_ir counts the DT enable assignment records');
    is_deeply(
        record_by_lhs($structural, 'watch_en'),
        {
            kind => 'continuous_assign',
            lhs => {
                kind => 'signal_ref',
                name => 'watch_en',
            },
            rhs => {
                kind => 'expression',
                language => 'systemverilog',
                text => 'A',
                ast => {
                    kind => 'binary_op',
                    class => 'FSM::CoreAST::BinaryOp',
                    operator => '!=',
                    left => {
                        kind => 'signal_ref',
                        class => 'FSM::CoreAST::SignalRef',
                        name => 'A',
                    },
                    right => {
                        kind => 'literal',
                        class => 'FSM::CoreAST::Literal',
                        value => '0',
                        radix => 'decimal',
                    },
                },
            },
            rendered => '  assign watch_en = A;',
            provenance => {
                family => 'generated_enable',
                role => 'standalone_dt_enable',
                dt_name => '-watch',
                clean_dt_name => 'watch',
            },
        },
        'direct assignment records expose standalone-DT enables as structured records',
    );
    is_deeply(
        record_by_lhs($structural, 'watch_watch_1_en')->{provenance},
        {
            family => 'generated_enable',
            role => 'dt_specific_enable',
            dt_name => '-watch',
            lhs_signal => 'WATCH',
            rhs_value => '1',
            dte_gate_signal => 'watch_en',
        },
        'direct assignment records preserve standalone-DT specific enable provenance',
    );
};

done_testing();

sub record_by_lhs {
    my ($structural, $lhs) = @_;
    my ($record) = grep {
        ref($_) eq 'HASH'
            && ref($_->{lhs}) eq 'HASH'
            && (($_->{lhs}{name} // '') eq $lhs)
    } @{$structural->{assignment_records} || []};
    return $record;
}

sub assignment_source {
    my ($assignment_lhs, $role) = @_;
    return {
        kind => 'assignment_record_driver',
        assignment_lhs => $assignment_lhs,
        assignment_kind => 'continuous_assign',
        family => 'generated_enable',
        role => $role,
    };
}

sub assignment_target {
    my ($assignment_lhs, $role) = @_;
    return {
        kind => 'assignment_record_rhs_dependency',
        assignment_lhs => $assignment_lhs,
        assignment_kind => 'continuous_assign',
        family => 'generated_enable',
        role => $role,
    };
}

sub expected_ports_from_module_info {
    my ($module_info) = @_;
    my %ports;

    for my $bucket (
        [ inputs => 'input' ],
        [ outputs => 'output' ],
    ) {
        my ($analysis_key, $direction) = @$bucket;
        for my $entry (@{$module_info->{signal_analysis}{$analysis_key} || []}) {
            my $name = $entry->{name};
            next unless defined($name) && length($name);
            my $signal = ref($module_info->{signals}) eq 'HASH'
                ? $module_info->{signals}{$name}
                : undef;
            $ports{$name} = {
                direction => $direction,
                width => $entry->{width} || 1,
                signed => (ref($signal) && $signal->can('signed') && $signal->signed) ? 1 : 0,
                type => (ref($signal) && $signal->can('type')) ? $signal->type : undef,
            };
        }
    }

    my $system_contract = $module_info->{system_contract} || {};
    if (($module_info->{requires_implicit_system_ports} || $module_info->{explicit_system_contract})
        && defined($system_contract->{clock}) && length($system_contract->{clock})
        && !exists $ports{$system_contract->{clock}}) {
        $ports{$system_contract->{clock}} = {
            direction => 'input',
            width => 1,
            signed => 0,
            type => 'clock',
        };
    }
    if (($module_info->{requires_implicit_system_ports} || $module_info->{explicit_system_contract})
        && defined($system_contract->{reset}) && length($system_contract->{reset})
        && !exists $ports{$system_contract->{reset}}) {
        $ports{$system_contract->{reset}} = {
            direction => 'input',
            width => 1,
            signed => 0,
            type => 'reset',
        };
    }

    return \%ports;
}

sub extract_module_header {
    my ($hdl_code) = @_;
    my ($header) = ($hdl_code || '') =~ /(module\s+direct_structural_projection_guard\s*\(.*?\n\);)/s;
    ok(defined $header, 'generated HDL contains the direct module header');
    return defined($header) ? $header : '';
}

sub generate_result {
    my ($path) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    return $pipeline->generate_hdl_from_file($path);
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
