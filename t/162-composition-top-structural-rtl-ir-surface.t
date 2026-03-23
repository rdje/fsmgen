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
  (?toplink:wiring
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

    is($structural_rtl_ir->{net_count}, 1, 'structural_rtl_ir reports internal net count');
    is_deeply(
        $structural_rtl_ir->{nets},
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
        { map { $_->{port_name} => $_->{signal_name} } @{$producer->{port_bindings}} },
        {
            clk => 'clk',
            rstn => 'rstn',
            select => 'select',
            output_data => 'comp_link_producer_output_data',
        },
        'structural_rtl_ir preserves the first instance pin bindings',
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
    is($structural_rtl_ir->{resolved_link_count}, 7, 'structural_rtl_ir reports resolved connectivity link count');
    is_deeply(
        [
            sort map { join(' -> ', $_->{source}, $_->{target}, ($_->{origin_kind} // '')) }
            @{$structural_rtl_ir->{resolved_links}}
        ],
        [
            sort { $a cmp $b } (
                'clk -> producer.clk -> auto_system_port_link',
                'data_a -> router.A -> declared_explicit_toplink',
                'data_b -> router.B -> declared_explicit_toplink',
                'producer.output_data -> router.IN_A -> declared_explicit_toplink',
                'router.OUT -> result_data -> declared_explicit_toplink',
                'rstn -> producer.rstn -> auto_system_port_link',
                'select -> producer.select -> declared_explicit_toplink',
            )
        ],
        'structural_rtl_ir preserves explicit resolved-link connectivity',
    );
    is($structural_rtl_ir->{auxiliary_assignment_count}, 0, 'structural_rtl_ir reports auxiliary assignment count');
    is_deeply($structural_rtl_ir->{auxiliary_assignments}, [], 'structural_rtl_ir preserves explicit empty auxiliary assignments');
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

    my $rendered_top = $pipeline->emit_composition_top_module($structural_rtl_ir);
    like(
        $result->{hdl_code},
        qr/\Q$rendered_top\E/s,
        'composition HDL contains the top module rendered directly from structural_rtl_ir',
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
