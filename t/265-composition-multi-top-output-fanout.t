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

subtest 'pipeline and CLI emit one carrier plus explicit assignments for multi-top-output fanout' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'multi_top_output_fanout_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'multi_top_output_fanout_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:multi_top_output_fanout_top
  (?ports:public_io
    clk
    rstn
    status_a>8
    status_b>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.payload/status_a/
    /producer.payload/status_b/
    /producer.payload/consumer.payload/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (payload> <= 8'3)
  )
  (+size
    (payload 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (done> <= payload[0])
  )
  (+size
    (payload 8)
    (done 1)
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

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C2', 'multi-top-output fanout stays on the explicit-link C2 lane');
    is_deeply(
        $result->{composition_plan}->auxiliary_assignments,
        [
            '    assign status_a = comp_link_producer_payload;',
            '    assign status_b = comp_link_producer_payload;',
        ],
        'composition plan preserves explicit top-output fanout assignments',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bwire\s+\[7:0\]\s+comp_link_producer_payload;/, 'generated HDL emits one shared carrier net for the fanned-out child source');
    like($hdl, qr/assign status_a = comp_link_producer_payload;/, 'generated HDL emits the first explicit top-output fanout assignment');
    like($hdl, qr/assign status_b = comp_link_producer_payload;/, 'generated HDL emits the second explicit top-output fanout assignment');
    like($hdl, qr/producer_src producer \(\s*.*\.payload\(comp_link_producer_payload\)/s, 'producer output binds to the shared carrier net');
    like($hdl, qr/consumer_src consumer \(\s*.*\.payload\(comp_link_producer_payload\)/s, 'consumer input reuses the shared carrier net');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for multi-top-output fanout');
    ok(-e $output_path, 'CLI writes HDL for multi-top-output fanout');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
