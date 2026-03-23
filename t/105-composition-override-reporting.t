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

subtest 'pipeline reports explicit toplink overrides of same-name convention' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_override_reporting_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_override_reporting_top
  (?ports:public_io
    trigger
    serial_out>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /trigger/producer.trigger/
    /producer.serial_payload/uart_tx.data_in/
    /uart_tx.serial_out/serial_out/
  )
)

(?dt:producer_src
  (-route
    (<trigger
      (serial_payload> = 8'1)
    )
    (<!trigger
      (serial_payload> = 8'0)
    )
  )
  (+size
    (trigger 1)
    (serial_payload 8)
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  serial_out>:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $report = $result->{composition_report};
    my ($input_override) = grep {
        ($_->{kind} || '') eq 'explicit_toplink_overrides_same_name_top_input_convention'
    } @{$report->{override_events} || []};
    my ($output_override) = grep {
        ($_->{kind} || '') eq 'explicit_toplink_overrides_same_name_top_output_convention'
    } @{$report->{override_events} || []};

    is($report->{lane}, 'C3', 'report records the active mixed explicit-link lane');
    is($report->{override_count}, 2, 'report counts same-name convention overrides');
    is(
        $report->{override_kind_counts}{explicit_toplink_overrides_same_name_top_input_convention},
        1,
        'report counts explicit toplink override of same-name top-input convention',
    );
    is(
        $report->{override_kind_examples}{explicit_toplink_overrides_same_name_top_input_convention},
        'trigger -> producer.trigger (?dt, blocks: 1, output drive families: 1)',
        'report keeps one forward-context example for the same-name top-input override family',
    );
    is(
        $report->{override_kind_counts}{explicit_toplink_overrides_same_name_top_output_convention},
        1,
        'report counts explicit toplink override of same-name top-output convention',
    );
    is(
        $report->{override_kind_examples}{explicit_toplink_overrides_same_name_top_output_convention},
        'uart_tx.serial_out (?rtl) -> serial_out',
        'report keeps one forward-context example for the same-name top-output override family',
    );
    is($input_override->{source_context}{kind}, 'top_port', 'top-input override event preserves top-port source context');
    is($input_override->{source_context}{direction}, 'input', 'top-input override event source direction now comes from structural top-port metadata');
    is($input_override->{source_context}{width}, 1, 'top-input override event source width now comes from structural top-port metadata');
    is($input_override->{source_context}{type}, undef, 'top-input override event source type now comes from structural top-port metadata');
    is($input_override->{target_context}{kind}, 'child_endpoint', 'top-input override event preserves child-endpoint target context');
    is($input_override->{target_context}{source_root_kind}, 'dt', 'top-input override event preserves child root kind in target context');
    is($input_override->{target_context}{direction}, 'input', 'top-input override event target direction now comes from structural child interface metadata');
    is($input_override->{target_context}{width}, 1, 'top-input override event target width now comes from structural child interface metadata');
    is($input_override->{target_context}{type}, undef, 'top-input override event target type now comes from structural child interface metadata');
    is($output_override->{source_context}{kind}, 'child_endpoint', 'top-output override event preserves child-endpoint source context');
    is($output_override->{source_context}{source_root_kind}, 'rtl', 'top-output override event preserves rtl child root kind in source context');
    is($output_override->{source_context}{direction}, 'output', 'top-output override event source direction now comes from structural child interface metadata');
    is($output_override->{source_context}{width}, 1, 'top-output override event source width now comes from structural child interface metadata');
    is($output_override->{source_context}{type}, 'data', 'top-output override event source type now comes from structural child interface metadata');
    is($output_override->{target_context}{kind}, 'top_port', 'top-output override event preserves top-port target context');
    is($output_override->{target_context}{direction}, 'output', 'top-output override event target direction now comes from structural top-port metadata');
    is($output_override->{target_context}{width}, 1, 'top-output override event target width now comes from structural top-port metadata');
    is($output_override->{target_context}{type}, undef, 'top-output override event target type now comes from structural top-port metadata');
    is(
        $result->{module_info}{composition_override_count},
        2,
        'module info carries the convention-override count',
    );
    is(
        $result->{statistics}{composition_override_count},
        2,
        'statistics carry the convention-override count',
    );
};

subtest 'pipeline reports explicit top-output re-export of inferred internal carrier' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_reexport_override_reporting_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_reexport_override_reporting_top
  (?ports:public_io
    go
    payload>8
  )
  (?dtc:producer producer_src)
  (?dtc:consumer consumer_src)
  (?toplink:wiring
    /go/producer.go/
    /go/consumer.go/
  )
)

(?dt:producer_src
  (-route
    (<go
      (payload> = 8'7)
    )
    (<!go
      (payload> = 8'0)
    )
  )
  (+size
    (go 1)
    (payload 8)
  )
)

(?dt:consumer_src
  (-route
    (<go
      (sink> = payload)
    )
    (<!go
      (sink> = 8'0)
    )
  )
  (+size
    (go 1)
    (payload 8)
    (sink 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $report = $result->{composition_report};
    my ($reexport_override) = grep {
        ($_->{kind} || '') eq 'explicit_top_output_reexports_internal_carrier'
    } @{$report->{override_events} || []};

    is($report->{lane}, 'C2', 'report records the active generated explicit-link lane');
    is($report->{override_count}, 2, 'report counts both the explicit input override and the internal-carrier re-export override');
    is(
        $report->{override_kind_counts}{explicit_toplink_overrides_same_name_top_input_convention},
        1,
        'report also counts explicit toplink override of same-name top-input convention in the re-export fixture',
    );
    is(
        $report->{override_kind_counts}{explicit_top_output_reexports_internal_carrier},
        1,
        'report counts explicit top-output re-export of an inferred internal carrier',
    );
    is(
        $report->{override_kind_examples}{explicit_top_output_reexports_internal_carrier},
        'producer.payload (?dt, blocks: 1, output drive families: 1) -> payload',
        'report keeps one forward-context example for the internal-carrier re-export override family',
    );
    is($reexport_override->{source_context}{kind}, 'child_endpoint', 'internal-carrier re-export override preserves child source context');
    is($reexport_override->{source_context}{source_root_kind}, 'dt', 'internal-carrier re-export override preserves dt child root kind');
    is($reexport_override->{source_context}{direction}, 'output', 'internal-carrier re-export override source direction now comes from structural child interface metadata');
    is($reexport_override->{source_context}{width}, 8, 'internal-carrier re-export override source width now comes from structural child interface metadata');
    is($reexport_override->{source_context}{type}, undef, 'internal-carrier re-export override source type now comes from structural child interface metadata');
    is($reexport_override->{top_port_context}{kind}, 'top_port', 'internal-carrier re-export override preserves top-port context');
    is($reexport_override->{top_port_context}{direction}, 'output', 'internal-carrier re-export override top-port direction now comes from structural top-port metadata');
    is($reexport_override->{top_port_context}{width}, 8, 'internal-carrier re-export override top-port width now comes from structural top-port metadata');
    is($reexport_override->{top_port_context}{type}, undef, 'internal-carrier re-export override top-port type now comes from structural top-port metadata');
};

subtest 'CLI prints convention override summary for non-quiet composition runs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_override_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'composition_override_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_override_cli_top
  (?ports:public_io
    trigger
    serial_out>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /trigger/producer.trigger/
    /producer.serial_payload/uart_tx.data_in/
    /uart_tx.serial_out/serial_out/
  )
)

(?dt:producer_src
  (-route
    (<trigger
      (serial_payload> = 8'1)
    )
    (<!trigger
      (serial_payload> = 8'0)
    )
  )
  (+size
    (trigger 1)
    (serial_payload 8)
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  serial_out>:data
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for convention-override reporting fixture');
    ok(-e $output_path, 'CLI writes HDL for convention-override reporting fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Convention overrides:\s+2/s, 'CLI reports the convention-override count');
    like($combined_output, qr/Convention Overrides:/s, 'CLI prints the convention override section');
    like(
        $combined_output,
        qr/explicit toplink overrides same-name top-input convention:\s+1 \(example: trigger -> producer\.trigger \(\?dt, blocks: 1, output drive families: 1\)\)/s,
        'CLI reports the top-input override kind with one forward-context example',
    );
    like(
        $combined_output,
        qr/explicit toplink overrides same-name top-output convention:\s+1 \(example: uart_tx\.serial_out \(\?rtl\) -> serial_out\)/s,
        'CLI reports the top-output override kind with one forward-context example',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
