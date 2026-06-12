#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Backend::VerilogFamily::StructuralRTLIREmitter;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::Pipeline::HDLGenerator;
use FSM::IR::StructuralRTLIR;
use FSM::Test::CompositionNets qw(assert_only_carrier_and_shared_dp_sink_nets);

my $tempdir = tempdir(CLEANUP => 1);

subtest 'composition tops now surface a structural_rtl_ir connectivity summary' => sub {
    my $composition_path = write_fsm('composition_top_structural_rtl_ir_surface.fsm', <<'FSM');
(?top:composition_top_structural_rtl_ir_surface
  (?ports:public_io
    clk
    rstn
    select
    data_a<8
    data_b<8
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?dtc:router route_src)
  (?wiring:wiring
    /select/producer.select/
    /producer.output_data/router.IN_A/
    /data_a/router.A/
    /data_b/router.B/
    /router.OUT/result_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (asreset rstn)
  )
  (+size
    (select 1)
    (output_data 8)
  )
  (IDLE
    (<select==1'b0
      (output_data> <= 8'1)
    )
  )
  (ACTIVE
    (<select==1'b1
      (output_data> <= 8'2)
    )
  )
)

(?dt:route_src
  (+size
    (IN_A 8)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (-from_in_a
    (OUT = IN_A)
  )
  (-from_a
    (OUT = A)
  )
  (-from_b
    (OUT = B)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $structural_rtl_ir = $result->{structural_rtl_ir};
    my $module_info = $result->{module_info};
    my $statistics = $result->{statistics};
    my $composition_plan = $result->{composition_plan};
    my $structural_rtl_ir_obj = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan(
        $composition_plan,
        'systemverilog',
    );

    ok($structural_rtl_ir, 'composition top now exposes a top-level structural_rtl_ir summary');
    is_deeply(
        $module_info->{structural_rtl_ir},
        $structural_rtl_ir,
        'composition module_info preserves the same serialized structural_rtl_ir summary',
    );

    is($structural_rtl_ir->{module_name}, 'composition_top_structural_rtl_ir_surface', 'structural_rtl_ir preserves the top module name');
    is($structural_rtl_ir->{source_root_kind}, 'top', 'structural_rtl_ir reports the top root kind');
    is($structural_rtl_ir->{target_language}, 'systemverilog', 'structural_rtl_ir preserves the target language');
    is($structural_rtl_ir->{port_count}, 6, 'structural_rtl_ir reports top port count');
    is_deeply(
        [map { $_->{name} } @{$structural_rtl_ir->{ports}}],
        ['clk', 'rstn', 'select', 'data_a', 'data_b', 'result_data'],
        'structural_rtl_ir preserves top port order',
    );
    is_deeply(
        [map { $_->{direction} } @{$structural_rtl_ir->{ports}}],
        ['input', 'input', 'input', 'input', 'input', 'output'],
        'structural_rtl_ir preserves top port directions',
    );
    is_deeply(
        [map { $_->{width} } @{$structural_rtl_ir->{ports}}],
        [1, 1, 1, 8, 8, 8],
        'structural_rtl_ir preserves top port widths',
    );

    my ($structural_carrier_nets) = assert_only_carrier_and_shared_dp_sink_nets(
        $structural_rtl_ir->{nets},
        ['comp_link_producer_output_data'],
        'structural_rtl_ir internal connectivity',
    );
    is($structural_rtl_ir->{net_count}, scalar(@{$structural_rtl_ir->{nets}}), 'structural_rtl_ir reports physical internal net count');
    is_deeply(
        $structural_carrier_nets,
        [
            {
                name => 'comp_link_producer_output_data',
                source => 'producer.output_data',
                targets => ['router.IN_A'],
                width => 8,
            },
        ],
        'structural_rtl_ir preserves explicit internal connectivity nets',
    );

    is($structural_rtl_ir->{instance_count}, 2, 'structural_rtl_ir reports realized instance count');
    is_deeply(
        [map { $_->{instance_name} } @{$structural_rtl_ir->{instances}}],
        ['producer', 'router'],
        'structural_rtl_ir preserves realized instance order',
    );
    my $producer = $structural_rtl_ir->{instances}[0];
    my $router = $structural_rtl_ir->{instances}[1];
    my $planned_producer = $composition_plan->instances->[0];
    my $planned_router = $composition_plan->instances->[1];
    is($producer->{kind}, 'fsmc', 'structural_rtl_ir preserves the first instance kind');
    is($producer->{module_name}, 'producer_src', 'structural_rtl_ir preserves the first instance module name');
    is($producer->{source_name}, 'producer_src', 'structural_rtl_ir preserves the first instance source name');
    is_deeply(
        [sort map { $_->{name} } @{$producer->{interface_ports}}],
        ['clk', 'output_data', 'rstn', 'select'],
        'structural_rtl_ir preserves the first instance interface port names',
    );
    is_deeply(
        { map { $_->{name} => { direction => $_->{direction}, type => $_->{type}, width => $_->{width} } } @{$producer->{interface_ports}} },
        {
            clk => { direction => 'input', type => 'clock', width => 1 },
            output_data => { direction => 'output', type => undef, width => 8 },
            rstn => { direction => 'input', type => 'reset', width => 1 },
            select => { direction => 'input', type => undef, width => 1 },
        },
        'structural_rtl_ir preserves the first instance interface port metadata',
    );
    is_deeply(
        {
            map { $_->{port_name} => $_->{signal_name} }
            grep { (($_->{signal_name} || '') !~ /\Ashared_dp_unused_/) }
            @{$producer->{port_bindings}}
        },
        {
            clk => 'clk',
            rstn => 'rstn',
            select => 'select',
            output_data => 'comp_link_producer_output_data',
        },
        'structural_rtl_ir preserves the first instance pin bindings',
    );
    is_deeply(
        {
            map { $_->{port_name} => $_->{connection_expr} }
            grep { (($_->{signal_name} || '') !~ /\Ashared_dp_unused_/) }
            @{$producer->{port_bindings}}
        },
        {
            clk => { kind => 'signal_ref', signal_name => 'clk' },
            rstn => { kind => 'signal_ref', signal_name => 'rstn' },
            select => { kind => 'signal_ref', signal_name => 'select' },
            output_data => { kind => 'signal_ref', signal_name => 'comp_link_producer_output_data' },
        },
        'structural_rtl_ir preserves the first instance connection expressions',
    );
    is_deeply(
        {
            map { $_->{port_name} => $_->{connection_expr} }
            grep { (($_->{signal_name} || '') !~ /\Ashared_dp_unused_/) }
            @{$planned_producer->port_bindings}
        },
        {
            clk => { kind => 'signal_ref', signal_name => 'clk' },
            rstn => { kind => 'signal_ref', signal_name => 'rstn' },
            select => { kind => 'signal_ref', signal_name => 'select' },
            output_data => { kind => 'signal_ref', signal_name => 'comp_link_producer_output_data' },
        },
        'composition_plan now preserves the first instance connection expressions before structural serialization',
    );

    is($router->{kind}, 'dtc', 'structural_rtl_ir preserves the second instance kind');
    is($router->{module_name}, 'route_src', 'structural_rtl_ir preserves the second instance module name');
    is($router->{source_name}, 'route_src', 'structural_rtl_ir preserves the second instance source name');
    is_deeply(
        [sort map { $_->{name} } @{$router->{interface_ports}}],
        ['A', 'B', 'IN_A', 'OUT'],
        'structural_rtl_ir preserves the second instance interface port names',
    );
    is_deeply(
        { map { $_->{name} => { direction => $_->{direction}, type => $_->{type}, width => $_->{width} } } @{$router->{interface_ports}} },
        {
            A => { direction => 'input', type => undef, width => 8 },
            B => { direction => 'input', type => undef, width => 8 },
            IN_A => { direction => 'input', type => undef, width => 8 },
            OUT => { direction => 'output', type => undef, width => 8 },
        },
        'structural_rtl_ir preserves the second instance interface port metadata',
    );
    is_deeply(
        { map { $_->{port_name} => $_->{signal_name} } @{$router->{port_bindings}} },
        {
            IN_A => 'comp_link_producer_output_data',
            A => 'data_a',
            B => 'data_b',
            OUT => 'result_data',
        },
        'structural_rtl_ir preserves the second instance pin bindings',
    );
    is_deeply(
        { map { $_->{port_name} => $_->{connection_expr} } @{$router->{port_bindings}} },
        {
            IN_A => { kind => 'signal_ref', signal_name => 'comp_link_producer_output_data' },
            A => { kind => 'signal_ref', signal_name => 'data_a' },
            B => { kind => 'signal_ref', signal_name => 'data_b' },
            OUT => { kind => 'signal_ref', signal_name => 'result_data' },
        },
        'structural_rtl_ir preserves the second instance connection expressions',
    );
    is_deeply(
        { map { $_->{port_name} => $_->{connection_expr} } @{$planned_router->port_bindings} },
        {
            IN_A => { kind => 'signal_ref', signal_name => 'comp_link_producer_output_data' },
            A => { kind => 'signal_ref', signal_name => 'data_a' },
            B => { kind => 'signal_ref', signal_name => 'data_b' },
            OUT => { kind => 'signal_ref', signal_name => 'result_data' },
        },
        'composition_plan now preserves the second instance connection expressions before structural serialization',
    );
    is($structural_rtl_ir->{declared_link_count}, 5, 'structural_rtl_ir reports declared wiring count');
    is_deeply(
        [
            sort map { join(' -> ', $_->{source}, $_->{target}, ($_->{origin_kind} // '')) }
            @{$structural_rtl_ir->{declared_links}}
        ],
        [
            sort { $a cmp $b } (
                'data_a -> router.A -> declared_explicit_wiring',
                'data_b -> router.B -> declared_explicit_wiring',
                'producer.output_data -> router.IN_A -> declared_explicit_wiring',
                'router.OUT -> result_data -> declared_explicit_wiring',
                'select -> producer.select -> declared_explicit_wiring',
            )
        ],
        'structural_rtl_ir preserves declared explicit-link connectivity separately from resolved links',
    );
    is($structural_rtl_ir->{resolved_link_count}, 7, 'structural_rtl_ir reports resolved connectivity link count');
    is_deeply(
        [
            sort map { join(' -> ', $_->{source}, $_->{target}, ($_->{origin_kind} // '')) }
            @{$structural_rtl_ir->{resolved_links}}
        ],
        [
            sort { $a cmp $b } (
                'clk -> producer.clk -> auto_system_port_link',
                'data_a -> router.A -> declared_explicit_wiring',
                'data_b -> router.B -> declared_explicit_wiring',
                'producer.output_data -> router.IN_A -> declared_explicit_wiring',
                'router.OUT -> result_data -> declared_explicit_wiring',
                'rstn -> producer.rstn -> auto_system_port_link',
                'select -> producer.select -> declared_explicit_wiring',
            )
        ],
        'structural_rtl_ir preserves explicit resolved-link connectivity',
    );
    is($structural_rtl_ir->{auxiliary_assignment_count}, 0, 'structural_rtl_ir reports auxiliary assignment count');
    is_deeply($structural_rtl_ir->{auxiliary_assignments}, [], 'structural_rtl_ir preserves explicit empty auxiliary assignments');
    is($structural_rtl_ir->{assignment_record_count}, 0, 'structural_rtl_ir reports assignment record count');
    is_deeply($structural_rtl_ir->{assignment_records}, [], 'structural_rtl_ir preserves explicit empty assignment records');
    is(
        $module_info->{composition_child_count},
        $structural_rtl_ir->{instance_count},
        'composition module_info now derives child count from structural_rtl_ir',
    );
    is(
        $module_info->{composition_net_count},
        $structural_rtl_ir->{net_count},
        'composition module_info now derives net count from structural_rtl_ir',
    );
    is(
        $statistics->{composition_child_count},
        $structural_rtl_ir->{instance_count},
        'composition statistics now derive child count from structural_rtl_ir',
    );
    is(
        $statistics->{composition_top_port_count},
        $structural_rtl_ir->{port_count},
        'composition statistics now derive top-port count from structural_rtl_ir',
    );
    is(
        $statistics->{composition_net_count},
        $structural_rtl_ir->{net_count},
        'composition statistics now derive net count from structural_rtl_ir',
    );
    is(
        $module_info->{composition_resolved_link_count},
        $structural_rtl_ir->{resolved_link_count},
        'composition module_info now derives resolved-link count from structural_rtl_ir via the report handoff',
    );
    is(
        $statistics->{composition_resolved_link_count},
        $structural_rtl_ir->{resolved_link_count},
        'composition statistics now derive resolved-link count from structural_rtl_ir via the report handoff',
    );

    my $router_out = $structural_rtl_ir_obj->interface_endpoint('router.OUT');
    is($router_out->{endpoint}, 'router.OUT', 'structural_rtl_ir endpoint lookup preserves the full endpoint token');
    is($router_out->{instance_name}, 'router', 'structural_rtl_ir endpoint lookup preserves the instance name');
    is($router_out->{port_name}, 'OUT', 'structural_rtl_ir endpoint lookup preserves the formal port name');
    is_deeply(
        $router_out->{port},
        { direction => 'output', name => 'OUT', type => undef, width => 8, signed => 0 },
        'structural_rtl_ir endpoint lookup preserves the interface port metadata',
    );

    my $select_inputs = $structural_rtl_ir_obj->interface_signal_endpoints('select', 'input');
    is(scalar(@$select_inputs), 1, 'structural_rtl_ir signal-family lookup finds the matching input endpoint');
    is($select_inputs->[0]{endpoint}, 'producer.select', 'signal-family lookup preserves the matching child endpoint token');

    my $signal_groups = $structural_rtl_ir_obj->interface_signal_endpoint_groups;
    is_deeply(
        [map { $_->{endpoint} } @{$signal_groups->{output_data} || []}],
        ['producer.output_data'],
        'structural_rtl_ir signal-family grouping indexes child endpoints by interface signal name',
    );

    is_deeply(
        $structural_rtl_ir_obj->top_port('result_data'),
        {
            binding_mode => 'explicit',
            direction => 'output',
            name => 'result_data',
            origin_kind => 'declared_explicit_port',
            signed => 0,
            type => undef,
            width => 8,
        },
        'structural_rtl_ir top-port lookup preserves cloned top-port metadata',
    );

    is_deeply(
        $structural_rtl_ir_obj->resolved_links_touching('select', 'declared_explicit_wiring'),
        [
            {
                origin_kind => 'declared_explicit_wiring',
                raw_token => '/select/producer.select/',
                source => 'select',
                target => 'producer.select',
            },
        ],
        'structural_rtl_ir resolved-link lookup can answer which explicit wiring_blocks touch a given endpoint',
    );

    my $port_metadata = $structural_rtl_ir_obj->port_metadata;
    is_deeply(
        $port_metadata,
        FSM::IR::StructuralRTLIR->port_metadata_from_input($structural_rtl_ir),
        'structural_rtl_ir port metadata helper works for both objects and serialized hashes',
    );
    is_deeply(
        FSM::IR::StructuralRTLIRBuilder->coerce($structural_rtl_ir, 'systemverilog')->as_hashref,
        $structural_rtl_ir,
        'structural_rtl_ir builder coercion preserves the serialized structural graph',
    );
    is_deeply(
        $port_metadata->{signal_names},
        ['clk', 'rstn', 'select', 'data_a', 'data_b', 'result_data'],
        'structural_rtl_ir port metadata preserves top-port signal names',
    );
    is_deeply(
        $port_metadata->{signal_analysis}{inputs},
        [
            { name => 'clk', width => 1, direction => 'input', signed => 0 },
            { name => 'rstn', width => 1, direction => 'input', signed => 0 },
            { name => 'select', width => 1, direction => 'input', signed => 0 },
            { name => 'data_a', width => 8, direction => 'input', signed => 0 },
            { name => 'data_b', width => 8, direction => 'input', signed => 0 },
        ],
        'structural_rtl_ir port metadata groups input ports',
    );
    is_deeply(
        $port_metadata->{signal_analysis}{outputs},
        [
            { name => 'result_data', width => 8, direction => 'output', signed => 0 },
        ],
        'structural_rtl_ir port metadata groups output ports',
    );
    is_deeply(
        $port_metadata->{signals},
        {
            clk => { width => 1, direction => 'input', signed => 0 },
            rstn => { width => 1, direction => 'input', signed => 0 },
            select => { width => 1, direction => 'input', signed => 0 },
            data_a => { width => 8, direction => 'input', signed => 0 },
            data_b => { width => 8, direction => 'input', signed => 0 },
            result_data => { width => 8, direction => 'output', signed => 0 },
        },
        'structural_rtl_ir port metadata preserves the compatible signals map',
    );

    my $rendered_top = FSM::Backend::VerilogFamily::StructuralRTLIREmitter->emit_module($structural_rtl_ir);
    like(
        $result->{hdl_code},
        qr/\Q$rendered_top\E/s,
        'composition HDL contains the top module rendered directly by the structural backend emitter',
    );
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
