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

subtest 'shared-datapath candidates classify peer-read registered outputs as internal-by-default when lifted' => sub {
    my $composition_path = write_fsm('shared_datapath_visibility_top.fsm', <<'FSM');
(?top:shared_datapath_visibility_top
  (?ports:public_io
    select
    left_status>8
    right_status>8
    result_data>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (result_data> <= status_bus)
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

    is($candidate->{storage_class}, 'registered', 'shared candidate is classified as registered');
    is($candidate->{peer_input_count}, 1, 'shared candidate reports one peer-read input endpoint');
    is_deeply(
        $candidate->{peer_input_endpoints},
        [
            {
                instance_name => 'consumer',
                module_name => 'consumer_src',
                endpoint => 'consumer.status_bus',
                bound_signal => 'left_status',
                bound_signals => ['left_status'],
            },
        ],
        'shared candidate surfaces peer-read input endpoint identity and current bound signal',
    );
    is($candidate->{default_lifted_visibility}, 'internal', 'shared registered output becomes internal-by-default when peer-read');
    is($candidate->{peer_read_policy}, 'registered_loopback', 'shared registered output advertises loopback-eligible peer-read policy');
    is_deeply(
        $candidate->{planned_reexport_top_output_signals},
        ['left_status', 'right_status'],
        'shared candidate preserves explicit top outputs as planned re-exports when internalized',
    );
    ok($candidate->{loopback_allowed}, 'shared registered output allows loopback planning for peer-read inputs');
};

subtest 'CLI prints shared-datapath visibility planning for peer-read registered outputs' => sub {
    my $composition_path = write_fsm('shared_datapath_visibility_cli_top.fsm', <<'FSM');
(?top:shared_datapath_visibility_cli_top
  (?ports:public_io
    select
    left_status>8
    right_status>8
    result_data>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (result_data> <= status_bus)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
    (result_data 8)
  )
)
FSM
    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_visibility_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for shared-datapath visibility summary fixture');
    ok(-e $output_path, 'CLI writes HDL for shared-datapath visibility summary fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/\* storage class: registered/s, 'CLI prints the registered storage class');
    like($combined_output, qr/\* default lifted visibility: internal/s, 'CLI prints the internal-by-default lifted visibility');
    like($combined_output, qr/\* peer-read inputs: consumer\.status_bus/s, 'CLI prints the peer-read input endpoint');
    like($combined_output, qr/\* peer-read policy: registered loopback eligible/s, 'CLI prints the registered peer-read policy');
    like($combined_output, qr/\* planned top re-exports: left_status, right_status/s, 'CLI prints the planned top re-export list');
    like($combined_output, qr/\* loopback allowed: yes/s, 'CLI prints the positive loopback planning decision');
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
