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

subtest 'combinational shared-datapath families now lift into one shared top-facing carrier for pure public fanout' => sub {
    my $composition_path = write_fsm('shared_datapath_comb_public_fanout_top.fsm', <<'FSM');
(?top:shared_datapath_comb_public_fanout_top
  (?ports:public_io
    select
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?wiring:wiring
    /select/left.select/
    /select/right.select/
    /left.status_bus/left_status/
    /right.status_bus/right_status/
  )
)

(?fsm:left_src
  (-path_a
    (<select==1'b0
      (status_bus> = 8'1)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:right_src
  (-path_a
    (<select==1'b1
      (status_bus> = 8'2)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my ($candidate) = grep {
        ($_->{signal_name} || '') eq 'status_bus'
    } @{$result->{module_info}{composition_shared_datapath_candidates} || []};
    my $hdl = $result->{hdl_code};

    ok($candidate, 'shared-datapath candidate metadata includes the combinational public-fanout status_bus family');
    is($candidate->{storage_class}, 'combinational', 'shared candidate is classified as combinational');
    is($candidate->{peer_input_count}, 0, 'shared candidate has no peer-read child inputs in the combinational public-fanout case');
    is($candidate->{default_lifted_visibility}, 'top_output', 'shared combinational public-fanout family stays top-output-visible by default');
    is($candidate->{lifted_runtime_kind}, 'combinational_shared_public_fanout', 'shared candidate records the bounded combinational public-fanout runtime kind');
    is($candidate->{lifted_runtime_signal}, 'status_bus_shared_comb', 'shared candidate records the lifted shared combinational carrier name');
    is_deeply(
        $candidate->{top_output_signals},
        ['left_status', 'right_status'],
        'shared candidate preserves both public top outputs in the combinational public-fanout case',
    );

    like($hdl, qr/\blogic\s+\[7:0\]\s+status_bus_shared_comb;/s, 'top HDL declares the lifted shared combinational carrier');
    like($hdl, qr/always_comb begin\s+status_bus_shared_comb = 1'b0;/s, 'top HDL defaults the lifted shared combinational carrier to zero');
    like($hdl, qr/if \(status_bus__8_d1_shared_en\) begin\s+status_bus_shared_comb = 8'd1;/s, 'top HDL updates the lifted combinational carrier from the first aggregate value family');
    like($hdl, qr/if \(status_bus__8_d2_shared_en\) begin\s+status_bus_shared_comb = 8'd2;/s, 'top HDL updates the lifted combinational carrier from the second aggregate value family');
    unlike($hdl, qr/\balways_ff\b/s, 'top HDL does not invent lifted sequential state for the combinational public-fanout carrier');

    like($hdl, qr/\bwire\s+\[7:0\]\s+shared_dp_raw_left_status_bus;/s, 'top HDL declares the raw left contributor output binding');
    like($hdl, qr/\bwire\s+\[7:0\]\s+shared_dp_raw_right_status_bus;/s, 'top HDL declares the raw right contributor output binding');
    like($hdl, qr/left_src left \([\s\S]*?\.status_bus\(shared_dp_raw_left_status_bus\)/s, 'left contributor output now binds to a private raw source net');
    like($hdl, qr/right_src right \([\s\S]*?\.status_bus\(shared_dp_raw_right_status_bus\)/s, 'right contributor output now binds to a private raw source net');
    like($hdl, qr/assign left_status = status_bus_shared_comb;/s, 'top HDL fans out the lifted combinational carrier to the first public top output');
    like($hdl, qr/assign right_status = status_bus_shared_comb;/s, 'top HDL fans out the lifted combinational carrier to the second public top output');
};

subtest 'CLI reports the bounded combinational public-fanout runtime' => sub {
    my $composition_path = write_fsm('shared_datapath_comb_public_fanout_cli_top.fsm', <<'FSM');
(?top:shared_datapath_comb_public_fanout_cli_top
  (?ports:public_io
    select
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?wiring:wiring
    /select/left.select/
    /select/right.select/
    /left.status_bus/left_status/
    /right.status_bus/right_status/
  )
)

(?fsm:left_src
  (-path_a
    (<select==1'b0
      (status_bus> = 8'1)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:right_src
  (-path_a
    (<select==1'b1
      (status_bus> = 8'2)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)
FSM

    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_comb_public_fanout_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for combinational public-fanout shared-datapath runtime fixture');
    ok(-e $output_path, 'CLI writes HDL for combinational public-fanout shared-datapath runtime fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/\* default lifted visibility: top_output/s, 'CLI reports the top-output default visibility');
    like($combined_output, qr/\* lifted runtime: combinational shared public fanout active/s, 'CLI reports the active combinational public-fanout runtime');
    like($combined_output, qr/\* lifted signal: status_bus_shared_comb/s, 'CLI reports the lifted shared combinational carrier name');
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
