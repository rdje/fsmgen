#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Link;
use FSM::Composition::LinkedPlanBuilder;
use FSM::Composition::Plan;
use FSM::Composition::Port;
use FSM::Composition::PortsBlock;
use FSM::Composition::RealizedInstance;
use FSM::Composition::Spec;
use FSM::Composition::Top;
use FSM::Composition::TopLink;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_select_expr
    slice_expr
);
use FSM::Pipeline::HDLGenerator;

subtest 'linked plan builder preserves child bit-select and slice sources through one base carrier' => sub {
    my @ports = (
        port('top_hi', 'output', 4, undef),
        port('top_flag', 'output', 1, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('child_expr_top'),
        top => FSM::Composition::Top->new(name => 'child_expr_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => 'producer.payload[7:4]', target => 'top_hi'),
                    FSM::Composition::Link->new(source => 'producer.payload[0]', target => 'top_flag'),
                    FSM::Composition::Link->new(source => 'producer.payload[7:4]', target => 'consumer.hi'),
                    FSM::Composition::Link->new(source => 'producer.payload[0]', target => 'consumer.enable'),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'producer',
                port('payload', 'output', 8, undef),
            ),
            realized_instance(
                'rtl',
                'consumer',
                port('hi', 'input', 4, undef),
                port('enable', 'input', 1, undef),
            ),
        ],
        fsm_file => 'child_expr_top.fsm',
        header => 'child_expr_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for child expressions');
    is(scalar(@{$plan->nets}), 1, 'child expressions from one child output share one deterministic base carrier net');
    is($plan->nets->[0]->name, 'comp_link_producer_payload', 'builder keeps the deterministic base-carrier naming rule for child expressions');
    is($plan->nets->[0]->source, 'producer.payload', 'carrier provenance points at the base child output rather than one projected expression');
    is_deeply(
        $plan->nets->[0]->targets,
        ['top_hi', 'top_flag', 'consumer.hi', 'consumer.enable'],
        'carrier net tracks both top-output and child-input consumers of the projected child source family',
    );
    is_deeply(
        $plan->auxiliary_assignments,
        [
            '    assign top_hi = comp_link_producer_payload[7:4];',
            '    assign top_flag = comp_link_producer_payload[0];',
        ],
        'builder emits direct top-output assignments from projected child-source expressions',
    );

    my %producer_bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    my %consumer_bindings = map { $_->{port_name} => $_ } @{$plan->instances->[1]->port_bindings};

    is($producer_bindings{payload}{signal_name}, 'comp_link_producer_payload', 'producer output binds once to the shared base carrier');
    is_deeply(
        $consumer_bindings{hi}{connection_expr},
        slice_expr('comp_link_producer_payload', 7, 4),
        'consumer hi binding preserves the typed slice expression on the shared carrier',
    );
    is_deeply(
        $consumer_bindings{enable}{connection_expr},
        bit_select_expr('comp_link_producer_payload', 0),
        'consumer enable binding preserves the typed bit-select expression on the shared carrier',
    );
};

subtest 'pipeline and CLI emit child bit-select and slice sources for explicit toplinks' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'child_expr_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'child_expr_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:child_expr_top
  (?ports:public_io
    top_hi>4
    top_flag>
  )
  (?rtl:producer)
  (?rtl:consumer)
  (?toplink:wiring
    /producer.payload[7:4]/top_hi/
    /producer.payload[0]/top_flag/
    /producer.payload[7:4]/consumer.hi/
    /producer.payload[0]/consumer.enable/
  )
)

(?rtlif:producer
  payload>8:data
)

(?rtlif:consumer
  hi<4:data
  enable:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'child-expression explicit toplinks stay on the C3 lane');

    my %producer_bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %consumer_bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($producer_bindings{payload}{signal_name}, 'comp_link_producer_payload', 'pipeline preserves one shared base carrier binding for the producer output');
    is_deeply(
        $consumer_bindings{hi}{connection_expr},
        slice_expr('comp_link_producer_payload', 7, 4),
        'pipeline preserves the typed child slice binding in the realized composition plan',
    );
    is_deeply(
        $consumer_bindings{enable}{connection_expr},
        bit_select_expr('comp_link_producer_payload', 0),
        'pipeline preserves the typed child bit-select binding in the realized composition plan',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bwire\s+\[7:0\]\s+comp_link_producer_payload\s*;/s, 'generated HDL emits one shared base carrier wire for projected child-source bindings');
    like($hdl, qr/\.payload\(comp_link_producer_payload\)/, 'generated HDL binds the producer output to the shared base carrier');
    like($hdl, qr/\.hi\(comp_link_producer_payload\[7:4\]\)/, 'generated HDL emits the child slice directly on the consumer input');
    like($hdl, qr/\.enable\(comp_link_producer_payload\[0\]\)/, 'generated HDL emits the child bit-select directly on the consumer input');
    like($hdl, qr/assign\s+top_hi\s*=\s*comp_link_producer_payload\[7:4\];/s, 'generated HDL emits the child slice directly on the top output assignment');
    like($hdl, qr/assign\s+top_flag\s*=\s*comp_link_producer_payload\[0\];/s, 'generated HDL emits the child bit-select directly on the top output assignment');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for explicit child-expression toplinks');
    ok(-e $output_path, 'CLI writes HDL for explicit child-expression toplinks');
};

subtest 'linked plan builder rejects out-of-range child expressions' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_child_expr_top'),
            top => FSM::Composition::Top->new(name => 'blocked_child_expr_top'),
            ports_block => FSM::Composition::PortsBlock->new(
                name => 'public_io',
                ports => [port('top_flag', 'output', 1, undef)],
            ),
            ports => [port('top_flag', 'output', 1, undef)],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => 'producer.payload[8]', target => 'top_flag'),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'producer',
                    port('payload', 'output', 8, undef),
                ),
            ],
            fsm_file => 'blocked_child_expr_top.fsm',
            header => 'blocked_child_expr_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses child expression 'producer\.payload\[8\]', .*explicit link endpoint resolution is blocked because bit index 8 falls outside declared width 8 of child endpoint 'producer\.payload'/s,
        'builder blocks out-of-range child expressions through the endpoint-resolution boundary',
    );
};

done_testing();

sub composition_spec {
    my ($top_name) = @_;
    return FSM::Composition::Spec->new(
        top => FSM::Composition::Top->new(name => $top_name),
    );
}

sub realized_instance {
    my ($kind, $instance_name, @ports) = @_;

    return FSM::Composition::RealizedInstance->new(
        kind => $kind,
        instance_name => $instance_name,
        module_name => $instance_name.'_mod',
        source_name => $instance_name.'_src',
        interface_ports => \@ports,
        port_bindings => [],
        module_info => {},
        hdl_code => undef,
    );
}

sub port {
    my ($name, $direction, $width, $type) = @_;
    return FSM::Composition::Port->new(
        name => $name,
        direction => $direction,
        width => $width,
        type => $type,
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
