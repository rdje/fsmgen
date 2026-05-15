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

subtest 'registered shared-datapath families now lift into one shared top-level register for pure public fanout' => sub {
    my $composition_path = write_fsm('shared_datapath_public_fanout_top.fsm', <<'FSM');
(?top:shared_datapath_public_fanout_top
  (?ports:public_io
    clk
    rstn
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
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> <= 8'1)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> <= 8'2)
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

    ok($candidate, 'shared-datapath candidate metadata includes the public-fanout status_bus family');
    is($candidate->{storage_class}, 'registered', 'shared candidate is classified as registered');
    is($candidate->{peer_input_count}, 0, 'shared candidate has no peer-read child inputs in the public-fanout case');
    is($candidate->{default_lifted_visibility}, 'top_output', 'shared registered public-fanout family stays top-output-visible by default');
    is($candidate->{lifted_runtime_kind}, 'registered_shared_public_fanout', 'shared candidate records the bounded public-fanout runtime kind');
    is($candidate->{lifted_runtime_signal}, 'status_bus_shared_q', 'shared candidate records the lifted shared register name');
    is_deeply(
        $candidate->{top_output_signals},
        ['left_status', 'right_status'],
        'shared candidate preserves both public top outputs in the fanout case',
    );

    like($hdl, qr/\blogic\s+\[7:0\]\s+status_bus_shared_next;/s, 'top HDL declares the lifted shared next-value register signal');
    like($hdl, qr/\blogic\s+\[7:0\]\s+status_bus_shared_q;/s, 'top HDL declares the lifted shared register');
    like($hdl, qr/always_ff @\(posedge clk\)/s, 'top HDL emits the lifted shared register runtime');
    like($hdl, qr/assign left_status = status_bus_shared_q;/s, 'top HDL fans out the lifted register to the first public top output');
    like($hdl, qr/assign right_status = status_bus_shared_q;/s, 'top HDL fans out the lifted register to the second public top output');
    like($hdl, qr/left_src left \([\s\S]*?\.status_bus\(shared_dp_raw_left_status_bus\)/s, 'left contributor output now binds to a private raw source net');
    like($hdl, qr/right_src right \([\s\S]*?\.status_bus\(shared_dp_raw_right_status_bus\)/s, 'right contributor output now binds to a private raw source net');
};

subtest 'CLI reports the bounded registered public-fanout runtime' => sub {
    my $composition_path = write_fsm('shared_datapath_public_fanout_cli_top.fsm', <<'FSM');
(?top:shared_datapath_public_fanout_cli_top
  (?ports:public_io
    clk
    rstn
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
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> <= 8'1)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> <= 8'2)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)
FSM

    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_public_fanout_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for registered public-fanout shared-datapath runtime fixture');
    ok(-e $output_path, 'CLI writes HDL for registered public-fanout shared-datapath runtime fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/\* default lifted visibility: top_output/s, 'CLI reports the top-output default visibility');
    like($combined_output, qr/\* lifted runtime: registered shared public fanout active/s, 'CLI reports the active registered public-fanout runtime');
    like($combined_output, qr/\* lifted signal: status_bus_shared_q/s, 'CLI reports the lifted shared register name');
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
