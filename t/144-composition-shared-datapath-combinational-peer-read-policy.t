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

subtest 'shared-datapath candidates keep combinational peer-read families top-output-only' => sub {
    my $composition_path = write_fsm('shared_datapath_comb_peer_read_top.fsm', <<'FSM');
(?top:shared_datapath_comb_peer_read_top
  (?ports:public_io
    select
    left_status>8
    right_status>8
    result_data>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:consumer consumer_src)
  (?wiring:wiring
    /select/left.select/
    /select/right.select/
    /select/consumer.select/
    /left.status_bus/left_status/
    /left.status_bus/consumer.status_bus/
    /right.status_bus/right_status/
    /consumer.result_data/result_data/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
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
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> = 8'2)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (result_data> = status_bus)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
    (result_data 8)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $candidate = $result->{module_info}{composition_shared_datapath_candidates}[0];

    is($candidate->{storage_class}, 'combinational', 'shared candidate is classified as combinational');
    is($candidate->{peer_input_count}, 1, 'shared candidate reports one peer-read input endpoint');
    is($candidate->{default_lifted_visibility}, 'top_output', 'shared combinational peer-read family stays top-output-only by default');
    is($candidate->{peer_read_policy}, 'top_output_only', 'shared combinational peer-read family advertises top-output-only policy');
    is(
        $candidate->{peer_read_block_reason},
        'combinational shared families must stay top-facing and are not internalized into lifted state',
        'shared combinational peer-read family surfaces the bounded top-facing constraint',
    );
    is_deeply(
        $candidate->{planned_reexport_top_output_signals},
        [],
        'shared combinational peer-read family does not invent internal re-exports',
    );
    ok(!$candidate->{loopback_allowed}, 'shared combinational peer-read family does not allow loopback planning');
};

subtest 'CLI prints top-output-only policy for combinational peer-read shared-datapath families' => sub {
    my $composition_path = write_fsm('shared_datapath_comb_peer_read_cli_top.fsm', <<'FSM');
(?top:shared_datapath_comb_peer_read_cli_top
  (?ports:public_io
    select
    left_status>8
    right_status>8
    result_data>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:consumer consumer_src)
  (?wiring:wiring
    /select/left.select/
    /select/right.select/
    /select/consumer.select/
    /left.status_bus/left_status/
    /left.status_bus/consumer.status_bus/
    /right.status_bus/right_status/
    /consumer.result_data/result_data/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
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
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> = 8'2)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (result_data> = status_bus)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
    (result_data 8)
  )
)
FSM
    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_comb_peer_read_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for combinational peer-read shared-datapath summary fixture');
    ok(-e $output_path, 'CLI writes HDL for combinational peer-read shared-datapath summary fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/\* storage class: combinational/s, 'CLI prints the combinational storage class');
    like($combined_output, qr/\* default lifted visibility: top_output/s, 'CLI prints the top-output-only default visibility');
    like($combined_output, qr/\* peer-read inputs: consumer\.status_bus <= left_status/s, 'CLI prints the peer-read input endpoint together with its structural binding expression');
    like($combined_output, qr/\* peer-read policy: top-output-only/s, 'CLI prints the top-output-only peer-read policy');
    like(
        $combined_output,
        qr/\* peer-read constraint: combinational shared families must stay top-facing and are not internalized into lifted state/s,
        'CLI prints the combinational peer-read top-facing constraint',
    );
    like($combined_output, qr/\* loopback allowed: no/s, 'CLI prints the negative loopback planning decision');
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
