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

subtest 'pipeline reports explicit child links blocking undeclared top inference' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_blocked_inference_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_blocked_inference_top
  (?ports)
  (?dtc:producer producer_src)
  (?dtc:consumer0 consumer0_src)
  (?dtc:consumer1 consumer1_src)
  (?toplink:wiring
    /producer.payload_bus/consumer0.payload_in/
    /producer.payload_bus/consumer1.payload_in/
  )
)

(?dt:producer_src
  (-route
    (payload_bus> = 8'5)
  )
  (+size
    (payload_bus 8)
  )
)

(?dt:consumer0_src
  (-route
    (sink0> = payload_in)
  )
  (+size
    (payload_in 8)
    (sink0 8)
  )
)

(?dt:consumer1_src
  (-route
    (sink1> = payload_in)
  )
  (+size
    (payload_in 8)
    (sink1 8)
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
    my $structural_rtl_ir = $result->{structural_rtl_ir};
    my ($blocked_input) = grep {
        ($_->{kind} || '') eq 'explicit_child_links_block_undeclared_top_input_inference'
    } @{$report->{block_events} || []};
    my ($blocked_output) = grep {
        ($_->{kind} || '') eq 'explicit_child_links_block_undeclared_top_output_inference'
    } @{$report->{block_events} || []};

    is($report->{lane}, 'C2', 'report records the generated explicit-link lane');
    is($report->{block_count}, 2, 'report counts both blocked undeclared top-interface families');
    is(
        $report->{block_kind_counts}{explicit_child_links_block_undeclared_top_input_inference},
        1,
        'report counts blocked undeclared top-input inference',
    );
    is(
        $report->{block_kind_examples}{explicit_child_links_block_undeclared_top_input_inference},
        'consumer0.payload_in (?dt, blocks: 1, output drive families: 1)',
        'report keeps one forward-context example for blocked undeclared top-input inference',
    );
    is(
        $report->{block_kind_counts}{explicit_child_links_block_undeclared_top_output_inference},
        1,
        'report counts blocked undeclared top-output inference',
    );
    is(
        $report->{block_kind_examples}{explicit_child_links_block_undeclared_top_output_inference},
        'producer.payload_bus (?dt, blocks: 1, output drive families: 1)',
        'report keeps one forward-context example for blocked undeclared top-output inference',
    );
    is($blocked_input->{candidate_contexts}[0]{kind}, 'child_endpoint', 'blocked top-input inference event preserves child endpoint context');
    is($blocked_input->{candidate_contexts}[0]{source_root_kind}, 'dt', 'blocked top-input inference event preserves child root kind');
    is($blocked_input->{candidate_contexts}[0]{direction}, 'input', 'blocked top-input inference candidate direction now comes from structural child interface metadata');
    is($blocked_input->{candidate_contexts}[0]{width}, 8, 'blocked top-input inference candidate width now comes from structural child interface metadata');
    is($blocked_input->{candidate_contexts}[0]{type}, undef, 'blocked top-input inference candidate type now comes from structural child interface metadata');
    is($blocked_output->{candidate_contexts}[0]{kind}, 'child_endpoint', 'blocked top-output inference event preserves child endpoint context');
    is($blocked_output->{candidate_contexts}[0]{source_root_kind}, 'dt', 'blocked top-output inference event preserves child root kind');
    is($blocked_output->{candidate_contexts}[0]{direction}, 'output', 'blocked top-output inference candidate direction now comes from structural child interface metadata');
    is($blocked_output->{candidate_contexts}[0]{width}, 8, 'blocked top-output inference candidate width now comes from structural child interface metadata');
    is($blocked_output->{candidate_contexts}[0]{type}, undef, 'blocked top-output inference candidate type now comes from structural child interface metadata');
    is(
        $result->{module_info}{composition_block_count},
        2,
        'module info carries the convention-block count',
    );
    is(
        $result->{statistics}{composition_block_count},
        2,
        'statistics carry the convention-block count',
    );
};

subtest 'pipeline reports inferred internal carriers kept internal by default' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_internal_block_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_internal_block_top
  (?ports)
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
    my $structural_rtl_ir = $result->{structural_rtl_ir};
    my ($internal_block) = grep {
        ($_->{kind} || '') eq 'inferred_internal_carrier_kept_internal_by_default'
    } @{$report->{block_events} || []};
    my ($internal_carrier_link) = grep {
        (($_->{origin_kind} || '') eq 'inferred_internal_carrier_link')
    } @{$structural_rtl_ir->{resolved_links} || []};

    is($report->{lane}, 'C2', 'report records the generated explicit-link lane');
    is($report->{block_count}, 1, 'report counts one internal carrier kept internal by default');
    is(
        $report->{block_kind_counts}{inferred_internal_carrier_kept_internal_by_default},
        1,
        'report counts the kept-internal internal-carrier family',
    );
    is(
        $report->{block_kind_examples}{inferred_internal_carrier_kept_internal_by_default},
        'producer.payload (?dt, blocks: 1, output drive families: 1)',
        'report keeps one forward-context example for the kept-internal internal-carrier family',
    );
    is($internal_block->{signal_name}, 'payload', 'kept-internal carrier event keeps the inferred internal family name');
    like($internal_carrier_link->{raw_token}, qr/^=implicit-internal:payload$/, 'structural resolved links preserve the kept-internal family token');
    is($internal_block->{candidate_contexts}[0]{kind}, 'child_endpoint', 'kept-internal carrier event preserves child endpoint context');
    is($internal_block->{candidate_contexts}[0]{source_root_kind}, 'dt', 'kept-internal carrier event preserves dt child root kind');
    is($internal_block->{candidate_contexts}[0]{direction}, 'output', 'kept-internal carrier candidate direction now comes from structural child interface metadata');
    is($internal_block->{candidate_contexts}[0]{width}, 8, 'kept-internal carrier candidate width now comes from structural child interface metadata');
    is($internal_block->{candidate_contexts}[0]{type}, undef, 'kept-internal carrier candidate type now comes from structural child interface metadata');
};

subtest 'CLI prints convention block summary for non-quiet composition runs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_blocked_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'composition_blocked_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_blocked_cli_top
  (?ports)
  (?dtc:producer producer_src)
  (?dtc:consumer0 consumer0_src)
  (?dtc:consumer1 consumer1_src)
  (?toplink:wiring
    /producer.payload_bus/consumer0.payload_in/
    /producer.payload_bus/consumer1.payload_in/
  )
)

(?dt:producer_src
  (-route
    (payload_bus> = 8'5)
  )
  (+size
    (payload_bus 8)
  )
)

(?dt:consumer0_src
  (-route
    (sink0> = payload_in)
  )
  (+size
    (payload_in 8)
    (sink0 8)
  )
)

(?dt:consumer1_src
  (-route
    (sink1> = payload_in)
  )
  (+size
    (payload_in 8)
    (sink1 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for convention-block reporting fixture');
    ok(-e $output_path, 'CLI writes HDL for convention-block reporting fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Convention blocks:\s+2/s, 'CLI reports the convention-block count');
    like($combined_output, qr/Convention Blocks:/s, 'CLI prints the convention block section');
    like(
        $combined_output,
        qr/explicit child links block undeclared top-input inference:\s+1 \(example: consumer0\.payload_in \(\?dt, blocks: 1, output drive families: 1\)\)/s,
        'CLI reports the blocked top-input inference kind with one forward-context example',
    );
    like(
        $combined_output,
        qr/explicit child links block undeclared top-output inference:\s+1 \(example: producer\.payload_bus \(\?dt, blocks: 1, output drive families: 1\)\)/s,
        'CLI reports the blocked top-output inference kind with one forward-context example',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
