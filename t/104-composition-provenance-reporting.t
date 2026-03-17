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

subtest 'pipeline surfaces composition provenance report counts' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_provenance_reporting_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_provenance_reporting_top
  (?ports:public_io
    trigger
    serial_out>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.serial_payload/uart_tx.data_in/
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

    ok($report, 'composition result carries a provenance report');
    is($report->{lane}, 'C3', 'report records the active composition lane');
    is($report->{top_port_count}, 4, 'report counts top ports');
    is($report->{resolved_link_count}, 5, 'report counts resolved links');

    is($report->{port_origin_counts}{declared_explicit_port}, 2, 'report counts declared explicit top ports');
    is($report->{port_origin_counts}{inferred_undeclared_top_input_port}, 2, 'report counts inferred undeclared top inputs');
    is($report->{port_category_counts}{declared}, 2, 'report groups declared top ports');
    is($report->{port_category_counts}{inferred}, 2, 'report groups inferred top ports');

    is($report->{resolved_link_origin_counts}{declared_explicit_toplink}, 1, 'report counts declared explicit toplinks');
    is($report->{resolved_link_origin_counts}{inferred_plain_explicit_top_input_link}, 1, 'report counts inferred plain explicit top-input links');
    is($report->{resolved_link_origin_counts}{inferred_plain_explicit_top_output_link}, 1, 'report counts inferred plain explicit top-output links');
    is($report->{resolved_link_origin_counts}{auto_system_port_link}, 2, 'report counts auto system-port links');
    is($report->{resolved_link_category_counts}{declared}, 1, 'report groups declared resolved links');
    is($report->{resolved_link_category_counts}{inferred}, 2, 'report groups inferred resolved links');
    is($report->{resolved_link_category_counts}{auto}, 2, 'report groups auto resolved links');

    is(
        $result->{module_info}{composition_resolved_link_count},
        5,
        'module info carries the resolved-link count for composition summaries',
    );
    is(
        $result->{statistics}{composition_resolved_link_count},
        5,
        'statistics carry the resolved-link count for composition summaries',
    );
};

subtest 'CLI prints composition provenance summary for non-quiet composition runs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_provenance_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'composition_provenance_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_provenance_cli_top
  (?ports:public_io
    trigger
    serial_out>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.serial_payload/uart_tx.data_in/
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

    ok($success, 'CLI succeeds for composition provenance reporting fixture');
    ok(-e $output_path, 'CLI writes HDL output for composition provenance reporting fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Summary ===/s, 'CLI prints the composition summary section');
    like($combined_output, qr/Lane:\s+C3/s, 'CLI reports the active composition lane');
    like($combined_output, qr/Resolved links:\s+5/s, 'CLI reports the resolved-link count');
    like($combined_output, qr/Top Port Provenance:/s, 'CLI prints top-port provenance');
    like($combined_output, qr/declared explicit top port:\s+2/s, 'CLI reports declared explicit top-port provenance');
    like($combined_output, qr/inferred undeclared top input:\s+2/s, 'CLI reports inferred undeclared top-input provenance');
    like($combined_output, qr/Resolved Link Provenance:/s, 'CLI prints resolved-link provenance');
    like($combined_output, qr/declared explicit toplink:\s+1/s, 'CLI reports declared explicit-toplink provenance');
    like($combined_output, qr/inferred plain explicit top-input convention link:\s+1/s, 'CLI reports inferred plain explicit top-input provenance');
    like($combined_output, qr/inferred plain explicit top-output convention link:\s+1/s, 'CLI reports inferred plain explicit top-output provenance');
    like($combined_output, qr/auto system-port link:\s+2/s, 'CLI reports auto system-port provenance');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
