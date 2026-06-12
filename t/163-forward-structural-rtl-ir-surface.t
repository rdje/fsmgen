#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'direct generated roots now surface a bounded structural_rtl_ir module-interface summary' => sub {
    my $fsm_path = write_fsm('structural_rtl_ir_direct.fsm', <<'FSM');
(?fsm:structural_rtl_ir_direct
  (+system
    (clock clk)
    (asreset rstn)
  )
  (+size
    (IN 8)
    (OUT 8)
  )
  (IDLE
    (OUT> <= IN)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $structural_rtl_ir = $result->{structural_rtl_ir};

    ok($structural_rtl_ir, 'direct result now exposes a structural_rtl_ir summary');
    is_deeply(
        $result->{module_info}{structural_rtl_ir},
        $structural_rtl_ir,
        'module_info preserves the same serialized structural_rtl_ir summary',
    );
    is($structural_rtl_ir->{module_name}, 'structural_rtl_ir_direct', 'structural_rtl_ir preserves the direct module name');
    is($structural_rtl_ir->{source_root_kind}, 'fsm', 'structural_rtl_ir preserves the direct root kind');
    is($structural_rtl_ir->{target_language}, 'systemverilog', 'structural_rtl_ir preserves the direct target language');
    is($structural_rtl_ir->{port_count}, 4, 'structural_rtl_ir reports the full direct module port count');
    is_deeply(
        [sort map { $_->{name} } @{$structural_rtl_ir->{ports}}],
        [qw(IN OUT clk rstn)],
        'structural_rtl_ir preserves the direct module port names',
    );

    my %ports_by_name = map { $_->{name} => $_ } @{$structural_rtl_ir->{ports}};
    is_deeply(
        {
            map {
                $_ => {
                    direction => $ports_by_name{$_}{direction},
                    width => $ports_by_name{$_}{width},
                    type => $ports_by_name{$_}{type},
                }
            } sort keys %ports_by_name
        },
        {
            IN => { direction => 'input', width => 8, type => 'wire' },
            OUT => { direction => 'output', width => 8, type => 'wire' },
            clk => { direction => 'input', width => 1, type => 'clock' },
            rstn => { direction => 'input', width => 1, type => 'reset' },
        },
        'structural_rtl_ir preserves direct module boundary port metadata',
    );
    is_deeply(
        $ports_by_name{OUT}{source},
        output_port_source(
            signal_name => 'OUT',
            multiplexer_type => 'flop',
            driver_count => 1,
            driver_blocks => ['IDLE'],
            rhs_values => ['IN'],
            driver_enable_signals => ['IDLE_out_in_en'],
            family_enable_signals => ['out_in_en'],
        ),
        'structural_rtl_ir exposes a structured source summary for the direct output port',
    );
    is($structural_rtl_ir->{net_count}, 4, 'bounded direct structural_rtl_ir reports helper plus generated enable net count');
    is_deeply(
        $structural_rtl_ir->{nets},
        [
            {
                name => 'OUT_q',
                width => 8,
                signed => 0,
                source => undef,
                targets => [],
            },
            {
                name => 'IDLE_en',
                width => 1,
                signed => 0,
                source => assignment_source('IDLE_en', 'top_state_enable'),
                targets => [
                    assignment_target('IDLE_out_in_en', 'dt_specific_enable'),
                ],
            },
            {
                name => 'IDLE_out_in_en',
                width => 1,
                signed => 0,
                source => assignment_source('IDLE_out_in_en', 'dt_specific_enable'),
                targets => [
                    assignment_target('out_in_en', 'lhs_level_enable'),
                ],
            },
            {
                name => 'out_in_en',
                width => 1,
                signed => 0,
                source => assignment_source('out_in_en', 'lhs_level_enable'),
                targets => [],
            },
        ],
        'structural_rtl_ir projects the direct output helper and generated enable declaration-only nets',
    );
    is_deeply(
        $structural_rtl_ir->{auxiliary_assignments},
        [
            '  assign IDLE_en = current_state == IDLE;',
            q{  assign IDLE_out_in_en = IDLE_en & 1'b1;  // OUT <- IN},
            '  assign out_in_en = IDLE_out_in_en;',
        ],
        'structural_rtl_ir preserves direct generated enable assignment lines',
    );
    unlike(
        $result->{hdl_code},
        qr/FSMGEN_STRUCTURAL_RTLIR_ENABLE_ASSIGNMENTS_(?:BEGIN|END)/,
        'pipeline direct HDL does not leak internal StructuralRTLIR reroute markers',
    );
    is($structural_rtl_ir->{assignment_record_count}, 3, 'bounded direct structural_rtl_ir reports direct enable assignment records');
    is_deeply(
        [map { $_->{rendered} } @{$structural_rtl_ir->{assignment_records} || []}],
        $structural_rtl_ir->{auxiliary_assignments},
        'direct assignment records render the scalar assignment compatibility mirror',
    );
    is_deeply(
        $structural_rtl_ir->{assignment_records}[2],
        {
            kind => 'continuous_assign',
            lhs => {
                kind => 'signal_ref',
                name => 'out_in_en',
            },
            rhs => {
                kind => 'expression',
                language => 'systemverilog',
                text => 'IDLE_out_in_en',
                ast => {
                    kind => 'signal_ref',
                    class => 'FSM::AST::SignalRef',
                    name => 'IDLE_out_in_en',
                },
            },
            rendered => '  assign out_in_en = IDLE_out_in_en;',
            provenance => {
                family => 'generated_enable',
                role => 'lhs_level_enable',
                lhs_signal => 'OUT',
                rhs_value => 'IN',
            },
        },
        'structural_rtl_ir exposes LHS-level direct enable assignment records as structured data',
    );
    is($structural_rtl_ir->{instance_count}, 0, 'bounded direct structural_rtl_ir keeps instance count empty at this slice');
    is($structural_rtl_ir->{auxiliary_assignment_count}, 3, 'bounded direct structural_rtl_ir reports direct enable assignment lines');
};

done_testing();

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

sub output_port_source {
    my (%args) = @_;
    return {
        kind => 'lowered_output_drive_family',
        signal_name => $args{signal_name},
        multiplexer_type => $args{multiplexer_type},
        driver_count => $args{driver_count},
        driver_blocks => $args{driver_blocks},
        rhs_values => $args{rhs_values},
        driver_enable_signals => $args{driver_enable_signals},
        family_enable_signals => $args{family_enable_signals},
    };
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
