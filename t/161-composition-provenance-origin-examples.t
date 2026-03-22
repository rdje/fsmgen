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

subtest 'composition provenance now preserves resolved-link endpoint context and origin examples' => sub {
    my $composition_path = write_fsm('composition_provenance_origin_examples_top.fsm', <<'FSM');
(?top:composition_provenance_origin_examples_top
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
    /producer.output_data/router.IN_A/
    /select/producer.select/
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
    my $report = $result->{composition_report};
    my ($producer_instance, $router_instance) = @{$result->{composition_plan}->instances};
    my ($producer_to_router) = grep {
        ($_->{source} || '') eq 'producer.output_data'
            && ($_->{target} || '') eq 'router.IN_A'
    } @{$report->{resolved_links} || []};

    ok($producer_to_router, 'resolved-link provenance keeps the producer-to-router link entry');
    is(
        $report->{port_origin_examples}{declared_explicit_port},
        'clk',
        'provenance report keeps one stable example top port for declared explicit port provenance',
    );
    is(
        $report->{resolved_link_origin_examples}{declared_explicit_toplink},
        'producer.output_data (?fsm, states: 2, output drive families: 1) -> router.IN_A (?dt, blocks: 3, output drive families: 1)',
        'provenance report keeps one stable forward-context example for declared explicit toplink provenance',
    );
    is(
        $report->{resolved_link_origin_examples}{auto_system_port_link},
        'clk -> producer.clk (?fsm, states: 2, output drive families: 1)',
        'provenance report keeps one stable forward-context example for auto system-port provenance',
    );

    is($producer_to_router->{source_context}{kind}, 'child_endpoint', 'resolved-link provenance tags child source endpoints explicitly');
    is($producer_to_router->{source_context}{instance_name}, 'producer', 'resolved-link provenance keeps source instance name');
    is($producer_to_router->{source_context}{source_root_kind}, 'fsm', 'resolved-link provenance keeps source root kind');
    is($producer_to_router->{source_context}{regular_state_count}, 2, 'resolved-link provenance keeps source state count');
    is($producer_to_router->{source_context}{output_drive_family_count}, 1, 'resolved-link provenance keeps source output-drive-family count');
    is_deeply(
        $producer_to_router->{source_context}{intent_hir},
        $producer_instance->module_info->{intent_hir},
        'resolved-link provenance keeps the same source intent_hir as the realized generated child',
    );
    is_deeply(
        $producer_to_router->{source_context}{lowered_rtl_ir},
        $producer_instance->module_info->{lowered_rtl_ir},
        'resolved-link provenance keeps the same source lowered_rtl_ir as the realized generated child',
    );

    is($producer_to_router->{target_context}{kind}, 'child_endpoint', 'resolved-link provenance tags child target endpoints explicitly');
    is($producer_to_router->{target_context}{instance_name}, 'router', 'resolved-link provenance keeps target instance name');
    is($producer_to_router->{target_context}{source_root_kind}, 'dt', 'resolved-link provenance keeps target root kind');
    is($producer_to_router->{target_context}{standalone_dt_count}, 3, 'resolved-link provenance keeps target standalone-DT block count');
    is($producer_to_router->{target_context}{output_drive_family_count}, 1, 'resolved-link provenance keeps target output-drive-family count');
    is_deeply(
        $producer_to_router->{target_context}{intent_hir},
        $router_instance->module_info->{intent_hir},
        'resolved-link provenance keeps the same target intent_hir as the realized generated child',
    );
    is_deeply(
        $producer_to_router->{target_context}{lowered_rtl_ir},
        $router_instance->module_info->{lowered_rtl_ir},
        'resolved-link provenance keeps the same target lowered_rtl_ir as the realized generated child',
    );
};

subtest 'CLI prints provenance origin examples from the new report surface' => sub {
    my $composition_path = write_fsm('composition_provenance_origin_examples_cli_top.fsm', <<'FSM');
(?top:composition_provenance_origin_examples_cli_top
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
    /producer.output_data/router.IN_A/
    /select/producer.select/
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
    my $output_path = File::Spec->catfile($tempdir, 'composition_provenance_origin_examples_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for provenance origin example fixture');
    ok(-e $output_path, 'CLI writes HDL for provenance origin example fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/declared explicit top port:\s+6 \(example: clk\)/s,
        'CLI prints top-port provenance examples',
    );
    like(
        $combined_output,
        qr/declared explicit toplink:\s+5 \(example: producer\.output_data \(\?fsm, states: 2, output drive families: 1\) -> router\.IN_A \(\?dt, blocks: 3, output drive families: 1\)\)/s,
        'CLI prints resolved-link provenance examples with forward child context',
    );
    like(
        $combined_output,
        qr/auto system-port link:\s+2 \(example: clk -> producer\.clk \(\?fsm, states: 2, output drive families: 1\)\)/s,
        'CLI prints auto-link provenance examples with forward child context',
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
