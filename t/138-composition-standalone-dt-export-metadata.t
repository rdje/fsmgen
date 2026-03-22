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

subtest 'composition module_info aggregates reusable standalone-DT child export metadata' => sub {
    my $composition_path = write_fsm('composition_standalone_dt_export_metadata_top.fsm', <<'FSM');
(?top:composition_standalone_dt_export_metadata_top
  (?ports:public_io
    sel
    data_a<8
    data_b<8
    final_out>8
  )
  (?dtc:router_a route_a)
  (?dtc:router_b route_b)
  (?toplink:wiring
    /sel/router_a.sel/
    /data_a/router_a.a/
    /data_b/router_a.b/
    /router_a.out/router_b.in/
    /router_b.final_out/final_out/
  )
)

(?dt:route_a
  (+size
    (sel 1)
    (a 8)
    (b 8)
    (out 8)
  )
  (-from_a
    (<sel==1'b0
      (out> = a)
    )
  )
  (-from_b
    (<sel==1'b1
      (out> = b)
    )
  )
)

(?dt:route_b
  (+size
    (in 8)
    (final_out 8)
  )
  (-route
    (final_out> = in)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $intent_hir = $result->{intent_hir};
    my $module_info = $result->{module_info};
    my $children = $module_info->{composition_standalone_dt_children};
    my ($router_a, $router_b) = @$children;

    is($result->{composition_plan}->lane, 'C2', 'two generated dt children use the explicit-link C2 lane');
    is($module_info->{composition_standalone_dt_child_count}, 2, 'top module_info counts realized dt children');
    is($module_info->{composition_standalone_dt_block_count}, 3, 'top module_info sums standalone-DT blocks across realized dt children');
    is($module_info->{composition_standalone_dt_multi_drive_target_count}, 1, 'top module_info sums grouped shared targets across realized dt children');
    is($intent_hir->{composition_standalone_dt_child_count}, 2, 'top intent_hir counts realized dt children');
    is($intent_hir->{composition_standalone_dt_block_count}, 3, 'top intent_hir sums standalone-DT blocks across realized dt children');
    is($intent_hir->{composition_standalone_dt_multi_drive_target_count}, 1, 'top intent_hir sums grouped shared targets across realized dt children');
    is_deeply(
        [map { $_->{instance_name} } @$children],
        ['router_a', 'router_b'],
        'top module_info keeps reusable dt children in stable instance order',
    );
    is_deeply(
        [map { $_->{instance_name} } @{$intent_hir->{composition_standalone_dt_children}}],
        ['router_a', 'router_b'],
        'top intent_hir keeps reusable dt children in stable instance order',
    );
    is_deeply(
        $intent_hir->{composition_standalone_dt_children},
        $module_info->{composition_standalone_dt_children},
        'top module_info mirrors the reusable dt child export from intent_hir',
    );
    is_deeply(
        {
            instance_name => $router_a->{instance_name},
            module_name => $router_a->{module_name},
            source_name => $router_a->{source_name},
            standalone_dt_count => $router_a->{standalone_dt_count},
            standalone_dt_names => $router_a->{standalone_dt_names},
            standalone_dt_enable_families => $router_a->{standalone_dt_enable_families},
            standalone_dt_module_enable_family => $router_a->{standalone_dt_module_enable_family},
            standalone_dt_multi_drive_target_count => $router_a->{standalone_dt_multi_drive_target_count},
            standalone_dt_multi_drive_targets => $router_a->{standalone_dt_multi_drive_targets},
        },
        {
            instance_name => 'router_a',
            module_name => 'route_a',
            source_name => 'route_a',
            standalone_dt_count => 2,
            standalone_dt_names => ['-from_a', '-from_b'],
            standalone_dt_enable_families => [
                { dt_name => '-from_a', enable_signal => 'from_a_en' },
                { dt_name => '-from_b', enable_signal => 'from_b_en' },
            ],
            standalone_dt_module_enable_family => {
                dt_names => ['-from_a', '-from_b'],
                enable_signals => ['from_a_en', 'from_b_en'],
            },
            standalone_dt_multi_drive_target_count => 1,
            standalone_dt_multi_drive_targets => [
                {
                    signal_name => 'out',
                    multiplexer_type => 'comb',
                    dt_names => ['-from_a', '-from_b'],
                    rhs_values => ['a', 'b'],
                    dt_enable_signals => ['from_a_out_a_en', 'from_b_out_b_en'],
                    lhs_enable_signals => ['out_a_en', 'out_b_en'],
                    multi_drive_assertion => {
                        kind => 'onehot0',
                        target_signal => 'out',
                        input_count => 2,
                        input_enable_signals => ['from_a_out_a_en', 'from_b_out_b_en'],
                    },
                },
            ],
        },
        'top module_info exposes reusable dt child export metadata for the first child while allowing additional exported forward IR fields',
    );
    is_deeply(
        {
            instance_name => $router_b->{instance_name},
            module_name => $router_b->{module_name},
            source_name => $router_b->{source_name},
            standalone_dt_count => $router_b->{standalone_dt_count},
            standalone_dt_names => $router_b->{standalone_dt_names},
            standalone_dt_enable_families => $router_b->{standalone_dt_enable_families},
            standalone_dt_module_enable_family => $router_b->{standalone_dt_module_enable_family},
            standalone_dt_multi_drive_target_count => $router_b->{standalone_dt_multi_drive_target_count},
            standalone_dt_multi_drive_targets => $router_b->{standalone_dt_multi_drive_targets},
        },
        {
            instance_name => 'router_b',
            module_name => 'route_b',
            source_name => 'route_b',
            standalone_dt_count => 1,
            standalone_dt_names => ['-route'],
            standalone_dt_enable_families => [
                { dt_name => '-route', enable_signal => 'route_en' },
            ],
            standalone_dt_module_enable_family => {
                dt_names => ['-route'],
                enable_signals => ['route_en'],
            },
            standalone_dt_multi_drive_target_count => 0,
            standalone_dt_multi_drive_targets => [],
        },
        'top module_info exposes reusable dt child export metadata for the second child while allowing additional exported forward IR fields',
    );
};

subtest 'CLI prints reusable standalone-DT child summary for composition tops' => sub {
    my $composition_path = write_fsm('composition_standalone_dt_export_summary_top.fsm', <<'FSM');
(?top:composition_standalone_dt_export_summary_top
  (?ports:public_io
    sel
    data_a<8
    data_b<8
    final_out>8
  )
  (?dtc:router_a route_a)
  (?dtc:router_b route_b)
  (?toplink:wiring
    /sel/router_a.sel/
    /data_a/router_a.a/
    /data_b/router_a.b/
    /router_a.out/router_b.in/
    /router_b.final_out/final_out/
  )
)

(?dt:route_a
  (+size
    (sel 1)
    (a 8)
    (b 8)
    (out 8)
  )
  (-from_a
    (<sel==1'b0
      (out> = a)
    )
  )
  (-from_b
    (<sel==1'b1
      (out> = b)
    )
  )
)

(?dt:route_b
  (+size
    (in 8)
    (final_out 8)
  )
  (-route
    (final_out> = in)
  )
)
FSM
    my $output_path = File::Spec->catfile($tempdir, 'composition_standalone_dt_export_summary_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for reusable standalone-DT child summary fixture');
    ok(-e $output_path, 'CLI writes HDL for reusable standalone-DT child summary fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Reusable Standalone-DT Children:/s, 'CLI prints reusable dt child summary header');
    like($combined_output, qr/Count:\s+2/s, 'CLI reports realized dt child count');
    like($combined_output, qr/Standalone-DT blocks:\s+3/s, 'CLI reports aggregated dt block count');
    like($combined_output, qr/Grouped shared targets:\s+1/s, 'CLI reports aggregated grouped shared-target count');
    like($combined_output, qr/router_a => route_a \(source: route_a, blocks: 2, grouped shared targets: 1\)/s, 'CLI prints first reusable dt child summary');
    like($combined_output, qr/\* out onehot0 over from_a_out_a_en, from_b_out_b_en/s, 'CLI prints the reusable dt child assertion summary for the grouped shared target');
    like($combined_output, qr/router_b => route_b \(source: route_b, blocks: 1, grouped shared targets: 0\)/s, 'CLI prints second reusable dt child summary');
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
